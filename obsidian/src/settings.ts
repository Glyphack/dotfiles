import { App, PluginSettingTab, Setting } from 'obsidian';
import type DotsPlugin from './main';

export interface DotsSettings {
	hugoContentPath: string;
	ntfyServer: string;
	ntfyTopic: string;
	typewriterMode: boolean;
}

export const DEFAULT_SETTINGS: DotsSettings = {
	hugoContentPath: '',
	ntfyServer: 'https://ntfy.sh',
	ntfyTopic: '',
	typewriterMode: false,
};

export class DotsSettingTab extends PluginSettingTab {
	constructor(
		app: App,
		private readonly plugin: DotsPlugin,
	) {
		super(app, plugin);
	}

	display(): void {
		const { containerEl } = this;
		containerEl.empty();

		new Setting(containerEl)
			.setName('Hugo content path')
			.setDesc(
				'Absolute path to your Hugo content directory. Notes with publish: true are exported here as leaf bundles. Desktop only.',
			)
			.addText((text) =>
				text
					.setPlaceholder('/path/to/site/content')
					.setValue(this.plugin.settings.hugoContentPath)
					.onChange(async (value) => {
						this.plugin.settings.hugoContentPath = value;
						await this.plugin.saveSettings();
					}),
			);

		new Setting(containerEl)
			.setName('Ntfy server')
			.setDesc('Base URL of the ntfy server used to send time-tracking reminders.')
			.addText((text) =>
				text
					.setPlaceholder('https://ntfy.sh')
					.setValue(this.plugin.settings.ntfyServer)
					.onChange(async (value) => {
						this.plugin.settings.ntfyServer = value;
						await this.plugin.saveSettings();
					}),
			);

		new Setting(containerEl)
			.setName('Ntfy topic')
			.setDesc(
				'Topic to publish time-tracking reminders to. Leave empty to send no reminder. Anyone who knows the topic can read it, so pick something hard to guess.',
			)
			.addText((text) =>
				text
					.setPlaceholder('Pick a hard-to-guess name')
					.setValue(this.plugin.settings.ntfyTopic)
					.onChange(async (value) => {
						this.plugin.settings.ntfyTopic = value;
						await this.plugin.saveSettings();
					}),
			);
	}
}
