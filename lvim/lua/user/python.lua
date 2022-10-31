local M = {}

M.config = function()
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
end

return M
