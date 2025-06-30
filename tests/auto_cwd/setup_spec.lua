---@diagnostic disable: undefined-field

-- Set up module path for testing
local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local lua_dir = plugin_dir .. "/lua"
if not package.path:find(lua_dir, 1, true) then
  package.path = lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua;" .. package.path
end

local eq = assert.are.same

describe("auto_cwd.setup", function()
  local setup

  before_each(function()
    -- Clear any existing modules for clean state
    package.loaded["auto_cwd.setup"] = nil

    setup = require("auto_cwd.setup")
  end)
  
  describe("defaults", function()
    it("should return default configuration", function()
      local defaults = setup.defaults()
      
      eq({
        enabled = true,
        enabled_languages = {},
        cache_enabled = true,
        fallback_to_git = false,
        custom_languages = {},
        debug = false,
      }, defaults)
    end)
    
    it("should return new table each time", function()
      local defaults1 = setup.defaults()
      local defaults2 = setup.defaults()
      
      -- Should be equal but not the same table
      eq(defaults1, defaults2)
      assert.is_not.equal(defaults1, defaults2)
    end)
  end)
  
  describe("configure", function()
    it("should use defaults when no user options provided", function()
      local config = setup.configure()
      local defaults = setup.defaults()
      
      eq(defaults, config)
    end)
    
    it("should use defaults when nil user options provided", function()
      local config = setup.configure(nil)
      local defaults = setup.defaults()
      
      eq(defaults, config)
    end)
    
    it("should merge user options with defaults", function()
      local user_opts = {
        enabled_languages = { "golang", "csharp" },
        debug = true
      }
      
      local config = setup.configure(user_opts)
      
      eq({
        enabled = true,
        enabled_languages = { "golang", "csharp" },
        cache_enabled = true,
        fallback_to_git = false,
        custom_languages = {},
        debug = true,
      }, config)
    end)
    
    it("should override defaults with user options", function()
      local user_opts = {
        enabled = false,
        cache_enabled = false,
        fallback_to_git = true
      }
      
      local config = setup.configure(user_opts)
      
      eq({
        enabled = false,
        enabled_languages = {},
        cache_enabled = false,
        fallback_to_git = true,
        custom_languages = {},
        debug = false,
      }, config)
    end)
    
    it("should handle custom languages", function()
      local user_opts = {
        custom_languages = {
          mylang = {
            patterns = { "*.mylang" },
            priority = { "mylang.config" },
            root_indicators = { "mylang.config" }
          }
        }
      }
      
      local config = setup.configure(user_opts)
      
      eq(user_opts.custom_languages, config.custom_languages)
    end)
    
    it("should handle nested configuration merging", function()
      local user_opts = {
        custom_languages = {
          lang1 = {
            patterns = { "*.lang1" },
            priority = { "config1" }
          },
          lang2 = {
            patterns = { "*.lang2" },
            priority = { "config2" }
          }
        }
      }
      
      local config = setup.configure(user_opts)
      
      eq(user_opts.custom_languages.lang1, config.custom_languages.lang1)
      eq(user_opts.custom_languages.lang2, config.custom_languages.lang2)
    end)
  end)
  
  describe("get_current_config", function()
    it("should return empty config before configure is called", function()
      local config = setup.get_current_config()
      eq({}, config)
    end)
    
    it("should return current config after configure is called", function()
      local user_opts = {
        enabled_languages = { "golang" },
        debug = true
      }
      
      setup.configure(user_opts)
      local current_config = setup.get_current_config()
      
      eq({
        enabled = true,
        enabled_languages = { "golang" },
        cache_enabled = true,
        fallback_to_git = false,
        custom_languages = {},
        debug = true,
      }, current_config)
    end)
    
    it("should return updated config after multiple configure calls", function()
      -- First configuration
      setup.configure({ debug = true })
      local config1 = setup.get_current_config()
      assert.is_true(config1.debug)
      
      -- Second configuration
      setup.configure({ debug = false, enabled_languages = { "python" } })
      local config2 = setup.get_current_config()
      assert.is_false(config2.debug)
      eq({ "python" }, config2.enabled_languages)
    end)
    
    it("should return reference to actual config (not copy)", function()
      setup.configure({ debug = false })
      local config = setup.get_current_config()
      
      -- Modify the returned config
      config.debug = true
      
      -- Should affect the stored config
      local config2 = setup.get_current_config()
      assert.is_true(config2.debug)
    end)
  end)
  
  describe("internal state", function()
    it("should expose current config for testing", function()
      local user_opts = { debug = true }
      setup.configure(user_opts)

      -- Access internal config through exposed function
      local internal_config = setup._get_current_config_ref()
      assert.is_true(internal_config.debug)
    end)
  end)
end)
