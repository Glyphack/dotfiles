import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFile } from 'child_process';
import { promises as fs } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { promisify } from 'util';
import { deflateSync } from 'zlib';
import {
	EXIFTOOL_MISSING,
	ExifTool,
	RemovalReport,
	invocationError,
	parseScans,
	parseStripErrors,
} from './image';

const execFileAsync = promisify(execFile);

const GPS_IMAGE_URL =
	'https://raw.githubusercontent.com/ianare/exif-py/master/tests/resources/jpg/gps/DSCN0010.jpg';

const XMP_SVG =
	'<svg xmlns="http://www.w3.org/2000/svg"><metadata>' +
	'<x:xmpmeta xmlns:x="adobe:ns:meta/">' +
	'<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">' +
	'<rdf:Description xmlns:dc="http://purl.org/dc/elements/1.1/">' +
	'<dc:creator><rdf:Seq><rdf:li>SECRETCREATOR</rdf:li></rdf:Seq></dc:creator>' +
	'</rdf:Description></rdf:RDF></x:xmpmeta>' +
	'</metadata><rect width="1" height="1"/></svg>';

test('parseScans classifies images, metadata, and errors', () => {
	const stdout = JSON.stringify([
		{ SourceFile: '/v/clean.jpg', 'File:MIMEType': 'image/jpeg' },
		{
			SourceFile: '/v/gps.jpg',
			'File:MIMEType': 'image/jpeg',
			'EXIF:GPSLatitude': "43 deg 28' 2.81\" N",
			'EXIF:Model': 'COOLPIX P6000',
		},
		{ SourceFile: '/v/note.md', 'File:MIMEType': 'text/plain' },
		{
			SourceFile: '/v/broken.jpg',
			'File:MIMEType': 'image/jpeg',
			'ExifTool:Error': 'File format error',
		},
		{
			SourceFile: '/v/text.png',
			'File:MIMEType': 'image/png',
			'PNG:Author': 'someone',
		},
	]);
	const scans = parseScans(stdout);
	assert.equal(scans.length, 5);

	const [clean, gps, note, broken, png] = scans;
	assert.ok(clean && gps && note && broken && png);

	assert.ok(clean.isImage);
	assert.equal(clean.dirty, false);
	assert.equal(clean.error, null);

	assert.ok(gps.dirty);
	assert.deepEqual(gps.metadataKeys, ['EXIF:GPSLatitude', 'EXIF:Model']);

	assert.equal(note.isImage, false);

	assert.ok(broken.isImage);
	assert.equal(broken.dirty, false);
	assert.equal(broken.error, 'File format error');

	assert.ok(png.isImage);
	assert.deepEqual(png.metadataKeys, ['PNG:Author']);
});

test('parseScans returns nothing for empty or invalid output', () => {
	assert.deepEqual(parseScans(''), []);
	assert.deepEqual(parseScans('not json'), []);
	assert.deepEqual(parseScans('{"SourceFile":"x"}'), []);
});

test('parseStripErrors maps error lines to paths and skips other lines', () => {
	const stderr = [
		'Error: ExifTool does not yet support writing of SVG images - /v/logo - final.svg',
		'Warning: [minor] Fixed incorrect URI - /v/other.jpg',
		'    1 image files updated',
	].join('\n');
	const errors = parseStripErrors(stderr);
	assert.equal(errors.size, 1);
	assert.equal(
		errors.get('/v/logo - final.svg'),
		'ExifTool does not yet support writing of SVG images',
	);
});

test('RemovalReport.describe summarizes counts', () => {
	const report = new RemovalReport(
		['/v/a.pdf'],
		['/v/b.png'],
		['/v/c.jpg', '/v/d.jpg'],
		[{ path: '/v/e.svg', reason: 'nope' }],
	);
	assert.equal(
		report.describe(),
		'EXIF removal: cleaned 2, already clean 1, skipped 1 non-images, failed 1.',
	);
});

test('invocationError shows the command, the output, and hides long path lists', () => {
	const error = Object.assign(new Error('exiftool exited with signal SIGKILL'), {
		stderr: 'something went wrong\n',
		stdout: '',
	});
	const paths = ['/v/a 1.png', '/v/b.png', '/v/c.png', '/v/d.png', '/v/e.png', '/v/f.png'];
	const wrapped = invocationError(error, 'exiftool', ['-json', '-a'], paths);

	const [headline, command, output] = wrapped.message.split('\n');
	assert.equal(headline, 'exiftool failed: exiftool exited with signal SIGKILL');
	assert.equal(
		command,
		"command: exiftool -json -a '/v/a 1.png' /v/b.png /v/c.png /v/d.png /v/e.png (and 1 more)",
	);
	assert.equal(output, 'output: something went wrong');
});

test('invocationError leaves the missing exiftool error unchanged', () => {
	const missing = new Error(EXIFTOOL_MISSING);
	assert.equal(invocationError(missing, 'exiftool', [], []), missing);
});

const EXIFTOOL_CANDIDATES = [
	'exiftool',
	'/opt/homebrew/bin/exiftool',
	'/usr/local/bin/exiftool',
];

async function readTags(path: string): Promise<Record<string, unknown>> {
	for (const binary of EXIFTOOL_CANDIDATES) {
		try {
			const { stdout } = await execFileAsync(binary, ['-json', '-a', '-G0', path]);
			const entries = JSON.parse(stdout) as Record<string, unknown>[];
			return entries[0] ?? {};
		} catch {
			continue;
		}
	}
	throw new Error('exiftool not available to verify results');
}

function sensitiveKeys(tags: Record<string, unknown>): string[] {
	const prefixes = ['EXIF:', 'XMP:', 'IPTC:', 'MakerNotes:', 'Photoshop:'];
	const allowed = new Set(['EXIF:Orientation', 'EXIF:YCbCrPositioning']);
	return Object.keys(tags).filter(
		(key) =>
			prefixes.some((prefix) => key.startsWith(prefix)) && !allowed.has(key),
	);
}

test('end to end: cleans a real photo with GPS and device metadata', async (t) => {
	const tool = new ExifTool();
	if (!(await tool.available())) {
		t.skip('exiftool is not installed');
		return;
	}
	const dir = await fs.mkdtemp(join(tmpdir(), 'dots-image-e2e-'));
	try {
		const response = await fetch(GPS_IMAGE_URL);
		assert.ok(response.ok, `download failed with status ${response.status}`);
		const photo = join(dir, 'photo.jpg');
		await fs.writeFile(photo, new Uint8Array(await response.arrayBuffer()));

		const before = await readTags(photo);
		assert.ok(before['EXIF:GPSLatitude'], 'sample should carry GPS data');
		assert.ok(before['EXIF:Model'], 'sample should carry a device model');

		const report = await tool.removeMetadata([photo]);
		assert.deepEqual(report.failures, []);
		assert.deepEqual(report.cleaned, [photo]);

		const after = await readTags(photo);
		assert.deepEqual(sensitiveKeys(after), []);
		assert.ok(after['File:ImageWidth'], 'image should still decode');

		const again = await tool.removeMetadata([photo]);
		assert.deepEqual(again.cleaned, []);
		assert.deepEqual(again.alreadyClean, [photo]);
		assert.deepEqual(again.failures, []);
	} finally {
		await fs.rm(dir, { recursive: true, force: true });
	}
});

function crc32(bytes: Uint8Array): number {
	let crc = 0xffffffff;
	for (const byte of bytes) {
		crc ^= byte;
		for (let bit = 0; bit < 8; bit++) {
			crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
		}
	}
	return (crc ^ 0xffffffff) >>> 0;
}

function pngChunk(type: string, payload: number[]): number[] {
	const body = [...Array.from(type, (ch) => ch.charCodeAt(0)), ...payload];
	const crc = crc32(Uint8Array.from(body));
	const length = payload.length;
	return [
		(length >>> 24) & 0xff,
		(length >>> 16) & 0xff,
		(length >>> 8) & 0xff,
		length & 0xff,
		...body,
		(crc >>> 24) & 0xff,
		(crc >>> 16) & 0xff,
		(crc >>> 8) & 0xff,
		crc & 0xff,
	];
}

function buildPng(extraChunks: number[][]): Uint8Array {
	const idat = Array.from(deflateSync(Uint8Array.from([0, 0, 255, 0])));
	return Uint8Array.from([
		0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
		...pngChunk('IHDR', [0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0]),
		...extraChunks.flat(),
		...pngChunk('IDAT', idat),
		...pngChunk('IEND', []),
	]);
}

const IDOT_CHUNK = pngChunk('iDOT', new Array<number>(28).fill(0));
const TEXT_CHUNK = pngChunk(
	'tEXt',
	Array.from('Author\0someone', (ch) => ch.charCodeAt(0)),
);

test('end to end: apple decoding hints in png do not count as metadata', async (t) => {
	const tool = new ExifTool();
	if (!(await tool.available())) {
		t.skip('exiftool is not installed');
		return;
	}
	const dir = await fs.mkdtemp(join(tmpdir(), 'dots-image-e2e-'));
	try {
		const hintsOnly = join(dir, 'hints-only.png');
		await fs.writeFile(hintsOnly, buildPng([IDOT_CHUNK]));
		const hintsAndText = join(dir, 'hints-and-text.png');
		await fs.writeFile(hintsAndText, buildPng([IDOT_CHUNK, TEXT_CHUNK]));

		const report = await tool.removeMetadata([hintsOnly, hintsAndText]);
		assert.deepEqual(report.failures, []);
		assert.deepEqual(report.alreadyClean, [hintsOnly]);
		assert.deepEqual(report.cleaned, [hintsAndText]);

		const after = await readTags(hintsAndText);
		assert.equal(after['PNG:Author'], undefined);
		assert.ok(after['PNG:AppleDataOffsets']);
	} finally {
		await fs.rm(dir, { recursive: true, force: true });
	}
});

test('end to end: skips non-images and fails files it cannot clean', async (t) => {
	const tool = new ExifTool();
	if (!(await tool.available())) {
		t.skip('exiftool is not installed');
		return;
	}
	const dir = await fs.mkdtemp(join(tmpdir(), 'dots-image-e2e-'));
	try {
		const note = join(dir, 'note.md');
		await fs.writeFile(note, '# hello\n', 'utf8');
		const svg = join(dir, 'tagged.svg');
		await fs.writeFile(svg, XMP_SVG, 'utf8');

		const report = await tool.removeMetadata([note, svg]);
		assert.deepEqual(report.skipped, [note]);
		assert.deepEqual(report.cleaned, []);
		assert.equal(report.failures.length, 1);
		const failure = report.failures[0];
		assert.ok(failure);
		assert.equal(failure.path, svg);
		assert.match(failure.reason, /SVG/);
	} finally {
		await fs.rm(dir, { recursive: true, force: true });
	}
});
