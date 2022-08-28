vim.cmd([[packadd packer.nvim]])


require("packer").startup(function(use)
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
    use 'f3fora/cmp-spell'
    use({
        "scalameta/nvim-metals",
        requires = {
            "nvim-lua/plenary.nvim",
        },
    })
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
    use 'kyazdani42/blue-moon'
    use 'morhetz/gruvbox'
    use 'junegunn/fzf'
    use({
        'nvim-telescope/telescope.nvim',
        branch = release
    })
    use "nvim-telescope/telescope-file-browser.nvim"
    use 'nvim-telescope/telescope-project.nvim'
    use 'nvim-treesitter/nvim-treesitter'
    use 'BurntSushi/ripgrep'
    use 'kyazdani42/nvim-web-devicons'
    use 'ray-x/go.nvim'
    use 'ray-x/guihua.lua'
    use 'tpope/vim-dispatch'
    use 'radenling/vim-dispatch-neovim'
    use 'vim-airline/vim-airline'
    use 'tpope/vim-commentary'
    use 'tmhedberg/SimpylFold'
    use 'nvie/vim-flake8'
    use 'preservim/vim-markdown'
    use 'tpope/vim-fugitive'
    use 'andweeb/presence.nvim'
    -- use 'pocco81/auto-save.nvim'
    use 'nvim-lua/plenary.nvim'
    use 'rebelot/kanagawa.nvim'
    use 'neovim/nvim-lspconfig'
    use 'wakatime/vim-wakatime'
    use 'simrat39/symbols-outline.nvim'
    use 'pixelneo/vim-python-docstring'
end)

vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])
