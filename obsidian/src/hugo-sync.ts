import {
	App,
	CachedMetadata,
	FileSystemAdapter,
	Notice,
	ReferenceCache,
	TFile,
	normalizePath,
} from 'obsidian';
import { DotsSettings } from './settings';
import { ExifTool } from './image';
import { BundleFile, BundleStore } from './bundles';
import {
	FRONTMATTER_CONFIG,
	FailedResult,
	INDEX_FILE,
	PublishIndex,
	PublishedNote,
	PublishedResult,
	Resolution,
	ResolvedReference,
	SOURCE_KEY,
	SyncSummary,
	describeError,
	diffBundles,
	expandHome,
	isWikilink,
	linkDisplayText,
	linkpath,
	noteLinkUrl,
	parseEmbedDisplay,
	shareState,
	transformNote,
} from './sync';
import { SyncSummaryModal } from './sync-summary-modal';

interface DiscoveryResult {
	index: PublishIndex;
	skipped: string[];
}

interface PreparedNote {
	note: PublishedNote;
	file: TFile;
	references: ResolvedReference[];
	attachments: Map<string, TFile>;
	missingEmbeds: string[];
}

const NOTICE_MS = 15000;
const LEGACY_MANIFEST_FILE = 'sync-manifest.json';

export class HugoSync {
	private chain: Promise<unknown> = Promise.resolve();

	constructor(
		private readonly app: App,
		private readonly getSettings: () => DotsSettings,
		private readonly exiftool: ExifTool,
	) {}

	async publishAll(): Promise<void> {
		if (!this.contentPath()) {
			new Notice('Set the Hugo content path in Dots settings first.');
			return;
		}
		const summary = await this.serialize(() => this.run(null));
		if (summary) {
			new SyncSummaryModal(this.app, summary).open();
		}
	}

	async publishOne(vaultPath: string): Promise<void> {
		const summary = await this.serialize(() => this.run(vaultPath));
		const failure = summary?.failed[0];
		if (failure) {
			new Notice(`Failed to publish ${failure.path}: ${failure.error}`, NOTICE_MS);
		}
	}

	async removeLegacyManifest(): Promise<void> {
		const target = normalizePath(`${this.app.vault.configDir}/${LEGACY_MANIFEST_FILE}`);
		const adapter = this.app.vault.adapter;
		if (await adapter.exists(target)) {
			await adapter.remove(target);
		}
	}

	private serialize<T>(task: () => Promise<T>): Promise<T> {
		const result = this.chain.then(task, task);
		this.chain = result.catch(() => undefined);
		return result;
	}

	private async run(only: string | null): Promise<SyncSummary | null> {
		const store = await this.openStore();
		if (!store) {
			return null;
		}

		const previous = await store.readManifest();
		const owned = new Set(previous);
		const { index, skipped } = this.discover();
		const targets =
			only === null ? index.all() : index.all().filter((note) => note.vaultPath === only);

		const prepared: PreparedNote[] = [];
		for (const note of targets) {
			const file = this.app.vault.getAbstractFileByPath(note.vaultPath);
			if (!(file instanceof TFile)) {
				continue;
			}
			const cache = this.app.metadataCache.getFileCache(file);
			prepared.push({ note, file, ...this.resolveReferences(file, cache, index) });
		}

		const metadataFailures = await this.removeAttachmentMetadata(prepared);

		const published: PublishedResult[] = [];
		const failed: FailedResult[] = [];
		const written: string[] = [];
		for (const item of prepared) {
			const { note } = item;
			const target = store.path.join(store.contentPath, note.bundleDir);
			const problems = publishProblems(item, metadataFailures);
			if (problems.length > 0) {
				failed.push({ path: note.vaultPath, target, error: problems.join('; ') });
				continue;
			}
			const known = owned.has(note.bundleDir);
			try {
				await this.writeBundle(store, item, known);
				written.push(note.bundleDir);
				published.push({
					path: note.vaultPath,
					dest: note.dest,
					url: note.url,
					action: known ? 'updated' : 'created',
				});
			} catch (error) {
				console.error(`Publish notes: ${note.vaultPath} -> ${target}`, error);
				failed.push({ path: note.vaultPath, target, error: describeError(error) });
			}
		}

		const diff = diffBundles(previous, index.bundleDirs(), written);
		await this.removeBundles(store, diff.stale);
		await store.writeManifest(diff.synced);

		return {
			published,
			failed,
			skipped,
			removed: diff.stale.map((bundleDir) => ({ bundleDir })),
		};
	}

	private async removeAttachmentMetadata(
		prepared: PreparedNote[],
	): Promise<Map<string, string>> {
		const attachments = new Map<string, string>();
		const adapter = this.app.vault.adapter;
		for (const item of prepared) {
			for (const file of item.attachments.values()) {
				if (attachments.has(file.path)) {
					continue;
				}
				if (!(adapter instanceof FileSystemAdapter)) {
					throw new Error('Publishing attachments needs the desktop app.');
				}
				attachments.set(file.path, adapter.getFullPath(file.path));
			}
		}
		if (attachments.size === 0) {
			return new Map();
		}

		const report = await this.exiftool.removeMetadata(Array.from(attachments.values()));

		const vaultPathByAbsolute = new Map<string, string>();
		for (const [vaultPath, absolute] of attachments) {
			vaultPathByAbsolute.set(absolute, vaultPath);
		}
		const failures = new Map<string, string>();
		for (const failure of report.failures) {
			const vaultPath = vaultPathByAbsolute.get(failure.path) ?? failure.path;
			failures.set(vaultPath, failure.reason);
		}
		return failures;
	}

	private async removeBundles(store: BundleStore, bundleDirs: string[]): Promise<void> {
		const errors: string[] = [];
		for (const bundleDir of bundleDirs) {
			try {
				await store.remove(bundleDir);
			} catch (error) {
				errors.push(`${bundleDir}: ${describeError(error)}`);
			}
		}
		if (errors.length > 0) {
			console.error(`Publish notes cleanup errors:\n${errors.join('\n')}`);
		}
	}

	private contentPath(): string {
		return this.getSettings().hugoContentPath.trim();
	}

	private async openStore(): Promise<BundleStore | null> {
		const configured = this.contentPath();
		if (!configured) {
			return null;
		}

		const fs = require('fs') as typeof import('fs');
		const path = require('path') as typeof import('path');
		const os = require('os') as typeof import('os');
		const store = new BundleStore(fs.promises, path, expandHome(configured, os.homedir()));

		const unusable = await store.check();
		if (unusable) {
			new Notice(unusable, NOTICE_MS);
			console.error(`Publish notes: ${unusable}`);
			return null;
		}
		return store;
	}

	private discover(): DiscoveryResult {
		const index = new PublishIndex();
		const skipped: string[] = [];
		for (const file of this.app.vault.getMarkdownFiles()) {
			const state = shareState(this.app.metadataCache.getFileCache(file)?.frontmatter);
			if (state.kind === 'unshared') {
				continue;
			}
			if (state.kind === 'incomplete') {
				skipped.push(file.path);
				continue;
			}
			index.add(new PublishedNote(file.path, state.dest));
		}
		return { index, skipped };
	}

	private async writeBundle(
		store: BundleStore,
		item: PreparedNote,
		owned: boolean,
	): Promise<void> {
		const { note, file, references, attachments } = item;
		const cache = this.app.metadataCache.getFileCache(file);
		const raw = await this.app.vault.read(file);
		const frontmatterEnd = cache?.frontmatterPosition?.end.offset ?? 0;
		const result = transformNote(raw, frontmatterEnd, references, FRONTMATTER_CONFIG);

		const files: BundleFile[] = [{ name: INDEX_FILE, data: result.content }];
		for (const filename of result.attachments) {
			const source = attachments.get(filename);
			if (!source) {
				continue;
			}
			const bytes = await this.app.vault.readBinary(source);
			files.push({ name: filename, data: new Uint8Array(bytes) });
		}

		await store.write(note.bundleDir, files, owned);
	}

	private resolveReferences(
		file: TFile,
		cache: CachedMetadata | null,
		index: PublishIndex,
	): {
		references: ResolvedReference[];
		attachments: Map<string, TFile>;
		missingEmbeds: string[];
	} {
		const references: ResolvedReference[] = [];
		const attachments = new Map<string, TFile>();
		const missingEmbeds: string[] = [];

		for (const link of cache?.links ?? []) {
			if (linkpath(link.link).length === 0) {
				continue;
			}
			const target = this.resolveNote(link.link, file);
			if (!target && !isWikilink(link.original)) {
				continue;
			}
			references.push(
				toReference(
					link,
					false,
					linkDisplayText(link),
					target ? this.resolveFile(target, index) : { kind: 'note', url: null },
				),
			);
		}

		for (const embed of cache?.embeds ?? []) {
			const target = this.resolveTarget(embed.link, file);
			if (!target) {
				missingEmbeds.push(embed.link);
				continue;
			}
			if (target.extension === 'md') {
				if (!rewritable(embed)) {
					continue;
				}
				references.push(
					toReference(embed, true, linkDisplayText(embed), this.resolveFile(target, index)),
				);
				continue;
			}
			attachments.set(target.name, target);
			const display = parseEmbedDisplay(embed.displayText ?? '');
			references.push(
				toReference(embed, true, display.alt, {
					kind: 'attachment',
					filename: target.name,
					width: display.width,
					height: display.height,
				}),
			);
		}

		return { references, attachments, missingEmbeds };
	}

	private resolveNote(link: string, file: TFile): TFile | null {
		const target = this.resolveTarget(link, file);
		if (!target || target.extension !== 'md') {
			return null;
		}
		return target;
	}

	private resolveFile(target: TFile, index: PublishIndex): Resolution {
		const url = noteLinkUrl(index.get(target.path), this.sourceUrl(target));
		return { kind: 'note', url };
	}

	private sourceUrl(target: TFile): string | null {
		const frontmatter = this.app.metadataCache.getFileCache(target)?.frontmatter;
		const value = frontmatter?.[SOURCE_KEY] as unknown;
		if (typeof value !== 'string') {
			return null;
		}
		const url = value.trim();
		return url.length > 0 ? url : null;
	}

	private resolveTarget(link: string, file: TFile): TFile | null {
		return this.app.metadataCache.getFirstLinkpathDest(linkpath(link), file.path);
	}
}

function toReference(
	reference: ReferenceCache,
	isEmbed: boolean,
	text: string,
	resolution: Resolution,
): ResolvedReference {
	return {
		start: reference.position.start.offset,
		end: reference.position.end.offset,
		isEmbed,
		text,
		original: reference.original,
		resolution,
	};
}

function publishProblems(item: PreparedNote, failures: Map<string, string>): string[] {
	const problems: string[] = [];
	if (item.missingEmbeds.length > 0) {
		problems.push(`unresolved embeds: ${item.missingEmbeds.join(', ')}`);
	}
	const blocked: string[] = [];
	for (const file of item.attachments.values()) {
		const reason = failures.get(file.path);
		if (reason) {
			blocked.push(`${file.name} (${reason})`);
		}
	}
	if (blocked.length > 0) {
		problems.push(`EXIF removal failed: ${blocked.join('; ')}`);
	}
	return problems;
}

function rewritable(reference: ReferenceCache): boolean {
	return isWikilink(reference.original) && linkpath(reference.link).length > 0;
}
