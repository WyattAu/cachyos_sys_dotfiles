-- Which-key
return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  config = function()
    local wk = require('which-key')
    wk.setup()

    wk.add({
      { '<leader>f', group = 'Find (Telescope)' },
      { '<leader>g', group = 'Git' },
      { '<leader>l', group = 'LSP' },
      { '<leader>d', group = 'Debug' },
      { '<leader>c', group = 'Code' },
    })
  end,
}
