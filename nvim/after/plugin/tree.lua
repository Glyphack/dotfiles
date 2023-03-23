vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local function open_tab_silent(node)
    local api = require("nvim-tree.api")

    api.node.open.tab(node)
    vim.cmd.tabprev()
end

local tree = require("nvim-tree")
tree.setup({
    actions = {
        open_file = {
            quit_on_open = false
        }
    },
    view = {
        mappings = {
            list = {
                { key = "T", action = "open_tab_silent", action_cb = open_tab_silent },
            },
        }
    },
    filters = { custom = { "^.git" }, git_clean = false, exclude = { ".git", "node_modules" } },
}
)

require("lsp-file-operations").setup()


vim.keymap.set("n", "<leader>pe", ":NvimTreeFindFileToggle<CR>", { noremap = true, silent = true })
