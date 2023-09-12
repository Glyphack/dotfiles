-- copied from teej

SHOULD_RELOAD_TELESCOPE = true
local reloader = function()
  if SHOULD_RELOAD_TELESCOPE then
    R "plenary"
    R "telescope"
    R "glyphack.telescope.setup"
  end
end

local action_state = require "telescope.actions.state"
local themes = require "telescope.themes"

local _ = pcall(require, "nvim-nonicons")

local M = {}

function M.find_files()
  require("telescope.builtin").find_files {
    sorting_strategy = "descending",
    scroll_strategy = "cycle",
    layout_config = {
    },
  }
end

function M.git_files()
  local path = vim.fn.expand "%:h"
  if path == "" then
    path = nil
  end

  local width = 0.75
  if path and string.find(path, "sourcegraph.*sourcegraph", 1, false) then
    width = 0.5
  end

  local opts = themes.get_dropdown {
    winblend = 5,
    previewer = false,
    shorten_path = false,

    cwd = path,

    layout_config = {
      width = width,
    },
  }

  require("telescope.builtin").git_files(opts)
end

function M.grep_with_args()
  require('telescope').extensions.live_grep_args.live_grep_args()
end

function M.grep_last_search(opts)
  opts = opts or {}

  -- \<getreg\>\C
  -- -> Subs out the search things
  local register = vim.fn.getreg("/"):gsub("\\<", ""):gsub("\\>", ""):gsub("\\C", "")

  opts.path_display = { "shorten" }
  opts.word_match = "-w"
  opts.search = register

  require("telescope.builtin").grep_string(opts)
end

function M.oldfiles()
  require("telescope").extensions.frecency.frecency(themes.get_ivy {})
end

function M.buffers()
  require("telescope.builtin").buffers {
    shorten_path = false,
  }
end

function M.curbuf()
  local opts = themes.get_dropdown {
    winblend = 10,
    border = true,
    previewer = false,
    shorten_path = false,
  }
  require("telescope.builtin").current_buffer_fuzzy_find(opts)
end

function M.help_tags()
  require("telescope.builtin").help_tags {
    show_version = true,
  }
end

function M.search_all_files()
  require("telescope.builtin").find_files {
    find_command = { "rg", "--no-ignore", "--files" },
  }
end

function M.file_browser()
  local opts

  opts = {
    sorting_strategy = "ascending",
    scroll_strategy = "cycle",
    layout_config = {
      prompt_position = "top",
    },
    select_buffer = true,
    path = "%:p:h",

    attach_mappings = function(prompt_bufnr, map)
      local current_picker = action_state.get_current_picker(prompt_bufnr)

      local modify_cwd = function(new_cwd)
        local finder = current_picker.finder

        finder.path = new_cwd
        finder.files = true
        current_picker:refresh(false, { reset_prompt = true })
      end

      map("i", "-", function()
        modify_cwd(current_picker.cwd .. "/..")
      end)

      map("i", "~", function()
        modify_cwd(vim.fn.expand "~")
      end)

      map("n", "yy", function()
        local entry = action_state.get_selected_entry()
        vim.fn.setreg("+", entry.value)
      end)

      return true
    end,
  }

  require("telescope").extensions.file_browser.file_browser(opts)
end

function M.git_commits()
  require("telescope.builtin").git_commits {
    winblend = 5,
  }
end

function M.search_only_certain_files()
  require("telescope.builtin").find_files {
    find_command = {
      "rg",
      "--files",
      "--type",
      vim.fn.input "Type: ",
    },
  }
end

function M.lsp_references()
  require("telescope.builtin").lsp_references {
    layout_strategy = "vertical",
    layout_config = {
      prompt_position = "top",
    },
    sorting_strategy = "ascending",
    ignore_filename = false,
  }
end

function M.lsp_implementations()
  require("telescope.builtin").lsp_implementations {
    layout_strategy = "vertical",
    layout_config = {
      prompt_position = "top",
    },
    sorting_strategy = "ascending",
    ignore_filename = false,
  }
end

function M.vim_options()
  require("telescope.builtin").vim_options {
    layout_config = {
      width = 0.5,
    },
    sorting_strategy = "ascending",
  }
end

function M.neoclip()
  require('telescope').extensions.neoclip.default()
end

function M.grep_highlighted()
  -- get current text highlighted in visual mode
  local search = vim.fn.getreg "/"
  print(search)
  require('telescope').extensions.live_grep_args.live_grep_args(search)
end

return setmetatable({}, {
  __index = function(_, k)
    reloader()

    local has_custom, custom = pcall(require, string.format("glyphack.telescope.custom.%s", k))

    if M[k] then
      print(M[k])
      return M[k]
    elseif has_custom then
      return custom
    else
      return require("telescope.builtin")[k]
    end
  end,
})
