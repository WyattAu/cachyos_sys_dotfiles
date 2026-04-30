-- Telescope
return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.5',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable('make') == 1
      end,
    },
  },
  config = function()
    local builtin = require('telescope.builtin')
    local actions = require('telescope.actions')

    require('telescope').setup({
      defaults = {
        mappings = {
          i = {
            ['<c-u>'] = false,
            ['<c-d>'] = false,
            ['<c-k>'] = actions.move_selection_previous,
            ['<c-j>'] = actions.move_selection_next,
          },
        },
        file_ignore_patterns = {
          'node_modules',
          '.git/',
          'target/',
          'build/',
        },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
      },
    })

    pcall(require('telescope').load_extension, 'fzf')

    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Buffers' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })
    vim.keymap.set('n', '<leader>fo', builtin.oldfiles, { desc = 'Recent files' })
    vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = 'Word under cursor' })
    vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Diagnostics' })
    vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = 'Resume last picker' })
    -- LSP telescope extensions (lazy-loaded by lspconfig)
    vim.keymap.set('n', '<leader>ls', builtin.lsp_document_symbols, { desc = 'Document symbols' })
    vim.keymap.set('n', '<leader>lS', builtin.lsp_workspace_symbols, { desc = 'Workspace symbols' })
    vim.keymap.set('n', '<leader>lr', builtin.lsp_references, { desc = 'References' })
    vim.keymap.set('n', '<leader>ld', builtin.lsp_definitions, { desc = 'Go to definition' })
    vim.keymap.set('n', '<leader>lt', builtin.lsp_type_definitions, { desc = 'Type definition' })
    vim.keymap.set('n', '<leader>li', builtin.lsp_implementations, { desc = 'Implementations' })
  end,
}
