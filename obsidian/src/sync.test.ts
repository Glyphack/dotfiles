import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
	PublishedNote,
	Resolution,
	ResolvedReference,
	describeError,
	diffBundles,
	expandHome,
	isWikilink,
	linkDisplayText,
	linkpath,
	noteLinkUrl,
	parseEmbedDisplay,
	rewriteFrontmatter,
	shareState,
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
	assert.equal(typo.bundleDir, 'synced/dv-8');
	assert.equal(typo.url, '/synced/dv-8/');

	const bare = new PublishedNote('Notes/D.md', 'dv-8');
	assert.equal(bare.bundleDir, 'synced/dv-8');
	assert.equal(bare.url, '/synced/dv-8/');

	const foreign = new PublishedNote('Notes/E.md', 'notes/dv-8');
	assert.equal(foreign.bundleDir, 'synced/dv-8');
	assert.equal(foreign.url, '/synced/dv-8/');
});

test('noteLinkUrl prefers the published page over source', () => {
	const published = new PublishedNote('Notes/A.md', 'blog/a');
	const source = 'https://example.com/a';

	assert.equal(noteLinkUrl(published, source), '/blog/a/');
	assert.equal(noteLinkUrl(published, null), '/blog/a/');
	assert.equal(noteLinkUrl(undefined, source), source);
	assert.equal(noteLinkUrl(undefined, null), null);
});

test('rewrites a published note link to its url', () => {
	const body = 'See [[Other]] now.';
	const out = transformNote(body, 0, [
		ref(body, '[[Other]]', 'Other', { kind: 'note', url: '/s/other/' }),
	]);
	assert.equal(out.content, 'See [Other](/s/other/) now.');
	assert.deepEqual(out.attachments, []);
});

test('drops a link to an unpublished note down to plain text', () => {
	const body = 'See [[Secret|the secret]] now.';
	const out = transformNote(body, 0, [
		ref(body, '[[Secret|the secret]]', 'the secret', { kind: 'note', url: null }),
	]);
	assert.equal(out.content, 'See the secret now.');
});

test('links an unpublished note to its source address', () => {
	const body = 'See [[External|the write-up]] now.';
	const out = transformNote(body, 0, [
		ref(body, '[[External|the write-up]]', 'the write-up', {
			kind: 'note',
			url: 'https://example.com/write-up',
		}),
	]);
	assert.equal(out.content, 'See [the write-up](https://example.com/write-up) now.');
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

test('linkpath drops the heading and decodes the note path', () => {
	assert.equal(linkpath('other-note#heading'), 'other-note');
	assert.equal(linkpath('other-note#^abc123'), 'other-note');
	assert.equal(linkpath('Some%20Note'), 'Some Note');
	assert.equal(linkpath('#heading'), '');
});

test('linkDisplayText uses the alias only when one was written', () => {
	const text = (original: string, link: string, displayText?: string) =>
		linkDisplayText({ original, link, displayText });

	assert.equal(text('[[other-note]]', 'other-note', 'other-note'), 'other-note');
	assert.equal(
		text('[[other-note#heading]]', 'other-note#heading', 'other-note > heading'),
		'other-note',
	);
	assert.equal(
		text('[[other-note#^abc123]]', 'other-note#^abc123', 'other-note > ^abc123'),
		'other-note',
	);
	assert.equal(text('[[folder/other-note]]', 'folder/other-note'), 'other-note');
	assert.equal(text('![[other-note]]', 'other-note'), 'other-note');

	assert.equal(text('[[other-note|my alias]]', 'other-note', 'my alias'), 'my alias');
	assert.equal(
		text('[[other-note#heading|my alias]]', 'other-note#heading', 'my alias'),
		'my alias',
	);
});

test('rewrites a markdown link to a published note', () => {
	const body = 'See [self feature](Ty%20Self.md) now.';
	const out = transformNote(body, 0, [
		ref(body, '[self feature](Ty%20Self.md)', 'self feature', {
			kind: 'note',
			url: '/blog/ty-self/',
		}),
	]);
	assert.equal(out.content, 'See [self feature](/blog/ty-self/) now.');
});

test('linkDisplayText keeps the text written in a markdown link', () => {
	assert.equal(
		linkDisplayText({
			original: '[self feature](Adding%20Support%20for%20Self%20to%20Ty.md)',
			link: 'Adding Support for Self to Ty.md',
			displayText: 'self feature',
		}),
		'self feature',
	);
});

test('linkDisplayText falls back to the note name when a markdown link has no text', () => {
	assert.equal(
		linkDisplayText({ original: '[](Second%20Note.md)', link: 'Second Note.md' }),
		'Second Note',
	);
});

test('isWikilink only accepts bracket links', () => {
	assert.equal(isWikilink('[[Some Note]]'), true);
	assert.equal(isWikilink('[[Some Note|alias]]'), true);
	assert.equal(isWikilink('![[diagram.png]]'), true);

	assert.equal(isWikilink('[Introduction](#introduction)'), false);
	assert.equal(isWikilink('[Site](https://example.com)'), false);
	assert.equal(isWikilink('[Second Note](Second%20Note.md)'), false);
	assert.equal(isWikilink('![a chart](chart.png)'), false);
});

test('leaves external links untouched', () => {
	const body = 'Go to [Site](https://example.com) and [[Other]].';
	const out = transformNote(body, 0, [
		ref(body, '[[Other]]', 'Other', { kind: 'note', url: '/blog/other/' }),
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
		ref(body, '[[A|first]]', 'first', { kind: 'note', url: '/s/a/' }),
		ref(body, '[[B]]', 'B', { kind: 'note', url: null }),
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

test('strips control keys and keeps every other property', () => {
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
		'tags: [a, b]',
		'---',
		'',
		'Body here.',
		'',
	].join('\n');
	assert.equal(out.content, expected);
});

test('keeps a block style property, and removes it only when configured', () => {
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

	const kept = transformNote(raw, fmEnd, []);
	assert.equal(
		kept.content,
		[
			'---',
			'title: T',
			'tags:',
			'  - intro',
			'  - notes',
			'date: 2026-01-01',
			'---',
			'',
			'Body.',
			'',
		].join('\n'),
	);

	const removed = transformNote(raw, fmEnd, [], {
		removeKeys: ['tags'],
		renameKeys: {},
	});
	assert.equal(
		removed.content,
		['---', 'title: T', 'date: 2026-01-01', '---', '', 'Body.', ''].join('\n'),
	);
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

test('unwraps wikilinks in frontmatter values', () => {
	const raw = [
		'---',
		'title: After Interview',
		'category:',
		'  - "[[Blog]]"',
		'tags: ["[[A]]", "[[B|bee]]"]',
		'ref: "[[Note#Heading]]"',
		'share: true',
		'dest: blog/after-interview',
		'---',
		'',
		'Body keeps its [[Other]] link handling.',
		'',
	].join('\n');
	const fmEnd = raw.indexOf('---', 3) + 3;
	const out = transformNote(raw, fmEnd, []);
	const expected = [
		'---',
		'title: After Interview',
		'category:',
		'  - "Blog"',
		'tags: ["A", "bee"]',
		'ref: "Note"',
		'---',
		'',
		'Body keeps its [[Other]] link handling.',
		'',
	].join('\n');
	assert.equal(out.content, expected);
});

test('leaves frontmatter without wikilinks untouched', () => {
	assert.equal(
		rewriteFrontmatter('---\ntitle: Plain [text] here\n---', [], {}),
		'---\ntitle: Plain [text] here\n---',
	);
});

test('stripFrontmatterKeys does not touch nested or similarly named keys', () => {
	const raw = ['---', 'published: yes', 'destination: x', '  dest: nested', '---'].join('\n');
	assert.equal(stripFrontmatterKeys(raw, ['publish', 'dest']), raw);
});

test('expandHome resolves a leading home marker only', () => {
	const home = '/Users/me';

	assert.equal(expandHome('~/site/content', home), '/Users/me/site/content');
	assert.equal(expandHome('$HOME/site/content', home), '/Users/me/site/content');
	assert.equal(expandHome('${HOME}/site/content', home), '/Users/me/site/content');
	assert.equal(expandHome('  ~/site  ', home), '/Users/me/site');
	assert.equal(expandHome('~', home), home);

	assert.equal(expandHome('/Users/other/site', home), '/Users/other/site');
	assert.equal(expandHome('/opt/$HOME/site', home), '/opt/$HOME/site');
	assert.equal(expandHome('~backup/site', home), '~backup/site');
});

test('describeError keeps the message and adds only missing detail', () => {
	const fsError = Object.assign(
		new Error("EACCES: permission denied, mkdir '/Users/me/site'"),
		{ code: 'EACCES', syscall: 'mkdir', path: '/Users/me/site' },
	);
	assert.equal(describeError(fsError), "EACCES: permission denied, mkdir '/Users/me/site'");

	const terse = Object.assign(new Error('write failed'), {
		code: 'ENOSPC',
		path: '/Users/me/site/index.md',
	});
	assert.equal(
		describeError(terse),
		'write failed (code=ENOSPC, path=/Users/me/site/index.md)',
	);

	assert.equal(describeError('plain string'), 'plain string');
});

test('shareState separates a ready note from one still missing a dest', () => {
	assert.deepEqual(shareState(undefined), { kind: 'unshared' });
	assert.deepEqual(shareState({ title: 'note' }), { kind: 'unshared' });
	assert.deepEqual(shareState({ share: false, dest: 'blog/post' }), {
		kind: 'unshared',
	});
	assert.deepEqual(shareState({ share: true }), { kind: 'incomplete' });
	assert.deepEqual(shareState({ share: true, dest: '   ' }), { kind: 'incomplete' });
	assert.deepEqual(shareState({ share: true, dest: 42 }), { kind: 'incomplete' });
	assert.deepEqual(shareState({ share: true, dest: ' blog/post ' }), {
		kind: 'shared',
		dest: 'blog/post',
	});
});

test('diffBundles flags a folder nobody wants', () => {
	const diff = diffBundles(['blog/a', 'blog/b'], ['blog/a'], ['blog/a']);
	assert.deepEqual(diff.stale, ['blog/b']);
	assert.deepEqual(diff.synced, ['blog/a']);
});

test('diffBundles flags the old folder after a dest change', () => {
	const diff = diffBundles(['blog/old'], ['blog/new'], ['blog/new']);
	assert.deepEqual(diff.stale, ['blog/old']);
	assert.deepEqual(diff.synced, ['blog/new']);
});

test('diffBundles removes nothing when nothing was synced before', () => {
	const diff = diffBundles([], ['blog/a'], ['blog/a']);
	assert.deepEqual(diff.stale, []);
	assert.deepEqual(diff.synced, ['blog/a']);
});

test('diffBundles keeps a wanted folder that this run did not write', () => {
	const diff = diffBundles(['blog/a', 'blog/b'], ['blog/a', 'blog/b'], ['blog/b']);
	assert.deepEqual(diff.stale, []);
	assert.deepEqual(diff.synced.sort(), ['blog/a', 'blog/b']);
});

test('diffBundles drops a wanted folder that was never written', () => {
	const diff = diffBundles([], ['blog/a'], []);
	assert.deepEqual(diff.stale, []);
	assert.deepEqual(diff.synced, []);
});
