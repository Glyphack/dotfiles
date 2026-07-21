export interface LogInput {
	message: string;
	place: string;
	from: string;
	to: string;
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
		const start = input.from ? applyTime(now, input.from) : now;
		if (input.to) {
			return new LogEntry(input.message, place, start, applyTime(now, input.to));
		}
		if (!input.from) {
			return new LogEntry(input.message, place, now, null);
		}
		return new LogEntry(input.message, place, start, now);
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

		let insertAt = this.findNextHeader(headerIdx) ?? this.lines.length;
		while (insertAt > headerIdx + 1) {
			const previous = this.lines[insertAt - 1];
			if (previous === undefined || previous.trim() !== '') {
				break;
			}
			insertAt--;
		}
		this.lines.splice(insertAt, 0, entry.format());
	}

	toString(): string {
		return this.lines.join('\n') + '\n';
	}

	private createSection(dateHeader: string, entry: LogEntry): void {
		const section = [dateHeader, '', entry.format(), ''];
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
	const period = date.getHours() >= 12 ? 'PM' : 'AM';
	const hour = date.getHours() % 12 || 12;
	const minutes = String(date.getMinutes()).padStart(2, '0');
	return `${String(hour).padStart(2, '0')}:${minutes} ${period}`;
}

function applyTime(now: Date, time: string): Date {
	const [hour, minute] = time.split(':');
	const start = new Date(now);
	start.setHours(Number(hour), Number(minute), 0, 0);
	return start;
}

function splitLines(content: string): string[] {
	const lines = content.split('\n');
	if (lines.length > 0 && lines[lines.length - 1] === '') {
		lines.pop();
	}
	return lines;
}
