import {
	App,
	CachedMetadata,
	Notice,
	ReferenceCache,
	TFile,
	normalizePath,
} from 'obsidian';
import { DotsSettings } from './settings';
import {
	BundleDeletion,
	DEST_KEY,
	FRONTMATTER_CONFIG,
	INDEX_FILE,
	MANIFEST_FILE,
	Manifest,
	ManifestEntry,
	PUBLISH_KEY,
	PublishIndex,
	PublishedNote,
	PublishedResult,
	RemovedResult,
	Resolution,
	ResolvedReference,
	SyncSummary,
	parseEmbedDisplay,
	transformNote,
} from './sync';
import { SyncSummaryModal } from './sync-summary-modal';

interface Io {
	fs: typeof import('fs').promises;
	path: typeof import('path');
	contentPath: string;
}

interface DiscoveryResult {
	index: PublishIndex;
	skipped: string[];
}

const MISSING_CODES = new Set(['ENOENT']);
const NOT_EMPTY_CODES = new Set(['ENOTEMPTY', 'EEXIST']);

export class HugoSync {
	constructor(
		private readonly app: App,
		private readonly getSettings: () => DotsSettings,
	) {}

	async run(): Promise<void> {
		const contentPath = this.getSettings().hugoContentPath.trim();
		if (!contentPath) {
			new Notice('Set the Hugo content path in Dots settings first.');
			return;
		}

		const fs = require('fs') as typeof import('fs');
		const path = require('path') as typeof import('path');
		const io: Io = { fs: fs.promises, path, contentPath };

		const { index, skipped } = this.discover();
		const oldManifest = await this.readManifest();
		const newManifest = new Manifest();
		const published: PublishedResult[] = [];

		for (const note of index.all()) {
			const file = this.app.vault.getAbstractFileByPath(note.vaultPath);
			if (!(file instanceof TFile)) {
				continue;
			}
			const previous = oldManifest.get(note.vaultPath);
			try {
				newManifest.set(note.vaultPath, await this.writeBundle(io, file, note, index));
				published.push({
					path: note.vaultPath,
					dest: note.dest,
					url: note.url,
					action: classifyAction(previous, note),
					detail: movedDetail(previous, note),
				});
			} catch (error) {
				if (previous) {
					newManifest.set(note.vaultPath, previous);
				}
				published.push({
					path: note.vaultPath,
					dest: note.dest,
					url: note.url,
					action: 'failed',
					detail: describe(error),
				});
			}
		}

		const removed = this.removedNotes(oldManifest, newManifest);

		const deletionErrors: string[] = [];
		for (const deletion of oldManifest.reconcile(newManifest)) {
			try {
				await this.applyDeletion(io, deletion);
			} catch (error) {
				deletionErrors.push(`${deletion.bundleDir}: ${describe(error)}`);
			}
		}
		if (deletionErrors.length > 0) {
			console.error(`Publish notes cleanup errors:\n${deletionErrors.join('\n')}`);
		}

		await this.writeManifest(newManifest);

		const summary: SyncSummary = { published, skipped, removed };
		new SyncSummaryModal(this.app, summary).open();
	}

	private removedNotes(oldManifest: Manifest, newManifest: Manifest): RemovedResult[] {
		const removed: RemovedResult[] = [];
		for (const path of oldManifest.paths()) {
			if (newManifest.get(path)) {
				continue;
			}
			const entry = oldManifest.get(path);
			removed.push({ path, bundleDir: entry?.bundleDir ?? '' });
		}
		return removed;
	}

	private discover(): DiscoveryResult {
		const index = new PublishIndex();
		const skipped: string[] = [];
		for (const file of this.app.vault.getMarkdownFiles()) {
			const frontmatter = this.app.metadataCache.getFileCache(file)?.frontmatter;
			if (!frontmatter || frontmatter[PUBLISH_KEY] !== true) {
				continue;
			}
			const dest =
				typeof frontmatter[DEST_KEY] === 'string' ? frontmatter[DEST_KEY].trim() : '';
			if (!dest) {
				skipped.push(file.path);
				continue;
			}
			index.add(new PublishedNote(file.path, dest));
		}
		return { index, skipped };
	}

	private async writeBundle(
		io: Io,
		file: TFile,
		note: PublishedNote,
		index: PublishIndex,
	): Promise<ManifestEntry> {
		const cache = this.app.metadataCache.getFileCache(file);
		const raw = await this.app.vault.read(file);
		const frontmatterEnd = cache?.frontmatterPosition?.end.offset ?? 0;
		const { references, attachments } = this.resolveReferences(file, cache, index);
		const result = transformNote(raw, frontmatterEnd, references, FRONTMATTER_CONFIG);

		const bundleDir = io.path.join(io.contentPath, note.bundleDir);
		await io.fs.mkdir(bundleDir, { recursive: true });
		await io.fs.writeFile(io.path.join(bundleDir, INDEX_FILE), result.content, 'utf8');

		const files = [INDEX_FILE];
		for (const filename of result.attachments) {
			const source = attachments.get(filename);
			if (!source) {
				continue;
			}
			const bytes = await this.app.vault.readBinary(source);
			await io.fs.writeFile(io.path.join(bundleDir, filename), new Uint8Array(bytes));
			files.push(filename);
		}

		return new ManifestEntry(note.dest, note.bundleDir, files);
	}

	private resolveReferences(
		file: TFile,
		cache: CachedMetadata | null,
		index: PublishIndex,
	): { references: ResolvedReference[]; attachments: Map<string, TFile> } {
		const references: ResolvedReference[] = [];
		const attachments = new Map<string, TFile>();

		for (const link of cache?.links ?? []) {
			references.push(
				toReference(
					link,
					false,
					this.linkText(link),
					this.resolveLink(link.link, file, index),
				),
			);
		}

		for (const embed of cache?.embeds ?? []) {
			const target = this.resolveTarget(embed.link, file);
			if (!target) {
				continue;
			}
			if (target.extension === 'md') {
				references.push(
					toReference(embed, true, this.linkText(embed), this.resolveFile(target, index)),
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

		return { references, attachments };
	}

	private resolveLink(link: string, file: TFile, index: PublishIndex): Resolution {
		const target = this.resolveTarget(link, file);
		if (!target || target.extension !== 'md') {
			return { kind: 'note', published: false, url: null };
		}
		return this.resolveFile(target, index);
	}

	private resolveFile(target: TFile, index: PublishIndex): Resolution {
		const published = index.get(target.path);
		if (published) {
			return { kind: 'note', published: true, url: published.url };
		}
		return { kind: 'note', published: false, url: null };
	}

	private resolveTarget(link: string, file: TFile): TFile | null {
		return this.app.metadataCache.getFirstLinkpathDest(linkpath(link), file.path);
	}

	private linkText(reference: ReferenceCache): string {
		const display = reference.displayText?.trim();
		if (display) {
			return display;
		}
		return displayFallback(reference.link);
	}

	private async applyDeletion(io: Io, deletion: BundleDeletion): Promise<void> {
		const bundleDir = io.path.join(io.contentPath, deletion.bundleDir);
		for (const filename of deletion.files) {
			await removeFile(io, io.path.join(bundleDir, filename));
		}
		if (deletion.removeDirIfEmpty) {
			await removeDirIfEmpty(io, bundleDir);
		}
	}

	private async readManifest(): Promise<Manifest> {
		const target = this.manifestPath();
		const adapter = this.app.vault.adapter;
		if (!(await adapter.exists(target))) {
			return new Manifest();
		}
		try {
			return Manifest.parse(await adapter.read(target));
		} catch {
			return new Manifest();
		}
	}

	private async writeManifest(manifest: Manifest): Promise<void> {
		await this.app.vault.adapter.write(this.manifestPath(), manifest.serialize());
	}

	private manifestPath(): string {
		return normalizePath(`${this.app.vault.configDir}/${MANIFEST_FILE}`);
	}
}

function classifyAction(
	previous: ManifestEntry | undefined,
	note: PublishedNote,
): 'created' | 'updated' | 'moved' {
	if (!previous) {
		return 'created';
	}
	if (previous.bundleDir !== note.bundleDir) {
		return 'moved';
	}
	return 'updated';
}

function movedDetail(
	previous: ManifestEntry | undefined,
	note: PublishedNote,
): string | null {
	if (previous && previous.bundleDir !== note.bundleDir) {
		return `from /${previous.bundleDir}/`;
	}
	return null;
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

function linkpath(link: string): string {
	const withoutSubpath = link.split('#')[0] ?? link;
	try {
		return decodeURIComponent(withoutSubpath);
	} catch {
		return withoutSubpath;
	}
}

function displayFallback(link: string): string {
	const base = linkpath(link);
	const segments = base.split('/');
	const last = segments[segments.length - 1] ?? base;
	return last.endsWith('.md') ? last.slice(0, -3) : last;
}

function removeFile(io: Io, target: string): Promise<void> {
	return io.fs.unlink(target).catch((error: unknown) => {
		if (hasCode(error, MISSING_CODES)) {
			return;
		}
		throw error;
	});
}

function removeDirIfEmpty(io: Io, dir: string): Promise<void> {
	return io.fs.rmdir(dir).catch((error: unknown) => {
		if (hasCode(error, MISSING_CODES) || hasCode(error, NOT_EMPTY_CODES)) {
			return;
		}
		throw error;
	});
}

function hasCode(error: unknown, codes: Set<string>): boolean {
	if (typeof error !== 'object' || error === null || !('code' in error)) {
		return false;
	}
	const { code } = error;
	return typeof code === 'string' && codes.has(code);
}

function describe(error: unknown): string {
	return error instanceof Error ? error.message : String(error);
}
