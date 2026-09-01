import { Debouncer, Notice, Platform, TAbstractFile, TFile, debounce } from 'obsidian';
import { HugoSync } from './hugo-sync';
import { describeError } from './sync';

const FLUSH_DELAY_MS = 3000;
const NOTICE_MS = 15000;

export class AutoPublisher {
	private readonly pending = new Set<string>();
	private readonly schedule: Debouncer<[], void>;
	private draining = false;

	constructor(
		private readonly sync: HugoSync,
		private readonly isEnabled: () => boolean,
	) {
		this.schedule = debounce(() => this.drain(), FLUSH_DELAY_MS, true);
	}

	queue(file: TAbstractFile): void {
		if (!this.isEnabled() || !Platform.isDesktopApp) {
			return;
		}
		if (!(file instanceof TFile) || file.extension !== 'md') {
			return;
		}
		this.pending.add(file.path);
		this.schedule();
	}

	private drain(): void {
		if (this.draining) {
			this.schedule();
			return;
		}
		this.draining = true;
		void this.publishPending().finally(() => {
			this.draining = false;
		});
	}

	private async publishPending(): Promise<void> {
		while (this.pending.size > 0) {
			const paths = Array.from(this.pending);
			this.pending.clear();
			for (const path of paths) {
				await this.publish(path);
			}
		}
	}

	private async publish(path: string): Promise<void> {
		try {
			await this.sync.publishOne(path);
		} catch (error) {
			console.error(`Auto publish: ${path}`, error);
			new Notice(`Failed to publish ${path}: ${describeError(error)}`, NOTICE_MS);
		}
	}
}
