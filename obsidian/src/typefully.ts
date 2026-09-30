import type { RequestUrlParam, RequestUrlResponse } from 'obsidian';

const API = 'https://api.typefully.com/v2';

type SendRequest = (request: RequestUrlParam) => Promise<RequestUrlResponse>;

interface SocialSetList {
	results: { id: number }[];
}

export class Typefully {
	constructor(
		private readonly apiKey: string,
		private readonly request: SendRequest,
	) {}

	async createXDraft(text: string): Promise<void> {
		const socialSet = await this.firstSocialSet();
		await this.request({
			url: `${API}/social-sets/${socialSet}/drafts`,
			method: 'POST',
			headers: this.headers(),
			contentType: 'application/json',
			body: JSON.stringify({ platforms: { x: { enabled: true, posts: [{ text }] } } }),
		});
	}

	private async firstSocialSet(): Promise<number> {
		const response = await this.request({ url: `${API}/social-sets`, headers: this.headers() });
		const id = (response.json as SocialSetList).results[0]?.id;
		if (id === undefined) {
			throw new Error('No social set found in Typefully.');
		}
		return id;
	}

	private headers(): Record<string, string> {
		return { Authorization: `Bearer ${this.apiKey}` };
	}
}
