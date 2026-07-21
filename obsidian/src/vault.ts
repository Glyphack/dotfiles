import { App, Notice, TFile, TFolder, normalizePath } from 'obsidian';

// For using the internal templates plugin by obsidian
declare module 'obsidian' {
	interface TemplatesPluginInstance {
		insertTemplate(file: TFile): Promise<void>;
	}

	interface InternalPlugin {
		enabled: boolean;
		instance?: TemplatesPluginInstance;
	}

	interface App {
		internalPlugins: {
			getPluginById(id: string): InternalPlugin | null;
		};
	}
}

export async function ensureFolder(app: App, folder: string): Promise<void> {
	const path = normalizePath(folder);
	const existing = app.vault.getAbstractFileByPath(path);
	if (existing instanceof TFolder) {
		return;
	}

	await app.vault.createFolder(path);
}

export async function ensureNote(app: App, notePath: string): Promise<TFile> {
	const path = normalizePath(notePath);
	const existing = app.vault.getAbstractFileByPath(path);
	if (existing instanceof TFile) {
		return existing;
	}

	return await app.vault.create(path, '');
}

export async function insertTemplate(
	app: App,
	templatePath: string,
): Promise<void> {
	const template = app.vault.getAbstractFileByPath(
		normalizePath(templatePath),
	);
	if (!(template instanceof TFile)) {
		new Notice(`Template not found: ${templatePath}`);
		return;
	}

	const templates = app.internalPlugins.getPluginById('templates');
	if (!templates?.enabled || !templates.instance) {
		new Notice('Core templates plugin is not enabled.');
		return;
	}

	await templates.instance.insertTemplate(template);
}
