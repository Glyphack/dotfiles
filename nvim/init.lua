local function map(mode, l, r, opts)
	opts = opts or {}
	opts.buffer = bufnr
	vim.keymap.set(mode, l, r, opts)
end

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

vim.opt.shiftwidth = 2

vim.cmd("filetype plugin on")

-- Save undo history
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

vim.o.background = "dark"
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
vim.opt.cursorline = false

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- spell checker
vim.opt.spell = true

vim.opt.swapfile = false

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
-- vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
-- vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Copy and paste and cut keymaps
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
vim.keymap.set("n", "x", '"_x')
vim.keymap.set("n", "X", '"_X')

-- quickfix list navigation
vim.keymap.set("n", "<M-j>", ":cn<CR>", { desc = "Move focus to the next quickfix item" })
vim.keymap.set("n", "<M-k>", ":cp<CR>", { desc = "Move focus to the previous quickfix item" })

-- useless motion can be used for something else
vim.api.nvim_set_keymap("v", "<CR>", "<nop>", { noremap = true })
vim.api.nvim_set_keymap("n", "<BS>", "<nop>", { noremap = true })
vim.api.nvim_set_keymap("v", "<BS>", "<nop>", { noremap = true })

-- terminal navigation
vim.api.nvim_set_keymap("t", "<c-w><c-h>", "<ESC><c-w><c-h>", {})
vim.api.nvim_set_keymap("t", "<c-w><c-j>", "<ESC><c-w><c-j>", {})
vim.api.nvim_set_keymap("t", "<c-w><c-k>", "<ESC><c-w><c-k>", {})
vim.api.nvim_set_keymap("t", "<c-w><c-l>", "<ESC><c-w><c-l>", {})

vim.keymap.set("v", "<leader>r", function()
	local save_previous = vim.fn.getreg("a")
	local save_previous_type = vim.fn.getregtype("a")

	vim.cmd('normal! "ay')
	local selection = vim.fn.getreg("a")
	vim.fn.setreg("a", save_previous, save_previous_type)

	local magic_chars = { "%", ".", "*", "^", "$", "[", "]", "(", ")", "\\", "/", "?", "+", "-" }
	for _, char in ipairs(magic_chars) do
		selection = selection:gsub("%" .. char, "\\" .. char)
	end

	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes(":%s/" .. selection .. "//g<Left><Left>", true, true, true),
		"n",
		false
	)
end, { noremap = true, silent = true })

vim.keymap.set("n", "<leader>cl", function()
	local file = vim.fn.expand("%")
	local line = vim.fn.line(".")
	vim.fn.setreg("+", file .. ":" .. line)
end)

-- Copy entire file content to system clipboard
vim.keymap.set("n", "<leader>fc", 'gg"+yG``', { desc = "Copy entire file to clipboard" })

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

vim.diagnostic.config({
	signs = false,
	virtual_text = {
		source = true,
	},
	float = {
		source = true,
	},
	update_in_insert = false,
	severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end
		map("gs", ":vsplit | lua vim.lsp.buf.definition()<CR>", "Goto definition in split")
		map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
		map("gr", vim.lsp.buf.references, "Goto References")
		map("gi", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
		map("gt", require("telescope.builtin").lsp_type_definitions, "Goto type definition")

		map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
		map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
		map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
		map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
		map("<leader>ps", vim.lsp.buf.signature_help, "Peek signature")
		map("K", vim.lsp.buf.hover, "Hover Documentation")
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client == nil then
			return
		end
		if client.name == "ruff" then
			client.server_capabilities.hoverProvider = false
		end
	end,
	desc = "LSP: Disable hover capability from Ruff",
})

servers = {
	"lua_ls",
	"clangd",
	"gopls",
	"pyright",
	"ruff",
	"ts_ls",
	"yamlls",
	"jsonls",
	"terraformls",
	"bashls",
	"dockerls",
	"tailwindcss",
	"html",
	"marksman",
	"emmet_ls",
	"ruby_lsp",
	"sorbet",
	"kotlin_language_server",
	"vale_ls",
	"lemminx",
	"clojure_lsp",
	"efm",
	"dartls",
}
vim.lsp.enable(servers)

vim.g.rustaceanvim = {
	tools = {},
	server = {
		on_attach = function(client, bufnr)
			map("n", "<leader>cc", ":RustLsp flyCheck<CR>", { desc = "check code" })
		end,
		default_settings = {
			["rust-analyzer"] = {
				cargo = {
					targetDir = "target/rust-analyzer",
				},
				check = {
					command = "check",
				},
				checkOnSave = {
					enable = true,
				},
			},
		},
	},
	dap = {},
}

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		"numToStr/Comment.nvim",
		opts = {
			toggler = {
				block = nil,
			},
		},
	},

	{
		"Bekaboo/dropbar.nvim",
		event = { "BufWinEnter", "BufWritePost" },
		dependencies = {
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		config = function()
			local dropbar_api = require("dropbar.api")
			vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
			vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
			vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
		end,
	},

	-- Here is a more advanced example where we pass configuration
	-- options to `gitsigns.nvim`. This is equivalent to the following lua:
	--    require('gitsigns').setup({ ... })
	--
	-- See `:help gitsigns` to understand what the configuration keys do
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			current_line_blame = false,
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
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
			require("gitlinker").setup()
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
					vim.cmd("tab :G")
				end
			end
			vim.keymap.set("n", "<leader>hs", fugitive_toggle, { desc = "Toggle Git" })
			vim.opt.diffopt:append({ "internal", "algorithm:histogram", "indent-heuristic", "linematch:60" })

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
					vim.keymap.set("n", "<leader>fp", function()
						vim.cmd("Git! forgot")
						vim.cmd("Git push --force-with-lease")
						vim.api.nvim_command("normal! <CR>")
					end, opts)
					vim.keymap.set("n", "<leader>P", function()
						vim.cmd.Git({ "pul" })
					end, opts)

					vim.keymap.set("n", "<leader>b", ":Git co -b ", opts)
				end,
			})
		end,
	},
	{ "sindrets/diffview.nvim" },

	-- Useful plugin to show you pending keybinds.
	{
		"folke/which-key.nvim",
		event = "VimEnter", -- Sets the loading event to 'VimEnter'
		config = function() -- This is the function that runs, AFTER loading
			require("which-key").setup()
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		dependencies = {
			"kkharji/sqlite.lua",
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
			-- To view the current file history in git
			{
				"isak102/telescope-git-file-history.nvim",
				dependencies = { "tpope/vim-fugitive" },
			},
		},

		config = function()
			local history_db_file = os.getenv("VIMDATA") .. "/telescope_history.sqlite3"
			local actions = require("telescope.actions")
			local action_layout = require("telescope.actions.layout")
			local lga_actions = require("telescope-live-grep-args.actions")
			local action_state = require("telescope.actions.state")
			local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")
			local builtin = require("telescope.builtin")

			require("telescope").setup({
				defaults = {
					selection_strategy = "closest",
					sorting_strategy = "descending",
					scroll_strategy = "cycle",
					color_devicons = true,
					layout_strategy = "horizontal",
					use_less = true,
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
							["<C-h>"] = action_layout.toggle_preview,
							["<C-k>"] = lga_actions.quote_prompt(),
							["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
							-- freeze the current list and start a fuzzy search in the frozen list
							["<C-f>"] = actions.to_fuzzy_refine,
						},
						n = {
							["<C-h>"] = action_layout.toggle_preview,
							["<leader>oo"] = lga_actions.quote_prompt,
						},
					},

					history = {
						path = history_db_file,
						limit = 200,
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
				},
				pickers = {
					find_files = {
						find_command = {
							"fd",
							"--type",
							"f",
							"--no-ignore",
							"--hidden",
							"--exclude",
							"target",
							"--exclude",
							"debug",
							"--exclude",
							"node_modules",
							"--exclude",
							".git",
							"--exclude",
							"*venv*",
							"--exclude",
							".cache",
							"--exclude",
							".databricks",
						},
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
					neoclip = {
						initial_mode = "normal",
					},
				},
			})

			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")
			pcall(require("telescope").load_extension, "git_file_history")
			require("telescope").load_extension("neoclip")
			require("telescope").load_extension("cmdline")
			require("telescope").load_extension("smart_history")

			local function find_files()
				builtin.find_files({
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

			local git_changed_files = function()
				builtin.git_status({
					attach_mappings = function(prompt_bufnr, map)
						local switch_to_file = function()
							local selection = action_state.get_selected_entry()
							actions.close(prompt_bufnr)
							vim.cmd(":e " .. selection.value)
						end
						map("i", "<CR>", switch_to_file)
						map("n", "<CR>", switch_to_file)
						return true
					end,
				})
			end

			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sf", find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>ss", git_changed_files, { desc = "[E]dited [F]iles" })
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
		"j-hui/fidget.nvim",
		opts = {
			progress = {
				suppress_on_insert = true,
			},
		},
	},
	{ "creativenull/efmls-configs-nvim" },
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"mrcjkb/rustaceanvim",
		version = "^6",
	},
	{
		"nvim-flutter/flutter-tools.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim",
		},
		filetypes = { "dart" },
		config = function()
			require("flutter-tools").setup({ widget_guides = { enabled = true } })
		end,
	},
	{
		"MagicDuck/grug-far.nvim",
		config = function()
			require("grug-far").setup({ prefills = { search = vim.fn.expand("<cword>") } })
			vim.keymap.set("v", "<leader>se", function()
				require("grug-far").with_visual_selection({ prefills = { paths = vim.fn.expand("%") } })
			end, { desc = "Search replace visual selection" })
		end,
	},
	-- {
	-- 	"ray-x/go.nvim",
	-- 	dependencies = {
	-- 		"ray-x/guihua.lua",
	-- 		"neovim/nvim-lspconfig",
	-- 		"nvim-treesitter/nvim-treesitter",
	-- 		"theHamsta/nvim-dap-virtual-text",
	-- 	},
	-- 	config = function()
	-- 		require("go").setup({
	-- 			lsp_codelens = false,
	-- 		})
	-- 	end,
	-- 	event = { "CmdlineEnter" },
	-- 	ft = { "go", "gomod" },
	-- 	build = ':lua require("go.install").update_all_sync()',
	-- },
	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>ff",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = "",
				desc = "Format buffer",
			},
		},
		config = function()
			local conform = require("conform")
			conform.setup({
				notify_on_error = false,
				format_on_save = function(bufnr)
					if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
						return
					end
					local disable_filetypes = { c = true, cpp = true, yaml = true }
					return {
						timeout_ms = 1800,
						lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
					}
				end,
				formatters_by_ft = {
					lua = { "stylua" },
					go = { "goimports" },
					python = { "ruff_format" },
					javascript = { "prettierd" },
					typescript = { "prettierd" },
					kotlin = { "ktlint" },
					rust = { "rustfmt" },
					yaml = { "yamlfmt" },
					toml = { "taplo" },
					shell = { "shfmt" },
					sql = { "sqlfluff" },
					terraform = { "terraform_fmt" },
					markdown = { "markdownlint" },
					json = { "jq" },
					c = { "clang-format" },
					html = { "djlint", "prettierd" },
					htmldjango = { "djlint" },
					clojure = { "cljfmt" },
					["*"] = { "trim_newlines" },
				},
			})
			vim.api.nvim_create_user_command("FormatDisable", function(args)
				if args.bang then
					-- FormatDisable! will disable formatting just for this buffer
					vim.b.disable_autoformat = true
				else
					vim.g.disable_autoformat = true
				end
			end, {
				desc = "Disable autoformat-on-save",
				bang = true,
			})
			vim.api.nvim_create_user_command("FormatEnable", function()
				vim.b.disable_autoformat = false
				vim.g.disable_autoformat = false
			end, {
				desc = "Re-enable autoformat-on-save",
			})
		end,
	},

	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			{
				"L3MON4D3/LuaSnip",
				build = "make install_jsregexp",
			},
			"hrsh7th/cmp-nvim-lsp",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "saadparwaiz1/cmp_luasnip" },
			{ "hrsh7th/cmp-nvim-lua" },
			{ "hrsh7th/cmp-nvim-lsp-signature-help" },
			{ "petertriho/cmp-git", dependencies = "nvim-lua/plenary.nvim", opts = {} },
			"lukas-reineke/cmp-rg",
			"hrsh7th/cmp-path",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			luasnip.config.setup({})
			vim.api.nvim_set_hl(0, "CmpItemKindCody", { fg = "Red" })

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone" },
				preselect = cmp.PreselectMode.None,
				mapping = cmp.mapping.preset.insert({
					-- ["<c-a>"] = cmp.mapping.complete({
					-- 	config = {
					-- 		sources = {
					-- 			{ name = "cody" },
					-- 		},
					-- 	},
					-- }),
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
					{ name = "copilot", group_index = 2 },
					{ name = "path" },
					{ name = "buffer", keyword_length = 3 },
					{ name = "nvim_lsp_signature_help" },
					{ name = "fish" },
					{ name = "nvim_lua" },
					{ name = "git" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "rg" },
				},
			})
		end,
	},

	-- color schemes
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = true,
			styles = {
				sidebars = "transparent",
				floats = "transparent",
			},
		},
	},
	{ "rebelot/kanagawa.nvim" },
	{ "lunarvim/templeos.nvim" },
	{ "shaunsingh/solarized.nvim" },
	{ "sainnhe/gruvbox-material" },
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })

			require("mini.jump").setup()
			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			--
			-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
			-- - sd'   - [S]urround [D]elete [']quotes
			-- - sr)'  - [S]urround [R]eplace [)] [']
			require("mini.surround").setup()

			local statusline = require("mini.statusline")
			statusline.setup()

			MiniStatusline.config = {
				content = {
					active = function()
						local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
						local git = MiniStatusline.section_git({ trunc_width = 75 })
						local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
						local filename = MiniStatusline.section_filename({ trunc_width = 140 })
						local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
						local location = MiniStatusline.section_location({ trunc_width = 75 })
						local search = MiniStatusline.section_searchcount({ trunc_width = 75 })

						return MiniStatusline.combine_groups({
							{ hl = mode_hl, strings = { mode } },
							{ hl = "MiniStatuslineFilename", strings = { filename } },
							"%<", -- Mark general truncate point
							{ hl = "MiniStatuslineDevinfo", strings = { git, diagnostics } },
							"%=", -- End left alignment
							{ hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
							{ hl = mode_hl, strings = { search, location } },
						})
					end,
					inactive = nil,
				},
				use_icons = true,
				set_vim_settings = true,
			}

			-- You can configure sections in the statusline by overriding their
			-- default behavior. For example, here we set the section for
			-- cursor location to LINE:COLUMN
			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_location = function()
				return "%2l:%-2v"
			end

			require("mini.files").setup({
				mappings = {
					go_in = "l",
				},
			})
			local minifiles_toggle = function()
				if not MiniFiles.close() then
					pcall(MiniFiles.open, vim.api.nvim_buf_get_name(0))
					MiniFiles.reveal_cwd()
				end
			end

			vim.keymap.set("n", "<leader>t", minifiles_toggle, { noremap = true, silent = true, desc = "Tree" })

			vim.keymap.set("n", "<leader>cp", function()
				if vim.bo.ft == "minifiles" then
					local path = MiniFiles.get_fs_entry()["path"]
					vim.fn.setreg("+", path)
					return
				end
				vim.fn.setreg("+", vim.fn.expand("%"))
			end, { noremap = true, silent = true, desc = "Copy filepath to clipboard" })

			vim.keymap.set("n", "<leader>cP", function()
				if vim.bo.ft == "minifiles" then
					local path = MiniFiles.get_fs_entry()["path"]
					vim.fn.setreg("+", path)
					return
				end
				vim.fn.setreg("+", vim.fn.expand("%:p"))
			end, { noremap = true, silent = true, desc = "Copy full filepath to clipboard" })

			require("mini.extra").setup()
			-- require("mini.visits").setup()
			--
			-- local map_vis = function(keys, call, desc)
			-- 	local rhs = "<Cmd>lua MiniVisits." .. call .. "<CR>"
			-- 	vim.keymap.set("n", "<Leader>" .. keys, rhs, { desc = desc })
			-- end
			--
			-- map_vis("vv", 'add_label("core")', "Add to core")
			-- map_vis("vc", 'select_path(nil, { filter = "core" })', "Select core")
			-- map_vis("vV", 'remove_label("core")', "Remove from core")
			-- map_vis("vC", 'remove_label("core", "")', "Remove all paths")
			--
			-- -- Iterate based on recency
			-- local map_iterate_core = function(lhs, direction, desc)
			-- 	local opts = { filter = "core", sort = sort_latest, wrap = true }
			-- 	local rhs = function()
			-- 		MiniVisits.iterate_paths(direction, vim.fn.getcwd(), opts)
			-- 	end
			-- 	vim.keymap.set("n", "<C-" .. lhs .. ">", rhs, { desc = desc })
			-- end
			-- map_iterate_core("n", "forward", "Core label (earlier)")
			-- map_iterate_core("/", "backward", "Core label (later)")

			require("mini.splitjoin").setup()
			require("mini.bracketed").setup()
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter",

		build = ":TSUpdate",
		config = function()
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
					"tsx",
					"css",
					"html",
					"htmldjango",
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
				sync_install = false,
				ignore_install = {},
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = "nvim-treesitter/nvim-treesitter-textobjects",
		config = function()
			require("nvim-treesitter.configs").setup({
				textobjects = {
					select = {
						enable = true,
						-- lookahead = true,
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
							["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
						},
						selection_modes = {
							["@parameter.outer"] = "v", -- charwise
							["@function.outer"] = "V", -- linewise
							["@class.outer"] = "<c-v>", -- blockwise
						},
						-- include_surrounding_whitespace = true,
					},
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = {
							["]m"] = "@function.outer",
						},
						goto_next_end = {
							["]M"] = "@function.outer",
						},
						goto_previous_start = {
							["[m"] = "@function.outer",
						},
						goto_previous_end = {
							["[M"] = "@function.outer",
						},
					},
				},
			})
			require("treesitter-context").setup({
				enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
				max_lines = 3, -- How many lines the window should span. Values <= 0 mean no limit.
				min_window_height = 15, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
				line_numbers = true,
				multiline_threshold = 1, -- Maximum number of lines to collapse for a single context line
				trim_scope = "inner", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
				-- Separator between context and content. Should be a single character string, like '-'.
				-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
				separator = nil,
				zindex = 20, -- The Z-index of the context window
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			})
		end,
	},
	{
		"rmagatti/gx-extended.nvim",
		config = function()
			require("gx-extended").setup({
				extensions = {
					-- Open local file paths under cursor (e.g., in Markdown)
					{
						patterns = { "*" },
						name = "local files",
						match_to_url = function(line_string)
							-- Try to resolve a local file path near the cursor and return a file:// URL.
							local cursor = vim.api.nvim_win_get_cursor(0)
							local row, col0 = cursor[1], cursor[2] -- row is 1-based, col is 0-based
							local current_line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
								or line_string
								or ""

							-- Delimiters that typically bound a path in text/markdown
							local function is_delim(ch)
								if not ch or ch == "" then
									return true
								end
								if ch:match("%s") then
									return true
								end
								return string.find("[](){}<>\"'`,;|", ch, 1, true) ~= nil
							end

							-- Expand from cursor to find a token that looks like a path
							local idx = col0 + 1 -- convert to 1-based for Lua strings
							if idx < 1 then
								idx = 1
							end
							if idx > #current_line then
								idx = #current_line
							end
							local l, r = idx, idx
							while l > 1 and not is_delim(current_line:sub(l - 1, l - 1)) do
								l = l - 1
							end
							while r <= #current_line and not is_delim(current_line:sub(r, r)) do
								r = r + 1
							end
							local token = current_line:sub(l, r - 1)

							-- Clean up common wrappers and trailing punctuation
							token = token:gsub("^%s+", ""):gsub("%s+$", "")
							token = token
								:gsub("^%(", "")
								:gsub("^%[", "")
								:gsub("^%{", "")
								:gsub("^<", "")
								:gsub('^"', "")
								:gsub("^'", "")
								:gsub("^`", "")
								:gsub("%)$", "")
								:gsub("%]$", "")
								:gsub("%}$", "")
								:gsub(">$", "")
								:gsub('"$', "")
								:gsub("'$", "")
								:gsub("`$", "")
							token = token:gsub("[,.;:|]+$", "")

							-- If cursor is on markdown link text, try to grab the (...) part surrounding it
							if (not token:find("[/\\.]")) and current_line:find("%b()") then
								local nearest
								local search_from = 1
								while true do
									local s1, e1 = current_line:find("%b()", search_from)
									if not s1 then
										break
									end
									if s1 <= idx and idx <= e1 then
										nearest = { s1, e1 }
										break
									end
									search_from = e1 + 1
								end
								if nearest then
									local inner = current_line:sub(nearest[1] + 1, nearest[2] - 1)
									inner = inner:match("%s*<?([^>]+)>?%s*$") or inner
									token = inner
								end
							end

							-- Skip obvious URLs; gx-extended handles those already
							if token:match("^%a[%w+.-]*://") then
								return nil
							end

							-- Normalize potential path: extract :line(:col)? or #Lnum anchors
							token = token:gsub("^file://", "")
							token = token:gsub("^href=", ""):gsub("^src=", "")
							token = token:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")

							local path = token
							local anchor = nil
							path, anchor = path:match("^([^#]+)#?(.*)$")

							local lineno, colno = path:match(":(%d+):(%d+)$")
							if lineno then
								path = path:gsub(":%d+:%d+$", "")
							else
								lineno = path:match(":(%d+)$")
								if lineno then
									path = path:gsub(":%d+$", "")
								end
							end

							-- Expand ~ and resolve relative paths against current file dir
							if path:sub(1, 1) == "~" then
								path = (vim.env.HOME or "~") .. path:sub(2)
							end

							local abs = nil
							if vim.uv.fs_stat(path) then
								abs = path
							else
								local base = vim.fn.expand("%:p:h")
								local normalize = (vim.fs and vim.fs.normalize)
									or function(p)
										return vim.fn.fnamemodify(p, ":p")
									end
								abs = normalize(base .. "/" .. path)
								if not vim.uv.fs_stat(abs) then
									local try = abs:gsub("%%20", " ")
									if vim.uv.fs_stat(try) then
										abs = try
									end
								end
							end

							if abs and vim.uv.fs_stat(abs) then
								-- Return a file:// URL; gx-extended will open it.
								if lineno and tonumber(lineno) then
									return string.format("file://%s#L%s", abs, lineno)
								elseif anchor and anchor:match("^L%d+$") then
									return string.format("file://%s#%s", abs, anchor)
								else
									return "file://" .. abs
								end
							end

							return nil
						end,
					},
				},
			})
		end,
	},
	{ "mzlogin/vim-markdown-toc" },
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
	{
		"rcarriga/nvim-notify",
		config = function()
			vim.notify = require("notify")
		end,
	},
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		config = function()
			require("toggleterm").setup({
				direction = "vertical",
				size = function(term)
					if term.direction == "vertical" then
						return vim.o.columns * 0.4
					end
					return 30
				end,
			})

			local toggleterm = require("toggleterm")
			local big_terminal = function()
				toggleterm.toggle(1, nil, nil, "tab", "general")
			end
			vim.keymap.set("t", "<leader>ot", big_terminal, { desc = "Toggle Big Terminal" })
			vim.keymap.set("n", "<leader>ot", big_terminal, { desc = "Toggle Big Terminal" })

			local floating_term = function()
				toggleterm.toggle(2, vim.o.columns * 0.4, nil, "vertical", "vertical")
			end
			vim.keymap.set("t", "<C-q>", floating_term, { desc = "Toggle Vertical Terminal" })
			vim.keymap.set("n", "<C-q>", floating_term, { desc = "Toggle Vertical Terminal" })

			-- watchexec

			vim.api.nvim_create_user_command("Watch", function(opts)
				local ft = vim.bo.ft
				vim.cmd(string.format('2TermExec cmd="watchexec -r -e %s %s"', ft, opts.args))
			end, { nargs = "*" })
		end,
	},

	-- {
	-- 	"mfussenegger/nvim-dap",
	-- 	dependencies = {
	-- 		"rcarriga/nvim-dap-ui",
	-- 		"williamboman/mason.nvim",
	-- 		"jay-babu/mason-nvim-dap.nvim",
	-- 		"leoluz/nvim-dap-go",
	-- 		"nvim-neotest/nvim-nio",
	-- 		"theHamsta/nvim-dap-virtual-text",
	-- 		{
	-- 			"Joakker/lua-json5",
	-- 			build = "./install.sh",
	-- 		},
	-- 	},
	-- 	config = function()
	-- 		-- require("dap.ext.vscode").json_decode = require("json5").parse
	-- 		local dap = require("dap")
	-- 		local dapui = require("dapui")
	--
	-- 		require("mason-nvim-dap").setup({
	-- 			automatic_installation = true,
	-- 			handlers = {},
	-- 			ensure_installed = {
	-- 				"delve",
	-- 			},
	-- 		})
	--
	-- 		vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
	-- 		vim.keymap.set("n", "<F1>", dap.step_into, { desc = "Debug: Step Into" })
	-- 		vim.keymap.set("n", "<F2>", dap.step_over, { desc = "Debug: Step Over" })
	-- 		vim.keymap.set("n", "<F3>", dap.step_out, { desc = "Debug: Step Out" })
	-- 		vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
	-- 		vim.keymap.set("n", "<leader>B", function()
	-- 			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
	-- 		end, { desc = "Debug: Set Breakpoint" })
	--
	-- 		dapui.setup({
	-- 			icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
	-- 			controls = {
	-- 				icons = {
	-- 					pause = "⏸",
	-- 					play = "▶",
	-- 					step_into = "⏎",
	-- 					step_over = "⏭",
	-- 					step_out = "⏮",
	-- 					step_back = "b",
	-- 					run_last = "▶▶",
	-- 					terminate = "⏹",
	-- 					disconnect = "⏏",
	-- 				},
	-- 			},
	-- 		})
	--
	-- 		vim.keymap.set("n", "<F7>", dapui.toggle, { desc = "Debug: See last session result." })
	-- 		dap.listeners.after.event_initialized["dapui_config"] = dapui.open
	-- 		dap.listeners.before.event_terminated["dapui_config"] = dapui.close
	-- 		dap.listeners.before.event_exited["dapui_config"] = dapui.close
	-- 		require("dap-go").setup()
	-- 	end,
	-- },
	-- {
	-- 	"farmergreg/vim-lastplace",
	-- 	config = function()
	-- 		vim.g.lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit"
	-- 		vim.g.lastplace_ignore_buftype = "quickfix,nofile,help"
	-- 		vim.g.lastplace_open_folds = 1
	-- 	end,
	-- },
	{
		"andrewferrier/debugprint.nvim",
		dependencies = {
			"echasnovski/mini.nvim",
		},
		opts = {},
	},
	{
		"olimorris/codecompanion.nvim",
		opts = {},
		config = function()
			require("codecompanion").setup({
				strategies = {
					chat = {
						adapter = "gemini",
					},
					inline = {
						adapter = "openai",
					},
				},
			})
		end,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			-- {
			-- 	"MeanderingProgrammer/render-markdown.nvim",
			-- 	ft = { "codecompanion" },
			-- },
			{
				"OXY2DEV/markview.nvim",
				lazy = false,
				opts = {
					preview = {
						filetypes = { "codecompanion" },
						ignore_buftypes = {},
					},
				},
				priority = 49,
			},
			{
				"echasnovski/mini.diff",
				config = function()
					local diff = require("mini.diff")
					diff.setup({
						-- Disabled by default
						source = diff.gen_source.none(),
					})
				end,
			},
		},
	},
	{
		"IogaMaster/neocord",
		event = "VeryLazy",
		opts = {
			-- General options
			logo = "auto", -- "auto" or url
			main_image = "language", -- "language" or "logo"
			client_id = "1157438221865717891", -- Use your own Discord application client id (not recommended)
			log_level = nil, -- Log messages at or above this level (one of the following: "debug", "info", "warn", "error")
			blacklist = { "work" },
			show_time = true, -- Show the timer
			global_timer = false, -- if set true, timer won't update when any event are triggered
			-- Rich Presence text options
			editing_text = "Editing %s", -- Format string rendered when an editable file is loaded in the buffer (either string or function(filename: string): string)
			file_explorer_text = "Browsing %s", -- Format string rendered when browsing a file explorer (either string or function(file_explorer_name: string): string)
			git_commit_text = "Committing changes", -- Format string rendered when committing changes in git (either string or function(filename: string): string)
			plugin_manager_text = "Managing plugins", -- Format string rendered when managing plugins (either string or function(plugin_manager_name: string): string)
			reading_text = "Reading %s", -- Format string rendered when a read-only or unmodifiable file is loaded in the buffer (either string or function(filename: string): string)
			workspace_text = "Working on %s", -- Format string rendered when in a git repository (either string or function(project_name: string|nil, filename: string): string)
			line_number_text = "Line %s out of %s", -- Format string rendered when `enable_line_number` is set to true (either string or function(line_number: number, line_count: number): string)
			terminal_text = "Using Terminal", -- Format string rendered when in terminal mode.
		},
	},
	{
		"TobinPalmer/rayso.nvim",
		cmd = { "Rayso" },
		config = function()
			require("rayso").setup({})
		end,
	},
	-- {
	-- 	dir = "/Users/shayeganhooshyari/Programming/vim-music",
	-- 	name = "vim-music",
	-- 	config = function()
	-- 		require("vim-music").setup({
	-- 			enabled = true,
	-- 			sound_command = "afplay",
	-- 			languages = {
	-- 				python = {
	-- 					enabled = true,
	-- 					sound_file = "sounds/beep.wav",
	-- 				},
	-- 			},
	-- 		})
	-- 	end,
	-- 	lazy = false,
	-- },
})

-- For when editing text files with very long lines
local wrap_mode = false
local function toggle_wrap_mode()
	wrap_mode = not wrap_mode

	if wrap_mode then
		vim.keymap.set("n", "j", "gj", { noremap = true, silent = true })
		vim.keymap.set("n", "k", "gk", { noremap = true, silent = true })
		vim.keymap.set("v", "j", "gj", { noremap = true, silent = true })
		vim.keymap.set("v", "k", "gk", { noremap = true, silent = true })
		print("Wrap mode enabled")
	else
		vim.keymap.set("n", "j", "j", { noremap = true, silent = true })
		vim.keymap.set("n", "k", "k", { noremap = true, silent = true })
		vim.keymap.set("v", "k", "k", { noremap = true, silent = true })
		vim.keymap.set("v", "j", "j", { noremap = true, silent = true })
		print("Wrap mode disabled")
	end
end

vim.api.nvim_create_user_command("GJ", toggle_wrap_mode, {})

vim.api.nvim_create_user_command("Link", function(opts)
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local selected_text = vim.fn.getline(start_pos[2]):sub(start_pos[3], end_pos[3])

	vim.api.nvim_command("normal! gv")
	if selected_text:match("^http") then
		vim.fn.setreg('"', "[](" .. selected_text .. ")")
		vim.api.nvim_command("normal! P")
		local new_pos = { start_pos[2], start_pos[3] - 1 }
		vim.api.nvim_win_set_cursor(0, new_pos)
	else
		vim.fn.setreg('"', "[" .. selected_text .. "]()")
		vim.api.nvim_command("normal! P")
		local new_pos = { start_pos[2], start_pos[3] + #selected_text + 2 }
		vim.api.nvim_win_set_cursor(0, new_pos)
	end
end, { range = true })

vim.keymap.set("v", "<leader>k", ":Link<CR>", { noremap = true, silent = true })

vim.api.nvim_create_user_command("GotoTest", function()
	local current_file = vim.fn.expand("%:p")
	local file_type = vim.bo.filetype
	local test_file

	if file_type == "go" then
		test_file = vim.fn.fnamemodify(current_file, ":r") .. "_test.go"
	else
		vim.api.nvim_err_writeln("Test file location not defined for filetype: " .. file_type)
		return
	end

	if vim.fn.filereadable(test_file) == 1 then
		vim.cmd("edit " .. test_file)
	else
		vim.api.nvim_err_writeln("Test file not found: " .. test_file)
	end
end, {})

-- Finds the test function name that you are currently inside in a go test file and run that using
-- go test ./... -run <function_name>
vim.api.nvim_create_user_command("GRunTest", function()
	local current_line = vim.fn.line(".")
	local lines = vim.fn.getline(1, current_line)
	local test_function

	for i = #lines, 1, -1 do
		local line = lines[i]
		if line:match("^func%s+Test") then
			test_function = line:match("^func%s+(Test%w+)")
			break
		end
	end

	if test_function then
		local cmd = string.format('2TermExec cmd="go test ./... -run ^%s$"', test_function)
		vim.cmd(cmd)
	else
		vim.api.nvim_err_writeln("No test function found above the current line.")
	end
end, {})

vim.o.background = "dark"
vim.cmd("colorscheme tokyonight-night")

require("bookmarks").setup()

-- vim: ts=2 sts=2 sw=2 et
