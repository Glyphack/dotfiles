vim.g.mapleader = " "

-- Easy window switch
vim.keymap.set("n", "<M-h>", "<c-w>h)")
vim.keymap.set("n", "<M-j>", "<c-w>j")
vim.keymap.set("n", "<M-k>", "<c-w>k")
vim.keymap.set("n", "<M-l>", "<c-w>l")
vim.keymap.set("t", "<M-h>", "<c-\\><c-n><c-w>h")
vim.keymap.set("t", "<M-j>", "<c-\\><c-n><c-w>j")
vim.keymap.set("t", "<M-k>", "<c-\\><c-n><c-w>k")
vim.keymap.set("t", "<M-l>", "<c-\\><c-n><c-w>l")
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")
vim.keymap.set("t", "<M-[>", "<Esc>")
vim.keymap.set("t", "<C-v><Esc>", "<Esc>")

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- No headache paste
vim.keymap.set("x", "<leader>p", [["_dP]])

-- to clipboard and from clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- To the void
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
vim.keymap.set("n", "<leader>w", ":w<CR>", opts)
vim.keymap.set("n", "<leader>q", ":q<CR>", opts)

-- Resize with arrows
vim.keymap.set("n", "<M-Up>", ":resize +2<CR>", opts)
vim.keymap.set("n", "<M-Down>", ":resize -2<CR>", opts)
vim.keymap.set("n", "<M-Left>", ":vertical resize -2<CR>", opts)
vim.keymap.set("n", "<M-Right>", ":vertical resize +2<CR>", opts)


vim.keymap.set("n", "<leader>xx", ":source %<CR>", opts)
vim.keymap.set("n", "<leader>xv", ":source $MYVIMRC<CR>", opts)
