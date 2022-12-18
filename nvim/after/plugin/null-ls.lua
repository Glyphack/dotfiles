-- Formatter and Linter
local null_ls = require("null-ls")

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
null_ls.setup({
    sources = {
        formatting.isort.with({
            extra_args = { "--line-length", "79", "--ca", "--profile", "black", "--float-to-top" },
        }),
        formatting.black.with({
            extra_args = { "--line-length", "79" },
        }),
        formatting.golines,
        formatting.buf,
        formatting.prettier,
        formatting.scalafmt,
        formatting.markdownlint,
        formatting.prismafmt,
        formatting.shfmt,
        formatting.goimports,
        formatting.gofumpt,
        diagnostics.markdownlint,
        diagnostics.ruff,
        diagnostics.eslint,
        diagnostics.buf,
        diagnostics.hadolint,
    },
})

