-- auto_cwd Root Detection Logic
-- Core functionality for finding project roots based on language configurations

local M = {}

-- Cache for discovered roots to avoid repeated filesystem searches
local root_cache = {}

---Clear the root cache
function M.clear_cache()
  for k in pairs(root_cache) do
    root_cache[k] = nil
  end
end

---Find project root for a given file path and language config
---@param file_path string Path to the file
---@param lang_config table Language configuration with root_indicators and priority
---@param use_cache boolean Whether to use cached results
---@param debug boolean Whether debug mode is enabled
---@return string|nil Root directory path or nil if not found
function M.find_project_root(file_path, lang_config, use_cache, debug)
  use_cache = use_cache ~= false -- default to true
  debug = debug or false

  if debug then
    print("auto_cwd DEBUG: find_project_root() called for:", file_path)
    print("auto_cwd DEBUG: root indicators priority:", vim.inspect(lang_config.priority))
  end

  -- Check cache first
  local cache_key = file_path .. ":" .. vim.inspect(lang_config.root_indicators)
  if use_cache and root_cache[cache_key] then
    if debug then
      print("auto_cwd DEBUG: using cached result:", root_cache[cache_key])
    end
    return root_cache[cache_key]
  end

  local dir = vim.fn.fnamemodify(file_path, ":h")
  if debug then
    print("auto_cwd DEBUG: starting search from directory:", dir)
  end

  -- Search upward for root indicators in priority order
  for _, indicator in ipairs(lang_config.priority) do
    if debug then
      print("auto_cwd DEBUG: searching for indicator:", indicator)
    end

    local root = vim.fs.root(dir, function(name)
      return name:match(indicator:gsub("%*", ".*")) ~= nil
    end)

    if root then
      if debug then
        print("auto_cwd DEBUG: found root with indicator", indicator, "at:", root)
      end

      -- Cache the result
      if use_cache then
        root_cache[cache_key] = root
      end
      return root
    else
      if debug then
        print("auto_cwd DEBUG: indicator", indicator, "not found")
      end
    end
  end

  if debug then
    print("auto_cwd DEBUG: no root found for any indicator")
  end

  -- Cache negative result
  if use_cache then
    root_cache[cache_key] = nil
  end

  return nil
end

---Detect and set CWD for the current buffer
---@param config table|nil Plugin configuration (uses current config if nil)
---@return boolean True if CWD was changed, false otherwise
function M.detect_and_set_cwd(config)
  config = config or require("auto_cwd.setup").get_current_config()

  if config.debug then
    print("auto_cwd DEBUG: detect_and_set_cwd() triggered")
  end

  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file == "" then
    if config.debug then
      print("auto_cwd DEBUG: current buffer has no file name, skipping")
    end
    return false
  end

  if config.debug then
    print("auto_cwd DEBUG: processing file:", current_file)
    print("auto_cwd DEBUG: enabled languages:", vim.inspect(config.enabled_languages))
  end
  
  local file_name = vim.fn.fnamemodify(current_file, ":t")
  local default_configs = require("auto_cwd.config")
  
  -- Check each enabled language
  for _, lang_name in ipairs(config.enabled_languages) do
    local lang_config = config.custom_languages[lang_name] or default_configs[lang_name]

    if config.debug then
      print("auto_cwd DEBUG: checking language:", lang_name)
    end

    if lang_config then
      -- Check if current file matches any pattern
      for _, pattern in ipairs(lang_config.patterns) do
        if config.debug then
          print("auto_cwd DEBUG: testing pattern:", pattern, "against file:", file_name)
        end

        if file_name:match(pattern:gsub("%*", ".*")) then
          if config.debug then
            print("auto_cwd DEBUG: pattern matched! Looking for project root...")
          end

          local root = M.find_project_root(current_file, lang_config, config.cache_enabled, config.debug)

          if root then
            if config.debug then
              print("auto_cwd DEBUG: found project root:", root)
            end

            local current_cwd = vim.fn.getcwd()
            if root ~= current_cwd then
              if config.debug then
                print("auto_cwd DEBUG: changing CWD from", current_cwd, "to", root)
              end

              vim.cmd("cd " .. vim.fn.fnameescape(root))

              if config.debug then
                vim.notify(
                  string.format("auto_cwd: Changed to %s (%s)", root, lang_name),
                  vim.log.levels.INFO
                )
              end

              return true
            else
              if config.debug then
                print("auto_cwd DEBUG: already in correct directory:", current_cwd)
              end
              return false -- Already in correct directory
            end
          else
            if config.debug then
              print("auto_cwd DEBUG: no project root found for", lang_name)
            end
          end
        end
      end
    else
      if config.debug then
        print("auto_cwd DEBUG: no config found for language:", lang_name)
      end
    end
  end
  
  -- Fallback to git root if enabled
  if config.fallback_to_git then
    if config.debug then
      print("auto_cwd DEBUG: trying git fallback...")
    end

    local git_root = vim.fs.root(vim.fn.fnamemodify(current_file, ":h"), ".git")
    if git_root then
      if config.debug then
        print("auto_cwd DEBUG: found git root:", git_root)
      end

      local current_cwd = vim.fn.getcwd()
      if git_root ~= current_cwd then
        if config.debug then
          print("auto_cwd DEBUG: changing CWD to git root:", git_root)
        end

        vim.cmd("cd " .. vim.fn.fnameescape(git_root))

        if config.debug then
          vim.notify(
            string.format("auto_cwd: Fallback to git root %s", git_root),
            vim.log.levels.INFO
          )
        end

        return true
      else
        if config.debug then
          print("auto_cwd DEBUG: already in git root directory")
        end
      end
    else
      if config.debug then
        print("auto_cwd DEBUG: no git root found")
      end
    end
  else
    if config.debug then
      print("auto_cwd DEBUG: git fallback disabled")
    end
  end

  if config.debug then
    print("auto_cwd DEBUG: no CWD change made")
  end

  return false
end

-- Expose for testing
M._find_project_root = M.find_project_root
M._root_cache = root_cache

return M
