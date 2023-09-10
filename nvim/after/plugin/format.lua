local ft = require('guard.filetype')

ft('go'):fmt('lsp')
    :append('golines')

ft('rb'):fmt('rubocop')
    :lint('rubocop')

ft('kt'):fmt({
    fn = function()

    end
})

require('guard').setup({

    fmt_on_save = false,

    lsp_as_default_formatter = true,
})
