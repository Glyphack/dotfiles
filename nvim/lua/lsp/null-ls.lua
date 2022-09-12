-- Formatter and Linter
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
                    -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
                    vim.lsp.buf.formatting_seq_sync()
                end,
            })
        end
    end,
    sources = {
        formatting.lua_format,
        formatting.isort,
        formatting.black.with({
            extra_args = { "--line-length", "79" },
        }),
        formatting.golines,
        formatting.prettier,
        -- null_ls.builtins.formatting.scalafmt,
        diagnostics.eslint,
        -- diagnostics.pylint.with({
        --     diagnostics_postprocess = function(diagnostic)
        --         diagnostic.code = diagnostic.message_id
        --     end,
        -- }),
    },
})
