require("conform").setup({
	-- Map of filetype to formatters
	formatters_by_ft = {
		lua = { "stylua" },
		go = { "goimports", "golines" },
		javascript = { { "prettierd", "prettier" } },
		python = { "ruff_format", "ruff_fix" },
		kotlin = { "ktlint" },
		rust = { "rustfmt" },
		yaml = { "yamlfmt" },
		toml = { "taplo" },
		shell = { "shfmt" },
		sql = { "sqlfluff" },
		terraform = { "terraform_fmt" },
		ruby = { "rubocop" },
		markdown = { "prettierd", "prettier", "markdownlint" },
		json = { "jq" },

		-- Try out injected formatter later

		["*"] = { "trim_whitespace", "trim_newlines" },
	},
	log_level = vim.log.levels.ERROR,
	notify_on_error = true,
	-- TODO: Add support for spotless
})

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
vim.api.nvim_set_keymap("n", "<leader>ff", "<cmd>lua require'conform'.format()<cr>", { noremap = true })

vim.api.nvim_create_augroup("format_on_save", {})

vim.api.nvim_create_autocmd("BufWritePost", {
	group = "format_on_save",
	pattern = { "*" },
	callback = function(args)
		if vim.bo.filetype == "kotlin" then
			return
		end
		require("conform").format({ bufnr = args.buf })
	end,
})
