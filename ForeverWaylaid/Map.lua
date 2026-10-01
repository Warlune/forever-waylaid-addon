local _, F = ...
-- A lightweight overlay on Blizzard's map: gold travel legs, blue flights,
-- numbered deliveries. Lines indicate itinerary, not terrain-safe road paths.
function F.InstallMap()
  if not WorldMapFrame or not WorldMapFrame.ScrollContainer then return end
  local canvas = WorldMapFrame.ScrollContainer.Child
  if not canvas then return end
  local overlay = CreateFrame("Frame",nil,canvas)
  overlay:SetAllPoints(canvas); overlay:SetFrameLevel(canvas:GetFrameLevel()+20)
  overlay:EnableMouse(false)
  local pins, lines = {}, {}
  local function project(point,map)
    local result, pos = C_Map.GetMapPosFromWorldPos(point.instance,CreateVector2D(point.wx,point.wy),map)
    if result ~= map or not pos then return end
    local x,y = pos:GetXY()
    if x<0 or y<0 or x>1 or y>1 then return end
    return x*canvas:GetWidth(), -y*canvas:GetHeight()
  end
  local function draw()
    for _,pin in ipairs(pins) do pin:Hide() end
    for _,line in ipairs(lines) do line:Hide() end
    if not F.route then return end
    local map, lineIndex = WorldMapFrame:GetMapID(), 0
    for i,leg in ipairs(F.route) do
      local x,y = project(leg.stop.point,map)
      if x then
        local pin = pins[i]
        if not pin then
          pin=CreateFrame("Button",nil,overlay,"BackdropTemplate"); pin:SetSize(24,24)
          pin:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
          pin:SetBackdropColor(0.16,0.10,0.04,1); pin:SetBackdropBorderColor(1,0.8,0.2,1)
          pin.text=pin:CreateFontString(nil,"OVERLAY","GameFontNormal"); pin.text:SetAllPoints()
          pins[i]=pin
        end
        pin:ClearAllPoints();pin:SetPoint("CENTER",overlay,"TOPLEFT",x,y);pin.text:SetText(i);pin:Show()
        pin:SetScript("OnClick",function() F.Navigate(leg.stop.point,leg.stop.questID) end)
        pin:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(leg.stop.writ.name);GameTooltip:Show() end)
        pin:SetScript("OnLeave",function() GameTooltip:Hide() end)
      end
      for _,step in ipairs(leg.steps) do
        local ax,ay=project(step.from,map); local bx,by=project(step.to,map)
        if ax and bx then
          lineIndex=lineIndex+1
          local line=lines[lineIndex]
          if not line then line=overlay:CreateLine(nil,"ARTWORK");line:SetThickness(2);lines[lineIndex]=line end
          if step.mode=="Fly" then line:SetColorTexture(0.3,0.75,1,0.85) else line:SetColorTexture(1,0.78,0.25,0.8) end
          line:SetStartPoint("TOPLEFT",overlay,ax,ay);line:SetEndPoint("TOPLEFT",overlay,bx,by);line:Show()
        end
      end
    end
  end
  local elapsed=0
  overlay:SetScript("OnUpdate",function(_,dt) elapsed=elapsed+dt;if elapsed>1 then elapsed=0;draw() end end)
end
