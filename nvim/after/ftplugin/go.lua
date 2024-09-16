vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

vim.keymap.set("n", "<leader>et", '<cmd>1TermExec cmd="go test ./..."<CR>', { desc = "Go tests" })
