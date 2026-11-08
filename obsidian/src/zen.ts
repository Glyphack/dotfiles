import { Workspace } from 'obsidian';

const ZEN_CLASS = 'dots-zen';

interface Sidebar {
	collapsed: boolean;
	collapse(): void;
	expand(): void;
}

/**
 * Hides everything around the note: both sidebars, the ribbon, tab headers,
 * the note header and the status bar. Turning it off opens again only the
 * sidebars that were open before.
 */
export class ZenMode {
	private reopen: Sidebar[] = [];
	private active = false;

	constructor(private readonly workspace: Workspace) {}

	get isActive(): boolean {
		return this.active;
	}

	toggle(): void {
		if (this.active) {
			this.exit();
			return;
		}
		this.enter();
	}

	enter(): void {
		const sidebars: Sidebar[] = [this.workspace.leftSplit, this.workspace.rightSplit];
		this.reopen = sidebars.filter((sidebar) => !sidebar.collapsed);
		for (const sidebar of this.reopen) {
			sidebar.collapse();
		}
		document.body.addClass(ZEN_CLASS);
		this.active = true;
	}

	exit(): void {
		document.body.removeClass(ZEN_CLASS);
		for (const sidebar of this.reopen) {
			sidebar.expand();
		}
		this.reopen = [];
		this.active = false;
	}
}
