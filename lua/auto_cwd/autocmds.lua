-- auto_cwd Autocmd Management
-- Handles creation and management of BufEnter autocmds for enabled languages

local M = {}

-- Track enabled languages and their autocmd IDs
local enabled_autocmds = {}
local augroup_id = nil

---Setup autocmds for all enabled languages
---@param config table Plugin configuration
function M.setup(config)
  -- Create augroup
  augroup_id = vim.api.nvim_create_augroup("AutoCwd", { clear = true })
  
  -- Setup autocmds for each enabled language
  for _, lang_name in ipairs(config.enabled_languages) do
    M.enable_language(lang_name, config)
  end
end

---Enable autocmd for a specific language
---@param lang_name string Language name to enable
---@param config table|nil Plugin configuration (uses current if nil)
function M.enable_language(lang_name, config)
  config = config or require("auto_cwd.setup").get_current_config()
  
  -- Skip if already enabled
  if enabled_autocmds[lang_name] then
    return
  end
  
  local default_configs = require("auto_cwd.config")
  local lang_config = config.custom_languages[lang_name] or default_configs[lang_name]
  
  if not lang_config then
    vim.notify(
      string.format("auto_cwd: Unknown language '%s'", lang_name),
      vim.log.levels.WARN
    )
    return
  end
  
  -- Create autocmd for this language
  local autocmd_id = vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup_id,
    pattern = lang_config.patterns,
    callback = function()
      if config.debug then
        local current_file = vim.api.nvim_buf_get_name(0)
        print("auto_cwd DEBUG: BufEnter triggered for", lang_name, "- file:", current_file)
      end
      require("auto_cwd.detector").detect_and_set_cwd(config)
    end,
    desc = string.format("auto_cwd: %s (%s)", lang_name, lang_config.description or "")
  })
  
  enabled_autocmds[lang_name] = autocmd_id
  
  if config.debug then
    vim.notify(
      string.format("auto_cwd: Enabled %s for patterns: %s", 
        lang_name, 
        table.concat(lang_config.patterns, ", ")
      ),
      vim.log.levels.INFO
    )
  end
end

---Disable autocmd for a specific language
---@param lang_name string Language name to disable
function M.disable_language(lang_name)
  local autocmd_id = enabled_autocmds[lang_name]
  if autocmd_id then
    vim.api.nvim_del_autocmd(autocmd_id)
    enabled_autocmds[lang_name] = nil
    
    local config = require("auto_cwd.setup").get_current_config()
    if config.debug then
      vim.notify(
        string.format("auto_cwd: Disabled %s", lang_name),
        vim.log.levels.INFO
      )
    end
  end
end

---Get list of currently enabled languages
---@return table List of enabled language names
function M.get_enabled_languages()
  return vim.tbl_keys(enabled_autocmds)
end

-- Expose for testing
M._enabled_autocmds = enabled_autocmds
M._get_augroup_id = function() return augroup_id end

return M
