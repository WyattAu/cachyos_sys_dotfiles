-- Comment
return {
  'numToStr/Comment.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    require('Comment').setup({
      padding = true,
      sticky = true,
      mappings = {
        basic = true,
        extra = true,
        extended = false,
      },
    })
  end,
}
