local root_dir = vim.fs.dirname(vim.fs.find({
	"Package.swift",
	".git",
}, { upward = true })[1])

return {
	name = "sourcekit-lsp",
	filetypes = "swift",
	cmd = { "sourcekit-lsp" },
	root_markers = { ".git", "Package.swift" },
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
