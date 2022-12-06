require("user.options")
require("user.harpoon")

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.dap.active = true
lvim.builtin.terminal.active = true
lvim.builtin.bufferline.active = false
lvim.builtin.autopairs.active = false
lvim.builtin.nvimtree.setup.view.side = "left"
-- lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.builtin.lualine.options.theme = "tokyonight"

-- colorscheme
require("tokyonight").setup({
  style = "storm",
})


-- keymappings [view all the defaults by pressing <leader>lk]
lvim.leader = "space"
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

lvim.lsp.buffer_mappings.normal_mode['gi'] = { vim.lsp.buf.implementation, "Show implementation" }

lvim.builtin.treesitter.highlight.enable = true
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
  "lua",
  "go",
  "scala",
  "java",
}

local null_ls = require("null-ls")
local code_actions = require "lvim.lsp.null-ls.code_actions"
code_actions.setup {
  null_ls.builtins.diagnostics.cspell,
  null_ls.builtins.code_actions.cspell,
}

local formatters = require "lvim.lsp.null-ls.formatters"

formatters.setup {
  { name = "prettierd", },
}

lvim.lsp.installer.setup.ensure_installed = {
  "jsonls",
}
vim.api.nvim_create_autocmd("bufenter", {
  pattern = { "*.json", "*.jsonc" },
  -- enable wrap mode for json files only
  command = "setlocal wrap",
})

lvim.builtin.cmp.formatting.source_names["copilot"] = "(copilot)"
table.insert(lvim.builtin.cmp.sources, 1, { name = "copilot" })



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

lvim.plugins = {
  -- language supports
  -- scala
  "scalameta/nvim-metals",
  -- go
  "leoluz/nvim-dap-go",
  "ray-x/go.nvim",
  -- -- python
  "acksld/swenv.nvim",
  "mfussenegger/nvim-dap-python",
  -- lsp features
  "ray-x/lsp_signature.nvim",
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    config = function()
      require("lsp_lines").setup()
    end,
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
  { "simrat39/symbols-outline.nvim" },
  { "tpope/vim-surround", },
  { 'ray-x/guihua.lua' },
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
  { 'krivahtoo/silicon.nvim', run = './install.sh' },
  { "iamcco/markdown-preview.nvim", run = "cd app && npm install",
    setup = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" }, }
}
require "lsp_signature".setup()
require('symbols-outline').setup()
