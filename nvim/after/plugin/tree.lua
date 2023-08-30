vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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
