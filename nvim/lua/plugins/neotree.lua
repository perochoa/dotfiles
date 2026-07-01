return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    sync_root_with_cwd = true, -- Syncs Neovim's PWD to the Neo-tree root
    respect_buf_cwd = true, -- Follows the CWD of the current buffer
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
