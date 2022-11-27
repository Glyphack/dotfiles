local function metals_status()
  local status = vim.g["metals_status"]
  if status == nil then
    return ""
  else
    return status
  end
end

local metals_config = require("metals").bare_config()
metals_config.on_attach = require("lvim.lsp").common_on_attach
metals_config.settings = {
  showImplicitArguments = true,
  showInferredType = true,
  excludedPackages = {},
}
metals_config.init_options.statusBarProvider = true
require("metals").initialize_or_attach { metals_config }

local components = require("lvim.core.lualine.components")
lvim.builtin.lualine.sections.lualine_c = {
  -- NOTE: There is no way to append a component, so we need to include the components
  -- here that are already supplied by lunarvim in `lualine_c`
  components.diff,
  components.python_env,
  metals_status,
}
lvim.builtin.which_key.mappings["L"] = {
  name = "Metals",
  u = { "<Cmd>MetalsUpdate<CR>", "Update Metals" },
  i = { "<Cmd>MetalsInfo<CR>", "Metals Info" },
  r = { "<Cmd>MetalsRestartBuild<CR>", "Restart Build Server" },
  d = { "<Cmd>MetalsRunDoctor<CR>", "Metals Doctor" },
}
