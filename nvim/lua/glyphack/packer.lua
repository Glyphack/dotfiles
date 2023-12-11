require("lazy").setup({
    -- telescope
    {
        "nvim-telescope/telescope.nvim",
        priority = 100,
        config = function()
        end,
    },
    "nvim-telescope/telescope-file-browser.nvim",
    "nvim-telescope/telescope-hop.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    "nvim-telescope/telescope-live-grep-args.nvim",
    "nvim-telescope/telescope-frecency.nvim",
    "Marskey/telescope-sg",
    "Marskey/telescope-sg",
    { 'prochri/telescope-all-recent.nvim',          dependencies = "kkharji/sqlite.lua", lazy = false },
    { 'nvim-telescope/telescope-smart-history.nvim' },
    {
        "ThePrimeagen/git-worktree.nvim",
        config = function()
            require("git-worktree").setup {}
        end,
    },
    {
        "AckslD/nvim-neoclip.lua",
        config = function()
            require("neoclip").setup()
        end,
    },
    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = 'make',
        lazy = false
    },
    -- telescope end
    { "nvim-treesitter/nvim-treesitter", build = ':TSUpdate' },
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
    { 'stevedylandev/flexoki-nvim',  name = 'flexoki' },
    { "ellisonleao/gruvbox.nvim",    priority = 1000 },
    { "catppuccin/nvim" },
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
    { "lvimuser/lsp-inlayhints.nvim" },
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
            { "hrsh7th/cmp-nvim-lsp-signature-help" },

            -- Snippets
            { "L3MON4D3/LuaSnip" },
            { "rafamadriz/friendly-snippets" },
        },
        branch = "v3.x",
    },
    { "folke/zen-mode.nvim" },
    { 'yamatsum/nvim-nonicons' },
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
    -- debugger
    { "mfussenegger/nvim-dap" },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { { "mfussenegger/nvim-dap" } }
    },
    -- editor assist
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
                    },
                    kotlin = {
                        template = {
                            annotation_convention = "kdoc"
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
    { "ray-x/cmp-treesitter" },
    -- { "wakatime/vim-wakatime" },
    { "krivahtoo/silicon.nvim",       build = "./install.sh" },
    {
        "iamcco/markdown-preview.nvim",
        build = function() vim.fn["mkdp#util#install"]() end,
        ft = { "markdown" },
    },
    { "mbbill/undotree" },
    { "lewis6991/gitsigns.nvim" },
    { "andweeb/presence.nvim" },
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
        }
    },
    { "jose-elias-alvarez/null-ls.nvim" },
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup({
                toggler = {
                    block = nil,
                },
            })
        end
    },
    { "wellle/targets.vim" },
    { "nvim-lualine/lualine.nvim" },
    { "github/copilot.vim" },
    { "akinsho/toggleterm.nvim" },
    { "j-hui/fidget.nvim",              tag = "legacy" },
    -- it's getting annoying when takes control of the cursor and adjusts everything I write
    -- {
    --     "gaoDean/autolist.nvim",
    --     ft = {
    --         "markdown",
    --         "text",
    --         "tex",
    --         "plaintex",
    --     },
    --     config = function()
    --         require("autolist").setup()
    --
    --         vim.keymap.set("i", "<tab>", "<cmd>AutolistTab<cr>")
    --         vim.keymap.set("i", "<s-tab>", "<cmd>AutolistShiftTab<cr>")
    --         vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>")
    --         vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<cr>")
    --         vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<cr>")
    --         vim.keymap.set("n", "<CR>", "<cmd>AutolistToggleCheckbox<cr><CR>")
    --         vim.keymap.set("n", "<C-r>", "<cmd>AutolistRecalculate<cr>")
    --
    --         -- cycle list types with dot-repeat
    --         vim.keymap.set("n", "<leader>cn", require("autolist").cycle_next_dr, { expr = true })
    --         vim.keymap.set("n", "<leader>cp", require("autolist").cycle_prev_dr, { expr = true })
    --
    --         -- if you don't want dot-repeat
    --         -- vim.keymap.set("n", "<leader>cn", "<cmd>AutolistCycleNext<cr>")
    --         -- vim.keymap.set("n", "<leader>cp", "<cmd>AutolistCycleNext<cr>")
    --
    --         -- functions to recalculate list on edit
    --         vim.keymap.set("n", ">>", ">><cmd>AutolistRecalculate<cr>")
    --         vim.keymap.set("n", "<<", "<<<cmd>AutolistRecalculate<cr>")
    --         vim.keymap.set("n", "dd", "dd<cmd>AutolistRecalculate<cr>")
    --         vim.keymap.set("v", "d", "d<cmd>AutolistRecalculate<cr>")
    --     end,
    -- },
    {
        "ruifm/gitlinker.nvim",
        dependencies = "nvim-lua/plenary.nvim",
    },

    { "tpope/vim-fugitive" },
    { "tpope/vim-repeat" },
    { "tpope/vim-unimpaired" },
    { "RRethy/nvim-treesitter-textsubjects" },
    { "nvim-treesitter/nvim-treesitter-textobjects" },
    { "ThePrimeagen/refactoring.nvim" },
    { "tpope/vim-sleuth" },
    { "phelipetls/jsonpath.nvim" },
    { "folke/neodev.nvim" },
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        ---@type Flash.Config
        opts = {},
        -- stylua: ignore
        keys = {
            { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
            {
                "S",
                mode = { "n", "x", "o" },
                function() require("flash").treesitter() end,
                desc =
                "Flash Treesitter"
            },
            {
                "r",
                mode = "o",
                function() require("flash").remote() end,
                desc =
                "Remote Flash"
            },
            {
                "R",
                mode = { "o", "x" },
                function() require("flash").treesitter_search() end,
                desc =
                "Treesitter Search"
            },
            {
                "<c-s>",
                mode = { "c" },
                function() require("flash").toggle() end,
                desc =
                "Toggle Flash Search"
            },
        },
    },
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
    { 'ActivityWatch/aw-watcher-vim' },
    {
        'TobinPalmer/rayso.nvim',
        cmd = { 'Rayso' },
        config = function()
            require('rayso').setup {}
        end
    },
    {
        "nvimdev/guard.nvim",
        dependencies = {
            "nvimdev/guard-collection",
        },
    },
    { "tpope/vim-dadbod" },
    { "hrsh7th/cmp-nvim-lua" },
    { "mtoohey31/cmp-fish" },
    {
        "aaronhallaert/advanced-git-search.nvim",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "tpope/vim-fugitive",
            "tpope/vim-rhubarb",
        },
    },
    {
        'nvimdev/hlsearch.nvim',
        event = 'BufRead',
        config = function()
            require('hlsearch').setup()
        end
    },
    -- {
    --     "sourcegraph/sg.nvim",
    --     dependencies = { "nvim-lua/plenary.nvim" },
    --
    --     build = "nvim -l build/init.lua",
    -- },
    {
        "kevinhwang91/nvim-fundo",
        config = function()
            require('fundo').install()
        end
    },
    { 'chaoren/vim-wordmotion' },
    {
        'echasnovski/mini.nvim',
        version = '*',
        config = function()
            require('mini.bracketed').setup()
            require('mini.fuzzy').setup()
            require('mini.trailspace').setup()
        end
    },
    {
        'eandrju/cellular-automaton.nvim',
        config = function()
            vim.keymap.set("n", "<leader>fml", "<cmd>CellularAutomaton game_of_life<CR>")
        end
    },
    { 'SmiteshP/nvim-navic' },
    {
        'gelguy/wilder.nvim',
        config = function()
            require('wilder').setup {
                modes = {
                    ':',
                    '/',
                    '?',
                },
            }
        end
    },
    { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {}, ft = { "json", "yaml" } },
    { 'tzachar/highlight-undo.nvim' },
    { "hdiniz/vim-gradle" },
    {
        'stevearc/aerial.nvim',
        opts = {},
        -- Optional dependencies
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons"
        },
    },
    {
        'stevearc/conform.nvim',
        opts = {},
    },
    {
  'stevearc/overseer.nvim',
  opts = {},
}
})
