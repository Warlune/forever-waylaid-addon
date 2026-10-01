local _,F=...
local P,S=F.Pets,F.Style
local atlas="Interface\\AddOns\\ForeverWaylaid\\Art\\WaylaidPets"
local function portrait(parent,size)
  local art=parent:CreateTexture(nil,"ARTWORK");art:SetSize(size,size);art:SetTexture(atlas,"CLAMP","CLAMP","NEAREST")
  return art
end
local function showPet(art,pet)
  art:SetShown(pet~=nil)
  if not pet then return end
  local col=(pet.species-1)%2;local row=math.floor((pet.species-1)/2)
  art:SetTexCoord(col/2,(col+1)/2,row/2,(row+1)/2)
  art:SetDesaturated(pet.deadAt~=nil)
end
local function act(fn)
  local ok,message=fn();if not ok and message then P.notice=message end;P.Render()
end
local function shell(name,width,height,title)
  local w=S.Panel(UIParent,0,0,width,height);w:ClearAllPoints();w:SetPoint("CENTER")
  w:SetFrameStrata("HIGH");w:SetClampedToScreen(true);w:SetMovable(true);w:EnableMouse(true);w:RegisterForDrag("LeftButton")
  w:SetScript("OnDragStart",w.StartMoving);w:SetScript("OnDragStop",w.StopMovingOrSizing)
  local close=CreateFrame("Button",nil,w,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-3,-3);close:SetScript("OnClick",function()w:Hide()end)
  S.Text(w,title,18,-15,width-55,"GameFontNormalLarge",S.gold)
  w:Hide();return w
end
function P.BuildUI()
  if P.window then return end
  local w=shell("Pets",760,570,"WAYLAID COMPANIONS");P.window=w;P.mode="collection";P.page=1;P.floor=1
  w.name=S.Text(w,"Adopt a companion",20,-50,220,"GameFontNormalLarge",S.gold)
  w.art=portrait(w,196);w.art:SetPoint("TOPLEFT",20,-74)
  w.age=S.Text(w,"",20,-270,220,"GameFontHighlightSmall",S.muted);w.age:SetHeight(40)
  local xpHelp=CreateFrame("Frame",nil,w);xpHelp:SetPoint("TOPLEFT",20,-270);xpHelp:SetSize(220,40);xpHelp:EnableMouse(true)
  xpHelp:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText("Growing your companion")
    GameTooltip:AddLine("Tower wins earn XP. Your NPC killing blows give 3 XP; PvP killing blows give 10. Your combat pet's kills count too.",1,1,1,true)
    GameTooltip:AddLine("Combat: up to 60 XP per minute, same target once per 5 minutes. Only your living active companion earns XP. Level cap: 100.",1,0.82,0,true);GameTooltip:Show()
  end)
  xpHelp:SetScript("OnLeave",function()GameTooltip:Hide()end)
  w.needs=S.Text(w,"",20,-318,220,"GameFontHighlight");w.needs:SetHeight(78)
  S.Button(w,"Feed",20,-401,103,function()act(function()return P.Care('food')end)end)
  S.Button(w,"Play",133,-401,103,function()act(function()return P.Care('toy')end)end)
  w.rest=S.Button(w,"Rest",20,-435,103,function()act(function()return P.Care('rest')end)end)
  S.Button(w,"Heal",133,-435,103,function()act(function()return P.Care('medicine')end)end)
  S.Button(w,"Pocket view",20,-477,216,function()w:Hide();P.pocket:Show();P.Render()end)
  w.stock=S.Text(w,"",20,-518,720,"GameFontHighlightSmall",S.gold);w.stock:SetHeight(38)
  for i,mode in ipairs({"collection","tower","peers"})do
    local selectedMode=mode
    S.Button(w,({"Stable","Tower","Social"})[i],260+(i-1)*157,-48,147,function()P.mode=selectedMode;P.page=1;P.Render()end)
  end
  w.collection=S.Panel(w,252,-88,488,342)
  local c=w.collection
  local adopt=S.Button(c,"Adopt (25 tokens)*",12,-12,214,function()act(P.Adopt)end)
  adopt:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText("Adopt a random companion")
    GameTooltip:AddLine("Common 55% / Uncommon 25% / Rare 14% / Epic 5% / Legendary 1%",1,1,1,true)
    GameTooltip:AddLine("Each of the four species is equally likely. Free when you have no living pets. Death is permanent.",1,0.82,0,true);GameTooltip:Show()
  end)
  adopt:SetScript("OnLeave",function()GameTooltip:Hide()end)
  S.Text(c,"*Free if no living pets",240,-18,230,"GameFontHighlightSmall",S.muted)
  c.rows={}
  for i=1,5 do
    local row=S.Button(c,"",12,-53-(i-1)*46,458,function()end);row:SetHeight(42)
    row:SetScript("OnClick",function(self)if self.petID then act(function()return P.Select(self.petID)end)end end)
    c.rows[i]=row
  end
  S.Button(c,"<",12,-293,50,function()P.page=math.max(1,P.page-1);P.Render()end)
  S.Button(c,">",420,-293,50,function()P.page=P.page+1;P.Render()end)
  c.page=S.Text(c,"",80,-299,320,"GameFontHighlightSmall");c.page:SetJustifyH("CENTER")
  w.tower=S.Panel(w,252,-88,488,342);local t=w.tower
  t.title=S.Text(t,"",14,-14,454,"GameFontNormalLarge",S.gold)
  t.stats=S.Text(t,"",14,-51,454,"GameFontHighlight");t.stats:SetHeight(95)
  t.warning=S.Text(t,"Defeat is permanent death. Retreat before health reaches zero.",14,-152,454,"GameFontHighlightSmall",S.gold);t.warning:SetHeight(40)
  S.Button(t,"< Floor",14,-202,100,function()if not P.state.battle then P.floor=math.max(1,P.floor-1);P.Render()end end)
  S.Button(t,"Next >",124,-202,100,function()if not P.state.battle then P.floor=math.min(100,P.floor+1);P.Render()end end)
  t.start=S.Button(t,"Enter tower",244,-202,224,function()act(function()return P.StartBattle(P.floor)end)end)
  for i,entry in ipairs({{'Strike','strike'},{'Guard','guard'},{'Special','burst'},{'Herbs','heal'}})do
    local action=entry[2];S.Button(t,entry[1],14+(i-1)*116,-244,106,function()act(function()return P.BattleAction(action)end)end)
  end
  S.Button(t,"Retreat",14,-290,454,function()act(function()return P.BattleAction('retreat')end)end)
  w.social=S.Panel(w,252,-88,488,342);local p=w.social
  p.share=S.Button(p,"",12,-12,458,function()P.SetSharing(not P.state.share);P.Render()end)
  p.text=S.Text(p,"",14,-54,458,"GameFontHighlightSmall");p.text:SetHeight(272)
  w.buyFood=S.Button(w,"Treat: 2",260,-441,147,function()act(function()return P.Buy('food')end)end)
  S.Button(w,"Toy: 3",417,-441,147,function()act(function()return P.Buy('toy')end)end)
  S.Button(w,"Herbs: 4",574,-441,147,function()act(function()return P.Buy('medicine')end)end)
  w.notice=S.Text(w,"",260,-474,480,"GameFontHighlightSmall",S.gold);w.notice:SetHeight(38)
  local pocket=shell("Pocket",234,292,"COMPANION");P.pocket=pocket
  pocket.art=portrait(pocket,140);pocket.art:SetPoint("TOP",0,-39)
  pocket.text=S.Text(pocket,"",12,-177,210,"GameFontHighlightSmall");pocket.text:SetHeight(55)
  S.Button(pocket,"Feed",12,-248,96,function()act(function()return P.Care('food')end)end)
  S.Button(pocket,"Open",120,-248,102,function()pocket:Hide();w:Show();P.Render()end)
  local elapsed=0
  pocket:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt
    local y=F.db.settings.reduceMotion and 0 or math.sin(elapsed*2)*2
    pocket.art:SetPoint("TOP",0,-39+y)
  end)
end
function P.Toggle()
  P.BuildUI();P.window:SetShown(not P.window:IsShown());P.Render()
end
function P.Render()
  if not P.window or not P.state then return end
  local w,s=P.window,P.state;local pet=P.Active()
  if not w:IsShown() and not P.pocket:IsShown()then return end
  showPet(w.art,pet);showPet(P.pocket.art,pet)
  w.name:SetText(pet and (P.rarities[pet.rarity].." "..P.species[pet.species]) or "Adopt a companion")
  S.TextColor(w.name,pet and P.colors[pet.rarity] or S.gold)
  w.age:SetText(pet and ("Lv "..pet.level.." • XP "..pet.xp.."/"..(pet.level==100 and "MAX" or 20+pet.level*5).."\nTime alive: "..P.Age(pet.age)) or "Stable pets and offline time\ndo not lose needs.")
  w.needs:SetText(pet and string.format("Health  %d / 100\nFood  %d / 100\nHappy  %d / 100\nEnergy  %d / 100",math.floor(pet.health),math.floor(pet.food),math.floor(pet.happy),math.floor(pet.energy)) or "Adopt a random pet.\nDeath is permanent.\nFirst replacement is free.")
  w.rest:SetText(pet and pet.resting and "Wake" or "Rest")
  w.stock:SetText(string.format("Pet tokens: %d   •   Treats: %d   Toys: %d   Herbs: %d\nEarn 1 token per 5 active pet minutes; tower victories also award tokens.",s.tokens,s.inventory.food,s.inventory.toy,s.inventory.medicine))
  w.notice:SetText(P.notice or "Active pets need care. Stabled pets rest safely. No real gold is used.")
  P.pocket.text:SetText(pet and string.format("%s • Lv %d\nHP %d   Food %d   Happy %d",P.species[pet.species],pet.level,math.floor(pet.health),math.floor(pet.food),math.floor(pet.happy)) or "No living active pet.\nOpen the stable to adopt.")
  w.collection:SetShown(P.mode=='collection');w.tower:SetShown(P.mode=='tower');w.social:SetShown(P.mode=='peers')
  if P.mode=='collection' then
    local pages=math.max(1,math.ceil(#s.pets/5));P.page=math.min(P.page,pages)
    w.collection.page:SetText("Stable & memorial  "..P.page.." / "..pages)
    for i,row in ipairs(w.collection.rows)do
      local item=s.pets[(P.page-1)*5+i];row.petID=item and item.id or false;row:SetShown(item~=nil)
      if item then row:SetText((item.deadAt and "RIP " or item.id==s.active and "* " or "")..P.rarities[item.rarity].." "..P.species[item.species].."  Lv "..item.level.."\n"..P.Age(item.age).." alive • Floor "..item.best)end
    end
  elseif P.mode=='tower' then
    local b=s.battle;local floor=b and b.enemy.floor or P.floor;local e=b and b.enemy or P.Enemy(floor)
    w.tower.title:SetText("Floor "..floor.." / 100"..(e.boss and " — BOSS" or ""))
    w.tower.stats:SetText(b and string.format("Your HP: %d / %d\nEnemy HP: %d / %d\nTurn %d • Special cooldown: %d",b.hp,b.maxHP,e.hp,e.maxHP,b.turn+1,b.cooldown)
      or (P.species[e.species].." challenger • "..e.maxHP.." health\nYour highest floor: "..(pet and pet.best or 0).."\nClear floors in order. Replay cleared floors to train."))
    w.tower.start:SetEnabled(not b and pet~=nil)
  else
    w.social.share:SetText(s.share and "Pet stats: sharing with guild / group" or "Pet stats: sharing OFF (click to opt in)")
    local lines={"Guild/group standings • self-reported, unverified."}
    if s.review then lines[#lines+1]="Your save needs integrity review; excluded from ranking." end
    local rows={};for name,entry in pairs(P.peers)do rows[#rows+1]={name=name,pet=entry}end
    table.sort(rows,function(a,b)if a.pet.best==b.pet.best then return a.name<b.name end;return a.pet.best>b.pet.best end)
    for i=1,math.min(3,#rows)do local row=rows[i];local p=row.pet
      lines[#lines+1]=row.name:sub(1,24)..": "..P.rarities[p.rarity].." "..P.species[p.species].."\nLv "..p.level.." • Floor "..p.best.." • Alive "..P.Age(p.age)
    end
    if #rows==0 then lines[#lines+1]="No sharing peers seen in your guild or group yet." end
    local flags=0;for _ in pairs(P.flags)do flags=flags+1 end
    lines[#lines+1]="Integrity review: "..flags.." record(s) excluded."
    local shown=0;for name,entry in pairs(P.flags)do if shown<2 then lines[#lines+1]=name:sub(1,24)..": "..entry.reason;shown=shown+1 end end
    lines[#lines+1]="Flags are not proof of cheating. Records expire in 10 minutes."
    w.social.text:SetText(table.concat(lines,"\n"))
  end
end
