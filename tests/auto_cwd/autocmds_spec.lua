---@diagnostic disable: undefined-field

-- Set up module path for testing
local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local lua_dir = plugin_dir .. "/lua"
if not package.path:find(lua_dir, 1, true) then
	package.path = lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua;" .. package.path
end

local eq = assert.are.same

describe("auto_cwd.autocmds", function()
	local autocmds

	before_each(function()
		-- Clear any existing modules for clean state
		package.loaded["auto_cwd.autocmds"] = nil
		package.loaded["auto_cwd.setup"] = nil
		package.loaded["auto_cwd.config"] = nil

		autocmds = require("auto_cwd.autocmds")

		-- Clear any existing autocmds
		local enabled = autocmds._enabled_autocmds
		for lang_name, autocmd_id in pairs(enabled) do
			if autocmd_id then
				pcall(vim.api.nvim_del_autocmd, autocmd_id)
			end
		end
		-- Clear the table
		for k in pairs(enabled) do
			enabled[k] = nil
		end
	end)

	after_each(function()
		-- Clean up any autocmds created during tests
		local enabled = autocmds._enabled_autocmds
		for lang_name, autocmd_id in pairs(enabled) do
			if autocmd_id then
				pcall(vim.api.nvim_del_autocmd, autocmd_id)
			end
		end
	end)

	describe("setup", function()
		it("should create augroup", function()
			local config = {
				enabled_languages = {},
				custom_languages = {},
				debug = false,
			}

			autocmds.setup(config)

			local augroup_id = autocmds._get_augroup_id()
			assert.is_not_nil(augroup_id)
			assert.is_number(augroup_id)
		end)

		it("should setup autocmds for enabled languages", function()
			local config = {
				enabled_languages = { "golang" },
				custom_languages = {},
				debug = false,
			}

			autocmds.setup(config)

			local enabled = autocmds._enabled_autocmds
			assert.is_not_nil(enabled.golang)
			assert.is_number(enabled.golang)
		end)

		it("should handle empty enabled languages", function()
			local config = {
				enabled_languages = {},
				custom_languages = {},
				debug = false,
			}

			assert.has_no.errors(function()
				autocmds.setup(config)
			end)

			local enabled = autocmds._enabled_autocmds
			eq({}, enabled)
		end)
	end)

	describe("enable_language", function()
		before_each(function()
			-- Setup augroup first
			local config = {
				enabled_languages = {},
				custom_languages = {},
				debug = false,
			}
			autocmds.setup(config)
		end)

		it("should enable a valid language", function()
			local config = {
				enabled_languages = {},
				custom_languages = {},
				debug = false,
			}

			autocmds.enable_language("golang", config)

			local enabled = autocmds._enabled_autocmds
			assert.is_not_nil(enabled.golang)
			assert.is_number(enabled.golang)
		end)

		it("should not enable already enabled language", function()
			local config = {
				enabled_languages = {},
				custom_languages = {},
				debug = false,
			}

			autocmds.enable_language("golang", config)
			local first_id = autocmds._enabled_autocmds.golang

			autocmds.enable_language("golang", config)
			local second_id = autocmds._enabled_autocmds.golang

			eq(first_id, second_id)
		end)

		it("should handle unknown language", function()
			local config = {
				enabled_languages = {},
				custom_languages = {},
				debug = false,
			}

			-- Should not error, but should show warning
			assert.has_no.errors(function()
				autocmds.enable_language("unknown_language", config)
			end)

			local enabled = autocmds._enabled_autocmds
			assert.is_nil(enabled.unknown_language)
		end)

		it("should enable custom language", function()
			local config = {
				enabled_languages = {},
				custom_languages = {
					custom = {
						patterns = { "*.custom" },
						priority = { "custom.config" },
						root_indicators = { "custom.config" },
						description = "Custom language",
					},
				},
				debug = false,
			}

			autocmds.enable_language("custom", config)

			local enabled = autocmds._enabled_autocmds
			assert.is_not_nil(enabled.custom)
			assert.is_number(enabled.custom)
		end)
	end)

	describe("disable_language", function()
		before_each(function()
			-- Setup augroup and enable a language
			local config = {
				enabled_languages = { "golang" },
				custom_languages = {},
				debug = false,
			}
			autocmds.setup(config)
		end)

		it("should disable enabled language", function()
			local enabled = autocmds._enabled_autocmds
			assert.is_not_nil(enabled.golang)

			autocmds.disable_language("golang")

			assert.is_nil(enabled.golang)
		end)

		it("should handle disabling non-enabled language", function()
			assert.has_no.errors(function()
				autocmds.disable_language("python")
			end)
		end)
	end)

	describe("get_enabled_languages", function()
		it("should return empty list when no languages enabled", function()
			local config = {
				enabled_languages = {},
				custom_languages = {},
				debug = false,
			}
			autocmds.setup(config)

			local enabled_langs = autocmds.get_enabled_languages()
			eq({}, enabled_langs)
		end)

		it("should return list of enabled languages", function()
			local config = {
				enabled_languages = { "golang", "csharp" },
				custom_languages = {},
				debug = false,
			}
			autocmds.setup(config)

			local enabled_langs = autocmds.get_enabled_languages()
			table.sort(enabled_langs) -- Sort for consistent comparison
			eq({ "csharp", "golang" }, enabled_langs)
		end)
	end)
end)
