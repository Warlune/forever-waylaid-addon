local _,F=...
local P,S=F.Pets,F.Style
local atlas="Interface\\AddOns\\ForeverWaylaid\\Art\\WaylaidPets"
local icons={food="INV_Misc_Food_14",toy="INV_Misc_Bone_01",rest="Spell_Nature_Sleep",medicine="INV_Potion_51",adopt="INV_Egg_02",next="Ability_Hunter_BeastCall",fight="Ability_DualWield",pause="Spell_Frost_Stun",retreat="Ability_Rogue_Sprint",open="INV_Misc_Book_09",inspect="Ability_Hunter_EagleEye"}
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
local function fill(bar,value,label)bar:SetValue(value or 0);bar.label:SetText(label)end
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
    f.victory.detail:SetText("Floor "..result.floor..(result.first and " completed!" or " cleared again!").."\n+"..result.xp.." XP  |  +"..result.tokens.." tokens")
    f.victory.next:SetText(result.floor<100 and "Next floor" or "Done")
  end
end
local function stage(parent,x,y,width,height)
  local f=S.Panel(parent,x,y,width,height);f.width=width;f.height=height
  f.displayEnemies={};f.round=false;f.tower=false
  f.bg=f:CreateTexture(nil,"BACKGROUND");f.bg:SetPoint("TOPLEFT",3,-3);f.bg:SetPoint("BOTTOMRIGHT",-3,3)
  f.pet=sprite(f,height*0.88);f.enemies={};f.enemyHP={}
  for i=1,3 do f.enemies[i]=sprite(f,height*0.88);f.enemyHP[i]=meter(f,width*0.48+(i-1)*width*0.17,-36,width*0.15,"",{0.75,0.25,0.2})end
  f.enemy=f.enemies[1]
  f.leftHP=meter(f,10,-10,(width-30)/2,"",{0.25,0.65,0.4})
  f.rightHP=meter(f,width/2+5,-10,(width-30)/2,"",{0.75,0.25,0.2})
  f.float=text(f,"",10,-50,width-20,28,{1,0.85,0.3});f.float:SetJustifyH("CENTER")
  f.caption=text(f,"",8,-height+29,width-16,24,{1,1,1});f.caption:SetJustifyH("CENTER")
  local vw=math.min(width-16,350)
  f.victory=S.Panel(f,(width-vw)/2,-(height-144)/2,vw,144)
  local v=f.victory;v:SetFrameLevel(f:GetFrameLevel()+5);v:EnableMouse(true)
  v.title=text(v,"VICTORY!",8,-8,vw-16,26,S.gold);v.title:SetJustifyH("CENTER")
  v.detail=text(v,"",8,-40,vw-16,48,{1,1,1});v.detail:SetJustifyH("CENTER")
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
        fill(self.leftHP,event.hp/round.maxHP*100,"HP "..event.hp.." / "..round.maxHP)
        for i,e in ipairs(round.enemies)do fill(self.enemyHP[i],event.enemyHP[i]/e.maxHP*100,tostring(event.enemyHP[i]))end
      else self.float:SetText("")end
    else self.float:SetText("")end
    local bob=motion and math.floor(math.sin(t*2)*2) or 0
    self.pet:SetPoint("CENTER",self,"TOPLEFT",width*(self.tower and 0.23 or 0.5)+attack,-height*0.62+bob)
    for i,art in ipairs(self.enemies)do
      art:SetPoint("CENTER",self,"TOPLEFT",width*((self.enemyCount or 1)==1 and 0.73 or 0.54+(i-1)*0.17)-(event and event.actor==i and reply or 0),-height*0.65)
    end
    self.pet:SetVertexColor(1,event and event.actor~=0 and motion and 0.6 or 1,1)
    updateOutcome(self)
  end)
  return f
end
local function renderStage(f,pet,tower)
  f.tower=tower
  f.bg:SetTexture("Interface\\AddOns\\ForeverWaylaid\\Art\\PetScenes"..S.Faction(),"CLAMP","CLAMP","NEAREST")
  f.bg:SetTexCoord(tower and 0.5 or 0,tower and 1 or 0.5,0.2,0.8);f.bg:SetAlpha(S.HighContrast() and 0.25 or 1)
  local b=P.state.battle;local result=tower and P.CurrentVictory()
  local r=result and result.round or P.lastRound
  local recent=tower and r and r.enemy.floor==(P.floor or 1) and (result or (P.sceneClock or 0)-r.at<3)
  local age=r and (P.sceneClock or 0)-r.at or 9
  local step=recent and age<(r.duration or 0) and r.events[math.floor(age/0.55)+1]
  local enemies=tower and (b and b.enemies or recent and r.enemies or P.Enemies(P.floor or 1)) or {}
  f.round=(b or recent) and r or false;f.displayEnemies=enemies
  f.enemyCount=#enemies
  showPet(f.pet,pet or recent and r.pet)
  f.pet:SetSize(f.height*(tower and 0.65 or 0.88),f.height*(tower and 0.65 or 0.88))
  for i,art in ipairs(f.enemies)do
    local e=enemies[i];showPet(art,e,true)
    art:SetSize(f.height*(#enemies>1 and 0.44 or 0.65),f.height*(#enemies>1 and 0.44 or 0.65))
    f.enemyHP[i]:SetShown(e~=nil)
    f.enemyHP[i]:ClearAllPoints();f.enemyHP[i]:SetPoint("TOPLEFT",f,"TOPLEFT",f.width*(#enemies==1 and 0.65 or 0.48+(i-1)*0.17),-36)
    if e then local value=step and step.enemyHP[i] or e.hp or e.maxHP;fill(f.enemyHP[i],value/e.maxHP*100,tostring(value))end
  end
  f.leftHP:SetShown(tower);f.rightHP:Hide()
  if tower then
    if step then fill(f.leftHP,step.hp/r.maxHP*100,"HP "..step.hp.." / "..r.maxHP)
    else fill(f.leftHP,b and b.hp/b.maxHP*100 or pet and pet.health or 0,"Your pet: "..math.floor(pet and pet.health or 0).."%")end
    f.caption:SetText(b and (b.paused and "Paused" or "Round "..(b.turn+1).." - 1 vs "..#enemies) or "Floor "..(P.floor or 1).." - "..P.FloorStatus(P.floor or 1))
  else f.caption:SetText(pet and (pet.resting and "Resting at camp" or P.rarities[pet.rarity].." "..P.species[pet.species]) or "Your next companion awaits")end
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
    icon(parent,"fight","Fight",x,y,size,function()return P.StartBattle(P.floor or 1)end,"Fight one floor automatically. Your pet strikes, guards heavy attacks and uses healing herbs when needed. Defeat is permanent death."),
    icon(parent,"pause","Pause",x+gap,y,size,P.PauseBattle,"Pause or resume this pet battle. Hidden battle views pause automatically."),
    icon(parent,"retreat","Retreat",x+gap*2,y,size,function()return P.BattleAction('retreat')end,"Leave safely now. Spent supplies and lost health remain.")}
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
  m.scene=stage(m,8,-40,268,161)
  m.stats=text(m,"",10,-206,264,20);m.stats:SetJustifyH("CENTER")
  m.health=meter(m,10,-232,127,"",{0.25,0.65,0.4});m.food=meter(m,147,-232,127,"",{0.7,0.53,0.2})
  m.care=careIcons(m,20,-263,34,64);m.battle=fightIcons(m,37,-263,34,86);m.enter=m.battle[1]
  m.prev=S.Button(m,"<",10,-232,32,function()if not P.state.battle then P.floor=math.max(1,P.floor-1)end;P.Render()end)
  m.next=S.Button(m,">",242,-232,32,function()if not P.state.battle then P.floor=math.min(P.Unlocked(),P.floor+1)end;P.Render()end)
  m.floor=text(m,"",50,-233,184,22);m.floor:SetJustifyH("CENTER")
  m.notice=text(m,"",10,-324,264,24);m.notice:SetMaxLines(1)
  tip(m,"Companion",function()return P.notice or "Open the large view to adopt, switch companions and inspect other players."end)
  m.adopt=S.Button(m,"Adopt companion",49,-265,186,function()P.OpenAdopt()end)
  m:Hide()
end
function P.RenderCompass()
  local m=P.mini;if not m or not P.state or not m:IsShown()then return end
  local pet=P.Active();local tower=P.miniMode=="tower";local b=P.state.battle
  if not b then P.floor=math.max(1,math.min(P.floor or 1,P.Unlocked()))end
  renderStage(m.scene,pet,tower)
  m.stats:SetText(pet and ("Lv "..pet.level.." | XP "..pet.xp.." | "..P.state.tokens.." tokens") or "A new friend for your journey")
  fill(m.health,pet and pet.health or 0,"Health "..math.floor(pet and pet.health or 0));fill(m.food,pet and pet.food or 0,"Food "..math.floor(pet and pet.food or 0))
  m.health:SetShown(not tower);m.food:SetShown(not tower);m.prev:SetShown(tower);m.next:SetShown(tower);m.floor:SetShown(tower)
  m.floor:SetText("Floor "..(b and b.floor or P.floor).." | "..P.FloorStatus(b and b.floor or P.floor))
  for _,control in ipairs(m.care)do shown(control,not tower and pet~=nil)end
  for _,control in ipairs(m.battle)do shown(control,tower and pet~=nil)end
  m.enter:SetEnabled(not b);m.battle[2].label:SetText(b and b.paused and "Resume" or "Pause")
  m.enter.label:SetText(P.FloorStatus(P.floor)=="Completed" and "Replay" or "Fight")
  m.battle[2]:SetEnabled(b~=nil);m.battle[3]:SetEnabled(b~=nil)
  m.adopt:SetShown(pet==nil);m.notice:SetText(P.notice or "Hover an icon for details")
end
function P.BuildUI()
  if P.window then return end
  local w=S.Panel(UIParent,0,0,780,610);P.window=w;P.mode="collection";P.page=1;P.floor=P.floor or 1
  w:ClearAllPoints();w:SetPoint("CENTER");w:SetFrameStrata("HIGH");w:SetClampedToScreen(true);w:SetMovable(true);w:EnableMouse(true);w:RegisterForDrag("LeftButton")
  w:SetScript("OnDragStart",w.StartMoving);w:SetScript("OnDragStop",w.StopMovingOrSizing)
  local close=CreateFrame("Button",nil,w,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-3,-3);close:SetScript("OnClick",function()w:Hide()end)
  text(w,"WAYLAID COMPANIONS",22,-16,680,26)
  for i,mode in ipairs({"collection","tower","peers"})do local value=mode
    S.Button(w,({"Camp & stable","Tower","Inspect pets"})[i],20+(i-1)*158,-52,148,function()P.mode=value;P.page=1;P.Render()end)
  end
  S.Button(w,"Compass view",526,-52,230,function()w:Hide();P.ToggleCompass(true)end)
  w.scene=stage(w,20,-94,456,272)
  w.health=meter(w,20,-381,220,"",{0.25,0.65,0.4});w.food=meter(w,256,-381,220,"",{0.7,0.53,0.2})
  w.happy=meter(w,20,-414,220,"",{0.4,0.6,0.8});w.energy=meter(w,256,-414,220,"",{0.55,0.4,0.7})
  w.care=careIcons(w,50,-454,45,112);w.fight=fightIcons(w,75,-454,45,145)
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
  t.info=text(t,"",12,-12,232,98)
  S.Button(t,"<",12,-118,40,function()if not P.state.battle then P.floor=math.max(1,P.floor-1)end;P.Render()end)
  S.Button(t,">",204,-118,40,function()if not P.state.battle then P.floor=math.min(P.Unlocked(),P.floor+1)end;P.Render()end)
  t.floor=text(t,"",57,-120,142,24);t.floor:SetJustifyH("CENTER")
  text(t,"One floor per fight.\nAuto uses healing herbs.\nDefeat is permanent.\nPause or retreat anytime.",12,-166,232,96)
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
function P.OpenAdopt()
  if not P.adoption then
    local a=S.Panel(UIParent,0,0,820,680);P.adoption=a
    a:ClearAllPoints();a:SetPoint("CENTER");a:SetFrameStrata("DIALOG");a:SetClampedToScreen(true)
    local close=CreateFrame("Button",nil,a,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-3,-3);close:SetScript("OnClick",function()a:Hide()end)
    text(a,"ADOPT A COMPANION",22,-16,750,28)
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
      tip(c,"Pack contents","One of 84 Warcraft species, equally likely. Quality uses the exact odds shown. Raid bosses come only from raid rewards. Duplicate species are possible. These are virtual pet tokens, never gold or money.")
    end
    a.info=text(a,"",20,-534,778,44,S.muted)
    a.rescue=S.Button(a,"Free common rescue",20,-590,244,function()act(P.Rescue)end)
    a.claim=S.Button(a,"Claim raid companion",286,-590,270,function()act(function()return P.ClaimBoss(a.bossSpecies)end)end)
    a.close=S.Button(a,"Back to pets",578,-590,222,function()a:Hide()end)
    a.notice=text(a,"",20,-633,778,36);a.notice:SetMaxLines(2)
  end
  P.adoption:Show();P.RenderAdopt()
end
function P.RenderAdopt()
  local a=P.adoption;if not a or not a:IsShown() or not P.state then return end
  a:SetScale(F.AccessibleScale(F.db.settings.ledgerScale,820,680))
  local s=P.state
  for i,c in ipairs(a.cards)do
    c.open:SetText(s.packs[i]>0 and "Open earned pack - free" or "Adopt - "..P.packs[i].cost.." tokens")
    c.open:SetEnabled(not s.battle and (s.packs[i]>0 or s.tokens>=P.packs[i].cost) and P.LivingCount()<100 and #s.pets<512)
    c.owned:SetText("Owned: "..s.packs[i])
  end
  local seen,count={},0;for _,pet in ipairs(s.pets)do if not seen[pet.species]then seen[pet.species]=true;count=count+1 end end
  a.info:SetText(s.tokens.." tokens | "..count.." / 100 species found\nEarn tokens through tower clears, time online and dungeon/raid bosses.")
  a.rescue:SetEnabled(P.LivingCount()==0 and not s.battle)
  a.bossSpecies=false;for i=85,100 do if (s.bossEggs[i] or 0)>0 then a.bossSpecies=i;break end end
  a.claim:SetEnabled(not not a.bossSpecies and not s.battle and P.LivingCount()<100)
  tip(a.claim,"Raid companion",a.bossSpecies and ("Claim epic "..P.species[a.bossSpecies]..". Other waiting boss companions remain saved.") or "Supported raid bosses have a 5% chance to grant their own epic companion. One roll per boss per seven days.")
  a.notice:SetText(P.notice or "Choose a pack to adopt. Your equipped pet stays with you.")
end
function P.Render()
  P.RenderAdopt();P.RenderCompass();local w=P.window;if not w or not P.state or not w:IsShown()then return end
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
  w.fight[1]:SetEnabled(not s.battle and pet~=nil);w.fight[2].label:SetText(s.battle and s.battle.paused and "Resume" or "Pause")
  w.fight[1].label:SetText(P.FloorStatus(P.floor)=="Completed" and "Replay" or "Fight")
  w.fight[2]:SetEnabled(s.battle~=nil);w.fight[3]:SetEnabled(s.battle~=nil)
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
    w.tower.info:SetText((e.boss and "BOSS CHAMBER" or "THE NEXT CHALLENGE").."\n"..P.species[e.species].." | "..e.maxHP.." HP\n"..P.FloorStatus(floor).." | Best: "..(pet and pet.best or 0))
    w.tower.floor:SetText("Floor "..floor.." / 100")
  end
  w.notice:SetText(P.notice or "Care for a companion. Explore together. Face the tower when ready.")
  w.stock:SetText(s.tokens.." tokens | Treats "..s.inventory.food.." | Toys "..s.inventory.toy.." | Herbs "..s.inventory.medicine)
end
