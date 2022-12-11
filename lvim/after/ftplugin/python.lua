-- Setup dap for python
lvim.builtin.dap.active = true
local mason_path = vim.fn.glob(vim.fn.stdpath "data" .. "/mason/")
pcall(function() require("dap-python").setup(mason_path .. "packages/debugpy/venv/bin/python") end)

-- Supported test frameworks are unittest, pytest and django. By default it
-- tries to detect the runner by probing for pytest.ini and manage.py, if
-- neither are present it defaults to unittest.
pcall(function() require("dap-python").test_runner = "pytest" end)


-- Mappings
lvim.builtin.which_key.mappings["dm"] = { "<cmd>lua require('dap-python').test_method()<cr>", "Test Method" }
lvim.builtin.which_key.mappings["df"] = { "<cmd>lua require('dap-python').test_class()<cr>", "Test Class" }
lvim.builtin.which_key.vmappings["d"] = {
  name = "Debug",
  s = { "<cmd>lua require('dap-python').debug_selection()<cr>", "Debug Selection" },
}
lvim.builtin.which_key.mappings["P"] = {
  name = "Python",
  i = { "<cmd>lua require('swenv.api').pick_venv()<cr>", "Pick Env" },
  d = { "<cmd>lua require('swenv.api').get_current_venv()<cr>", "Show Env" },
}

require("lvim.lsp.manager").setup("pyright", {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
      },
    },
  },
})


local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  -- Flake8 not blazingly fast
  -- { command = "flake8", filetypes = { "python" }, extra_args = { "--max-complexity", "5", "--ignore", "e203,W503" }, },
  { name = "ruff" },
}

local formatters = require "lvim.lsp.null-ls.formatters"

local null_ls = require("null-ls")
local methods = require("null-ls.methods")
local helpers = require("null-ls.helpers")

local function ruff_fix()
  return helpers.make_builtin({
    name = "ruff",
    meta = {
      url = "https://github.com/charliermarsh/ruff/",
      description = "An extremely fast Python linter, written in Rust.",
    },
    method = methods.internal.FORMATTING,
    filetypes = { "python" },
    generator_opts = {
      command = "ruff",
      args = { "--fix", "-e", "-n", "--stdin-filename", "$FILENAME", "-" },
      to_stdin = true
    },
    factory = helpers.formatter_factory
  })
end

formatters.setup {
  -- todo https://github.com/younger-1/nvim/blob/one/lua/young/lang/python.lua
  { command = "isort", filetypes = { "python" },
    extra_args = { "--line-length", "79", "--ca", "--profile", "black", "--float-to-top" },
  },
  { command = "black", filetypes = { "python" }, args = { "--line-length", "79" } },
}
