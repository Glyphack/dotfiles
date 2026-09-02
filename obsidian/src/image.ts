import { execFile } from 'child_process';
import { promises as fs } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { promisify } from 'util';

const execFileAsync = promisify(execFile);

const BINARY_CANDIDATES = [
	'exiftool',
	'/opt/homebrew/bin/exiftool',
	'/usr/local/bin/exiftool',
];
const MAX_BUFFER = 64 * 1024 * 1024;

export const EXIFTOOL_MISSING =
	'exiftool not found. Install it first (brew install exiftool).';

// PNG tags that describe how to render the pixels rather than metadata about
// them. AppleDataOffsets is the iDOT chunk, a decoding hint with no metadata.
const PNG_STRUCTURAL_TAGS = [
	'AppleDataOffsets',
	'ImageWidth',
	'ImageHeight',
	'BitDepth',
	'ColorType',
	'Compression',
	'Filter',
	'Interlace',
	'SRGBRendering',
	'Gamma',
	'PixelsPerUnitX',
	'PixelsPerUnitY',
	'PixelUnits',
	'SignificantBits',
	'BackgroundColor',
	'Transparency',
	'Palette',
	'ProfileName',
	'WhitePointX',
	'WhitePointY',
	'RedX',
	'RedY',
	'GreenX',
	'GreenY',
	'BlueX',
	'BlueY',
	'AnimationFrames',
	'AnimationPlays',
];

// Orientation is kept so photos display upright; YCbCrPositioning is a
// structural tag exiftool writes back alongside it.
const SCAN_ARGS = [
	'-json',
	'-a',
	'-G0',
	'-MIMEType',
	'-EXIF:all',
	'--EXIF:Orientation',
	'--EXIF:YCbCrPositioning',
	'-XMP:all',
	'-IPTC:all',
	'-MakerNotes:all',
	'-Photoshop:all',
	'-Comment',
	'-PNG:all',
	...PNG_STRUCTURAL_TAGS.map((tag) => `--PNG:${tag}`),
];

// Deletes all metadata except the color profile, drops trailing data such as
// embedded motion-photo videos, and writes the orientation back.
const STRIP_ARGS = [
	'-all=',
	'--icc_profile:all',
	'-trailer:all=',
	'-tagsfromfile',
	'@',
	'-Orientation',
	'-overwrite_original',
];

const SOURCE_KEY = 'SourceFile';
const MIME_KEY = 'File:MIMEType';
const TOOL_KEY_PREFIX = 'ExifTool:';
const ERROR_KEY = 'ExifTool:Error';

export interface RemovalFailure {
	path: string;
	reason: string;
}

export class FileScan {
	constructor(
		public readonly path: string,
		public readonly mimeType: string,
		public readonly metadataKeys: string[],
		public readonly error: string | null,
	) {}

	get isImage(): boolean {
		return this.mimeType.startsWith('image/');
	}

	get dirty(): boolean {
		return this.metadataKeys.length > 0;
	}
}

export class RemovalReport {
	constructor(
		public readonly skipped: string[],
		public readonly alreadyClean: string[],
		public readonly cleaned: string[],
		public readonly failures: RemovalFailure[],
	) {}

	static empty(): RemovalReport {
		return new RemovalReport([], [], [], []);
	}

	describe(): string {
		const parts = [
			`cleaned ${this.cleaned.length}`,
			`already clean ${this.alreadyClean.length}`,
		];
		if (this.skipped.length > 0) {
			parts.push(`skipped ${this.skipped.length} non-images`);
		}
		if (this.failures.length > 0) {
			parts.push(`failed ${this.failures.length}`);
		}
		return `EXIF removal: ${parts.join(', ')}.`;
	}
}

export class ExifTool {
	private binary: string | null = null;

	async available(): Promise<boolean> {
		return (await this.resolveBinary()) !== null;
	}

	async removeMetadata(paths: string[]): Promise<RemovalReport> {
		if (paths.length === 0) {
			return RemovalReport.empty();
		}
		if (!(await this.resolveBinary())) {
			throw new Error(EXIFTOOL_MISSING);
		}

		const scans = byPath(await this.scan(paths));
		const skipped: string[] = [];
		const alreadyClean: string[] = [];
		const failures: RemovalFailure[] = [];
		const dirty: string[] = [];
		for (const path of paths) {
			const scan = scans.get(path);
			if (!scan) {
				failures.push({ path, reason: 'exiftool returned no result' });
				continue;
			}
			if (!scan.isImage) {
				skipped.push(path);
				continue;
			}
			if (scan.error) {
				failures.push({ path, reason: scan.error });
				continue;
			}
			if (!scan.dirty) {
				alreadyClean.push(path);
				continue;
			}
			dirty.push(path);
		}
		if (dirty.length === 0) {
			return new RemovalReport(skipped, alreadyClean, [], failures);
		}

		const stripErrors = await this.strip(dirty);
		const verified = byPath(await this.scan(dirty));
		const cleaned: string[] = [];
		for (const path of dirty) {
			const scan = verified.get(path);
			if (scan && !scan.error && !scan.dirty) {
				cleaned.push(path);
				continue;
			}
			failures.push({ path, reason: failureReason(path, scan, stripErrors) });
		}
		return new RemovalReport(skipped, alreadyClean, cleaned, failures);
	}

	private async scan(paths: string[]): Promise<FileScan[]> {
		const { stdout } = await this.run(SCAN_ARGS, paths);
		return parseScans(stdout);
	}

	private async strip(paths: string[]): Promise<Map<string, string>> {
		const { stderr } = await this.run(STRIP_ARGS, paths);
		return parseStripErrors(stderr);
	}

	private async run(
		args: string[],
		paths: string[],
	): Promise<{ stdout: string; stderr: string }> {
		const dir = await fs.mkdtemp(join(tmpdir(), 'dots-exiftool-'));
		try {
			const argFile = join(dir, 'paths.txt');
			await fs.writeFile(argFile, paths.join('\n'), 'utf8');
			try {
				return await this.execTool([...args, '-@', argFile]);
			} catch (error) {
				const wrapped = invocationError(error, this.binary ?? 'exiftool', args, paths);
				if (wrapped !== error) {
					console.error(wrapped.message);
				}
				throw wrapped;
			}
		} finally {
			await fs.rm(dir, { recursive: true, force: true });
		}
	}

	private async execTool(
		args: string[],
	): Promise<{ stdout: string; stderr: string }> {
		const binary = await this.resolveBinary();
		if (!binary) {
			throw new Error(EXIFTOOL_MISSING);
		}
		try {
			return await execFileAsync(binary, args, { maxBuffer: MAX_BUFFER });
		} catch (error) {
			const failure = error as {
				code?: unknown;
				stdout?: unknown;
				stderr?: unknown;
			};
			if (
				typeof failure.code === 'number' &&
				typeof failure.stdout === 'string' &&
				typeof failure.stderr === 'string'
			) {
				return { stdout: failure.stdout, stderr: failure.stderr };
			}
			throw error;
		}
	}

	private async resolveBinary(): Promise<string | null> {
		if (this.binary) {
			return this.binary;
		}
		for (const candidate of BINARY_CANDIDATES) {
			try {
				await execFileAsync(candidate, ['-ver'], { maxBuffer: MAX_BUFFER });
				this.binary = candidate;
				return candidate;
			} catch {
				continue;
			}
		}
		return null;
	}
}

const MAX_ERROR_PATHS = 5;
const MAX_ERROR_OUTPUT = 2000;

export function invocationError(
	error: unknown,
	binary: string,
	args: string[],
	paths: string[],
): Error {
	if (error instanceof Error && error.message === EXIFTOOL_MISSING) {
		return error;
	}
	const failure = error as { stdout?: unknown; stderr?: unknown };
	const output = [failure.stderr, failure.stdout]
		.filter((part): part is string => typeof part === 'string')
		.map((part) => part.trim())
		.filter((part) => part.length > 0)
		.join('\n');
	const shown = paths.slice(0, MAX_ERROR_PATHS);
	const hidden = paths.length - shown.length;
	const command = [binary, ...args, ...shown].map(shellWord).join(' ');
	const suffix = hidden > 0 ? ` (and ${hidden} more)` : '';
	const lines = [
		`exiftool failed: ${messageOf(error)}`,
		`command: ${command}${suffix}`,
	];
	if (output.length > 0) {
		lines.push(`output: ${truncate(output, MAX_ERROR_OUTPUT)}`);
	}
	return new Error(lines.join('\n'));
}

function shellWord(word: string): string {
	if (/^[A-Za-z0-9_@%+=:,./-]+$/.test(word)) {
		return word;
	}
	return `'${word.replaceAll("'", "'\\''")}'`;
}

function truncate(text: string, limit: number): string {
	if (text.length <= limit) {
		return text;
	}
	return `${text.slice(0, limit)}...`;
}

function messageOf(error: unknown): string {
	return error instanceof Error ? error.message : String(error);
}

export function parseScans(stdout: string): FileScan[] {
	const trimmed = stdout.trim();
	if (!trimmed.startsWith('[')) {
		return [];
	}
	let entries: unknown;
	try {
		entries = JSON.parse(trimmed);
	} catch {
		return [];
	}
	if (!Array.isArray(entries)) {
		return [];
	}
	const scans: FileScan[] = [];
	for (const entry of entries) {
		if (typeof entry !== 'object' || entry === null) {
			continue;
		}
		scans.push(scanFromEntry(entry as Record<string, unknown>));
	}
	return scans;
}

export function parseStripErrors(stderr: string): Map<string, string> {
	const errors = new Map<string, string>();
	for (const line of stderr.split('\n')) {
		const match = /^Error: (.+?) - (.+)$/.exec(line.trim());
		if (!match) {
			continue;
		}
		const [, reason, path] = match;
		if (reason && path) {
			errors.set(path, reason);
		}
	}
	return errors;
}

function scanFromEntry(entry: Record<string, unknown>): FileScan {
	const path = typeof entry[SOURCE_KEY] === 'string' ? entry[SOURCE_KEY] : '';
	const mime = typeof entry[MIME_KEY] === 'string' ? entry[MIME_KEY] : '';
	const errorValue = entry[ERROR_KEY];
	const error = typeof errorValue === 'string' ? errorValue : null;
	const metadataKeys = Object.keys(entry).filter(
		(key) =>
			key !== SOURCE_KEY && key !== MIME_KEY && !key.startsWith(TOOL_KEY_PREFIX),
	);
	return new FileScan(path, mime, metadataKeys, error);
}

function byPath(scans: FileScan[]): Map<string, FileScan> {
	const map = new Map<string, FileScan>();
	for (const scan of scans) {
		map.set(scan.path, scan);
	}
	return map;
}

function failureReason(
	path: string,
	scan: FileScan | undefined,
	stripErrors: Map<string, string>,
): string {
	const stripError = stripErrors.get(path);
	if (stripError) {
		return stripError;
	}
	if (!scan) {
		return 'exiftool returned no result';
	}
	if (scan.error) {
		return scan.error;
	}
	return `metadata still present: ${scan.metadataKeys.join(', ')}`;
}
