-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

local function explorer_cwd()
  local explorers = Snacks.picker.get({ source = "explorer" })
  local explorer = explorers[1]
  return explorer and explorer:cwd() or LazyVim.root()
end

map("n", "<leader>w", "<cmd>w<cr>", { desc = "Write Buffer" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })
map({ "n", "t" }, "<C-/>", function()
  Snacks.terminal.focus(nil, { cwd = explorer_cwd() })
end, { desc = "Terminal (Explorer Dir)" })
map("n", "<leader>rn", [[:%s/\<<C-r><C-w>\>//gI<Left><Left><Left>]], { desc = "Rename Word in Buffer" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move Selection Down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move Selection Up" })
