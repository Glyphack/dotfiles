local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'
local is_bootstrap = false
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    is_bootstrap = true
    vim.fn.execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
    vim.cmd [[packadd packer.nvim]]
end

require('packer').startup(function(use)

    use 'wbthomason/packer.nvim'
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.0',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }
    use({ 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' })
    use('nvim-treesitter/playground')

    use({
        'rose-pine/neovim',
        as = 'rose-pine',
        config = function()
            vim.cmd('colorscheme rose-pine')
        end
    })
    use({ 'folke/tokyonight.nvim', })
    -- language supports
    -- scala
    use({ "scalameta/nvim-metals" })
    -- go
    use({ "leoluz/nvim-dap-go" })
    use({ "ray-x/go.nvim" })
    -- -- python
    use({ "acksld/swenv.nvim" })
    use({ "mfussenegger/nvim-dap-python" })
    -- lsp features
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

    use("folke/zen-mode.nvim")
    use({ "ray-x/lsp_signature.nvim" })
    -- editor assistant
    use({
        "danymat/neogen",
        config = function()
            require("neogen").setup {
                enabled = true,
                languages = {
                    python = {
                        template = {
                            annotation_convention = "numpydoc"
                        }
                    }
                }
            }
        end
    })
    use({ 'mzlogin/vim-markdown-toc' })
    use({ 'sainnhe/everforest' })
    use({ 'theprimeagen/harpoon' })
    use({ "simrat39/symbols-outline.nvim" })
    use({ "tpope/vim-surround" })
    use({ 'ray-x/guihua.lua' })
    -- use({ 'hrsh7th/cmp-nvim-lsp-signature-help' })
    use({ 'ray-x/cmp-treesitter' })
    use({ 'wakatime/vim-wakatime' })
    use({ 'krivahtoo/silicon.nvim', run = "./install.sh" })
    use({ "iamcco/markdown-preview.nvim", run = "cd app && npm install",
        setup = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" }, })
    use({ 'mbbill/undotree' })
    use({ 'lewis6991/gitsigns.nvim' })
    use({ 'andweeb/presence.nvim' })
    use({
        "jackMort/ChatGPT.nvim",
        config = function()
            require("chatgpt").setup({})
        end,
        requires = {
            { "MunifTanjim/nui.nvim" },
            { "nvim-lua/plenary.nvim" },
            { "nvim-telescope/telescope.nvim" },
        }
    })
    use {
        'nvim-tree/nvim-tree.lua',
        requires = {
            'nvim-tree/nvim-web-devicons',
        },
        tag = 'nightly' -- optional, updated every week. (see issue #1193)
    }

    use({
        "jose-elias-alvarez/null-ls.nvim",
    })
    use {
        'numToStr/Comment.nvim',
        config = function()
            require('Comment').setup()
        end
    }
    use { 'nvim-lualine/lualine.nvim' }
    -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
    use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make', cond = vim.fn.executable 'make' == 1 }
    use { 'github/copilot.vim' }
    use { 'akinsho/toggleterm.nvim' }
    use { 'j-hui/fidget.nvim' }

    if is_bootstrap then
        require('packer').sync()
    end
end)


if is_bootstrap then
    print '=================================='
    print '    Plugins are being installed'
    print '    Wait until Packer completes,'
    print '       then restart nvim'
    print '=================================='
    return
end

-- Automatically source and re-compile packer whenever you save this init.lua
local packer_group = vim.api.nvim_create_augroup('Packer', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
    command = 'source <afile> | PackerCompile',
    group = packer_group,
    pattern = vim.fn.expand '$MYVIMRC',
})
