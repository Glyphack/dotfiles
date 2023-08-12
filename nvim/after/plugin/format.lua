local ft = require('guard.filetype')

ft('go'):fmt('lsp')
    :append('golines')

ft('rb'):fmt('rubocop')
    :lint('rubocop')


require('guard').setup({

    fmt_on_save = true,

    lsp_as_default_formatter = true,
})
