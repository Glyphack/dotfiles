local function in_blockquote(bufnr, diagnostic)
	local row = diagnostic.range.start.line
	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
	return line:match("^%s*>") ~= nil
end

-- Returns the markdown buffer open for uri, or nil. Never creates a buffer.
local function markdown_buffer(uri)
	if vim.fn.bufexists(vim.uri_to_fname(uri)) == 0 then
		return nil
	end
	local bufnr = vim.uri_to_bufnr(uri)
	if vim.bo[bufnr].filetype ~= "markdown" then
		return nil
	end
	return bufnr
end

return {
	handlers = {
		["textDocument/publishDiagnostics"] = function(err, result, ctx)
			local bufnr = markdown_buffer(result.uri)
			if bufnr then
				result.diagnostics = vim.tbl_filter(function(diagnostic)
					return not in_blockquote(bufnr, diagnostic)
				end, result.diagnostics)
			end
			vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
		end,
	},
}
