local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { command = "eslint", filetypes = { "javascript", "typescript" } },
}
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { name = "prismafmt" },
}

vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "tsserver" })
require("lvim.lsp.manager").setup("tsserver", {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
  end,
  filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
  cmd = { "typescript-language-server", "--stdio" }
})
