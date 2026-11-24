local _, L = ...

local function help()
  L.Say("commands:")
  print("  /lfgf filters - show or hide the filter panel")
  print("  /lfgf reset - reset all filters")
  print("  /lfgf debug - toggle debug output")
end

SLASH_LFGFOREVER1 = "/lfgf"
SLASH_LFGFOREVER2 = "/lfgforever"
SlashCmdList.LFGFOREVER = function(msg)
  local cmd = msg:match("^(%S*)"):lower()
  if cmd == "debug" then
    L.db.debug = not L.db.debug
    L.Say("debug %s", L.db.debug and "on" or "off")
  elseif cmd == "filters" then
    if L.Filters.Panel then L.Filters.TogglePanel() else L.Say("open the group finder first.") end
  elseif cmd == "reset" then
    L.ResetFilters()
    L.Filters.Refresh()
    L.Say("filters reset")
  else
    help()
  end
end
