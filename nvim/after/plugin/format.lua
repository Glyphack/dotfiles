require("conform").setup({
	-- Map of filetype to formatters
	formatters_by_ft = {
		lua = { "stylua" },
		go = { "goimports", "golines" },
		javascript = { { "prettierd", "prettier" } },
		python = { "ruff_format" },
		kotlin = { "ktlint" },
		["*"] = { "codespell" },
		["_"] = { "trim_whitespace" },
	},
	format_on_save = {
		lsp_fallback = true,
		timeout_ms = 500,
	},
	format_after_save = {
		lsp_fallback = true,
	},
	log_level = vim.log.levels.ERROR,
	notify_on_error = true,
	-- TODO: Add support for spotless
})
