import { requestUrl } from 'obsidian';

export interface NtfyConfig {
	server: string;
	topic: string;
}

export interface ScheduledNotification {
	title: string;
	body: string;
	delay: string;
}

export async function sendScheduledNotification(
	config: NtfyConfig,
	notification: ScheduledNotification,
): Promise<void> {
	const server = config.server.trim().replace(/\/+$/, '');
	await requestUrl({
		url: `${server}/${encodeURIComponent(config.topic)}`,
		method: 'POST',
		body: notification.body,
		headers: {
			Title: notification.title,
			In: notification.delay,
		},
	});
}
