-- Set lualine as statusline
-- See `:help lualine.txt`
require('lualine').setup {
    options = {
        icons_enabled = false,
        theme = 'rose-pine',
    },
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch' },
        lualine_c = { 'filename' },
        lualine_x = { 'swenv', 'filetype' },
        lualine_y = {},
        lualine_z = { 'location' },
    },
}
