-- global
vim.opt_global.completeopt = { "menuone", "noinsert", "noselect" }
vim.opt_global.shortmess:remove("F"):append("c")

-- require("nvim-tree").setup()
require("presence"):setup({
    -- General options
    auto_update        = true, -- Update activity based on autocmd events (if `false`, map or manually execute `:lua package.loaded.presence:update()`)
    neovim_image_text  = "The One True Text Editor", -- Text displayed when hovered over the Neovim image
    main_image         = "neovim", -- Main image display (either "neovim" or "file")
    client_id          = "793271441293967371", -- Use your own Discord application client id (not recommended)
    log_level          = nil, -- Log messages at or above this level (one of the following: "debug", "info", "warn", "error")
    debounce_timeout   = 10, -- Number of seconds to debounce events (or calls to `:lua package.loaded.presence:update(<filename>, true)`)
    enable_line_number = false, -- Displays the current line number instead of the current project
    blacklist          = {}, -- A list of strings or Lua patterns that disable Rich Presence if the current file name, path, or workspace matches
    buttons            = true, -- Configure Rich Presence button(s), either a boolean to enable/disable, a static table (`{{ label = "<label>", url = "<url>" }, ...}`, or a function(buffer: string, repo_url: string|nil): table)
    file_assets        = {}, -- Custom file asset definitions keyed by file names and extensions (see default config at `lua/presence/file_assets.lua` for reference)

    -- Rich Presence text options
    editing_text        = "Editing %s", -- Format string rendered when an editable file is loaded in the buffer (either string or function(filename: string): string)
    file_explorer_text  = "Browsing %s", -- Format string rendered when browsing a file explorer (either string or function(file_explorer_name: string): string)
    git_commit_text     = "Committing changes", -- Format string rendered when committing changes in git (either string or function(filename: string): string)
    plugin_manager_text = "Managing plugins", -- Format string rendered when managing plugins (either string or function(plugin_manager_name: string): string)
    reading_text        = "Reading %s", -- Format string rendered when a read-only or unmodifiable file is loaded in the buffer (either string or function(filename: string): string)
    workspace_text      = "Working on %s", -- Format string rendered when in a git repository (either string or function(project_name: string|nil, filename: string): string)
    line_number_text    = "Line %s out of %s", -- Format string rendered when `enable_line_number` is set to true (either string or function(line_number: number, line_count: number): string)
})

local lsp = require('lsp-zero')
lsp.preset('recommended')
lsp.setup()


-- Formatter and Linter
local null_ls = require("null-ls")
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
null_ls.setup({
    on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function()
                    -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
                    vim.lsp.buf.formatting_sync()
                end,
            })
        end
    end,
    sources = {
        null_ls.builtins.diagnostics.pylint.with({
            diagnostics_postprocess = function(diagnostic)
                diagnostic.code = diagnostic.message_id
            end,
        }),
        null_ls.builtins.diagnostics.flake8,
        null_ls.builtins.formatting.isort,
        null_ls.builtins.formatting.black.with({
        extra_args = {"--line-length", "79"},
    }),
        null_ls.builtins.formatting.gofumpt,
        null_ls.builtins.formatting.scalafmt,
        require("null-ls").builtins.diagnostics.eslint,
        require("null-ls").builtins.completion.spell,
    },
})

require("nvim-tree").setup()
vim.api.nvim_set_keymap(
    "n",
    ",fb",
    ":NvimTreeToggle<CR>",
    { noremap = true }
)
vim.api.nvim_set_keymap(
    "n",
    ",ff",
    ":NvimTreeFindFile<CR>",
    { noremap = true }
)

-- Telescope
require("telescope").setup {
    extensions = {
        file_browser = {
            theme = "ivy",
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
            mappings = {
                ["i"] = {
                },
                ["n"] = {
                },
            },
        },
        project = {
            base_dirs = {
                { '~/Programming/', max_depth = 4 },
                { '~/', max_depth = 2 },
            },
            hidden_files = true, -- default: false
            theme = "dropdown"
        }
    },
}
-- require("telescope").load_extension "file_browser"
-- vim.api.nvim_set_keymap(
--   "n",
--   "<space>fb",
--   ":Telescope file_browser<CR>",
--   { noremap = true }
-- )
require 'telescope'.load_extension 'project'
vim.api.nvim_set_keymap(
    'n',
    '<C-p>',
    ":lua require'telescope'.extensions.project.project{}<CR>",
    { noremap = true, silent = true }
)

require("symbols-outline").setup()

