-- Debug Adapter Protocol (nvim-dap)
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'theHamsta/nvim-dap-virtual-text',
    'nvim-neotest/nvim-nio',
    'jay-babu/mason-nvim-dap.nvim',
  },
  config = function()
    local dap = require('dap')
    local dapui = require('dapui')

    -- DAP UI setup
    dapui.setup({
      layouts = {
        {
          elements = {
            { id = 'scopes', size = 0.25 },
            { id = 'breakpoints', size = 0.25 },
            { id = 'stacks', size = 0.25 },
            { id = 'watches', size = 0.25 },
          },
          size = 40,
          position = 'left',
        },
        {
          elements = {
            { id = 'repl', size = 0.5 },
            { id = 'console', size = 0.5 },
          },
          size = 10,
          position = 'bottom',
        },
      },
    })

    -- Virtual text
    require('nvim-dap-virtual-text').setup({
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
    })

    -- Auto-open/close DAP UI
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- DAP keymaps
    vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Toggle breakpoint' })
    vim.keymap.set('n', '<leader>dB', function()
      dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
    end, { desc = 'Conditional breakpoint' })
    vim.keymap.set('n', '<leader>dc', dap.continue, { desc = 'Continue' })
    vim.keymap.set('n', '<leader>dC', dap.run_to_cursor, { desc = 'Run to cursor' })
    vim.keymap.set('n', '<leader>di', dap.step_into, { desc = 'Step into' })
    vim.keymap.set('n', '<leader>do', dap.step_over, { desc = 'Step over' })
    vim.keymap.set('n', '<leader>dO', dap.step_out, { desc = 'Step out' })
    vim.keymap.set('n', '<leader>dt', dap.terminate, { desc = 'Terminate' })
    vim.keymap.set('n', '<leader>dr', dap.repl.open, { desc = 'Open REPL' })
    vim.keymap.set('n', '<leader>du', dapui.toggle, { desc = 'Toggle DAP UI' })
    vim.keymap.set('n', '<leader>dl', dap.list_breakpoints, { desc = 'List breakpoints' })

    -- ── Adapter configurations ──

    -- C/C++ (gdb or lldb)
    dap.adapters.gdb = {
      type = 'executable',
      command = 'gdb',
      args = { '-i', 'dap' },
    }
    dap.configurations.c = {
      {
        name = 'Launch',
        type = 'gdb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},
      },
    }
    dap.configurations.cpp = dap.configurations.c

    -- Rust (uses gdb adapter, cargo builds first)
    dap.adapters.rust = dap.adapters.gdb
    dap.configurations.rust = {
      {
        name = 'Launch',
        type = 'rust',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},
        runInTerminal = true,
      },
    }

    -- Python
    dap.adapters.python = {
      type = 'executable',
      command = 'python',
      args = { '-m', 'debugpy.adapter' },
    }
    dap.configurations.python = {
      {
        name = 'Launch file',
        type = 'python',
        request = 'launch',
        program = '${file}',
        pythonPath = function()
          return 'python'
        end,
      },
      {
        name = 'Launch with args',
        type = 'python',
        request = 'launch',
        program = '${file}',
        args = function()
          local args_string = vim.fn.input('Arguments: ')
          return vim.split(args_string, ' +')
        end,
        pythonPath = function()
          return 'python'
        end,
      },
    }

    -- Go (delve)
    dap.adapters.delve = {
      type = 'server',
      port = '${port}',
      executable = {
        command = 'dlv',
        args = { 'dap', '-l', '127.0.0.1:${port}' },
      },
    }
    dap.configurations.go = {
      {
        type = 'delve',
        name = 'Debug',
        request = 'launch',
        program = '${file}',
      },
      {
        type = 'delve',
        name = 'Debug test',
        request = 'launch',
        mode = 'test',
        program = '${file}',
      },
    }
  end,
}
