local lsp = require("lsp-zero")
require("neodev").setup({
})

lsp.preset("recommended")

require('fidget').setup()

lsp.ensure_installed({
    'tsserver',
    'lua_ls',
    'rust_analyzer',
    'jsonls',
    'pyright',
    'bufls',
    'ruff_lsp',
    'bashls',
    'dockerls',
    'tailwindcss',
    'yamlls',
    'gopls',
    'golangci_lint_ls',
    'prismals',
    'ruff_lsp',
    -- 'marksman',
})

local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp.defaults.cmp_mappings({
    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
    ['<C-i>'] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
})

-- disable completion with tab
-- this helps with copilot setup
cmp_mappings['<Tab>'] = nil
cmp_mappings['<S-Tab>'] = nil
cmp_mappings['<CR>'] = nil

lsp.setup_nvim_cmp({
    mapping = cmp_mappings,
    sources = {
        { name = "path" },
        { name = "nvim_lsp",               keyword_length = 1 },
        { name = "buffer",                 keyword_length = 3 },
        { name = "luasnip",                keyword_length = 2 },
        { name = 'nvim_lsp_signature_help' },
        {
            name = "rg",
        },
    }
})

lsp.set_preferences({
    suggest_lsp_servers = false,
    sign_icons = {
        error = 'E',
        warn = 'W',
        hint = 'H',
        info = 'I'
    }
})


lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }

    if client.name == 'tsserver' or client.name == 'jsonls' then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentFormattingRangeProvider = false
    end

    vim.keymap.set('n', 'gD', ':Glance definitions<CR>')
    vim.keymap.set('n', 'gr', '<CMD>Glance references<CR>')
    vim.keymap.set('n', 'gy', '<CMD>Glance type_definitions<CR>')
    vim.keymap.set('n', 'gi', '<CMD>Glance implementations<CR>')
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>lws", vim.lsp.buf.workspace_symbol, opts)
    vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "<leader>lca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>lr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>lrn", vim.lsp.buf.rename, opts)
    vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
    vim.diagnostic.config({ virtual_text = true })
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
        description =
        "AWS CloudFormation provides a common language for you to describe and provision all the infrastructure resources in your cloud environment.",
        fileMatch = {
            "*.cf.json",
            "cloudformation.json",
        },
        url = "https://raw.githubusercontent.com/awslabs/goformation/v5.2.9/schema/cloudformation.schema.json",
    },
    {
        description =
        "The AWS Serverless Application Model (AWS SAM, previously known as Project Flourish) extends AWS CloudFormation to provide a simplified way of defining the Amazon API Gateway APIs, AWS Lambda functions, and Amazon DynamoDB tables needed by your serverless application.",
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
    {
        description = "Resume json",
        fileMatch = { "resume.json" },
        url = "https://raw.githubusercontent.com/jsonresume/resume-schema/v1.0.0/schema.json",
    },
}

local function extend(tab1, tab2)
    for _, value in ipairs(tab2 or {}) do
        table.insert(tab1, value)
    end
    return tab1
end

local extended_schemas = extend(schemas, default_schemas)

lsp.configure("jsonls", {
    settings = {
        json = {
            schemas = extended_schemas,
        },
    },
})

lsp.configure("lua_ls", {
    settings = {
        Lua = {
            diagnostics = {
                globals = { 'vim' },
            },
            completion = {
                callSnippet = "Replace"
            }
        },
        format = {
            enable = true,
            defaultConfig = {
                indent_style = "space",
                indent_size = "2",
            }
        },
    }
})

lsp.configure("ruff_lsp", {
})

lsp.configure("yamlls", {
  settings = {
    yaml = {
      keyOrdering = false
    }
  }
})

lsp.setup()

require("glyphack.null-ls")
