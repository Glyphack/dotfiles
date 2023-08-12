local options = {
  cmdheight = 2,                           -- more space in the neovim command line for displaying messages
  completeopt = { "menuone", "noselect" }, -- mostly just for cmp
  conceallevel = 0,                        -- so that `` is visible in markdown files
  fileencoding = "utf-8",                  -- the encoding written to a file
  pumheight = 10,                          -- pop up menu height
  incsearch = true,

  tabstop = 4,
  softtabstop = 4,
  shiftwidth = 4,
  expandtab = true,
  smartindent = true, -- make indenting smarter again
  autoindent = true,

  splitbelow = true,         -- force all horizontal splits to go below current window
  splitright = true,         -- force all vertical splits to go to the right of current window
  swapfile = false,          -- creates a swapfile
  backup = false,            -- creates a backup file
  termguicolors = true,      -- set term gui colors (most terminals support this)
  undofile = true,           -- enable persistent undo
  undodir = os.getenv("HOME") .. "/.vim/undodir",
  updatetime = 50,           -- faster completion (4000ms default)

  autowriteall = true,       -- autosave before commands like :next and :make

  number = true,             -- set numbered lines
  relativenumber = true,     -- set relative numbered lines
  numberwidth = 4,           -- set number column width to 2 {default 4}
  signcolumn = "yes",        -- always show the sign column, otherwise it would shift the text each time
  wrap = false,              -- display lines as one long line
  scrolloff = 8,             -- is one of my fav
  sidescrolloff = 8,
  guifont = "monospace:h17", -- the font used in graphical neovim applications
  winbar = "1",
}

vim.opt.shortmess:append "c"

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.wo.number = true
