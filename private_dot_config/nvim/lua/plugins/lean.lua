-- lean.nvim (Lean 4 LSP integration)
return {
  'Julian/lean.nvim',
  ft = 'lean',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'neovim/nvim-lspconfig',
  },
  opts = {
    lsp = {
      -- lean.nvim manages its own LSP, let it
      on_attach = function(_client, bufnr)
        -- Lean-specific keymaps
        vim.keymap.set('n', '<leader>lt', '<cmd>LeanInfoViewToggle<cr>', { buffer = bufnr, desc = 'Toggle info view' })
        vim.keymap.set('n', '<leader>lp', '<cmd>LeanInfoViewPin<cr>', { buffer = bufnr, desc = 'Pin info view' })
        vim.keymap.set('n', '<leader>le', '<cmd>LeanGoalToggle<cr>', { buffer = bufnr, desc = 'Toggle goal' })
      end,
    },
    lean3 = { enabled = false },
    infoview = {
      autoopen = true,
      width = 50,
      horizontal_position = 'bottom',
    },
  },
}
