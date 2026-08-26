-- Add nvim-web-devicons for richer file/folder icons used by UI plugins.
-- Loaded eagerly so icons are available to UI plugins early.
return {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    config = function()
      -- Use the builtin defaults; override as desired for custom file names
      local ok, webicons = pcall(require, "nvim-web-devicons")
      if not ok then
        return
      end
      webicons.setup({
        -- override = { -- example overrides
        --   Dockerfile = { icon = "", color = "#0db7ed", name = "Dockerfile" },
        -- },
        default = true,
      })
    end,
  },
}
