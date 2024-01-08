local gs = require("gitsigns")
gs.setup({
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
	},
	current_line_blame = true,
})

local function map(mode, l, r, opts)
	opts = opts or {}
	opts.buffer = bufnr
	vim.keymap.set(mode, l, r, opts)
end

-- Navigation
map("n", "]g", function()
	if vim.wo.diff then
		return "]c"
	end
	vim.schedule(function()
		gs.next_hunk()
	end)
	return "<Ignore>"
end, { expr = true })

map("n", "[g", function()
	if vim.wo.diff then
		return "[c"
	end
	vim.schedule(function()
		gs.prev_hunk()
	end)
	return "<Ignore>"
end, { expr = true })

-- git linker

require("gitlinker").setup({
	callbacks = {
		["github.*.io"] = require("gitlinker.hosts").get_github_type_url,
	},
})

vim.api.nvim_set_keymap(
	"n",
	"<leader>gc",
	'<cmd>lua require"gitlinker".get_buf_range_url("n", {action_callback = require"gitlinker.actions".copy_to_clipboard})<cr>',
	{}
)

vim.api.nvim_set_keymap("n", "<leader>gr", "<cmd>:Gitsigns reset_hunk<cr>", {})
vim.api.nvim_set_keymap("n", "<leader>gR", "<cmd>:Gitsigns reset_buffer<cr>", {})
vim.api.nvim_set_keymap("n", "<leader>gp", "<cmd>:Gitsigns preview_hunk_inline<cr>", {})

-- fugitive

-- toggles fugitive by checking if the current buffer is fugitive
local fugitive_toggle = function()
	if vim.bo.ft == "fugitive" then
		vim.cmd("bd")
	else
		vim.cmd(":G")
	end
end
vim.keymap.set("n", "<leader>gs", fugitive_toggle)

local My_Fugitive = vim.api.nvim_create_augroup("My_Fugitive", {})

local autocmd = vim.api.nvim_create_autocmd
autocmd("BufWinEnter", {
	group = My_Fugitive,
	pattern = "*",
	callback = function()
		if vim.bo.ft ~= "fugitive" then
			return
		end

		local bufnr = vim.api.nvim_get_current_buf()
		local opts = { buffer = bufnr, remap = false }
		vim.keymap.set("n", "<leader>p", function()
			vim.cmd.Git("push")
		end, opts)

		vim.keymap.set("n", "<leader>P", function()
			vim.cmd.Git({ "pul" })
		end, opts)

		vim.keymap.set("n", "<leader>b", ":Git co -b ", opts)
	end,
})
