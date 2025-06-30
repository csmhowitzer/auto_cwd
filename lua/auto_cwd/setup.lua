-- auto_cwd Setup - User configuration with smart defaults
local M = {}

-- Current configuration (set during setup)
local current_config = {}

---Get default configuration
---@return table Default configuration options
function M.defaults()
  return {
    enabled = true,
    enabled_languages = {}, -- opt-in only, empty by default
    cache_enabled = true,
    fallback_to_git = false,
    custom_languages = {},
    debug = false,
  }
end

---Configure the plugin by merging user options with defaults
---@param user_opts table|nil User configuration options
---@return table Merged configuration
function M.configure(user_opts)
  local defaults = M.defaults()
  current_config = vim.tbl_deep_extend("force", defaults, user_opts or {})
  return current_config
end

---Get the current configuration
---@return table Current configuration
function M.get_current_config()
  return current_config
end

-- Expose for testing
M._get_current_config_ref = function() return current_config end

return M
