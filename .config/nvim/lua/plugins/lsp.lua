return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        enabled = true,
        exclude = { "vue" }, -- filetypes for which you don't want to enable inlay hints
      },
      servers = {
        tailwindcss = {
          -- nvim-lspconfig turns this on; without inotifywait nvim then walks every
          -- directory under the repo root on the main thread, freezing on big trees.
          capabilities = {
            workspace = { didChangeWatchedFiles = { dynamicRegistration = false } },
          },
        },
      },
    },
  },
}
