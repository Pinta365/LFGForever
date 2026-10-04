local _, L = ...

local ICON_SIZE = 20
local NAME_INDENT = 34

local function classColor(classFilename)
  return classFilename and RAID_CLASS_COLORS[classFilename]
end

local function getExtras(row)
  if row.LFGF then return row.LFGF end
  local x = {}
  x.Icon = row:CreateTexture(nil, "ARTWORK")
  x.Icon:SetSize(ICON_SIZE, ICON_SIZE)
  x.Icon:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -8)
  row.LFGF = x
  return x
end

local function updateRow(row, info)
  if not (info and row.Name and row.Level) then return end
  local x = getExtras(row)

  local color = classColor(info.filename) or NORMAL_FONT_COLOR
  row.Name:SetTextColor(color.r, color.g, color.b)

  if info.filename then
    x.Icon:SetAtlas("groupfinder-icon-class-" .. info.filename:lower(), false)
    x.Icon:Show()
    row.Name:SetPoint("TOPLEFT", row, "TOPLEFT", NAME_INDENT, -8)
  else
    x.Icon:Hide()
    row.Name:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -8)
  end

  if info.level then
    local levelColor = GetQuestDifficultyColor(info.level)
    row.Level:SetTextColor(levelColor.r, levelColor.g, levelColor.b)
  end
end

L.Skin.Register("whoRows", "LFGWhoListFrame", function(frame)
  if not frame.ScrollBox then return end
  local update = L.Guard("Who list enhancements", updateRow)
  frame.ScrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnInitializedFrame,
    function(_, row, elementData)
      update(row, elementData and elementData.info)
    end, frame)
end)
