local ADDON, L = ...

local defaults = {
  debug = false,
}

local function fillMissing(target, template)
  for k, v in pairs(template) do
    if type(v) == "table" then
      if type(target[k]) ~= "table" then target[k] = {} end
      fillMissing(target[k], v)
    elseif target[k] == nil then
      target[k] = v
    end
  end
end

function L.Say(fmt, ...)
  print(("|cff33ff99LFGForever|r: " .. fmt):format(...))
end

function L.Debug(fmt, ...)
  if L.db and L.db.debug then L.Say("|cff999999" .. fmt .. "|r", ...) end
end

-- Wraps a handler that runs on every row refresh. The first error goes to the normal error
-- handler (BugSack etc.) with its stack, then the feature switches off for the session
-- rather than erroring again on every row.
function L.Guard(feature, fn)
  local broken = false
  local function onError(err)
    broken = true
    geterrorhandler()(err)
    L.Say("%s turned off after an error; /reload to retry.", feature)
  end
  return function(...)
    if broken then return end
    local n, args = select("#", ...), { ... }
    xpcall(function() fn(unpack(args, 1, n)) end, onError)
  end
end

L.FIT_COLOR = {
  fits = { r = 1, g = 1, b = 1 },
  low  = { r = 0.5, g = 0.5, b = 0.5 },
  high = { r = 1, g = 0.4, b = 0.3 },
}

-- Colour for an activity's suggested level range relative to the player; 0 means unbounded.
function L.LevelFitColor(lo, hi)
  local level = UnitLevel("player")
  if lo and lo > 0 and level < lo then return L.FIT_COLOR.high end
  if hi and hi > 0 and level > hi then return L.FIT_COLOR.low end
  return L.FIT_COLOR.fits
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" then
    if name == ADDON then
      LFGForeverDB = LFGForeverDB or {}
      fillMissing(LFGForeverDB, defaults)
      L.db = LFGForeverDB
    end
    if L.db then L.Skin.TryApply() end
  elseif event == "PLAYER_LOGIN" then
    L.Skin.TryApply()
  end
end)
