local null_ls = require("null-ls")

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

null_ls.setup({
    on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function()
                    vim.lsp.buf.format({ bufnr = bufnr })
                end,
            })
        end
    end,
    sources = {
        formatting.isort.with({
            extra_args = { "--line-length", "79", "--ca", "--profile", "black", "--float-to-top" },
        }),
        formatting.black.with({
            extra_args = { "--line-length", "79" },
        }),
        formatting.ruff.with({
            extra_args = { "--line-length", "79" },
        }),
        formatting.golines,
        formatting.buf,
        formatting.prettierd,
        formatting.scalafmt,
        formatting.shfmt,
        formatting.goimports,
        formatting.gofumpt,
        diagnostics.markdownlint,
        diagnostics.ruff,
        diagnostics.eslint_d,
        diagnostics.buf,
        diagnostics.hadolint,
    },
})
