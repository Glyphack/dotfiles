vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.relativenumber = true
vim.opt.number = true

-- Mouse mode for resizing windows
vim.opt.mouse = "a"
-- Don't show the mode, since it's already in status line
vim.opt.showmode = false

-- When indented lines are break in wrapping it shows them as indented
vim.opt.breakindent = true
vim.opt.showbreak = ">>"

-- Save undo history
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

vim.opt.termguicolors = true

-- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- spell checker
vim.opt.spell = true

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Copy and paste and cut keymaps
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

	-- "gc" to comment visual regions/lines
	{ "numToStr/Comment.nvim", opts = {
		toggler = {
			block = nil,
		},
	} },

	-- Here is a more advanced example where we pass configuration
	-- options to `gitsigns.nvim`. This is equivalent to the following lua:
	--    require('gitsigns').setup({ ... })
	--
	-- See `:help gitsigns` to understand what the configuration keys do
	{ -- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			current_line_blame = true,
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map("n", "]c", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "jump to next hunk" })
				map("n", "[c", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "jump to previous hunk" })
				-- Actions
				map("n", "<leader>hr", gs.reset_hunk, { desc = "reset hunk" })
				map("n", "<leader>hp", gs.preview_hunk, { desc = "preview hunk" })
				map("n", "<leader>hb", function()
					gs.blame_line({ full = true })
				end, { desc = "toggle blame" })
				-- NOTE: Experimental
				map("n", "<leader>hd", gs.diffthis, { desc = "diff" })
			end,
		},
	},
	{
		"ruifm/gitlinker.nvim",
		dependencies = "nvim-lua/plenary.nvim",
    config = function() 
      require("gitlinker").setup({
			callbacks = {
				["github.*.io"] = require("gitlinker.hosts").get_github_type_url,
			},
		})
    end,
		keys = {
			{
				"<leader>gb",
				'<cmd>lua require"gitlinker".get_buf_range_url()<cr>',
				desc = "Get File URL in Git Remote",
			},
		},
	},
	{
		"tpope/vim-fugitive",
		config = function()
			local fugitive_toggle = function()
				if vim.bo.ft == "fugitive" then
					vim.cmd("bd")
				else
					vim.cmd(":G")
				end
			end
			vim.keymap.set("n", "<leader>hs", fugitive_toggle, { desc = "Toggle Git" })

			local My_Fugitive = vim.api.nvim_create_augroup("My_Fugitive", {})
			local autocmd = vim.api.nvim_create_autocmd
			autocmd("BufWinEnter", {
				group = My_Fugitive,
				pattern = "*",
				callback = function()
					if vim.bo.ft ~= "fugitive" then
						return
					end
					local bufnr = vim.api.nvim_get_current_buf()
					local opts = { buffer = bufnr, remap = false }
					vim.keymap.set("n", "<leader>p", function()
						vim.cmd.Git("push")
					end, opts)
					vim.keymap.set("n", "<leader>P", function()
						vim.cmd.Git({ "pul" })
					end, opts)

					vim.keymap.set("n", "<leader>b", ":Git co -b ", opts)
				end,
			})
		end,
	},

	-- Useful plugin to show you pending keybinds.
	{
		"folke/which-key.nvim",
		event = "VimEnter", -- Sets the loading event to 'VimEnter'
		config = function() -- This is the function that runs, AFTER loading
			require("which-key").setup()

			-- Document existing key chains
			require("which-key").register({
				["<leader>c"] = { name = "[C]ode", _ = "which_key_ignore" },
				["<leader>d"] = { name = "[D]ocument", _ = "which_key_ignore" },
				["<leader>r"] = { name = "[R]ename", _ = "which_key_ignore" },
				["<leader>s"] = { name = "[S]earch", _ = "which_key_ignore" },
				["<leader>w"] = { name = "[W]orkspace", _ = "which_key_ignore" },
			})
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
			{ "nvim-tree/nvim-web-devicons" },
			"nvim-telescope/telescope-smart-history.nvim",
			"nvim-telescope/telescope-live-grep-args.nvim",
			{
				"AckslD/nvim-neoclip.lua",
				lazy = true,
				opts = {},
			},
			"jonarrien/telescope-cmdline.nvim",
		},

		config = function()
			local history_db_file = os.getenv("VIMDATA") .. "/telescope_history.sqlite3"
			local actions = require("telescope.actions")
			local action_layout = require("telescope.actions.layout")
			local lga_actions = require("telescope-live-grep-args.actions")
			local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")
			require("telescope").setup({
				selection_strategy = "closest",
				sorting_strategy = "descending",
				scroll_strategy = "cycle",
				color_devicons = true,
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
					neoclip = {
						initial_mode = "normal",
					},
				},
				layout_strategy = "horizontal",
				layout_config = {
					width = 0.99,
					height = 0.85,
					preview_cutoff = 120,
					prompt_position = "bottom",
					horizontal = {
						preview_width = function(_, cols, _)
							if cols > 200 then
								return math.floor(cols * 0.4)
							else
								return math.floor(cols * 0.4)
							end
						end,
					},
					vertical = {
						width = 0.9,
						height = 0.95,
						preview_height = 0.5,
					},
					flex = {
						horizontal = {
							preview_width = 0.9,
						},
					},
				},
				mappings = {
					i = {
						["<C-s>"] = actions.select_horizontal,
						["<C-g>"] = "move_selection_next",
						["<C-t>"] = "move_selection_previous",
						["<C-u>"] = actions.results_scrolling_down,
						["<C-d>"] = actions.results_scrolling_up,
						["<C-h>"] = action_layout.toggle_preview,
						["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
						["<C-w>"] = actions.send_selected_to_qflist + actions.open_qflist,
						["<C-k>"] = actions.cycle_history_next,
						["<C-j>"] = actions.cycle_history_prev,
						["<c-a>s"] = actions.select_all,
						["<c-a>a"] = actions.add_selection,
						["<M-f>"] = actions.results_scrolling_left,
						["<M-k>"] = actions.results_scrolling_right,
					},
					n = {
						["<leader>oo"] = lga_actions.quote_prompt(),
					},
				},

				history = {
					path = history_db_file,
					limit = 100,
				},

				file_ignore_patterns = {
					"node_modules",
					"vendor",
					".git/",
					"*.lock",
					"package-lock.json",
				},

				grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
				qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
			})

			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")
			require("telescope").load_extension("neoclip")
			require("telescope").load_extension("cmdline")
			require("telescope").load_extension("smart_history")

			local function find_files()
				require("telescope.builtin").find_files({
					sorting_strategy = "descending",
					scroll_strategy = "cycle",
					layout_config = {},
				})
			end

			local function neoclip()
				require("telescope").extensions.neoclip.default({
					initial_mode = "normal",
				})
			end

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sf", find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set("n", "<leader>sp", neoclip, { desc = "Search clipboard history" })
			vim.keymap.set(
				"n",
				"<leader>sg",
				require("telescope").extensions.live_grep_args.live_grep_args,
				{ desc = "[S]earch by [G]rep" }
			)
			vim.keymap.set(
				"n",
				"<leader>sw",
				live_grep_args_shortcuts.grep_word_under_cursor,
				{ desc = "[S]earch current [W]ord" }
			)
			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })
			vim.keymap.set(
				"v",
				"<leader>s;",
				live_grep_args_shortcuts.grep_visual_selection,
				{ desc = "Search highlighted word" }
			)
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
			vim.keymap.set("n", "<leader>/", function()
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			vim.keymap.set("n", "<leader>sc", "<cmd>Telescope cmdline<cr>", { desc = "Cmdline" })
		end,
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end
					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					map("gi", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
					map("gt", require("telescope.builtin").lsp_type_definitions, "Goto type definition")

					map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
					map(
						"<leader>ws",
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[W]orkspace [S]ymbols"
					)
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
					map("<leader>ps", vim.lsp.buf.signature_help, "Peek signature")
					map("K", vim.lsp.buf.hover, "Hover Documentation")
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					-- highlight references to symbol under cursor
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.server_capabilities.documentHighlightProvider then
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							callback = vim.lsp.buf.clear_references,
						})
					end
				end,
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			local servers = {
				clangd = {},
				gopls = {},
				pyright = {},
				rust_analyzer = {},
				tsserver = {},
				ruff_lsp = {},
				efm = {},
				yamlls = {},
				jsonls = {},
				ltex = {},
				terraformls = {},
				bashls = {},
				dockerls = {},
				tailwindcss = {},
				emmet_ls = {
					-- on_attach = on_attach,
					capabilities = capabilities,
					filetypes = {
						"css",
						"eruby",
						"html",
						"javascript",
						"javascriptreact",
						"less",
						"sass",
						"scss",
						"svelte",
						"pug",
						"typescriptreact",
						"vue",
					},
					init_options = {
						html = {
							options = {
								-- For possible options, see: https://github.com/emmetio/emmet/blob/master/src/config.ts#L79-L267
								["bem.enabled"] = true,
							},
						},
					},
				},
				golangci_lint_ls = {},
				ruby_ls = {},
				sorbet = {},
				kotlin_language_server = {},
				vale_ls = {},
				lua_ls = {
					-- cmd = {...},
					-- filetypes { ...},
					-- capabilities = {},
					settings = {
						Lua = {
							runtime = { version = "LuaJIT" },
							workspace = {
								checkThirdParty = false,
								-- Tells lua_ls where to find all the Lua files that you have loaded
								-- for your neovim configuration.
								library = {
									"${3rd}/luv/library",
									unpack(vim.api.nvim_get_runtime_file("", true)),
								},
								-- If lua_ls is really slow on your computer, you can try this instead:
								-- library = { vim.env.VIMRUNTIME },
							},
							completion = {
								callSnippet = "Replace",
							},
							-- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
							-- diagnostics = { disable = { 'missing-fields' } },
						},
					},
				},
			}

			require("mason").setup()
			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"stylua", -- Used to format lua code
			})
			-- NOTE: uncomment for installation, otherwise it's slow
			-- require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						-- This handles overriding only values explicitly passed
						-- by the server configuration above. Useful when disabling
						-- certain features of an LSP (for example, turning off formatting for tsserver)
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
			-- TODO: Add this to servers table but exclude from mason install
			require("lspconfig").dartls.setup({})
		end,
	},

	{ -- Autoformat
		"stevearc/conform.nvim",
		config = function()
			local conform = require("conform")

			conform.setup({
				notify_on_error = false,
				formatters_by_ft = {
					lua = { "stylua" },
					go = { "goimports", "golines", "gofmt" },
					javascript = { { "prettierd", "prettier" } },
					python = { "ruff_format" },
					kotlin = { "ktlint" },
					rust = { "rustfmt" },
					yaml = { "yamlfmt" },
					toml = { "taplo" },
					shell = { "shfmt" },
					sql = { "sqlfluff" },
					terraform = { "terraform_fmt" },
					markdown = { "prettierd", "markdownlint" },
					json = { "jq" },
					html = { "prettierd" },
					["*"] = { "trim_whitespace", "trim_newlines" },
				},
			})
			vim.api.nvim_set_keymap("n", "<leader>ff", "<cmd>lua require'conform'.format()<cr>", { noremap = true })

			vim.api.nvim_create_augroup("format_on_save", {})

			vim.api.nvim_create_autocmd("BufWritePost", {
				group = "format_on_save",
				pattern = { "*" },
				callback = function(args)
					if vim.bo.filetype == "kotlin" or vim.bo.filetype == "python" or vim.bo.filetype == "yaml" then
						return
					end
					conform.format({ bufnr = args.buf })
				end,
			})
		end,
	},

	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			{
				"L3MON4D3/LuaSnip",
				build = (function()
					return "make install_jsregexp"
				end)(),
			},
			"hrsh7th/cmp-nvim-lsp",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "saadparwaiz1/cmp_luasnip" },
			{ "hrsh7th/cmp-nvim-lua" },
			{ "petertriho/cmp-git", requires = "nvim-lua/plenary.nvim", opts = {} },
			"lukas-reineke/cmp-rg",
			"hrsh7th/cmp-path",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			luasnip.config.setup({})

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone,noinsert" },
				mapping = cmp.mapping.preset.insert({
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-i>"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete({}),

					-- Think of <c-l> as moving to the right of your snippet expansion.
					--  So if you have a snippet that's like:
					--  function $name($args)
					--    $body
					--  end
					--
					-- <c-l> will move you to the right of each of the expansion locations.
					-- <c-h> is similar, except moving you backwards.
					["<C-l>"] = cmp.mapping(function()
						if luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						end
					end, { "i", "s" }),
					["<C-h>"] = cmp.mapping(function()
						if luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						end
					end, { "i", "s" }),
				}),
				sources = {
					{ name = "nvim_lsp", keyword_length = 1 },
					{ name = "luasnip", keyword_length = 2 },
					{ name = "path" },
					{ name = "buffer", keyword_length = 3 },
					{ name = "fish" },
					{ name = "nvim_lua" },
					{ name = "git" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "rg" },
				},
			})
		end,
	},

	{
		"folke/tokyonight.nvim",
		lazy = false, -- make sure we load this during startup if it is your main colorscheme
		priority = 1000, -- make sure to load this before all the other start plugins
		config = function()
			vim.cmd.colorscheme("tokyonight-night")
			vim.cmd.hi("Comment gui=none")
		end,
	},

	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	{
		"echasnovski/mini.nvim",
		config = function()
			-- Better Around/Inside textobjects
			--
			-- Examples:
			--  - va)  - [V]isually select [A]round [)]paren
			--  - yinq - [Y]ank [I]nside [N]ext [']quote
			--  - ci'  - [C]hange [I]nside [']quote
			require("mini.ai").setup({ n_lines = 500 })

			if vim.bo.filetype == "yaml" or vim.bo.filetype == "json" then
				require("mini.indent").setup()
			end
			require("mini.jump").setup()
			require("mini.jump2d").setup()

			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			--
			-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
			-- - sd'   - [S]urround [D]elete [']quotes
			-- - sr)'  - [S]urround [R]eplace [)] [']
			require("mini.surround").setup()

			-- Simple and easy statusline.
			--  You could remove this setup call if you don't like it,
			--  and try some other statusline plugin
			local statusline = require("mini.statusline")
			statusline.setup()

			-- You can configure sections in the statusline by overriding their
			-- default behavior. For example, here we set the section for
			-- cursor location to LINE:COLUMN
			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_location = function()
				return "%2l:%-2v"
			end

			require("mini.files").setup()
			local minifiles_toggle = function()
				if not MiniFiles.close() then
					MiniFiles.open(vim.api.nvim_buf_get_name(0))
					MiniFiles.reveal_cwd()
				end
			end
			vim.keymap.set("n", "<leader>t", minifiles_toggle, { noremap = true, silent = true })

			require("mini.visits").setup()

			local map_vis = function(keys, call, desc)
				local rhs = "<Cmd>lua MiniVisits." .. call .. "<CR>"
				vim.keymap.set("n", "<Leader>" .. keys, rhs, { desc = desc })
			end

			map_vis("vv", 'add_label("core")', "Add to core")
			map_vis("vV", 'remove_label("core")', "Remove from core")
			map_vis("vC", 'select_path("", { filter = "core" })', "Select core (all)")
			map_vis("vc", 'select_path(nil, { filter = "core" })', "Select core (cwd)")

			-- Iterate based on recency
			local map_iterate_core = function(lhs, direction, desc)
				local opts = { filter = "core", sort = sort_latest, wrap = true }
				local rhs = function()
					MiniVisits.iterate_paths(direction, vim.fn.getcwd(), opts)
				end
				vim.keymap.set("n", "<C-" .. lhs .. ">", rhs, { desc = desc })
			end

			-- map_iterate_core("[{", "last", "Core label (earliest)")
			map_iterate_core("n", "forward", "Core label (earlier)")
			map_iterate_core("/", "backward", "Core label (later)")
			-- map_iterate_core("]}", "first", "Core label (latest)")

			require("mini.splitjoin").setup()
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			-- [[ Configure Treesitter ]] See `:help nvim-treesitter`

			---@diagnostic disable-next-line: missing-fields
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"c",
					"cpp",
					"go",
					"lua",
					"python",
					"rust",
					"typescript",
					"javascript",
					"ruby",
					"vim",
					"sql",
					"kotlin",
					"java",
					"markdown",
					"markdown_inline",
					"proto",
					"bash",
					"haskell",
					"ocaml",
					"hcl",
					"terraform",
					"dart",
				}, -- Autoinstall languages that are not installed
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
	{ "nvim-treesitter/nvim-treesitter-textobjects" },
	{
		"nvim-treesitter/nvim-treesitter-context",
		config = function()
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
	{ "github/copilot.vim" },
	{ "andweeb/presence.nvim", opts = {} },
	require("kickstart.plugins.debug"),

	{
		import = "custom.plugins",
	},
})

-- Lua function to wrap the word under the cursor with []
function Link()
	local word = vim.fn.expand("<cWORD>")
	-- if the word starts with http, don't wrap it in []
	if word:match("^http") then
		vim.api.nvim_command("normal ciW[](" .. word .. ")")
		vim.api.nvim_exec("normal! F[", true)
		return
	end
	vim.api.nvim_command("normal ciW[" .. word .. "]()")
	vim.api.nvim_exec("normal! F(", true)
end
vim.cmd("command! Link :lua Link()")

vim.cmd([[command! Replace :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- vim: ts=2 sts=2 sw=2 et
