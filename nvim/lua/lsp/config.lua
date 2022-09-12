local lsp = require('lsp-zero')
lsp.preset('lsp-compe')


lsp.configure('sumneko_lua', require('lsp.settings.sumneko_lua'))
lsp.configure('jsonls', require('lsp.settings.jsonls'))
lsp.configure('pylsp', require("lsp.settings.pylsp"))

local function lsp_highlight_document(client)
    -- Set autocommands conditional on server_capabilities
    local status_ok, illuminate = pcall(require, "illuminate")
    if not status_ok then
        return
    end
    illuminate.on_attach(client)
    -- end
end

lsp.on_attach(function(client, bufnr)
    local noremap = { buffer = bufnr, remap = false }
    local bind = vim.keymap.set

    bind('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', noremap)
    bind('n', '<leader>sh', '<cmd><cmd>lua vim.lsp.buf.signature_help()<cr>', noremap)
    bind('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<cr>', noremap)

    lsp_highlight_document(client)
end)

lsp.setup()


-- Signature completion
require("lsp_signature").setup({
    bind = false,
    handler_opts = {
        border = "rounded",
    },
    max_width = 80,
    max_height = 4,
    -- doc_lines = 4,
    floating_window = true,

    floating_window_above_cur_line = false,
    fix_pos = false,
    always_trigger = false,
    zindex = 40,
    timer_interval = 100,
})
