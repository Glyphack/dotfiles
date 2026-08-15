return {
	cmd = { 'vscode-html-language-server', '--stdio' },
	filetypes = { 'html', 'templ', 'htmldjango' },
	root_markers = { '.git' },
	init_options = {
		configurationSection = { "html", "css", "javascript" },
		embeddedLanguages = {
			css = true,
			javascript = true,
		},
	},
}
