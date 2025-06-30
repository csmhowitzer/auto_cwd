---@diagnostic disable: undefined-field

-- Set up module path for testing
local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local lua_dir = plugin_dir .. "/lua"
if not package.path:find(lua_dir, 1, true) then
  package.path = lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua;" .. package.path
end

local eq = assert.are.same

describe("auto_cwd.config", function()
  local config

  before_each(function()
    -- Clear any existing modules for clean state
    package.loaded["auto_cwd.config"] = nil

    config = require("auto_cwd.config")
  end)
  
  describe("language configurations", function()
    it("should have csharp configuration", function()
      assert.is_not_nil(config.csharp)
      eq({ "*.cs" }, config.csharp.patterns)
      eq({ "*.sln", "*.csproj" }, config.csharp.root_indicators)
      eq({ "*.sln", "*.csproj" }, config.csharp.priority)
      assert.is_string(config.csharp.description)
    end)
    
    it("should have golang configuration", function()
      assert.is_not_nil(config.golang)
      eq({ "*.go" }, config.golang.patterns)
      eq({ "go.work", "go.mod", "go.sum" }, config.golang.root_indicators)
      eq({ "go.work", "go.mod" }, config.golang.priority)
      assert.is_string(config.golang.description)
    end)
    
    it("should have frontend configuration", function()
      assert.is_not_nil(config.frontend)
      eq({ "*.js", "*.jsx", "*.ts", "*.tsx", "*.vue", "*.svelte" }, config.frontend.patterns)
      eq({ "package.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb" }, config.frontend.root_indicators)
      eq({ "package.json" }, config.frontend.priority)
      assert.is_string(config.frontend.description)
    end)
    
    it("should have python configuration", function()
      assert.is_not_nil(config.python)
      eq({ "*.py" }, config.python.patterns)
      eq({ "pyproject.toml", "setup.py", "requirements.txt", "Pipfile", "poetry.lock" }, config.python.root_indicators)
      eq({ "pyproject.toml", "setup.py" }, config.python.priority)
      assert.is_string(config.python.description)
    end)
    
    it("should have rust configuration", function()
      assert.is_not_nil(config.rust)
      eq({ "*.rs" }, config.rust.patterns)
      eq({ "Cargo.toml", "Cargo.lock" }, config.rust.root_indicators)
      eq({ "Cargo.toml" }, config.rust.priority)
      assert.is_string(config.rust.description)
    end)
    
    it("should have obsidian configuration", function()
      assert.is_not_nil(config.obsidian)
      eq({ "*.md", "*.markdown" }, config.obsidian.patterns)
      eq({ ".obsidian", ".git" }, config.obsidian.root_indicators)
      eq({ ".obsidian", ".git" }, config.obsidian.priority)
      assert.is_string(config.obsidian.description)
    end)
  end)
  
  describe("configuration structure", function()
    local function validate_lang_config(lang_name, lang_config)
      assert.is_table(lang_config, lang_name .. " should be a table")
      assert.is_table(lang_config.patterns, lang_name .. " should have patterns array")
      assert.is_table(lang_config.root_indicators, lang_name .. " should have root_indicators array")
      assert.is_table(lang_config.priority, lang_name .. " should have priority array")
      assert.is_string(lang_config.description, lang_name .. " should have description string")
      
      -- Patterns should not be empty
      assert.is_true(#lang_config.patterns > 0, lang_name .. " should have at least one pattern")
      
      -- Root indicators should not be empty
      assert.is_true(#lang_config.root_indicators > 0, lang_name .. " should have at least one root indicator")
      
      -- Priority should not be empty
      assert.is_true(#lang_config.priority > 0, lang_name .. " should have at least one priority item")
      
      -- All priority items should exist in root_indicators
      for _, priority_item in ipairs(lang_config.priority) do
        local found = false
        for _, indicator in ipairs(lang_config.root_indicators) do
          if indicator == priority_item then
            found = true
            break
          end
        end
        assert.is_true(found, lang_name .. " priority item '" .. priority_item .. "' should exist in root_indicators")
      end
    end
    
    it("should have valid structure for all languages", function()
      for lang_name, lang_config in pairs(config) do
        validate_lang_config(lang_name, lang_config)
      end
    end)
    
    it("should have consistent pattern formats", function()
      for lang_name, lang_config in pairs(config) do
        for _, pattern in ipairs(lang_config.patterns) do
          -- Patterns should be strings
          assert.is_string(pattern, lang_name .. " pattern should be string: " .. tostring(pattern))
          
          -- Most patterns should start with *. (file extensions)
          if not pattern:match("^%*%.") then
            -- Allow some exceptions like specific filenames
            assert.is_true(
              pattern:match("^[%w_%-%.]+$"), 
              lang_name .. " pattern should be either *.ext or filename: " .. pattern
            )
          end
        end
      end
    end)
    
    it("should have reasonable root indicators", function()
      for lang_name, lang_config in pairs(config) do
        for _, indicator in ipairs(lang_config.root_indicators) do
          assert.is_string(indicator, lang_name .. " root indicator should be string")

          -- Should be either a filename or pattern
          -- Just check that it's not empty and contains reasonable characters
          assert.is_true(
            #indicator > 0 and not indicator:match("[^%w%._%-%*]"),
            lang_name .. " root indicator should be valid filename/pattern: " .. indicator
          )
        end
      end
    end)
  end)
  
  describe("language coverage", function()
    it("should cover common development languages", function()
      local expected_languages = {
        "csharp", "golang", "frontend", "python", "rust", "obsidian"
      }
      
      for _, lang in ipairs(expected_languages) do
        assert.is_not_nil(config[lang], "Should have configuration for " .. lang)
      end
    end)
    
    it("should have unique patterns across languages where appropriate", function()
      local pattern_to_langs = {}
      
      for lang_name, lang_config in pairs(config) do
        for _, pattern in ipairs(lang_config.patterns) do
          if not pattern_to_langs[pattern] then
            pattern_to_langs[pattern] = {}
          end
          table.insert(pattern_to_langs[pattern], lang_name)
        end
      end
      
      -- Some patterns like *.md might be shared (obsidian), but most should be unique
      for pattern, langs in pairs(pattern_to_langs) do
        if #langs > 1 then
          -- Only allow certain known overlaps
          local allowed_overlaps = {
            ["*.md"] = { "obsidian" }, -- markdown can be shared
            ["*.markdown"] = { "obsidian" }
          }
          
          if not allowed_overlaps[pattern] then
            assert.fail("Pattern " .. pattern .. " is used by multiple languages: " .. table.concat(langs, ", "))
          end
        end
      end
    end)
  end)
end)
