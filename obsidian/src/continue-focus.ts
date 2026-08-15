import { TRACK_TIME_CATEGORIES } from './track-time';

export interface ContinuedFocus {
	category: string;
	duration: number;
	message: string;
}

const FOCUS_TAG = '#focus-session';
const TIME_RANGE = /^(\d{1,2}:\d{2}\s*(?:AM|PM))-(\d{1,2}:\d{2}\s*(?:AM|PM))/i;
const CLOCK = /^(\d{1,2}):(\d{2})\s*(AM|PM)$/i;

export function lastFocusSession(
	content: string,
	dayHeader: string,
): ContinuedFocus | null {
	const line = findLastFocusLine(content, dayHeader);
	if (line === null) {
		return null;
	}
	const { goal, message } = parseLabel(line);
	return {
		category: categoryForGoal(goal),
		duration: parseDuration(line),
		message,
	};
}

function findLastFocusLine(content: string, dayHeader: string): string | null {
	const lines = sectionLines(content, dayHeader);
	for (let i = lines.length - 1; i >= 0; i--) {
		const line = lines[i];
		if (line !== undefined && line.includes(FOCUS_TAG)) {
			return line;
		}
	}
	return null;
}

function sectionLines(content: string, dayHeader: string): string[] {
	const lines = content.split('\n');
	const plain = dayHeader.replace('[[', '').replace(']]', '');
	const start = lines.findIndex((line) => {
		const trimmed = line.trim();
		return trimmed === dayHeader || trimmed === plain;
	});
	if (start === -1) {
		return [];
	}
	const section: string[] = [];
	for (let i = start + 1; i < lines.length; i++) {
		const line = lines[i];
		if (line?.startsWith('# ')) {
			break;
		}
		section.push(line ?? '');
	}
	return section;
}

function parseLabel(line: string): { goal: string; message: string } {
	const tagIdx = line.indexOf(FOCUS_TAG);
	const rest = line.slice(tagIdx + FOCUS_TAG.length).trim();
	const colonIdx = rest.indexOf(':');
	if (colonIdx === -1) {
		return { goal: rest, message: '' };
	}
	return {
		goal: rest.slice(0, colonIdx).trim(),
		message: rest.slice(colonIdx + 1).trim(),
	};
}

function parseDuration(line: string): number {
	const match = TIME_RANGE.exec(line.trim());
	if (!match) {
		return 0;
	}
	const start = match[1] ? parseClock(match[1]) : null;
	const end = match[2] ? parseClock(match[2]) : null;
	if (start === null || end === null) {
		return 0;
	}
	const elapsed = end - start;
	return elapsed < 0 ? elapsed + 24 * 60 : elapsed;
}

function parseClock(text: string): number | null {
	const match = CLOCK.exec(text.trim());
	if (!match) {
		return null;
	}
	const hourText = match[1];
	const minuteText = match[2];
	const period = match[3];
	if (hourText === undefined || minuteText === undefined || period === undefined) {
		return null;
	}
	const hour = (Number(hourText) % 12) + (period.toUpperCase() === 'PM' ? 12 : 0);
	return hour * 60 + Number(minuteText);
}

function categoryForGoal(goal: string): string {
	const found = TRACK_TIME_CATEGORIES.find((category) => category.goal === goal);
	return found ? found.value : goal.toLowerCase();
}
