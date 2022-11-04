lvim.builtin.alpha.active = true
lvim.builtin.dap.active = true
lvim.builtin.terminal.active = true
lvim.builtin.terminal.open_mapping = [[<c-\>]]
lvim.builtin.bufferline.active = false
lvim.builtin.autopairs.active = false

-- general
lvim.log.level = "warn"
lvim.format_on_save = true

-- colorscheme
vim.g.tokyonight_style = "night"
vim.g.tokyonight_italic_comments = true
vim.g.tokyonight_sidebars = { "qf", "vista_kind", "terminal", "packer" }
vim.g.tokyonight_transparent_sidebar = true
vim.g.tokyonight_colors = { hint = "orange", error = "#ff0000" }
lvim.colorscheme = "tokyonight"


-- keymappings [view all the defaults by pressing <leader>lk]
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<c-s>"] = ":w<cr>"
lvim.keys.normal_mode["<leader>m"] = ":lua require('harpoon.mark').add_file()<cr>"
lvim.keys.normal_mode["<leader>["] = ":lua require('harpoon.ui').toggle_quick_menu()<cr>"


-- lvim.keys.normal_mode["<s-l>"] = ":bufferlinecyclenext<cr>"
-- lvim.keys.normal_mode["<s-h>"] = ":bufferlinecycleprev<cr>"
-- unmap a default keymapping
-- vim.keymap.del("n", "<c-up>")
-- override a default keymapping
-- lvim.keys.normal_mode["<c-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<c-q>", ":q<cr>" )
vim.cmd([[
nnoremap <m-h> <c-w>h
nnoremap <m-j> <c-w>j
nnoremap <m-k> <c-w>k
nnoremap <m-l> <c-w>l 
tnoremap <m-h> <c-\><c-n><c-w>h
tnoremap <m-j> <c-\><c-n><c-w>j
tnoremap <m-k> <c-\><c-n><c-w>k
tnoremap <m-l> <c-\><c-n><c-w>l
tnoremap <esc> <c-\><c-n>
tnoremap <m-[> <esc>
tnoremap <c-v><esc> <esc>
]])
--
-- after changing plugin config exit and reopen lunarvim, run :packerinstall :packercompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
  "go",
  "gomod",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true

-- generic lsp settings
lvim.lsp.installer.setup.ensure_installed = {
  "sumeko_lua",
  "jsonls",
}
local formatters = require "lvim.lsp.null-ls.formatters"
local null_ls = require("null-ls")

formatters.setup {
  -- todo https://github.com/younger-1/nvim/blob/one/lua/young/lang/python.lua
  { command = "isort", filetypes = { "python" },
    extra_args = { "--line-length", "79", "--ca", "--profile", "black", "--float-to-top" },
  },
  -- { command = "black", filetypes = { "python" }, args = { "--line-length", "79" } },
  -- { command = "shfmt", filetypes = { "sh" }, args = { "-filename", "$filename", "--indent", "2" } },
  -- {
  --   command = "prettier",
  --   args = { "--print-width", "100" },
  -- },
  -- { command = "goimports", filetypes = { "go", "gomod" } },
  -- { command = "gofumpt", filetypes = { "go" } },
  -- { name = "markdownlint" },
  -- { name = "prismafmt" },
}

local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { command = "flake8", filetypes = { "python" }, extra_args = { "--max-complexity", "5", "--ignore", "e203,w503" }, },
  { command = "golangci_lint", filetypes = { "go" } },
  { name = "markdownlint" },
  { command = "eslint", filetypes = { "javascript", "typescript" } },
}

local code_actions = require "lvim.lsp.null-ls.code_actions"
code_actions.setup {
  null_ls.builtins.diagnostics.cspell,
  null_ls.builtins.code_actions.cspell,
}




-- additional plugins
lvim.plugins = {
  -- language supports
  -- scala
  {
    "scalameta/nvim-metals",
  },
  -- go
  "leoluz/nvim-dap-go",
  "ray-x/go.nvim",
  -- -- python
  "acksld/swenv.nvim",
  "mfussenegger/nvim-dap-python",
  -- lsp features
  {
    "ray-x/lsp_signature.nvim",
    event = "bufread",
    config = function() require "lsp_signature".on_attach() end,
  },
  -- editor assistant
  {
    "danymat/neogen",
    config = function()
      require("neogen").setup {
        enabled = true,
        languages = {
          python = {
            template = {
              annotation_convention = "numpydoc",
            },
          },
        },
      }
    end,
  },
  { 'mzlogin/vim-markdown-toc' },
  { 'sainnhe/everforest' },
  { 'theprimeagen/harpoon' },
  {
    "simrat39/symbols-outline.nvim",
    config = function()
      require('symbols-outline').setup()
    end
  },
  { "tpope/vim-surround", },
  { 'ray-x/guihua.lua' },
  -- { 'hrsh7th/cmp-cmdline' },
  -- { 'hrsh7th/cmp-nvim-lsp-signature-help' },
  { 'ray-x/cmp-treesitter' },
  { 'wakatime/vim-wakatime' },
  {
    "zbirenbaum/copilot.lua",
    event = { "VimEnter" },
    config = function()
      vim.defer_fn(function()
        require("copilot").setup {
          plugin_manager_path = os.getenv "LUNARVIM_RUNTIME_DIR" .. "/site/pack/packer",
        }
      end, 100)
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    after = { "copilot.lua" },
    config = function()
      require("copilot_cmp").setup()
    end,
  },
  { 'krivahtoo/silicon.nvim', run = './install.sh', config = function()
    require('silicon').setup({
      font = 'fantasquesansmono nerd font=16',
      theme = 'monokai extended',
    })
  end },
}

-- autocommands (https://neovim.io/doc/user/autocmd.html)
vim.api.nvim_create_autocmd("bufenter", {
  pattern = { "*.json", "*.jsonc" },
  -- enable wrap mode for json files only
  command = "setlocal wrap",
})
vim.api.nvim_create_autocmd("filetype", {
  pattern = "zsh",
  callback = function()
    -- let treesitter use bash highlight for zsh files as well
    require("nvim-treesitter.highlight").attach(0, "bash")
  end,
})

lvim.builtin.cmp.formatting.source_names["copilot"] = "(copilot)"
table.insert(lvim.builtin.cmp.sources, 1, { name = "copilot" })


require("user.options")
require("user.harpoon")

-- require 'navigator'.setup({
--   lsp = {
--     disable_lsp = { 'pylsp', 'jedi_language_server' },
--   }
-- })




local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local yank_group = augroup('highlightyank', {})
autocmd('textyankpost', {
  group = yank_group,
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({
      higroup = 'incsearch',
      timeout = 40,
    })
  end,
})

-- -- scala
local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
vim.api.nvim_create_autocmd("filetype", {
  pattern = { "*.scala", "*.sbt", "*.sc" },
  callback = function()
    require('user.metals').config()
  end,
  group = nvim_metals_group,
})

-- python
local python_group = vim.api.nvim_create_augroup("nvim-python", { clear = true })
vim.api.nvim_create_autocmd("filetype", {
  pattern = { "*.py", "pyproject.toml" },
  callback = function()
    require('user.python').config()
  end,
  group = python_group,
})
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "tailwindcss", "tsserver" })
require("lvim.lsp.manager").setup("tsserver", {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = true
  end,
})

-- require("lvim.lsp.manager").setup("pylsp", {
--   settings = {
--     pylsp = {
--       plugins = {
--         jedi_completion = { cache_for = { "pandas", "numpy", "tensorflow", "matplotlib", "aws_cdk" ,} },
--         autopep8 = { enabled = false },
--         flake8 = { enabled = false, },
--         pyflakes = { enabled = false },
--         mypy = { enabled = false },
--         isort = { enabled = false },
--         yapf = { enabled = false },
--         pylint = { enabled = false },
--         pydocstyle = { enabled = false },
--         pycodestyle = { enabled = false },
--         mccabe = { enabled = false },
--       }
--     }
--   }
-- }
-- )


-- -- golang
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "gopls" })
require('user.go').config()
