# auto_cwd.nvim

Automatic working directory management for Neovim. Intelligently switches to project root directories based on file types and configurable root indicators.

## Features

- **Language-aware**: Supports C#, Go, Frontend (JS/TS), Python, Rust, and Obsidian out of the box
- **Configurable**: Easy to add custom languages and root detection patterns
- **Opt-in**: All languages disabled by default - you choose what to enable
- **Cached**: Filesystem searches are cached for performance
- **Runtime control**: Enable/disable languages on the fly
- **Debug mode**: Comprehensive logging to understand when and why CWD changes occur

## Installation

### With lazy.nvim (local plugin)

```lua
-- In your lua/plugins/dev.lua or similar
return {
  {
    dir = "~/plugins/auto_cwd.nvim",
    name = "auto_cwd",
    config = function()
      require("auto_cwd").setup({
        enabled_languages = { "csharp", "golang", "frontend" },
        cache_enabled = true,
        debug = false,
      })
    end,
  },
}
```

## Configuration

### Basic Setup

```lua
require("auto_cwd").setup({
  enabled_languages = { "csharp", "golang", "obsidian" },
  cache_enabled = true,
  fallback_to_git = false,
  debug = false,
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled_languages` | `table` | `{}` | **List of languages to enable**. Empty by default - you must opt-in to specific languages. Available: `"csharp"`, `"golang"`, `"frontend"`, `"python"`, `"rust"`, `"obsidian"` |
| `cache_enabled` | `boolean` | `true` | **Enable filesystem search caching**. When `true`, discovered project roots are cached to avoid repeated filesystem searches for better performance |
| `fallback_to_git` | `boolean` | `false` | **Fallback to git root**. When `true`, if no language-specific root is found, falls back to searching for `.git` directory |
| `debug` | `boolean` | `false` | **Enable debug notifications**. When `true`, shows notifications when CWD changes occur, useful for troubleshooting |
| `custom_languages` | `table` | `{}` | **Define custom language configurations**. Allows you to add your own file patterns and root detection rules |

### Language-Specific Behavior

When you enable a language, the plugin will:

1. **Monitor file patterns** - Watch for files matching the language's patterns (e.g., `*.cs` for C#)
2. **Search for root indicators** - Look upward from the file for project root markers
3. **Change working directory** - Set Neovim's CWD to the discovered project root
4. **Cache results** - Remember discovered roots for performance (if `cache_enabled = true`)

### Available Languages

- **`csharp`**: Looks for `*.sln` or `*.csproj` files
  - Patterns: `*.cs`
  - Root indicators: `*.sln`, `*.csproj` (prefers solution over project)
  
- **`golang`**: Looks for `go.work` or `go.mod` files  
  - Patterns: `*.go`
  - Root indicators: `go.work`, `go.mod`, `go.sum` (prefers workspace over module)
  
- **`frontend`**: Looks for `package.json` files
  - Patterns: `*.js`, `*.jsx`, `*.ts`, `*.tsx`, `*.vue`, `*.svelte`
  - Root indicators: `package.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb`
  
- **`python`**: Looks for `pyproject.toml`, `setup.py`, etc.
  - Patterns: `*.py`
  - Root indicators: `pyproject.toml`, `setup.py`, `requirements.txt`, `Pipfile`, `poetry.lock`
  
- **`rust`**: Looks for `Cargo.toml` files
  - Patterns: `*.rs`
  - Root indicators: `Cargo.toml`, `Cargo.lock`
  
- **`obsidian`**: Looks for `.obsidian` or `.git` directories (example custom setup)
  - Patterns: `*.md`, `*.markdown`
  - Root indicators: `.obsidian`, `.git` (prefers obsidian vault over git repo)

### Adding Custom Languages

```lua
require("auto_cwd").setup({
  enabled_languages = { "my_custom_lang" },
  custom_languages = {
    my_custom_lang = {
      patterns = { "*.myext", "*.custom" },
      root_indicators = { ".myproject", "project.config" },
      priority = { ".myproject", "project.config" },
      description = "My custom project type"
    }
  }
})
```

### Runtime Control

```lua
-- Enable/disable languages at runtime
require("auto_cwd").enable_language("python")
require("auto_cwd").disable_language("frontend")

-- Debug mode control
require("auto_cwd").enable_debug()
require("auto_cwd").disable_debug()

-- Cache management
require("auto_cwd").clear_cache()

-- Manually trigger detection
require("auto_cwd").detect_and_set_cwd()

-- Get current config
local config = require("auto_cwd").get_config()
```

## How It Works

1. **File Detection**: When you open a file, the plugin checks if it matches any enabled language patterns
2. **Root Search**: Searches upward from the file's directory for root indicators (in priority order)
3. **Directory Switch**: Changes Neovim's working directory to the found project root
4. **Caching**: Results are cached to avoid repeated filesystem searches

## Examples

### C# Development
- Opening `MyProject/src/Program.cs` 
- Finds `MyProject/MyProject.sln`
- Sets CWD to `MyProject/` so `dotnet` commands work correctly

### Go Development  
- Opening `myapp/cmd/main.go`
- Finds `myapp/go.mod`
- Sets CWD to `myapp/` so `go build` works correctly

### Obsidian Notes
- Opening `MyVault/Notes/daily.md`
- Finds `MyVault/.obsidian/`
- Sets CWD to `MyVault/` for proper vault context

## Troubleshooting

### Enable Debug Mode

Debug mode provides detailed logging to help you understand when and why auto_cwd triggers:

```lua
-- Enable debug mode during setup
require("auto_cwd").setup({
  debug = true,  -- Shows detailed debug output
})

-- Or enable debug mode at runtime
require("auto_cwd").enable_debug()

-- Disable debug mode at runtime
require("auto_cwd").disable_debug()
```

When debug mode is enabled, you'll see detailed output like:
```
auto_cwd DEBUG: BufEnter triggered for golang - file: /path/to/project/main.go
auto_cwd DEBUG: detect_and_set_cwd() triggered
auto_cwd DEBUG: processing file: /path/to/project/main.go
auto_cwd DEBUG: enabled languages: { "golang" }
auto_cwd DEBUG: checking language: golang
auto_cwd DEBUG: testing pattern: *.go against file: main.go
auto_cwd DEBUG: pattern matched! Looking for project root...
auto_cwd DEBUG: find_project_root() called for: /path/to/project/main.go
auto_cwd DEBUG: found root with indicator go.mod at: /path/to/project
auto_cwd DEBUG: changing CWD from /old/path to /path/to/project
```

### Check Current Configuration
```lua
-- See what languages are enabled and current settings
local config = require("auto_cwd").get_config()
print(vim.inspect(config))
```

### Clear Cache
```lua
-- If you're having issues with cached results
require("auto_cwd").clear_cache()
```

### Manual Trigger
```lua
-- Manually trigger CWD detection for current buffer
require("auto_cwd").detect_and_set_cwd()
```
