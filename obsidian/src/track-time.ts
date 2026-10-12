import { LogEntry } from './log';
import type { ScheduledNotification } from './ntfy';

export interface TrackTimeInput {
	category: string;
	duration: number;
	message: string;
}

export interface TrackTimeCategory {
	value: string;
	goal: string;
}

export const TRACK_TIME_CATEGORIES: TrackTimeCategory[] = [
	{ value: 'writing', goal: 'Writing' },
	{ value: 'programming', goal: 'Programming' },
	{ value: 'work', goal: 'Work' },
	{ value: 'reading', goal: 'Reading' },
	{ value: 'afk', goal: 'AFK' },
	{ value: 'break', goal: 'Break' },
	{ value: 'track', goal: 'Track' },
];

export const DEFAULT_CATEGORY = 'writing';
export const DEFAULT_DURATION_MIN = 30;
export const DURATION_ERROR = 'Duration must be a positive whole number of minutes.';

const FALLBACK_GOAL = 'Focus';
const FOCUS_BLOCKS: Record<string, string[]> = {
	writing: ['writing-coding'],
	programming: ['writing-coding'],
};

export class TrackTimeSession {
	constructor(
		public readonly category: string,
		public readonly durationMin: number,
		public readonly message: string,
		public readonly start: Date,
	) {}

	get goal(): string {
		const found = TRACK_TIME_CATEGORIES.find((c) => c.value === this.category);
		return found ? found.goal : FALLBACK_GOAL;
	}

	get end(): Date {
		return new Date(this.start.getTime() + this.durationMin * 60_000);
	}

	get durationSec(): number {
		return this.durationMin * 60;
	}

	get title(): string {
		return this.message ? `${this.goal}: ${this.message}` : this.goal;
	}

	logEntry(): LogEntry {
		return new LogEntry(`#focus-session ${this.title}`, null, this.start, this.end);
	}

	reminder(): ScheduledNotification {
		return {
			title: this.goal,
			body: this.message ? `Time is up: ${this.message}` : 'Time is up',
			delay: `${this.durationMin}min`,
		};
	}

	raycastUrl(): string {
		const params = new URLSearchParams({
			goal: this.goal,
			duration: String(this.durationSec),
			mode: 'block',
		});
		const blocks = FOCUS_BLOCKS[this.category];
		if (blocks) {
			params.set('categories', blocks.join(','));
		}
		return `raycast://focus/start?${params.toString()}`;
	}

	oneThingUrl(): string {
		return `one-thing:?text=${encodeURIComponent(this.title)}`;
	}
}

export function parseDuration(raw: string): number | null {
	const text = raw.trim();
	if (!text) {
		return DEFAULT_DURATION_MIN;
	}
	const minutes = Number(text);
	if (!Number.isInteger(minutes) || minutes <= 0) {
		return null;
	}
	return minutes;
}
