export const TIME_ERROR = 'Start time must be a time like 09:30 or 0930.';

const TIME_PATTERN = /^(\d{1,2}):?(\d{2})$/;
// Log lines may use a 24-hour clock or a 12-hour clock with AM or PM.
const STAMP = String.raw`\d{1,2}:\d{2}(?:\s*[AP]M)?`;
const STAMP_PARTS = /^(\d{1,2}):(\d{2})(?:\s*([AP]M))?$/i;

export const STAMP_RANGE = new RegExp(`^(${STAMP})-(${STAMP})`, 'i');

export interface ClockTime {
	hour: number;
	minute: number;
}

export function parseTime(text: string): ClockTime | null {
	const match = TIME_PATTERN.exec(text.trim());
	if (!match) {
		return null;
	}
	const hour = Number(match[1]);
	const minute = Number(match[2]);
	if (hour > 23 || minute > 59) {
		return null;
	}
	return { hour, minute };
}

export function parseStamp(text: string): ClockTime | null {
	const match = STAMP_PARTS.exec(text.trim());
	if (!match) {
		return null;
	}
	const hour = Number(match[1]);
	const minute = Number(match[2]);
	const period = match[3]?.toUpperCase();
	if (!period) {
		return { hour, minute };
	}
	return { hour: (hour % 12) + (period === 'PM' ? 12 : 0), minute };
}

export interface LogInput {
	message: string;
	place: string;
	from: string;
}

export class LogEntry {
	constructor(
		public readonly message: string,
		public readonly place: string | null,
		public readonly start: Date,
		public readonly end: Date | null,
	) {}

	static fromInput(input: LogInput, now: Date): LogEntry {
		const place = input.place ? input.place : null;
		if (!input.from) {
			return new LogEntry(input.message, place, now, null);
		}
		const time = parseTime(input.from);
		if (time === null) {
			throw new Error(TIME_ERROR);
		}
		return new LogEntry(input.message, place, applyTime(now, time), now);
	}

	format(): string {
		let timestamp = formatTime(this.start);
		if (this.end) {
			timestamp += `-${formatTime(this.end)}`;
		}
		let line = `${timestamp} > ${this.message}`;
		if (this.place) {
			line += ` place: ${this.place}`;
		}
		return line;
	}
}

const LOG_SEPARATOR = '***';
const LOG_LINE = new RegExp(`^${STAMP}(?:-${STAMP})? > `, 'i');

export class WeeklyLog {
	private readonly lines: string[];

	constructor(content: string) {
		this.lines = splitLines(content);
	}

	insert(dateHeader: string, entry: LogEntry): void {
		const headerIdx = this.findSection(dateHeader);
		if (headerIdx === null) {
			this.createSection(dateHeader, entry);
			return;
		}

		const sectionEnd = this.findNextHeader(headerIdx) ?? this.lines.length;
		let insertAt = sectionEnd;
		while (insertAt > headerIdx + 1) {
			const previous = this.lines[insertAt - 1];
			if (previous === undefined || previous.trim() !== '') {
				break;
			}
			insertAt--;
		}
		if (this.hasSeparator(headerIdx, sectionEnd)) {
			const lastLog = this.findLastLog(headerIdx, sectionEnd);
			this.lines.splice(lastLog === null ? insertAt : lastLog + 1, 0, entry.format());
			return;
		}
		this.lines.splice(insertAt, 0, '', LOG_SEPARATOR, '', entry.format());
	}

	toString(): string {
		return this.lines.join('\n') + '\n';
	}

	private createSection(dateHeader: string, entry: LogEntry): void {
		const section = [dateHeader, '', LOG_SEPARATOR, '', entry.format(), ''];
		const firstDateIdx = this.findFirstDateHeader();
		if (firstDateIdx === null) {
			this.lines.push('', ...section);
			return;
		}
		this.lines.splice(firstDateIdx, 0, ...section);
	}

	private findSection(header: string): number | null {
		const plain = header.replace('[[', '').replace(']]', '');
		const idx = this.lines.findIndex((line) => {
			const trimmed = line.trim();
			return trimmed === header || trimmed === plain;
		});
		return idx === -1 ? null : idx;
	}

	private hasSeparator(from: number, to: number): boolean {
		return this.lines
			.slice(from + 1, to)
			.some((line) => line.trim() === LOG_SEPARATOR);
	}

	private findLastLog(from: number, to: number): number | null {
		for (let i = to - 1; i > from; i--) {
			if (LOG_LINE.test(this.lines[i] ?? '')) {
				return i;
			}
		}
		return null;
	}

	private findNextHeader(after: number): number | null {
		for (let i = after + 1; i < this.lines.length; i++) {
			if (this.lines[i]?.startsWith('# ')) {
				return i;
			}
		}
		return null;
	}

	private findFirstDateHeader(): number | null {
		const dateHeader = /^# (?:\[\[)?\d{4}-\d{2}-\d{2}(?:\]\])?$/;
		for (let i = 0; i < this.lines.length; i++) {
			const stripped = this.lines[i]?.trim() ?? '';
			if (dateHeader.test(stripped)) {
				return i;
			}
		}
		return null;
	}
}

function formatTime(date: Date): string {
	const hours = String(date.getHours()).padStart(2, '0');
	const minutes = String(date.getMinutes()).padStart(2, '0');
	return `${hours}:${minutes}`;
}

function applyTime(now: Date, time: ClockTime): Date {
	const start = new Date(now);
	start.setHours(time.hour, time.minute, 0, 0);
	return start;
}

function splitLines(content: string): string[] {
	const lines = content.split('\n');
	if (lines.length > 0 && lines[lines.length - 1] === '') {
		lines.pop();
	}
	return lines;
}
