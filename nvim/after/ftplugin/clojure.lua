vim.api.nvim_create_user_command("ClojureStartRepl", function()
	local project_root = vim.fn.getcwd()
	local nrepl_cmd = "clj -M:nrepl -m nrepl.cmdline"
	vim.cmd("new | terminal " .. nrepl_cmd)
	local term_win = vim.api.nvim_get_current_win()
	vim.cmd("wincmd p")
	local current_buf = vim.api.nvim_get_current_buf()
	local current_ft = vim.bo[current_buf].filetype
	if current_ft ~= "clojure" then
		vim.cmd("e src/clj/main.clj")
		vim.notify("📝 Opened Clojure buffer for REPL connection", vim.log.levels.INFO)
	end
	vim.defer_fn(function()
		local port_file = project_root .. "/.nrepl-port"
		if vim.fn.filereadable(port_file) == 1 then
			local port = vim.fn.readfile(port_file)[1]:gsub("%s+", "")
			vim.cmd("ConjureConnect " .. port)
			vim.notify("Connected to nREPL on port " .. port, vim.log.levels.INFO)
		else
			vim.notify(".nrepl-port not found, waiting...", vim.log.levels.WARN)
			vim.defer_fn(function()
				if vim.fn.filereadable(port_file) == 1 then
					local port = vim.fn.readfile(port_file)[1]:gsub("%s+", "")
					vim.cmd("ConjureConnect " .. port)
					vim.notify("Connected to nREPL on port " .. port, vim.log.levels.INFO)
				else
					vim.notify(
						".nrepl-port still not found. Connect manually with :ConjureConnect <port>",
						vim.log.levels.ERROR
					)
				end
			end, 2000)
		end
	end, 1500)
end, {
	desc = "Start nREPL server and connect Conjure automatically",
})

vim.keymap.set("n", "<localleader>rs", "<cmd>ClojureStartRepl<CR>", {
	desc = "Start Clojure REPL + Connect",
	buffer = true,
	silent = true,
})
