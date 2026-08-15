import { test } from 'node:test';
import assert from 'node:assert/strict';
import { lastFocusSession } from './continue-focus';

const TODAY = '# [[2026-08-03]]';

test('picks the last focus session of the day', () => {
	const content = [
		'# [[2026-08-03]]',
		'',
		'09:00 AM-09:30 AM > #focus-session Programming: fixing auth bug',
		'10:00 AM-10:45 AM > #focus-session Reading: chapter 3',
		'',
	].join('\n');
	assert.deepEqual(lastFocusSession(content, TODAY), {
		category: 'reading',
		duration: 45,
		message: 'chapter 3',
	});
});

test('computes duration across the noon boundary', () => {
	const content = [
		'# [[2026-08-03]]',
		'',
		'11:30 AM-01:15 PM > #focus-session Work: standup and review',
		'',
	].join('\n');
	assert.deepEqual(lastFocusSession(content, TODAY), {
		category: 'work',
		duration: 105,
		message: 'standup and review',
	});
});

test('computes duration across the midnight boundary', () => {
	const content = [
		'# [[2026-08-03]]',
		'',
		'11:00 PM-12:30 AM > #focus-session Work: late night',
		'',
	].join('\n');
	assert.deepEqual(lastFocusSession(content, TODAY), {
		category: 'work',
		duration: 90,
		message: 'late night',
	});
});

test('returns an empty message when the session has none', () => {
	const content = [
		'# [[2026-08-03]]',
		'',
		'01:15 PM-02:00 PM > #focus-session Reading',
		'',
	].join('\n');
	assert.deepEqual(lastFocusSession(content, TODAY), {
		category: 'reading',
		duration: 45,
		message: '',
	});
});

test('falls back to the lowercased goal for an unknown category', () => {
	const content = [
		'# [[2026-08-03]]',
		'',
		'09:00 AM-09:30 AM > #focus-session Gardening: pull weeds',
		'',
	].join('\n');
	assert.deepEqual(lastFocusSession(content, TODAY), {
		category: 'gardening',
		duration: 30,
		message: 'pull weeds',
	});
});

test('returns null when the day has no focus session', () => {
	const content = [
		'# [[2026-08-03]]',
		'',
		'09:00 AM > woke up',
		'10:00 AM > coffee',
		'',
	].join('\n');
	assert.equal(lastFocusSession(content, TODAY), null);
});

test('returns null when the note has no matching day', () => {
	const content = [
		'# [[2026-08-01]]',
		'',
		'09:00 AM-09:30 AM > #focus-session Programming: old work',
		'',
	].join('\n');
	assert.equal(lastFocusSession(content, TODAY), null);
});

test('ignores focus sessions from other days', () => {
	const content = [
		'# [[2026-08-02]]',
		'',
		'09:00 AM-09:30 AM > #focus-session Programming: yesterday work',
		'',
		'# [[2026-08-03]]',
		'',
		'10:00 AM-10:30 AM > #focus-session Reading: today reading',
		'',
	].join('\n');
	assert.deepEqual(lastFocusSession(content, TODAY), {
		category: 'reading',
		duration: 30,
		message: 'today reading',
	});
});

test('does not leak a focus session from the previous day', () => {
	const content = [
		'# [[2026-08-02]]',
		'',
		'09:00 AM-09:30 AM > #focus-session Programming: yesterday work',
		'',
		'# [[2026-08-03]]',
		'',
		'10:00 AM > note only',
		'',
	].join('\n');
	assert.equal(lastFocusSession(content, TODAY), null);
});
