require 'options'
require 'keymaps'
require 'theme'
require 'lsp'
require 'terminal'
require 'tree'
require 'completion'
require 'discord'
require 'telescopec'
require 'syntax'
require 'git'
require 'tabline'
require 'harpooner'

-- global
vim.opt_global.completeopt = { "menuone", "noinsert", "noselect" }
-- vim.opt_global.shortmess:remove("F"):append("c")


require("symbols-outline").setup()
