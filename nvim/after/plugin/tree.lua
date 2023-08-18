vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- local function open_tab_silent(node)
--     local api = require("nvim-tree.api")
--
--     api.node.open.tab(node)
--     vim.cmd.tabprev()
-- end
--
-- local tree = require("nvim-tree")
-- tree.setup({
--     actions = {
--         open_file = {
--             quit_on_open = false
--         }
--     },
--     view = {
--         mappings = {
--         }
--     },
--     filters = { custom = { "^.git" }, git_clean = false, exclude = { ".git", "node_modules" } },
-- }
-- )

require("lsp-file-operations").setup()
require("neo-tree").setup({
    close_if_last_window = true,
    filesystem = {
        filtered_items = {
            visible = true,
        }
    },
})


vim.keymap.set("n", "<C-p>", ":Neotree toggle current reveal_force_cwd<cr>", { noremap = true, silent = true })
