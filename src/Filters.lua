local _, L = ...

local PANEL_WIDTH = 250
local ROW = 21
local PAD = 12

local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local ROLE_ICON = {
  tank   = "groupfinder-icon-role-large-tank",
  healer = "groupfinder-icon-role-large-heal",
  dps    = "groupfinder-icon-role-large-dps",
}

local Filters = { hidden = 0, total = 0, controls = {} }
L.Filters = Filters

local function db() return L.db.filters end

-- Class and playstyle tables only store the hidden entries, so new values default to shown.
local function setShown(t, key, shown)
  if shown then t[key] = nil else t[key] = false end
end

-------------------------------------------------------------------------------
-- Matching. Anything we can't read (secret values, missing info) is kept, so a
-- filter never hides a listing it couldn't actually judge.
-------------------------------------------------------------------------------

local function playerPasses(f, resultID)
  if not f.players then return false end
  local info = L.MemberInfo(resultID, 1)
  if not info then return true end
  if f.classes[info.classFilename] == false then return false end

  local roles = info.lfgRoles
  if type(roles) == "table" and (roles.tank or roles.healer or roles.dps) then
    local r = f.roles
    if not ((roles.tank and r.tank) or (roles.healer and r.healer) or (roles.dps and r.dps)) then
      return false
    end
  end

  local level = info.level
  if level then
    if f.minLevel > 0 and level < f.minLevel then return false end
    if f.maxLevel > 0 and level > f.maxLevel then return false end
  end
  return true
end

local function groupPasses(f, resultID, result)
  if not f.groups then return false end
  local _, maxPlayers = LFGBrowseUtil_GetBestDisplayTypeForActivityIDs(result.activityIDs)
  if f.hideFull and maxPlayers and maxPlayers > 0 and result.numMembers >= maxPlayers then
    return false
  end
  if f.hasTank or f.hasHealer then
    local counts = C_LFGList.GetSearchResultMemberCounts(resultID)
    if counts and not L.AnySecret(counts, "TANK", "HEALER") then
      if f.hasTank and (counts.TANK or 0) == 0 then return false end
      if f.hasHealer and (counts.HEALER or 0) == 0 then return false end
    end
  end
  if f.openForMe and #L.OpenRolesForPlayer(resultID, result, maxPlayers) == 0 then
    return false
  end
  return true
end

function Filters.Passes(resultID)
  local f = db()
  local result = C_LFGList.GetSearchResultInfo(resultID)
  if type(result) ~= "table"
      or L.AnySecret(result, "hasSelf", "isDelisted", "numMembers", "generalPlaystyle", "activityIDs") then
    return true
  end
  if result.hasSelf then return true end
  if f.hideDelisted and result.isDelisted then return false end

  local style = result.generalPlaystyle
  if style and style ~= 0 and f.playstyles[tostring(style)] == false then return false end

  if (result.numMembers or 0) <= 1 then
    return playerPasses(f, resultID)
  end
  return groupPasses(f, resultID, result)
end

-------------------------------------------------------------------------------
-- Hooking the result list. Blizzard fills frame.results from
-- C_LFGList.GetFilteredSearchResults(), sorts it and draws it; we drop the
-- listings that fail our filters and draw again.
-------------------------------------------------------------------------------

local function applyToFrame(frame)
  Filters.hidden, Filters.total = 0, 0
  if type(frame.results) ~= "table" then return Filters.UpdateStatus() end
  Filters.total = #frame.results

  local kept = {}
  for _, resultID in ipairs(frame.results) do
    if Filters.Passes(resultID) then kept[#kept + 1] = resultID end
  end
  Filters.hidden = Filters.total - #kept

  if Filters.hidden > 0 then
    frame.results = kept
    frame.totalResults = #kept
    frame:UpdateResults()
    if #kept == 0 and not frame.searching and not frame.searchFailed and frame.NoResultsFound then
      frame.NoResultsFound:SetText(("All %d results are hidden by your LFGForever filters."):format(Filters.hidden))
    end
  end
  Filters.UpdateStatus()
end

function Filters.Refresh()
  local frame = LFGBrowseFrame
  if frame and frame:IsVisible() and not frame.searching then frame:UpdateResultList() end
  for _, c in ipairs(Filters.controls) do c:Sync() end
  Filters.UpdateStatus()
end

-------------------------------------------------------------------------------
-- Panel
-------------------------------------------------------------------------------

local function addControl(c)
  Filters.controls[#Filters.controls + 1] = c
  return c
end

local function tooltip(owner, title, text)
  owner:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(title, 1, 1, 1)
    if text then GameTooltip:AddLine(text, nil, nil, nil, true) end
    GameTooltip:Show()
  end)
  owner:SetScript("OnLeave", GameTooltip_Hide)
end

-- get/set read and write one setting; label may be nil for an icon-only box.
local function checkbox(parent, x, y, label, atlas, get, set, tipTitle, tipText)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetSize(22, 22)
  cb:SetPoint("TOPLEFT", x, y)
  local anchor, width = cb, 0
  if atlas then
    cb.Icon = cb:CreateTexture(nil, "ARTWORK")
    cb.Icon:SetAtlas(atlas, false)
    cb.Icon:SetSize(16, 16)
    cb.Icon:SetPoint("LEFT", cb, "RIGHT", 0, 0)
    anchor, width = cb.Icon, 16
  end
  if label then
    cb.Label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    cb.Label:SetPoint("LEFT", anchor, "RIGHT", 2, 0)
    cb.Label:SetJustifyH("LEFT")
    cb.Label:SetText(label)
    width = width + 2 + cb.Label:GetStringWidth()
  end
  cb:SetHitRectInsets(0, -width, 0, 0)
  cb:SetScript("OnClick", function(self)
    set(self:GetChecked() and true or false)
    Filters.Refresh()
  end)
  if tipTitle then tooltip(cb, tipTitle, tipText) end
  function cb:Sync() self:SetChecked(get()) end
  return addControl(cb)
end

local function header(parent, y, text)
  local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  fs:SetPoint("TOPLEFT", PAD - 4, y)
  fs:SetText(text)
  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(1, 0.82, 0, 0.25)
  line:SetHeight(1)
  line:SetPoint("LEFT", fs, "RIGHT", 6, 0)
  line:SetPoint("RIGHT", parent, "RIGHT", -PAD, 0)
  return y - 20
end

local function textLink(parent, text, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetNormalFontObject(GameFontNormalSmall)
  b:SetHighlightFontObject(GameFontHighlightSmall)
  b:SetText(text)
  b:SetSize(b:GetFontString():GetStringWidth() + 4, 16)
  b:SetScript("OnClick", onClick)
  return b
end

local function levelBox(parent, key)
  local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  eb:SetSize(30, 18)
  eb:SetAutoFocus(false)
  eb:SetNumeric(true)
  eb:SetMaxLetters(2)
  eb:SetJustifyH("CENTER")
  eb:SetScript("OnTextChanged", function(self, userInput)
    if not userInput then return end
    db()[key] = tonumber(self:GetText()) or 0
    Filters.Refresh()
  end)
  eb:SetScript("OnEnterPressed", EditBox_ClearFocus)
  eb:SetScript("OnEscapePressed", EditBox_ClearFocus)
  function eb:Sync()
    if self:HasFocus() then return end
    local v = db()[key]
    self:SetText(v > 0 and tostring(v) or "")
  end
  return addControl(eb)
end

local function playstyles()
  local list = {}
  local enum = Enum and Enum.LFGEntryGeneralPlaystyle
  if not enum then return list end
  for _, key in ipairs({ "Learning", "FunRelaxed", "FunSerious", "Expert" }) do
    local value = enum[key]
    if value then
      local name = GetGeneralPlaystyleString and GetGeneralPlaystyleString(value)
      list[#list + 1] = { value = value, name = (name and name ~= "") and name or key }
    end
  end
  return list
end

local function buildContent(c)
  local f = db
  local col2 = PAD + 100
  local y = -6

  y = header(c, y, "Show")
  checkbox(c, PAD, y, LFG_LIST_CATEGORY_GROUPS or "Groups", nil,
    function() return f().groups end, function(v) f().groups = v end)
  checkbox(c, col2, y, LFG_LIST_CATEGORY_SOLO_PLAYERS or "Players", nil,
    function() return f().players end, function(v) f().players = v end)
  y = y - ROW
  checkbox(c, PAD, y, "Hide delisted", nil,
    function() return f().hideDelisted end, function(v) f().hideDelisted = v end)
  y = y - ROW - 6

  y = header(c, y, "Groups")
  checkbox(c, PAD, y, "Has a spot for my role", nil,
    function() return f().openForMe end, function(v) f().openForMe = v end,
    "Has a spot for my role", "Only groups with room for one of the roles you've selected in the group finder.")
  y = y - ROW
  checkbox(c, PAD, y, "Has a tank", ROLE_ICON.tank,
    function() return f().hasTank end, function(v) f().hasTank = v end)
  checkbox(c, col2, y, "Has a healer", ROLE_ICON.healer,
    function() return f().hasHealer end, function(v) f().hasHealer = v end)
  y = y - ROW
  checkbox(c, PAD, y, "Hide full groups", nil,
    function() return f().hideFull end, function(v) f().hideFull = v end)
  y = y - ROW - 6

  y = header(c, y, "Players")
  local roleLabel = c:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  roleLabel:SetPoint("TOPLEFT", PAD, y - 5)
  roleLabel:SetText(ROLE or "Role")
  local rx = PAD + 44
  for _, role in ipairs({ "tank", "healer", "dps" }) do
    local name = ({ tank = TANK, healer = HEALER, dps = DAMAGER })[role] or role
    checkbox(c, rx, y, nil, ROLE_ICON[role],
      function() return f().roles[role] end, function(v) f().roles[role] = v end,
      name, "Show players who listed themselves as " .. name:lower() .. ".")
    rx = rx + 46
  end
  y = y - ROW - 2

  local levelLabel = c:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  levelLabel:SetPoint("TOPLEFT", PAD, y - 5)
  levelLabel:SetText(LEVEL or "Level")
  local minBox = levelBox(c, "minLevel")
  minBox:SetPoint("TOPLEFT", PAD + 50, y - 2)
  local dash = c:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  dash:SetPoint("LEFT", minBox, "RIGHT", 4, 0)
  dash:SetText("-")
  local maxBox = levelBox(c, "maxLevel")
  maxBox:SetPoint("LEFT", dash, "RIGHT", 8, 0)
  local mine = textLink(c, "Near me", function()
    local level = UnitLevel("player")
    f().minLevel = math.max(1, level - 3)
    f().maxLevel = level + 3
    Filters.Refresh()
  end)
  mine:SetPoint("LEFT", maxBox, "RIGHT", 8, 0)
  tooltip(mine, "Near me", "Players within 3 levels of you.")
  y = y - ROW - 4

  local colWidth = (PANEL_WIDTH - 2 * PAD) / 3
  for i, class in ipairs(CLASSES) do
    local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
    local name = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class
    local cb = checkbox(c, PAD + col * colWidth, y - row * ROW, name, nil,
      function() return f().classes[class] ~= false end,
      function(v) setShown(f().classes, class, v) end)
    local color = RAID_CLASS_COLORS[class]
    if color then cb.Label:SetTextColor(color.r, color.g, color.b) end
  end
  y = y - 3 * ROW
  local all = textLink(c, "Select all", function()
    wipe(f().classes)
    Filters.Refresh()
  end)
  all:SetPoint("TOPLEFT", PAD + 4, y)
  local none = textLink(c, "Unselect all", function()
    for _, class in ipairs(CLASSES) do f().classes[class] = false end
    Filters.Refresh()
  end)
  none:SetPoint("LEFT", all, "RIGHT", 12, 0)
  y = y - ROW - 4

  local styles = playstyles()
  if #styles > 0 then
    y = header(c, y, "Playstyle")
    for _, s in ipairs(styles) do
      local key = tostring(s.value)
      checkbox(c, PAD, y, s.name, nil,
        function() return f().playstyles[key] ~= false end,
        function(v) setShown(f().playstyles, key, v) end)
      y = y - ROW
    end
  end
end

local function setPanelOpen(open)
  db().panelOpen = open
  Filters.Panel:SetShown(open)
  Filters.Toggle:SetShown(not open)
end

function Filters.TogglePanel()
  if not Filters.Panel then return end
  setPanelOpen(not db().panelOpen)
end

function Filters.UpdateStatus()
  local panel = Filters.Panel
  if not panel then return end
  local text
  if Filters.hidden > 0 then
    text = ("Hiding |cffffffff%d|r of %d"):format(Filters.hidden, Filters.total)
  else
    text = "|cff808080Nothing hidden|r"
  end
  panel.Status:SetText(text)
  Filters.Toggle.Count:SetText(Filters.hidden > 0 and Filters.hidden or "")
end

local function createPanel(browse)
  local parent = LFGParentFrame or browse
  local panel = CreateFrame("Frame", "LFGForeverFilterPanel", browse, "ButtonFrameTemplate")
  panel:SetWidth(PANEL_WIDTH)
  panel:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
  panel:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 0, 0)
  if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(panel) end
  if ButtonFrameTemplate_HideButtonBar then ButtonFrameTemplate_HideButtonBar(panel) end
  if panel.SetTitle then panel:SetTitle("LFGForever Filters") end
  -- The inset leaves room for a portrait we don't have; start it right under the title.
  if panel.Inset then panel.Inset:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -24) end
  panel:EnableMouse(true)
  if panel.CloseButton then
    panel.CloseButton:SetScript("OnClick", function() setPanelOpen(false) end)
  end

  local content = CreateFrame("Frame", nil, panel)
  content:SetPoint("TOPLEFT", panel.Inset or panel, "TOPLEFT", 0, -4)
  content:SetPoint("BOTTOMRIGHT", panel.Inset or panel, "BOTTOMRIGHT", 0, 30)
  buildContent(content)

  panel.Status = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  panel.Status:SetPoint("BOTTOMLEFT", panel.Inset or panel, "BOTTOMLEFT", PAD, 10)

  local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  reset:SetSize(70, 22)
  reset:SetText(RESET or "Reset")
  reset:SetPoint("BOTTOMRIGHT", panel.Inset or panel, "BOTTOMRIGHT", -8, 6)
  reset:SetScript("OnClick", function()
    L.ResetFilters()
    Filters.Refresh()
  end)

  -- Reopens the panel; sits on the group finder's right edge while it's closed.
  local toggle = CreateFrame("Button", nil, browse)
  toggle:SetSize(34, 34)
  toggle:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, -64)
  toggle.Icon = toggle:CreateTexture(nil, "ARTWORK")
  toggle.Icon:SetAllPoints()
  toggle.Icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
  toggle:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  toggle.Count = toggle:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  toggle.Count:SetPoint("BOTTOMRIGHT", -2, 2)
  toggle:SetScript("OnClick", function() setPanelOpen(true) end)
  tooltip(toggle, "LFGForever Filters", "Show the filter panel.")

  Filters.Panel, Filters.Toggle = panel, toggle
  setPanelOpen(db().panelOpen)
  for _, c in ipairs(Filters.controls) do c:Sync() end
  Filters.UpdateStatus()
end

L.Skin.Register("filters", "LFGBrowseFrame", function(browse)
  if type(browse.UpdateResultList) ~= "function" or type(browse.UpdateResults) ~= "function" then return end
  hooksecurefunc(browse, "UpdateResultList", L.Guard("Filters", applyToFrame))
  L.Guard("Filter panel", createPanel)(browse)

  -- "Has a spot for my role" depends on the roles you've picked.
  local roleWatcher = CreateFrame("Frame")
  roleWatcher:RegisterEvent("LFG_LIST_ROLE_UPDATE")
  roleWatcher:SetScript("OnEvent", function()
    if db().openForMe then Filters.Refresh() end
  end)
end)
