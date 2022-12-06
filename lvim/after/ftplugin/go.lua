-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--   { command = "golangci_lint", filetypes = { "go" } },
-- }
local formatters = require "lvim.lsp.null-ls.formatters"

formatters.setup {
  { command = "goimports", filetypes = { "go", "gomod" } },
  { command = "gofumpt", filetypes = { "go" } },
}

vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "gopls" })

local lsp_manager = require "lvim.lsp.manager"
lsp_manager.setup("golangci_lint_ls", {
  on_init = require("lvim.lsp").common_on_init,
  capabilities = require("lvim.lsp").common_capabilities(),
})
lsp_manager.setup("gopls", {
  on_attach = function(client, bufnr)
    require("lvim.lsp").common_on_attach(client, bufnr)
    local _, _ = pcall(vim.lsp.codelens.refresh)
    local map = function(mode, lhs, rhs, desc)
      if desc then
        desc = desc
      end

      vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc, buffer = bufnr, noremap = true })
    end
    -- map("<leader>Ci", "<cmd>GoInstallDeps<Cr>", "Install Go Dependencies")
    map("<leader>Ct", "<cmd>GoMod tidy<cr>", "Tidy")
    map("<leader>Ca", "<cmd>GoTestAdd<Cr>", "Add Test")
    map("<leader>CA", "<cmd>GoTestsAll<Cr>", "Add All Tests")
    map("<leader>Ce", "<cmd>GoTestsExp<Cr>", "Add Exported Tests")
    map("<leader>Cg", "<cmd>GoGenerate<Cr>", "Go Generate")
    map("<leader>Cf", "<cmd>GoGenerate %<Cr>", "Go Generate File")
    map("<leader>Cc", "<cmd>GoCmt<Cr>", "Generate Comment")
    map("<leader>DT", "<cmd>lua require('dap-go').debug_test()<cr>", "Debug Test")
  end,
  on_init = require("lvim.lsp").common_on_init,
  capabilities = require("lvim.lsp").common_capabilities(),
  settings = {
    gopls = {
      usePlaceholders = true,
      gofumpt = true,
      codelenses = {
        generate = false,
        gc_details = true,
        test = true,
        tidy = true,
      },
    },
  },
})
