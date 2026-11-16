local _, L = ...

local function help()
  L.Say(L.L.COMMANDS)
  print(L.L.KEY_DEBUG_HELP)
end

SLASH_LFGFOREVER1 = "/lfgf"
SLASH_LFGFOREVER2 = "/lfgforever"
SlashCmdList.LFGFOREVER = function(msg)
  local cmd = msg:match("^(%S*)"):lower()
  if cmd == L.L.KEY_DEBUG then
    L.db.debug = not L.db.debug
    L.Say(L.L.DEBUG_TOGGLE, L.db.debug and L.L.DEBUG_ON or L.L.DEBUG_OFF)
  else
    help()
  end
end
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
