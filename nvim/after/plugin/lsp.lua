local lsp_zero = require("lsp-zero")
local nvim_navic = require("nvim-navic")

-- Enable if slow
-- nvim_navic.setup {
--     lazy_update_context = true,
-- }
require("neodev").setup({})

require("mason").setup({})

require("fidget").setup()

local cmp = require("cmp")
local cmp_format = lsp_zero.cmp_format()
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp_zero.defaults.cmp_mappings({
	["<C-k>"] = cmp.mapping.select_prev_item(cmp_select),
	["<C-j>"] = cmp.mapping.select_next_item(cmp_select),
	["<C-i>"] = cmp.mapping.confirm({
		behavior = cmp.ConfirmBehavior.Replace,
		select = true,
	}),
	["<C-e>"] = cmp.mapping.close(),
	["<C-d>"] = cmp.mapping.scroll_docs(-4),
	["<C-f>"] = cmp.mapping.scroll_docs(4),
})

-- disable completion with tab
-- this helps with copilot setup
cmp_mappings["<Tab>"] = nil
cmp_mappings["<S-Tab>"] = nil
cmp_mappings["<CR>"] = nil

cmp.setup({
	formatting = cmp_format,
	mapping = cmp_mappings,
	sources = {
		{ name = "path" },
		{ name = "nvim_lsp", keyword_length = 1 },
		{ name = "buffer", keyword_length = 3 },
		{ name = "luasnip", keyword_length = 2 },
		{ name = "fish" },
		{ name = "nvim_lua" },
		{ name = "nvim_lsp_signature_help" },
		{ name = "rg" },
	},
	-- Copied from TJ
	sorting = {
		comparators = {
			cmp.config.compare.offset,
			cmp.config.compare.exact,
			cmp.config.compare.score,

			function(entry1, entry2)
				local _, entry1_under = entry1.completion_item.label:find("^_+")
				local _, entry2_under = entry2.completion_item.label:find("^_+")
				entry1_under = entry1_under or 0
				entry2_under = entry2_under or 0
				if entry1_under > entry2_under then
					return false
				elseif entry1_under < entry2_under then
					return true
				end
			end,

			cmp.config.compare.kind,
			cmp.config.compare.sort_text,
			cmp.config.compare.length,
			cmp.config.compare.order,
		},
	},
})

lsp_zero.set_preferences({
	suggest_lsp_servers = false,
	sign_icons = {
		error = "E",
		warn = "W",
		hint = "H",
		info = "I",
	},
})

lsp_zero.on_attach(function(client, bufnr)
	local opts = { buffer = bufnr, remap = false }

	if client.server_capabilities.documentSymbolProvider then
		nvim_navic.attach(client, bufnr)
	end
	if client.name == "tsserver" then
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentFormattingRangeProvider = false
	end

	vim.keymap.set("n", "grn", vim.lsp.buf.rename, opts)
	vim.keymap.set("n", "gws", vim.lsp.buf.workspace_symbol, opts)
	vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
	vim.diagnostic.config({ virtual_text = true })

	vim.keymap.set("n", "[[,", "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts)
	vim.keymap.set("n", "]],", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts)
	vim.keymap.set("n", "gl", "<Cmd>Lspsaga show_line_diagnostics<CR>", opts)
	vim.keymap.set("n", "gb", "<cmd>Lspsaga show_buf_diagnostics<CR>")
	vim.keymap.set("n", "gf", "<cmd>Lspsaga finder<CR>", opts)
	-- vim.keymap.set('n', 'gd', '<Cmd>Lspsaga goto_definition<CR>', opts)
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	vim.keymap.set("n", "gD", "<cmd>Lspsaga peek_definition<CR>", opts)
	vim.keymap.set("n", "gt", "<cmd>Lspsaga goto_type_definition<CR>", opts)
	vim.keymap.set("n", "gT", "<cmd>Lspsaga peek_type_definition<CR>", opts)
	vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", opts)
	vim.keymap.set("n", "grn", "<cmd>Lspsaga rename<CR>", opts)
	vim.keymap.set("n", "grnp", "<cmd>Lspsaga rename ++project<CR>", opts)
	vim.keymap.set("i", "<C-k>", "<cmd>Lspsaga signature_help<CR>", opts)
	vim.keymap.set({ "n", "v" }, "gca", "<cmd>Lspsaga code_action<CR>")
end)

local default_schemas = nil
local status_ok, jsonls_settings = pcall(require, "nlspsettings.jsonls")
if status_ok then
	default_schemas = jsonls_settings.get_default_schemas()
end

local schemas = {
	{
		description = "TypeScript compiler configuration file",
		fileMatch = {
			"tsconfig.json",
			"tsconfig.*.json",
		},
		url = "https://json.schemastore.org/tsconfig.json",
	},
	{
		description = "Lerna config",
		fileMatch = { "lerna.json" },
		url = "https://json.schemastore.org/lerna.json",
	},
	{
		description = "Babel configuration",
		fileMatch = {
			".babelrc.json",
			".babelrc",
			"babel.config.json",
		},
		url = "https://json.schemastore.org/babelrc.json",
	},
	{
		description = "ESLint config",
		fileMatch = {
			".eslintrc.json",
			".eslintrc",
		},
		url = "https://json.schemastore.org/eslintrc.json",
	},
	{
		description = "Bucklescript config",
		fileMatch = { "bsconfig.json" },
		url = "https://raw.githubusercontent.com/rescript-lang/rescript-compiler/8.2.0/docs/docson/build-schema.json",
	},
	{
		description = "Prettier config",
		fileMatch = {
			".prettierrc",
			".prettierrc.json",
			"prettier.config.json",
		},
		url = "https://json.schemastore.org/prettierrc",
	},
	{
		description = "Vercel Now config",
		fileMatch = { "now.json" },
		url = "https://json.schemastore.org/now",
	},
	{
		description = "Stylelint config",
		fileMatch = {
			".stylelintrc",
			".stylelintrc.json",
			"stylelint.config.json",
		},
		url = "https://json.schemastore.org/stylelintrc",
	},
	{
		description = "A JSON schema for the ASP.NET LaunchSettings.json files",
		fileMatch = { "launchsettings.json" },
		url = "https://json.schemastore.org/launchsettings.json",
	},
	{
		description = "Schema for CMake Presets",
		fileMatch = {
			"CMakePresets.json",
			"CMakeUserPresets.json",
		},
		url = "https://raw.githubusercontent.com/Kitware/CMake/master/Help/manual/presets/schema.json",
	},
	{
		description = "Configuration file as an alternative for configuring your repository in the settings page.",
		fileMatch = {
			".codeclimate.json",
		},
		url = "https://json.schemastore.org/codeclimate.json",
	},
	{
		description = "LLVM compilation database",
		fileMatch = {
			"compile_commands.json",
		},
		url = "https://json.schemastore.org/compile-commands.json",
	},
	{
		description = "Config file for Command Task Runner",
		fileMatch = {
			"commands.json",
		},
		url = "https://json.schemastore.org/commands.json",
	},
	{
		description = "AWS CloudFormation provides a common language for you to describe and provision all the infrastructure resources in your cloud environment.",
		fileMatch = {
			"*.cf.json",
			"cloudformation.json",
		},
		url = "https://raw.githubusercontent.com/awslabs/goformation/v5.2.9/schema/cloudformation.schema.json",
	},
	{
		description = "The AWS Serverless Application Model (AWS SAM, previously known as Project Flourish) extends AWS CloudFormation to provide a simplified way of defining the Amazon API Gateway APIs, AWS Lambda functions, and Amazon DynamoDB tables needed by your serverless application.",
		fileMatch = {
			"serverless.template",
			"*.sam.json",
			"sam.json",
		},
		url = "https://raw.githubusercontent.com/awslabs/goformation/v5.2.9/schema/sam.schema.json",
	},
	{
		description = "Json schema for properties json file for a GitHub Workflow template",
		fileMatch = {
			".github/workflow-templates/**.properties.json",
		},
		url = "https://json.schemastore.org/github-workflow-template-properties.json",
	},
	{
		description = "golangci-lint configuration file",
		fileMatch = {
			".golangci.toml",
			".golangci.json",
		},
		url = "https://json.schemastore.org/golangci-lint.json",
	},
	{
		description = "JSON schema for the JSON Feed format",
		fileMatch = {
			"feed.json",
		},
		url = "https://json.schemastore.org/feed.json",
		versions = {
			["1"] = "https://json.schemastore.org/feed-1.json",
			["1.1"] = "https://json.schemastore.org/feed.json",
		},
	},
	{
		description = "Packer template JSON configuration",
		fileMatch = {
			"packer.json",
		},
		url = "https://json.schemastore.org/packer.json",
	},
	{
		description = "NPM configuration file",
		fileMatch = {
			"package.json",
		},
		url = "https://json.schemastore.org/package.json",
	},
	{
		description = "JSON schema for Visual Studio component configuration files",
		fileMatch = {
			"*.vsconfig",
		},
		url = "https://json.schemastore.org/vsconfig.json",
	},
}

local function extend(tab1, tab2)
	for _, value in ipairs(tab2 or {}) do
		table.insert(tab1, value)
	end
	return tab1
end

local extended_schemas = extend(schemas, default_schemas)

require("mason-lspconfig").setup({
	ensure_installed = {
		"tsserver",
		"lua_ls",
		"rust_analyzer",
		"jsonls",
		"pyright",
		"bufls",
		"ruff_lsp",
		"bashls",
		"dockerls",
		"tailwindcss",
		"emmet_ls",
		"eslint",
		"graphql",
		"yamlls",
		"gopls",
		"golangci_lint_ls",
		"prismals",
		"ruff_lsp",
		"ruby_ls",
		"sorbet",
		"kotlin_language_server",
		"terraformls",
		"jdtls",
		"ltex",
		"marksman",
		"typos_lsp",
	},
	handlers = {
		lsp_zero.default_setup,
		jsonls = function()
			require("lspconfig").jsonls.setup({
				settings = {
					json = {
						schemas = extended_schemas,
					},
				},
			})
		end,
		tsserver = function()
			require("lspconfig").tsserver.setup({
				filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
				cmd = { "typescript-language-server", "--stdio" },
			})
		end,
		pyright = function()
			require("lspconfig").pyright.setup({
				settings = {
					python = {
						-- not working for some reason
						analysis = {
							exclude = {
								"**/testdata/**",
							},
							ignore = {
								"**/testdata/**",
							},
						},
					},
				},
			})
		end,
		yamlls = function()
			require("lspconfig").yamlls.setup({
				settings = {
					yaml = {
						keyOrdering = false,
					},
				},
			})
		end,
		ruff_lsp = function()
			require("lspconfig").ruff_lsp.setup({})
		end,
		lua_ls = function()
			require("lspconfig").lua_ls.setup({
				settings = {
					Lua = {
						diagnostics = {
							-- Get the language server to recognize the `vim` global
							globals = { "vim", "hs" },
						},

						workspace = {
							-- Make the server aware of Neovim runtime files
							library = vim.api.nvim_get_runtime_file("", true),
							checkThirdParty = false,
						},
					},
				},
			})
		end,
		-- flow = function()
		--     require("lspconfig").flow.setup({})
		-- end,
	},
})

require("glyphack.null-ls")
