-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd({ "BufLeave" }, {
  pattern = { "*.lazygit*" },
  group = vim.api.nvim_create_augroup("git_refresh_explorer", { clear = true }),
  callback = function()
    if pcall(require, "neo-tree") then
      require("neo-tree.sources.filesystem.commands").refresh(
        require("neo-tree.sources.manager").get_state("filesystem")
      )
    end

    if pcall(require, "snacks") then
      Snacks.picker.buffers()
    end
  end,
})
