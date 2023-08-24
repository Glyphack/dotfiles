if not pcall(require, "telescope") then
  return
end

local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local action_layout = require "telescope.actions.layout"

require 'telescope-all-recent'.setup {}

local set_prompt_to_entry_value = function(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  if not entry or not type(entry) == "table" then
    return
  end

  action_state.get_current_picker(prompt_bufnr):reset_prompt(entry.ordinal)
end

require("telescope").setup {
  defaults = {
    prompt_prefix = "> ",
    selection_caret = "> ",
    entry_prefix = "  ",
    multi_icon = "<>",

    -- path_display = "truncate",

    winblend = 0,

    layout_strategy = "horizontal",
    layout_config = {
      width = 0.95,
      height = 0.85,
      -- preview_cutoff = 120,
      prompt_position = "top",

      horizontal = {
        preview_width = function(_, cols, _)
          if cols > 200 then
            return math.floor(cols * 0.4)
          else
            return math.floor(cols * 0.6)
          end
        end,
      },

      vertical = {
        width = 0.9,
        height = 0.95,
        preview_height = 0.5,
      },

      flex = {
        horizontal = {
          preview_width = 0.9,
        },
      },
    },

    selection_strategy = "reset",
    sorting_strategy = "descending",
    scroll_strategy = "cycle",
    color_devicons = true,

    mappings = {
      i = {
        ["<RightMouse>"] = actions.close,
        ["<LeftMouse>"] = actions.select_default,
        ["<ScrollWheelDown>"] = actions.move_selection_next,
        ["<ScrollWheelUp>"] = actions.move_selection_previous,

        ["<C-x>"] = false,
        ["<C-s>"] = actions.select_horizontal,
        ["<C-n>"] = "move_selection_next",

        ["<C-e>"] = actions.results_scrolling_down,
        ["<C-y>"] = actions.results_scrolling_up,
        -- ["<C-y>"] = set_prompt_to_entry_value,

        -- These are new :)
        ["<M-p>"] = action_layout.toggle_preview,
        ["<M-m>"] = action_layout.toggle_mirror,
        -- ["<M-p>"] = action_layout.toggle_prompt_position,

        -- ["<M-m>"] = actions.master_stack,

        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        -- ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

        -- This is nicer when used with smart-history plugin.
        ["<C-k>"] = actions.cycle_history_next,
        ["<C-j>"] = actions.cycle_history_prev,
        ["<c-g>s"] = actions.select_all,
        ["<c-g>a"] = actions.add_selection,

        -- ["<c-space>"] = function(prompt_bufnr)
        --   local opts = {
        --     callback = actions.toggle_selection,
        --     loop_callback = actions.send_selected_to_qflist,
        --   }
        --   require("telescope").extensions.hop._hop_loop(prompt_bufnr, opts)
        -- end,

        ["<C-w>"] = function()
          vim.api.nvim_input "<c-s-w>"
        end,
      },

      n = {
        ["<C-e>"] = actions.results_scrolling_down,
        ["<C-y>"] = actions.results_scrolling_up,
      },
    },

    file_ignore_patterns = nil,

    file_previewer = require("telescope.previewers").vim_buffer_cat.new,
    grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
    qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,

    history = {
      path = "~/.local/share/nvim/databases/telescope_history.sqlite3",
      limit = 100,
    },
  },

  pickers = {
    find_files = {
      -- I don't like having the cwd prefix in my files
      find_command = vim.fn.executable "fdfind" == 1 and { "fdfind", "--strip-cwd-prefix", "--type", "f" } or nil,

      mappings = {
        n = {
          ["kj"] = "close",
        },
      },
    },

    git_branches = {
      mappings = {
        i = {
          ["<C-a>"] = false,
        },
      },
    },

    buffers = {
      sort_lastused = true,
      sort_mru = true,
    },
  },

  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },

    fzf_writer = {
      use_highlighter = false,
      minimum_grep_characters = 6,
    },
    advanced_git_search = {
      diff_plugin = "fugitive",
      git_flags = {},
      git_diff_flags = {},
      show_builtin_git_pickers = false,
      entry_default_author_or_date = "author", -- one of "author" or "date"
      telescope_theme = {
        show_custom_functions = {
          layout_config = { width = 0.4, height = 0.4 },
        },
      }
    },
  },
}

_ = require("telescope").load_extension "file_browser"
_ = require("telescope").load_extension "fzf"
_ = require("telescope").load_extension "git_worktree"
_ = require("telescope").load_extension "neoclip"

require("telescope").load_extension("advanced_git_search")
require("telescope").load_extension("live_grep_args")
require("telescope").load_extension("smart_history")
require 'telescope-all-recent'.setup {}
