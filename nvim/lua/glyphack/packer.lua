require("lazy").setup({
	-- telescope
	{
		"nvim-telescope/telescope.nvim",
		priority = 100,
		config = function() end,
	},
	"nvim-telescope/telescope-live-grep-args.nvim",
	"Marskey/telescope-sg",
	{ "prochri/telescope-all-recent.nvim", dependencies = "kkharji/sqlite.lua", lazy = false },
	{ "nvim-telescope/telescope-smart-history.nvim" },
	{
		"ThePrimeagen/git-worktree.nvim",
		config = function()
			require("git-worktree").setup({})
		end,
	},
	{
		"AckslD/nvim-neoclip.lua",
		config = function()
			require("neoclip").setup()
		end,
		lazy = true,
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
		lazy = false,
	},

	-- treesitter
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
	{
		"nvim-treesitter/nvim-treesitter-context",
		config = function(plugin)
			require("treesitter-context").setup({
				enable = true,
				max_lines = 5,
				min_window_height = 0,
				line_numbers = true,
				multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
				trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
				separator = nil,
				zindex = 20, -- The Z-index of the context window
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			})
		end,
	},
	{ "RRethy/nvim-treesitter-textsubjects" },
	{ "nvim-treesitter/nvim-treesitter-textobjects" },
	{
		"stevearc/aerial.nvim",
		opts = {
			on_attach = function(bufnr)
				vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
				vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
			end,
		},
		keys = {
			{ "<leader>ta", "<cmd>AerialToggle<CR>" },
			dependencies = {
				"nvim-treesitter/nvim-treesitter",
				"nvim-tree/nvim-web-devicons",
			},
		},
	},

	-- colorschemes
	{
		"rose-pine/neovim",
		config = function(plugin)
			vim.cmd("colorscheme rose-pine")
		end,
	},
	{ "svrana/neosolarized.nvim" },
	{ "folke/tokyonight.nvim" },
	{ "stevedylandev/flexoki-nvim", name = "flexoki" },
	{ "ellisonleao/gruvbox.nvim", priority = 1000 },
	{ "catppuccin/nvim" },
	{ "sainnhe/everforest" },

	-- lsp
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
			{ "petertriho/cmp-git", requires = "nvim-lua/plenary.nvim" },
			{ "lukas-reineke/cmp-rg" },
			{ "hrsh7th/cmp-nvim-lsp-signature-help" },
			{ "hrsh7th/cmp-nvim-lua" },
			{ "ray-x/cmp-treesitter" },
			{ "mtoohey31/cmp-fish" },
			-- Snippets
			{ "L3MON4D3/LuaSnip" },
			{ "rafamadriz/friendly-snippets" },
		},
		branch = "v3.x",
	},
	{
		"glepnir/lspsaga.nvim",
		event = "LspAttach",
		config = function()
			require("lspsaga").setup({
				ui = {
					winblend = 10,
					border = "rounded",
					colors = {
						normal_bg = "#002b36",
					},
				},
				symbol_in_winbar = {
					enable = false,
				},
			})
		end,
		dependencies = { { "nvim-tree/nvim-web-devicons" } },
	},
	{ "antosha417/nvim-lsp-file-operations" },
	{ "sourcegraph/sg.nvim" },
	{
		"dgagn/diagflow.nvim",
		opts = {
			placement = "inline",
			toggle_event = { "InsertEnter" },
			inline_padding_left = 3,
		},
	},

	-- format and lint
	{
		"stevearc/conform.nvim",
		opts = {},
	},
	{
		"creativenull/efmls-configs-nvim",
		dependencies = { "neovim/nvim-lspconfig" },
	},

	-- language supports
	{
		"stevearc/overseer.nvim",
		opts = {},
	},
	-- scala
	{ "scalameta/nvim-metals", lazy = true },
	-- go
	{ "leoluz/nvim-dap-go" },
	{ "ray-x/go.nvim" },
	-- python
	{ "acksld/swenv.nvim" },
	{ "mfussenegger/nvim-dap-python" },
	-- ruby
	{ "tpope/vim-rake", lazy = true },
	{ "tpope/vim-rails", lazy = true },

	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = { auto_preview = false },
		keys = {
			{
				"<leader>xx",
				mode = { "n" },
				function()
					require("trouble").toggle()
				end,
				desc = "Trouble Toggle",
			},
			{
				"gR",
				mode = { "n" },
				function()
					require("trouble").toggle("lsp_references")
				end,
				desc = "Trouble Toggle",
			},
			-- Not working properly
			-- {
			-- 	"[d",
			-- 	mode = { "n" },
			-- 	function()
			-- 		require("trouble").previous({ skip_groups = true, jump = true })
			-- 	end,
			-- 	desc = "Trouble Toggle",
			-- },
			-- {
			-- 	"]d",
			-- 	mode = { "n" },
			-- 	function()
			-- 		require("trouble").next({ skip_groups = true, jump = true })
			-- 	end,
			-- 	desc = "Trouble Toggle",
			-- },
		},
	},

	-- debugger
	{ "mfussenegger/nvim-dap" },
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { { "mfussenegger/nvim-dap" } },
	},

	-- coding
	{ "folke/zen-mode.nvim" },
	{
		"danymat/neogen",
		config = function(plugin)
			require("neogen").setup({
				enabled = true,
				languages = {
					python = {
						template = {
							annotation_convention = "numpydoc",
						},
					},
					rust = {
						template = {
							annotation_convention = "rustdoc",
						},
					},
					kotlin = {
						template = {
							annotation_convention = "kdoc",
						},
					},
				},
			})
		end,
	},
	{ "mzlogin/vim-markdown-toc" },
	{ "theprimeagen/harpoon" },
	{ "krivahtoo/silicon.nvim", build = "./install.sh" },
	{
		"TobinPalmer/rayso.nvim",
		cmd = { "Rayso" },
		config = function()
			require("rayso").setup({})
		end,
	},
	{
		"iamcco/markdown-preview.nvim",
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		ft = { "markdown" },
	},
	-- { "mbbill/undotree" },
	{ "lewis6991/gitsigns.nvim" },
	{ "andweeb/presence.nvim" },
	{ "nvim-lualine/lualine.nvim" },
	{ "j-hui/fidget.nvim", tag = "legacy" },
	{ "tpope/vim-repeat", event = "VeryLazy" },
	{ "tpope/vim-unimpaired" },
	{ "tpope/vim-sleuth" },
	{ "phelipetls/jsonpath.nvim" },
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup({
				toggler = {
					block = nil,
				},
			})
		end,
	},
	{ "github/copilot.vim" },
	-- Experimenting with mini jumps
	-- {
	-- 	"folke/flash.nvim",
	-- 	event = "VeryLazy",
	-- 	---@type Flash.Config
	-- 	opts = {},
	--        -- stylua: ignore
	--        keys = {
	--            {
	--                "<leader>sj",
	--                mode = { "n", "x", "o" },
	--                function() require("flash").jump() end,
	--                desc = "Flash"
	--            },
	--            {
	--                "<leader>st",
	--                mode = { "n", "x", "o" },
	--                function() require("flash").treesitter() end,
	--                desc =
	--                "Flash Treesitter"
	--            },
	--            {
	--                "<c-s>",
	--                mode = { "c" },
	--                function() require("flash").toggle() end,
	--                desc =
	--                "Toggle Flash Search"
	--            },
	--        },
	-- },
	{
		"AckslD/nvim-neoclip.lua",
		config = function()
			require("neoclip").setup()
		end,
	},
	{
		"echasnovski/mini.nvim",
		version = "*",
		config = function()
			require("mini.bracketed").setup()
			require("mini.fuzzy").setup()
			require("mini.trailspace").setup()
			require("mini.ai").setup()
			if vim.bo.filetype == "yaml" or vim.bo.filetype == "json" then
				require("mini.indent").setup()
			end
			require("mini.jump").setup()
			require("mini.jump2d").setup()
		end,
	},
	{ "SmiteshP/nvim-navic", lazy = true },

	-- terminal
	{ "akinsho/toggleterm.nvim" },

	-- git
	{
		"ruifm/gitlinker.nvim",
		dependencies = "nvim-lua/plenary.nvim",
	},
	{ "tpope/vim-fugitive" },
	{
		"aaronhallaert/advanced-git-search.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"tpope/vim-fugitive",
			"tpope/vim-rhubarb",
		},
	},

	{ "ActivityWatch/aw-watcher-vim" },
	{ "tpope/vim-dadbod" },

	-- vim overrides
	{ "chaoren/vim-wordmotion" },
	{
		"nvimdev/hlsearch.nvim",
		event = "BufRead",
		config = function()
			require("hlsearch").setup()
		end,
	},
	{
		"gx-extended.vim",
	},
	{
		"gelguy/wilder.nvim",
		config = function()
			require("wilder").setup({
				modes = {
					":",
					"/",
					"?",
				},
			})
		end,
	},

	{ "folke/neodev.nvim" },
	{
		"eandrju/cellular-automaton.nvim",
		config = function()
			vim.keymap.set("n", "<leader>fml", "<cmd>CellularAutomaton game_of_life<CR>")
		end,
	},
})
