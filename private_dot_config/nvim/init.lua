-- Leader key (must be set before plugins)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Core settings
require('options')
require('autocmds')

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

-- Load plugin specs from lua/plugins/
require('lazy').setup('plugins', {
  change_detection = {
    notify = false,
  },
})
