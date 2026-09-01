import type { Dirent } from 'fs';
import { describeError } from './sync';

export const MANIFEST_FILE = '.dots-synced';

export interface BundleFile {
	name: string;
	data: string | Uint8Array;
}

const MISSING_CODES = new Set(['ENOENT']);
const NOT_EMPTY_CODES = new Set(['ENOTEMPTY', 'EEXIST']);

export function parseManifest(raw: string): string[] {
	const bundleDirs = new Set<string>();
	for (const line of raw.split('\n')) {
		const bundleDir = line.trim().replace(/\/+$/, '');
		if (bundleDir.length > 0) {
			bundleDirs.add(bundleDir);
		}
	}
	return Array.from(bundleDirs);
}

export function formatManifest(bundleDirs: string[]): string {
	const lines = Array.from(new Set(bundleDirs)).sort();
	return lines.map((bundleDir) => `${bundleDir}/\n`).join('');
}

export class BundleStore {
	constructor(
		public readonly fs: typeof import('fs').promises,
		public readonly path: typeof import('path'),
		public readonly contentPath: string,
	) {}

	async check(): Promise<string | null> {
		const label = `Hugo content path ${this.contentPath}`;
		let stats;
		try {
			stats = await this.fs.stat(this.contentPath);
		} catch (error) {
			return `${label} cannot be read: ${describeError(error)}. Fix it in Dots settings.`;
		}
		if (!stats.isDirectory()) {
			return `${label} is not a folder. Fix it in Dots settings.`;
		}
		const { constants } = require('fs') as typeof import('fs');
		try {
			await this.fs.access(this.contentPath, constants.W_OK);
		} catch (error) {
			return `${label} is not writable: ${describeError(error)}. Fix it in Dots settings.`;
		}
		return null;
	}

	async readManifest(): Promise<string[]> {
		let raw: string;
		try {
			raw = await this.fs.readFile(this.manifestPath, 'utf8');
		} catch (error) {
			if (hasCode(error, MISSING_CODES)) {
				return [];
			}
			throw error;
		}
		return parseManifest(raw);
	}

	writeManifest(bundleDirs: string[]): Promise<void> {
		return this.fs.writeFile(this.manifestPath, formatManifest(bundleDirs));
	}

	async write(bundleDir: string, files: BundleFile[], owned: boolean): Promise<void> {
		const dir = this.path.join(this.contentPath, bundleDir);
		await this.fs.mkdir(dir, { recursive: true });

		if (owned) {
			const keep = new Set(files.map((file) => file.name));
			const entries = (await this.readDir(dir)) ?? [];
			for (const entry of entries) {
				if (entry.isFile() && !keep.has(entry.name)) {
					await removeFile(this.fs, this.path.join(dir, entry.name));
				}
			}
		}

		for (const file of files) {
			await this.fs.writeFile(this.path.join(dir, file.name), file.data);
		}
	}

	async remove(bundleDir: string): Promise<void> {
		const dir = this.path.join(this.contentPath, bundleDir);
		const entries = await this.readDir(dir);
		if (!entries) {
			return;
		}
		for (const entry of entries) {
			if (entry.isFile()) {
				await removeFile(this.fs, this.path.join(dir, entry.name));
			}
		}
		await removeDirIfEmpty(this.fs, dir);
	}

	private get manifestPath(): string {
		return this.path.join(this.contentPath, MANIFEST_FILE);
	}

	private async readDir(dir: string): Promise<Dirent[] | null> {
		try {
			return await this.fs.readdir(dir, { withFileTypes: true });
		} catch (error) {
			if (hasCode(error, MISSING_CODES)) {
				return null;
			}
			throw error;
		}
	}
}

function removeFile(fs: typeof import('fs').promises, target: string): Promise<void> {
	return fs.unlink(target).catch((error: unknown) => {
		if (hasCode(error, MISSING_CODES)) {
			return;
		}
		throw error;
	});
}

function removeDirIfEmpty(fs: typeof import('fs').promises, dir: string): Promise<void> {
	return fs.rmdir(dir).catch((error: unknown) => {
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
