vim.loader.enable()

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

-- Save undo history
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.updatecount = 500

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = "auto"

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

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

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

vim.keymap.set("n", "<leader>sv", function()
	dofile(vim.env.MYVIMRC)
	vim.notify("Config reloaded")
end, { desc = "Reload nvim config" })

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
end, { desc = "Copy file and line number to clipboard" })

vim.opt.clipboard = "unnamedplus"
vim.keymap.set("n", "<leader>fc", 'gg"+yG``', { desc = "Copy entire file to clipboard" })
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

local large_file_config = {
	max_filesize = 1024 * 1024,
	max_lines = 10000,
}

vim.api.nvim_create_autocmd("BufReadPre", {
	group = vim.api.nvim_create_augroup("large-file-guard", { clear = true }),
	callback = function(args)
		local bufnr = args.buf
		local filename = args.file
		local stat = vim.uv.fs_stat(filename)
		if not stat then
			return
		end

		local is_large = stat.size > large_file_config.max_filesize
		if is_large then
			vim.b[bufnr].large_file = true
			vim.opt_local.syntax = "off"
			vim.opt_local.foldmethod = "manual"
			vim.opt_local.spell = false
			vim.schedule(function()
				vim.treesitter.stop(bufnr)
				local ok, gitsigns = pcall(require, "gitsigns")
				if ok then
					gitsigns.detach(bufnr)
				end
			end)
			vim.notify("Large file detected: disabled treesitter and gitsigns", vim.log.levels.WARN)
		end
	end,
})

-- Also check line count after file is read
vim.api.nvim_create_autocmd("BufReadPost", {
	group = vim.api.nvim_create_augroup("large-file-guard-lines", { clear = true }),
	callback = function(args)
		local bufnr = args.buf
		if vim.b[bufnr].large_file then
			return
		end

		local line_count = vim.api.nvim_buf_line_count(bufnr)
		if line_count > large_file_config.max_lines then
			vim.b[bufnr].large_file = true
			vim.opt_local.syntax = "off"
			vim.opt_local.foldmethod = "manual"
			vim.opt_local.spell = false
			vim.schedule(function()
				vim.treesitter.stop(bufnr)
				local ok, gitsigns = pcall(require, "gitsigns")
				if ok then
					gitsigns.detach(bufnr)
				end
			end)
			vim.notify(
				"Large file detected (" .. line_count .. " lines): disabled treesitter and gitsigns",
				vim.log.levels.WARN
			)
		end
	end,
})

-- vim.api.nvim_create_user_command("GJ", toggle_wrap_mode, {})

vim.api.nvim_create_user_command("Link", function(opts)
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local selected_text = vim.fn.getline(start_pos[2]):sub(start_pos[3], end_pos[3])

	local new_text, cursor_col
	if selected_text:match("^http") then
		new_text = "[](" .. selected_text .. ")"
		cursor_col = start_pos[3]
	else
		new_text = "[" .. selected_text .. "]()"
		cursor_col = start_pos[3] + #selected_text + 2
	end

	vim.fn.setreg('z', new_text)
	vim.cmd('normal! gv"zP')
	vim.api.nvim_win_set_cursor(0, { start_pos[2], cursor_col })
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

-- vim: ts=2 sts=2 sw=2 et

vim.lsp.enable("lua_ls")
vim.lsp.enable("clangd")
vim.lsp.enable("gopls")
vim.lsp.enable("pyright")
vim.lsp.enable("ruff")
vim.lsp.enable("ts_ls")
vim.lsp.enable("yamlls")
vim.lsp.enable("jsonls")
vim.lsp.enable("terraformls")
vim.lsp.enable("bashls")
vim.lsp.enable("dockerls")
vim.lsp.enable("tailwindcss")
vim.lsp.enable("html")
vim.lsp.enable("marksman")
vim.lsp.enable("emmet_ls")
vim.lsp.enable("ruby_lsp")
vim.lsp.enable("sorbet")
vim.lsp.enable("kotlin_language_server")
vim.lsp.enable("vale_ls")
vim.lsp.enable("lemminx")
vim.lsp.enable("clojure_lsp")
vim.lsp.enable("efm")
vim.lsp.enable("dartls")
vim.lsp.enable("sourcekit")

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end
		map("gs", ":vsplit | lua vim.lsp.buf.definition()<CR>", "Goto definition in split")
		map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
		map("gr", vim.lsp.buf.references, "Goto References")
		map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
		map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
		map("<leader>ps", vim.lsp.buf.signature_help, "Peek signature")
		map("K", vim.lsp.buf.hover, "Hover Documentation")

		-- 	local telescope = require("telescope.builtin")
		-- 	map("gi", telescope.lsp_implementations, "[G]oto [I]mplementation")
		-- 	map("gt", telescope.lsp_type_definitions, "Goto type definition")
		-- 	map("<leader>ds", telescope.lsp_document_symbols, "[D]ocument [S]ymbols")
		-- 	map("<leader>ws", telescope.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client == nil then
			return
		end
		if client.name == "ruff" then
			client.server_capabilities.hoverProvider = false
		end
	end,
})

local wrap_mode = false
vim.api.nvim_create_user_command("GJ", function()
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
end, {})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			"nvim-tree/nvim-web-devicons",
			"nvim-telescope/telescope-live-grep-args.nvim",

			"nvim-telescope/telescope-fzy-native.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
			"jonarrien/telescope-cmdline.nvim",
			{
				"isak102/telescope-git-file-history.nvim",
				dependencies = { "tpope/vim-fugitive" },
			},
			{
				"AckslD/nvim-neoclip.lua",
				lazy = true,
			},
		},

		config = function()
			require("bookmarks").setup()

			local actions = require("telescope.actions")
			local action_layout = require("telescope.actions.layout")
			local action_state = require("telescope.actions.state")
			local builtin = require("telescope.builtin")
			local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")
			local lga_actions = require("telescope-live-grep-args.actions")

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
						},
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
			require("telescope").load_extension("fzy_native")
			require("telescope").load_extension("ui-select")
			require("telescope").load_extension("git_file_history")
			require("telescope").load_extension("neoclip")
			require("telescope").load_extension("cmdline")

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
					attach_mappings = function(prompt_bufnr, mapper)
						local switch_to_file = function()
							local selection = action_state.get_selected_entry()
							actions.close(prompt_bufnr)
							vim.cmd(":e " .. selection.value)
						end
						mapper("i", "<CR>", switch_to_file)
						mapper("n", "<CR>", switch_to_file)
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

			vim.keymap.set("n", "Q", "<cmd>Telescope cmdline<cr>", { desc = "Cmdline" })
		end,
	},

	-- VISUALS

	{
		"Bekaboo/dropbar.nvim",
		event = "LspAttach",
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

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			require("which-key").setup()
		end,
	},

	-- FUNC
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
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "saadparwaiz1/cmp_luasnip" },
			{ "hrsh7th/cmp-nvim-lsp-signature-help" },
			{ "petertriho/cmp-git", dependencies = "nvim-lua/plenary.nvim", opts = {} },
			"lukas-reineke/cmp-rg",
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
					{
						name = "lazydev",
						group_index = 0,
					},
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

	{
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
					clojure = { "zprint" },
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
		"numToStr/Comment.nvim",
		keys = { { "gc", mode = { "n", "v" } }, { "gb", mode = { "n", "v" } } },
		opts = {
			toggler = {
				block = nil,
			},
		},
	},
	{
		"tpope/vim-fugitive",
		cmd = { "Git", "G", "Gvdiffsplit", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse" },
		keys = {
			{ "<leader>hs", desc = "Toggle Git" },
		},
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
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
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
				vim.keymap.set("n", "]c", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "jump to next hunk" })
				vim.keymap.set("n", "[c", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "jump to previous hunk" })
				-- Actions
				vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { desc = "reset hunk" })
				vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { desc = "preview hunk" })
				vim.keymap.set("n", "<leader>hb", function()
					gs.blame_line({ full = true })
				end, { desc = "toggle blame" })
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

	{ "creativenull/efmls-configs-nvim", event = "LspAttach" },
	{
		"nvim-flutter/flutter-tools.nvim",
		ft = { "dart" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim",
		},
		config = function()
			require("flutter-tools").setup({ widget_guides = { enabled = true } })
		end,
	},
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"mrcjkb/rustaceanvim",
		version = "^6",
		ft = { "rust" },
		config = function()
			vim.g.rustaceanvim = {
				tools = {},
				server = {
					on_attach = function(client, bufnr)
						vim.keymap.set("n", "<leader>cc", ":RustLsp flyCheck<CR>", { desc = "check code" })
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
		config = function()
			vim.o.background = "dark"
			vim.cmd("colorscheme tokyonight-night")
		end,
	},
	{ "rebelot/kanagawa.nvim", lazy = true },
	{ "lunarvim/templeos.nvim", lazy = true },
	{ "shaunsingh/solarized.nvim", lazy = true },
	{ "sainnhe/gruvbox-material", lazy = true },
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufReadPost", "BufNewFile" },
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").install({
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
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("treesitter-context").setup({
				enable = true,
				max_lines = 3,
				min_window_height = 15,
				line_numbers = true,
				multiline_threshold = 1,
				trim_scope = "inner",
				mode = "cursor",
				separator = nil,
				zindex = 20,
				on_attach = nil,
			})
		end,
	},
	{ "rmagatti/gx-extended.nvim", event = "VeryLazy" },
	{ "mzlogin/vim-markdown-toc", ft = { "markdown" } },

	{
		"Olical/conjure",
		ft = { "clojure", "fennel", "scheme" },
		config = function()
			vim.g.maplocalleader = ","
		end,
	},
	{
		"julienvincent/nvim-paredit",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		ft = { "clojure", "fennel", "scheme" },
		config = function()
			local paredit = require("nvim-paredit")
			require("nvim-paredit").setup({
				use_default_keys = false,
				keys = {
					["<localleader>@"] = { paredit.unwrap.unwrap_form_under_cursor, "Splice sexp" },
					[">)"] = { paredit.api.slurp_forwards, "Slurp forwards" },
					[">("] = { paredit.api.barf_backwards, "Barf backwards" },

					["<)"] = { paredit.api.barf_forwards, "Barf forwards" },
					["<("] = { paredit.api.slurp_backwards, "Slurp backwards" },

					[">e"] = { paredit.api.drag_element_forwards, "Drag element right" },
					["<e"] = { paredit.api.drag_element_backwards, "Drag element left" },

					[">p"] = { paredit.api.drag_pair_forwards, "Drag element pairs right" },
					["<p"] = { paredit.api.drag_pair_backwards, "Drag element pairs left" },

					[">f"] = { paredit.api.drag_form_forwards, "Drag form right" },
					["<f"] = { paredit.api.drag_form_backwards, "Drag form left" },

					["<localleader>o"] = { paredit.api.raise_form, "Raise form" },
					["<localleader>O"] = { paredit.api.raise_element, "Raise element" },

					["E"] = {
						paredit.api.move_to_next_element_tail,
						"Jump to next element tail",
						-- by default all keybindings are dot repeatable
						repeatable = false,
						mode = { "n", "x", "o", "v" },
					},
					["W"] = {
						paredit.api.move_to_next_element_head,
						"Jump to next element head",
						repeatable = false,
						mode = { "n", "x", "o", "v" },
					},

					["B"] = {
						paredit.api.move_to_prev_element_head,
						"Jump to previous element head",
						repeatable = false,
						mode = { "n", "x", "o", "v" },
					},
					["gE"] = {
						paredit.api.move_to_prev_element_tail,
						"Jump to previous element tail",
						repeatable = false,
						mode = { "n", "x", "o", "v" },
					},

					["("] = {
						paredit.api.move_to_parent_form_start,
						"Jump to parent form's head",
						repeatable = false,
						mode = { "n", "x", "v" },
					},
					[")"] = {
						paredit.api.move_to_parent_form_end,
						"Jump to parent form's tail",
						repeatable = false,
						mode = { "n", "x", "v" },
					},

					["T"] = {
						paredit.api.move_to_top_level_form_head,
						"Jump to top level form's head",
						repeatable = false,
						mode = { "n", "x", "v" },
					},

					-- These are text object selection keybindings which can used with standard `d, y, c`, `v`
					["af"] = {
						paredit.api.select_around_form,
						"Around form",
						repeatable = false,
						mode = { "o", "v" },
					},
					["if"] = {
						paredit.api.select_in_form,
						"In form",
						repeatable = false,
						mode = { "o", "v" },
					},
					["aF"] = {
						paredit.api.select_around_top_level_form,
						"Around top level form",
						repeatable = false,
						mode = { "o", "v" },
					},
					["iF"] = {
						paredit.api.select_in_top_level_form,
						"In top level form",
						repeatable = false,
						mode = { "o", "v" },
					},
					["ae"] = {
						paredit.api.select_element,
						"Around element",
						repeatable = false,
						mode = { "o", "v" },
					},
					["ie"] = {
						paredit.api.select_element,
						"Element",
						repeatable = false,
						mode = { "o", "v" },
					},
				},
				indent = {
					enabled = true,
					indentor = require("nvim-paredit.indentation.native").indentor,
				},
			})

			vim.api.nvim_create_user_command("ClojureStartRepl", function()
				local project_root = vim.fn.getcwd()
				local nrepl_cmd = "clj -M:nrepl -m nrepl.cmdline"

				-- Start nREPL in new terminal buffer
				vim.cmd("new | terminal " .. nrepl_cmd)
				local term_win = vim.api.nvim_get_current_win()

				-- Switch back to previous window
				vim.cmd("wincmd p")

				-- Ensure we're in a Clojure buffer for ConjureConnect
				local current_buf = vim.api.nvim_get_current_buf()
				local current_ft = vim.bo[current_buf].filetype
				if current_ft ~= "clojure" then
					vim.cmd("e src/clj/main.clj") -- Adjust path as needed
					vim.notify("📝 Opened Clojure buffer for REPL connection", vim.log.levels.INFO)
				end

				vim.defer_fn(function()
					local port_file = project_root .. "/.nrepl-port"
					if vim.fn.filereadable(port_file) == 1 then
						local port = vim.fn.readfile(port_file)[1]:gsub("%s+", "")
						vim.cmd("ConjureConnect " .. port)
						vim.notify("✅ Connected to nREPL on port " .. port, vim.log.levels.INFO)
					else
						vim.notify(".nrepl-port not found, waiting...", vim.log.levels.WARN)
						vim.defer_fn(function()
							if vim.fn.filereadable(port_file) == 1 then
								local port = vim.fn.readfile(port_file)[1]:gsub("%s+", "")
								vim.cmd("ConjureConnect " .. port)
								vim.notify("✅ Connected to nREPL on port " .. port, vim.log.levels.INFO)
							else
								vim.notify(
									".nrepl-port still not found. Connect manually with :ConjureConnect <port>",
									vim.log.levels.ERROR
								)
							end
						end, 2000)
					end
				end, 1500)
			end, {
				desc = "Start nREPL server and connect Conjure automatically",
			})

			vim.keymap.set(
				"n",
				"<localleader>rs",
				"<cmd>ClojureStartRepl<CR>",
				{ desc = "Start Clojure REPL + Connect", silent = true }
			)
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},
	{
		"echasnovski/mini.nvim",
		event = "VeryLazy",
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

			vim.keymap.set("n", "<leader>of", function()
				vim.fn.system("open .")
			end, { noremap = true, silent = true, desc = "Open current directory in Finder" })

			require("mini.extra").setup()
			require("mini.splitjoin").setup()
			require("mini.bracketed").setup()
		end,
	},
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
		event = "VeryLazy",
		config = function()
			vim.notify = require("notify")
		end,
	},

	{
		"andrewferrier/debugprint.nvim",
		keys = {
			{ "g?p", desc = "Debug print below" },
			{ "g?P", desc = "Debug print above" },
			{ "g?v", mode = { "n", "v" }, desc = "Debug print variable below" },
			{ "g?V", mode = { "n", "v" }, desc = "Debug print variable above" },
		},
		cmd = { "DeleteDebugPrints" },
		dependencies = {
			"echasnovski/mini.nvim",
		},
		opts = {},
	},
	{
		"TobinPalmer/rayso.nvim",
		cmd = { "Rayso" },
		config = function()
			require("rayso").setup({})
		end,
	},
})
