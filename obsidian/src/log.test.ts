import { test } from 'node:test';
import assert from 'node:assert/strict';
import { LogEntry, WeeklyLog } from './log';

const TODAY = '# [[2026-08-03]]';

function at(hour: number, minute: number, message: string): LogEntry {
	return new LogEntry(message, null, new Date(2026, 7, 3, hour, minute, 0, 0), null);
}

function logAll(lines: string[], ...entries: LogEntry[]): string {
	const note = new WeeklyLog(lines.join('\n'));
	for (const entry of entries) {
		note.insert(TODAY, entry);
	}
	return note.toString();
}

test('a new day starts with the separator above the first log', () => {
	const result = logAll(
		['# To-do', '', '# [[2026-08-02]]', '', 'old note', ''],
		at(9, 0, 'woke up'),
	);
	assert.equal(
		result,
		[
			'# To-do',
			'',
			'# [[2026-08-03]]',
			'',
			'***',
			'',
			'09:00 AM > woke up',
			'',
			'# [[2026-08-02]]',
			'',
			'old note',
			'',
		].join('\n'),
	);
});

test('the separator is added once below notes that are already there', () => {
	const result = logAll(
		['# [[2026-08-03]]', '', 'a note', 'another line', ''],
		at(9, 0, 'woke up'),
		at(10, 0, 'coffee'),
	);
	assert.equal(
		result,
		[
			'# [[2026-08-03]]',
			'',
			'a note',
			'another line',
			'',
			'***',
			'',
			'09:00 AM > woke up',
			'10:00 AM > coffee',
			'',
		].join('\n'),
	);
});

test('logs go to the bottom of the day, not into the next day', () => {
	const result = logAll(
		[
			'# [[2026-08-03]]',
			'',
			'a note',
			'',
			'***',
			'',
			'09:00 AM > woke up',
			'',
			'',
			'# [[2026-08-02]]',
			'',
			'old note',
			'',
		],
		at(10, 0, 'coffee'),
	);
	assert.equal(
		result,
		[
			'# [[2026-08-03]]',
			'',
			'a note',
			'',
			'***',
			'',
			'09:00 AM > woke up',
			'10:00 AM > coffee',
			'',
			'',
			'# [[2026-08-02]]',
			'',
			'old note',
			'',
		].join('\n'),
	);
});

test('a day from the weekly template gets the separator under its header', () => {
	const result = logAll(
		['---', 'created: "2026-08-03"', 'tags:', '---', '# To-do', '', '# 2026-08-03'],
		at(9, 0, 'woke up'),
	);
	assert.equal(
		result,
		[
			'---',
			'created: "2026-08-03"',
			'tags:',
			'---',
			'# To-do',
			'',
			'# 2026-08-03',
			'',
			'***',
			'',
			'09:00 AM > woke up',
			'',
		].join('\n'),
	);
});

test('another day with a separator does not count for today', () => {
	const result = logAll(
		[
			'# [[2026-08-03]]',
			'',
			'a note',
			'',
			'# [[2026-08-02]]',
			'',
			'***',
			'',
			'09:00 AM > old log',
			'',
		],
		at(10, 0, 'coffee'),
	);
	assert.equal(
		result,
		[
			'# [[2026-08-03]]',
			'',
			'a note',
			'',
			'***',
			'',
			'10:00 AM > coffee',
			'',
			'# [[2026-08-02]]',
			'',
			'***',
			'',
			'09:00 AM > old log',
			'',
		].join('\n'),
	);
});

test('a note typed below the logs stays below the next log', () => {
	const result = logAll(
		['# [[2026-08-03]]', '', '***', '', '09:00 AM > woke up', '', 'a note', ''],
		at(10, 0, 'coffee'),
	);
	assert.equal(
		result,
		[
			'# [[2026-08-03]]',
			'',
			'***',
			'',
			'09:00 AM > woke up',
			'10:00 AM > coffee',
			'',
			'a note',
			'',
		].join('\n'),
	);
});

test('a note right under a timed log with a place stays below the next log', () => {
	const result = logAll(
		['# [[2026-08-03]]', '', '***', '', '09:00 AM-09:30 AM > run place: park', 'a note', ''],
		at(10, 0, 'coffee'),
	);
	assert.equal(
		result,
		[
			'# [[2026-08-03]]',
			'',
			'***',
			'',
			'09:00 AM-09:30 AM > run place: park',
			'10:00 AM > coffee',
			'a note',
			'',
		].join('\n'),
	);
});
