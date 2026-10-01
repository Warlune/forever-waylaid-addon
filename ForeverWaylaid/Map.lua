local _,F=...
local G,S=F.Geometry,F.Style
function F.CreateRouteOverlay(parent)
  local overlay=CreateFrame("Frame",nil,parent);overlay:SetAllPoints(parent)
  overlay:SetFrameLevel(parent:GetFrameLevel()+5);overlay:EnableMouse(false);overlay:SetClipsChildren(true)
  overlay.lines={};overlay.pins={};overlay.showJourneyStages=false;return overlay
end
function F.ClearRouteOverlay(overlay)
  for _,line in ipairs(overlay.lines)do line:Hide()end
  for _,pin in ipairs(overlay.pins)do pin:Hide()end
end
function F.DrawRouteOverlay(overlay,project,clip,inside,showPlayer,small,player,overview)
  F.ClearRouteOverlay(overlay)
  if not F.DisplayRoute then return end
  player=player or F.Route.Player()
  local segments,stops=F.DisplayRoute(player);local lineIndex,pinIndex=0,0
  local stages=overlay.showJourneyStages and F.BuildJourney(segments) or {};overlay.journey=stages;overlay.journeyStops=stops
  local function pin(point,text,kind,stop,stage)
    local x,y=project(point);if not x or not inside(x,y)then return end
    pinIndex=pinIndex+1;local p=overlay.pins[pinIndex]
    if not p then
      p=CreateFrame("Button",nil,overlay,"BackdropTemplate");p:SetSize(small and 15 or 22,small and 15 or 22)
      p:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8})
      p:SetBackdropColor(0.13,0.09,0.04,0.95);p:SetBackdropBorderColor(0.94,0.73,0.28,1)
      p.icon=p:CreateTexture(nil,"ARTWORK");p.icon:SetPoint("CENTER");p.icon:SetSize(small and 13 or 18,small and 13 or 18)
      p.text=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");p.text:SetAllPoints()
      overlay.pins[pinIndex]=p
    end
    p:ClearAllPoints();p:SetPoint("CENTER",overlay,"TOPLEFT",x,-y);p:Show()
    p.icon:SetShown(kind~="stop" and kind~="stage");p.text:SetText((kind=="stop" or kind=="stage") and text or "")
    p.icon:SetTexture(kind=="player" and "Interface\\Minimap\\MinimapArrow" or kind=="transport" and "Interface\\Icons\\INV_Misc_Map_01" or S.icons.flight)
    p:SetBackdropColor(0.13,0.09,0.04,kind=="player" and 0 or 0.95)
    p:SetBackdropBorderColor(0.94,0.73,0.28,kind=="player" and 0 or 1)
    if stage and stage.mode~="Travel" then
      if stage.mode=="Fly" then p:SetBackdropBorderColor(0.25,0.8,1,1)
      else p:SetBackdropBorderColor(0.8,0.55,1,1)end
    end
    p.icon:SetRotation(kind=="player" and (GetPlayerFacing and GetPlayerFacing()or 0)or 0)
    p:SetScript("OnEnter",function(self)
      if stage then F.JourneyTooltip(stage,self);return end
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(text)
      if stop then GameTooltip:AddLine(stop.npc or stop.deliveryText or F.DestinationText(stop.point),1,0.85,0.5,true)end
      GameTooltip:Show()
    end)
    p:SetScript("OnLeave",function()GameTooltip:Hide()end)
    p:SetScript("OnClick",function()
      if stage and WorldMapFrame then
        local id=F.JourneyMap({stage});if id then WorldMapFrame:SetMapID(id)end
      elseif stop then F.TrackDelivery(stop.questID)end
    end)
  end
  local function line(x,y,u,v,mode,dashed)
    lineIndex=lineIndex+1;local stroke=overlay.lines[lineIndex]
    if not stroke then stroke=overlay:CreateLine(nil,"ARTWORK");stroke:SetThickness(small and 2 or 3);overlay.lines[lineIndex]=stroke end
    if mode=="Fly" then stroke:SetColorTexture(0.25,0.8,1,0.95)
    elseif mode~="Travel" then stroke:SetColorTexture(0.8,0.55,1,0.95)
    else stroke:SetColorTexture(1,0.73,0.2,dashed and 0.65 or 0.95)end
    stroke:SetStartPoint("TOPLEFT",overlay,x,-y);stroke:SetEndPoint("TOPLEFT",overlay,u,-v);stroke:Show()
  end
  for _,step in ipairs(segments)do
    -- A direct bearing is not a traversable path. Do not draw unknown ground
    -- or off-road approaches as a solid line through walls and mountains.
    local dashed=step.mode=="Travel" and step.road~="mapped"
    local draw=not dashed or overview
    local ax,ay,bx,by
    if draw then ax,ay=project(step.from);bx,by=project(step.to)end
    if ax and bx then
      local x,y,u,v=clip(ax,ay,bx,by)
      if x and (math.abs(x-u)+math.abs(y-v))>0.1 then
        if dashed then
          local dx,dy=u-x,v-y;local length=math.sqrt(dx*dx+dy*dy)
          local count=math.min(80,math.max(1,math.ceil(length/12)))
          for i=0,count-1 do
            local a,b=i/count,(i+0.5)/count
            line(x+dx*a,y+dy*a,x+dx*b,y+dy*b,step.mode,true)
          end
        else line(x,y,u,v,step.mode)end
      end
    end
    if not overlay.showJourneyStages then
      if step.mode=="Fly" then pin(step.from,step.from.name or "Flight master","flight");pin(step.to,step.to.name or "Arrival flight master","flight")end
      if step.mode~="Fly" and step.mode~="Travel" then pin(step.from,step.mode..": "..(step.to.name or "Destination"),"transport");pin(step.to,step.to.name or "Arrival","transport")end
    end
  end
  if overlay.showJourneyStages then
    for _,stage in ipairs(stages)do pin(stage.from,tostring(stage.number),"stage",nil,stage)end
  end
  for _,stop in ipairs(stops)do pin(stop.point,(overlay.showJourneyStages and "D" or "")..stop.number,"stop",stop.stop)end
  if showPlayer and player then pin(player,"You","player")end
end
local function drawMap(overlay,map,showPlayer)
  local w,h=overlay:GetWidth(),overlay:GetHeight()
  local function project(point)local x,y=G.Project(point,map);if x then return x*w,y*h end end
  local info=C_Map.GetMapInfo(map)
  local overview=info and (info.mapType==1 or info.mapType==2)
  F.DrawRouteOverlay(overlay,project,function(a,b,c,d)return G.Rect(a,b,c,d,2,2,w-2,h-2)end,
    function(x,y)return x>=8 and x<=w-8 and y>=8 and y<=h-8 end,showPlayer,nil,nil,overview)
end
function F.UpdateWorldRouteLayer(overlay,map)
  local manager=map.GetPinFrameLevelsManager and map:GetPinFrameLevelsManager()
  if not manager or not manager.GetValidFrameLevel then return end
  -- Zone exploration and fog are full-map pins, far above the canvas.
  -- Use the map's overlay band above both, below its POI/player icons.
  -- Query again when drawing: map providers can change the level ordering.
  local level=math.max(manager:GetValidFrameLevel("PIN_FRAME_LEVEL_QUEST_BLOB"),
    manager:GetValidFrameLevel("PIN_FRAME_LEVEL_MAP_EXPLORATION")+1,
    manager:GetValidFrameLevel("PIN_FRAME_LEVEL_FOG_OF_WAR")+1)
  if overlay:GetFrameLevel()~=level then overlay:SetFrameLevel(level)end
end
function F.InstallMap()
  if F.worldOverlay or not WorldMapFrame or not WorldMapFrame.ScrollContainer then return end
  local canvas=WorldMapFrame.ScrollContainer.Child;if not canvas then return end
  local overlay=F.CreateRouteOverlay(canvas);F.worldOverlay=overlay
  overlay.showJourneyStages=true
  local journey=F.CreateJourneyPanel(WorldMapFrame,overlay);F.journeyPanel=journey
  F.UpdateWorldRouteLayer(overlay,WorldMapFrame)
  local elapsed,panelElapsed=0,0
  overlay:SetScript("OnUpdate",function(_,dt)
    panelElapsed=panelElapsed+dt
    elapsed=elapsed+dt;if elapsed<0.05 or not F.ready then return end;elapsed=0
    if F.db.settings.worldRoute then
      F.UpdateWorldRouteLayer(overlay,WorldMapFrame)
      drawMap(overlay,WorldMapFrame:GetMapID(),false)
    else F.ClearRouteOverlay(overlay);journey:Hide()end
    if panelElapsed>=0.25 then panelElapsed=0;F.UpdateJourneyPanel(journey,WorldMapFrame,overlay)end
  end)
end
function F.CreateTravelMap(parent,x,y,w,h)
  local map=S.Panel(parent,x,y,w,h);map:SetClipsChildren(true)
  map.canvas=CreateFrame("Frame",nil,map);map.canvas:SetPoint("TOPLEFT",5,-5);map.canvas:SetPoint("BOTTOMRIGHT",-5,5)
  map.tiles={};map.overlay=F.CreateRouteOverlay(map.canvas)
  map.label=S.Text(map,"",10,-10,w-76,"GameFontNormalSmall",S.gold)
  map.label:SetMaxLines(1)
  map.unavailable=S.Text(map,"Map artwork unavailable",15,-h/2,w-30,"GameFontHighlightSmall",S.muted)
  map.zoomPath={};map.zoomIndex=1
  local function zoomButton(text,offset,delta)
    local button=S.Button(map,text,0,0,24,function()F.ZoomTravelMap(map,delta)end)
    button:ClearAllPoints();button:SetPoint("TOPRIGHT",map,"TOPRIGHT",offset,-8);button:SetSize(24,24)
    button:SetFrameLevel(map.overlay:GetFrameLevel()+3)
    button:SetScript("OnEnter",function(self)
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      GameTooltip:SetText(delta>0 and "Zoom in" or "Zoom out")
      local id=map.zoomPath[map.zoomIndex+delta]
      local info=id and C_Map.GetMapInfo(id)
      if info then GameTooltip:AddLine(info.name,1,0.85,0.5)end
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function()GameTooltip:Hide()end)
    return button
  end
  map.zoomOut=zoomButton("−",-34,-1)
  map.zoomIn=zoomButton("+",-8,1)
  return map
end
-- Use the client's map hierarchy, including Forever zones. The world is
-- the outer limit; never zoom into unrelated cosmic or instance maps.
local function zoomPath(id)
  local path,seen={},{}
  local worldType=Enum.UIMapType and Enum.UIMapType.World or 1
  for _=1,15 do
    if not id or id==0 or seen[id] then break end
    local info=C_Map.GetMapInfo(id);if not info then break end
    table.insert(path,1,id);seen[id]=true
    if info.mapType==worldType then break end
    id=info.parentMapID
  end
  return path
end
function F.ZoomTravelMap(map,delta)
  local index=map.zoomIndex+delta
  if index<1 or index>#map.zoomPath then return end
  map.zoomDepth=index
  GameTooltip:Hide()
  F.UpdateTravelMap(map)
end
local function commonMap(a,b)
  return F.CommonRouteMap(a,b)
end
function F.UpdateTravelMap(map)
  local player=F.Route.Player();local target=F.guidance and F.guidance.target
  map.zoomPath=zoomPath(player and player.mapID)
  local id=player and commonMap(player.mapID,target and target.mapID)
  if type(map.zoomDepth)=="number" then
    id=map.zoomPath[math.min(map.zoomDepth,#map.zoomPath)]
  end
  map.zoomIndex=1
  for index,pathID in ipairs(map.zoomPath)do if pathID==id then map.zoomIndex=index;break end end
  map.zoomIn:SetEnabled(id~=nil and map.zoomIndex<#map.zoomPath)
  map.zoomOut:SetEnabled(id~=nil and map.zoomIndex>1)
  if not id then F.ClearRouteOverlay(map.overlay);return end
  local info=C_Map.GetMapInfo(id);map.label:SetText(info and info.name or "")
  if id==map.mapID then F.DrawTravelRoute(map);return end
  map.mapID=id
  for _,tile in ipairs(map.tiles)do tile:Hide()end
  local layers=C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(id)
  local layer=layers and layers[1]
  local textures=layer and C_Map.GetMapArtLayerTextures(id,1)
  map.unavailable:SetShown(not textures or #textures==0)
  if textures and layer then
    local cols=math.ceil(layer.layerWidth/layer.tileWidth);local rows=math.ceil(layer.layerHeight/layer.tileHeight)
    local w,h=map.canvas:GetWidth(),map.canvas:GetHeight()
    for row=0,rows-1 do for col=0,cols-1 do
      local index=row*cols+col+1;local tile=map.tiles[index]
      if not tile then tile=map.canvas:CreateTexture(nil,"BACKGROUND");map.tiles[index]=tile end
      local tw=math.min(layer.tileWidth,layer.layerWidth-col*layer.tileWidth)
      local th=math.min(layer.tileHeight,layer.layerHeight-row*layer.tileHeight)
      tile:ClearAllPoints();tile:SetPoint("TOPLEFT",col*layer.tileWidth/layer.layerWidth*w,-row*layer.tileHeight/layer.layerHeight*h)
      tile:SetSize(tw/layer.layerWidth*w,th/layer.layerHeight*h);tile:SetTexCoord(0,tw/layer.tileWidth,0,th/layer.tileHeight)
      tile:SetTexture(textures[index]);tile:Show()
    end end
  end
  F.DrawTravelRoute(map)
end
function F.DrawTravelRoute(map)
  if map.mapID then drawMap(map.overlay,map.mapID,true)end
end
