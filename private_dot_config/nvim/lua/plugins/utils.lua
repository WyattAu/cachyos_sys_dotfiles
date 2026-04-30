-- Extra utilities for LSP/completion
return {
  -- lspkind for completion menu icons
  {
    'onsails/lspkind.nvim',
    lazy = true,
  },

  -- JSON schema store (used by jsonls)
  {
    'b0o/schemastore.nvim',
    lazy = true,
  },

  -- Statusline LSP integration
  {
    'nvim-lua/lsp-status.nvim',
    lazy = true,
  },

  --Trouble.nvim for diagnostics quickfix
  {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = { 'Trouble', 'TroubleToggle' },
    opts = {
      use_diagnostic_signs = true,
      auto_open = false,
    },
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer diagnostics' },
      { '<leader>xl', '<cmd>Trouble loclist toggle<cr>', desc = 'Location list' },
      { '<leader>xq', '<cmd>Trouble quickfix toggle<cr>', desc = 'Quickfix list' },
    },
  },
}
