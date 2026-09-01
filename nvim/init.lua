vim.loader.enable()
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options

vim.o.relativenumber = true
vim.o.number = true
vim.o.ruler = false

vim.o.winborder = "single"
vim.o.pumheight = 10
vim.o.pummaxwidth = 100
vim.o.pumborder = "single"

-- Mouse mode for resizing windows
vim.o.mouse = "a"
-- Don't show the mode, since it's already in status line
vim.o.showmode = false

-- When indented lines are break in wrapping it shows them as indented
vim.o.breakindent = true
vim.o.showbreak = ">>"
vim.o.linebreak = true
vim.o.breakindentopt = "list:-1"

vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.tabstop = 2

-- Save undo history
vim.o.undofile = true
vim.o.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.o.updatecount = 500
vim.o.swapfile = false

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true

vim.o.signcolumn = "auto"
vim.o.termguicolors = true

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.splitkeep = "screen"

-- Jump to a window that already holds the buffer instead of splitting again
vim.o.switchbuf = "usetab"

-- Sets how neovim will display certain whitespace in the editor.
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 999

-- spell checker
vim.o.spell = true
-- handle camel case
vim.o.spelloptions = "camel"

vim.o.clipboard = "unnamedplus"

-- Fold some stuff by default.
vim.o.foldlevelstart = 99

-- Diagnostics
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

-- Keymaps

---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param desc string
---@param opts table|nil extra options forwarded to `vim.keymap.set`
local function map(mode, lhs, rhs, desc, opts)
	assert(type(desc) == "string" and desc ~= "", "keymap " .. lhs .. " is missing a description")
	vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { desc = desc }, opts or {}))
end

map("n", ";", ":", "https://x.com/Neovim/status/2089768728724484148")
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")

-- Diagnostics
map("n", "<leader>e", vim.diagnostic.open_float, "Show diagnostic [E]rror messages")
map("n", "<leader>q", vim.diagnostic.setloclist, "Open diagnostic [Q]uickfix list")

-- Quickfix list navigation
map("n", "<M-j>", ":cn<CR>", "Move focus to the next quickfix item")
map("n", "<M-k>", ":cp<CR>", "Move focus to the previous quickfix item")

-- Terminal. The window motions replay <Esc>, which is itself mapped, so they
-- need remap enabled to leave terminal mode first.
map("t", "<Esc>", "<C-\\><C-n>", "Exit terminal mode")
map("t", "<c-w><c-h>", "<ESC><c-w><c-h>", "Move to the window on the left", { remap = true })
map("t", "<c-w><c-j>", "<ESC><c-w><c-j>", "Move to the window below", { remap = true })
map("t", "<c-w><c-k>", "<ESC><c-w><c-k>", "Move to the window above", { remap = true })
map("t", "<c-w><c-l>", "<ESC><c-w><c-l>", "Move to the window on the right", { remap = true })

-- Keys hit by accident more often than they are used on purpose
map("v", "<CR>", "<nop>", "Disabled")
map("n", "<BS>", "<nop>", "Disabled")
map("v", "<BS>", "<nop>", "Disabled")

-- Autocommands

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("formatoptions", { clear = true }),
	callback = function()
		vim.cmd("setlocal formatoptions-=c formatoptions-=o")
	end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("my-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Treesitter folds for languages that ship a folds.scm query
local fold_langs = {}
for name, kind in vim.fs.dir(vim.fn.stdpath("config") .. "/queries") do
	if kind == "directory" and vim.uv.fs_stat(vim.fn.stdpath("config") .. "/queries/" .. name .. "/folds.scm") then
		fold_langs[name] = true
	end
end
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter-folds", { clear = true }),
	callback = function(args)
		local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype) or vim.bo[args.buf].filetype
		if fold_langs[lang] then
			vim.opt_local.foldmethod = "expr"
			vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
			vim.opt_local.foldenable = true
		end
	end,
})

-- Large files: skip syntax, treesitter and diff to keep them responsive
local large_file_config = {
	max_filesize = 1024 * 1024,
	max_lines = 30000,
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
			vim.b[bufnr].minidiff_disable = true
			vim.opt_local.syntax = "off"
			vim.opt_local.foldmethod = "manual"
			vim.opt_local.spell = false
			vim.schedule(function()
				vim.treesitter.stop(bufnr)
			end)
			vim.notify("Large file detected: disabled treesitter and diff", vim.log.levels.WARN)
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
			vim.b[bufnr].minidiff_disable = true
			vim.schedule(function()
				vim.treesitter.stop(bufnr)
			end)
			vim.notify(
				"Large file detected (" .. line_count .. " lines): disabled treesitter and diff",
				vim.log.levels.WARN
			)
		end
	end,
})

-- Git buffers
local git_buffers = vim.api.nvim_create_augroup("git-buffer-perf", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = git_buffers,
	pattern = { "fugitive", "fugitiveblame", "git", "gitcommit", "gitrebase", "diff" },
	callback = function()
		vim.opt_local.spell = false
		vim.opt_local.scrolloff = 0
		vim.opt_local.cursorline = false
	end,
})

vim.api.nvim_create_autocmd("DiffUpdated", {
	group = git_buffers,
	callback = function()
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			if vim.wo[win].diff then
				vim.wo[win].spell = false
				vim.wo[win].scrolloff = 0
			end
		end
	end,
})

-- LSP
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("my-lsp-attach", { clear = true }),
	callback = function(event)
		local function lsp_map(keys, func, desc)
			map("n", keys, func, "LSP: " .. desc, { buffer = event.buf })
		end
		lsp_map("gs", ":vsplit | lua vim.lsp.buf.definition()<CR>", "Goto definition in split")
		lsp_map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
		lsp_map("gr", vim.lsp.buf.references, "Goto References")
		lsp_map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
		lsp_map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
		lsp_map("<leader>ps", vim.lsp.buf.signature_help, "Peek signature")
		lsp_map("K", vim.lsp.buf.hover, "Hover Documentation")
		lsp_map("gt", vim.lsp.buf.type_definition, "Goto type definition")
		lsp_map("<leader>ws", function()
			MiniExtra.pickers.lsp({ scope = "workspace_symbol_live" })
		end, "[W]orkspace [S]ymbols")
		lsp_map("gi", function()
			MiniExtra.pickers.lsp({ scope = "implementation" })
		end, "[G]oto [I]mplementation")

		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client == nil then
			return
		end
		if client:supports_method("textDocument/codeLens") then
			vim.lsp.codelens.enable(true, { bufnr = event.buf })
		end
	end,
})

-- User commands

vim.api.nvim_create_user_command("LspLog", function()
	vim.cmd("edit " .. vim.lsp.get_log_path())
end, { desc = "Open LSP log file" })

vim.api.nvim_create_user_command("Lsp", function()
	vim.cmd("checkhealth vim.lsp")
end, { desc = "Show LSP health check" })

local wrap_mode = false
vim.api.nvim_create_user_command("ToggleWrap", function()
	wrap_mode = not wrap_mode

	if wrap_mode then
		map("n", "j", "gj", "Move down by display line", { silent = true })
		map("n", "k", "gk", "Move up by display line", { silent = true })
		map("v", "j", "gj", "Move down by display line", { silent = true })
		map("v", "k", "gk", "Move up by display line", { silent = true })
		print("Wrap mode enabled")
	else
		map("n", "j", "j", "Move down by line", { silent = true })
		map("n", "k", "k", "Move up by line", { silent = true })
		map("v", "k", "k", "Move up by line", { silent = true })
		map("v", "j", "j", "Move down by line", { silent = true })
		print("Wrap mode disabled")
	end
end, { desc = "Toggle j/k movement for wrapped lines" })

vim.api.nvim_create_user_command("RestartNvim", function()
	vim.cmd("wall")
	local session = vim.fn.stdpath("state") .. "/restart_session.vim"
	vim.cmd("mksession! " .. vim.fn.fnameescape(session))
	vim.cmd("restart source " .. vim.fn.fnameescape(session))
end, {
	desc = "Save session, restart Neovim, and restore session",
})

-- Plugins

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
	-- LANGUAGE SUPPORT: lsp, formatting, completion, treesitter
	{
		-- Every server config lives in after/lsp/<name>.lua. Names without a file
		-- there are provided by nvim-lspconfig.
		"neovim/nvim-lspconfig",
		dependencies = { "hrsh7th/cmp-nvim-lsp" },
		config = function()
			vim.lsp.config("*", {
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
			})

			vim.lsp.enable({
				"bashls",
				"clangd",
				-- "clojure_lsp",
				-- "dockerls",
				"gopls",
				"html",
				"jsonls",
				"lua_ls",
				"ruff",
				"sourcekit",
				-- "tailwindcss",
				-- "terraformls",
				"typescript",
				"yamlls",
				"harper_ls",
			})

			vim.lsp.enable("ty")
		end,
	},
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				-- mini.nvim assigns its globals inside each setup(), so they only
				-- resolve once its sources are in the workspace library
				{ path = "mini.nvim", words = { "Mini%w+" } },
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
						map("n", "<leader>cc", ":RustLsp flyCheck<CR>", "check code")
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
								enable = not vim.fn.fnamemodify(vim.fn.getcwd(), ":t"):find("ruff"),
							},
							runnables = {
								extraTestBinaryArgs = { "--nocapture" },
							},
						},
					},
				},
				dap = {},
			}
		end,
	},
	{
		"nvim-flutter/flutter-tools.nvim",
		ft = { "dart" },
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("flutter-tools").setup({ widget_guides = { enabled = true } })
		end,
	},
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
			require("nvim-paredit").setup()
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
					python = { "ruff_format", "ruff_fix", "ruff_organize_imports" },
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
					html = { "prettierd" },
					htmldjango = { "prettierd" },
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
					{
						name = "nvim_lsp",
						keyword_length = 1,
						option = {
							markdown_oxide = {
								keyword_pattern = [[\(\k\| \|\/\|#\)\+]],
							},
						},
					},
					{ name = "luasnip", keyword_length = 2 },
					{ name = "path" },
					{ name = "buffer", keyword_length = 3 },
					{ name = "nvim_lsp_signature_help" },
					{ name = "nvim_lua" },
					{ name = "git" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "rg", keyword_length = 3 },
				},
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufReadPost", "BufNewFile" },
		build = ":TSUpdate",
		branch = "main",
		config = function()
			require("nvim-treesitter")
				.install({
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
				:wait(300000)
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("nvim-treesitter-textobjects").setup({
				select = { lookahead = true },
			})
			local select = require("nvim-treesitter-textobjects.select")
			local shared = require("nvim-treesitter-textobjects.shared")
			map({ "x", "o" }, "ac", function()
				select.select_textobject("@comment.outer", "textobjects")
			end, "a comment")
			map({ "x", "o" }, "ic", function()
				local has_inner =
					shared.textobject_at_point("@comment.inner", "textobjects", nil, nil, { lookahead = true })
				select.select_textobject(has_inner and "@comment.inner" or "@comment.outer", "textobjects")
			end, "inner comment")
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

	-- SEARCH, FILES AND GIT
	{
		"dmtrKovalenko/fff",
		lazy = false,
		build = function()
			require("fff.download").download_or_build_binary()
		end,
	},
	{
		"echasnovski/mini.nvim",
		lazy = false,
		config = function()
			require("mini.icons").setup()
			MiniIcons.mock_nvim_web_devicons()
			require("mini.notify").setup()
			vim.notify = MiniNotify.make_notify()
			vim.api.nvim_create_user_command("NotifyHistory", function()
				MiniNotify.show_history()
			end, { desc = "Open past notifications in a scratch buffer" })
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("lisp-quote-pairs", { clear = true }),
				pattern = { "clojure", "fennel", "scheme", "lisp" },
				callback = function(args)
					require("mini.pairs").setup()
					map("i", "'", "'", "Literal quote, no auto pair", { buffer = args.buf })
					map("i", "`", "`", "Literal backtick, no auto pair", { buffer = args.buf })
				end,
			})
			require("mini.trailspace").setup()
			vim.api.nvim_create_user_command("Trim", function()
				MiniTrailspace.trim()
				MiniTrailspace.trim_last_lines()
			end, { desc = "Trim trailing whitespace and empty lines" })
			require("mini.hipatterns").setup({
				highlighters = {
					fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
					bug = { pattern = "%f[%w]()BUG()%f[%W]", group = "MiniHipatternsFixme" },
					hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
					warn = { pattern = "%f[%w]()WARN()%f[%W]", group = "MiniHipatternsHack" },
					todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
					note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
				},
			})
			require("mini.diff").setup({
				view = {
					style = "sign",
					signs = { add = "+", change = "~", delete = "_" },
				},
			})
			local goto_hunk = function(direction, diff_key)
				return function()
					if vim.wo.diff then
						vim.cmd("normal! " .. diff_key)
						return
					end
					MiniDiff.goto_hunk(direction)
				end
			end
			map("n", "]c", goto_hunk("next", "]c"), "jump to next hunk")
			map("n", "[c", goto_hunk("prev", "[c"), "jump to previous hunk")
			map("n", "<leader>hr", function()
				local line = vim.fn.line(".")
				MiniDiff.do_hunks(0, "reset", { line_start = line, line_end = line })
			end, "reset hunk")
			map("n", "<leader>hp", function()
				MiniDiff.toggle_overlay(0)
			end, "toggle diff overlay")
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.jump").setup({
				mappings = {
					forward = "f",
					backward = "F",
					forward_till = "t",
					backward_till = "T",
					repeat_jump = "<CR>",
				},
			})
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
						local git = MiniStatusline.section_diff({ trunc_width = 75 })
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
					local bufname = vim.api.nvim_buf_get_name(0)
					local target = vim.loop.cwd()
					if bufname ~= "" and vim.loop.fs_stat(bufname) then
						target = bufname
					end
					pcall(MiniFiles.open, target)
					MiniFiles.reveal_cwd()
				end
			end
			local minifiles_open_buffer_or_cwd = function()
				if MiniFiles.close() then
					return
				end
				local bufname = vim.api.nvim_buf_get_name(0)
				local target = vim.loop.cwd()
				if bufname ~= "" and vim.loop.fs_stat(bufname) then
					target = bufname
				end
				pcall(MiniFiles.open, target)
				MiniFiles.reveal_cwd()
			end
			map("n", "<leader>t", minifiles_toggle, "Tree", { silent = true })
			map("n", "<leader>p", minifiles_open_buffer_or_cwd, "Tree (buffer or cwd)", { silent = true })
			map("n", "<leader>cp", function()
				if vim.bo.ft == "minifiles" then
					local path = vim.fn.fnamemodify(MiniFiles.get_fs_entry()["path"], ":.")
					vim.fn.setreg("+", path)
					return
				end
				vim.fn.setreg("+", vim.fn.expand("%:."))
			end, "Copy relative filepath to clipboard", { silent = true })
			map("n", "<leader>cP", function()
				if vim.bo.ft == "minifiles" then
					local path = MiniFiles.get_fs_entry()["path"]
					vim.fn.setreg("+", path)
					return
				end
				vim.fn.setreg("+", vim.fn.expand("%:p"))
			end, "Copy full filepath to clipboard", { silent = true })
			map("n", "<leader>of", function()
				vim.fn.system("open .")
			end, "Open current directory in Finder", { silent = true })
			local function fish_quote(s)
				return "'" .. s:gsub("'", "'\\''") .. "'"
			end
			local function minifiles_focused_dir()
				if MiniFiles.get_explorer_state then
					local state = MiniFiles.get_explorer_state()
					if state and state.branch and state.depth_focus then
						return state.branch[state.depth_focus]
					end
				end
				local entry = MiniFiles.get_fs_entry()
				if entry then
					return vim.fn.fnamemodify(entry.path, ":h")
				end
				return nil
			end
			local function minifiles_copy_file()
				local entry = MiniFiles.get_fs_entry()
				if not entry then
					vim.notify("mini.files: no entry under cursor", vim.log.levels.WARN)
					return
				end
				local parent = vim.fn.fnamemodify(entry.path, ":h")
				local name = vim.fn.fnamemodify(entry.path, ":t")
				local code = "cd " .. fish_quote(parent) .. "; and ,cp " .. fish_quote(name)
				local out = vim.fn.system({ "fish", "-c", code })
				if vim.v.shell_error ~= 0 then
					vim.notify("mini.files: copy failed\n" .. out, vim.log.levels.ERROR)
					return
				end
				vim.notify("Copied " .. name .. " to clipboard")
			end
			local function minifiles_paste_file()
				local dir = minifiles_focused_dir()
				if not dir then
					vim.notify("mini.files: no target directory", vim.log.levels.WARN)
					return
				end
				local code = "cd " .. fish_quote(dir) .. "; and ,pf"
				local out = vim.fn.system({ "fish", "-c", code })
				if vim.v.shell_error ~= 0 then
					vim.notify("mini.files: paste failed\n" .. out, vim.log.levels.ERROR)
					return
				end
				MiniFiles.synchronize()
				vim.notify("Pasted into " .. vim.fn.fnamemodify(dir, ":t"))
			end
			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniFilesBufferCreate",
				callback = function(args)
					local buf = args.data.buf_id
					map("n", "gy", minifiles_copy_file, "Copy file to clipboard", { buffer = buf })
					map("n", "gp", minifiles_paste_file, "Paste file from clipboard", { buffer = buf })
				end,
			})
			require("mini.extra").setup()
			require("mini.splitjoin").setup()
			require("mini.bracketed").setup()
			require("mini.pick").setup({
				mappings = { choose_marked = "<C-q>" },
			})
			vim.ui.select = MiniPick.ui_select

			-- fff pickers: fff owns matching and ranking, mini.pick owns the window,
			-- preview and marking. Every prompt change re-queries fff instead of
			-- filtering a static list, so results stay live. <C-e> cycles the
			-- search mode. Choosing a directory item opens mini.files there.
			local function fff_pick(spec, prefill)
				local ok, conf = pcall(require, "fff.conf")
				local config = ok and conf.get() or nil
				local base = config and config.base_path
				if not base or base == "" then
					base = vim.fn.getcwd()
				end
				local root = (vim.fn.fnamemodify(vim.fn.expand(base), ":p"):gsub("(.)/$", "%1"))

				local last
				local run = function(prompt)
					last = prompt
					MiniPick.set_picker_items(spec.search(root, prompt, spec.mode), { do_match = false })
				end
				local title = function()
					return string.format("%s (%s)", spec.name, spec.mode)
				end
				local cycle_mode = function()
					local at = vim.fn.index(spec.modes, spec.mode)
					spec.mode = spec.modes[((at + 1) % #spec.modes) + 1]
					MiniPick.set_picker_opts({ source = { name = title() } })
					run(table.concat(MiniPick.get_picker_query()))
				end
				if prefill and prefill ~= "" then
					vim.api.nvim_create_autocmd("User", {
						pattern = "MiniPickStart",
						once = true,
						callback = function()
							MiniPick.set_picker_query(vim.split(prefill, ""))
						end,
					})
				end
				MiniPick.start({
					source = {
						name = title(),
						cwd = root,
						items = {},
						match = function(_, _, query)
							local prompt = table.concat(query)
							if prompt == last then
								return
							end
							run(prompt)
						end,
						choose = spec.choose,
					},
					mappings = { cycle_mode = { char = "<C-e>", func = cycle_mode } },
				})
			end

			local fff_files = {
				name = "FFF files",
				mode = "mixed",
				modes = { "mixed", "files", "directories" },
				search = function(root, prompt, mode)
					local result = require("fff").file_search(prompt, { mode = mode, max_results = 200 })
					local items = {}
					for i, entry in ipairs(result.items) do
						items[i] = {
							text = entry.relative_path,
							path = vim.fs.joinpath(root, entry.relative_path),
							is_dir = entry.type == "directory",
						}
					end
					return items
				end,
				choose = function(item)
					if not item.is_dir then
						return MiniPick.default_choose(item)
					end
					vim.schedule(function()
						MiniFiles.open(item.path, false)
					end)
				end,
			}

			local fff_grep = {
				name = "FFF grep",
				mode = "plain",
				modes = { "plain", "regex", "fuzzy" },
				search = function(root, prompt, mode)
					if prompt == "" then
						return {}
					end
					local result = require("fff").content_search(prompt, { mode = mode, page_size = 200 })
					local items = {}
					for i, match in ipairs(result.items) do
						local col = (match.col or 0) + 1
						items[i] = {
							text = string.format(
								"%s:%d:%d: %s",
								match.relative_path,
								match.line_number,
								col,
								match.line_content or ""
							),
							path = vim.fs.joinpath(root, match.relative_path),
							lnum = match.line_number,
							col = col,
						}
					end
					return items
				end,
			}

			MiniPick.registry.fff_files = function()
				fff_pick(fff_files)
			end
			MiniPick.registry.fff_grep = function()
				fff_pick(fff_grep)
			end

			map("n", "<leader>sf", function()
				fff_pick(fff_files)
			end, "[S]earch [F]iles")
			-- I do search replace using this:
			-- 1: search the term with grep
			-- 2: <C-x> and <C-a> to select files. Then <C-q> to send to quick fix.
			-- 3: cfdo %s ...
			map("n", "<leader>sg", function()
				fff_pick(fff_grep)
			end, "[S]earch by [G]rep")
			map("n", "<leader>sw", function()
				fff_pick(fff_grep, vim.fn.expand("<cword>"))
			end, "[S]earch current [W]ord")
			map("v", "<leader>sw", function()
				local region = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
				fff_pick(fff_grep, table.concat(region, " "))
			end, "Search highlighted word")

			map("n", "<leader>sF", function()
				MiniPick.builtin.cli(
					{ command = { "fd", "--type", "f", "--hidden", "--no-ignore-vcs" } },
					{ source = { name = "All files (incl. gitignored)" } }
				)
			end, "[S]earch All [F]iles (incl. gitignored)")
			map("n", "<leader>sh", MiniPick.builtin.help, "[S]earch [H]elp")
			map("n", "<leader>sk", function()
				MiniExtra.pickers.keymaps()
			end, "[S]earch [K]eymaps")
			map("n", "<leader>ss", function()
				MiniExtra.pickers.git_files({ scope = "modified" })
			end, "[E]dited [F]iles")
			map("n", "<leader>s/", function()
				MiniExtra.pickers.buf_lines({ scope = "all" })
			end, "[S]earch [/] in Open Files")
			map("n", "<leader>sd", function()
				MiniExtra.pickers.diagnostic()
			end, "[S]earch [D]iagnostics")
			map("n", "<leader>ds", function()
				MiniExtra.pickers.lsp({ scope = "document_symbol" })
			end, "Goto Symbol")
			map("n", "<leader>sr", MiniPick.builtin.resume, "[S]earch [R]esume")
			map("n", "<leader>s.", function()
				MiniExtra.pickers.oldfiles()
			end, '[S]earch Recent Files ("." for repeat)')
			map("n", "<leader><leader>", MiniPick.builtin.buffers, "[ ] Find existing buffers")
			map("n", "<leader>/", function()
				MiniExtra.pickers.buf_lines({ scope = "current" })
			end, "[/] Fuzzily search in current buffer")
			map("n", "<leader>sc", function()
				MiniExtra.pickers.commands()
			end, "[S]earch [C]ommands")
			map("n", "Q", function()
				MiniExtra.pickers.history({ scope = ":" })
			end, "Command history")

			local fileprs = require("fileprs")
			map("n", "<leader>sP", fileprs.pick, "[S]earch file [P]Rs")
			vim.api.nvim_create_user_command("FilePRs", fileprs.pick, { desc = "Show PRs that touched this file" })

			vim.api.nvim_create_user_command("SpawnTerminal", function()
				local dirs = vim.fn.systemlist({ "fd", "--type", "d" })
				table.insert(dirs, 1, ".")
				MiniPick.start({
					source = {
						name = "Spawn terminal in folder",
						items = dirs,
						choose = function(item)
							local dir = vim.fn.fnamemodify(item or ".", ":p")
							vim.system({ "wezterm", "cli", "split-pane", "--right", "--cwd", dir }, {}, function(out)
								if out.code ~= 0 then
									vim.schedule(function()
										vim.notify("wezterm split failed: " .. out.stderr, vim.log.levels.ERROR)
									end)
								end
							end)
						end,
					},
				})
			end, { desc = "Open a wezterm split in a picked folder" })
		end,
	},
	{
		"tpope/vim-fugitive",
		dependencies = { "tpope/vim-rhubarb" },
		cmd = { "Git", "G", "Gvdiffsplit", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse" },
		keys = {
			{ "<leader>hs", desc = "Toggle Git" },
			{ "<leader>hb", "<cmd>Git blame<cr>", desc = "Blame current file" },
			{ "<leader>gb", mode = { "n", "v" }, desc = "Copy file URL in git remote" },
		},
		config = function()
			local fugitive_toggle = function()
				if vim.bo.ft == "fugitive" then
					vim.cmd("bd")
				else
					vim.cmd("tab :G")
				end
			end
			map("n", "<leader>hs", fugitive_toggle, "Toggle Git")
			map("n", "<leader>gb", ":.GBrowse!<CR>", "Copy line URL in git remote", { silent = true })
			map("v", "<leader>gb", ":GBrowse!<CR>", "Copy selection URL in git remote", { silent = true })
			map("n", "<leader>hd", function()
				local base =
					vim.fn.system("git branch -r | grep -q origin/main && echo main || echo master"):gsub("%s+", "")
				local diff = vim.fn.systemlist("git diff --unified=0 " .. base .. "...HEAD")
				local qf = {}
				local file = nil
				for _, line in ipairs(diff) do
					local f = line:match("^%+%+%+ b/(.*)")
					if f then
						file = f
					end
					local lnum = line:match("^@@ .* %+(%d+)")
					if file and lnum then
						table.insert(qf, { filename = file, lnum = tonumber(lnum), text = line })
					end
				end
				vim.fn.setqflist(qf)
				vim.cmd("copen")
			end, "Branch changes vs base")
			vim.opt.diffopt:append("algorithm:histogram")
		end,
	},

	-- THEMES
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
		config = function() end,
	},
	{
		"zenbones-theme/zenbones.nvim",
		dependencies = "rktjmp/lush.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.darken_cursor_line = 1
		end,
	},
	{ "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },
	{ "lunarvim/templeos.nvim", lazy = false, priority = 1000 },
	{ "kepano/flexoki-neovim", name = "flexoki", lazy = false, priority = 1000 },
	{ "shaunsingh/solarized.nvim", lazy = false, priority = 1000 },
	{ "morhetz/gruvbox", lazy = false, priority = 1000 },

	-- NICE TO HAVE
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
	{ "rmagatti/gx-extended.nvim", event = "VeryLazy" },
	{ "mzlogin/vim-markdown-toc", ft = { "markdown" } },
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
		"TobinPalmer/rayso.nvim",
		cmd = { "Rayso" },
		config = function()
			require("rayso").setup({})
		end,
	},
	{
		"obsidian-nvim/obsidian.nvim",
		version = "*",
		config = function()
			require("obsidian").setup({
				legacy_commands = false,
				workspaces = {
					{
						name = "personal",
						path = "$vault",
					},
				},
				picker = {
					name = "mini.pick",
				},
				frontmatter = { enabled = false },
				-- ui = { enable = false },
			})
			-- for beautiful visuals, or:
			vim.o.conceallevel = 1
		end,
	},
})

-- My keymaps and commands

require("agent").setup()
require("bookmarks").setup()
require("splitline").setup()

map("n", "<leader>fc", 'gg"+yG``', "Copy entire file to clipboard")
map("v", "<leader>k", ":Link<CR>", "Convert selection to markdown link", { silent = true })

map("n", "<leader>sv", function()
	dofile(vim.env.MYVIMRC)
	vim.notify("Config reloaded")
end, "Reload nvim config")

map("v", "<leader>r", function()
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
end, "Substitute the selected text", { silent = true })

map("n", "<leader>cl", function()
	local file = vim.fn.expand("%:.")
	local line = vim.fn.line(".")
	vim.fn.setreg("+", file .. ":" .. line)
end, "Copy file and line number to clipboard")

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

	vim.fn.setreg("z", new_text)
	vim.cmd('normal! gv"zP')
	vim.api.nvim_win_set_cursor(0, { start_pos[2], cursor_col })
end, { range = true, desc = "Convert selection to markdown link" })

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-server-tweaks", { clear = true }),
	callback = function(event)
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client == nil then
			return
		end
		if client.name == "ruff" then
			client.server_capabilities.hoverProvider = false
		end
		if client.name == "ty" then
			vim.api.nvim_create_user_command("TyDebug", function()
				client:request("workspace/executeCommand", {
					command = "ty.printDebugInformation",
				}, function(err, result)
					vim.schedule(function()
						local buf = vim.api.nvim_create_buf(false, true)
						vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result, "\n"))
						vim.cmd("split")
						vim.api.nvim_win_set_buf(0, buf)
					end)
				end)
			end, {})

			vim.api.nvim_create_user_command("TyDiscoverTests", function()
				local params = {
					textDocument = vim.lsp.util.make_text_document_params(),
				}

				local response = client.request_sync("ty/discoverTests", params, 2000, 0)
				if not response then
					vim.notify("Request timed out", vim.log.levels.ERROR)
					return
				end

				if response.err then
					vim.notify("Error: " .. response.err.message, vim.log.levels.ERROR)
					return
				end

				print("Got sync result: " .. vim.inspect(response.result))
			end, {})
		end
	end,
})

-- Startup

vim.cmd.colorscheme("flexoki")

-- This catches the delayed terminal response (or live OS changes)
-- and re-triggers the colorscheme to adapt.
vim.api.nvim_create_autocmd("OptionSet", {
	pattern = "background",
	callback = function()
		vim.cmd.colorscheme("flexoki")
	end,
})
