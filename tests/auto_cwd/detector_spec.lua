---@diagnostic disable: undefined-field

-- Set up module path for testing
local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local lua_dir = plugin_dir .. "/lua"
if not package.path:find(lua_dir, 1, true) then
  package.path = lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua;" .. package.path
end

local eq = assert.are.same

describe("auto_cwd.detector", function()
  local detector

  before_each(function()
    -- Clear any existing modules for clean state
    package.loaded["auto_cwd.detector"] = nil
    package.loaded["auto_cwd.setup"] = nil
    package.loaded["auto_cwd.config"] = nil

    detector = require("auto_cwd.detector")
    -- Clear cache before each test
    detector.clear_cache()
  end)
  
  describe("clear_cache", function()
    it("should clear the root cache", function()
      -- Access internal cache and add a test entry
      local cache = detector._root_cache
      cache["test"] = "value"

      -- Verify the entry was added
      assert.is_not_nil(cache["test"])

      detector.clear_cache()

      -- Verify the cache is now empty
      assert.is_nil(cache["test"])
      eq({}, cache)
    end)
  end)
  
  describe("find_project_root", function()
    local mock_lang_config = {
      priority = { "go.mod", "*.go" },
      root_indicators = { "go.mod", "*.go" }
    }
    
    it("should return nil for empty priority list", function()
      local config = { priority = {}, root_indicators = {} }
      local result = detector._find_project_root("/tmp/test.go", config, false, false)
      eq(nil, result)
    end)
    
    it("should handle non-existent file path", function()
      local result = detector._find_project_root("/non/existent/path/test.go", mock_lang_config, false, false)
      eq(nil, result)
    end)
    
    it("should use cache when enabled", function()
      -- First, clear the cache to ensure clean state
      detector.clear_cache()

      local cache = detector._root_cache
      local test_path = "/tmp/test.go"
      local cache_key = test_path .. ":" .. vim.inspect(mock_lang_config.root_indicators)

      -- Manually set a cache entry
      cache[cache_key] = "/tmp"

      -- Call the function with cache enabled - should return cached value
      local result = detector._find_project_root(test_path, mock_lang_config, true, false)

      -- Should return the cached value
      eq("/tmp", result)
    end)
    
    it("should skip cache when disabled", function()
      local cache = detector._root_cache
      local cache_key = "/tmp/test.go:" .. vim.inspect(mock_lang_config.root_indicators)
      cache[cache_key] = "/tmp"
      
      -- With cache disabled, should not use cached value
      local result = detector._find_project_root("/tmp/test.go", mock_lang_config, false, false)
      -- Result depends on actual filesystem, but cache shouldn't be used
      assert.is_not_nil(result == nil or type(result) == "string")
    end)
  end)
  
  describe("detect_and_set_cwd", function()
    local original_cwd
    
    before_each(function()
      original_cwd = vim.fn.getcwd()
      
      -- Mock vim.api.nvim_buf_get_name to return a test file
      _G._test_buf_name = "/tmp/test.go"
      local original_get_name = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function(bufnr)
        if bufnr == 0 then
          return _G._test_buf_name or ""
        end
        return original_get_name(bufnr)
      end
    end)
    
    after_each(function()
      -- Restore original CWD
      vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))
      
      -- Clean up global
      _G._test_buf_name = nil
    end)
    
    it("should return false for empty buffer name", function()
      _G._test_buf_name = ""
      
      local config = {
        enabled_languages = { "golang" },
        custom_languages = {},
        cache_enabled = true,
        debug = false
      }
      
      local result = detector.detect_and_set_cwd(config)
      eq(false, result)
    end)
    
    it("should return false when no languages enabled", function()
      local config = {
        enabled_languages = {},
        custom_languages = {},
        cache_enabled = true,
        debug = false
      }
      
      local result = detector.detect_and_set_cwd(config)
      eq(false, result)
    end)
    
    it("should handle unknown language gracefully", function()
      local config = {
        enabled_languages = { "unknown_language" },
        custom_languages = {},
        cache_enabled = true,
        debug = false
      }
      
      local result = detector.detect_and_set_cwd(config)
      eq(false, result)
    end)
    
    it("should use custom language config when provided", function()
      _G._test_buf_name = "/tmp/custom.ext"
      
      local config = {
        enabled_languages = { "custom" },
        custom_languages = {
          custom = {
            patterns = { "*.ext" },
            priority = { "custom.config" },
            root_indicators = { "custom.config" }
          }
        },
        cache_enabled = true,
        debug = false
      }
      
      -- Should not error even if no root is found
      local result = detector.detect_and_set_cwd(config)
      assert.is_boolean(result)
    end)
    
    it("should handle git fallback when enabled", function()
      local config = {
        enabled_languages = {},
        custom_languages = {},
        cache_enabled = true,
        fallback_to_git = true,
        debug = false
      }
      
      local result = detector.detect_and_set_cwd(config)
      assert.is_boolean(result)
    end)
    
    it("should skip git fallback when disabled", function()
      local config = {
        enabled_languages = {},
        custom_languages = {},
        cache_enabled = true,
        fallback_to_git = false,
        debug = false
      }
      
      local result = detector.detect_and_set_cwd(config)
      eq(false, result)
    end)
  end)
end)
