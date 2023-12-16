require("overseer").setup({
	templates = { "builtin", "user.gradle_spotless" },
})

vim.api.nvim_set_keymap("n", "<leader>o", ":OverseerRun<cr>", { noremap = true })
