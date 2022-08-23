local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

require'lspconfig'.jsonls.setup {
  capabilities = capabilities,
}
-- requires npm i -g vscode-langservers-extracted
require'lspconfig'.jsonls.setup{}
