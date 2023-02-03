local gs = require('gitsigns')
gs.setup {
    signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
    },
    current_line_blame = true,
}

local function map(mode, l, r, opts)
    opts = opts or {}
    opts.buffer = bufnr
    vim.keymap.set(mode, l, r, opts)
end

-- Navigation
map('n', ']c', function()
    if vim.wo.diff then return ']c' end
    vim.schedule(function() gs.next_hunk() end)
    return '<Ignore>'
end, { expr = true })

map('n', '[c', function()
    if vim.wo.diff then return '[c' end
    vim.schedule(function() gs.prev_hunk() end)
    return '<Ignore>'
end, { expr = true })

vim.api.nvim_set_keymap('n', '<leader>gr', '<cmd>:Gitsigns reset_hunk<cr>', {})
vim.api.nvim_set_keymap('n', '<leader>gR', '<cmd>:Gitsigns reset_buffer<cr>', {})
vim.api.nvim_set_keymap('n', '<leader>gp', '<cmd>:Gitsigns preview_hunk_inline<cr>', {})
vim.api.nvim_set_keymap('n', '<leader>gs', '<cmd>:Gitsigns stage_hunk<cr>', {})
vim.api.nvim_set_keymap('n', '<leader>gS', '<cmd>:Gitsigns stage_buffer<cr>', {})

vim.api.nvim_set_keymap('n', '<leader>gwd', '<cmd>:Gitsigns toggle_word_diff<cr>', {})

require("gitlinker").setup()
vim.api.nvim_set_keymap('n', '<leader>gb',
    '<cmd>lua require"gitlinker".get_buf_range_url("n", {action_callback = require"gitlinker.actions".open_in_browser})<cr>'
    , { silent = true })

vim.api.nvim_set_keymap('v', '<leader>gb',
    '<cmd>lua require"gitlinker".get_buf_range_url("v", {action_callback = require"gitlinker.actions".open_in_browser})<cr>'
    , {})
