require("lazy").setup({
    {
        "nvim-telescope/telescope.nvim",
        tag = '0.1.0',
        dependencies = { "nvim-lua/plenary.nvim" }
    },
    { 'prochri/telescope-all-recent.nvim', dependencies = "kkharji/sqlite.lua", lazy = false },
    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = 'make',
        lazy = false
    },
    { "nvim-treesitter/nvim-treesitter",   build = ':TSUpdate' },
    {
        "nvim-treesitter/nvim-treesitter-context",
        config = function(plugin)
            require 'treesitter-context'.setup {
                enable = true,            -- Enable this plugin (Can be enabled/disabled later via commands)
                max_lines = 0,            -- How many lines the window should span. Values <= 0 mean no limit.
                min_window_height = 0,    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
                line_numbers = true,
                multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
                trim_scope = 'outer',     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
                mode = 'cursor',          -- Line used to calculate context. Choices: 'cursor', 'topline'
                -- Separator between context and content. Should be a single character string, like '-'.
                -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
                separator = nil,
                zindex = 20,     -- The Z-index of the context window
                on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
            }
        end
    },
    { "nvim-treesitter/playground" },
    -- colorschemes
    {
        "rose-pine/neovim",
        name = "rose-pine",
        config = function(plugin)
            vim.cmd("colorscheme rose-pine")
        end
    },
    { "svrana/neosolarized.nvim" },
    { "folke/tokyonight.nvim" },
    -- editing assistant
    { "windwp/nvim-ts-autotag" },
    { "windwp/nvim-autopairs" },
    -- language supports
    -- scala
    { "scalameta/nvim-metals" },
    -- go
    { "leoluz/nvim-dap-go" },
    { "ray-x/go.nvim" },
    -- python
    { "acksld/swenv.nvim" },
    { "mfussenegger/nvim-dap-python" },
    -- lsp features
    {
        "VonHeikemen/lsp-zero.nvim",
        dependencies = {
            -- LSP Support
            { "neovim/nvim-lspconfig" },
            { "williamboman/mason.nvim" },
            { "williamboman/mason-lspconfig.nvim" },

            -- Autocompletion
            { "hrsh7th/nvim-cmp" },
            { "hrsh7th/cmp-buffer" },
            { "hrsh7th/cmp-path" },
            { "saadparwaiz1/cmp_luasnip" },
            { "hrsh7th/cmp-nvim-lsp" },
            { "hrsh7th/cmp-nvim-lua" },
            { "hrsh7th/cmp-nvim-lsp-signature-help" },
            { "lukas-reineke/cmp-rg" },

            -- Snippets
            { "L3MON4D3/LuaSnip" },
            { "rafamadriz/friendly-snippets" },
        }
    },
    { "folke/zen-mode.nvim" },
    { "ray-x/lsp_signature.nvim" },
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
        },
    },
    {
        "glepnir/lspsaga.nvim",
        event = "LspAttach",
        config = function()
            require("lspsaga").setup({
                ui = {
                    winblend = 10,
                    border = 'rounded',
                    colors = {
                        normal_bg = '#002b36'
                    }
                },
                symbol_in_winbar = {
                    enable = false
                }
            })
        end,
        dependencies = { { "nvim-tree/nvim-web-devicons" } }
    },
    { "nvim-telescope/telescope-file-browser.nvim" },
    -- debugger
    { "mfussenegger/nvim-dap" },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { { "mfussenegger/nvim-dap" } }
    },
    -- editor assista
    {
        "danymat/neogen",
        config = function(plugin)
            require("neogen").setup {
                enabled = true,
                languages = {
                    python = {
                        template = {
                            annotation_convention = "numpydoc"
                        }
                    },
                    rust = {
                        template = {
                            annotation_convention = "rustdoc"
                        }
                    }
                }
            }
        end
    },
    { "mzlogin/vim-markdown-toc" },
    { "sainnhe/everforest" },
    { "theprimeagen/harpoon" },
    { "simrat39/symbols-outline.nvim" },
    { "tpope/vim-surround" },
    { "ray-x/guihua.lua" },
    { "hrsh7th/cmp-nvim-lsp-signature-help" },
    { "ray-x/cmp-treesitter" },
    { "wakatime/vim-wakatime" },
    { "krivahtoo/silicon.nvim",             build = "./install.sh" },
    {
        "iamcco/markdown-preview.nvim",
        build = "cd app && npm install",
        config = function() vim.g.mkdp_filetypes = { "markdown" } end,
        ft = { "markdown" },
    },
    { "mbbill/undotree" },
    { "lewis6991/gitsigns.nvim" },
    { "andweeb/presence.nvim" },
    {
        "jackMort/ChatGPT.nvim",
        config = function()
            require("chatgpt").setup({})
        end,
        dependencies = {
            { "MunifTanjim/nui.nvim" },
            { "nvim-lua/plenary.nvim" },
            { "nvim-telescope/telescope.nvim" },
        }
    },
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        version = "nightly"
    },

    { "jose-elias-alvarez/null-ls.nvim" },
    {
        "numToStr/Comment.nvim",
        config = function(plugin)
            require("Comment").setup()
        end
    },
    { "nvim-lualine/lualine.nvim" },
    { "github/copilot.vim" },
    { "akinsho/toggleterm.nvim" },
    { "j-hui/fidget.nvim" },
    {
        "gaoDean/autolist.nvim",
        ft = {
            "markdown",
            "text",
            "tex",
            "plaintex",
        },
        config = function(plugin)
            local autolist = require("autolist")
            autolist.setup()
            autolist.create_mapping_hook("i", "<CR>", autolist.new)
            autolist.create_mapping_hook("i", "<Tab>", autolist.indent)
            autolist.create_mapping_hook("i", "<S-Tab>", autolist.indent, "<C-D>")
            autolist.create_mapping_hook("n", "o", autolist.new)
            autolist.create_mapping_hook("n", "O", autolist.new_before)
            autolist.create_mapping_hook("n", ">>", autolist.indent)
            autolist.create_mapping_hook("n", "<<", autolist.indent)
            autolist.create_mapping_hook("n", "<C-r>", autolist.force_recalculate)
            autolist.create_mapping_hook("n", "<leader>x", autolist.invert_entry, "")
            vim.api.nvim_create_autocmd("TextChanged", {
                pattern = "*",
                callback = function()
                    vim.cmd.normal({ autolist.force_recalculate(nil, nil), bang = false })
                end
            })
        end,
    },
    {
        "ruifm/gitlinker.nvim",
        dependencies = "nvim-lua/plenary.nvim",
    },

    { "tpope/vim-fugitive" },
    { "tpope/vim-repeat" },
    { "RRethy/nvim-treesitter-textsubjects" },
    { "ThePrimeagen/refactoring.nvim" },
    { "tpope/vim-sleuth" },
    { "mrjones2014/nvim-ts-rainbow" },
    { "phelipetls/jsonpath.nvim" },
    { "folke/neodev.nvim" },

    { "antosha417/nvim-lsp-file-operations" },
    {
        "DNLHC/glance.nvim",
        config = function(plugin)
            require('glance').setup({
            })
        end
    },
    {
        "AckslD/nvim-neoclip.lua",
        config = function()
            require('neoclip').setup()
        end
    },
    { "tpope/vim-rake" },
    { "tpope/vim-rails" },
})
