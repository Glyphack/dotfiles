local map_tele = require "glyphack.telescope.mappings"

-- -- Dotfiles
map_tele("<leader>en", "edit_neovim")
map_tele("<space><space>d", "diagnostics")

-- Search
-- TODO: I would like to completely remove _mock from my search results here when I'm in SG/SG
map_tele("<space>gw", "grep_string", {
  word_match = "-w",
  short_path = true,
  only_sort_text = true,
  layout_strategy = "vertical",
})

map_tele("<space>f/", "grep_last_search", {
  layout_strategy = "vertical",
})

-- Files
map_tele("<space>ft", "git_files")
map_tele("<space>fg", "grep_with_args")
map_tele("<space>fo", "oldfiles")
map_tele("<space>fd", "find_files")
map_tele("<space>fs", "fs")
map_tele("<space>fi", "search_all_files")
map_tele("<space>pp", "project_search")
-- map_tele("<space>fv", "find_nvim_source")
map_tele("<space>fe", "file_browser")
map_tele("<space>fz", "search_only_certain_files")

-- Nvim
map_tele("<space>ff", "curbuf")
map_tele("<space>fh", "help_tags")
map_tele("<space>ts", "treesitter")

-- Clip
map_tele("<leader>yh", "neoclip")
