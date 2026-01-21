local M = {}

local BOOKMARK_FILE = ".nvim-bookmarks"

M.extmark_ns = nil
M.extmark_map = {}

local function get_git_root()
	local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
	if not handle then
		return nil
	end
	local result = handle:read("*a")
	handle:close()

	if result and result ~= "" then
		return vim.trim(result)
	end
	return nil
end

local function get_bookmark_file_path()
	local git_root = get_git_root()
	if not git_root then
		return nil, "Not in a git repository"
	end
	return git_root .. "/" .. BOOKMARK_FILE, nil
end

local function read_bookmarks()
	local bookmark_file, err = get_bookmark_file_path()
	if not bookmark_file then
		return nil, err
	end

	local file = io.open(bookmark_file, "r")
	if not file then
		return {}, nil
	end

	local content = file:read("*a")
	file:close()

	if content == "" then
		return {}, nil
	end

	local ok, bookmarks = pcall(vim.json.decode, content)
	if not ok then
		return nil, "Failed to parse bookmarks file"
	end

	return bookmarks, nil
end

local function write_bookmarks(bookmarks)
	local bookmark_file, err = get_bookmark_file_path()
	if not bookmark_file then
		return false, err
	end

	local content = vim.json.encode(bookmarks)
	local file = io.open(bookmark_file, "w")
	if not file then
		return false, "Failed to open bookmarks file for writing"
	end

	file:write(content)
	file:close()
	return true, nil
end

local function get_relative_path(file, root)
	if file:sub(1, #root) == root then
		local relative = file:sub(#root + 2)
		return relative
	end
	return file
end

local function try_get_extmark_position(bookmark)
	local key = bookmark.file .. ":" .. bookmark.name
	local extmark_data = M.extmark_map[key]

	if not extmark_data then
		return nil
	end

	local ok, extmark = pcall(
		vim.api.nvim_buf_get_extmark_by_id,
		extmark_data.bufnr,
		M.extmark_ns,
		extmark_data.extmark_id,
		{ details = false }
	)

	if ok and extmark and #extmark > 0 then
		return { line = extmark[1] + 1, col = extmark[2] }
	end
	return nil
end

local function create_extmark_for_bookmark(bookmark, bufnr, line)
	local ok, extmark_id = pcall(vim.api.nvim_buf_set_extmark, bufnr, M.extmark_ns, line - 1, 0, {
		sign_text = "🔖",
		sign_hl_group = "BookmarkSign",
	})

	if not ok then
		return
	end

	local key = bookmark.file .. ":" .. bookmark.name
	M.extmark_map[key] = {
		bufnr = bufnr,
		extmark_id = extmark_id,
	}
end

function M.add_bookmark(name)
	if not name or name == "" then
		vim.ui.input({ prompt = "Bookmark name: " }, function(input)
			if input and input ~= "" then
				M.add_bookmark(input)
			end
		end)
		return
	end

	local git_root = get_git_root()
	if not git_root then
		vim.notify("Not in a git repository", vim.log.levels.ERROR)
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local current_file = vim.fn.expand("%:p")
	local current_line = vim.fn.line(".")
	local current_col = vim.fn.col(".")

	local relative_file = get_relative_path(current_file, git_root)

	local bookmarks, err = read_bookmarks()
	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	local found = false
	for i, bookmark in ipairs(bookmarks) do
		if bookmark.name == name then
			bookmarks[i] = {
				name = name,
				file = relative_file,
				line = current_line,
				col = current_col - 1,
			}
			found = true
			break
		end
	end

	if not found then
		table.insert(bookmarks, {
			name = name,
			file = relative_file,
			line = current_line,
			col = current_col - 1,
		})
	end

	local success, write_err = write_bookmarks(bookmarks)
	if not success then
		vim.notify(write_err, vim.log.levels.ERROR)
		return
	end

	local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, M.extmark_ns, current_line - 1, 0, {
		sign_text = "🔖",
		sign_hl_group = "BookmarkSign",
	})

	local key = relative_file .. ":" .. name
	M.extmark_map[key] = {
		bufnr = bufnr,
		extmark_id = extmark_id,
	}

	vim.notify("Bookmark '" .. name .. "' saved", vim.log.levels.INFO)
end

function M.delete_bookmark(name)
	local bookmarks, err = read_bookmarks()
	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	local new_bookmarks = {}
	local found = false
	for _, bookmark in ipairs(bookmarks) do
		if bookmark.name ~= name then
			table.insert(new_bookmarks, bookmark)
		else
			found = true
		end
	end

	if not found then
		vim.notify("Bookmark '" .. name .. "' not found", vim.log.levels.WARN)
		return
	end

	local success, write_err = write_bookmarks(new_bookmarks)
	if not success then
		vim.notify(write_err, vim.log.levels.ERROR)
		return
	end

	for key, _ in pairs(M.extmark_map) do
		if key:match(":" .. vim.pesc(name) .. "$") then
			local data = M.extmark_map[key]
			pcall(vim.api.nvim_buf_del_extmark, data.bufnr, M.extmark_ns, data.extmark_id)
			M.extmark_map[key] = nil
		end
	end

	vim.notify("Bookmark '" .. name .. "' deleted", vim.log.levels.INFO)
end

local function jump_to_bookmark(bookmark)
	local git_root = get_git_root()
	if not git_root then
		vim.notify("Not in a git repository", vim.log.levels.ERROR)
		return
	end

	local full_path = git_root .. "/" .. bookmark.file

	if vim.fn.filereadable(full_path) == 0 then
		vim.notify("File does not exist: " .. bookmark.file, vim.log.levels.ERROR)
		return
	end

	local extmark_pos = try_get_extmark_position(bookmark)
	if extmark_pos then
		vim.cmd("edit " .. vim.fn.fnameescape(full_path))
		vim.fn.cursor(extmark_pos.line, extmark_pos.col)
		vim.cmd("normal! zz")
		return
	end

	vim.cmd("edit " .. vim.fn.fnameescape(full_path))
	local bufnr = vim.api.nvim_get_current_buf()

	local line_count = vim.fn.line("$")
	if bookmark.line > line_count then
		vim.notify(
			"Line " .. bookmark.line .. " does not exist in file (max: " .. line_count .. ")",
			vim.log.levels.ERROR
		)
		vim.fn.cursor(line_count, 0)
	else
		vim.fn.cursor(bookmark.line, bookmark.col or 0)
		create_extmark_for_bookmark(bookmark, bufnr, bookmark.line)
	end
	vim.cmd("normal! zz")
end

function M.show_bookmarks_picker()
	local bookmarks, err = read_bookmarks()
	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	if #bookmarks == 0 then
		vim.notify("No bookmarks found", vim.log.levels.INFO)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local conf = require("telescope.config").values

	pickers
		.new({}, {
			prompt_title = "Bookmarks",
			finder = finders.new_table({
				results = bookmarks,
				entry_maker = function(bookmark)
					return {
						value = bookmark,
						display = string.format("%s → %s:%d", bookmark.name, bookmark.file, bookmark.line),
						ordinal = bookmark.name .. " " .. bookmark.file,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection then
						jump_to_bookmark(selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

function M.show_delete_picker()
	local bookmarks, err = read_bookmarks()
	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	if #bookmarks == 0 then
		vim.notify("No bookmarks found", vim.log.levels.INFO)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local conf = require("telescope.config").values

	pickers
		.new({}, {
			prompt_title = "Delete Bookmark",
			finder = finders.new_table({
				results = bookmarks,
				entry_maker = function(bookmark)
					return {
						value = bookmark,
						display = string.format("%s → %s:%d", bookmark.name, bookmark.file, bookmark.line),
						ordinal = bookmark.name .. " " .. bookmark.file,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection then
						M.delete_bookmark(selection.value.name)
					end
				end)
				return true
			end,
		})
		:find()
end

function M.setup_highlights()
	vim.api.nvim_set_hl(0, "BookmarkSign", { fg = "#f7768e", bold = true })
	vim.api.nvim_set_hl(0, "BookmarkLineNr", { fg = "#f7768e", bold = true })
end

function M.refresh_signs_for_buffer(bufnr) end

function M.refresh_all_signs() end

function M.sync_extmarks_to_file(bufnr)
	local git_root = get_git_root()
	if not git_root then
		return
	end

	local file_path = vim.api.nvim_buf_get_name(bufnr)
	local relative_file = get_relative_path(file_path, git_root)

	local bookmarks, err = read_bookmarks()
	if err or not bookmarks then
		return
	end

	local updated = false

	for i, bookmark in ipairs(bookmarks) do
		if bookmark.file == relative_file then
			local key = relative_file .. ":" .. bookmark.name
			local extmark_data = M.extmark_map[key]

			if extmark_data and extmark_data.bufnr == bufnr then
				local ok, extmark = pcall(
					vim.api.nvim_buf_get_extmark_by_id,
					bufnr,
					M.extmark_ns,
					extmark_data.extmark_id,
					{ details = false }
				)

				if ok and extmark and #extmark > 0 then
					local new_line = extmark[1] + 1
					if bookmarks[i].line ~= new_line then
						bookmarks[i].line = new_line
						updated = true
					end
				end
			end
		end
	end

	if updated then
		write_bookmarks(bookmarks)
	end
end

function M.restore_extmarks_for_buffer(bufnr)
	vim.schedule(function()
		local git_root = get_git_root()
		if not git_root then
			return
		end

		local file_path = vim.api.nvim_buf_get_name(bufnr)
		local relative_file = get_relative_path(file_path, git_root)

		local bookmarks, err = read_bookmarks()
		if err or not bookmarks then
			return
		end

		for _, bookmark in ipairs(bookmarks) do
			if bookmark.file == relative_file then
				local key = relative_file .. ":" .. bookmark.name

				if not M.extmark_map[key] then
					local ok, extmark_id =
						pcall(vim.api.nvim_buf_set_extmark, bufnr, M.extmark_ns, bookmark.line - 1, 0, {
							sign_text = "🔖",
							sign_hl_group = "BookmarkSign",
						})

					if ok then
						M.extmark_map[key] = {
							bufnr = bufnr,
							extmark_id = extmark_id,
						}
					end
				end
			end
		end
	end)
end

local current_bookmark_index = 1

function M.cycle_bookmarks(direction)
	local bookmarks, err = read_bookmarks()
	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	if #bookmarks == 0 then
		vim.notify("No bookmarks found", vim.log.levels.INFO)
		return
	end

	if direction == "forward" then
		current_bookmark_index = current_bookmark_index + 1
		if current_bookmark_index > #bookmarks then
			current_bookmark_index = 1
		end
	elseif direction == "backward" then
		current_bookmark_index = current_bookmark_index - 1
		if current_bookmark_index < 1 then
			current_bookmark_index = #bookmarks
		end
	end

	local bookmark = bookmarks[current_bookmark_index]
	jump_to_bookmark(bookmark)
	vim.notify(
		string.format("Bookmark %d/%d: %s", current_bookmark_index, #bookmarks, bookmark.name),
		vim.log.levels.DEBUG
	)
end

function M.delete_current_line_bookmark()
	local git_root = get_git_root()
	if not git_root then
		vim.notify("Not in a git repository", vim.log.levels.ERROR)
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local current_file = vim.fn.expand("%:p")
	local current_line = vim.fn.line(".")
	local relative_file = get_relative_path(current_file, git_root)

	local bookmarks, err = read_bookmarks()
	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	local new_bookmarks = {}
	local found = false
	local deleted_name = nil

	for _, bookmark in ipairs(bookmarks) do
		if bookmark.file == relative_file and bookmark.line == current_line then
			found = true
			deleted_name = bookmark.name

			local key = relative_file .. ":" .. bookmark.name
			local extmark_data = M.extmark_map[key]
			if extmark_data then
				pcall(vim.api.nvim_buf_del_extmark, extmark_data.bufnr, M.extmark_ns, extmark_data.extmark_id)
				M.extmark_map[key] = nil
			end
		else
			table.insert(new_bookmarks, bookmark)
		end
	end

	if not found then
		vim.notify("No bookmark found at current line", vim.log.levels.WARN)
		return
	end

	local success, write_err = write_bookmarks(new_bookmarks)
	if not success then
		vim.notify(write_err, vim.log.levels.ERROR)
		return
	end

	vim.notify("Bookmark '" .. deleted_name .. "' deleted", vim.log.levels.INFO)
end

function M.migrate_old_bookmarks()
	local bookmarks, err = read_bookmarks()
	if err or not bookmarks then
		return
	end

	local updated = false
	for i, bookmark in ipairs(bookmarks) do
		if not bookmark.col then
			bookmarks[i].col = 0
			updated = true
		end

		if bookmark.anchor then
			bookmarks[i].anchor = nil
			updated = true
		end

		if bookmark.timestamp then
			bookmarks[i].timestamp = nil
			updated = true
		end
	end

	if updated then
		write_bookmarks(bookmarks)
	end
end

function M.setup()
	M.extmark_ns = vim.api.nvim_create_namespace("BookmarkExtmarks")
	M.extmark_map = {}

	M.setup_highlights()
	M.migrate_old_bookmarks()

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = vim.api.nvim_create_augroup("BookmarkRestore", { clear = true }),
		callback = function(args)
			-- Defer bookmark restoration to avoid blocking file open
			vim.schedule(function()
				vim.defer_fn(function()
					if vim.api.nvim_buf_is_valid(args.buf) then
						M.restore_extmarks_for_buffer(args.buf)
					end
				end, 100)
			end)
		end,
	})

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup("BookmarkSync", { clear = true }),
		callback = function(args)
			M.sync_extmarks_to_file(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = vim.api.nvim_create_augroup("BookmarkCleanup", { clear = true }),
		callback = function(args)
			for key, data in pairs(M.extmark_map) do
				if data.bufnr == args.buf then
					M.extmark_map[key] = nil
				end
			end
		end,
	})

	vim.api.nvim_create_user_command("BookmarkAdd", function(opts)
		M.add_bookmark(opts.args)
	end, { nargs = "?", desc = "Add bookmark at current location" })

	vim.api.nvim_create_user_command("Bookmarks", function()
		M.show_bookmarks_picker()
	end, { desc = "Open bookmarks picker" })

	vim.api.nvim_create_user_command("BookmarkDelete", function()
		M.show_delete_picker()
	end, { desc = "Delete a bookmark" })

	local map_bookmark = function(keys, func, desc)
		vim.keymap.set("n", "<Leader>" .. keys, func, { desc = desc })
	end

	map_bookmark("bb", function()
		M.add_bookmark()
	end, "Add bookmark")

	map_bookmark("bc", function()
		M.show_bookmarks_picker()
	end, "Show bookmarks")

	map_bookmark("bB", function()
		M.delete_current_line_bookmark()
	end, "Remove bookmark at line")

	map_bookmark("bC", function()
		M.show_delete_picker()
	end, "Remove bookmark (picker)")

	vim.keymap.set("n", "<C-n>", function()
		M.cycle_bookmarks("forward")
	end, { desc = "Next bookmark" })

	vim.keymap.set("n", "<C-p>", function()
		M.cycle_bookmarks("backward")
	end, { desc = "Previous bookmark" })
end

return M
