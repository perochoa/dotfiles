return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
      local function preferred_cmd(bin)
        local mason_cmd = mason_bin .. "/" .. bin
        if vim.fn.executable(mason_cmd) == 1 then
          return mason_cmd
        end
        return bin
      end

      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.json = { "prettier", "jq", stop_after_first = true }
      opts.formatters_by_ft.jsonc = { "prettier", "jq", stop_after_first = true }
      opts.formatters_by_ft.json5 = { "prettier", "jq", stop_after_first = true }

      opts.formatters = opts.formatters or {}
      local prettier = opts.formatters.prettier or {}
      local prettier_condition = prettier.condition
      opts.formatters.prettier = vim.tbl_deep_extend("force", prettier, {
        command = preferred_cmd("prettier"),
      })
      opts.formatters.prettier.condition = function(self, ctx)
        if vim.fn.executable("node") ~= 1 then
          return false
        end
        if type(prettier_condition) == "function" then
          return prettier_condition(self, ctx)
        end
        return true
      end
      opts.formatters.jq = vim.tbl_deep_extend("force", opts.formatters.jq or {}, {
        command = preferred_cmd("jq"),
      })
    end,
  },
}
