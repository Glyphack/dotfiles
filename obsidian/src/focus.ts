import { Platform } from 'obsidian';

interface ElectronApp {
	hide(): void;
}

interface ElectronWindow {
	hide(): void;
}

interface ElectronRemote {
	app?: ElectronApp;
	getCurrentWindow?(): ElectronWindow;
}

export function returnToPreviousApp(): void {
	if (!Platform.isMacOS || !Platform.isDesktopApp) {
		return;
	}
	const remote = loadRemote();
	if (!remote) {
		return;
	}
	try {
		if (remote.app) {
			remote.app.hide();
			return;
		}
		const win = remote.getCurrentWindow?.();
		win?.hide();
	} catch {
		return;
	}
}

function loadRemote(): ElectronRemote | null {
	const electron = tryRequire('electron') as { remote?: ElectronRemote } | null;
	if (electron?.remote) {
		return electron.remote;
	}
	return tryRequire('@electron/remote') as ElectronRemote | null;
}

function tryRequire(id: string): unknown {
	const load = (window as unknown as { require?: (id: string) => unknown }).require;
	if (!load) {
		return null;
	}
	try {
		return load(id);
	} catch {
		return null;
	}
}
