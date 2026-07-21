import { App, Modal } from 'obsidian';
import { PUBLISH_KEY, PublishedResult, SyncSummary } from './sync';

export class SyncSummaryModal extends Modal {
	constructor(
		app: App,
		private readonly summary: SyncSummary,
	) {
		super(app);
	}

	onOpen(): void {
		this.setTitle('Publish summary');
		const { summary } = this;

		if (
			summary.published.length === 0 &&
			summary.skipped.length === 0 &&
			summary.removed.length === 0
		) {
			this.contentEl.createEl('p', { text: `No notes had ${PUBLISH_KEY}: true.` });
			return;
		}

		this.renderPublished();
		this.renderSkipped();
		this.renderRemoved();
	}

	onClose(): void {
		this.contentEl.empty();
	}

	private renderPublished(): void {
		const items = this.summary.published;
		if (items.length === 0) {
			return;
		}
		this.contentEl.createEl('h3', { text: `Published (${items.length})` });
		const list = this.contentEl.createEl('ul');
		for (const item of items) {
			list.createEl('li', { text: describeItem(item) });
		}
	}

	private renderSkipped(): void {
		const items = this.summary.skipped;
		if (items.length === 0) {
			return;
		}
		this.contentEl.createEl('h3', {
			text: `Skipped, no ${DEST_LABEL} (${items.length})`,
		});
		const list = this.contentEl.createEl('ul');
		for (const path of items) {
			list.createEl('li', { text: path });
		}
	}

	private renderRemoved(): void {
		const items = this.summary.removed;
		if (items.length === 0) {
			return;
		}
		this.contentEl.createEl('h3', { text: `Removed (${items.length})` });
		const list = this.contentEl.createEl('ul');
		for (const item of items) {
			list.createEl('li', { text: `${item.path} (/${item.bundleDir}/)` });
		}
	}
}

const DEST_LABEL = 'destination';

function describeItem(item: PublishedResult): string {
	if (item.action === 'failed') {
		return `${item.path}: failed, ${item.detail ?? 'unknown error'}`;
	}
	if (item.detail) {
		return `${item.path}: ${item.action} at ${item.url}, ${item.detail}`;
	}
	return `${item.path}: ${item.action} at ${item.url}`;
}
