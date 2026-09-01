return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      treesitter = {
        ensure_installed = { "nix" },
      },
    },
  },

--   {
--     "AstroNvim/astrolsp",
--     ---@type AstroLSPOpts
--     opts = {
--       servers = {
--         "nixd",
--       },
-- 
--       config = {
--         nil_ls = {
--           settings = {
--             ["nil"] = {
--               formatting = {
--                 command = { "nixfmt" },
--               },
--             },
--           },
--         },
--       },
--     },
--   },
}
