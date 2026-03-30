-- Basic Settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.completeopt = 'menuone,noselect'
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.wrap = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.cursorline = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'

-- Leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Basic keymaps
vim.keymap.set('n', '<leader>w', '<cmd>write<cr>', { desc = 'Save' })
vim.keymap.set('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Quit' })
vim.keymap.set('n', '<leader>e', '<cmd>Explore<cr>', { desc = 'Explore' })
vim.keymap.set('n', '<esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })

-- Window navigation
vim.keymap.set('n', '<c-h>', '<c-w>h', { desc = 'Go to left window' })
vim.keymap.set('n', '<c-j>', '<c-w>j', { desc = 'Go to lower window' })
vim.keymap.set('n', '<c-k>', '<c-w>k', { desc = 'Go to upper window' })
vim.keymap.set('n', '<c-l>', '<c-w>l', { desc = 'Go to right window' })

-- Resize windows
vim.keymap.set('n', '<c-up>', '<cmd>resize +2<cr>', { desc = 'Increase window height' })
vim.keymap.set('n', '<c-down>', '<cmd>resize -2<cr>', { desc = 'Decrease window height' })
vim.keymap.set('n', '<c-left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width' })
vim.keymap.set('n', '<c-right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width' })

-- Buffer navigation
vim.keymap.set('n', '<s-h>', '<cmd>bprevious<cr>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<s-l>', '<cmd>bnext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Delete buffer' })

-- Move text up and down
vim.keymap.set('v', 'J', ":m '>+1<cr>gv=gv", { desc = 'Move text down' })
vim.keymap.set('v', 'K', ":m '<-2<cr>gv=gv", { desc = 'Move text up' })

-- Better paste
vim.keymap.set('v', 'p', '"_dP', { desc = 'Paste without yanking' })

-- Stay in indent mode
vim.keymap.set('v', '<', '<gv', { desc = 'Indent left' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right' })

-- Plugin manager (lazy.nvim) bootstrap
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specifications
require('lazy').setup({
  -- Colorscheme
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end,
  },

  -- Git signs
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end,
  },

  -- Autopairs
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup({})
    end,
  },

  -- Comment
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end,
  },

  -- Which-key
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    config = function()
      require('which-key').setup()
    end,
  },

  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'lua', 'vim', 'vimdoc', 'python', 'javascript', 'typescript', 'rust', 'c', 'cpp', 'go', 'json', 'yaml', 'toml', 'markdown', 'bash', 'fish' },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Telescope
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })
    end,
  },
}, {})
