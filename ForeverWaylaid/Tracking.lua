local _, F = ...

function F.DestinationText(point)
  if not point then return "Delivery location not supplied yet" end
  local info=C_Map.GetMapInfo(point.mapID)
  return (info and info.name or "Map "..point.mapID)..string.format("  %.1f, %.1f",point.x*100,point.y*100)
end
function F.LearnRecipient()
  local questID=GetQuestID and GetQuestID()
  if not questID or not F.writsByQuest[questID] then return end
  local name=UnitName and UnitName("npc");local point=F.Route.Player()
  if name and point then F.char.recipients[questID]={npc=name,point=point} end
end

function F.UpdateTracking()
  F.active = {}
  for questID, writ in pairs(F.writsByQuest) do
    if C_QuestLog.IsOnQuest(questID) then
      local ready = C_QuestLog.IsComplete(questID)
      local location = F.char.pins[questID]
      -- Before completion a quest waypoint may be a material objective.
      -- Only use the game's waypoint automatically when ready to deliver.
      if not location and ready and C_QuestLog.GetNextWaypoint then
        local map, x, y = C_QuestLog.GetNextWaypoint(questID)
        if map and x and y then location = { mapID = map, x = x, y = y } end
      end
      if not location and ready and GetQuestUiMapID and C_QuestLog.GetQuestsOnMap then
        local map=GetQuestUiMapID(questID,true)
        for _,poi in ipairs(map and C_QuestLog.GetQuestsOnMap(map) or {}) do
          if poi.questID==questID and not poi.isQuestStart then location={mapID=map,x=poi.x,y=poi.y};break end
        end
      end
      local count = (C_Item and C_Item.GetItemCount or GetItemCount)(writ.targetId)
      local point=F.Route.World(location)
      local remembered=F.char.recipients[questID]
      local npc=location and location.npc
      if not npc and remembered and point and F.Route.Distance(point,remembered.point)<100 then npc=remembered.npc end
      local deliveryText=C_QuestLog.GetNextWaypointText and C_QuestLog.GetNextWaypointText(questID)
      if not deliveryText and C_QuestLog.GetLogIndexForQuestID and GetQuestLogCompletionText then
        local index=C_QuestLog.GetLogIndexForQuestID(questID)
        if index then deliveryText=GetQuestLogCompletionText(index) end
      end
      F.active[#F.active + 1] = { questID = questID, writ = writ, ready = ready,
        owned = count or 0, point = point, manual = location and location.manual, npc=npc, deliveryText=deliveryText }
    end
  end
  table.sort(F.active, function(a,b) return a.questID < b.questID end)
  F.route, F.unresolved, F.routeSeconds, F.routeMode = F.Route.Plan(F.Route.Player(), F.active, F.char.flights, F.db.settings.flights)
end

function F.LearnFlights()
  if not C_TaxiMap or not C_TaxiMap.GetTaxiNodesForMap then return end
  local mapID = C_Map.GetBestMapForUnit("player")
  if not mapID then return end
  local root = mapID
  for _ = 1, 8 do
    local info = C_Map.GetMapInfo(root)
    if not info or not info.parentMapID or info.parentMapID == 0 then break end
    root = info.parentMapID
  end
  local maps = C_Map.GetMapChildrenInfo(root, nil, true) or {}
  maps[#maps + 1] = { mapID = root }; maps[#maps + 1] = { mapID = mapID }
  local byName = {}
  local faction = UnitFactionGroup("player") == "Horde" and 1 or 2
  for _, map in ipairs(maps) do
    local nodes = C_TaxiMap.GetTaxiNodesForMap(map.mapID) or {}
    for _, node in ipairs(nodes) do
      if not node.isUndiscovered and (node.faction == 0 or node.faction == faction) then
        local x, y = node.position:GetXY()
        local point = F.Route.World({ mapID = map.mapID, x = x, y = y, name = node.name })
        if point then point.nodeID = node.nodeID; byName[node.name] = point end
      end
    end
  end
  local current, reachable = nil, {}
  for slot = 1, NumTaxiNodes() do
    local kind, name = TaxiNodeGetType(slot), TaxiNodeName(slot)
    local point = byName[name]
    if point and (kind == "CURRENT" or kind == "REACHABLE") then
      F.char.flights.nodes[point.nodeID] = point
      if kind == "CURRENT" then current = point else reachable[#reachable + 1] = point end
    end
  end
  if current then
    local edges = {}
    for _, point in ipairs(reachable) do
      -- Flight curvature varies. This is an explicit estimate, not a measured ETA.
      edges[point.nodeID] = F.Route.Distance(current, point) / 32 * 1.3
    end
    F.char.flights.edges[current.nodeID] = edges
  end
end

function F.Navigate(point, questID)
  if not point then F.Print("This writ needs a delivery pin."); return end
  if F.tomtom and TomTom and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(F.tomtom); F.tomtom = nil end
  if TomTom and TomTom.AddWaypoint then
    F.tomtom = TomTom:AddWaypoint(point.mapID, point.x, point.y, { title = "Waylaid delivery", persistent = false, minimap = true, world = true })
  end
  if C_Map.SetUserWaypoint and UiMapPoint then
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(point.mapID, point.x, point.y))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
  elseif questID and C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
    C_SuperTrack.SetSuperTrackedQuestID(questID)
  end
  if WorldMapFrame then WorldMapFrame:SetMapID(point.mapID); ShowUIPanel(WorldMapFrame) end
end
