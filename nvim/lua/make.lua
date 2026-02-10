local M = {}

local DEFAULT_CONFIG = {
  output_buffer_name = "Make Output",
  split_command = "vsplit",
  auto_scroll = true,
  shell_fallback = "sh",
  bun_command = "bun",
  extension_runners = {
    sh = "sh",
    bash = "bash",
    zsh = "zsh",
    fish = "fish",
    py = "python3",
    rb = "ruby",
    lua = "lua",
  },
}

local function merge_config(config)
  return vim.tbl_deep_extend("force", {}, DEFAULT_CONFIG, config or {})
end

local function find_output_buffer(name)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name == name then
        return buf
      end
    end
  end
  return nil
end

local function ensure_output_buffer(config)
  local buf = find_output_buffer(config.output_buffer_name)
  local win

  if buf then
    win = vim.fn.bufwinid(buf)
    if win ~= -1 then
      vim.api.nvim_set_current_win(win)
    else
      vim.cmd(config.split_command)
      vim.api.nvim_win_set_buf(0, buf)
      win = vim.api.nvim_get_current_win()
    end
  else
    vim.cmd(config.split_command)
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_buf_set_name(buf, config.output_buffer_name)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
  end

  return buf, win
end

local function append_lines(buf, lines)
  if not lines or vim.tbl_isempty(lines) then
    return
  end

  local last = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_buf_set_lines(buf, last, last, false, lines)
end

local function scroll_to_bottom(buf, win)
  if not win or win == -1 then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_win_set_cursor(win, { line_count, 0 })
end

local function notify_error(message)
  vim.notify(message, vim.log.levels.ERROR)
end

local function file_has_shebang(path)
  local ok, lines = pcall(vim.fn.readfile, path, "", 1)
  if not ok or not lines or #lines == 0 then
    return false
  end
  return vim.startswith(lines[1], "#!")
end

local function detect_runner(path, config)
  local ext = vim.fn.fnamemodify(path, ":e")

  if ext == "js" or ext == "ts" then
    if vim.fn.executable(config.bun_command) == 1 then
      return config.bun_command
    end
    return nil, "bun is not available in PATH"
  end

  local runner = config.extension_runners[ext]
  if runner then
    if vim.fn.executable(runner) == 1 then
      return runner
    end
    return nil, runner .. " is not available in PATH"
  end

  if vim.fn.executable(path) == 1 and file_has_shebang(path) then
    return path
  end

  if ext == "" and file_has_shebang(path) then
    return path
  end

  if config.shell_fallback and file_has_shebang(path) == false then
    return config.shell_fallback
  end

  return nil, "unsupported file type"
end

local function build_command(path, args, config)
  local runner, err = detect_runner(path, config)
  if not runner then
    return nil, err
  end

  local cmd = { runner, path }
  for _, arg in ipairs(args) do
    table.insert(cmd, arg)
  end

  return cmd
end

local function split_args(raw)
  if not raw or raw == "" then
    return {}
  end
  return vim.split(raw, "%s+", { trimempty = true })
end

local function write_separator(buf)
  local separator = string.rep("-", 72)
  append_lines(buf, { "", separator, "" })
end

local function start_job(cmd, buf, win, config)
  append_lines(buf, { table.concat(cmd, " ") })

  local function handle_output(_, data)
    if not data then
      return
    end
    if #data == 1 and data[1] == "" then
      return
    end
    append_lines(buf, data)
    if config.auto_scroll then
      scroll_to_bottom(buf, win)
    end
  end

  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = handle_output,
    on_stderr = handle_output,
    on_exit = function(_, code)
      append_lines(buf, { "", "[Process exited with code " .. code .. "]" })
      if config.auto_scroll then
        scroll_to_bottom(buf, win)
      end
    end,
  })

  if job_id <= 0 then
    notify_error("Failed to start job")
  end
end

local function run_make(raw_args, config)
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    notify_error("Buffer has no file name")
    return
  end

  if vim.fn.filereadable(path) == 0 then
    notify_error("File is not readable: " .. path)
    return
  end

  local args = split_args(raw_args)
  local cmd, err = build_command(path, args, config)
  if not cmd then
    notify_error(err)
    return
  end

  local buf, win = ensure_output_buffer(config)
  write_separator(buf)
  start_job(cmd, buf, win, config)
end

function M.setup(config)
  local merged = merge_config(config)
  vim.api.nvim_create_user_command("Make", function(opts)
    run_make(opts.args, merged)
  end, { nargs = "*", complete = "file" })
end

return M
