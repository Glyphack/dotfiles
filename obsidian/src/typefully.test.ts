import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { RequestUrlParam, RequestUrlResponse } from 'obsidian';
import { Typefully } from './typefully';

test('createXDraft posts a draft with no publish time to the first social set', async () => {
	const sent: RequestUrlParam[] = [];
	const request = (param: RequestUrlParam) => {
		sent.push(param);
		return Promise.resolve({ json: { results: [{ id: 7 }, { id: 8 }] } } as RequestUrlResponse);
	};

	await new Typefully('key-1', request).createXDraft('hello');

	assert.equal(sent.length, 2);
	assert.equal(sent[0]?.url, 'https://api.typefully.com/v2/social-sets');
	assert.deepEqual(sent[0]?.headers, { Authorization: 'Bearer key-1' });
	assert.equal(sent[1]?.url, 'https://api.typefully.com/v2/social-sets/7/drafts');
	assert.equal(sent[1]?.method, 'POST');
	assert.equal(sent[1]?.contentType, 'application/json');
	assert.deepEqual(sent[1]?.headers, { Authorization: 'Bearer key-1' });
	assert.deepEqual(JSON.parse(sent[1]?.body as string), {
		platforms: { x: { enabled: true, posts: [{ text: 'hello' }] } },
	});
});

test('createXDraft fails when the account has no social set', async () => {
	const request = () => Promise.resolve({ json: { results: [] } } as unknown as RequestUrlResponse);
	await assert.rejects(new Typefully('key-1', request).createXDraft('hello'), {
		message: 'No social set found in Typefully.',
	});
});
