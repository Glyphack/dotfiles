vim.cmd([[packadd packer.nvim]])

require("packer").startup(function(use)
    use({ "wbthomason/packer.nvim", opt = true })

    use({
    "hrsh7th/nvim-cmp",
    requires = {
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-vsnip" },
      { "hrsh7th/vim-vsnip" },
    },
    })
    use 'hrsh7th/cmp-buffer'
    use 'hrsh7th/cmp-path'
    use 'hrsh7th/cmp-cmdline'
    use 'f3fora/cmp-spell'
    use({
    "scalameta/nvim-metals",
    requires = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
    },
    })
    use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
    use 'L3MON4D3/LuaSnip' -- Snippets plugin
    use 'morhetz/gruvbox'
    use 'junegunn/fzf'
    use ({
        'nvim-telescope/telescope.nvim',
        branch = release
    })
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
    use 'vim-syntastic/syntastic'
    use 'nvie/vim-flake8'
    use 'preservim/vim-markdown'
    use 'tpope/vim-fugitive'
    use 'andweeb/presence.nvim'
    use 'pocco81/auto-save.nvim'
    use 'kyazdani42/nvim-tree.lua'
    use 'nvim-lua/plenary.nvim'
    use 'rebelot/kanagawa.nvim'
    use 'neovim/nvim-lspconfig'
    use 'easymotion/vim-easymotion'
    end)

vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])
