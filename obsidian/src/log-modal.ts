import { App, Modal, Notice, Setting } from 'obsidian';
import { LogInput } from './log';

const TIME_PATTERN = /^\d{1,2}:\d{2}$/;

export class LogModal extends Modal {
	private message = '';
	private place = '';
	private from = '';

	constructor(
		app: App,
		private readonly onSubmit: (input: LogInput) => void,
	) {
		super(app);
	}

	onOpen(): void {
		this.setTitle('Log');
		const { contentEl } = this;

		new Setting(contentEl).setName('Message').addText((text) => {
			text.setPlaceholder('What happened?');
			text.onChange((value) => (this.message = value));
			text.inputEl.addEventListener('keydown', (event) => {
				if (event.key === 'Enter') {
					event.preventDefault();
					this.submit();
				}
			});
			text.inputEl.focus();
		});

		new Setting(contentEl).setName('Place').addText((text) => {
			text.setPlaceholder('Optional');
			text.onChange((value) => (this.place = value));
		});

		new Setting(contentEl).setName('From').addText((text) => {
			text.setPlaceholder('Start time, e.g. 09:30 (optional)');
			text.onChange((value) => (this.from = value));
		});

		new Setting(contentEl).addButton((button) => {
			button
				.setButtonText('Log')
				.setCta()
				.onClick(() => this.submit());
		});
	}

	onClose(): void {
		this.contentEl.empty();
	}

	private submit(): void {
		const message = this.message.trim();
		const from = this.from.trim();
		if (!message) {
			new Notice('Message is required.');
			return;
		}
		if (from && !TIME_PATTERN.test(from)) {
			new Notice('Start time must be a time like 09:30.');
			return;
		}

		this.close();
		this.onSubmit({ message, place: this.place.trim(), from, to: '' });
	}
}
