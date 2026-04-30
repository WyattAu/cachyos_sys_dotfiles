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

-- LSP-friendly settings
vim.opt.formatexpr = 'v:lua.vim.lsp.formatexpr(#{timeout_ms = 3000})'
vim.opt.omnifunc = 'v:lua.vim.lsp.omnifunc'

-- Keymaps
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

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>ld', vim.diagnostic.setloclist, { desc = 'Diagnostics to loclist' })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
vim.keymap.set('n', '<leader>lf', vim.diagnostic.open_float, { desc = 'Float diagnostic' })
