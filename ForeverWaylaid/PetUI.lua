local _,F=...
local P,S=F.Pets,F.Style
local atlas="Interface\\AddOns\\ForeverWaylaid\\Art\\WaylaidPets"
local icons={food="INV_Misc_Food_14",toy="INV_Misc_Bone_01",rest="Spell_Nature_Sleep",medicine="INV_Potion_51",adopt="INV_Egg_02",next="Ability_Hunter_BeastCall",fight="Ability_DualWield",pause="Spell_Frost_Stun",open="INV_Misc_Book_09",inspect="Ability_Hunter_EagleEye"}
local function text(parent,value,x,y,width,height,color)
  local t=S.Text(parent,value,x,y,width,"GameFontHighlightSmall",color or S.gold);t:SetHeight(height);return t
end
local function sprite(parent,size)
  local art=parent:CreateTexture(nil,"ARTWORK");art:SetSize(size,size);art:SetTexture(atlas,"CLAMP","CLAMP","NEAREST");return art
end
local function showPet(art,pet,flip)
  art:SetShown(not not pet);if not pet then return end
  local entry=F.PetData.species[pet.species];local grid=entry.atlas==0 and 2 or 4
  art:SetTexture(entry.atlas==0 and atlas or "Interface\\AddOns\\ForeverWaylaid\\Art\\PetRoster"..entry.atlas,"CLAMP","CLAMP","NEAREST")
  local col=entry.cell%grid;local row=math.floor(entry.cell/grid)
  art:SetTexCoord((col+(flip and 1 or 0))/grid,(col+(flip and 0 or 1))/grid,row/grid,(row+1)/grid)
  art:SetDesaturated(pet.deadAt~=nil)
end
local function act(fn)local ok,message=fn();if not ok and message then P.notice=message end;P.Render()end
local function tip(frame,title,body)
  frame:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(title)
    GameTooltip:AddLine(type(body)=="function" and body() or body,1,1,1,true);GameTooltip:Show()
  end)
  frame:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
local function icon(parent,key,label,x,y,size,fn,help)
  local b=CreateFrame("Button",nil,parent);b:SetPoint("TOPLEFT",x,y);b:SetSize(size,size)
  b:SetNormalTexture("Interface\\Icons\\"..icons[key]);b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
  local border=b:CreateTexture(nil,"OVERLAY");border:SetTexture("Interface\\Buttons\\UI-Quickslot2");border:SetPoint("CENTER");border:SetSize(size*1.6,size*1.6)
  b.label=text(parent,label,x-10,y-size-3,size+20,20);b.label:SetJustifyH("CENTER")
  b:SetScript("OnClick",function()act(fn)end);tip(b,label,help or label)
  return b
end
local function shown(b,value)b:SetShown(value);b.label:SetShown(value)end
local function meter(parent,x,y,width,label,color)
  local b=CreateFrame("StatusBar",nil,parent);b:SetPoint("TOPLEFT",x,y);b:SetSize(width,19)
  b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");b:SetMinMaxValues(0,100);b:SetStatusBarColor(unpack(color))
  local bg=b:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(0,0,0,0.9)
  b.label=text(b,label,4,0,width-8,19,{1,1,1});return b
end
local function frameHealth(bar)
  local frame=CreateFrame("Frame",nil,bar,"BackdropTemplate")
  frame:SetPoint("TOPLEFT",-4,4);frame:SetPoint("BOTTOMRIGHT",4,-4)
  frame:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=3,right=3,top=3,bottom=3}})
  frame:SetBackdropBorderColor(0.72,0.68,0.56,1);frame:EnableMouse(false)
  bar.healthFrame=frame
  bar.label:SetShadowColor(0,0,0,1);bar.label:SetShadowOffset(1,-1)
end
local function fill(bar,value,label)bar:SetValue(value or 0);bar.label:SetText(label)end
-- Decorative copies of Forever's target-frame geometry. Never inherit a
-- secure unit template or register a fake pet as a real game unit.
local function unitFrame(parent)
  local f=CreateFrame("Frame",nil,parent);f:SetSize(232,100);f:EnableMouse(true)
  local portraitBG=f:CreateTexture(nil,"BACKGROUND")
  portraitBG:SetColorTexture(0.06,0.05,0.04,1);portraitBG:SetSize(58,58);portraitBG:SetPoint("TOPRIGHT",-26,-19)
  f.portrait=sprite(f,58);f.portrait:SetDrawLayer("BACKGROUND",1);f.portrait:SetPoint("TOPRIGHT",-26,-19)
  local mask=f:CreateMaskTexture();mask:SetAtlas("CircleMask");mask:SetAllPoints(f.portrait)
  f.portrait:AddMaskTexture(mask);portraitBG:AddMaskTexture(mask)
  local content=CreateFrame("Frame",nil,f);content:SetAllPoints();content:SetFrameLevel(f:GetFrameLevel()+1)
  f.nameplate=content:CreateTexture(nil,"BACKGROUND");f.nameplate:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Type",true);f.nameplate:SetPoint("TOPRIGHT",-75,-25)
  f.hp=meter(content,22,-40,126,"",{0,0.85,0})
  f.hp:SetHeight(20);f.hp:GetStatusBarTexture():SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Bar-Health")
  f.hp.label:Hide()
  f.resource=meter(content,22,-61,134,"",{0.9,0.7,0.1});f.resource:SetHeight(10);f.resource.label:Hide()
  -- Artwork above the fills keeps the original beveled edges and portrait ring.
  local trim=CreateFrame("Frame",nil,f);trim:SetAllPoints();trim:SetFrameLevel(f:GetFrameLevel()+3);trim:EnableMouse(false)
  f.healthFrame=trim
  local border=trim:CreateTexture(nil,"ARTWORK");border:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn",true);border:SetPoint("CENTER")
  f.eliteDragon=trim:CreateTexture(nil,"OVERLAY",nil,1)
  f.eliteDragon:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold",true);f.eliteDragon:SetPoint("TOPRIGHT",-11,-7);f.eliteDragon:Hide()
  local circle=trim:CreateTexture(nil,"OVERLAY",nil,2);circle:SetAtlas("UI-HUD-UnitFrame-SmallCircle",true);circle:SetPoint("BOTTOMRIGHT",-13,7)
  f.name=text(trim,"",26,-25,119,14,S.gold);f.name:SetMaxLines(1)
  f.percent=text(trim,"",24,-42,47,16,{1,1,1})
  f.amount=text(trim,"",70,-42,76,16,{1,1,1});f.amount:SetJustifyH("RIGHT")
  f.detail=text(trim,"",24,-61,122,10,{1,1,1});f.detail:SetJustifyH("CENTER")
  f.level=text(trim,"",0,0,30,22,S.gold);f.level:ClearAllPoints();f.level:SetPoint("CENTER",circle,"CENTER",0,0);f.level:SetJustifyH("CENTER")
  for _,label in ipairs({f.name,f.percent,f.amount,f.detail,f.level})do
    label:SetShadowColor(0,0,0,1);label:SetShadowOffset(1,-1)
  end
  tip(f,"Tower companion",function()return f.tooltip or ""end)
  f:Hide();return f
end
local function healthValue(f,current,maximum)
  maximum=math.max(1,maximum or 1);current=math.max(0,math.min(maximum,current or 0))
  f.hp:SetValue(current/maximum*100)
  f.percent:SetText(math.floor(current/maximum*100).."%")
  f.amount:SetText(tostring(math.floor(current)))
  f.tooltip=(f.unitName or "Companion").."\nHealth: "..math.floor(current).." / "..maximum..(f.isEnemy and "\nTower floor "..f.unitLevel or "\nLevel "..f.unitLevel)..(f.isElite and "\nElite" or "")
end
local function unitInfo(f,unit,enemy)
  if not unit then f:Hide();return end
  f.unitName=P.species[unit.species];f.unitLevel=unit.level or unit.floor
  f.isEnemy=enemy;f.isElite=not not unit.elite
  showPet(f.portrait,unit)
  f.name:SetText(f.unitName);f.level:SetText(f.unitLevel)
  f.nameplate:SetVertexColor(enemy and 0.8 or 0.1,enemy and 0.05 or 0.5,0.05)
  f.eliteDragon:SetShown(f.isElite)
  f.resource:SetValue(enemy and 0 or unit.energy or 0)
  f.detail:SetText(enemy and (f.isElite and "ELITE" or "Enemy "..unit.index) or "Energy "..math.floor(unit.energy or 0))
end
-- Small pixel glyphs stay sharp without requiring a particular font or new artwork.
local function pixelMark(parent,rows,color)
  local mark=CreateFrame("Frame",nil,parent);mark:SetSize(#rows[1]*2,#rows*2)
  for y,row in ipairs(rows)do for x=1,#row do if row:sub(x,x)=="1" then
    local shadow=mark:CreateTexture(nil,"ARTWORK");shadow:SetColorTexture(0,0,0,0.85);shadow:SetSize(3,3);shadow:SetPoint("TOPLEFT",(x-1)*2+1,-(y-1)*2-1)
    local pixel=mark:CreateTexture(nil,"OVERLAY");pixel:SetColorTexture(unpack(color));pixel:SetSize(2,2);pixel:SetPoint("TOPLEFT",(x-1)*2,-(y-1)*2)
  end end end
  mark:EnableMouse(true);mark:Hide();return mark
end
local function buildNeeds(f)
  f.needs={sleep={}}
  for i=1,3 do
    local z=pixelMark(f,{"11111","00010","00100","01000","11111"},{0.7,0.85,1,1})
    tip(z,"Sleeping","Resting restores energy, and restores health while food is at least 25. Click Rest to wake.")
    f.needs.sleep[i]=z
  end
  f.needs.hungry=pixelMark(f,{"11000000","01100000","00110000","00011000","00110000","01100000","00110000","00011000"},{1,0.8,0.25,1})
  tip(f.needs.hungry,"Hungry","Food is below 25. Feed your pet; below 10 food it loses health.")
  f.needs.angry=pixelMark(f,{"00010001000","00010001000","11110001111","00000000000","00000000000","11110001111","00010001000","00010001000"},{1,0.35,0.25,1})
  tip(f.needs.angry,"Unhappy","Happiness is below 25. Play with your pet using a chew toy.")
end
local function updateNeeds(f,t,motion)
  local pet=f.needsPet
  local alive=pet and not pet.deadAt and not f.tower
  local cx,cy=f.width*0.5,-f.height*0.62
  local head=cy+f.height*0.28
  for i,z in ipairs(f.needs.sleep)do
    local visible=alive and pet.resting
    z:SetShown(not not visible)
    if visible then
      local phase=motion and (t/2.4+(i-1)/3)%1 or (i-1)/3
      z:SetPoint("CENTER",f,"TOPLEFT",math.floor(cx+f.width*0.14+phase*18),math.floor(head+phase*24))
      z:SetAlpha(motion and math.min(1,phase*6,(1-phase)*6) or 1)
    end
  end
  local hungry=alive and (pet.food or 100)<25
  local angry=alive and (pet.happy or 100)<25
  f.needs.hungry:SetShown(not not hungry);f.needs.angry:SetShown(not not angry)
  if hungry then f.needs.hungry:SetPoint("CENTER",f,"TOPLEFT",math.floor(cx-f.width*0.17+(motion and math.sin(t*5)*2 or 0)),math.floor(cy))end
  if angry then
    f.needs.angry:SetPoint("CENTER",f,"TOPLEFT",math.floor(cx-f.width*0.15),math.floor(head+(motion and math.sin(t*3)*2 or 0)))
  end
end
local function updateOutcome(f)
  local now=P.sceneClock or 0
  for i,art in ipairs(f.enemies)do
    local enemy=f.displayEnemies[i]
    local alpha=1
    if enemy and enemy.defeatedAt and now>=enemy.defeatedAt then
      alpha=F.db.settings.reduceMotion and 0 or math.max(0,1-(now-enemy.defeatedAt)/0.65)
    end
    art:SetAlpha(alpha)
    if enemy then f.enemyHP[i]:SetShown(alpha>0)end
  end
  local result=f.tower and P.CurrentVictory()
  local visible=result and not result.dismissed and now>=result.readyAt
  f.victory:SetShown(not not visible)
  if visible then
    f.victory.title:SetText(result.floor==100 and "TOWER CONQUERED" or "VICTORY!")
    f.victory.detail:SetText("Floor "..result.floor..(result.first and " completed!" or " cleared again!").."\n+"..result.xp.." XP  |  +"..result.tokens.." tokens"..((result.treats or 0)>0 and "\n+1 trail treat" or ""))
    f.victory.next:SetText(result.floor<100 and "Next floor" or "Done")
  end
end
local function stage(parent,x,y,width,height)
  local f=S.Panel(parent,x,y,width,height);f.width=width;f.height=height
  f.displayEnemies={};f.round=false;f.tower=false
  -- Above the BackdropTemplate's fill, below the ARTWORK pet sprites.
  f.bg=f:CreateTexture(nil,"BORDER",nil,1);f.bg:SetPoint("TOPLEFT",6,-6);f.bg:SetPoint("BOTTOMRIGHT",-6,6)
  f.pet=sprite(f,height*0.88);f.enemies={};f.enemyHP={}
  buildNeeds(f)
  for i=1,3 do f.enemies[i]=sprite(f,height*0.88);f.enemyHP[i]=unitFrame(f)end
  f.enemy=f.enemies[1]
  f.leftHP=unitFrame(f)

  f.float=text(f,"",10,-50,width-20,28,{1,0.85,0.3});f.float:SetJustifyH("CENTER")
  f.caption=text(f,"",8,-height+29,width-16,24,{1,1,1});f.caption:SetJustifyH("CENTER")
  local vw=math.min(width-16,350)
  f.victory=S.Panel(f,(width-vw)/2,-(height-144)/2,vw,144)
  local v=f.victory;v:SetFrameLevel(f:GetFrameLevel()+5);v:EnableMouse(true)
  v.title=text(v,"VICTORY!",8,-8,vw-16,26,S.gold);v.title:SetJustifyH("CENTER")
  v.detail=text(v,"",8,-35,vw-16,62,{1,1,1});v.detail:SetJustifyH("CENTER")
  v.next=S.Button(v,"Next floor",(vw-166)/2,-105,166,function()
    local result=P.CurrentVictory();if not result then return end
    result.dismissed=true
    if result.floor<100 then P.floor=result.floor+1 end
    P.Render()
  end)
  v:Hide()
  f:SetScript("OnUpdate",function(self)
    local t=P.sceneClock or 0;local round=self.round;local age=round and t-round.at or 9
    local motion=not F.db.settings.reduceMotion;local attack=0;local reply=0;local event
    if self.tower and round and age<(round.duration or 1.6) then
      event=round.events and round.events[math.floor(age/0.55)+1]
      if event then
        local offset=motion and math.sin((age%0.55)/0.55*math.pi)*width*0.055 or 0
        attack=event.actor==0 and offset or 0;reply=event.actor~=0 and offset or 0
        self.float:SetText((event.actor==0 and "Pet: " or "Enemy "..event.actor..": ")..event.label..(event.amount>0 and " "..event.amount or ""))
        healthValue(self.leftHP,event.hp,round.maxHP)
        for i,e in ipairs(round.enemies)do healthValue(self.enemyHP[i],event.enemyHP[i],e.maxHP)end
      else self.float:SetText("")end
    else self.float:SetText("")end
    local bob=motion and math.floor(math.sin(t*2)*2) or 0
    local actorY=self.tower and -(self.hudHeight+self.arenaHeight*0.52) or -self.height*0.62
    self.pet:SetPoint("CENTER",self,"TOPLEFT",width*(self.tower and 0.23 or 0.5)+attack,actorY+bob)
    for i,art in ipairs(self.enemies)do
      art:SetPoint("CENTER",self,"TOPLEFT",width*((self.enemyCount or 1)==1 and 0.73 or 0.54+(i-1)*0.17)-(event and event.actor==i and reply or 0),actorY)
    end
    self.pet:SetVertexColor(1,event and event.actor~=0 and motion and 0.6 or 1,1)
    updateNeeds(self,t,motion)
    updateOutcome(self)
  end)
  return f
end
local function renderStage(f,pet,tower)
  f.tower=tower;f.needsPet=pet or false
  f.victory:ClearAllPoints();f.victory:SetPoint("CENTER",f,"CENTER")
  f.bg:SetTexture("Interface\\AddOns\\ForeverWaylaid\\Art\\PetScenes"..S.Faction()..".tga","CLAMP","CLAMP","NEAREST")
  f.bg:SetTexCoord(tower and 0.5 or 0,tower and 1 or 0.5,0.2,0.8);f.bg:SetAlpha(S.HighContrast() and 0.25 or 1)
  local b=P.state.battle;local result=tower and P.CurrentVictory()
  local r=result and result.round or P.lastRound
  local recent=tower and r and r.enemy.floor==(P.floor or 1) and (result or (P.sceneClock or 0)-r.at<3)
  local age=r and (P.sceneClock or 0)-r.at or 9
  local step=recent and age<(r.duration or 0) and r.events[math.floor(age/0.55)+1]
  local enemies=tower and (b and b.enemies or recent and r.enemies or P.Enemies(P.floor or 1)) or {}
  f.round=(b or recent) and r or false;f.displayEnemies=enemies
  f.enemyCount=#enemies
  local shownPet=pet or recent and r.pet
  local scale=(f.width-12)/464
  local rows=#enemies>1 and 2 or 1
  f.hudHeight=tower and (rows*86*scale+8) or 0
  f.arenaHeight=f.height-f.hudHeight-26
  local function place(frame,column,row)
    frame:SetScale(scale);frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT",f,"TOPLEFT",(6+column*(f.width-12)/2)/scale,-row*86)
    -- Slightly larger type in the compass while keeping the native bar geometry.
    local path=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    for _,label in ipairs({frame.name,frame.percent,frame.amount,frame.level})do
      label:SetFont(path,scale<0.7 and 16 or 12,"OUTLINE")
    end
    frame.detail:SetFont(path,scale<0.7 and 13 or 10,"OUTLINE")
  end
  place(f.leftHP,0,0);unitInfo(f.leftHP,shownPet,false)
  showPet(f.pet,shownPet)
  local petSize=tower and math.min(f.height*0.65,f.arenaHeight*0.95) or f.height*0.88
  f.pet:SetSize(petSize,petSize)
  for i,art in ipairs(f.enemies)do
    local e=enemies[i];showPet(art,e,true)
    local size=math.min(f.height*(#enemies>1 and 0.44 or 0.65),f.arenaHeight*0.85)*(e and e.elite and 1.15 or 1)
    art:SetSize(size,size)
    local bar=f.enemyHP[i]
    place(bar,i==2 and 0 or 1,i>1 and 1 or 0)
    unitInfo(bar,e,true);bar:SetShown(e~=nil)
    if e then healthValue(bar,step and step.enemyHP[i] or e.hp or e.maxHP,e.maxHP)end
  end
  f.leftHP:SetShown(tower and shownPet~=nil)
  -- The elite label now lives inside the native frame's lower strip.
  f.float:ClearAllPoints();f.float:SetPoint("TOPLEFT",10,-f.hudHeight+4)
  if tower then
    local maxHP=b and b.maxHP or shownPet and P.Stats(shownPet) or 1
    if step then healthValue(f.leftHP,step.hp,r.maxHP)
    elseif shownPet then healthValue(f.leftHP,b and b.hp or math.floor(maxHP*(shownPet.health or 0)/100),maxHP)end
    f.caption:SetText(b and (b.paused and "Paused" or "Round "..(b.turn+1).." - 1 vs "..#enemies) or "Floor "..(P.floor or 1).." - "..P.FloorStatus(P.floor or 1))
  else f.caption:SetText(pet and (pet.resting and "Resting at camp" or P.rarities[pet.rarity].." "..P.species[pet.species]) or "Your next companion awaits")end
  updateNeeds(f,P.sceneClock or 0,not F.db.settings.reduceMotion)
  updateOutcome(f)
end
local function careIcons(parent,x,y,size,gap)
  local result={}
  for i,entry in ipairs({{"food","Feed"},{"toy","Play"},{"rest","Rest"},{"medicine","Heal"}})do
    local key=entry[1]
    result[i]=icon(parent,key,entry[2],x+(i-1)*gap,y,size,function()return P.UseCare(key)end,function()
      local item=P.items[key]
      return item and (item.name..": "..P.state.inventory[key].." in your bag. If empty, buy one for "..item.cost.." pet tokens and use it. No real gold.") or "Rest to recover energy and health while fed. Click again to wake."
    end)
  end
  return result
end
local function fightIcons(parent,x,y,size,gap)
  return {
    icon(parent,"fight","Fight",x,y,size,function()return P.StartBattle(P.floor or 1)end,function()
      local _,message=P.BattleReadiness(P.floor or 1)
      return message.."\nAttacks and guards are automatic; healing requires your click."
    end),
    icon(parent,"pause","Pause",x+gap,y,size,P.PauseBattle,"Pause or resume this pet battle. Hidden battle views pause automatically."),
    icon(parent,"medicine","Heal",x+gap*2,y,size,P.RequestHeal,function()
      local _,description=P.HealChoice()
      return description..". Takes your pet's next turn; faster enemies can attack first. A ready healing ability is used first, otherwise one herb, otherwise 4 tokens. Herbs/token healing restores 40% max HP. No automatic healing."
    end)}
end
function P.BattleVisible()
  return (P.window and P.window:IsShown() and P.mode=="tower") or (P.mini and P.mini:IsShown() and F.compass and F.compass:IsShown() and P.miniMode=="tower")
end
function P.ToggleCompass(show)
  F.char.navPets=show==nil and not F.char.navPets or show
  if F.char.navPets then F.char.navExpanded=false;F.db.settings.navigator=true end
  F.UpdateNavigator();P.Render()
end
function P.BuildCompass(parent)
  local m=S.Panel(parent,8,-129,284,356);P.mini=m;P.miniMode="care";P.floor=P.floor or 1
  m.careButton=S.Button(m,"Camp",8,-8,80,function()P.miniMode="care";P.Render()end)
  m.towerButton=S.Button(m,"Tower",98,-8,80,function()P.miniMode="tower";P.Render()end)
  S.Button(m,"Open",188,-8,86,function()P.BuildUI();P.window:Show();P.mode=P.miniMode=="tower" and "tower" or "collection";P.Render()end)
  m.scene=stage(m,8,-40,268,137)
  m.footer=CreateFrame("Frame",nil,m);m.footer:SetSize(284,356);m.footer:SetPoint("TOPLEFT")
  m.stats=text(m.footer,"",10,-182,264,20);m.stats:SetJustifyH("CENTER")
  m.readiness=text(m.footer,"",10,-205,264,22);m.readiness:SetJustifyH("CENTER");m.readiness:SetMaxLines(1)
  m.health=meter(m.footer,10,-208,127,"",{0.25,0.65,0.4});m.food=meter(m.footer,147,-208,127,"",{0.7,0.53,0.2})
  frameHealth(m.health)
  m.happy=meter(m.footer,10,-232,127,"",{0.4,0.6,0.8});m.energy=meter(m.footer,147,-232,127,"",{0.55,0.4,0.7})
  for _,entry in ipairs({{m.health,"Health"},{m.food,"Food"},{m.happy,"Happiness"},{m.energy,"Energy"}})do
    entry[1]:EnableMouse(true);tip(entry[1],entry[2],"Out of 100. Use Feed, Play, Rest or Heal to care for your companion.")
  end
  m.care=careIcons(m.footer,20,-263,34,64);m.battle=fightIcons(m.footer,37,-263,34,86);m.enter=m.battle[1]
  m.prev=S.Button(m.footer,"<",10,-232,32,function()if not P.state.battle then P.floor=math.max(1,P.floor-1)end;P.Render()end)
  m.next=S.Button(m.footer,">",242,-232,32,function()if not P.state.battle then P.floor=math.min(P.Unlocked(),P.floor+1)end;P.Render()end)
  m.floor=text(m.footer,"",50,-233,184,22);m.floor:SetJustifyH("CENTER")
  m.notice=text(m.footer,"",10,-324,178,24);m.notice:SetMaxLines(1)
  S.Button(m.footer,"Store",196,-321,78,function()P.OpenStore()end)
  tip(m,"Companion",function()return P.notice or "Open the large view to adopt, switch companions and inspect other players."end)
  m.adopt=S.Button(m.footer,"Adopt companion",49,-265,186,function()P.OpenAdopt()end)
  m:Hide()
end
function P.RenderCompass()
  local m=P.mini;if not m or not P.state or not m:IsShown()then return end
  local pet=P.Active();local tower=P.miniMode=="tower";local b=P.state.battle
  if not b then P.floor=math.max(1,math.min(P.floor or 1,P.Unlocked()))end
  local extra=tower and 90 or 0
  local layoutChanged=m.towerLayout~=tower;m.towerLayout=tower
  m:SetHeight(356+extra);m.footer:ClearAllPoints();m.footer:SetPoint("TOPLEFT",0,-extra)
  m.scene.height=137+extra;m.scene:SetHeight(m.scene.height)
  m.scene.caption:ClearAllPoints();m.scene.caption:SetPoint("TOPLEFT",8,-m.scene.height+29)
  renderStage(m.scene,pet,tower)
  m.stats:SetText(pet and ("Lv "..pet.level.." | XP "..pet.xp.." | "..P.state.tokens.." tokens") or "A new friend for your journey")
  fill(m.health,pet and pet.health or 0,"Health "..math.floor(pet and pet.health or 0));fill(m.food,pet and pet.food or 0,"Food "..math.floor(pet and pet.food or 0))
  fill(m.happy,pet and pet.happy or 0,"Happy "..math.floor(pet and pet.happy or 0));fill(m.energy,pet and pet.energy or 0,"Energy "..math.floor(pet and pet.energy or 0))
  m.happy:SetShown(not tower);m.energy:SetShown(not tower)
  m.health:SetShown(not tower);m.food:SetShown(not tower);m.prev:SetShown(tower);m.next:SetShown(tower);m.floor:SetShown(tower)
  m.floor:SetText("Floor "..(b and b.floor or P.floor).." | "..P.FloorStatus(b and b.floor or P.floor))
  local ready,_,summary=P.BattleReadiness(P.floor or 1)
  m.readiness:SetShown(tower);m.readiness:SetText(summary);S.TextColor(m.readiness,ready and {0.4,1,0.4} or S.gold)
  for _,control in ipairs(m.care)do shown(control,not tower and pet~=nil)end
  for _,control in ipairs(m.battle)do shown(control,tower and pet~=nil)end
  m.enter:SetEnabled(not b);m.battle[2].label:SetText(b and b.paused and "Resume" or "Pause")
  m.enter.label:SetText(P.FloorStatus(P.floor)=="Completed" and "Replay" or "Fight")
  m.battle[2]:SetEnabled(b~=nil);m.battle[3]:SetEnabled(b~=nil)
  m.battle[3].label:SetText(b and b.pendingHeal and "Queued" or "Heal")
  m.adopt:SetShown(pet==nil);m.notice:SetText(P.notice or "Hover an icon for details")
  if layoutChanged and F.char.navPets then F.UpdateNavigator()end
end
function P.BuildUI()
  if P.window then return end
  local w=S.Panel(UIParent,0,0,780,610);P.window=w;P.mode="collection";P.page=1;P.floor=P.floor or 1
  w:ClearAllPoints();w:SetPoint("CENTER");w:SetFrameStrata("DIALOG");w:SetFrameLevel(100);w:SetToplevel(true);w:SetClampedToScreen(true);w:SetMovable(true);w:EnableMouse(true);w:RegisterForDrag("LeftButton")
  w:SetScript("OnDragStart",w.StartMoving);w:SetScript("OnDragStop",w.StopMovingOrSizing)
  local close=CreateFrame("Button",nil,w,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-3,-3);close:SetScript("OnClick",function()w:Hide()end)
  text(w,"WAYLAID COMPANIONS",22,-16,680,26)
  for i,mode in ipairs({"collection","tower","peers"})do local value=mode
    S.Button(w,({"Camp & stable","Tower","Inspect pets"})[i],20+(i-1)*158,-52,148,function()P.mode=value;P.page=1;P.Render()end)
  end
  S.Button(w,"Store",526,-52,80,function()P.OpenStore()end)
  S.Button(w,"Compass view",616,-52,140,function()w:Hide();P.ToggleCompass(true)end)
  w.scene=stage(w,20,-94,456,272)
  w.health=meter(w,20,-381,220,"",{0.25,0.65,0.4});w.food=meter(w,256,-381,220,"",{0.7,0.53,0.2})
  frameHealth(w.health)
  w.happy=meter(w,20,-414,220,"",{0.4,0.6,0.8});w.energy=meter(w,256,-414,220,"",{0.55,0.4,0.7})
  w.care=careIcons(w,50,-454,45,112);w.fight=fightIcons(w,75,-454,45,145)
  w.readiness=text(w,"",20,-433,456,20);w.readiness:SetJustifyH("CENTER");w.readiness:SetMaxLines(1)
  w.side=S.Panel(w,492,-94,268,424)
  w.name=text(w.side,"",14,-14,240,46);w.meta=text(w.side,"",14,-60,240,82,S.muted)
  tip(w.side,"Pet progression","Tower victories earn XP. Your NPC kills give 3 XP; PvP kills give 10. Enemy levels must be within five of your character and not gray. Unknown or restricted levels give no XP. Up to 60 combat XP per minute; repeat target cooldown: five minutes.")
  tip(w.scene,"Companion details",function()
    local pet=P.Active()
    if P.mode=="collection" and P.viewID then for _,candidate in ipairs(P.state.pets)do if candidate.id==P.viewID then pet=candidate;break end end end
    if not pet then return "Adopt a companion to begin." end
    local ability=P.Ability(pet)
    return "XP: "..pet.xp.." / "..(pet.level==100 and "MAX" or 20+pet.level*5).."\nLifespan: "..P.Age(pet.age).."\n"..(ability and ability.ability.." - "..P.AbilityHelp(ability.effect) or "Stats only. Rare and higher unlock a special ability.")
  end)
  w.collection=S.Panel(w.side,6,-146,256,272);local c=w.collection;c.rows={}
  for i=1,3 do
    local row=CreateFrame("Button",nil,c);row:SetPoint("TOPLEFT",8,-8-(i-1)*60);row:SetSize(238,56)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD");row.art=sprite(row,52);row.art:SetPoint("TOPLEFT",0,0)
    row.info=text(row,"",55,-3,180,50)
    row:SetScript("OnClick",function(self)if self.petID then P.viewID=self.petID;P.Render()end end);c.rows[i]=row
  end
  S.Button(c,"<",8,-190,30,function()P.page=math.max(1,P.page-1);P.Render()end)
  S.Button(c,">",218,-190,30,function()P.page=P.page+1;P.Render()end)
  c.page=text(c,"",45,-192,168,24);c.page:SetJustifyH("CENTER")
  S.Button(c,"Adopt",8,-230,114,function()P.OpenAdopt()end)
  c.equip=S.Button(c,"Equip",134,-230,114,function()act(function()return P.Select(P.viewID)end)end)
  w.tower=S.Panel(w.side,6,-146,256,272);local t=w.tower
  tip(t,"Tower challenge",function()
    local floor=P.state.battle and P.state.battle.floor or P.floor
    return floor%10==0 and "An elite leads this fight: more health, damage and armor. Its heavy attack hits harder every third round. Prepare supplies and use Heal yourself." or "Clear this floor to unlock the next. Every tenth floor is an elite encounter."
  end)
  t.info=text(t,"",12,-12,232,98)
  S.Button(t,"<",12,-118,40,function()if not P.state.battle then P.floor=math.max(1,P.floor-1)end;P.Render()end)
  S.Button(t,">",204,-118,40,function()if not P.state.battle then P.floor=math.min(P.Unlocked(),P.floor+1)end;P.Render()end)
  t.floor=text(t,"",57,-120,142,24);t.floor:SetJustifyH("CENTER")
  text(t,"One floor per fight.\nClick Heal to save your pet.\nDefeat is permanent.\nPause to plan your next turn.",12,-166,232,96)
  w.social=S.Panel(w.side,6,-146,256,272);local p=w.social
  p.share=S.Button(p,"",8,-8,240,function()P.SetSharing(not P.state.share);P.Render()end)
  S.Button(p,"Inspect target",8,-48,240,function()act(P.InspectTarget)end)
  p.text=text(p,"",12,-94,232,126)
  S.Button(p,"<",8,-234,35,function()P.inspectName=nil;P.page=math.max(1,P.page-1);P.Render()end)
  S.Button(p,">",213,-234,35,function()P.inspectName=nil;P.page=P.page+1;P.Render()end)
  p.page=text(p,"",46,-236,164,24);p.page:SetJustifyH("CENTER")
  w.notice=text(w,"",22,-534,732,38);w.notice:SetMaxLines(2)
  w.stock=text(w,"",22,-580,732,22,S.muted)
  w:Hide()
end
function P.Toggle()P.BuildUI();P.window:SetShown(not P.window:IsShown());P.Render()end
function P.OpenStore()
  if not P.store then
    local w=S.Panel(UIParent,0,0,396,364);P.store=w
    w:ClearAllPoints();w:SetPoint("CENTER");w:SetFrameStrata("FULLSCREEN_DIALOG");w:SetFrameLevel(100);w:SetToplevel(true);w:EnableMouse(true);w:SetClampedToScreen(true)
    local close=CreateFrame("Button",nil,w,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-3,-3);close:SetScript("OnClick",function()w:Hide()end)
    text(w,"COMPANION SUPPLIES",16,-14,350,26)
    w.wallet=text(w,"",16,-46,364,24);w.rows={};w.buy={}
    for i,key in ipairs({"food","toy","medicine"})do
      local itemKey=key;local item=P.items[key];local y=-80-(i-1)*68
      local art=w:CreateTexture(nil,"ARTWORK");art:SetPoint("TOPLEFT",16,y);art:SetSize(34,34);art:SetTexture("Interface\\Icons\\"..icons[key])
      local label=text(w,"",60,y,204,48);w.rows[key]=label
      w.buy[key]=S.Button(w,"Buy 1",282,y-2,96,function()act(function()
        local ok,message=P.Buy(itemKey)
        if ok then P.notice="Bought "..P.items[itemKey].name..". Use its care icon or battle Heal when needed." end
        return ok,message
      end)end)
    end
    text(w,"2 tokens per 5 minutes online with a living equipped pet. Purchases add supplies; they do not use them.",16,-286,364,64,S.muted)
  end
  -- A separate stratum survives automatic raising of the top-level Pets window.
  if P.adoption then P.adoption:Hide()end
  P.store:Show();P.store:Raise();P.RenderStore()
end
function P.RenderStore()
  local w=P.store;if not w or not w:IsShown() or not P.state then return end
  w:SetScale(F.AccessibleScale(F.db.settings.ledgerScale,396,364))
  w.wallet:SetText(P.state.tokens.." pet tokens")
  for key,label in pairs(w.rows)do
    local item=P.items[key];label:SetText(item.name.."\n"..item.cost.." tokens | Owned: "..P.state.inventory[key])
    w.buy[key]:SetEnabled(P.state.tokens>=item.cost)
  end
end
function P.OpenAdopt()
  if not P.adoption then
    local a=S.Panel(UIParent,0,0,820,680);P.adoption=a
    a:ClearAllPoints();a:SetPoint("CENTER");a:SetFrameStrata("FULLSCREEN_DIALOG");a:SetFrameLevel(100);a:SetToplevel(true);a:EnableMouse(true);a:SetClampedToScreen(true)
    local close=CreateFrame("Button",nil,a,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-3,-3);close:SetScript("OnClick",function()a:Hide()end)
    text(a,"ADOPTION CRATES",22,-16,750,28)
    a.cards={}
    for i,pack in ipairs(P.packs)do
      local index=i;local x=16+((i-1)%2)*400;local y=-58-math.floor((i-1)/2)*156
      local c=S.Panel(a,x,y,388,146);a.cards[i]=c
      local art=c:CreateTexture(nil,"ARTWORK");art:SetPoint("TOPLEFT",10,-10);art:SetSize(32,32);art:SetTexture("Interface\\Icons\\"..pack.icon)
      text(c,pack.name,52,-10,326,30)
      local odds={};for rarity,chance in ipairs(pack.odds)do if chance>0 then odds[#odds+1]=P.rarities[rarity].." "..chance.."%"end end
      text(c,table.concat(odds,"  |  "),12,-47,364,56,{1,1,1})
      c.open=S.Button(c,"",12,-112,226,function()act(function()return P.Adopt(index)end)end)
      c.owned=text(c,"",248,-112,128,24)
      tip(c,"Adoption crate contents","One of 84 Warcraft species, equally likely. Quality uses the exact odds shown. Raid bosses come only from raid rewards. Duplicate species are possible. These are virtual pet tokens, never gold or money.")
    end
    a.info=text(a,"",20,-534,778,44,S.muted)
    a.rescue=S.Button(a,"Free common rescue",20,-590,244,function()act(P.Rescue)end)
    a.claim=S.Button(a,"Claim raid companion",286,-590,270,function()act(function()return P.ClaimBoss(a.bossSpecies)end)end)
    a.close=S.Button(a,"Back to pets",578,-590,222,function()a:Hide()end)
    a.notice=text(a,"",20,-633,778,36);a.notice:SetMaxLines(2)
  end
  if P.store then P.store:Hide()end
  P.adoption:Show();P.adoption:Raise();P.RenderAdopt()
end
function P.RenderAdopt()
  local a=P.adoption;if not a or not a:IsShown() or not P.state then return end
  a:SetScale(F.AccessibleScale(F.db.settings.ledgerScale,820,680))
  local s=P.state
  for i,c in ipairs(a.cards)do
    c.open:SetText(s.packs[i]>0 and "Open earned crate - free" or "Adopt - "..P.packs[i].cost.." tokens")
    c.open:SetEnabled(not s.battle and (s.packs[i]>0 or s.tokens>=P.packs[i].cost) and P.LivingCount()<100 and #s.pets<512)
    c.owned:SetText("Owned: "..s.packs[i])
  end
  local seen,count={},0;for _,pet in ipairs(s.pets)do if not seen[pet.species]then seen[pet.species]=true;count=count+1 end end
  a.info:SetText(s.tokens.." tokens | "..count.." / 100 species found\nEarn tokens from time with your pet, tower clears and bosses.")
  a.rescue:SetEnabled(P.LivingCount()==0 and not s.battle)
  a.bossSpecies=false;for i=85,100 do if (s.bossEggs[i] or 0)>0 then a.bossSpecies=i;break end end
  a.claim:SetEnabled(not not a.bossSpecies and not s.battle and P.LivingCount()<100)
  tip(a.claim,"Raid companion",a.bossSpecies and ("Claim epic "..P.species[a.bossSpecies]..". Other waiting boss companions remain saved.") or "Supported raid bosses have a 5% chance to grant their own epic companion. One roll per boss per seven days.")
  a.notice:SetText(P.notice or "Choose an adoption crate. Your equipped pet stays with you.")
end
function P.Render()
  P.RenderStore();P.RenderAdopt();P.RenderCompass();local w=P.window;if not w or not P.state or not w:IsShown()then return end
  w:SetScale(F.AccessibleScale(F.db.settings.ledgerScale,780,610))
  local s=P.state;local pet=P.Active();local tower=P.mode=="tower";local social=P.mode=="peers";local viewed=pet;local owner
  if not s.battle then P.floor=math.max(1,math.min(P.floor or 1,P.Unlocked()))end
  if social then
    local rows={};for name,entry in pairs(P.peers)do rows[#rows+1]={name=name,pet=entry}end
    table.sort(rows,function(a,b)return a.name:lower()<b.name:lower()end)
    if P.inspectName then for i,row in ipairs(rows)do if row.name==P.inspectName then P.page=i;break end end end
    P.page=math.max(1,math.min(P.page,math.max(1,#rows)));local row=rows[P.page];viewed=row and row.pet;owner=row and row.name
    w.social.share:SetText(s.share and "Sharing: ON" or "Sharing: OFF")
    w.social.text:SetText(viewed and (owner.."\nHighest floor: "..viewed.best.." / 100\nTower wins: "..viewed.wins.."\nAlive: "..P.Age(viewed.age)) or "Target an opted-in addon user, or browse shared guild/group pets.")
    w.social.page:SetText(#rows>0 and (P.page.." / "..#rows.." pets") or "No shared pets")
  end
  if not social and not tower and P.viewID then
    for _,candidate in ipairs(s.pets)do if candidate.id==P.viewID then viewed=candidate;break end end
  end
  renderStage(w.scene,viewed,tower)
  w.name:SetText(viewed and (P.rarities[viewed.rarity].." "..P.species[viewed.species]) or "Your adventure begins")
  S.TextColor(w.name,viewed and P.colors[viewed.rarity] or S.gold)
  if viewed then
    local hp,attack,armor,speed=P.Stats(viewed)
    local ability=P.Ability(viewed)
    w.meta:SetText((social and "Shared" or viewed.deadAt and "Memorial" or viewed.id==s.active and "EQUIPPED" or "Preview").." | Level "..viewed.level.."\nHP "..hp.." | Attack "..attack.."\nArmor "..armor.."% | Speed "..speed.."\n"..(ability and ability.ability or "Stats only"))
  else w.meta:SetText("Adopt a Warcraft companion.\n100 species to discover.")end
  fill(w.health,pet and pet.health or 0,"Health "..math.floor(pet and pet.health or 0).." / 100")
  fill(w.food,pet and pet.food or 0,"Food "..math.floor(pet and pet.food or 0).." / 100")
  fill(w.happy,pet and pet.happy or 0,"Happiness "..math.floor(pet and pet.happy or 0).." / 100")
  fill(w.energy,pet and pet.energy or 0,"Energy "..math.floor(pet and pet.energy or 0).." / 100")
  for _,b in ipairs({w.health,w.food,w.happy,w.energy})do b:SetShown(not social and viewed==pet)end
  for _,b in ipairs(w.care)do shown(b,not tower and not social and viewed==pet and pet~=nil)end
  for _,b in ipairs(w.fight)do shown(b,tower)end
  local ready,_,summary=P.BattleReadiness(P.floor or 1)
  w.readiness:SetShown(tower);w.readiness:SetText(summary);S.TextColor(w.readiness,ready and {0.4,1,0.4} or S.gold)
  w.fight[1]:SetEnabled(not s.battle and pet~=nil);w.fight[2].label:SetText(s.battle and s.battle.paused and "Resume" or "Pause")
  w.fight[1].label:SetText(P.FloorStatus(P.floor)=="Completed" and "Replay" or "Fight")
  w.fight[2]:SetEnabled(s.battle~=nil);w.fight[3]:SetEnabled(s.battle~=nil)
  w.fight[3].label:SetText(s.battle and s.battle.pendingHeal and "Queued" or "Heal")
  w.care[3].label:SetText(pet and pet.resting and "Wake" or "Rest")
  w.collection:SetShown(not tower and not social);w.tower:SetShown(tower);w.social:SetShown(social)
  if not tower and not social then
    w.collection.equip:SetEnabled(viewed~=nil and not viewed.deadAt and viewed.id~=s.active and not s.battle)
    w.collection.equip:SetText(viewed and viewed.id==s.active and "Equipped" or "Equip")
    local pages=math.max(1,math.ceil(#s.pets/3));P.page=math.min(P.page,pages);w.collection.page:SetText(P.page.." / "..pages)
    for i,row in ipairs(w.collection.rows)do local item=s.pets[(P.page-1)*3+i];row.petID=item and item.id;row:SetShown(item~=nil)
      if item then showPet(row.art,item);row.info:SetText(P.species[item.species].."\nLv "..item.level..(item.deadAt and " | Memorial" or item.id==s.active and " | Equipped" or ""));S.TextColor(row.info,P.colors[item.rarity])end
    end
  elseif tower then
    local b=s.battle;local floor=b and b.enemy.floor or P.floor;local e=b and b.enemy or P.Enemy(floor)
    w.tower.info:SetText((floor%10==0 and "ELITE CHAMBER" or "THE NEXT CHALLENGE").."\n"..P.species[e.species].." | "..e.maxHP.." HP\n"..P.FloorStatus(floor).." | Best: "..(pet and pet.best or 0))
    w.tower.floor:SetText("Floor "..floor.." / 100")
  end
  w.notice:SetText(P.notice or "Care for a companion. Explore together. Face the tower when ready.")
  w.stock:SetText(s.tokens.." tokens | Treats "..s.inventory.food.." | Toys "..s.inventory.toy.." | Herbs "..s.inventory.medicine)
end
