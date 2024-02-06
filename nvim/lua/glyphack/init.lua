require("glyphack.options")
require("glyphack.remap")

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup("HighlightYank", {})

function R(name)
	require("plenary.reload").reload_module(name)
end

autocmd("TextYankPost", {
	group = yank_group,
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 40,
		})
	end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
	callback = function()
		if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
			vim.api.nvim_command("silent update")
		end
	end,
})

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
	callback = function()
		if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
			vim.api.nvim_command("silent update")
		end
	end,
})

-- Lua function to wrap the word under the cursor with []
function Link()
	local word = vim.fn.expand("<cWORD>")
	-- if the word starts with http, don't wrap it in []
	if word:match("^http") then
		vim.api.nvim_command("normal ciW[](" .. word .. ")")
		vim.api.nvim_exec("normal! F[", true)
		return
	end
	vim.api.nvim_command("normal ciW[" .. word .. "]()")
	vim.api.nvim_exec("normal! F(", true)
end
vim.cmd("command! Link :lua Link()")

require("glyphack.packer")
