local _,F=...

function F.CommonRouteMap(a,b)
  if not a then return b end
  if not b then return a end
  local ancestors,seen={},{}
  local current=a
  for _=1,15 do
    if not current or current==0 or ancestors[current] then break end
    ancestors[current]=true
    local info=C_Map.GetMapInfo(current);current=info and info.parentMapID
  end
  current=b
  for _=1,15 do
    if not current or current==0 or seen[current] then break end
    if ancestors[current] then return current end
    seen[current]=true
    local info=C_Map.GetMapInfo(current);current=info and info.parentMapID
  end
  return a
end

-- Group road bends into human-sized stages, keeping deliveries and separate
-- transport boardings distinct. The displayed segments are disposable copies.
function F.BuildJourney(segments)
  local stages={}
  for _,step in ipairs(segments)do
    local a,b=step.from,step.to
    local stationary=step.mode=="Travel" and (a==b or (a.wx and b.wx and a.instance==b.instance
      and (a.wx-b.wx)^2+(a.wy-b.wy)^2<0.01))
    if not stationary then
      local stage=stages[#stages]
      if not stage or stage.mode~=step.mode or stage.delivery~=step.delivery
        or (step.mode~="Travel" and (not step.detail or stage.detail~=step.detail)) then
        stage={number=#stages+1,mode=step.mode,from=step.from,to=step.to,
          delivery=step.delivery,recipient=step.recipient,detail=step.detail,points={step.from}}
        stages[#stages+1]=stage
      end
      stage.to=step.to;stage.points[#stage.points+1]=step.to
      stage.unmapped=stage.unmapped or (step.mode=="Travel" and step.road~="mapped")
      step.stage=stage.number
    end
  end
  return stages
end

function F.JourneyPlace(point)
  if not point then return "Destination" end
  local info=point.mapID and C_Map.GetMapInfo(point.mapID)
  return point.name or (info and info.name) or "Destination"
end
function F.JourneyMode(stage)
  return stage.mode=="Travel" and "Walk" or stage.mode=="Fly" and "Flight" or stage.mode
end
function F.JourneyTitle(stage)
  local destination=F.JourneyPlace(stage.to)
  if stage.recipient and stage.to==stage.recipient.point then
    destination="Turn-in: "..(stage.recipient.npc or destination)
  end
  return stage.number..". "..F.JourneyMode(stage).." > "..destination
end
function F.JourneyTooltip(stage,owner)
  GameTooltip:SetOwner(owner,"ANCHOR_RIGHT");GameTooltip:SetText(F.JourneyTitle(stage))
  GameTooltip:AddLine("From: "..F.JourneyPlace(stage.from),1,1,1,true)
  local recipient=stage.recipient
  if recipient then
    GameTooltip:AddLine("Delivery "..(stage.delivery or 1)..": "..(recipient.writ and recipient.writ.name or "Writ"),1,0.85,0.5,true)
    if recipient.npc then GameTooltip:AddLine(recipient.npc,1,1,1,true)end
  end
  if stage.unmapped then
    GameTooltip:AddLine("Includes unmapped walking. Dashed lines on the overview show direction only; follow the terrain locally.",1,0.82,0,true)
  elseif stage.mode~="Travel" then
    GameTooltip:AddLine("Transport line shows the connection, not the vehicle's exact path.",0.8,0.8,0.8,true)
  end
  GameTooltip:AddLine("Click to view this stage.",0.8,0.8,0.8,true);GameTooltip:Show()
end
function F.JourneyMap(stages,stops)
  local map
  for _,stage in ipairs(stages)do for _,point in ipairs(stage.points)do map=F.CommonRouteMap(map,point.mapID)end end
  for _,stop in ipairs(stops or {})do map=F.CommonRouteMap(map,stop.point.mapID)end
  return map
end

function F.CreateJourneyPanel(map,overlay)
  local S=F.Style
  local panel=S.Panel(map.ScrollContainer,0,0,322,242)
  panel:ClearAllPoints();panel:SetPoint("BOTTOMLEFT",map.ScrollContainer,"BOTTOMLEFT",8,8)
  panel:EnableMouse(true);panel.page=1;panel.collapsed=false;panel.rows={}
  panel.header=S.Button(panel,"Full journey",8,-8,204,function()
    panel.collapsed=not panel.collapsed;F.UpdateJourneyPanel(panel,map,overlay)
  end)
  panel.overview=S.Button(panel,"Overview",218,-8,96,function()
    local id=F.JourneyMap(overlay.journey or {},overlay.journeyStops)
    if id then map:SetMapID(id)end
  end)
  for index=1,3 do
    local row=CreateFrame("Button",nil,panel);row:SetPoint("TOPLEFT",10,-40-(index-1)*45);row:SetSize(302,43)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
    row.title=S.Text(row,"",2,-2,298,"GameFontNormal",S.gold);row.title:SetMaxLines(1)
    row.info=S.Text(row,"",2,-22,298,"GameFontHighlightSmall",S.muted);row.info:SetMaxLines(1)
    row:SetScript("OnEnter",function(self)if self.stage then F.JourneyTooltip(self.stage,self)end end)
    row:SetScript("OnLeave",function()GameTooltip:Hide()end)
    row:SetScript("OnClick",function(self)
      local id=self.stage and F.JourneyMap({self.stage})
      if id then map:SetMapID(id)end
    end)
    panel.rows[index]=row
  end
  panel.previous=S.Button(panel,"<",10,-177,38,function()panel.page=panel.page-1;F.UpdateJourneyPanel(panel,map,overlay)end)
  panel.next=S.Button(panel,">",274,-177,38,function()panel.page=panel.page+1;F.UpdateJourneyPanel(panel,map,overlay)end)
  panel.pageLabel=S.Text(panel,"",58,-182,212,"GameFontHighlightSmall");panel.pageLabel:SetJustifyH("CENTER")
  panel.legend=S.Text(panel,"Dashed walk = direction only",10,-213,302,"GameFontHighlightSmall",S.muted)
  panel.legend:SetMaxLines(1)
  panel:Hide();return panel
end

function F.UpdateJourneyPanel(panel,map,overlay)
  local stages=overlay.journey or {}
  panel:SetShown(F.db.settings.worldRoute and #stages>0)
  if not F.db.settings.worldRoute or #stages==0 then return end
  local manager=map.GetPinFrameLevelsManager and map:GetPinFrameLevelsManager()
  local top=manager and manager.GetValidFrameLevel and manager:GetValidFrameLevel("PIN_FRAME_LEVEL_TOPMOST")
  panel:SetFrameLevel((top or overlay:GetFrameLevel())+10)
  panel:SetHeight(panel.collapsed and 42 or 242)
  panel.header:SetText((panel.collapsed and "+ " or "- ").."Full journey ("..#stages..")")
  local pages=math.max(1,math.ceil(#stages/3));panel.page=math.max(1,math.min(panel.page,pages))
  for index,row in ipairs(panel.rows)do
    row.stage=stages[(panel.page-1)*3+index] or false
    row:SetShown(not panel.collapsed and row.stage~=false)
    if row.stage then
      row.title:SetText(F.JourneyTitle(row.stage))
      local stage=row.stage
      row.info:SetText("Delivery "..(stage.delivery or 1).." / "..(stage.unmapped and "Includes unmapped walk" or stage.mode=="Travel" and "Mapped walk" or "Transport connection"))
    end
  end
  panel.previous:SetShown(not panel.collapsed);panel.next:SetShown(not panel.collapsed)
  panel.previous:SetEnabled(panel.page>1);panel.next:SetEnabled(panel.page<pages)
  panel.pageLabel:SetShown(not panel.collapsed);panel.pageLabel:SetText(panel.page.." / "..pages.."  •  Click a stage")
  panel.legend:SetShown(not panel.collapsed)
end
