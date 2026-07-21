export const PUBLISH_KEY = 'share';
export const DEST_KEY = 'dest';
export const CONTROL_KEYS = [PUBLISH_KEY, DEST_KEY];

export const INDEX_FILE = 'index.md';
export const MANIFEST_FILE = 'sync-manifest.json';

const BLOG_SECTION = 'blog';
const CATCHALL_SECTION = 'synced';

export interface FrontmatterConfig {
	removeKeys: string[];
	renameKeys: Record<string, string>;
}

export const FRONTMATTER_CONFIG: FrontmatterConfig = {
	removeKeys: [],
	renameKeys: { created: 'date' },
};

export class PublishedNote {
	constructor(
		public readonly vaultPath: string,
		public readonly dest: string,
	) {}

	get slug(): string {
		const segments = this.segments();
		const last = segments[segments.length - 1];
		return last ?? '';
	}

	get bundleDir(): string {
		if (this.isBlog()) {
			return this.segments().join('/');
		}
		return `${CATCHALL_SECTION}/${this.slug}`;
	}

	get url(): string {
		return `/${this.bundleDir}/`;
	}

	private segments(): string[] {
		return this.dest
			.split('/')
			.map((segment) => segment.trim())
			.filter((segment) => segment.length > 0);
	}

	private isBlog(): boolean {
		const segments = this.segments();
		return segments.length >= 2 && segments[0] === BLOG_SECTION;
	}
}

export class PublishIndex {
	private readonly notes = new Map<string, PublishedNote>();

	add(note: PublishedNote): void {
		this.notes.set(note.vaultPath, note);
	}

	get(vaultPath: string): PublishedNote | undefined {
		return this.notes.get(vaultPath);
	}

	all(): PublishedNote[] {
		return Array.from(this.notes.values());
	}
}

export type Resolution =
	| { kind: 'note'; published: boolean; url: string | null }
	| { kind: 'attachment'; filename: string; width: number | null; height: number | null };

export interface EmbedDisplay {
	alt: string;
	width: number | null;
	height: number | null;
}

const SIZE_PATTERN = /^\d+(x\d+)?$/;

export function parseEmbedDisplay(displayText: string): EmbedDisplay {
	const parts = displayText.split('|');
	const sizeIndex = parts.findIndex((part) => SIZE_PATTERN.test(part.trim()));
	if (sizeIndex === -1) {
		return { alt: displayText, width: null, height: null };
	}
	const sizeToken = parts[sizeIndex]?.trim() ?? '';
	const alt = parts.filter((_, index) => index !== sizeIndex).join('|');
	const [width, height] = sizeToken.split('x');
	return {
		alt,
		width: toInt(width),
		height: toInt(height),
	};
}

function toInt(value: string | undefined): number | null {
	if (value === undefined || value.length === 0) {
		return null;
	}
	const parsed = Number.parseInt(value, 10);
	return Number.isNaN(parsed) ? null : parsed;
}

export interface ResolvedReference {
	start: number;
	end: number;
	isEmbed: boolean;
	text: string;
	original: string;
	resolution: Resolution;
}

export interface TransformResult {
	content: string;
	attachments: string[];
}

export function transformNote(
	rawText: string,
	frontmatterEndOffset: number,
	references: ResolvedReference[],
	config: FrontmatterConfig = FRONTMATTER_CONFIG,
): TransformResult {
	const descending = [...references].sort((a, b) => b.start - a.start);
	let text = rawText;
	for (const reference of descending) {
		const replacement = renderReference(reference);
		text = text.slice(0, reference.start) + replacement + text.slice(reference.end);
	}

	const frontmatter = rewriteFrontmatter(
		rawText.slice(0, frontmatterEndOffset),
		[...CONTROL_KEYS, ...config.removeKeys],
		config.renameKeys,
	);
	const body = text.slice(frontmatterEndOffset);

	const attachments: string[] = [];
	for (const reference of references) {
		const { resolution } = reference;
		if (resolution.kind === 'attachment' && !attachments.includes(resolution.filename)) {
			attachments.push(resolution.filename);
		}
	}

	return { content: frontmatter + body, attachments };
}

function renderReference(reference: ResolvedReference): string {
	const { resolution, text } = reference;
	if (resolution.kind === 'attachment') {
		return `![${text}](${resolution.filename}${sizeQuery(resolution.width, resolution.height)})`;
	}
	if (resolution.published && resolution.url) {
		return `[${text}](${resolution.url})`;
	}
	return text;
}

function sizeQuery(width: number | null, height: number | null): string {
	if (width === null) {
		return '';
	}
	const params = [`width=${width}`];
	if (height !== null) {
		params.push(`height=${height}`);
	}
	return `?${params.join('&')}`;
}

export function rewriteFrontmatter(
	frontmatter: string,
	stripKeys: string[],
	renames: Record<string, string>,
): string {
	if (frontmatter.length === 0) {
		return frontmatter;
	}
	const stripPattern =
		stripKeys.length > 0 ? new RegExp(`^(?:${stripKeys.join('|')})\\s*:`) : null;
	const renamePairs = Object.entries(renames).map(
		([from, to]) => [new RegExp(`^${from}(\\s*:)`), to] as const,
	);
	const out: string[] = [];
	let skipping = false;
	for (const line of frontmatter.split('\n')) {
		if (skipping) {
			if (isIndented(line)) {
				continue;
			}
			skipping = false;
		}
		if (stripPattern && stripPattern.test(line)) {
			skipping = true;
			continue;
		}
		out.push(applyRenames(line, renamePairs));
	}
	return out.join('\n');
}

function isIndented(line: string): boolean {
	return /^[ \t]/.test(line);
}

function applyRenames(
	line: string,
	pairs: ReadonlyArray<readonly [RegExp, string]>,
): string {
	for (const [pattern, to] of pairs) {
		if (pattern.test(line)) {
			return line.replace(pattern, `${to}$1`);
		}
	}
	return line;
}

export function stripFrontmatterKeys(frontmatter: string, keys: string[]): string {
	return rewriteFrontmatter(frontmatter, keys, {});
}

export interface BundleDeletion {
	bundleDir: string;
	files: string[];
	removeDirIfEmpty: boolean;
}

export class ManifestEntry {
	constructor(
		public readonly dest: string,
		public readonly bundleDir: string,
		public readonly files: string[],
	) {}
}

interface SerializedEntry {
	dest: string;
	bundleDir: string;
	files: string[];
}

interface SerializedManifest {
	version: number;
	entries: Record<string, SerializedEntry>;
}

export class Manifest {
	static readonly VERSION = 1;
	private readonly entries = new Map<string, ManifestEntry>();

	constructor(public readonly version: number = Manifest.VERSION) {}

	static parse(raw: string): Manifest {
		try {
			const data = JSON.parse(raw) as Partial<SerializedManifest> | null;
			if (!data || typeof data !== 'object' || !data.entries) {
				return new Manifest();
			}
			const version =
				typeof data.version === 'number' ? data.version : Manifest.VERSION;
			const manifest = new Manifest(version);
			for (const [vaultPath, entry] of Object.entries(data.entries)) {
				if (!entry || typeof entry.bundleDir !== 'string') {
					continue;
				}
				const files = Array.isArray(entry.files)
					? entry.files.filter((file): file is string => typeof file === 'string')
					: [];
				const dest = typeof entry.dest === 'string' ? entry.dest : '';
				manifest.set(vaultPath, new ManifestEntry(dest, entry.bundleDir, files));
			}
			return manifest;
		} catch {
			return new Manifest();
		}
	}

	serialize(): string {
		const entries: Record<string, SerializedEntry> = {};
		for (const [vaultPath, entry] of this.entries) {
			entries[vaultPath] = {
				dest: entry.dest,
				bundleDir: entry.bundleDir,
				files: entry.files,
			};
		}
		const data: SerializedManifest = { version: this.version, entries };
		return `${JSON.stringify(data, null, 2)}\n`;
	}

	get(vaultPath: string): ManifestEntry | undefined {
		return this.entries.get(vaultPath);
	}

	set(vaultPath: string, entry: ManifestEntry): void {
		this.entries.set(vaultPath, entry);
	}

	paths(): string[] {
		return Array.from(this.entries.keys());
	}

	reconcile(next: Manifest): BundleDeletion[] {
		const deletions: BundleDeletion[] = [];
		for (const [vaultPath, oldEntry] of this.entries) {
			const newEntry = next.get(vaultPath);
			if (!newEntry || newEntry.bundleDir !== oldEntry.bundleDir) {
				deletions.push({
					bundleDir: oldEntry.bundleDir,
					files: oldEntry.files,
					removeDirIfEmpty: true,
				});
				continue;
			}
			const dropped = oldEntry.files.filter(
				(file) => !newEntry.files.includes(file),
			);
			if (dropped.length > 0) {
				deletions.push({
					bundleDir: oldEntry.bundleDir,
					files: dropped,
					removeDirIfEmpty: false,
				});
			}
		}
		return deletions;
	}
}

export type SyncAction = 'created' | 'updated' | 'moved' | 'failed';

export interface PublishedResult {
	path: string;
	dest: string;
	url: string;
	action: SyncAction;
	detail: string | null;
}

export interface RemovedResult {
	path: string;
	bundleDir: string;
}

export interface SyncSummary {
	published: PublishedResult[];
	skipped: string[];
	removed: RemovedResult[];
}
