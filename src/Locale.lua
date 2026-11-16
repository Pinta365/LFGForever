local _, L = ...

-- Addon-owned text is centralized here. Add another locale by extending the
-- table below; missing entries always fall back to English.
local english = {
  COMMANDS = "commands:",
  DEBUG_TOGGLE = "debug %s",
  DEBUG_ON = "on",
  DEBUG_OFF = "off",
  FEATURE_DISABLED = "%s turned off after an error; /reload to retry.",
  KEY_DEBUG = "debug",
  KEY_DEBUG_HELP = "  /lfgf debug - toggle debug output",
  OPEN_SPOT = "Open spot for your role",
}

local locales = {
  zhCN = {
    COMMANDS = "命令：",
    DEBUG_TOGGLE = "调试模式：%s",
    DEBUG_ON = "开启",
    DEBUG_OFF = "关闭",
    FEATURE_DISABLED = "功能“%s”发生错误，已停用；输入 /reload 重试。",
    KEY_DEBUG_HELP = "  /lfgf debug - 切换调试输出",
    OPEN_SPOT = "你的职责有空缺位置",
  },
}

local function copy(source)
  local result = {}
  for key, value in pairs(source) do result[key] = value end
  return result
end

local locale = GetLocale and GetLocale() or "enUS"
L.Locale = locale
L.L = copy(english)
for key, value in pairs(locales[locale] or {}) do L.L[key] = value end

-- Language packs may call this before the rest of the addon loads.
function L.RegisterLocale(code, strings)
  if code == locale and type(strings) == "table" then
    for key, value in pairs(strings) do
      if type(value) == "string" and english[key] ~= nil then L.L[key] = value end
    end
  end
end
