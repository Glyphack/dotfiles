require("conform").setup({
	-- Map of filetype to formatters
	formatters_by_ft = {
		lua = { "stylua" },
		go = { "goimports", "golines", "gofmt" },
		javascript = { { "prettierd", "prettier" } },
		python = { "ruff_format" },
		kotlin = { "ktlint" },
		rust = { "rustfmt" },
		yaml = { "yamlfmt" },
		toml = { "taplo" },
		shell = { "shfmt" },
		sql = { "sqlfluff" },
		terraform = { "terraform_fmt" },
		markdown = { "prettierd", "prettier", "markdownlint" },
		json = { "jq" },
		-- ruby = { "rubocop" },
		-- dart = { "dartfmt" },

		-- Try out injected formatter later

		["*"] = { "trim_whitespace", "trim_newlines" },
	},
	log_level = vim.log.levels.ERROR,
	notify_on_error = true,
	-- TODO: Add support for spotless
})

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
vim.keymap.set("n", "<leader>ff", "", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>ff", "<cmd>lua require'conform'.format()<cr>", { noremap = true })

vim.api.nvim_create_augroup("format_on_save", {})

vim.api.nvim_create_autocmd("BufWritePost", {
	group = "format_on_save",
	pattern = { "*" },
	callback = function(args)
		if vim.bo.filetype == "kotlin" or vim.bo.filetype == "python" or vim.bo.filetype == "yaml" then
			return
		end
		require("conform").format({ bufnr = args.buf })
	end,
})

-- Make configuration per project
require("conform").formatters.yamlfmt = {
	prepend_args = function(self, ctx)
		return { "-formatter", "retain_line_breaks=true,pad_line_comments=2,include_document_start=true" }
	end,
}
