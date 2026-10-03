local _,F=...
local S,G=F.Style,F.Geometry
local unfold="|TInterface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up:18:18|t"
local fold="|TInterface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up:18:18|t"
function F.TrackDelivery(questID)
  -- Selection opens the route; it must not lock the compass to a customer
  -- and override the planner's order for the remaining deliveries.
  F.char.navQuest=nil;F.db.settings.navigator=true;F.Refresh()
end
function F.UpdateGuidance()
  F.char.navQuest=nil -- Retire persisted single-writ navigation locks.
  local chosen=F.route and F.route[1] and F.route[1].stop
  local player=F.Route.Player()
  if not chosen or not player then F.guidance=nil;F.flightGuidance=nil;return end
  -- Keep the booked flight's arrival target while on the taxi. Replanning from
  -- an airborne position can otherwise direct the player back to departure.
  if UnitOnTaxi and UnitOnTaxi("player") and F.flightGuidance and F.flightGuidance.stop.questID==chosen.questID then
    F.guidance=F.flightGuidance;F.guidance.action="In flight";return
  end
  F.flightGuidance=nil
  -- Keep the itinerary's resource decision when updating the live arrow.
  -- Otherwise a locally faster hearth here could spend the one saved for
  -- the next delivery by the complete-round planner.
  local travel=F.travel
  local planned=F.route[1].steps
  if travel and planned then
    local allowed={}
    for _,step in ipairs(planned) do
      local detail=step.detail
      if detail and detail.resource then allowed[detail.id or detail.resource]=true end
    end
    travel={links=travel.links,resources=travel.resources,personal={}}
    for _,entry in ipairs(F.travel.personal or {}) do
      if allowed[entry.id or entry.resource] then travel.personal[#travel.personal+1]=entry end
    end
  end
  local seconds,steps=F.Route.Leg(player,chosen.point,F.GetRoutingFlights(),F.db.settings.flights,travel)
  if seconds==math.huge then F.guidance=nil;return end
  local target,action,flight,flightIndex=chosen.point,"Deliver to customer",nil,nil
  for index,step in ipairs(steps)do
    if step.mode=="Fly" then
      flight,flightIndex=step,index
      if F.Route.Distance(player,step.from)>25 then target,action=step.from,"Go to flight master"
      else target,action=step.from,"Take flight to "..(step.to.name or "next stop") end
      break
    elseif step.mode~="Travel" then
      target=step.from
      local personal=step.detail and step.detail.resource
      if personal then
        local wait=step.detail.wait or 0
        action=wait>1 and ("Wait "..math.ceil(wait/60).."m: "..step.mode) or ("Use "..step.mode)
      else
        local mode=step.mode:lower()
        action=F.Route.Distance(player,step.from)>35 and ("Go to "..mode.." boarding point") or ("Board "..mode)
      end
      break
    end
  end
  F.guidance={stop=chosen,target=target,action=action,origin=player,travelTarget=target,travelAction=action,steps=steps,seconds=seconds,flight=flight}
  local walk={}
  for _,step in ipairs(steps)do
    if step.mode~="Travel" then break end
    walk[#walk+1]=step
  end
  F.guidance.walkSteps=walk;F.guidance.walkIndex=1
  F.AdvanceRoadGuidance(F.guidance,player)
  for _,step in ipairs(steps)do
    if step.mode~="Travel" then F.guidance.nextStep=step;break end
  end
  if flight then
    local remaining={}
    for index=flightIndex,#steps do remaining[#remaining+1]=steps[index]end
    F.flightGuidance={stop=chosen,target=flight.to,action="In flight",steps=remaining,seconds=seconds,flight=flight,nextStep=flight}
  end
end
function F.RefreshMovingGuidance()
  local guide=F.guidance
  if not guide then return end
  local flying=UnitOnTaxi and UnitOnTaxi("player") or false
  if flying~=(guide.action=="In flight") then
    F.UpdateGuidance();F.UpdateNavigator();return
  end
  if not guide.origin or flying then return end
  local player=F.Route.Player()
  if not player or F.Route.Distance(player,guide.origin)<3 then return end
  -- Replan only the active leg. Full delivery ordering remains on the
  -- normal refresh/event schedule; standing still does no extra path work.
  F.UpdateGuidance()
  F.UpdateNavigator()
end
function F.AdvanceRoadGuidance(guide,player)
  local walk=guide.walkSteps or {}
  local index=guide.walkIndex or 1
  local function passed(step)
    if F.Route.Distance(player,step.to)<4 then return true end
    if not player or player.instance~=step.from.instance or player.instance~=step.to.instance then return false end
    local dx,dy=step.to.wx-step.from.wx,step.to.wy-step.from.wy
    local length2=dx*dx+dy*dy
    if length2<0.01 then return true end
    local x,y=player.wx-step.from.wx,player.wy-step.from.wy
    return x*dx+y*dy>=length2 and (x*dy-y*dx)^2/length2<=64
  end
  while index<=#walk and passed(walk[index])do index=index+1 end
  guide.walkIndex=index
  local step=walk[index]
  if step then
    if step.road=="mapped" then
      guide.target=step.to;guide.action=step.terrain=="corridor" and "Cross open ground" or "Follow the road"
      guide.roadWarning=step.terrain=="corridor" and "Approximate open-ground route. Enemies and small obstacles are not tracked." or nil
    elseif step.road=="transition" then
      guide.target=step.to;guide.action="Continue through the pass"
      guide.roadWarning="Zone handoff: the passage itself is not traced. Faint dots show direction only; follow the entrance and terrain."
    else
      guide.target=step.to;guide.action=step.to.cityGate and "Go to city gate" or step.road=="approach" and walk[index+1] and walk[index+1].road=="mapped" and "Join the mapped road" or "Direction only"
      guide.roadWarning="This approach has no mapped walking path. Faint dots show direction only; follow the terrain around obstacles."
    end
  elseif guide.travelTarget then
    guide.target=guide.travelTarget;guide.action=guide.travelAction;guide.roadWarning=nil
  end
end
function F.DisplayRoute(player,segments,stops)
  -- Renderers provide their own scratch arrays. Ordinary callers still get
  -- independent snapshots; no map can overwrite another map's route data.
  segments,stops=segments or {},stops or {}
  local segmentCount,stopCount=0,0
  local delivery,recipient
  player=player or F.Route.Player()
  local function segment(from,to,step,road,connectionFrom,connectionTo)
    segmentCount=segmentCount+1
    local row=segments[segmentCount] or {};segments[segmentCount]=row
    row.from,row.to,row.mode,row.detail=from,to,step.mode,step.detail
    row.road,row.delivery,row.recipient=road,delivery,recipient
    row.connectionFrom,row.connectionTo=connectionFrom,connectionTo
  end
  local function append(step)
    local from=step.from
    local connectionFrom=false
    for _,via in ipairs(step.detail and step.detail.via or {})do
      segment(from,via,step,nil,connectionFrom,step.mode=="Fly")
      from=via
      connectionFrom=step.mode=="Fly"
    end
    segment(from,step.to,step,step.road,connectionFrom,nil)
  end
  for i,leg in ipairs(F.route or {})do
    delivery,recipient=i,leg.stop
    local guide=i==1 and F.guidance and F.guidance.stop.questID==leg.stop.questID and F.guidance
    local steps=guide and guide.steps or leg.steps
    if guide and guide.walkSteps and player then F.AdvanceRoadGuidance(guide,player)end
    local walkCount=guide and guide.walkSteps and #guide.walkSteps or 0
    local first=guide and guide.walkIndex or 1
    for index,step in ipairs(steps)do
      if index>walkCount or index>=first then
        if player and index<=walkCount and index==first and player.instance==step.from.instance then
          -- Only trim the current walking segment. Keep every future bend,
          -- transport departure and later delivery anchored to its real point.
          local road=step.road
          if road=="mapped" then
            local dx,dy=step.to.wx-step.from.wx,step.to.wy-step.from.wy
            local length2=dx*dx+dy*dy
            local x,y=player.wx-step.from.wx,player.wy-step.from.wy
            local t=length2>0 and math.max(0,math.min(1,(x*dx+y*dy)/length2)) or 0
            if (x-t*dx)^2+(y-t*dy)^2>625 then road="unknown" end
          end
          append({from=player,to=step.to,mode=step.mode,detail=step.detail,road=road})
        else append(step)end
      end
    end
    stopCount=stopCount+1
    local row=stops[stopCount] or {};stops[stopCount]=row
    row.point,row.stop,row.number=leg.stop.point,leg.stop,i
  end
  for i=#segments,segmentCount+1,-1 do segments[i]=nil end
  for i=#stops,stopCount+1,-1 do stops[i]=nil end
  return segments,stops
end
function F.ResetNavigator()
  F.char.navPosition=nil;F.char.minimapAngle=220
  if F.compass then F.compass:ClearAllPoints();F.compass:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-270,-300)end
  if F.PositionMinimapButton then F.PositionMinimapButton()end
end
function F.BuildNavigator()
  local c=S.Panel(UIParent,0,0,300,126);F.compass=c;c:ClearAllPoints()
  local position=F.char.navPosition
  if position then c:SetPoint(position.point,UIParent,position.point,position.x,position.y)
  else c:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-270,-300)end
  c:SetFrameStrata("MEDIUM");c:SetClampedToScreen(true);c:SetMovable(true);c:EnableMouse(true);c:RegisterForDrag("LeftButton")
  c:SetScript("OnDragStart",c.StartMoving);c:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing();local point,_,_,x,y=self:GetPoint();F.char.navPosition={point=point,x=x,y=y}
  end)
  local stripe=c:CreateTexture(nil,"ARTWORK");stripe:SetPoint("TOPLEFT",5,-5);stripe:SetSize(290,19);S.Accent(stripe,0.55)
  F.compassStripe=stripe
  c.heading=S.Text(c,"COMPASS • ROUTES BETA",11,-9,214,"GameFontNormalSmall",S.gold)
  c.heading:SetMaxLines(1)
  c.hide=S.Button(c,"Hide",235,-5,56,function()
    F.db.settings.navigator=false;F.UpdateNavigator();GameTooltip:Hide()
  end)
  c.hide:SetHeight(22)
  c.hide:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:SetText("Hide compass")
    GameTooltip:AddLine("Show it again with Travel compass in the ledger, or right-click the minimap button.",1,1,1,true)
    GameTooltip:Show()
  end)
  c.hide:SetScript("OnLeave",function()GameTooltip:Hide()end)
  c.arrow=c:CreateTexture(nil,"ARTWORK");c.arrow:SetTexture("Interface\\Minimap\\MinimapArrow");c.arrow:SetPoint("TOPLEFT",10,-31);c.arrow:SetSize(40,40)
  c.distance=S.Text(c,"",5,-76,52,"GameFontNormalSmall",S.gold);c.distance:SetJustifyH("CENTER")
  c.action=S.Text(c,"",60,-29,230,"GameFontNormalSmall",S.gold);c.action:SetMaxLines(1)
  c.writ=S.Text(c,"",60,-44,230,"GameFontHighlightSmall");c.writ:SetHeight(28)
  c.recipient=S.Text(c,"",60,-76,230,"GameFontHighlightSmall",S.muted);c.recipient:SetMaxLines(1)
  c.location=S.Text(c,"",10,-98,192,"GameFontHighlightSmall",S.muted);c.location:SetMaxLines(1)
  c.empty=S.Text(c,"Accept a writ to start a route.",12,-35,182,"GameFontHighlightSmall",S.muted)
  c.flightNotice=S.Text(c,"Flight paths not scanned\nVisit a flight master to learn routes.",11,-76,278,"GameFontHighlightSmall",S.gold)
  c:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:SetText("Delivery route")
    GameTooltip:AddLine(F.routingBetaNotice,1,0.82,0,true)
    GameTooltip:AddLine("Larger delivery rounds can miss a shorter order. Dotted lines show direction, not a verified walking path.",1,0.82,0,true)
    local guide=F.guidance
    if guide then
      GameTooltip:AddLine(guide.stop.writ.name,1,1,1,true)
      if guide.roadWarning then GameTooltip:AddLine(guide.roadWarning,1,0.82,0,true)end
      for _,step in ipairs(guide.steps)do
        if step.mode~="Travel" then GameTooltip:AddLine(step.mode..": "..(step.to.name or F.DestinationText(step.to)),1,0.85,0.5,true)end
        local via=F.Travel.ViaText(step.detail)
        if via then GameTooltip:AddLine(via,1,0.85,0.5,true)end
        local note=F.Route.FlightNote(step)
        if note then GameTooltip:AddLine(note,1,0.82,0,true)end
      end
    end
    local warning=F.FlightCoverageText()
    if warning then GameTooltip:AddLine(warning,1,0.82,0,true)end
    GameTooltip:AddLine("Travel and waiting times are estimates. Follow roads and board transport manually.",0.8,0.8,0.8,true)
    GameTooltip:Show()
  end)
  c:SetScript("OnLeave",function()GameTooltip:Hide()end)
  c.expand=S.Button(c,unfold,210,-94,35,function()
    F.char.navExpanded=not F.char.navExpanded;F.UpdateNavigator()
  end)
  c.ledger=S.Button(c,"|TInterface\\Icons\\INV_Misc_Book_09:16:16|t",251,-94,35,function()F.window:SetShown(not F.window:IsShown())end)
  for _,button in ipairs({c.expand,c.ledger})do
    button:SetScript("OnEnter",function(self)
      GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:SetText(self==c.expand and "Show / hide route map" or "Open ledger");GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function()GameTooltip:Hide()end)
  end
  c.map=F.CreateTravelMap(c,8,-129,284,189)
  c.legend=S.Text(c,"Dots: walk • Faint dots: unverified",11,-324,280,"GameFontDisableSmall")
  c.map:EnableMouse(true);c.map:SetScript("OnMouseUp",function(_,button)
    if button=="LeftButton" and F.guidance then F.Navigate(F.guidance.stop.point,F.guidance.stop.questID)end
  end)
  if Minimap then
    local b=CreateFrame("Button","WaylaidForeverMinimapButton",Minimap);F.minimapButton=b
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
      GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:SetText("Waylaid Forever")
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
  local guide=F.guidance
  local large=S.MinimumTextSize()>=14
  local baseHeight=guide and (large and 156 or 126) or (large and 108 or 78)
  c.writ:ClearAllPoints();c.writ:SetPoint("TOPLEFT",60,large and -51 or -44);c.writ:SetHeight(large and 40 or 28)
  c.recipient:ClearAllPoints();c.recipient:SetPoint("TOPLEFT",60,large and -97 or -76)
  c.location:ClearAllPoints();c.location:SetPoint("TOPLEFT",10,large and -128 or -98)
  local missing=F.MissingFlightContinents()
  local needsScan=#missing>0
  local height=baseHeight+(needsScan and (large and 80 or 52) or 0)
  c.flightNotice:SetText(needsScan and ("Missing flights: "..table.concat(missing," / ").."\nRoutes may not be optimal.") or "")
  c.flightNotice:SetShown(needsScan)
  c.flightNotice:ClearAllPoints();c.flightNotice:SetPoint("TOPLEFT",11,-baseHeight+3)
  F.compassLayoutHeight=height+(expanded and (large and 238 or 212) or 0)
  c:SetHeight(F.compassLayoutHeight);c.map:SetShown(expanded);c.legend:SetShown(expanded)

  c:SetScale(F.AccessibleScale(F.db.settings.compassScale,300,F.compassLayoutHeight))
  c.expand:ClearAllPoints();c.expand:SetPoint("TOPLEFT",210,-baseHeight+32)
  c.ledger:ClearAllPoints();c.ledger:SetPoint("TOPLEFT",251,-baseHeight+32)
  c.map:ClearAllPoints();c.map:SetPoint("TOPLEFT",8,-height-3)
  c.legend:ClearAllPoints();c.legend:SetPoint("TOPLEFT",11,-height-198)
  c.expand:SetText(expanded and fold or unfold)
  c.empty:SetShown(not guide)
  for _,field in ipairs({c.action,c.writ,c.recipient,c.location,c.distance})do field:SetShown(guide~=nil)end
  if guide then
    c.action:SetText(guide.action)
    c.writ:SetText(guide.stop.writ.name:gsub("^Craftsman's Writ: ",""))
    c.recipient:SetText(guide.nextStep and ("To: "..(guide.nextStep.to.name or F.DestinationText(guide.nextStep.to))) or guide.stop.npc or guide.stop.deliveryText or "See quest for recipient")
    c.location:SetText(F.DestinationText(guide.target))
  else
    c.empty:SetText(#(F.active or {})>0 and "No route. Open the Route tab." or "Accept a writ from your bags.")
  end
  if expanded then F.UpdateTravelMap(c.map)end
  F.UpdateCompassPose()
end
function F.UpdateCompassPose()
  local c=F.compass;if not c or not c:IsShown()then return end
  local player=F.Route.Player();local guide=F.guidance
  if guide and guide.walkSteps and player and not (UnitOnTaxi and UnitOnTaxi("player")) then
    F.AdvanceRoadGuidance(guide,player)
    c.action:SetText(guide.action)
    c.location:SetText(F.DestinationText(guide.target))
  end
  local personal=guide and guide.nextStep and guide.nextStep.detail and guide.nextStep.detail.resource
  if personal and F.Route.Distance(player,guide.target)<25 then
    c.arrow:SetTexture(guide.nextStep.mode=="Hearthstone" and "Interface\\Icons\\INV_Misc_Rune_01" or "Interface\\Icons\\Spell_Arcane_TeleportOrgrimmar")
    c.arrow:SetRotation(0);c.arrow:Show();c.distance:SetText((guide.nextStep.detail.wait or 0)>1 and "Wait" or "Use")
    if F.char.navExpanded then F.DrawTravelRoute(c.map)end
    return
  end
  c.arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
  local angle=guide and G.Bearing(player,guide.target,GetPlayerFacing and GetPlayerFacing() or 0)
  c.arrow:SetShown(angle~=nil)
  if angle then
    local previous=type(c.heading)=="number" and c.heading or angle
    local delta=(angle-previous+math.pi)%(2*math.pi)-math.pi
    c.heading=previous+delta*0.35
    c.arrow:SetRotation(c.heading)
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
  F.DrawRouteOverlay(overlay,project,clip,inside,false,true,player)
end
