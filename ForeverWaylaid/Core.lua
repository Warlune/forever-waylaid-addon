local _, F = ...
F.version = "0.8.3"
F.defaults = { cheapest = true, includeCrate = false, allCosts = false, personal = true, flights = true, navigator = true, worldRoute = true, minimapRoute = true, craftGoods = false, peerSharing = false, debugAlliance = false, generalAuctionTooltips = true, autoHideAuction = true }

function F.ApplySettings()
  F.Style.ApplyTheme()
  if F.ShouldHideAuctionExtras() then F.CancelNativeScan("Another auction addon is enabled. Previous prices kept.")end
  F.UpdateScanUI();F.Refresh()
end

function F.Now() return GetServerTime and GetServerTime() or time() end
function F.Positive(n) return type(n) == "number" and n == n and n > 0 and n < math.huge end
function F.Print(text)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffdfbc65Forever Waylaid:|r " .. text) end
end
function F.Money(n)
  if not n then return "Unpriced" end
  n = math.ceil(n)
  return string.format("%dg %ds %dc", math.floor(n / 10000), math.floor(n / 100) % 100, n % 100)
end
function F.Refresh()
  if F.UpdateTracking then F.UpdateTracking() end
  if F.UpdateGuidance then F.UpdateGuidance() end
  if F.Render then F.Render() end
  if F.UpdateNavigator then F.UpdateNavigator() end
end

local events = CreateFrame("Frame")
F.events = events
for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "QUEST_LOG_UPDATE", "BAG_UPDATE_DELAYED", "TAXIMAP_OPENED", "ZONE_CHANGED_NEW_AREA", "QUEST_COMPLETE", "GET_ITEM_INFO_RECEIVED"}) do events:RegisterEvent(event) end
local queued = false
events:SetScript("OnEvent", function(_, event, name, success)
  if event=="GET_ITEM_INFO_RECEIVED" then
    if not success or not F.Style or not F.Style.qualityPending[name] then return end
    F.Style.qualityPending[name]=nil
  end
  if event == "ADDON_LOADED" and name == "ForeverWaylaid" then
    ForeverWaylaidDB = ForeverWaylaidDB or {}
    ForeverWaylaidCharDB = ForeverWaylaidCharDB or {}
    F.db, F.char = ForeverWaylaidDB, ForeverWaylaidCharDB
    F.db.settings = F.db.settings or {}
    for key, value in pairs(F.defaults) do if F.db.settings[key] == nil then F.db.settings[key] = value end end
    F.char.flights = F.char.flights or { nodes = {}, edges = {} }
    F.char.pins = F.char.pins or {}
    F.char.localPrices = F.char.localPrices or {}
    F.char.peerPrices = F.char.peerPrices or {}
    F.char.recipients = F.char.recipients or {}
    F.char.realm = GetRealmName()
  elseif event == "PLAYER_LOGIN" then
    F.BuildUI(); F.InstallTooltips(); F.InstallMap(); F.BuildNavigator(); F.RegisterAuctionator(); F.Refresh()
    F.InitializePeers()
    F.Print("v" .. F.version .. " — /fwl to open. Scan AH prices or opt into peer sharing in Settings.")
    if F.NeedsFlightScan()then F.Print("Flight paths not scanned: open a flight master's map to learn your routes. No flight purchase needed; until then, routing uses walking estimates.")end
  elseif F.char then
    if event=="ADDON_LOADED" then F.InstallMap();return end
    if event=="QUEST_COMPLETE" then F.LearnRecipient() end
    if event == "TAXIMAP_OPENED" then F.LearnFlights() end
    if not queued then
      queued = true
      C_Timer.After(0.25, function() queued = false; F.Refresh() end)
    end
  end
end)

-- Navigation must continue while the ledger and world map are closed.
local poseElapsed,routeElapsed=0,0
events:SetScript("OnUpdate",function(_,dt)
  if not F.ready then return end
  poseElapsed=poseElapsed+dt;routeElapsed=routeElapsed+dt
  if poseElapsed>=0.05 then
    poseElapsed=0;F.UpdateCompassPose();F.DrawMinimap()
  end
  if routeElapsed>=5 then
    routeElapsed=0
    if #(F.active or {})>0 then F.Refresh() end
    F.InstallMap()
  end
end)

SLASH_FOREVERWAYLAID1 = "/fwl"
SLASH_FOREVERWAYLAID2 = "/waylaid"
SlashCmdList.FOREVERWAYLAID = function(msg)
  local quest, map, x, y, npc = msg:match("^pin%s+(%d+)%s+(%d+)%s+([%d.]+)%s+([%d.]+)%s*(.*)$")
  if quest then
    quest, map, x, y = tonumber(quest), tonumber(map), tonumber(x), tonumber(y)
    if F.writsByQuest[quest] and C_Map.GetMapInfo(map) and x >= 0 and x <= 100 and y >= 0 and y <= 100 then
      F.char.pins[quest] = { mapID = map, x = x / 100, y = y / 100, manual = true, npc = npc~="" and npc or nil }
      F.Refresh(); F.Print("Delivery pin saved.")
    else F.Print("Invalid writ, map or coordinates.") end
    return
  end
  local clear = tonumber(msg:match("^unpin%s+(%d+)$"))
  if clear then F.char.pins[clear] = nil; F.Refresh(); return end
  if msg == "prices" then F.ImportPersonal(); F.Refresh(); return end
  if msg == "compass" then F.db.settings.navigator=not F.db.settings.navigator;F.UpdateNavigator();return end
  if msg == "reset" then F.ResetNavigator();return end
  if msg ~= "" then F.Print("/fwl | /fwl prices | /fwl pin QUEST_ID MAP_ID X Y | /fwl unpin QUEST_ID"); return end
  F.window:SetShown(not F.window:IsShown())
end
