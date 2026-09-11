return {
  {
    "folke/lazydev.nvim",
    dependencies = { "DrKJeff16/wezterm-types" },
    opts = function(_, opts)
      table.insert(opts.library, { path = "wezterm-types", mods = { "wezterm" } })
    end,
  },
  { "DrKJeff16/wezterm-types", lazy = true },
}
