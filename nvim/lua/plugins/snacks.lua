local function focus_explorer_directory(picker)
  picker:set_cwd(picker:dir())
  require("snacks.explorer.git").refresh(picker:cwd())
  picker:find()
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            git_status_open = true,
            actions = {
              explorer_focus = focus_explorer_directory,
            },
            win = {
              list = {
                keys = {
                  ["x"] = { "explorer_move", mode = { "n", "x" } },
                  ["d"] = "explorer_del",
                },
              },
            },
            on_close = function(picker)
              vim.g.snacks_explorer_last_cwd = picker:cwd()
            end,
          },
        },
      },
    },
  },
}
