vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

vim.keymap.set("n", "<leader>et", '<cmd>1TermExec cmd="go test ./..."<CR>', { desc = "Go tests" })

local ts_utils = require("nvim-treesitter.ts_utils")

local function get_current_function_name()
	local node = ts_utils.get_node_at_cursor()
	if not node then
		return nil
	end

	local func = node
	while func do
		if func:type() == "function_declaration" or func:type() == "method_declaration" then
			break
		end
		func = func:parent()
	end

	if not func then
		return nil
	end

	local func_name_node = func:child(1) -- In Go, the function name is typically the second child
	if func_name_node then
		return ts_utils.get_node_text(func_name_node)[1]
	end

	return nil
end

vim.api.nvim_create_user_command("GoRunTest", function()
	local function_name = get_current_function_name()
	if function_name == nil then
		vim.api.nvim_err_writeln("Test file not found: " .. function_name)
		return
	end
	local cmd = ":1TermExec cmd=" .. '"' .. "go test ./... -run " .. function_name .. '"' .. "<CR>"
	vim.notify(cmd)
	vim.cmd(cmd)
end, {})
