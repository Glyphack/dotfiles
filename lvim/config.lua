--[[
lvim is the global options object

Linters should be
filled in as strings with either
a global executable or a path to
an executable
]]
-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT
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


-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<leader>m"] = ":lua require('harpoon.mark').add_file()<CR>"
lvim.keys.normal_mode["<leader>["] = ":lua require('harpoon.ui').toggle_quick_menu()<CR>"


-- lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
-- lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"
-- unmap a default keymapping
-- vim.keymap.del("n", "<C-Up>")
-- override a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<C-q>", ":q<cr>" )
vim.cmd([[
nnoremap <M-h> <c-w>h
nnoremap <M-j> <c-w>j
nnoremap <M-k> <c-w>k
nnoremap <M-l> <c-w>l 
tnoremap <M-h> <c-\><c-n><c-w>h
tnoremap <M-j> <c-\><c-n><c-w>j
tnoremap <M-k> <c-\><c-n><c-w>k
tnoremap <M-l> <c-\><c-n><c-w>l
tnoremap <Esc> <C-\><C-n>
tnoremap <M-[> <Esc>
tnoremap <C-v><Esc> <Esc>
]])

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
-- local _, actions = pcall(require, "telescope.actions")
-- lvim.builtin.telescope.defaults.mappings = {
--   -- for input mode
--   i = {
--     ["<C-j>"] = actions.move_selection_next,
--     ["<C-k>"] = actions.move_selection_previous,
--     ["<C-n>"] = actions.cycle_history_next,
--     ["<C-p>"] = actions.cycle_history_prev,
--   },
--   -- for normal mode
--   n = {
--     ["<C-j>"] = actions.move_selection_next,
--     ["<C-k>"] = actions.move_selection_previous,
--   },
-- }

-- Use which-key to add extra bindings with the leader-key prefix
-- lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
-- lvim.builtin.which_key.mappings["t"] = {
--   name = "+Trouble",
--   r = { "<cmd>Trouble lsp_references<cr>", "References" },
--   f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
--   d = { "<cmd>Trouble document_diagnostics<cr>", "Diagnostics" },
--   q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
--   l = { "<cmd>Trouble loclist<cr>", "LocationList" },
--   w = { "<cmd>Trouble workspace_diagnostics<cr>", "Workspace Diagnostics" },
-- }

-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
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

-- generic LSP settings

-- -- make sure server will always be installed even if the server is in skipped_servers list
lvim.lsp.installer.setup.ensure_installed = {
  "sumeko_lua",
  "jsonls",
}
---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`

-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. !!Requires `:LvimCacheReset` to take effect!!
-- ---`:LvimInfo` lists which server(s) are skipped for the current filetype
-- lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
--   return server ~= "emmet_ls"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
lvim.lsp.on_attach_callback = function(client, bufnr)
  local function buf_set_option(...)
    vim.api.nvim_buf_set_option(bufnr, ...)
  end

  --Enable completion triggered by <c-x><c-o>
  buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
end

-- -- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require "lvim.lsp.null-ls.formatters"
local null_ls = require("null-ls")

formatters.setup {
  -- TODO https://github.com/younger-1/nvim/blob/one/lua/young/lang/python.lua
  { command = "isort", filetypes = { "python" },
    extra_args = { "--line-length", "79", "--ca", "--profile", "black", "--float-to-top" },
  },
  { command = "black", filetypes = { "python" }, args = { "--line-length", "79" } },
  { command = "shfmt", filetypes = { "sh" }, args = { "-filename", "$FILENAME"
  } },
  -- { command = "packer", filetypes = { "hcl" }, args = { "fmt", "-" } },
  {
    command = "prettier",
    extra_args = { "--print-with", "100" },
    filetypes = { "typescript", "typescriptreact" },
  },
  { command = "goimports", filetypes = { "go", "gomod" } },
  { command = "gofumpt", filetypes = { "go" } },
  null_ls.builtins.formatting.markdownlint,
}

local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { command = "flake8", filetypes = { "python" }, extra_args = { "--max-complexity", "5", "--ignore", "E203,W503" }, },
  { command = "golangci_lint", filetypes = { "go" } },
  null_ls.builtins.diagnostics.markdownlint,
}

local code_actions = require "lvim.lsp.null-ls.code_actions"
code_actions.setup {
  null_ls.builtins.diagnostics.cspell,
  null_ls.builtins.code_actions.cspell,
}




-- Additional Plugins
lvim.plugins = {
  -- language supports
  -- Scala
  {
    "scalameta/nvim-metals",
  },
  -- Go
  { "ray-x/go.nvim", requires = "ray-x/guihua.lua", },
  "leoluz/nvim-dap-go",
  -- Python
  "AckslD/swenv.nvim",
  "mfussenegger/nvim-dap-python",
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
  -- LSP features
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function()
      require "lsp_signature".setup({})
    end,
  },
  -- Editor assistant
  { 'sainnhe/everforest' },
  { 'ThePrimeagen/harpoon' }, {
    "folke/todo-comments.nvim",
    event = "BufRead",
    config = function()
      require("todo-comments").setup()
    end,
  },
  {
    "simrat39/symbols-outline.nvim",
    config = function()
      require('symbols-outline').setup()
    end
  },
  { "tpope/vim-surround", },
  { 'ray-x/guihua.lua', run = 'cd lua/fzy && make' },
  { "ray-x/navigator.lua" },
  { 'hrsh7th/cmp-cmdline' },
  { 'hrsh7th/cmp-nvim-lsp-signature-help' },
  { 'ray-x/cmp-treesitter' },
  { 'wakatime/vim-wakatime' },
  { "zbirenbaum/copilot.lua",
    event = { "VimEnter" },
    config = function()
      vim.defer_fn(function()
        require("copilot").setup {
          plugin_manager_path = get_runtime_dir() .. "/site/pack/packer",
        }
      end, 100)
    end,
  },

  { "zbirenbaum/copilot-cmp",
    after = { "copilot.lua", "nvim-cmp" },
    cofnig = function()
      local copilot_cmp = require "copilot_cmp"
      copilot_cmp.setup({
        formatters = {
          insert_text = require("copilot_cmp.format").remove_existing
        },
      })
    end
  },
  -- { "github/copilot.vim" } only for the auth
  { 'krivahtoo/silicon.nvim', run = './install.sh', config = function()
    require('silicon').setup({
      font = 'FantasqueSansMono Nerd Font=16',
      theme = 'Monokai Extended',
    })
  end },
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = { "*.json", "*.jsonc" },
--   -- enable wrap mode for json files only
--   command = "setlocal wrap",
-- })
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })
local cmp = require "cmp"

lvim.builtin.cmp.sorting = {
  sorting = {
    priority_weight = 2,
    comparators = {
      cmp.config.compare.exact,
      -- copilot_cmp.comparators.prioritize,
      -- copilot_cmp.comparators.score,

      cmp.config.compare.offset,
      cmp.config.compare.scopes,
      cmp.config.compare.score,
      cmp.config.compare.recently_used,
      cmp.config.compare.locality,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  }
}
lvim.builtin.cmp.formatting.source_names["copilot"] = "(Copilot)"
table.insert(lvim.builtin.cmp.sources, 1, { name = "copilot" })



require("user.options")
require("user.harpoon")

require('guihua.maps').setup({
  maps = {
    close_view = '<C-x>',
  }
})

-- require 'navigator'.setup({
--   lsp = {
--     disable_lsp = { 'pylsp', 'jedi_language_server' },
--   }
-- })




local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local yank_group = augroup('HighlightYank', {})
autocmd('TextYankPost', {
  group = yank_group,
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({
      higroup = 'IncSearch',
      timeout = 40,
    })
  end,
})

-- -- Scala
local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "*.scala", "*.sbt", "*.sc" },
  callback = function()
    require('user.metals').config()
  end,
  group = nvim_metals_group,
})

-- Python
local python_group = vim.api.nvim_create_augroup("nvim-python", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "*.py", "pyproject.toml" },
  callback = function()
    require('user.python').config()
  end,
  group = python_group,
})
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" })

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


-- -- GOlang
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "gopls" })
require('user.go').config()
