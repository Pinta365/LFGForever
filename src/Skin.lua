local _, L = ...

L.Skin = { list = {} }
local Skin = L.Skin

function Skin.Register(key, frameName, apply)
  Skin.list[#Skin.list + 1] = { key = key, frameName = frameName, apply = apply }
end

function Skin.TryApply()
  if not L.db then return end
  for _, skin in ipairs(Skin.list) do
    if not skin.done then
      local frame = _G[skin.frameName]
      if frame then
        skin.done = true
        skin.apply(frame)
        L.Debug("applied %s to %s", skin.key, skin.frameName)
      end
    end
  end
end
