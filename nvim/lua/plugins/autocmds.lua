vim.api.nvim_create_autocmd({ "BufLeave" }, {
  pattern = { "*lazygit*" },
  group = vim.api.nvim_create_augroup("git_refresh_explorer", { clear = true }),
  callback = function()
    -- For Neo-tree (Default in older LazyVim)
    if pcall(require, "neo-tree") then
      require("neo-tree.sources.filesystem.commands").refresh(
        require("neo-tree.sources.manager").get_state("filesystem")
      )
    end

    -- For Snacks Explorer (Default in newer LazyVim versions)
    if pcall(require, "snacks") then
      -- Triggers a Snacks explorer refresh
      Snacks.picker.buffers()
    end
  end,
})
