local _, L = ...

local MAX_SLOTS = 10
local SLOT_SIZE_LARGE = 22
local SLOT_SIZE_SMALL = 18
local SLOT_GAP = 2

local ROLE_MICRO = {
  TANK    = "groupfinder-icon-role-micro-tank",
  HEALER  = "groupfinder-icon-role-micro-heal",
  DAMAGER = "groupfinder-icon-role-micro-dps",
}
local ROLE_LARGE = {
  TANK    = "groupfinder-icon-role-large-tank",
  HEALER  = "groupfinder-icon-role-large-heal",
  DAMAGER = "groupfinder-icon-role-large-dps",
}
local ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }
local PLAYER_ROLE_KEY = { TANK = "tank", HEALER = "healer", DAMAGER = "dps" }
local DEFAULT_GROUP_SIZE = 5
local DIM = { r = 0.3, g = 0.3, b = 0.3 }

local ACTIVITY_MATCH
local ACTIVITY_OTHER = "|cff808080"
local ACTIVITY_SEP   = "|cff808080, |r"

-- C_LFGList member info can come back as secret values during chat messaging lockdown;
-- anything secret is treated as missing rather than compared or concatenated.
local isSecret = issecretvalue or function() return false end

local function anySecret(t, ...)
  for i = 1, select("#", ...) do
    if isSecret(t[select(i, ...)]) then return true end
  end
  return false
end

local function colorCode(c)
  return ("|cff%02x%02x%02x"):format(c.r * 255, c.g * 255, c.b * 255)
end

local function memberInfo(resultID, index)
  local info = C_LFGList.GetSearchResultPlayerInfo(resultID, index)
  if type(info) ~= "table" then return nil end
  if anySecret(info, "name", "level", "classFilename", "className", "assignedRole", "isLeader",
      "areaName", "lfgRoles") then return nil end
  if type(info.lfgRoles) == "table" and anySecret(info.lfgRoles, "tank", "healer", "dps") then return nil end
  if not info.classFilename then return nil end
  return info
end

local function classColor(classFilename)
  return classFilename and RAID_CLASS_COLORS[classFilename] or NORMAL_FONT_COLOR
end

-- Grows up and to the left so it stays clear of Blizzard's result tooltip on the right.
local function ownTooltip(slot)
  GameTooltip:SetOwner(slot, "ANCHOR_NONE")
  GameTooltip:SetPoint("BOTTOMRIGHT", slot, "TOPRIGHT", 0, 4)
end

local function slotOnEnter(slot)
  if slot.openRole then
    ownTooltip(slot)
    GameTooltip:AddLine("Open spot for your role", 0.3, 0.95, 0.4)
    GameTooltip:AddLine(_G[slot.openRole] or slot.openRole, 1, 1, 1)
    GameTooltip:Show()
    return
  end
  local info = slot.info
  if not info then return end
  ownTooltip(slot)
  local c = classColor(info.classFilename)
  GameTooltip:AddLine(info.name or UNKNOWN, c.r, c.g, c.b)
  GameTooltip:AddLine(("%s %s %s"):format(LEVEL_ABBR, info.level or "?", info.className or ""), 1, 1, 1)
  if info.areaName and info.areaName ~= "" then
    GameTooltip:AddLine(info.areaName, 0.6, 0.6, 0.6)
  end
  GameTooltip:Show()
end

local function slotOnLeave()
  GameTooltip:Hide()
end

local function createSlot(parent)
  local slot = CreateFrame("Frame", nil, parent)

  slot.Class = slot:CreateTexture(nil, "ARTWORK")
  slot.Class:SetAllPoints()

  slot.Role = slot:CreateTexture(nil, "OVERLAY")
  slot.Role:SetPoint("BOTTOMRIGHT", 4, -4)

  slot.Pulse = slot:CreateAnimationGroup()
  slot.Pulse:SetLooping("BOUNCE")
  local fade = slot.Pulse:CreateAnimation("Alpha")
  fade:SetFromAlpha(1)
  fade:SetToAlpha(0.35)
  fade:SetDuration(0.9)
  fade:SetSmoothing("IN_OUT")

  -- Pass clicks and hover through so the row keeps its selection and big tooltip.
  if slot.SetPropagateMouseClicks and slot.SetPropagateMouseMotion then
    slot:EnableMouse(true)
    slot:SetPropagateMouseClicks(true)
    slot:SetPropagateMouseMotion(true)
    slot:SetScript("OnEnter", slotOnEnter)
    slot:SetScript("OnLeave", slotOnLeave)
  end
  return slot
end

local function fillSlot(slot, info, size, roleAtlas, disabled)
  slot:SetSize(size, size)
  slot.Role:SetSize(size * 0.6, size * 0.6)
  slot.info = info
  slot.openRole = nil
  slot.Pulse:Stop()
  slot.Class:SetAtlas("groupfinder-icon-class-" .. info.classFilename:lower(), false)
  if roleAtlas then slot.Role:SetAtlas(roleAtlas, false); slot.Role:Show() else slot.Role:Hide() end
  slot.Class:SetDesaturated(disabled)
  slot.Role:SetDesaturated(disabled)
  slot:SetAlpha(disabled and 0.5 or 1)
  slot:Show()
end

local function getExtras(row)
  if row.LFGF then return row.LFGF end
  local x = {}
  x.Strip = CreateFrame("Frame", nil, row)
  x.Strip:SetSize(1, 1)
  x.Strip:SetFrameLevel(row:GetFrameLevel() + 5)
  x.slots = {}
  for i = 1, MAX_SLOTS do
    local slot = createSlot(x.Strip)
    if i == 1 then
      slot:SetPoint("LEFT", x.Strip, "LEFT", 0, 0)
    else
      slot:SetPoint("LEFT", x.slots[i - 1], "RIGHT", SLOT_GAP, 0)
    end
    x.slots[i] = slot
  end
  x.More = x.Strip:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  x.Range = x.Strip:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  x.Range:SetPoint("RIGHT", x.Strip, "LEFT", -6, 0)
  x.Roles = {}
  for i = 1, 3 do
    local tex = x.Strip:CreateTexture(nil, "ARTWORK")
    tex:SetSize(18, 18)
    tex:SetPoint("RIGHT", i == 1 and x.Strip or x.Roles[i - 1], "LEFT", i == 1 and -3 or -1, 0)
    x.Roles[i] = tex
  end
  x.Accent = row:CreateTexture(nil, "ARTWORK")
  x.Accent:SetColorTexture(0.3, 0.95, 0.4, 0.85)
  x.Accent:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -4)
  x.Accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4, 2)
  x.Accent:SetWidth(3)
  x.Accent:Hide()
  row.LFGF = x
  return x
end

local function showComment(row, result, disabled, canReplaceSolo)
  local display = row.DataDisplay
  if display.Comment:IsShown() then return true end
  local replaceSolo = canReplaceSolo and display.Solo:IsShown()
  if not (display.PlayerCount:IsShown() or replaceSolo) then return false end
  display.PlayerCount:Hide()
  if replaceSolo then display.Solo:Hide() end
  local comment = result.comment
  if not comment or comment == "" then return false end
  LFGBrowseGroupDataDisplayComment_Update(display.Comment, comment, disabled)
  display.Comment:Show()
  return true
end

local function levelDistance(info, level)
  local lo, hi = info.minLevelSuggestion or 0, info.maxLevelSuggestion or 0
  if lo == 0 and hi == 0 then return 0 end
  if level < lo then return lo - level end
  if hi > 0 and level > hi then return level - hi end
  return 0
end

local function updateActivities(row, result, x)
  if result.hasSelf then return end
  local r = row.ActivityName:GetTextColor()
  if r and r < 0.35 then return end  -- delisted or filtered out: keep Blizzard's dimmed text

  local active = C_LFGList.GetActiveEntryInfo()
  if active and isSecret(active.activityIDs) then active = nil end
  local level = UnitLevel("player")
  local list = {}
  for _, id in ipairs(result.activityIDs) do
    local info = C_LFGList.GetActivityInfoTable(id)
    local name = info and LFGUtil_GetActivityInfoName(info)
    if name and name ~= "" then
      list[#list + 1] = {
        name = name, info = info,
        match = active and tContains(active.activityIDs, id) or false,
        distance = levelDistance(info, level),
      }
    end
  end
  if #list == 0 then return end
  -- Blizzard narrows the display to activities matching your own listing when there are any.
  local anyMatch = false
  for _, a in ipairs(list) do anyMatch = anyMatch or a.match end
  if anyMatch then
    local only = {}
    for _, a in ipairs(list) do if a.match then only[#only + 1] = a end end
    list = only
  end
  table.sort(list, function(a, b)
    if a.distance ~= b.distance then return a.distance < b.distance end
    return (a.info.orderIndex or 0) < (b.info.orderIndex or 0)
  end)

  local function code(a)
    if a.match then return ACTIVITY_MATCH end
    return colorCode(L.LevelFitColor(a.info.minLevelSuggestion, a.info.maxLevelSuggestion))
  end

  local text = row.ActivityName
  text:SetWidth(0)
  if #list == 1 then
    local a = list[1]
    local lo, hi = a.info.minLevelSuggestion or 0, a.info.maxLevelSuggestion or 0
    local range = (lo > 0 and hi > 0) and (" %s(%d-%d)|r"):format(ACTIVITY_OTHER, lo, hi) or ""
    text:SetText(code(a) .. a.name .. "|r" .. range)
    return
  end

  local left = text:GetLeft()
  local display = row.DataDisplay
  local limit = (display and display.Comment:IsShown() and display:GetLeft())
    or (x.Range:IsShown() and x.Range:GetLeft())
    or (x.Strip:IsShown() and x.Strip:GetLeft()) or row:GetRight()
  local maxWidth = (left and limit) and (limit - left - 8) or 150

  for shown = #list, 1, -1 do
    local parts = {}
    for i = 1, shown do parts[i] = code(list[i]) .. list[i].name .. "|r" end
    local str = table.concat(parts, ACTIVITY_SEP)
    if shown < #list then str = str .. (" %s+%d|r"):format(ACTIVITY_OTHER, #list - shown) end
    text:SetText(str)
    if shown == 1 or text:GetStringWidth() <= maxWidth then break end
  end
end

-- Dungeon-style activities track remaining slots per role; for everything else a role is
-- open while nobody in the group has it and the group isn't full.
local function openRolesForPlayer(row, result, maxPlayers)
  local open = {}
  if result.hasSelf or result.isDelisted then return open end
  local mine = C_LFGListRoles and C_LFGListRoles.GetRoles()
  local counts = C_LFGList.GetSearchResultMemberCounts(row.resultID)
  if not mine or not counts then return open end

  local dungeonRoles = false
  for _, id in ipairs(result.activityIDs) do
    local info = C_LFGList.GetActivityInfoTable(id)
    if info and info.useDungeonRoleExpectations then dungeonRoles = true break end
  end
  local cap = (maxPlayers and maxPlayers > 0) and maxPlayers or DEFAULT_GROUP_SIZE
  local free = cap - (result.numMembers or 0)
  if free <= 0 then return open end

  for _, role in ipairs(ROLE_ORDER) do
    if mine[PLAYER_ROLE_KEY[role]] then
      local hasRoom
      if dungeonRoles then
        hasRoom = (counts[role .. "_REMAINING"] or 0) > 0
      else
        hasRoom = (counts[role] or 0) == 0
      end
      if hasRoom and #open < free then open[#open + 1] = role end
    end
  end
  return open
end

local function updateGroup(row, result, x, disabled, hasComment)
  local numMembers = result.numMembers or 0
  local members, minLevel, maxLevel = {}, nil, nil
  for i = 1, math.min(numMembers, 40) do
    local info = memberInfo(row.resultID, i)
    if info then
      if info.isLeader then table.insert(members, 1, info) else members[#members + 1] = info end
      if info.level then
        minLevel = math.min(minLevel or info.level, info.level)
        maxLevel = math.max(maxLevel or info.level, info.level)
      end
    end
  end

  local display = row.DataDisplay
  local middleEmpty = not hasComment and display and not (display.RoleCount:IsShown() or display.Enumerate:IsShown())
  local size = middleEmpty and SLOT_SIZE_LARGE or SLOT_SIZE_SMALL
  x.Strip:ClearAllPoints()
  if middleEmpty then
    x.Strip:SetPoint("RIGHT", row, "RIGHT", -14, 0)
  else
    x.Strip:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -10, 5)
  end
  x.Strip:SetHeight(size)
  for _, tex in ipairs(x.Roles) do tex:Hide() end

  local _, maxPlayers = LFGBrowseUtil_GetBestDisplayTypeForActivityIDs(result.activityIDs)
  local openRoles = openRolesForPlayer(row, result, maxPlayers)
  local slotsWanted = math.max(#members, (maxPlayers and maxPlayers <= MAX_SLOTS) and maxPlayers or 0)
  slotsWanted = math.max(slotsWanted, #members + #openRoles)
  local shown = math.min(slotsWanted, MAX_SLOTS)
  local overflow = #members - MAX_SLOTS

  for i, slot in ipairs(x.slots) do
    local info = members[i]
    slot:SetSize(size, size)
    slot.Role:SetSize(size * 0.6, size * 0.6)
    if i > shown or (overflow > 0 and i == MAX_SLOTS) then
      slot.openRole = nil
      slot.Pulse:Stop()
      slot:Hide()
    elseif info then
      fillSlot(slot, info, size, ROLE_MICRO[info.assignedRole], disabled)
    else
      slot.info = nil
      slot.Class:SetDesaturated(false)
      slot.Role:Hide()
      local openRole = openRoles[i - #members]
      if openRole then
        slot.openRole = openRole
        slot.Class:SetAtlas(ROLE_LARGE[openRole], false)
        slot:SetAlpha(1)
        slot.Pulse:Play()
      else
        slot.openRole = nil
        slot.Pulse:Stop()
        slot.Class:SetAtlas("groupfinder-icon-emptyslot", false)
        slot:SetAlpha(disabled and 0.3 or 0.6)
      end
      slot:Show()
    end
  end

  local visible = math.min(shown, overflow > 0 and MAX_SLOTS - 1 or MAX_SLOTS)
  local width = math.max(1, visible * size + math.max(0, visible - 1) * SLOT_GAP)
  if overflow > 0 then
    x.More:ClearAllPoints()
    x.More:SetPoint("LEFT", x.slots[visible], "RIGHT", SLOT_GAP + 1, 0)
    x.More:SetText("+" .. (#members - visible))
    x.More:Show()
    width = width + SLOT_GAP + x.More:GetStringWidth() + 2
  else
    x.More:Hide()
  end
  x.Strip:SetWidth(width)

  if minLevel and minLevel ~= maxLevel then
    x.Range:SetText(("%s %d-%d"):format(LEVEL_ABBR, minLevel, maxLevel))
    x.Range:Show()
  else
    x.Range:Hide()
  end
  x.Strip:Show()
  x.Accent:SetShown(#openRoles > 0)

  local leader = members[1]
  if leader and leader.isLeader and leader.level then
    row.Level:SetText(LEVEL_ABBR .. " " .. leader.level)
    row.Level:Show()
    row.NewPlayerFriendlyIcon:SetPoint("LEFT", row.Level, "RIGHT", 2, 0)
  end
end

local function updateSolo(row, x, disabled, info)
  x.Strip:Hide()
  x.Accent:Hide()
  if not info then return end

  if info.level and info.className then
    local c = disabled and DIM or classColor(info.classFilename)
    row.Level:SetText(("%s %d |cff%02x%02x%02x%s|r"):format(LEVEL_ABBR, info.level,
      c.r * 255, c.g * 255, c.b * 255, info.className))
  end

  local roles = info.lfgRoles
  local listed = {}
  if roles then
    if roles.dps then listed[#listed + 1] = ROLE_LARGE.DAMAGER end
    if roles.healer then listed[#listed + 1] = ROLE_LARGE.HEALER end
    if roles.tank then listed[#listed + 1] = ROLE_LARGE.TANK end
  end
  for i, tex in ipairs(x.Roles) do
    if listed[i] then
      tex:SetAtlas(listed[i], false)
      tex:SetDesaturated(disabled)
      tex:SetAlpha(disabled and 0.5 or 1)
      tex:Show()
    else
      tex:Hide()
    end
  end

  row.ClassIcon:Hide()
  row.NewPlayerFriendlyIcon:SetPoint("LEFT", row.Level, "RIGHT", 2, 0)
  for i = 2, MAX_SLOTS do x.slots[i]:Hide() end
  x.More:Hide()
  x.Range:Hide()
  fillSlot(x.slots[1], info, SLOT_SIZE_SMALL, nil, disabled)
  x.Strip:ClearAllPoints()
  x.Strip:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -10, 5)
  x.Strip:SetSize(SLOT_SIZE_SMALL, SLOT_SIZE_SMALL)
  x.Strip:Show()
end

local function hasExpectedLayout(row)
  local display = row.DataDisplay
  return row.Level and row.ActivityName and row.ClassIcon and row.NewPlayerFriendlyIcon
    and display and display.Comment and display.PlayerCount and display.Solo
    and display.RoleCount and display.Enumerate
end

local function onEntryUpdate(row)
  if not row.resultID or not hasExpectedLayout(row) then return end
  local result = C_LFGList.GetSearchResultInfo(row.resultID)
  local x = getExtras(row)
  if not result or not row:IsShown()
      or anySecret(result, "numMembers", "isDelisted", "hasSelf", "comment", "activityIDs") then
    x.Strip:Hide()
    x.Accent:Hide()
    return
  end
  local disabled = result.isDelisted
  local isGroup = (result.numMembers or 0) > 1
  local soloInfo = not isGroup and memberInfo(row.resultID, 1) or nil
  local hasComment = showComment(row, result, disabled, isGroup or soloInfo ~= nil)
  if isGroup then
    updateGroup(row, result, x, disabled, hasComment)
  else
    updateSolo(row, x, disabled, soloInfo)
  end
  updateActivities(row, result, x)
end

ACTIVITY_MATCH = colorCode(BRIGHTBLUE_FONT_COLOR)

L.Skin.Register("browseRows", "LFGBrowseFrame", function(frame)
  if type(LFGBrowseSearchEntry_Update) ~= "function" then return end
  local update = L.Guard("Browse list enhancements", onEntryUpdate)
  hooksecurefunc("LFGBrowseSearchEntry_Update", update)

  local roleWatcher = CreateFrame("Frame")
  roleWatcher:RegisterEvent("LFG_LIST_ROLE_UPDATE")
  roleWatcher:SetScript("OnEvent", function()
    if not frame:IsShown() then return end
    frame.ScrollBox:ForEachFrame(function(row)
      if row.resultID then update(row) end
    end)
  end)
end)
