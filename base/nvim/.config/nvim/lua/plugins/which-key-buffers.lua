local function expand_buf()
  local current = vim.api.nvim_get_current_buf()
  local ret = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.bo[buf].buflisted then
      local name = vim.api.nvim_buf_get_name(buf)
      name = name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":~:.")
      ret[#ret + 1] = {
        "",
        function()
          vim.api.nvim_set_current_buf(buf)
        end,
        desc = name,
        icon = { cat = "file", name = name },
      }
    end
  end

  ret = vim.list_slice(ret, 1, 10)
  for i, v in ipairs(ret) do
    -- 1,2,...,9,0 to match the keyboard row instead of 0-indexing
    v[1] = tostring(i % 10)
  end
  return ret
end

return {
  "folke/which-key.nvim",
  opts = {
    spec = {
      {
        "<leader>b",
        group = "buffer",
        expand = expand_buf,
      },
    },
  },
}
