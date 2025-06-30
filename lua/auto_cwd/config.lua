-- auto_cwd Language Configurations
-- Default language configurations for common development environments
-- All languages are disabled by default - users must opt-in via enabled_languages

return {
  csharp = {
    patterns = { "*.cs" },
    root_indicators = { "*.sln", "*.csproj" },
    priority = { "*.sln", "*.csproj" }, -- prefer solution over project
    description = "C# projects - looks for .sln (solution) or .csproj files"
  },
  
  golang = {
    patterns = { "*.go" },
    root_indicators = { "go.work", "go.mod", "go.sum" },
    priority = { "go.work", "go.mod" }, -- workspace > module
    description = "Go projects - looks for go.work (workspace) or go.mod files"
  },
  
  frontend = {
    patterns = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.vue", "*.svelte" },
    root_indicators = { "package.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb" },
    priority = { "package.json" },
    description = "Frontend projects - looks for package.json and lock files"
  },
  
  python = {
    patterns = { "*.py" },
    root_indicators = { "pyproject.toml", "setup.py", "requirements.txt", "Pipfile", "poetry.lock" },
    priority = { "pyproject.toml", "setup.py" },
    description = "Python projects - looks for pyproject.toml, setup.py, or requirements files"
  },
  
  rust = {
    patterns = { "*.rs" },
    root_indicators = { "Cargo.toml", "Cargo.lock" },
    priority = { "Cargo.toml" },
    description = "Rust projects - looks for Cargo.toml files"
  },
  
  obsidian = {
    patterns = { "*.md", "*.markdown" },
    root_indicators = { ".obsidian", ".git" },
    priority = { ".obsidian", ".git" }, -- obsidian vault > git repo
    description = "Obsidian vaults - example custom setup for markdown with .obsidian directories"
  }
}
