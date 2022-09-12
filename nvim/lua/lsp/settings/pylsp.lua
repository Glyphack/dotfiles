return {
  settings = {
    pylsp = {
      plugins = {
        autopep8 = {
            enabled = false
        },
        jedi_completion = {
            enabled = false
        },
        jedi_symbols = {enabled = true, all_scopes = true},
        flake8 = {
          enabled = true,
          ignore = {},
          maxLineLength = 79
        },
        pyflakes = {enabled = false},
        mypy = {enabled = false},
        isort = {enabled = false},
        yapf = {enabled = false},
        pylint = {enabled = false},
        pydocstyle = {enabled = false},
        mccabe = {enabled = false},
        preload = {enabled = false},
        rope_completion = {enabled = false}
      }
    }
  }
}
