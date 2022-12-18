require("glyphack.options")
require("glyphack.remap")
require("glyphack.packer")
require("glyphack.null-ls")

local augroup = vim.api.nvim_create_augroup
local MyGroup = augroup('ThePrimeagen', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

function R(name)
    require("plenary.reload").reload_module(name)
end

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

autocmd({ "BufWritePre" }, {
    group = MyGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.formatting_sync()]]
