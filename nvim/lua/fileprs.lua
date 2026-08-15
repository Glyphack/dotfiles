--- Pick from the GitHub pull requests that touched the current file.

local M = {}

--- @class FilePrs
--- @field file string Absolute path of the file
--- @field relative string Path shown in the picker title
--- @field prs table[] Pull requests as returned by `gh pr list --json`
local FilePrs = {}
FilePrs.__index = FilePrs

local cache = {}

--- @param file string Absolute path
--- @return table[]|nil
local function fetch(file)
	local shas = vim.fn.systemlist("git log --pretty=format:'%H' --follow -n 50 -- " .. vim.fn.shellescape(file))
	if vim.v.shell_error ~= 0 or #shas == 0 then
		return nil
	end

	local seen, prs = {}, {}
	for _, sha in ipairs(shas) do
		local json = vim.fn.system(
			"gh pr list --search '" .. sha .. "' --state all --json number,title,body,author,url --limit 1"
		)
		if vim.v.shell_error == 0 then
			local ok, listed = pcall(vim.json.decode, json)
			if ok and listed and #listed > 0 and not seen[listed[1].number] then
				seen[listed[1].number] = true
				table.insert(prs, listed[1])
			end
		end
		if #prs >= 20 then
			break
		end
	end
	return prs
end

--- @return FilePrs|nil
function FilePrs.for_current_buffer()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("No file open", vim.log.levels.WARN)
		return nil
	end

	local relative = vim.fn.fnamemodify(file, ":.")
	local prs = cache[file]
	if prs then
		vim.notify("Using cached PRs for " .. relative)
	else
		vim.notify("Fetching PRs for " .. relative .. "...")
		prs = fetch(file)
		if prs and #prs > 0 then
			cache[file] = prs
		end
	end

	if not prs or #prs == 0 then
		vim.notify("No PRs found for this file", vim.log.levels.WARN)
		return nil
	end
	return setmetatable({ file = file, relative = relative, prs = prs }, FilePrs)
end

--- @return table[]
function FilePrs:items()
	local items = {}
	for i, pr in ipairs(self.prs) do
		local author = pr.author and pr.author.login or "unknown"
		items[i] = {
			text = string.format("#%d @%s %s", pr.number, author, pr.title),
			pr = pr,
		}
	end
	return items
end

--- @param buf_id number
--- @param item table
local function preview(buf_id, item)
	local pr = item.pr
	local lines = {
		"# " .. pr.title,
		"",
		"PR: #" .. pr.number,
		"Author: @" .. (pr.author and pr.author.login or "unknown"),
		"URL: " .. pr.url,
		"",
		"---",
		"",
	}
	for line in (pr.body or "No description"):gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
	vim.bo[buf_id].filetype = "markdown"
end

function FilePrs:start()
	return require("mini.pick").start({
		source = {
			name = "PRs for " .. self.relative,
			items = self:items(),
			preview = preview,
			choose = function(item)
				vim.fn.system("gh pr view --web " .. item.pr.number)
			end,
		},
	})
end

function M.pick()
	local prs = FilePrs.for_current_buffer()
	if not prs then
		return
	end
	return prs:start()
end

return M
