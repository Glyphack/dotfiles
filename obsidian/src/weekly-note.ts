import { App, TFile, normalizePath } from 'obsidian';
import { LogEntry, WeeklyLog } from './log';
import { dayHeader, weeklyStamp } from './dates';
import { ensureFolder, insertTemplate } from './vault';

const WEEKLY_FOLDER = 'Weekly';
const WEEKLY_TEMPLATE = 'Templates/Weekly Note Template.md';

export class WeeklyNote {
	constructor(private readonly app: App) {}

	async ensure(): Promise<TFile> {
		await ensureFolder(this.app, WEEKLY_FOLDER);
		const path = normalizePath(`${WEEKLY_FOLDER}/${weeklyStamp(new Date())}.md`);
		const existing = this.app.vault.getAbstractFileByPath(path);
		if (existing instanceof TFile) {
			return existing;
		}

		// The core templates plugin inserts into the active editor,
		// so a new note must be opened before applying the template.
		const note = await this.app.vault.create(path, '');
		await this.app.workspace.getLeaf().openFile(note);
		await insertTemplate(this.app, WEEKLY_TEMPLATE);
		return note;
	}

	async open(): Promise<TFile> {
		const file = await this.ensure();
		await this.app.workspace.getLeaf().openFile(file);
		return file;
	}

	async append(entry: LogEntry): Promise<TFile> {
		const file = await this.ensure();
		const header = dayHeader(new Date());
		await this.app.vault.process(file, (data) => {
			const note = new WeeklyLog(data);
			note.insert(header, entry);
			return note.toString();
		});
		return file;
	}
}
