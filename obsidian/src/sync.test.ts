import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
	Manifest,
	ManifestEntry,
	PublishedNote,
	Resolution,
	ResolvedReference,
	parseEmbedDisplay,
	rewriteFrontmatter,
	stripFrontmatterKeys,
	transformNote,
} from './sync';

function ref(
	full: string,
	original: string,
	text: string,
	resolution: Resolution,
	isEmbed = false,
): ResolvedReference {
	const start = full.indexOf(original);
	assert.notEqual(start, -1, `original not found in body: ${original}`);
	return { start, end: start + original.length, isEmbed, text, original, resolution };
}

function only<T>(items: T[]): T {
	assert.equal(items.length, 1);
	const first = items[0];
	assert.ok(first);
	return first;
}

test('PublishedNote computes slug, bundleDir, and url', () => {
	const blog = new PublishedNote('Notes/A.md', 'blog/dv-8');
	assert.equal(blog.slug, 'dv-8');
	assert.equal(blog.bundleDir, 'blog/dv-8');
	assert.equal(blog.url, '/blog/dv-8/');

	const nested = new PublishedNote('Notes/B.md', 'blog/2026/hello');
	assert.equal(nested.bundleDir, 'blog/2026/hello');
	assert.equal(nested.url, '/blog/2026/hello/');

	const typo = new PublishedNote('Notes/C.md', 'blg/dv-8');
	assert.equal(typo.slug, 'dv-8');
	assert.equal(typo.bundleDir, 'sync/dv-8');
	assert.equal(typo.url, '/sync/dv-8/');

	const bare = new PublishedNote('Notes/D.md', 'dv-8');
	assert.equal(bare.bundleDir, 'sync/dv-8');
	assert.equal(bare.url, '/sync/dv-8/');

	const foreign = new PublishedNote('Notes/E.md', 'notes/dv-8');
	assert.equal(foreign.bundleDir, 'sync/dv-8');
	assert.equal(foreign.url, '/sync/dv-8/');
});

test('rewrites a published note link to its url', () => {
	const body = 'See [[Other]] now.';
	const out = transformNote(body, 0, [
		ref(body, '[[Other]]', 'Other', { kind: 'note', published: true, url: '/s/other/' }),
	]);
	assert.equal(out.content, 'See [Other](/s/other/) now.');
	assert.deepEqual(out.attachments, []);
});

test('drops a link to an unpublished note down to plain text', () => {
	const body = 'See [[Secret|the secret]] now.';
	const out = transformNote(body, 0, [
		ref(body, '[[Secret|the secret]]', 'the secret', {
			kind: 'note',
			published: false,
			url: null,
		}),
	]);
	assert.equal(out.content, 'See the secret now.');
});

test('rewrites a wikilink image embed and collects the attachment', () => {
	const body = 'Pic: ![[diagram.png]]';
	const out = transformNote(body, 0, [
		ref(body, '![[diagram.png]]', '', {
			kind: 'attachment',
			filename: 'diagram.png',
			width: null,
			height: null,
		}, true),
	]);
	assert.equal(out.content, 'Pic: ![](diagram.png)');
	assert.deepEqual(out.attachments, ['diagram.png']);
});

test('rewrites a markdown image embed carrying alt text', () => {
	const body = 'Pic: ![a chart](chart.png)';
	const out = transformNote(body, 0, [
		ref(body, '![a chart](chart.png)', 'a chart', {
			kind: 'attachment',
			filename: 'chart.png',
			width: null,
			height: null,
		}, true),
	]);
	assert.equal(out.content, 'Pic: ![a chart](chart.png)');
	assert.deepEqual(out.attachments, ['chart.png']);
});

test('writes width and height as a query on the image', () => {
	const widthOnly = transformNote('![[a.png]]', 0, [
		ref('![[a.png]]', '![[a.png]]', '', {
			kind: 'attachment',
			filename: 'a.png',
			width: 96,
			height: null,
		}, true),
	]);
	assert.equal(widthOnly.content, '![](a.png?width=96)');

	const both = transformNote('![[a.png]]', 0, [
		ref('![[a.png]]', '![[a.png]]', 'alt', {
			kind: 'attachment',
			filename: 'a.png',
			width: 96,
			height: 50,
		}, true),
	]);
	assert.equal(both.content, '![alt](a.png?width=96&height=50)');
});

test('parseEmbedDisplay separates alt text from size', () => {
	assert.deepEqual(parseEmbedDisplay('96'), { alt: '', width: 96, height: null });
	assert.deepEqual(parseEmbedDisplay('96x50'), { alt: '', width: 96, height: 50 });
	assert.deepEqual(parseEmbedDisplay('a caption|120'), {
		alt: 'a caption',
		width: 120,
		height: null,
	});
	assert.deepEqual(parseEmbedDisplay('a caption'), {
		alt: 'a caption',
		width: null,
		height: null,
	});
	assert.deepEqual(parseEmbedDisplay(''), { alt: '', width: null, height: null });
});

test('leaves external links untouched', () => {
	const body = 'Go to [Site](https://example.com) and [[Other]].';
	const out = transformNote(body, 0, [
		ref(body, '[[Other]]', 'Other', { kind: 'note', published: true, url: '/blog/other/' }),
	]);
	assert.equal(
		out.content,
		'Go to [Site](https://example.com) and [Other](/blog/other/).',
	);
});

test('applies multiple edits without corrupting offsets', () => {
	const body = '![[a.png]] then [[A|first]] then [[B]]';
	const out = transformNote(body, 0, [
		ref(body, '![[a.png]]', '', {
			kind: 'attachment',
			filename: 'a.png',
			width: null,
			height: null,
		}, true),
		ref(body, '[[A|first]]', 'first', { kind: 'note', published: true, url: '/s/a/' }),
		ref(body, '[[B]]', 'B', { kind: 'note', published: false, url: null }),
	]);
	assert.equal(out.content, '![](a.png) then [first](/s/a/) then B');
	assert.deepEqual(out.attachments, ['a.png']);
});

test('dedupes a repeated attachment', () => {
	const body = '![[a.png]] and again ![[a.png]]';
	const first = body.indexOf('![[a.png]]');
	const second = body.indexOf('![[a.png]]', first + 1);
	const make = (start: number): ResolvedReference => ({
		start,
		end: start + '![[a.png]]'.length,
		isEmbed: true,
		text: '',
		original: '![[a.png]]',
		resolution: { kind: 'attachment', filename: 'a.png', width: null, height: null },
	});
	const out = transformNote(body, 0, [make(first), make(second)]);
	assert.equal(out.content, '![](a.png) and again ![](a.png)');
	assert.deepEqual(out.attachments, ['a.png']);
});

test('strips control keys and configured removals, keeping a quoted date', () => {
	const raw = [
		'---',
		'title: Hello',
		'date: "2026-06-29"',
		'share: true',
		'dest: blog/dv-8',
		'tags: [a, b]',
		'---',
		'',
		'Body here.',
		'',
	].join('\n');
	const fmEnd = raw.indexOf('---', 3) + 3;
	const out = transformNote(raw, fmEnd, []);
	const expected = [
		'---',
		'title: Hello',
		'date: "2026-06-29"',
		'---',
		'',
		'Body here.',
		'',
	].join('\n');
	assert.equal(out.content, expected);
});

test('removes a block style tags property and all its items', () => {
	const raw = [
		'---',
		'title: T',
		'tags:',
		'  - intro',
		'  - notes',
		'date: 2026-01-01',
		'share: true',
		'dest: blog/x',
		'---',
		'',
		'Body.',
		'',
	].join('\n');
	const fmEnd = raw.indexOf('---', 3) + 3;
	const out = transformNote(raw, fmEnd, []);
	const expected = [
		'---',
		'title: T',
		'date: 2026-01-01',
		'---',
		'',
		'Body.',
		'',
	].join('\n');
	assert.equal(out.content, expected);
});

test('transformNote honors a custom frontmatter config', () => {
	const raw = [
		'---',
		'tags: [a]',
		'note: x',
		'share: true',
		'dest: p',
		'---',
		'',
		'B',
		'',
	].join('\n');
	const fmEnd = raw.indexOf('---', 3) + 3;
	const out = transformNote(raw, fmEnd, [], { removeKeys: ['note'], renameKeys: {} });
	const expected = ['---', 'tags: [a]', '---', '', 'B', ''].join('\n');
	assert.equal(out.content, expected);
});

test('renames created to date on export', () => {
	const raw = [
		'---',
		'title: Hello',
		'created: 2026-01-04',
		'share: true',
		'dest: blog/x',
		'---',
		'',
		'Body.',
		'',
	].join('\n');
	const fmEnd = raw.indexOf('---', 3) + 3;
	const out = transformNote(raw, fmEnd, []);
	const expected = [
		'---',
		'title: Hello',
		'date: 2026-01-04',
		'---',
		'',
		'Body.',
		'',
	].join('\n');
	assert.equal(out.content, expected);
});

test('rewriteFrontmatter renames created and keeps the quoted value', () => {
	assert.equal(
		rewriteFrontmatter('---\ncreated: "2026-01-04"\n---', [], { created: 'date' }),
		'---\ndate: "2026-01-04"\n---',
	);
});

test('stripFrontmatterKeys does not touch nested or similarly named keys', () => {
	const raw = ['---', 'published: yes', 'destination: x', '  dest: nested', '---'].join('\n');
	assert.equal(stripFrontmatterKeys(raw, ['publish', 'dest']), raw);
});

test('reconcile removes bundles for unpublished or deleted notes', () => {
	const old = new Manifest();
	old.set('Notes/A.md', new ManifestEntry('blog/a', 'blog/a', ['index.md', 'a.png']));
	const deletion = only(old.reconcile(new Manifest()));
	assert.deepEqual(deletion, {
		bundleDir: 'blog/a',
		files: ['index.md', 'a.png'],
		removeDirIfEmpty: true,
	});
});

test('reconcile removes the old bundle when dest moves', () => {
	const old = new Manifest();
	old.set('Notes/A.md', new ManifestEntry('blog/a', 'blog/a', ['index.md']));
	const next = new Manifest();
	next.set('Notes/A.md', new ManifestEntry('s/a', 's/a', ['index.md']));
	const deletion = only(old.reconcile(next));
	assert.equal(deletion.bundleDir, 'blog/a');
	assert.equal(deletion.removeDirIfEmpty, true);
});

test('reconcile prunes orphan attachments for surviving bundles', () => {
	const old = new Manifest();
	old.set('Notes/A.md', new ManifestEntry('s/a', 's/a', ['index.md', 'old.png']));
	const next = new Manifest();
	next.set('Notes/A.md', new ManifestEntry('s/a', 's/a', ['index.md', 'new.png']));
	const deletion = only(old.reconcile(next));
	assert.deepEqual(deletion, {
		bundleDir: 's/a',
		files: ['old.png'],
		removeDirIfEmpty: false,
	});
});

test('reconcile leaves unchanged bundles alone', () => {
	const old = new Manifest();
	old.set('Notes/A.md', new ManifestEntry('s/a', 's/a', ['index.md']));
	const next = new Manifest();
	next.set('Notes/A.md', new ManifestEntry('s/a', 's/a', ['index.md']));
	assert.deepEqual(old.reconcile(next), []);
});

test('Manifest round-trips through serialize and parse', () => {
	const manifest = new Manifest();
	manifest.set('Notes/A.md', new ManifestEntry('blog/a', 'blog/a', ['index.md', 'a.png']));
	const parsed = Manifest.parse(manifest.serialize());
	const entry = parsed.get('Notes/A.md');
	assert.ok(entry);
	assert.equal(entry.bundleDir, 'blog/a');
	assert.deepEqual(entry.files, ['index.md', 'a.png']);
});

test('Manifest.parse falls back to empty on invalid input', () => {
	assert.deepEqual(Manifest.parse('not json').reconcile(new Manifest()), []);
	assert.equal(Manifest.parse('{}').get('anything'), undefined);
});
