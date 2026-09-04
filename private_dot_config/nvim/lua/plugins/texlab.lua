-- Texlab LSP for LaTeX
return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    opts.servers = opts.servers or {}
    opts.servers.texlab = {
      settings = {
        texlab = {
          build = {
            onSave = true,
            forwardSearchAfterCompile = true,
          },
          forwardSearch = {
            executable = "zathura",
            args = { "--synctex-forward", "%l:1:%f", "%p" },
          },
          chktex = {
            onOpenAndSave = true,
            onEdit = false,
          },
          latexFormatter = "latexindent",
          latexindent = {
            modifyLineBreaks = false,
          },
        },
      },
    }
  end,
}
