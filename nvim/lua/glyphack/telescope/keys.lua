local map_tele = require("glyphack.telescope.mappings")
local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")

map_tele("<space><space>d", "diagnostics")

-- Files
map_tele("<space>ft", "git_files")
map_tele("<space>fg", "grep_with_args")
map_tele("<space>fr", "oldfiles")
map_tele("<space>fd", "find_files")
map_tele("<space>fi", "search_all_files")
map_tele("<space>fe", "file_browser")
map_tele("<space>fz", "search_only_certain_files")
map_tele("<space>fb", "curbuf")
map_tele("<space>fh", "help_tags")
map_tele("<space>ts", "treesitter")
map_tele("<leader>fp", "neoclip")

vim.keymap.set("v", ";;", live_grep_args_shortcuts.grep_visual_selection)

vim.keymap.set("n", "<leader>acf", ":AdvancedGitSearch diff_commit_file<CR>")
vim.keymap.set("n", "<leader>asc", ":AdvancedGitSearch search_commit<CR>")
