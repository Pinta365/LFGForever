local _, L = ...

local function colorActivity(button, elementData)
  if not (elementData and elementData.activityID and button.NameButton and button.Level) then return end
  local info = C_LFGList.GetActivityInfoTable(elementData.activityID)
  local lo, hi = elementData.minLevel, elementData.maxLevel
  if info and ((info.minLevelSuggestion or 0) > 0 or (info.maxLevelSuggestion or 0) > 0) then
    lo, hi = info.minLevelSuggestion, info.maxLevelSuggestion
  end
  local c = L.LevelFitColor(lo, hi)
  button.NameButton.Name:SetTextColor(c.r, c.g, c.b)
  button.Level:SetTextColor(c.r, c.g, c.b)
end

L.Skin.Register("listingActivities", "LFGListingFrame", function()
  if type(LFGListingActivityView_InitActivityButton) ~= "function" then return end
  hooksecurefunc("LFGListingActivityView_InitActivityButton", L.Guard("Listing zone colours", colorActivity))
end)
