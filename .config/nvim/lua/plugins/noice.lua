return {
  "folke/noice.nvim",
  opts = function(_, opts)
    opts.lsp.signature = { enabled = false }
    opts.lsp.hover = { enabled = false }
    opts.presets.bottom_search = false
    opts.presets.lsp_doc_border = true
    table.insert(opts.routes, 1, {
      filter = {
        any = {
          { event = { "notify", "msg_show" }, find = "No information available" },
          { event = "msg_show", kind = "progress", find = "written" },
        },
      },
      opts = { skip = true },
    })
  end,
}
