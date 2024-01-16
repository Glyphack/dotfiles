require("lsp-file-operations").setup()
require("mini.files").setup()
local minifiles_toggle = function()
	if not MiniFiles.close() then
		MiniFiles.open(vim.api.nvim_buf_get_name(0))
		MiniFiles.reveal_cwd()
	end
end

vim.keymap.set("n", "<C-t>", minifiles_toggle, { noremap = true, silent = true })
