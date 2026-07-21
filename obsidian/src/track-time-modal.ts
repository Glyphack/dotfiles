import { App, Modal, Notice, Setting } from 'obsidian';
import {
	DEFAULT_CATEGORY,
	DEFAULT_DURATION_MIN,
	TRACK_TIME_CATEGORIES,
	TrackTimeInput,
	TrackTimeSession,
} from './track-time';

export class TrackTimeModal extends Modal {
	private category = DEFAULT_CATEGORY;
	private duration = String(DEFAULT_DURATION_MIN);
	private message = '';
	private preview!: HTMLElement;

	constructor(
		app: App,
		private readonly onSubmit: (input: TrackTimeInput) => void,
	) {
		super(app);
	}

	onOpen(): void {
		this.setTitle('Track time');
		const { contentEl } = this;

		new Setting(contentEl).setName('Category').addDropdown((dropdown) => {
			for (const category of TRACK_TIME_CATEGORIES) {
				dropdown.addOption(category.value, category.goal);
			}
			dropdown.setValue(this.category);
			dropdown.onChange((value) => {
				this.category = value;
				this.renderPreview();
			});
		});

		new Setting(contentEl).setName('Duration (minutes)').addText((text) => {
			text.setPlaceholder(String(DEFAULT_DURATION_MIN));
			text.setValue(this.duration);
			text.onChange((value) => {
				this.duration = value;
				this.renderPreview();
			});
		});

		new Setting(contentEl).setName('Message').addText((text) => {
			text.setPlaceholder('What are you focusing on?');
			text.onChange((value) => {
				this.message = value;
				this.renderPreview();
			});
			text.inputEl.addEventListener('keydown', (event) => {
				if (event.key === 'Enter') {
					event.preventDefault();
					this.submit();
				}
			});
			text.inputEl.focus();
		});

		this.preview = contentEl.createDiv({ cls: 'dots-track-time-preview' });

		new Setting(contentEl).addButton((button) => {
			button
				.setButtonText('Start')
				.setCta()
				.onClick(() => this.submit());
		});

		this.renderPreview();
	}

	onClose(): void {
		this.contentEl.empty();
	}

	private renderPreview(): void {
		this.preview.empty();
		const session = this.session();
		if (!session) {
			this.preview.setText('Enter a positive number of minutes.');
			return;
		}

		this.preview.createEl('div', {
			cls: 'dots-track-time-preview-line',
			text: session.logEntry().format(),
		});
	}

	private session(): TrackTimeSession | null {
		const duration = this.parseDuration();
		if (duration === null) {
			return null;
		}

		return new TrackTimeSession(
			this.category,
			duration,
			this.message.trim(),
			new Date(),
		);
	}

	private parseDuration(): number | null {
		const raw = this.duration.trim();
		if (!raw) {
			return DEFAULT_DURATION_MIN;
		}

		const value = Number(raw);
		if (!Number.isInteger(value) || value <= 0) {
			return null;
		}
		return value;
	}

	private submit(): void {
		const duration = this.parseDuration();
		if (duration === null) {
			new Notice('Duration must be a positive whole number of minutes.');
			return;
		}

		this.close();
		this.onSubmit({
			category: this.category,
			duration,
			message: this.message.trim(),
		});
	}
}
