vim.api.nvim_set_keymap(
	"n",
	"<leader>v",
	":silent !clang-tidy -fix-errors -p=build %<CR>",
	{ noremap = true, silent = true }
)
