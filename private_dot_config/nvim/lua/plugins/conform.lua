-- Conform.nvim (async formatting)
return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format({ async = true, lsp_fallback = true })
      end,
      mode = '',
      desc = 'Format buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- Disable with a global or buffer-local variable
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return false
      end
      return { timeout_ms = 1000, lsp_fallback = true }
    end,
    formatters_by_ft = {
      c = { 'clang_format' },
      cpp = { 'clang_format' },
      lua = { 'stylua' },
      python = { 'ruff_format', 'ruff_fix' },
      go = { 'goimports', 'gofmt' },
      rust = { 'rustfmt' },
      javascript = { 'prettierd', 'prettier' },
      typescript = { 'prettierd', 'prettier' },
      json = { 'prettierd', 'prettier' },
      yaml = { 'prettierd', 'prettier' },
      markdown = { 'prettierd', 'prettier' },
      toml = { 'taplo' },
      bash = { 'shfmt' },
      fish = { 'fish_indent' },
      proto = { 'buf' },
      cmake = { 'cmake_format' },
      make = { 'checkmake' },
      sql = { 'sqlfmt' },
    },
    formatters = {
      shfmt = {
        prepend_args = { '-i', '2', '-ci' },
      },
    },
  },
}
