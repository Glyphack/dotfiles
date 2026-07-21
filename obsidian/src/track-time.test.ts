import { test } from 'node:test';
import assert from 'node:assert/strict';
import { TrackTimeSession } from './track-time';

function at(hour: number, minute: number): Date {
	return new Date(2026, 6, 15, hour, minute, 0, 0);
}

test('maps a known category to its goal and formats the log entry', () => {
	const session = new TrackTimeSession('programming', 30, 'fixing auth bug', at(9, 0));
	assert.equal(session.goal, 'Programming');
	assert.equal(
		session.logEntry().format(),
		'09:00 AM-09:30 AM > #focus-session Programming: fixing auth bug',
	);
});

test('drops the message suffix when there is no message', () => {
	const session = new TrackTimeSession('reading', 45, '', at(13, 15));
	assert.equal(
		session.logEntry().format(),
		'01:15 PM-02:00 PM > #focus-session Reading',
	);
});

test('falls back to Focus for an unknown category', () => {
	const session = new TrackTimeSession('gardening', 30, '', at(9, 0));
	assert.equal(session.goal, 'Focus');
});

test('computes the end time from the duration', () => {
	const session = new TrackTimeSession('work', 90, '', at(10, 0));
	assert.deepEqual(session.end, at(11, 30));
});

test('builds a delayed reminder carrying the message', () => {
	const session = new TrackTimeSession('programming', 30, 'fixing auth bug', at(9, 0));
	assert.deepEqual(session.reminder(), {
		title: 'Programming',
		body: 'Time is up: fixing auth bug',
		delay: '30min',
	});
});

test('reminder falls back to a plain body without a message', () => {
	const session = new TrackTimeSession('reading', 45, '', at(9, 0));
	assert.deepEqual(session.reminder(), {
		title: 'Reading',
		body: 'Time is up',
		delay: '45min',
	});
});

test('builds a raycast focus url with category blocks', () => {
	const session = new TrackTimeSession('writing', 25, 'draft post', at(9, 0));
	assert.equal(
		session.raycastUrl(),
		'raycast://focus/start?goal=Writing&duration=1500&mode=block&categories=writing-coding',
	);
});

test('omits categories for a goal without focus blocks', () => {
	const session = new TrackTimeSession('work', 30, '', at(9, 0));
	assert.equal(
		session.raycastUrl(),
		'raycast://focus/start?goal=Work&duration=1800&mode=block',
	);
});
