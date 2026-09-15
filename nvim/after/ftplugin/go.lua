vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

-- The bundled go ftplugin points 'keywordprg' at a command that runs "go doc"
-- in a terminal split, which K falls back to before the LSP attaches
vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = true, desc = "Hover Documentation" })
