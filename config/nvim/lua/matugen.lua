 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#010b17',
    base01 = '#1a2b39',
    base02 = '#203647',
    base03 = '#556979',
    base04 = '#708493',
    base05 = '#ebddf4',
    base06 = '#ebddf4',
    base07 = '#ebddf4',
    base08 = '#ff3a3a',
    base09 = '#a277ff',
    base0A = '#1376f8',
    base0B = '#a277ff',
    base0C = '#a880ff',
    base0D = '#a880ff',
    base0E = '#83b7fb',
    base0F = '#b5d4fd',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#ebddf4',          bg = '#010b17' })
  hi('TelescopeBorder',         { fg = '#556979',             bg = '#010b17' })
  hi('TelescopePromptNormal',   { fg = '#ebddf4',          bg = '#010b17' })
  hi('TelescopePromptBorder',   { fg = '#556979',             bg = '#010b17' })
  hi('TelescopePromptPrefix',   { fg = '#a277ff',             bg = '#010b17' })
  hi('TelescopePromptCounter',  { fg = '#708493',  bg = '#010b17' })
  hi('TelescopePromptTitle',    { fg = '#010b17',             bg = '#a277ff' })
  hi('TelescopePreviewTitle',   { fg = '#010b17',             bg = '#1376f8' })
  hi('TelescopeResultsTitle',   { fg = '#010b17',             bg = '#a277ff' })
  hi('TelescopeSelection',      { fg = '#ebddf4',          bg = '#203647' })
  hi('TelescopeSelectionCaret', { fg = '#a277ff',             bg = '#203647' })
  hi('TelescopeMatching',       { fg = '#a277ff',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
