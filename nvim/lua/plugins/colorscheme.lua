return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000, -- Loads this first
    opts = {
      style = "night", -- Choose from "storm", "moon", "night", "day"
      transparent = true,
      terminal_colors = true,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
