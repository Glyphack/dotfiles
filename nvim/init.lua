local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

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

vim.bo.swapfile = false

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
	-- UI
	{
		"nvim-focus/focus.nvim",
		version = false,
		config = function()
			require("focus").setup()
		end,
	},

	"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

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
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "creativenull/efmls-configs-nvim" },
			{
				"j-hui/fidget.nvim",
				opts = {
					progress = {
						suppress_on_insert = true,
					},
				},
			},
		},
		config = function()
			vim.diagnostic.config({
				virtual_text = {
					source = true,
				},
				float = {
					source = true,
				},
				update_in_insert = true,
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
					map(
						"<leader>ws",
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[W]orkspace [S]ymbols"
					)
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
					map("<leader>ps", vim.lsp.buf.signature_help, "Peek signature")
					map("K", vim.lsp.buf.hover, "Hover Documentation")

					-- highlight references to symbol under cursor
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.server_capabilities.documentHighlightProvider then
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							callback = function()
								if next(vim.lsp.get_clients()) ~= nil then
									return
								end
								vim.lsp.buf.document_highlight()
							end,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							callback = function()
								if next(vim.lsp.get_clients()) ~= nil then
									return
								end
								vim.lsp.buf.clear_references()
							end,
						})
					end
				end,
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			local languages = {
				lua = { require("efmls-configs.formatters.stylua") },
				proto = {
					require("efmls-configs.linters.buf"),
				},
				bash = {
					require("efmls-configs.linters.shellcheck"),
				},
				markdown = {
					require("efmls-configs.linters.proselint"),
				},
				gitcommit = {
					require("efmls-configs.linters.proselint"),
				},
				["="] = {},
			}

			local efmls_config = {
				settings = {
					rootMarkers = { ".git/" },
					languages = languages,
				},
				init_options = {
					documentRangeFormatting = true,
					documentFormatting = true,
					codeAction = true,
				},
			}

			local servers = {
				clangd = {
					keys = {
						{
							"<leader>ch",
							"<cmd>ClangdSwitchSourceHeader<cr>",
							desc = "Switch Source/Header (C/C++)",
						},
					},
					root_dir = function(fname)
						return require("lspconfig.util").root_pattern(
							"Makefile",
							"configure.ac",
							"configure.in",
							"config.h.in",
							"meson.build",
							"meson_options.txt",
							"build.ninja"
						)(fname) or require("lspconfig.util").root_pattern(
							"compile_commands.json",
							"compile_flags.txt"
						)(fname) or require("lspconfig.util").find_git_ancestor(fname)
					end,
					capabilities = {
						offsetEncoding = { "utf-16" },
					},
					cmd = {
						"clangd",
						"--background-index",
						"--clang-tidy",
						"--header-insertion=iwyu",
						"--completion-style=detailed",
						"--function-arg-placeholders",
						"--fallback-style=llvm",
					},
					init_options = {
						usePlaceholders = true,
						completeUnimported = true,
						clangdFileStatus = true,
					},
				},
				gopls = {
					settings = {
						gopls = {
							gofumpt = true,
						},
					},
				},
				basedpyright = {
					settings = {
						basedpyright = {
							disableOrganizeImports = true,
							analysis = {
								ignore = { "*" },
							},
						},
					},
				},
				ts_ls = {},
				ruff = {
					init_options = {
						settings = {
							fixAll = true,
							formatter = {
								enabled = true,
							},
							linter = {
								enabled = true,
							},
						},
					},
				},
				yamlls = {},
				jsonls = {},
				ltex = {
					settings = {
						ltex = {
							language = "en-GB",
						},
					},
					filetypes = {
						"bib",
						"gitcommit",
						"markdown",
						"org",
						"plaintex",
						"rst",
						"rnoweb",
						"tex",
						"pandoc",
						"quarto",
						"rmd",
						"context",
						"mail",
						"text",
					},
				},
				terraformls = {},
				bashls = {},
				dockerls = {},
				tailwindcss = {
					tailwindCSS = {
						classAttributes = { "class", "className", "class:list", "classList", "ngClass" },
						includeLanguages = {
							eelixir = "html-eex",
							eruby = "erb",
							htmlangular = "html",
							templ = "html",
						},
						lint = {
							cssConflict = "warning",
							invalidApply = "error",
							invalidConfigPath = "error",
							invalidScreen = "error",
							invalidTailwindDirective = "error",
							invalidVariant = "error",
							recommendedVariantOrder = "warning",
						},
						validate = true,
					},
				},
				html = { filetypes = { "html", "templ", "htmldjango" } },
				marksman = {},
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
				html = {
					init_options = {
						configurationSection = { "html", "css", "javascript" },
						embeddedLanguages = {
							css = true,
							javascript = true,
						},
					},
				},
				golangci_lint_ls = {},
				ruby_lsp = {},
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
				typos_lsp = {},
				lemminx = {},
			}

			require("mason").setup()
			local tool_ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(tool_ensure_installed, {
				"stylua", -- Used to format lua code
			})
			-- NOTE: uncomment for installation, otherwise it's slow
			require("mason-tool-installer").setup({
				ensure_installed = tool_ensure_installed,
				debounce_hours = 72,
				auto_update = true,
			})
			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						if server_name == "rust_analyzer" then
							return
						end
						local server = servers[server_name] or {}
						-- This handles overriding only values explicitly passed
						-- by the server configuration above. Useful when disabling
						-- certain features of an LSP (for example, turning off formatting for tsserver)
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
				ensure_installed = servers,
				automatic_installation = true,
			})
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client == nil then
						return
					end
					if client.name == "ruff" then
						-- Disable hover in favor of Pyright
						client.server_capabilities.hoverProvider = false
					end
				end,
				desc = "LSP: Disable hover capability from Ruff",
			})

			-- TODO: Add this to servers table but exclude from mason install
			require("lspconfig").dartls.setup({})
			require("lspconfig").efm.setup(efmls_config)
		end,
	},
	{
		"mrcjkb/rustaceanvim",
		version = "^5",
		lazy = false,
		config = function()
			vim.g.rustaceanvim = {
				tools = {},
				server = {
					on_attach = function(client, bufnr)
						local function map(mode, l, r, opts)
							opts = opts or {}
							opts.buffer = bufnr
							vim.keymap.set(mode, l, r, opts)
						end
						map("n", "<leader>cc", ":RustLsp flyCheck<CR>", { desc = "check code" })
					end,
					default_settings = {
						["rust-analyzer"] = {
							checkOnSave = {
								enable = false,
							},
						},
					},
				},
			}
			-- local mason_registry = require("mason-registry")
			-- local codelldb = mason_registry.get_package("codelldb")
			-- local extension_path = codelldb:get_install_path() .. "/extension/"
			-- local codelldb_path = extension_path .. "adapter/codelldb"
			-- local liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
			-- local cfg = require("rustaceanvim.config")

			-- vim.g.rustaceanvim = {
			-- 	dap = {
			-- 		adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
			-- 	},
			-- }
		end,
	},
	{
		"luckasRanarison/tailwind-tools.nvim",
		name = "tailwind-tools",
		build = ":UpdateRemotePlugins",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-telescope/telescope.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {},
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
						timeout_ms = 1000,
						lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
					}
				end,
				formatters_by_ft = {
					lua = { "stylua" },
					go = { "goimports" },
					python = {
						"ruff_fix",
						"ruff_format",
						"ruff_organize_imports",
					},
					javascript = { { "prettierd", "prettier" } },
					kotlin = { "ktlint" },
					rust = { "rustfmt" },
					yaml = { "yamlfmt" },
					toml = { "taplo" },
					shell = { "shfmt" },
					sql = { "sqlfluff" },
					terraform = { "terraform_fmt" },
					markdown = { "prettierd", "markdownlint" },
					json = { "jq" },
					c = { "clang-format" },
					html = { "djlint" },
					htmldjango = { "djlint" },
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
	{ "lunarvim/templeos.nvim" },
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

			vim.keymap.set("n", "<leader>gf", function()
				if vim.bo.ft == "minifiles" then
					local path = MiniFiles.get_fs_entry()["path"]
					-- notify the path change
					vim.notify("Path: " .. path)
					vim.fn.setreg('"', path)
					return
				end
				vim.fn.setreg('"', vim.fn.expand("%"))
			end, { noremap = true, silent = true })

			require("mini.extra").setup()
			require("mini.visits").setup()

			local map_vis = function(keys, call, desc)
				local rhs = "<Cmd>lua MiniVisits." .. call .. "<CR>"
				vim.keymap.set("n", "<Leader>" .. keys, rhs, { desc = desc })
			end

			map_vis("vv", 'add_label("core")', "Add to core")
			map_vis("vc", 'select_path(nil, { filter = "core" })', "Select core")
			map_vis("vV", 'remove_label("core")', "Remove from core")
			map_vis("vC", 'remove_label("core", "")', "Remove all paths")

			-- Iterate based on recency
			local map_iterate_core = function(lhs, direction, desc)
				local opts = { filter = "core", sort = sort_latest, wrap = true }
				local rhs = function()
					MiniVisits.iterate_paths(direction, vim.fn.getcwd(), opts)
				end
				vim.keymap.set("n", "<C-" .. lhs .. ">", rhs, { desc = desc })
			end
			map_iterate_core("n", "forward", "Core label (earlier)")
			map_iterate_core("/", "backward", "Core label (later)")

			require("mini.splitjoin").setup()
			require("mini.bracketed").setup()
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
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = "nvim-treesitter/nvim-treesitter-textobjects",
		config = function()
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
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
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
						include_surrounding_whitespace = true,
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
		end,
	},
	{
		"rmagatti/gx-extended.nvim",
		config = function()
			require("gx-extended").setup({
				extensions = {
					-- TODO: incomplete match file path
					-- {
					-- patterns = { "*" },
					-- name = "local files",
					-- match_to_url = function(line_string)
					-- 	local line = string.match(line_string, "(/[^/\0]+)+/?")
					-- 	vim.notify(line)
					-- 	return line or nil
					-- end,
					-- },
				},
			})
		end,
	},
	{ "mzlogin/vim-markdown-toc" },
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
			vim.keymap.set("t", "<leader>of", floating_term, { desc = "Toggle Vertical Terminal" })
			vim.keymap.set("n", "<leader>of", floating_term, { desc = "Toggle Vertical Terminal" })

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
	{
		"farmergreg/vim-lastplace",
		config = function()
			vim.g.lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit"
			vim.g.lastplace_ignore_buftype = "quickfix,nofile,help"
			vim.g.lastplace_open_folds = 1
		end,
	},
	{
		"andrewferrier/debugprint.nvim",
		dependencies = {
			"echasnovski/mini.nvim",
		},
		opts = {},
	},
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = false,
		version = false,
		opts = {
			provider = "openai",
		},
		build = "make",
		dependencies = {
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"hrsh7th/nvim-cmp",
			"nvim-tree/nvim-web-devicons",
			"zbirenbaum/copilot.lua",
			{
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
					},
				},
			},
			{
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
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

vim.cmd("colorscheme tokyonight")

-- vim: ts=2 sts=2 sw=2 et
