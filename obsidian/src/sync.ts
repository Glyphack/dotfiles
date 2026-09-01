export const PUBLISH_KEY = 'share';
export const DEST_KEY = 'dest';
export const SOURCE_KEY = 'source';
export const CONTROL_KEYS = [PUBLISH_KEY, DEST_KEY];

export type ShareState =
	| { kind: 'shared'; dest: string }
	| { kind: 'incomplete' }
	| { kind: 'unshared' };

export function shareState(
	frontmatter: Record<string, unknown> | undefined,
): ShareState {
	if (!frontmatter || frontmatter[PUBLISH_KEY] !== true) {
		return { kind: 'unshared' };
	}
	const raw = frontmatter[DEST_KEY];
	const dest = typeof raw === 'string' ? raw.trim() : '';
	if (!dest) {
		return { kind: 'incomplete' };
	}
	return { kind: 'shared', dest };
}

export const INDEX_FILE = 'index.md';

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

	bundleDirs(): string[] {
		return this.all().map((note) => note.bundleDir);
	}
}

export function noteLinkUrl(
	published: PublishedNote | undefined,
	source: string | null,
): string | null {
	return published?.url ?? source ?? null;
}

export type Resolution =
	| { kind: 'note'; url: string | null }
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
	if (resolution.url) {
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
		out.push(unwrapWikilinks(applyRenames(line, renamePairs)));
	}
	return out.join('\n');
}

const WIKILINK_PATTERN = /\[\[([^\]]*)\]\]/g;

function unwrapWikilinks(line: string): string {
	return line.replace(WIKILINK_PATTERN, (match, inner: string) => {
		const parts = inner.split('|');
		if (parts.length > 1) {
			return (parts[parts.length - 1] ?? '').trim();
		}
		const target = (parts[0] ?? '').split('#')[0]?.trim() ?? '';
		return target.length > 0 ? target : match;
	});
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

export interface BundleDiff {
	stale: string[];
	synced: string[];
}

export function diffBundles(
	previous: Iterable<string>,
	wanted: Iterable<string>,
	written: Iterable<string>,
): BundleDiff {
	const keep = new Set(wanted);
	const synced = new Set(written);
	const stale: string[] = [];
	for (const bundleDir of previous) {
		if (!keep.has(bundleDir)) {
			stale.push(bundleDir);
			continue;
		}
		synced.add(bundleDir);
	}
	return { stale, synced: Array.from(synced) };
}

export type SyncAction = 'created' | 'updated';

export interface PublishedResult {
	path: string;
	dest: string;
	url: string;
	action: SyncAction;
}

export interface FailedResult {
	path: string;
	target: string;
	error: string;
}

export interface RemovedResult {
	bundleDir: string;
}

export interface SyncSummary {
	published: PublishedResult[];
	failed: FailedResult[];
	skipped: string[];
	removed: RemovedResult[];
}

export interface LinkReference {
	original: string;
	displayText?: string;
	link: string;
}

export function linkpath(link: string): string {
	const withoutSubpath = link.split('#')[0] ?? link;
	try {
		return decodeURIComponent(withoutSubpath);
	} catch {
		return withoutSubpath;
	}
}

export function noteName(link: string): string {
	const base = linkpath(link);
	const segments = base.split('/');
	const last = segments[segments.length - 1] ?? base;
	return last.endsWith('.md') ? last.slice(0, -3) : last;
}

export function linkDisplayText(reference: LinkReference): string {
	const written = markdownLinkText(reference.original);
	if (written) {
		return written;
	}
	if (reference.original.includes('|')) {
		const alias = reference.displayText?.trim();
		if (alias) {
			return alias;
		}
	}
	return noteName(reference.link);
}

function markdownLinkText(original: string): string | null {
	if (isWikilink(original)) {
		return null;
	}
	const close = original.lastIndexOf('](');
	if (close < 0) {
		return null;
	}
	const open = original.startsWith('![') ? 2 : 1;
	const text = original.slice(open, close).trim();
	return text.length > 0 ? text : null;
}

export function isWikilink(original: string): boolean {
	return original.startsWith('[[') || original.startsWith('![[');
}

const HOME_PREFIXES = ['~', '$HOME', '${HOME}'];

export function expandHome(target: string, home: string): string {
	const trimmed = target.trim();
	for (const prefix of HOME_PREFIXES) {
		if (trimmed === prefix) {
			return home;
		}
		if (trimmed.startsWith(`${prefix}/`)) {
			return home + trimmed.slice(prefix.length);
		}
	}
	return trimmed;
}

const ERROR_FIELDS = ['code', 'syscall', 'path', 'dest'] as const;

export function describeError(error: unknown): string {
	if (!(error instanceof Error)) {
		return String(error);
	}
	const record = error as unknown as Record<string, unknown>;
	const extra: string[] = [];
	for (const field of ERROR_FIELDS) {
		const value = record[field];
		if (typeof value === 'string' && !error.message.includes(value)) {
			extra.push(`${field}=${value}`);
		}
	}
	if (extra.length === 0) {
		return error.message;
	}
	return `${error.message} (${extra.join(', ')})`;
}
