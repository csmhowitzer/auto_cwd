-- Tests for auto_cwd main module
-- Run with: :PlenaryBustedFile ~/plugins/auto_cwd.nvim/tests/auto_cwd/init_spec.lua

-- Set up module path for testing
local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local lua_dir = plugin_dir .. "/lua"
if not package.path:find(lua_dir, 1, true) then
  package.path = lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua;" .. package.path
end

describe("auto_cwd", function()
  local auto_cwd

  before_each(function()
    -- Clear any existing configuration
    package.loaded["auto_cwd"] = nil
    package.loaded["auto_cwd.setup"] = nil
    package.loaded["auto_cwd.config"] = nil
    package.loaded["auto_cwd.detector"] = nil
    package.loaded["auto_cwd.autocmds"] = nil

    auto_cwd = require("auto_cwd")
  end)
  
  describe("setup", function()
    it("should have a setup function", function()
      assert.is_function(auto_cwd.setup)
    end)
    
    it("should setup with default config", function()
      assert.has_no.errors(function()
        auto_cwd.setup()
      end)
    end)
    
    it("should setup with custom config", function()
      assert.has_no.errors(function()
        auto_cwd.setup({
          enabled_languages = { "csharp" },
          cache_enabled = false,
          debug = true,
        })
      end)
    end)
  end)
  
  describe("API functions", function()
    it("should have all expected API functions", function()
      assert.is_function(auto_cwd.setup)
      assert.is_function(auto_cwd.get_config)
      assert.is_function(auto_cwd.enable_language)
      assert.is_function(auto_cwd.disable_language)
      assert.is_function(auto_cwd.detect_and_set_cwd)
      assert.is_function(auto_cwd.enable_debug)
      assert.is_function(auto_cwd.disable_debug)
      assert.is_function(auto_cwd.clear_cache)
    end)
  end)

  describe("debug functionality", function()
    before_each(function()
      auto_cwd.setup({
        enabled_languages = { "golang" },
        debug = false
      })
    end)

    it("should enable debug mode", function()
      auto_cwd.enable_debug()

      local config = auto_cwd.get_config()
      assert.is_true(config.debug)
    end)

    it("should disable debug mode", function()
      auto_cwd.setup({ debug = true })
      auto_cwd.disable_debug()

      local config = auto_cwd.get_config()
      assert.is_false(config.debug)
    end)

    it("should clear cache", function()
      assert.has_no.errors(function()
        auto_cwd.clear_cache()
      end)
    end)
  end)

  describe("language management", function()
    before_each(function()
      auto_cwd.setup({
        enabled_languages = {},
        debug = false
      })
    end)

    it("should enable language at runtime", function()
      assert.has_no.errors(function()
        auto_cwd.enable_language("golang")
      end)
    end)

    it("should disable language at runtime", function()
      auto_cwd.enable_language("golang")

      assert.has_no.errors(function()
        auto_cwd.disable_language("golang")
      end)
    end)

    it("should manually trigger CWD detection", function()
      assert.has_no.errors(function()
        auto_cwd.detect_and_set_cwd()
      end)
    end)
  end)
end)
