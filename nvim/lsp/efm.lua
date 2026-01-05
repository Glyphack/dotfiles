local languages = {
	-- lua = { require("efmls-configs.formatters.stylua") },
	-- proto = {
	-- 	require("efmls-configs.linters.buf"),
	-- },
	-- bash = {
	-- 	require("efmls-configs.linters.shellcheck"),
	-- },
	-- markdown = {
	-- 	require("efmls-configs.linters.proselint"),
	-- },
	-- gitcommit = {
	-- 	require("efmls-configs.linters.proselint"),
	-- },
	-- ["="] = {},
}

return {
	cmd = { "efm-langserver" },
	root_markers = { ".git" },
	settings = {
		rootMarkers = { ".git/" },
		languages = languages,
	},
	init_options = {
		documentRangeFormatting = true,
		documentFormatting = true,
		codeAction = true,
	},
}
