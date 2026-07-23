local function has_codeartifact_pip()
  local env_indexes = {
    vim.env.PIP_INDEX_URL or "",
    vim.env.PIP_EXTRA_INDEX_URL or "",
    vim.env.UV_INDEX_URL or "",
    vim.env.UV_EXTRA_INDEX_URL or "",
  }
  for _, value in ipairs(env_indexes) do
    if value:find("codeartifact", 1, true) then
      return true
    end
  end

  local pip_conf_paths = {
    vim.fn.expand("~/.config/pip/pip.conf"),
    vim.fn.expand("~/.pip/pip.conf"),
    "/etc/pip.conf",
  }
  for _, path in ipairs(pip_conf_paths) do
    if vim.uv.fs_stat(path) then
      local content = table.concat(vim.fn.readfile(path), "\n")
      if content:find("codeartifact", 1, true) then
        return true
      end
    end
  end

  return false
end

local has_go = vim.fn.executable("go") == 1
local private_pip_index = has_codeartifact_pip()

return {
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gblame", "Gvdiffsplit" },
    keys = {
      { "<leader>gg", "<cmd>Git<cr>", desc = "Git Status (Fugitive)" },
      { "<leader>gB", "<cmd>Gblame<cr>", desc = "Git Blame (Fugitive)" },
    },
  },
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>uD", "<cmd>UndotreeToggle<cr>", desc = "Undo Tree" },
    },
  },
  {
    "folke/trouble.nvim",
    opts = { use_diagnostic_signs = true },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      local tools = {
        "eslint_d",
        "jq",
        "prettier",
        "shellcheck",
        "shfmt",
        "stylua",
        "yamlfmt",
      }
      if has_go then
        vim.list_extend(tools, { "delve", "gofumpt", "goimports" })
      end
      if not private_pip_index then
        vim.list_extend(tools, { "black", "debugpy" })
      end
      opts.ensure_installed = opts.ensure_installed or {}
      for _, tool in ipairs(tools) do
        if not vim.tbl_contains(opts.ensure_installed, tool) then
          table.insert(opts.ensure_installed, tool)
        end
      end

      local blocked = {}
      if not has_go then
        vim.list_extend(blocked, { "delve", "gofumpt", "goimports", "gopls" })
      end
      if private_pip_index then
        vim.list_extend(blocked, { "black", "debugpy", "ruff", "sqlfluff" })
      end

      if #blocked > 0 then
        opts.ensure_installed = vim.tbl_filter(function(pkg)
          return not vim.tbl_contains(blocked, pkg)
        end, opts.ensure_installed)
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      if not has_go and opts.servers.gopls then
        opts.servers.gopls.enabled = false
      end
      if private_pip_index and opts.servers.ruff then
        opts.servers.ruff.enabled = false
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      local parsers = {
        "bash",
        "dockerfile",
        "go",
        "gomod",
        "gosum",
        "hcl",
        "html",
        "javascript",
        "json",
        "jsonc",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "sql",
        "terraform",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      }
      opts.ensure_installed = opts.ensure_installed or {}
      for _, parser in ipairs(parsers) do
        if not vim.tbl_contains(opts.ensure_installed, parser) then
          table.insert(opts.ensure_installed, parser)
        end
      end
    end,
  },
}
