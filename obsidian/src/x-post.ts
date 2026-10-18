export function toXText(markdown: string): string {
	return markdown
		.replace(/^[ \t]*\*\*\*[ \t]*(\r?\n|$)/gm, '')
		.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, '$1 $2')
		.replace(/^[ \t]*[*-] /gm, '• ');
}
