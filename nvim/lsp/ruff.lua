return {
	cmd = { 'ruff', 'server', '--preview' },
	filetypes = { 'python' },
	root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
	init_options = {
		settings = {
			fixAll = true,
			formatter = {
				enabled = true,
			},
			linter = {
				enabled = true,
			},
		},
	},
}
