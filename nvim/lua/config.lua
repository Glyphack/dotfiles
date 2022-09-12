require 'options'
require 'keymaps'
require 'theme'
require 'lsp'
require 'terminal'
require 'tree'
require 'completion'
require 'discord'

-- global
vim.opt_global.completeopt = { "menuone", "noinsert", "noselect" }
vim.opt_global.shortmess:remove("F"):append("c")

-- Telescope
require("telescope").setup {
    extensions = {
        file_browser = {
            theme = "ivy",
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
            mappings = {
                ["i"] = {
                },
                ["n"] = {
                },
            },
        },
        project = {
            base_dirs = {
                { '~/Programming/', max_depth = 4 },
                { '~/', max_depth = 2 },
            },
            hidden_files = true, -- default: false
            theme = "dropdown"
        }
    },
}
-- require("telescope").load_extension "file_browser"
-- vim.api.nvim_set_keymap(
--   "n",
--   "<space>fb",
--   ":Telescope file_browser<CR>",
--   { noremap = true }
-- )
require 'telescope'.load_extension 'project'
vim.api.nvim_set_keymap(
    'n',
    '<C-p>',
    ":lua require'telescope'.extensions.project.project{}<CR>",
    { noremap = true, silent = true }
)

require("symbols-outline").setup()
