return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true,
            ignored = false, -- optional: include gitignored files
          },
        },
      },
    },
  },
}
