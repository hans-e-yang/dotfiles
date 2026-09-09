return { 'windwp/nvim-autopairs',
  event = "InsertEnter",
  config = true,
  init = function()
    local Rule = require('nvim-autopairs.rule')
    local npairs = require('nvim-autopairs')

    -- For erb
    npairs.add_rule(Rule("<%", "%>", "eruby"))
    -- Autopairs dont work in eruby, so manually do it here
    -- vim.keymap.set('i', '<CR>', function()
    --   local _, c = unpack(vim.api.nvim_win_get_cursor(0))
    --   local line = vim.api.nvim_get_current_line()
    --   local open = line:sub(c, c)
    --   local close = line:sub(c+1, c+1)
    --   if (open == '>' and close == '<' and vim.bo.filetype == "eruby") then
    --     return "<CR><Tab><CR><Esc>kA"
    --   else
    --     return "<CR>"
    --   end
    --
    -- end, {silent = true, expr = true})
  end
  -- use opts = {} for passing setup options
  -- this is equalent to setup({}) function
}


-- return {
--   'altermo/ultimate-autopair.nvim',
--   event= {"InsertEnter", "CmdlineEnter"},
--   branch="v0.6",
--   opts={
--   }
-- }
--
