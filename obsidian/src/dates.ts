export function todayStamp(now: Date): string {
	const year = now.getFullYear();
	const month = String(now.getMonth() + 1).padStart(2, '0');
	const day = String(now.getDate()).padStart(2, '0');
	return `${year}-${month}-${day}`;
}

export function dayHeader(now: Date): string {
	return `# [[${todayStamp(now)}]]`;
}

export function weeklyStamp(now: Date): string {
	const { year, week } = isoYearWeek(now);
	return `${year}-W${String(week).padStart(2, '0')}`;
}

function isoYearWeek(date: Date): { year: number; week: number } {
	const thursday = new Date(date.getFullYear(), date.getMonth(), date.getDate());
	const mondayOffset = (thursday.getDay() + 6) % 7;
	thursday.setDate(thursday.getDate() - mondayOffset + 3);

	const year = thursday.getFullYear();
	const firstThursday = new Date(year, 0, 4);
	firstThursday.setDate(
		firstThursday.getDate() - ((firstThursday.getDay() + 6) % 7) + 3,
	);

	const week =
		1 +
		Math.round(
			(thursday.getTime() - firstThursday.getTime()) /
				(7 * 24 * 60 * 60 * 1000),
		);
	return { year, week };
}
