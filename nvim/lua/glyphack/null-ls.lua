local null_ls = require("null-ls")

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics

local code_actions = null_ls.builtins.code_actions

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
        formatting.black,
        -- formatting.scalafmt,

        formatting.goimports,
        formatting.gofmt,
        formatting.buf,
        diagnostics.buf,

        formatting.rustfmt,

        diagnostics.ktlint,
        formatting.ktlint,

        formatting.markdownlint,
        diagnostics.markdownlint,

        formatting.prettierd.with({
            filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "css", "scss", "less", "html", "jsonc", "yaml", "markdown", "markdown.mdx", "graphql", "handlebars" }
        }),
        formatting.prismafmt,
        -- diagnostics.eslint_d,

        formatting.shfmt,
        formatting.packer,

        formatting.sqlfluff.with({
            extra_args = { "--dialect", "sparksql" }, -- change to your dialect
        }),
        diagnostics.sqlfluff.with({
            extra_args = { "--dialect", "sparksql" }, -- change to your dialect
        }),

        diagnostics.codespell.with({
            extra_args = { "--L", "crate" },
        }),
        -- formatting.codespell,
    },
})
