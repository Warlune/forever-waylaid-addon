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
  local col=(pet.species-1)%2;local row=math.floor((pet.species-1)/2)
  art:SetTexCoord((col+(flip and 1 or 0))/2,(col+(flip and 0 or 1))/2,row/2,(row+1)/2)
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
local function stage(parent,x,y,width,height)
  local f=S.Panel(parent,x,y,width,height);f.width=width;f.height=height
  f.bg=f:CreateTexture(nil,"BACKGROUND");f.bg:SetPoint("TOPLEFT",3,-3);f.bg:SetPoint("BOTTOMRIGHT",-3,3)
  f.pet=sprite(f,height*0.88);f.enemy=sprite(f,height*0.88)
  f.leftHP=meter(f,10,-10,(width-30)/2,"",{0.25,0.65,0.4})
  f.rightHP=meter(f,width/2+5,-10,(width-30)/2,"",{0.75,0.25,0.2})
  f.float=text(f,"",10,-50,width-20,28,{1,0.85,0.3});f.float:SetJustifyH("CENTER")
  f.caption=text(f,"",8,-height+29,width-16,24,{1,1,1});f.caption:SetJustifyH("CENTER")
  f:SetScript("OnUpdate",function(self)
    local t=P.sceneClock or 0;local round=P.lastRound;local age=round and t-round.at or 9
    local motion=not F.db.settings.reduceMotion;local attack=0;local reply=0
    if self.tower and round and age<1.3 then
      if motion then attack=age<0.45 and math.sin(age/0.45*math.pi)*width*0.09 or 0;reply=age>=0.6 and age<1.05 and math.sin((age-0.6)/0.45*math.pi)*width*0.07 or 0 end
      local value=age<0.6 and (round.hit>0 and "-"..round.hit or round.action=="guard" and "Guard" or "+"..round.heal) or round.hurt and "-"..round.hurt or "Victory!"
      self.float:SetText(value)
    else self.float:SetText("")end
    local bob=motion and math.floor(math.sin(t*2)*2) or 0
    self.pet:SetPoint("CENTER",self,"TOPLEFT",width*(self.tower and 0.28 or 0.5)+attack,-height*0.59+bob)
    self.enemy:SetPoint("CENTER",self,"TOPLEFT",width*0.73-reply,-height*0.59)
    self.pet:SetVertexColor(1,motion and self.tower and age>0.7 and age<0.85 and 0.5 or 1,1)
  end)
  return f
end
local function renderStage(f,pet,tower)
  f.tower=tower
  f.bg:SetTexture("Interface\\AddOns\\ForeverWaylaid\\Art\\PetScenes"..S.Faction(),"CLAMP","CLAMP","NEAREST")
  f.bg:SetTexCoord(tower and 0.5 or 0,tower and 1 or 0.5,0.2,0.8);f.bg:SetAlpha(S.HighContrast() and 0.25 or 1)
  local b=P.state.battle;local r=P.lastRound;local recent=tower and r and (P.sceneClock or 0)-r.at<3
  local enemy=tower and (b and b.enemy or recent and r.enemy or P.Enemy(P.floor or 1))
  showPet(f.pet,pet or recent and r.pet);showPet(f.enemy,enemy,true)
  f.leftHP:SetShown(tower);f.rightHP:SetShown(tower)
  if tower then
    fill(f.leftHP,b and b.hp/b.maxHP*100 or pet and pet.health or 0,"Your pet: "..math.floor(pet and pet.health or 0).."%")
    fill(f.rightHP,enemy and (enemy.hp or enemy.maxHP)/enemy.maxHP*100 or 0,"Enemy: "..math.floor(enemy and (enemy.hp or enemy.maxHP) or 0))
    f.caption:SetText(b and (b.paused and "Paused" or "Round "..(b.turn+1).." - auto battle") or "Floor "..(P.floor or 1).." / 100")
  else f.caption:SetText(pet and (pet.resting and "Resting at camp" or P.rarities[pet.rarity].." "..P.species[pet.species]) or "Your next companion awaits")end
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
  m.next=S.Button(m,">",242,-232,32,function()if not P.state.battle then P.floor=math.min(100,P.floor+1)end;P.Render()end)
  m.floor=text(m,"",50,-233,184,22);m.floor:SetJustifyH("CENTER")
  m.notice=text(m,"",10,-324,264,24);m.notice:SetMaxLines(1)
  tip(m,"Companion",function()return P.notice or "Open the large view to adopt, switch companions and inspect other players."end)
  m.adopt=S.Button(m,"Adopt companion",49,-265,186,function()act(P.Adopt)end)
  m:Hide()
end
function P.RenderCompass()
  local m=P.mini;if not m or not P.state or not m:IsShown()then return end
  local pet=P.Active();local tower=P.miniMode=="tower";local b=P.state.battle
  renderStage(m.scene,pet,tower)
  m.stats:SetText(pet and ("Lv "..pet.level.." | XP "..pet.xp.." | "..P.state.tokens.." tokens") or "A new friend for your journey")
  fill(m.health,pet and pet.health or 0,"Health "..math.floor(pet and pet.health or 0));fill(m.food,pet and pet.food or 0,"Food "..math.floor(pet and pet.food or 0))
  m.health:SetShown(not tower);m.food:SetShown(not tower);m.prev:SetShown(tower);m.next:SetShown(tower);m.floor:SetShown(tower)
  m.floor:SetText("Floor "..(b and b.enemy.floor or P.floor).." / 100")
  for _,control in ipairs(m.care)do shown(control,not tower and pet~=nil)end
  for _,control in ipairs(m.battle)do shown(control,tower and pet~=nil)end
  m.enter:SetEnabled(not b);m.battle[2].label:SetText(b and b.paused and "Resume" or "Pause")
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
  w.name=text(w.side,"",14,-14,240,46);w.meta=text(w.side,"",14,-66,240,66,S.muted)
  tip(w.side,"Pet progression","Tower victories earn XP. Your NPC kills give 3 XP; PvP kills give 10. Enemy levels must be within five of your character and not gray. Unknown or restricted levels give no XP. Up to 60 combat XP per minute; repeat target cooldown: five minutes.")
  w.collection=S.Panel(w.side,6,-146,256,272);local c=w.collection;c.rows={}
  for i=1,3 do
    local row=CreateFrame("Button",nil,c);row:SetPoint("TOPLEFT",8,-8-(i-1)*60);row:SetSize(238,56)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD");row.art=sprite(row,52);row.art:SetPoint("TOPLEFT",0,0)
    row.info=text(row,"",55,-3,180,50)
    row:SetScript("OnClick",function(self)if self.petID then act(function()return P.Select(self.petID)end)end end);c.rows[i]=row
  end
  S.Button(c,"<",8,-190,30,function()P.page=math.max(1,P.page-1);P.Render()end)
  S.Button(c,">",218,-190,30,function()P.page=P.page+1;P.Render()end)
  c.page=text(c,"",45,-192,168,24);c.page:SetJustifyH("CENTER")
  S.Button(c,"Adopt - 25 tokens*",8,-230,240,function()act(P.Adopt)end)
  w.tower=S.Panel(w.side,6,-146,256,272);local t=w.tower
  t.info=text(t,"",12,-12,232,98)
  S.Button(t,"<",12,-118,40,function()if not P.state.battle then P.floor=math.max(1,P.floor-1)end;P.Render()end)
  S.Button(t,">",204,-118,40,function()if not P.state.battle then P.floor=math.min(100,P.floor+1)end;P.Render()end)
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
function P.Render()
  P.RenderCompass();local w=P.window;if not w or not P.state or not w:IsShown()then return end
  w:SetScale(F.AccessibleScale(F.db.settings.ledgerScale,780,610))
  local s=P.state;local pet=P.Active();local tower=P.mode=="tower";local social=P.mode=="peers";local viewed=pet;local owner
  if social then
    local rows={};for name,entry in pairs(P.peers)do rows[#rows+1]={name=name,pet=entry}end
    table.sort(rows,function(a,b)return a.name:lower()<b.name:lower()end)
    if P.inspectName then for i,row in ipairs(rows)do if row.name==P.inspectName then P.page=i;break end end end
    P.page=math.max(1,math.min(P.page,math.max(1,#rows)));local row=rows[P.page];viewed=row and row.pet;owner=row and row.name
    w.social.share:SetText(s.share and "Sharing: ON" or "Sharing: OFF")
    w.social.text:SetText(viewed and (owner.."\nHighest floor: "..viewed.best.." / 100\nTower wins: "..viewed.wins.."\nAlive: "..P.Age(viewed.age)) or "Target an opted-in addon user, or browse shared guild/group pets.")
    w.social.page:SetText(#rows>0 and (P.page.." / "..#rows.." pets") or "No shared pets")
  end
  renderStage(w.scene,viewed,tower)
  w.name:SetText(viewed and (P.rarities[viewed.rarity].." "..P.species[viewed.species]) or "Your adventure begins")
  S.TextColor(w.name,viewed and P.colors[viewed.rarity] or S.gold)
  w.meta:SetText(viewed and ("Level "..viewed.level..(social and "" or " | XP "..viewed.xp.." / "..(viewed.level==100 and "MAX" or 20+viewed.level*5)).."\nAlive: "..P.Age(viewed.age)) or "Adopt your first companion.\n*Free when none are alive.")
  fill(w.health,pet and pet.health or 0,"Health "..math.floor(pet and pet.health or 0).." / 100")
  fill(w.food,pet and pet.food or 0,"Food "..math.floor(pet and pet.food or 0).." / 100")
  fill(w.happy,pet and pet.happy or 0,"Happiness "..math.floor(pet and pet.happy or 0).." / 100")
  fill(w.energy,pet and pet.energy or 0,"Energy "..math.floor(pet and pet.energy or 0).." / 100")
  for _,b in ipairs({w.health,w.food,w.happy,w.energy})do b:SetShown(not social)end
  for _,b in ipairs(w.care)do shown(b,not tower and not social)end
  for _,b in ipairs(w.fight)do shown(b,tower)end
  w.fight[1]:SetEnabled(not s.battle and pet~=nil);w.fight[2].label:SetText(s.battle and s.battle.paused and "Resume" or "Pause")
  w.care[3].label:SetText(pet and pet.resting and "Wake" or "Rest")
  w.collection:SetShown(not tower and not social);w.tower:SetShown(tower);w.social:SetShown(social)
  if not tower and not social then
    local pages=math.max(1,math.ceil(#s.pets/3));P.page=math.min(P.page,pages);w.collection.page:SetText(P.page.." / "..pages)
    for i,row in ipairs(w.collection.rows)do local item=s.pets[(P.page-1)*3+i];row.petID=item and item.id;row:SetShown(item~=nil)
      if item then showPet(row.art,item);row.info:SetText((item.deadAt and "Memorial: " or item.id==s.active and "Active: " or "")..P.species[item.species].."\nLv "..item.level.." | "..P.Age(item.age));S.TextColor(row.info,P.colors[item.rarity])end
    end
  elseif tower then
    local b=s.battle;local floor=b and b.enemy.floor or P.floor;local e=b and b.enemy or P.Enemy(floor)
    w.tower.info:SetText((e.boss and "BOSS CHAMBER" or "THE NEXT CHALLENGE").."\n"..P.species[e.species].." | "..e.maxHP.." HP\nYour best: "..(pet and pet.best or 0))
    w.tower.floor:SetText("Floor "..floor.." / 100")
  end
  w.notice:SetText(P.notice or "Care for a companion. Explore together. Face the tower when ready.")
  w.stock:SetText(s.tokens.." tokens | Treats "..s.inventory.food.." | Toys "..s.inventory.toy.." | Herbs "..s.inventory.medicine.." | Hover icons for details")
end
