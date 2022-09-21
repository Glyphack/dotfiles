-- local fn = vim.fn
-- -- Automatically install packer
-- local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
-- if fn.empty(fn.glob(install_path)) > 0 then
--     PACKER_BOOTSTRAP = fn.system {
--         "git",
--         "clone",
--         "--depth",
--         "1",
--         "https://github.com/wbthomason/packer.nvim",
--         install_path,
--     }
--     print "Installing packer close and reopen Neovim..."
--     vim.cmd [[packadd packer.nvim]]
-- end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
    return
end

-- Have packer use a popup window
packer.init {
    display = {
        open_fn = function()
            return require("packer.util").float { border = "rounded" }
        end,
    },
}


packer.startup(function(use)
    use({ "wbthomason/packer.nvim", opt = true })
    use {
        'VonHeikemen/lsp-zero.nvim',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    }
    use 'jose-elias-alvarez/null-ls.nvim'
    use 'hrsh7th/cmp-cmdline'
    use "hrsh7th/cmp-nvim-lua"
    use {
        "folke/trouble.nvim",
        requires = "kyazdani42/nvim-web-devicons",
        config = function()
            require("trouble").setup {
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            }
        end
    }
    use {
        'kyazdani42/nvim-tree.lua',
        requires = {
            'kyazdani42/nvim-web-devicons', -- optional, for file icons
        },
        tag = 'nightly' -- optional, updated every week. (see issue #1193)
    }
    use({
        'nvim-telescope/telescope.nvim',
        branch = 'release'
    })
    use 'nvim-telescope/telescope-project.nvim'
    use 'nvim-treesitter/nvim-treesitter'
    use 'm-demare/hlargs.nvim'
    use "akinsho/bufferline.nvim"
    use "moll/vim-bbye"
    use 'BurntSushi/ripgrep'
    use 'tpope/vim-dispatch'
    use 'radenling/vim-dispatch-neovim'
    use 'vim-airline/vim-airline'
    use 'tpope/vim-commentary'
    use 'nvie/vim-flake8'
    use 'preservim/vim-markdown'
    use 'andweeb/presence.nvim'
    use 'lewis6991/gitsigns.nvim'
    -- use 'pocco81/auto-save.nvim'
    use 'nvim-lua/plenary.nvim'
    use 'neovim/nvim-lspconfig'
    use 'wakatime/vim-wakatime'
    use 'simrat39/symbols-outline.nvim'
    use 'pixelneo/vim-python-docstring'
    use 'ray-x/lsp_signature.nvim'
    use { "akinsho/toggleterm.nvim", tag = 'v2.*' }
    use 'folke/tokyonight.nvim'
    use 'ray-x/go.nvim'
    use 'ray-x/guihua.lua'
    use({
        "scalameta/nvim-metals",
        requires = {
            "nvim-lua/plenary.nvim",
        },
    })
    use 'ThePrimeagen/harpoon'
    -- use {
    --     "zbirenbaum/copilot.lua",
    --     event = "InsertEnter",

    --     config = function()
    --         vim.defer_fn(function() require("copilot").setup() end, 100)
    --     end,
    -- }
    -- use {
    --     "zbirenbaum/copilot-cmp",
    --     after = { "copilot.lua" },
    --     config = function()
    --         require("copilot_cmp").setup({
    --             method = "getCompletionsCycling",
    --             force_autofmt = true,
    --             formatters = {
    --                 label = require("copilot_cmp.format").format_label_text,
    --                 insert_text = require("copilot_cmp.format").format_label_text,
    --                 preview = require("copilot_cmp.format").deindent,
    --             },
    --         })
    --     end
    -- }
    -- if PACKER_BOOTSTRAP then
    --     require("packer").sync()
    -- end
end)
