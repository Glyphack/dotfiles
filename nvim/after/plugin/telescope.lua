require "glyphack.telescope.setup"
require "glyphack.telescope.keys"

function old_config()
    local builtin = require('telescope.builtin')
    require('telescope').setup {
        extensions = {
            fzf = {
                fuzzy = true,                   -- false will only do exact matching
                override_generic_sorter = true, -- override the generic sorter
                override_file_sorter = true,    -- override the file sorter
                case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
            }
        },
        pickers = {
            find_files = {
                theme = "dropdown",
            },
            git_files = {
                theme = "dropdown",
            }
        },
        defaults = {
            layout_config = {
                vertical = { width = 0.5 }
                -- other layout configuration here
            },
            -- other defaults configuration here
        },
    }
    require('telescope').load_extension('fzf')
    require 'telescope-all-recent'.setup {}

    vim.keymap.set('n', '<leader>f', function()
        builtin.git_files()
    end, {})
    vim.keymap.set('n', '<leader><leader>', function()
        builtin.find_files({ no_ignore = true, hidden = true, follow = true, })
    end, {})
    vim.keymap.set('n', '<leader>sy', builtin.lsp_document_symbols, {})
    vim.keymap.set('n', '<leader>ps', builtin.live_grep, {})
    vim.keymap.set('n', '<leader>?', builtin.oldfiles, { desc = '[?] Find recently opened files' })
    vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, {})

    vim.keymap.set('n', '<leader>yh', function()
        require('telescope').extensions.neoclip.default()
    end)
end

-- old_config()
