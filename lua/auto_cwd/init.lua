-- auto_cwd.nvim - Automatic working directory management
-- A language-aware plugin that automatically switches to project root directories
-- based on configurable file patterns and root indicators.

local M = {}

---Setup the auto_cwd plugin with user configuration
---@param user_opts table|nil User configuration options
function M.setup(user_opts)
  local setup = require("auto_cwd.setup")
  local config = setup.configure(user_opts)
  
  -- Only proceed if plugin is enabled
  if not config.enabled then
    return
  end
  
  -- Setup autocmds for enabled languages
  require("auto_cwd.autocmds").setup(config)
end

---Get the current configuration (for debugging/inspection)
---@return table Current configuration
function M.get_config()
  return require("auto_cwd.setup").get_current_config()
end

---Enable a language at runtime
---@param lang_name string Language name to enable
function M.enable_language(lang_name)
  require("auto_cwd.autocmds").enable_language(lang_name)
end

---Disable a language at runtime
---@param lang_name string Language name to disable
function M.disable_language(lang_name)
  require("auto_cwd.autocmds").disable_language(lang_name)
end

---Manually trigger CWD detection for current buffer
function M.detect_and_set_cwd()
  require("auto_cwd.detector").detect_and_set_cwd()
end

---Enable debug mode at runtime
function M.enable_debug()
  local setup = require("auto_cwd.setup")
  local config = setup.get_current_config()
  config.debug = true
  print("auto_cwd: Debug mode enabled")
end

---Disable debug mode at runtime
function M.disable_debug()
  local setup = require("auto_cwd.setup")
  local config = setup.get_current_config()
  config.debug = false
  print("auto_cwd: Debug mode disabled")
end

---Clear the root detection cache
function M.clear_cache()
  require("auto_cwd.detector").clear_cache()
  print("auto_cwd: Cache cleared")
end

return M
