return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    sync_root_with_cwd = true, -- Syncs Neovim's PWD to the Neo-tree root
    respect_buf_cwd = true, -- Follows the CWD of the current buffer
    event_handlers = {
      {
        event = "file_opened",
        handler = function()
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if
              vim.api.nvim_buf_is_valid(bufnr)
              and vim.bo[bufnr].buflisted
              and vim.api.nvim_buf_get_name(bufnr) == ""
              and not vim.bo[bufnr].modified
              and #vim.fn.win_findbuf(bufnr) == 0
            then
              vim.api.nvim_buf_delete(bufnr, { force = false })
            end
          end
        end,
      },
    },
    -- Show symlink targets in the file tree so linked folders are obvious
    default_component_configs = {
      symlink_target = { enabled = true },
    },
    filesystem = {
      bind_to_cwd = true, -- Changes explorer root when you :cd
      window = {
        mappings = {
          -- Rebind "." to explicitly change the global CWD
          ["."] = "set_root",
        },
      },
    },
  },
}
