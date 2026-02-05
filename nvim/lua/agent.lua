--- Agent Prompt Generator
---
--- A simple plugin to generate prompts for AI coding assistants.
--- It captures file context and optional visual selection, opens a prompt buffer,
--- and copies the formatted prompt to the clipboard when you leave the buffer.
---
--- Usage:
---   <leader>a (normal mode) - Create prompt with entire file as context
---   <leader>a (visual mode) - Create prompt with selected lines as context
---
--- Setup: require("agent").setup()
--- Setup with Amp: require("agent").setup({ use_amp = true })

local M = {}

local config = {
	use_amp = false,
	use_opencode = false,
	opencode_url = "http://127.0.0.1:4096",
}

local function send_to_opencode(prompt)
	local curl = require("plenary.curl")
	local base_url = config.opencode_url

	curl.post(base_url .. "/tui/append-prompt", {
		body = vim.fn.json_encode({ text = prompt }),
		headers = { ["Content-Type"] = "application/json" },
		callback = function(append_response)
			vim.schedule(function()
				if append_response.status < 200 or append_response.status >= 300 then
					vim.notify(
						"OpenCode: failed to append prompt [" .. append_response.status .. "]",
						vim.log.levels.ERROR
					)
					return
				end

				curl.post(base_url .. "/tui/submit-prompt", {
					headers = { ["Content-Type"] = "application/json" },
					callback = function(submit_response)
						vim.schedule(function()
							local status = submit_response.status
							if status >= 200 and status < 300 then
								vim.notify("OpenCode: prompt submitted", vim.log.levels.INFO)
							else
								vim.notify("OpenCode: failed to submit [" .. status .. "]", vim.log.levels.ERROR)
							end
						end)
					end,
				})
			end)
		end,
	})
end

local function get_visual_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_line = start_pos[2]
	local end_line = end_pos[2]

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local text = table.concat(lines, "\n")

	return {
		text = text,
		start_line = start_line,
		end_line = end_line,
	}
end

local function open_prompt_buffer(context)
	vim.cmd("botright 10new")
	local prompt_buf = vim.api.nvim_get_current_buf()

	vim.bo[prompt_buf].buftype = "nofile"
	vim.bo[prompt_buf].bufhidden = "hide"
	vim.bo[prompt_buf].swapfile = false
	vim.bo[prompt_buf].filetype = "markdown"

	vim.api.nvim_buf_set_name(prompt_buf, "Agent Prompt")

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = prompt_buf,
		once = true,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(prompt_buf, 0, -1, false)
			local user_prompt = table.concat(lines, "\n")
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(prompt_buf) then
					vim.api.nvim_buf_delete(prompt_buf, { force = true })
				end
			end)

			if vim.trim(user_prompt) == "" then
				return
			end

			local full_prompt
			if context.selection then
				full_prompt = string.format(
					[[File: %s
Selection: lines %d-%d

```
%s
```

User request (only modify the selected code above):
%s]],
					context.filename,
					context.selection.start_line,
					context.selection.end_line,
					context.selection.text,
					user_prompt
				)
			else
				full_prompt = string.format(
					[[File: %s

User request:
%s]],
					context.filename,
					user_prompt
				)
			end

			if config.use_opencode then
				send_to_opencode(full_prompt)
			elseif config.use_amp then
				local ok, amp_message = pcall(require, "amp.message")
				if ok then
					amp_message.send_message(full_prompt)
					vim.notify("Prompt sent to Amp", vim.log.levels.INFO)
				else
					vim.fn.setreg("+", full_prompt)
					vim.notify("amp.nvim not available, copied to clipboard", vim.log.levels.WARN)
				end
			else
				vim.fn.setreg("+", full_prompt)
				vim.notify("Prompt copied to clipboard", vim.log.levels.INFO)
			end
		end,
	})

	vim.cmd("startinsert")
end

function M.run_visual()
	vim.cmd('normal! "')
	local selection = get_visual_selection()
	local filename = vim.fn.expand("%:p")
	local bufnr = vim.api.nvim_get_current_buf()

	open_prompt_buffer({
		filename = filename,
		selection = selection,
		bufnr = bufnr,
	})
end

function M.run_normal()
	local filename = vim.fn.expand("%:p")
	local bufnr = vim.api.nvim_get_current_buf()

	open_prompt_buffer({
		filename = filename,
		selection = nil,
		bufnr = bufnr,
	})
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})

	vim.keymap.set("v", "<leader>a", function()
		M.run_visual()
	end, { desc = "Copy agent prompt for selection" })

	vim.keymap.set("n", "<leader>a", function()
		M.run_normal()
	end, { desc = "Copy agent prompt for file" })
end

return M
