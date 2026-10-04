local _, L = ...

local function help()
  L.Say("commands:")
  print("  /lfgf debug - toggle debug output")
end

SLASH_LFGFOREVER1 = "/lfgf"
SLASH_LFGFOREVER2 = "/lfgforever"
SlashCmdList.LFGFOREVER = function(msg)
  local cmd = msg:match("^(%S*)"):lower()
  if cmd == "debug" then
    L.db.debug = not L.db.debug
    L.Say("debug %s", L.db.debug and "on" or "off")
  else
    help()
  end
end
