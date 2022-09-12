require("nvim-tree").setup()
vim.api.nvim_set_keymap(
    "n",
    "<leader>ee",
    ":NvimTreeToggle<CR>",
    { noremap = true }
)
vim.api.nvim_set_keymap(
    "n",
    "<leader>eh",
    ":NvimTreeFindFile<CR>",
    { noremap = true }
)


