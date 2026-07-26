 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#0f1417',
    base01 = '#1c2024',
    base02 = '#262a2e',
    base03 = '#8b9198',
    base04 = '#c1c7ce',
    base05 = '#dfe3e7',
    base06 = '#dfe3e7',
    base07 = '#dfe3e7',
    base08 = '#ffb4ab',
    base09 = '#ccc1e9',
    base0A = '#b6c9d8',
    base0B = '#92cef5',
    base0C = '#ccc1e9',
    base0D = '#92cef5',
    base0E = '#b6c9d8',
    base0F = '#93000a',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#dfe3e7',          bg = '#0f1417' })
  hi('TelescopeBorder',         { fg = '#8b9198',             bg = '#0f1417' })
  hi('TelescopePromptNormal',   { fg = '#dfe3e7',          bg = '#0f1417' })
  hi('TelescopePromptBorder',   { fg = '#8b9198',             bg = '#0f1417' })
  hi('TelescopePromptPrefix',   { fg = '#92cef5',             bg = '#0f1417' })
  hi('TelescopePromptCounter',  { fg = '#c1c7ce',  bg = '#0f1417' })
  hi('TelescopePromptTitle',    { fg = '#0f1417',             bg = '#92cef5' })
  hi('TelescopePreviewTitle',   { fg = '#0f1417',             bg = '#b6c9d8' })
  hi('TelescopeResultsTitle',   { fg = '#0f1417',             bg = '#ccc1e9' })
  hi('TelescopeSelection',      { fg = '#dfe3e7',          bg = '#262a2e' })
  hi('TelescopeSelectionCaret', { fg = '#92cef5',             bg = '#262a2e' })
  hi('TelescopeMatching',       { fg = '#92cef5',             bold = true })
end

 -- Register a signal handler for SIGUSR1 (matugen updates)
 local signal = vim.uv.new_signal()
 signal:start(
   'sigusr1',
   vim.schedule_wrap(function()
     package.loaded['matugen'] = nil
     require('matugen').setup()
   end)
 )

 return M
