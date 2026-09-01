import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, mkdir, writeFile, readFile, access } from 'fs/promises';
import { promises as fsPromises } from 'fs';
import { tmpdir } from 'os';
import path, { join } from 'path';
import { BundleStore, MANIFEST_FILE, formatManifest, parseManifest } from './bundles';

async function withTempDir(run: (contentPath: string) => Promise<void>): Promise<void> {
	const dir = await mkdtemp(join(tmpdir(), 'dots-bundles-'));
	try {
		await run(dir);
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
}

function store(contentPath: string): BundleStore {
	return new BundleStore(fsPromises, path, contentPath);
}

async function pathExists(target: string): Promise<boolean> {
	try {
		await access(target);
		return true;
	} catch {
		return false;
	}
}

test('parseManifest drops the trailing slash and the blank lines', () => {
	assert.deepEqual(parseManifest('blog/a/\n\nsynced/b\n  \n'), ['blog/a', 'synced/b']);
});

test('parseManifest keeps one entry when a folder is listed twice', () => {
	assert.deepEqual(parseManifest('blog/a/\nblog/a/\n'), ['blog/a']);
});

test('formatManifest writes one sorted folder per line', () => {
	assert.equal(formatManifest(['synced/b', 'blog/a']), 'blog/a/\nsynced/b/\n');
});

test('reading a missing manifest reports nothing synced', async () => {
	await withTempDir(async (contentPath) => {
		assert.deepEqual(await store(contentPath).readManifest(), []);
	});
});

test('a written manifest reads back', async () => {
	await withTempDir(async (contentPath) => {
		const bundle = store(contentPath);
		await bundle.writeManifest(['blog/a', 'synced/b']);

		assert.deepEqual(await bundle.readManifest(), ['blog/a', 'synced/b']);
		assert.equal(
			await readFile(join(contentPath, MANIFEST_FILE), 'utf8'),
			'blog/a/\nsynced/b/\n',
		);
	});
});

test('writing an owned bundle drops an attachment that is gone', async () => {
	await withTempDir(async (contentPath) => {
		const bundle = store(contentPath);
		await bundle.write(
			'blog/a',
			[
				{ name: 'index.md', data: 'first' },
				{ name: 'old.png', data: new Uint8Array([1]) },
			],
			false,
		);

		await bundle.write('blog/a', [{ name: 'index.md', data: 'second' }], true);

		assert.equal(await pathExists(join(contentPath, 'blog/a/old.png')), false);
		assert.equal(await readFile(join(contentPath, 'blog/a/index.md'), 'utf8'), 'second');
	});
});

test('writing a bundle that was not synced before leaves the stray files alone', async () => {
	await withTempDir(async (contentPath) => {
		await mkdir(join(contentPath, 'blog/a'), { recursive: true });
		await writeFile(join(contentPath, 'blog/a/stray.txt'), 'hand made');

		await store(contentPath).write('blog/a', [{ name: 'index.md', data: 'content' }], false);

		assert.equal(await pathExists(join(contentPath, 'blog/a/stray.txt')), true);
		assert.equal(await pathExists(join(contentPath, 'blog/a/index.md')), true);
	});
});

test('remove clears a folder', async () => {
	await withTempDir(async (contentPath) => {
		const bundle = store(contentPath);
		await bundle.write('blog/a', [{ name: 'index.md', data: 'content' }], false);

		await bundle.remove('blog/a');

		assert.equal(await pathExists(join(contentPath, 'blog/a')), false);
	});
});

test('remove keeps a parent that still holds a live bundle', async () => {
	await withTempDir(async (contentPath) => {
		const bundle = store(contentPath);
		await bundle.write('blog/a', [{ name: 'index.md', data: 'parent' }], false);
		await bundle.write('blog/a/child', [{ name: 'index.md', data: 'child' }], false);

		await bundle.remove('blog/a');

		assert.equal(await pathExists(join(contentPath, 'blog/a/index.md')), false);
		assert.equal(await pathExists(join(contentPath, 'blog/a/child/index.md')), true);
	});
});

test('remove ignores a folder that is already gone', async () => {
	await withTempDir(async (contentPath) => {
		await store(contentPath).remove('blog/missing');
	});
});
