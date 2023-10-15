vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("lsp-file-operations").setup()
require("neo-tree").setup({
    close_if_last_window = true,
    filesystem = {
        filtered_items = {
            visible = true,
        }
    },
})


vim.keymap.set("n", "<C-p>", ":Neotree toggle current reveal_force_cwd<cr>", { noremap = true, silent = true })

require('mini.files').setup()
local minifiles_toggle = function()
  if not MiniFiles.close() then
        MiniFiles.open(vim.api.nvim_buf_get_name(0))
        MiniFiles.reveal_cwd()
    end
end

vim.keymap.set("n", "<C-t>", minifiles_toggle, { noremap = true, silent = true })
