import { Notice, Platform, Plugin } from 'obsidian';
import { Extension } from '@codemirror/state';
import { LogEntry, LogInput } from './log';
import { LogModal } from './log-modal';
import { TrackTimeInput, TrackTimeSession } from './track-time';
import { TrackTimeModal } from './track-time-modal';
import { WeeklyNote } from './weekly-note';
import { sendScheduledNotification } from './ntfy';
import { todayStamp } from './dates';
import { ensureFolder, ensureNote } from './vault';
import { DEFAULT_SETTINGS, DotsSettings, DotsSettingTab } from './settings';
import { HugoSync } from './hugo-sync';
import { typewriterScroll } from './typewriter';

const DAILY_FOLDER = 'Daily';

export default class DotsPlugin extends Plugin {
	settings!: DotsSettings;
	private hugoSync!: HugoSync;
	private weeklyNote!: WeeklyNote;
	private typewriterExtension: Extension[] = [];

	async onload() {
		this.settings = Object.assign(
			{},
			DEFAULT_SETTINGS,
			(await this.loadData()) as Partial<DotsSettings>,
		);
		this.hugoSync = new HugoSync(this.app, () => this.settings);
		this.weeklyNote = new WeeklyNote(this.app);
		this.addSettingTab(new DotsSettingTab(this.app, this));

		this.addCommand({
			id: 'open-weekly-note',
			name: 'Open weekly note',
			callback: () => this.openWeeklyNote(),
		});
		this.registerObsidianProtocolHandler('dots-log', (params) => {
			const input: LogInput = {
				message: params.message ?? '',
				place: params.place ?? '',
				from: params.from ?? '',
				to: params.to ?? '',
			};
			if (!input.message) {
				new Notice('Log message is required.');
				return;
			}
			this.log(input).catch((error) => {
				new Notice(`Failed to log: ${message(error)}`);
			});
		});
		this.addCommand({
			id: 'log',
			name: 'Log',
			callback: () => {
				new LogModal(this.app, (input) => {
					this.log(input).catch((error) => {
						new Notice(`Failed to log: ${message(error)}`);
					});
				}).open();
			},
		});
		this.addCommand({
			id: 'track-time',
			name: 'Track time',
			callback: () => {
				new TrackTimeModal(this.app, (input) => {
					this.trackTime(input).catch((error) => {
						new Notice(`Failed to track time: ${message(error)}`);
					});
				}).open();
			},
		});
		this.addCommand({
			id: 'publish-notes',
			name: 'Publish notes',
			callback: () => this.syncToHugo(),
		});
		this.registerEditorExtension(this.typewriterExtension);
		this.applyTypewriterMode();
		this.addCommand({
			id: 'toggle-typewriter-mode',
			name: 'Toggle typewriter mode',
			callback: () => {
				this.toggleTypewriterMode().catch((error) => {
					new Notice(`Failed to toggle typewriter mode: ${message(error)}`);
				});
			},
		});
		this.addRibbonIcon('upload-cloud', 'Publish notes', () => this.syncToHugo());
		this.app.workspace.onLayoutReady(async () => {
			try {
				await this.createTodayNote();
			} catch (error) {
				new Notice(`Failed to create today's note: ${message(error)}`);
			}
		});
	}

	onunload() {}

	async saveSettings() {
		await this.saveData(this.settings);
	}

	syncToHugo() {
		if (!Platform.isDesktopApp) {
			new Notice('Publishing notes is only available on desktop.');
			return;
		}
		this.hugoSync.run().catch((error) => {
			new Notice(`Failed to publish notes: ${message(error)}`);
		});
	}

	async openWeeklyNote() {
		await this.weeklyNote.open();
	}

	async toggleTypewriterMode() {
		this.settings.typewriterMode = !this.settings.typewriterMode;
		await this.saveSettings();
		this.applyTypewriterMode();
		new Notice(`Typewriter mode ${this.settings.typewriterMode ? 'on' : 'off'}.`);
	}

	private applyTypewriterMode() {
		this.typewriterExtension.length = 0;
		if (this.settings.typewriterMode) {
			this.typewriterExtension.push(typewriterScroll());
		}
		this.app.workspace.updateOptions();
	}

	async log(input: LogInput) {
		const entry = LogEntry.fromInput(input, new Date());
		await this.weeklyNote.append(entry);
		new Notice('Logged to weekly note.');
	}

	async trackTime(input: TrackTimeInput) {
		const session = new TrackTimeSession(
			input.category,
			input.duration,
			input.message,
			new Date(),
		);
		await this.weeklyNote.append(session.logEntry());
		new Notice(`Tracking ${session.goal} for ${session.durationMin} min.`);
		this.startFocusSession(session);
		await this.scheduleReminder(session);
	}

	private startFocusSession(session: TrackTimeSession) {
		if (!Platform.isDesktopApp) {
			return;
		}
		const { shell } = require('electron') as {
			shell: { openExternal(url: string): Promise<void> };
		};
		void shell.openExternal(session.raycastUrl());
	}

	private async scheduleReminder(session: TrackTimeSession) {
		const topic = this.settings.ntfyTopic.trim();
		if (!topic) {
			return;
		}
		try {
			await sendScheduledNotification(
				{ server: this.settings.ntfyServer, topic },
				session.reminder(),
			);
		} catch (error) {
			new Notice(`Failed to schedule reminder: ${message(error)}`);
		}
	}

	async createTodayNote() {
		await ensureFolder(this.app, DAILY_FOLDER);
		await ensureNote(this.app, `${DAILY_FOLDER}/${todayStamp(new Date())}.md`);
	}
}

function message(error: unknown): string {
	return error instanceof Error ? error.message : String(error);
}
