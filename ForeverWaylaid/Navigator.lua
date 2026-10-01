local _,F=...
local S,G=F.Style,F.Geometry
local unfold="|TInterface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up:18:18|t Unfold the map"
local fold="|TInterface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up:18:18|t Fold the map"
function F.TrackDelivery(questID)
  F.char.navQuest=questID;F.db.settings.navigator=true;F.Refresh()
end
function F.UpdateGuidance()
  local chosen
  for _,stop in ipairs(F.active or {})do if stop.questID==F.char.navQuest and stop.point then chosen=stop end end
  if not chosen then
    F.char.navQuest=nil
    chosen=chosen or (F.route and F.route[1] and F.route[1].stop)
  end
  local player=F.Route.Player()
  if not chosen or not player then F.guidance=nil;F.flightGuidance=nil;return end
  -- Keep the booked flight's arrival target while on the taxi. Replanning from
  -- an airborne position can otherwise direct the player back to departure.
  if UnitOnTaxi and UnitOnTaxi("player") and F.flightGuidance and F.flightGuidance.stop.questID==chosen.questID then
    F.guidance=F.flightGuidance;F.guidance.action="In flight";return
  end
  F.flightGuidance=nil
  local seconds,steps=F.Route.Leg(player,chosen.point,F.char.flights,F.db.settings.flights)
  local target,action,flight=chosen.point,"Deliver to customer",nil
  for _,step in ipairs(steps)do
    if step.mode=="Fly" then
      flight=step
      if F.Route.Distance(player,step.from)>25 then target,action=step.from,"Go to flight master"
      else target,action=step.from,"Take flight to "..(step.to.name or "next stop") end
      break
    end
  end
  F.guidance={stop=chosen,target=target,action=action,steps=steps,seconds=seconds,flight=flight}
  if flight then
    F.flightGuidance={stop=chosen,target=flight.to,action="In flight",steps=steps,seconds=seconds,flight=flight}
  end
end
function F.DisplayRoute()
  local segments,stops={},{}
  if F.guidance and F.char.navQuest then
    for _,step in ipairs(F.guidance.steps)do segments[#segments+1]=step end
    stops[1]={point=F.guidance.stop.point,stop=F.guidance.stop,number=1}
  else
    for i,leg in ipairs(F.route or {})do
      local steps=i==1 and F.guidance and F.guidance.stop.questID==leg.stop.questID and F.guidance.steps or leg.steps
      for _,step in ipairs(steps)do segments[#segments+1]=step end
      stops[#stops+1]={point=leg.stop.point,stop=leg.stop,number=i}
    end
  end
  return segments,stops
end
function F.ResetNavigator()
  F.char.navPosition=nil;F.char.minimapAngle=220
  if F.compass then F.compass:ClearAllPoints();F.compass:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-270,-300)end
  if F.PositionMinimapButton then F.PositionMinimapButton()end
end
function F.BuildNavigator()
  local c=S.Panel(UIParent,0,0,328,170);F.compass=c;c:ClearAllPoints()
  local position=F.char.navPosition
  if position then c:SetPoint(position.point,UIParent,position.point,position.x,position.y)
  else c:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-270,-300)end
  c:SetFrameStrata("MEDIUM");c:SetClampedToScreen(true);c:SetMovable(true);c:EnableMouse(true);c:RegisterForDrag("LeftButton")
  c:SetScript("OnDragStart",c.StartMoving);c:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing();local point,_,_,x,y=self:GetPoint();F.char.navPosition={point=point,x=x,y=y}
  end)
  S.Text(c,"THE COURIER'S COMPASS",14,-12,290,"GameFontNormalSmall",S.gold)
  c.arrow=c:CreateTexture(nil,"ARTWORK");c.arrow:SetTexture("Interface\\Minimap\\MinimapArrow");c.arrow:SetPoint("TOPLEFT",16,-40);c.arrow:SetSize(48,48)
  c.distance=S.Text(c,"",8,-95,68,"GameFontNormalSmall",S.gold);c.distance:SetJustifyH("CENTER")
  c.action=S.Text(c,"",79,-38,236,"GameFontNormalSmall",S.gold)
  c.writ=S.Text(c,"",79,-58,234,"GameFontHighlight")
  c.recipient=S.Text(c,"",79,-93,232,"GameFontHighlightSmall",S.muted)
  c.location=S.Text(c,"",14,-119,300,"GameFontHighlightSmall",S.muted)
  c.writ:SetHeight(32);c.recipient:SetHeight(24)
  c.expand=S.Button(c,unfold,10,-140,196,function()
    F.char.navExpanded=not F.char.navExpanded;F.UpdateNavigator()
  end)
  S.Button(c,"Ledger",214,-140,104,function()F.window:SetShown(not F.window:IsShown())end)
  c.map=F.CreateTravelMap(c,12,-177,304,202)
  c.legend=S.Text(c,"Gold: travel  •  Blue: flight  •  Numbers: customers",14,-389,300,"GameFontDisableSmall")
  c.map:EnableMouse(true);c.map:SetScript("OnMouseUp",function(_,button)
    if button=="LeftButton" and F.guidance then F.Navigate(F.guidance.stop.point,F.guidance.stop.questID)end
  end)
  if Minimap then
    local b=CreateFrame("Button","ForeverWaylaidMinimapButton",Minimap);F.minimapButton=b
    b:SetSize(33,33);b:SetFrameStrata("MEDIUM");b:SetFrameLevel(Minimap:GetFrameLevel()+15)
    local bg=b:CreateTexture(nil,"BACKGROUND");bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background");bg:SetAllPoints()
    local icon=b:CreateTexture(nil,"ARTWORK");icon:SetTexture(S.icons.crate);icon:SetPoint("CENTER",0,0);icon:SetSize(22,22)
    local border=b:CreateTexture(nil,"OVERLAY");border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");border:SetSize(54,54);border:SetPoint("TOPLEFT",-1,1)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b:RegisterForClicks("LeftButtonUp","RightButtonUp");b:RegisterForDrag("LeftButton")
    F.PositionMinimapButton=function()
      local angle=math.rad(F.char.minimapAngle or 220);local radius=Minimap:GetWidth()/2+9
      b:ClearAllPoints();b:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*radius,math.sin(angle)*radius)
    end
    b:SetScript("OnDragStart",function(self)
      self:SetScript("OnUpdate",function()
        local x,y=GetCursorPosition();local cx,cy=Minimap:GetCenter();local scale=Minimap:GetEffectiveScale()
        F.char.minimapAngle=math.deg(G.Atan2(y/scale-cy,x/scale-cx));F.PositionMinimapButton()
      end)
    end)
    b:SetScript("OnDragStop",function(self)self:SetScript("OnUpdate",nil)end)
    b:SetScript("OnClick",function(_,button)
      if button=="RightButton" then F.db.settings.navigator=not F.db.settings.navigator;F.UpdateNavigator()
      else F.window:SetShown(not F.window:IsShown())end
    end)
    b:SetScript("OnEnter",function(self)
      GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:SetText("Forever Waylaid")
      GameTooltip:AddLine("Left-click: open your ledger",1,0.85,0.5)
      GameTooltip:AddLine("Right-click: show / hide compass",1,1,1)
      GameTooltip:AddLine("Drag: move around the minimap",0.7,0.7,0.7);GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function()GameTooltip:Hide()end);F.PositionMinimapButton()
    F.minimapOverlay=F.CreateRouteOverlay(Minimap);F.minimapOverlay:SetFrameLevel(Minimap:GetFrameLevel()+4)
  end
  F.ready=true
end
function F.UpdateNavigator()
  local c=F.compass;if not c then return end
  c:SetShown(F.db.settings.navigator)
  local expanded=F.char.navExpanded
  c:SetHeight(expanded and 413 or 170);c.map:SetShown(expanded);c.legend:SetShown(expanded)
  c.expand:SetText(expanded and fold or unfold)
  local guide=F.guidance
  if guide then
    c.action:SetText(guide.action)
    c.writ:SetText(guide.stop.writ.name:gsub("^Craftsman's Writ: ",""))
    c.recipient:SetText(guide.stop.npc or guide.stop.deliveryText or "Recipient: see quest details")
    c.location:SetText(F.DestinationText(guide.target))
  else
    c.action:SetText("Awaiting a delivery")
    c.writ:SetText(#(F.active or {})>0 and "Your writ needs a customer location" or "Accept a writ to start your route")
    c.recipient:SetText("Open the ledger for requirements")
    c.location:SetText("Drag the frame to move your compass")
  end
  if expanded then F.UpdateTravelMap(c.map)end
  F.UpdateCompassPose()
end
function F.UpdateCompassPose()
  local c=F.compass;if not c or not c:IsShown()then return end
  local player=F.Route.Player();local guide=F.guidance
  local angle=guide and G.Bearing(player,guide.target,GetPlayerFacing and GetPlayerFacing() or 0)
  c.arrow:SetShown(angle~=nil)
  if angle then
    c.arrow:SetRotation(angle)
    local yards=F.Route.Distance(player,guide.target)
    c.distance:SetText(yards<20 and "Arrived" or yards>999 and string.format("%.1f kyd",yards/1000) or math.floor(yards).." yd")
  else c.distance:SetText("—")end
  if F.char.navExpanded then F.DrawTravelRoute(c.map)end
end
function F.DrawMinimap()
  local overlay=F.minimapOverlay;if not overlay then return end
  overlay:SetShown(F.db.settings.minimapRoute)
  if not F.db.settings.minimapRoute then return end
  local player=F.Route.Player();if not player then F.ClearRouteOverlay(overlay);return end
  local radius=C_Minimap and C_Minimap.GetViewRadius and C_Minimap.GetViewRadius()
  if not radius or radius<=0 then
    local outdoor={466.6667,400,333.3333,266.6667,200,133.3333};local indoor={300,240,180,120,80,50}
    local zoom=Minimap:GetZoom();local inside=GetCVar and tonumber(GetCVar("minimapZoom"))~=zoom
    radius=(inside and indoor or outdoor)[zoom+1] or 200;radius=radius/2
  end
  local w,h=Minimap:GetWidth(),Minimap:GetHeight();local facing=GetCVar and GetCVar("rotateMinimap")=="1" and GetPlayerFacing() or 0
  local function project(point)
    local x,y=G.Relative(player,point,facing);if not x then return end
    return w/2+x/radius*w/2,h/2-y/radius*h/2
  end
  local square=GetMinimapShape and GetMinimapShape()=="SQUARE"
  local function clip(a,b,c,d)
    if square then return G.Rect(a,b,c,d,4,4,w-4,h-4)end
    local x,y,u,v=G.Circle(a-w/2,b-h/2,c-w/2,d-h/2,math.min(w,h)/2-5)
    if x then return x+w/2,y+h/2,u+w/2,v+h/2 end
  end
  local function inside(x,y)
    return square and x>=5 and x<=w-5 and y>=5 and y<=h-5 or not square and (x-w/2)^2+(y-h/2)^2<=(math.min(w,h)/2-7)^2
  end
  F.DrawRouteOverlay(overlay,project,clip,inside,false,true)
end
