return {
	cmd = { "clojure-lsp" },
	filetypes = { "clojure" },
	root_markers = { "project.clj", "deps.edn", "build.boot", "shadow-cljs.edn", ".git" },
	capabilities = (function()
		-- local capabilities = vim.lsp.protocol.make_client_capabilities()
		-- capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
		-- capabilities.textDocument.diagnostic = nil
		-- return capabilities
	end)(),
}
