return {
  {
    "sheng-tse/jupynvim",
    build = function(plugin)
      print(plugin.dir)
      local install = loadfile(plugin.dir .. "/lua/jupynvim/install.lua")()
      install.run(plugin)
    end,
    config = function()
      require("jupynvim").setup({
        log_level = "info",
        -- "placeholder" = kitty unicode-placeholder protocol (anchors to text,
        -- required for GIFs; correct under tmux). Needs Ghostty >= 1.3 / kitty.
        image_renderer = "placeholder",
      })
    end,
  },
}
