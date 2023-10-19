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

local history_db_file = os.getenv("VIMDATA") .. "/telescope_history.sqlite3"

-- local file = io.open(history_db_file, "w")
-- if not file then
--   -- create file
--   os.execute("touch " .. history_db_file)
--   local file, file_err = io.open(history_db_file, "w")
--   if not file then
--     print("Error opening file:", file_err)
--   end
-- end


require("telescope").setup {
  defaults = {
    prompt_prefix = "> ",
    selection_caret = "> ",
    entry_prefix = "  ",
    multi_icon = "<>",

    path_display = {"truncate"},

    winblend = 0,

    layout_strategy = "horizontal",
    layout_config = {
      width = 0.99,
      height = 0.85,
      preview_cutoff = 120,
      prompt_position = "bottom",

      horizontal = {
        preview_width = function(_, cols, _)
          if cols > 200 then
            return math.floor(cols * 0.4)
          else
            return math.floor(cols * 0.4)
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

    selection_strategy = "closest",
    sorting_strategy = "descending",
    scroll_strategy = "cycle",
    color_devicons = true,

    mappings = {
      i = {
        ["<RightMouse>"] = actions.close,
        ["<LeftMouse>"] = actions.select_default,
        ["<ScrollWheelDown>"] = actions.move_selection_next,
        ["<ScrollWheelUp>"] = actions.move_selection_previous,

        ["<C-s>"] = actions.select_horizontal,
        ["<C-g>"] = "move_selection_next",
        ["<C-t>"] = "move_selection_previous",

        ["<C-e>"] = actions.results_scrolling_down,
        ["<C-y>"] = actions.results_scrolling_up,

        -- These are new :)
        ["<M-p>"] = action_layout.toggle_preview,
        ["<M-m>"] = action_layout.toggle_mirror,

        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

        -- This is nicer when used with smart-history plugin.
        ["<C-k>"] = actions.cycle_history_next,
        ["<C-j>"] = actions.cycle_history_prev,
        ["<c-g>s"] = actions.select_all,
        ["<c-g>a"] = actions.add_selection,
        ["<C-w>"] = function()
          vim.api.nvim_input "<c-s-w>"
        end,
      },
    },

    file_ignore_patterns = {
      "node_modules",
      "vendor",
      ".git/",
      "*.lock",
      "package-lock.json",
    },

    grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
    qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,

    history = {
      path = history_db_file,
      limit = 100,
    },
  },

  pickers = {
    buffers = {
      sort_lastused = true,
      sort_mru = true,
    },
  },

  extensions = {
    --  using mini fuzzy instead
    -- fzf = {
    --   fuzzy = true,
    --   override_generic_sorter = true,
    --   override_file_sorter = true,
    --   case_mode = "smart_case",
    -- },
    fzf_writer = {
      use_highlighter = false,
      minimum_grep_characters = 6,
    },
    advanced_git_search = {
      diff_plugin = "fugitive",
      show_builtin_git_pickers = false,
      entry_default_author_or_date = "date",
      telescope_theme = {
        show_custom_functions = {
          layout_config = { width = 0.4, height = 0.4 },
        },
      }
    },
    ast_grep = {
      command = {
        "sg",
        "--json=stream",
      },                       -- must have --json=stream
      grep_open_files = false, -- search in opened files
      lang = nil,              -- string value, specify language for ast-grep `nil` for default
    },
  },
}

require("telescope").load_extension("fzf")
require("telescope").load_extension("neoclip")
require("telescope").load_extension("advanced_git_search")
require("telescope").load_extension("live_grep_args")
require("telescope").load_extension("smart_history")
require("telescope").load_extension("ast_grep")
