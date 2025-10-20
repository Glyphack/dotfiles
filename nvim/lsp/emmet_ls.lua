return {
	cmd = { 'emmet-ls', '--stdio' },
	filetypes = { 'css', 'eruby', 'html', 'javascript', 'javascriptreact', 'less', 'sass', 'scss', 'svelte', 'pug', 'typescriptreact', 'vue' },
	root_markers = { '.git' },
	init_options = {
		html = {
			options = {
				["bem.enabled"] = true,
			},
		},
	},
}
