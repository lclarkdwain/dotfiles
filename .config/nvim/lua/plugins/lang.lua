return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    dependencies = { "DrKJeff16/wezterm-types" },
    opts = {
      library = {
        { path = "wezterm-types", mods = { "wezterm" } },
      },
    },
  },
}
