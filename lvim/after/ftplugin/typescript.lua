local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { command = "eslint", filetypes = { "javascript", "typescript" } },
}
local formatters = require "lvim.lsp.null-ls.formatters"

formatters.setup {
  { name = "prettierd", },
  { name = "prismafmt" },
}
