return {
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_markers = { "go.work", "go.mod", ".git" },
	settings = {
		gopls = {
			codelenses = {
				generate = true,
				test = true,
				tidy = true,
				upgrade_dependency = true,
				gc_details = true,
			},
		},
	},
}
