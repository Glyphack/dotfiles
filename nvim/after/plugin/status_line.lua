local navic = require('nvim-navic')

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
        lualine_c = { {
            'filename',
            file_status = true, -- displays file status (readonly status, modified status)
            path = 1            -- 0 = just filename, 1 = relative path, 2 = absolute path
        } },
        lualine_x = {
            {
                'diagnostics',
                sources = { "nvim_diagnostic" },
                symbols = {
                    error = ' ',
                    warn = ' ',
                    info = ' ',
                    hint = ' '
                }
            }, 'swenv', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { {
            'filename',
            file_status = true, -- displays file status (readonly status, modified status)
            path = 1      -- 0 = just filename, 1 = relative path, 2 = absolute path
        } },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {},
    extensions = { 'fugitive' },
    winbar = {
        lualine_c = {
            {
              function()
                  return navic.get_location()
              end,
              cond = function()
                  return navic.is_available()
              end
            },
        }
    }
}
