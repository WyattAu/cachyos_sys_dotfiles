-- LSP Configuration
return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    { 'williamboman/mason.nvim', config = true },
    'williamboman/mason-lspconfig.nvim',
    'hrsh7th/cmp-nvim-lsp',
    { 'j-hui/fidget.nvim', opts = {} },
    'folke/neodev.nvim',
  },
  config = function()
    local lspconfig = require('lspconfig')
    local cmp_nvim_lsp = require('cmp_nvim_lsp')

    -- Extend default capabilities with nvim-cmp
    local capabilities = vim.tbl_deep_extend(
      'force',
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_nvim_lsp.default_capabilities()
    )

    -- LSP keymaps on attach
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end
        map('<leader>la', vim.lsp.buf.code_action, 'Code action')
        map('<leader>lr', vim.lsp.buf.rename, 'Rename')
        map('<leader>lk', vim.lsp.buf.hover, 'Hover docs')
        map('<leader>lK', vim.lsp.buf.signature_help, 'Signature help')
        map('<leader>lt', vim.lsp.buf.type_definition, 'Type definition')
        map('<leader>lD', vim.lsp.buf.declaration, 'Declaration')
        map('gd', vim.lsp.buf.definition, 'Go to definition')
        map('gD', vim.lsp.buf.declaration, 'Go to declaration')
        map('gI', vim.lsp.buf.implementation, 'Go to implementation')
        map('gr', vim.lsp.buf.references, 'Go to references')
        map('gy', vim.lsp.buf.type_definition, 'Go to type definition')
        map('K', vim.lsp.buf.hover, 'Hover documentation')
        map('gK', vim.lsp.buf.signature_help, 'Signature help')
      end,
    })

    -- Diagnostics display
    local sign = function(opts)
      vim.fn.sign_define(opts.name, { texthl = opts.name, text = opts.text, numhl = '' })
    end
    sign({ name = 'DiagnosticSignError', text = 'E' })
    sign({ name = 'DiagnosticSignWarn', text = 'W' })
    sign({ name = 'DiagnosticSignHint', text = 'H' })
    sign({ name = 'DiagnosticSignInfo', text = 'I' })

    vim.diagnostic.config({
      virtual_text = {
        prefix = '●',
        spacing = 4,
      },
      severity_sort = true,
      float = {
        border = 'rounded',
        source = true,
      },
    })

    -- ── Server configurations ──

    -- clangd (C/C++)
    lspconfig.clangd.setup({
      capabilities = capabilities,
      cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--header-insertion=iwyu',
        '--completion-style=detailed',
        '--function-arg-placeholders',
        '--fallback-style=llvm',
      },
      init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
      },
      filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
    })

    -- rust-analyzer
    lspconfig.rust_analyzer.setup({
      capabilities = capabilities,
      settings = {
        ['rust-analyzer'] = {
          cargo = { allFeatures = true },
          checkOnSave = {
            command = 'clippy',
            extraArgs = { '--', '-W', 'clippy::all' },
          },
          procMacro = { enable = true },
          inlayHints = {
            bindingModeHints = { enable = true },
            chainingHints = { enable = true },
            closingBraceHints = { enable = true },
            closureReturnTypeHints = { enable = 'always' },
            lifetimeElisionHints = { enable = 'skip_trivial' },
            parameterHints = { enable = true },
            reborrowHints = { enable = true },
            renderColons = false,
            typeHints = {
              closureReturnTypeHints = { enable = 'always' },
              enable = true,
              hideClosureInitialization = false,
              hideNamedConstructor = false,
            },
          },
        },
      },
    })

    -- Lean 4
    lspconfig.lean4.setup({
      capabilities = capabilities,
      -- lean.nvim handles its own setup, but this is the fallback
    })

    -- Lua (neodev for vim api)
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          completion = { callSnippet = 'Replace' },
          diagnostics = { globals = { 'vim' } },
          workspace = {
            library = {
              { '${3rd}/luv/library', words = { 'uv' } },
              vim.api.nvim_get_runtime_file('', true),
            },
            checkThirdParty = false,
          },
          telemetry = { enable = false },
          format = { enable = false }, -- use conform.nvim for formatting
        },
      },
    })

    -- Python (pyright)
    lspconfig.pyright.setup({
      capabilities = capabilities,
      settings = {
        pyright = {
          autoImportCompletion = true,
          typeCheckingMode = 'basic',
        },
        python = {
          analysis = {
            autoSearchPaths = true,
            diagnosticMode = 'workspace',
            useLibraryCodeForTypes = true,
          },
        },
      },
    })

    -- Go (gopls)
    lspconfig.gopls.setup({
      capabilities = capabilities,
      settings = {
        gopls = {
          analyses = {
            unusedparams = true,
            shadow = true,
          },
          staticcheck = true,
          gofumpt = true,
        },
      },
    })

    -- TOML (taplo)
    lspconfig.taplo.setup({
      capabilities = capabilities,
    })

    -- JSON (vscode-json-language-server)
    local has_schemastore, schemastore = pcall(require, 'schemastore')
    local json_schemas = has_schemastore and schemastore.json.schemas() or {}
    lspconfig.jsonls.setup({
      capabilities = capabilities,
      settings = {
        json = {
          schemas = json_schemas,
          validate = { enable = true },
        },
      },
    })

    -- YAML
    lspconfig.yamlls.setup({
      capabilities = capabilities,
      settings = {
        yaml = {
          keyOrdering = false,
          format = { enable = false },
        },
      },
    })

    -- Bash
    lspconfig.bashls.setup({
      capabilities = capabilities,
    })

    -- Dockerfile
    lspconfig.dockerls.setup({
      capabilities = capabilities,
    })

    -- TypeScript/JavaScript (optional - ts_ls)
    lspconfig.ts_ls.setup({
      capabilities = capabilities,
      init_options = {
        preferences = {
          disableSuggestions = true,
        },
      },
    })
  end,
}
