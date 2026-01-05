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

vim.api.nvim_create_user_command("GotoTest", function()
	local current_file = vim.fn.expand("%:p")
	local file_type = vim.bo.filetype
	local test_file

	if file_type == "go" then
		test_file = vim.fn.fnamemodify(current_file, ":r") .. "_test.go"
	else
		vim.api.nvim_err_writeln("Test file location not defined for filetype: " .. file_type)
		return
	end

	if vim.fn.filereadable(test_file) == 1 then
		vim.cmd("edit " .. test_file)
	else
		vim.api.nvim_err_writeln("Test file not found: " .. test_file)
	end
end, {})

vim.api.nvim_create_user_command("GRunTest", function()
	local current_line = vim.fn.line(".")
	local lines = vim.fn.getline(1, current_line)
	local test_function

	for i = #lines, 1, -1 do
		local line = lines[i]
		if line:match("^func%s+Test") then
			test_function = line:match("^func%s+(Test%w+)")
			break
		end
	end

	if test_function then
		local cmd = string.format('2TermExec cmd="go test ./... -run ^%s$"', test_function)
		vim.cmd(cmd)
	else
		vim.api.nvim_err_writeln("No test function found above the current line.")
	end
end, {})
