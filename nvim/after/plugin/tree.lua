vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local tree = require("nvim-tree")
tree.setup({
    actions = {
        open_file = {
            quit_on_open = false
        }
    },
}
)


vim.keymap.set("n", "<leader>pe", ":NvimTreeFindFileToggle<CR>", { noremap = true, silent = true })
