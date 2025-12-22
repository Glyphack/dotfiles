return {
	name = "sourcekit-lsp",
	cmd = { "sourcekit-lsp" },
	root_dir = vim.fs.dirname(vim.fs.find({
		"Package.swift",
		".git",
	}, { upward = true })[1]),
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
