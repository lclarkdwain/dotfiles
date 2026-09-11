return {
  {
    "saghen/blink.cmp",
    dependencies = { "moyiz/blink-emoji.nvim" },
    opts = {
      keymap = {
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
      sources = {
        default = { "emoji" },
        providers = {
          emoji = { module = "blink-emoji", name = "Emoji", score_offset = 15 },
        },
      },
    },
  },
}
