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

local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  -- Flake8 not blazingly fast
  -- { command = "flake8", filetypes = { "python" }, extra_args = { "--max-complexity", "5", "--ignore", "e203,W503" }, },
  { name = "ruff" },
}

local formatters = require "lvim.lsp.null-ls.formatters"

formatters.setup {
  -- todo https://github.com/younger-1/nvim/blob/one/lua/young/lang/python.lua
  { command = "isort", filetypes = { "python" },
    extra_args = { "--line-length", "79", "--ca", "--profile", "black", "--float-to-top" },
  },
  { command = "black", filetypes = { "python" }, args = { "--line-length", "79" } },
}
