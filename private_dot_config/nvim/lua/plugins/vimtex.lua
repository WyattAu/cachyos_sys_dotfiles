-- VimTeX - LaTeX integration for Neovim
return {
  "lervag/vimtex",
  ft = { "tex", "bib" },
  config = function()
    -- Viewer
    vim.g.vimtex_view_method = "zathura"
    vim.g.vimtex_view_general_viewer = "zathura"

    -- Compiler
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_compiler_latexmk = {
      build_dir = "build",
      options = {
        "-shell-escape",
        "-file-line-error",
        "-synctex=1",
        "-interaction=nonstopmode",
      },
    }

    -- Quickfix
    vim.g.vimtex_quickfix_mode = 0
    vim.g.vimtex_quickfix_autoclose_after_keystrokes = 3

    -- Format
    vim.g.vimtex_formatmode = 0

    -- Syntax concealment
    vim.g.vimtex_syntax_conceal = {
      accents = 1,
     ligatures = 1,
     citations = 1,
     fancy = 1,
     math = 1,
     sections = 0,
     greek = 1,
     maths = 1,
    }

    -- Keymaps
    vim.keymap.set("n", "<leader>lc", vimtex#compiler.compile, { desc = "LaTeX Compile" })
    vim.keymap.set("n", "<leader>lv", vimtex#view, { desc = "LaTeX View" })
    vim.keymap.set("n", "<leader>ls", vimtex#toc.show, { desc = "LaTeX TOC" })
    vim.keymap.set("n", "<leader>le", vimtex#errors, { desc = "LaTeX Errors" })
  end,
}
