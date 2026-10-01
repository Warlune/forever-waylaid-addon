local _,F=...
local P={};F.Pets=P
P.species={"Murloc","Whelp","Wolf pup","Owl"}
P.rarities={"Common","Uncommon","Rare","Epic","Legendary"}
P.colors={{0.9,0.9,0.9},{0.2,1,0.2},{0.3,0.6,1},{0.8,0.4,1},{1,0.6,0.15}}
P.items={food={name="Trail treats",cost=2},toy={name="Chew toy",cost=3},medicine={name="Healing herbs",cost=4}}
P.random=math.random
local function clamp(n)return math.max(0,math.min(100,n))end
local function whole(n,min,max)return type(n)=="number" and n==math.floor(n) and n>=min and n<=max end
function P.Seal(s)
  local bits={s.tokens,s.active or 0,s.nextID,s.playSeconds,s.rewardSeconds,s.inventory.food,s.inventory.toy,s.inventory.medicine}
  for _,pet in ipairs(s.pets)do
    for _,k in ipairs({"id","species","rarity","level","xp","health","food","happy","energy","born","age","best","wins","deadAt"})do bits[#bits+1]=pet[k] or 0 end
  end
  local h=5381
  for _,n in ipairs(bits)do for c in tostring(n):gmatch('.')do h=(h*33+c:byte())%2147483647 end end
  return h
end
function P.Save()P.state.seal=P.Seal(P.state)end
function P.Audit()
  local s=P.state
  if (s.seal and s.seal~=P.Seal(s)) or (#s.pets>0 and not s.seal) then s.review=true;P.notice="Save changed outside the pet system. Stats marked for integrity review." end
end
local function validSave(s)
  if type(s)~="table" or s.version~=1 or type(s.pets)~="table" or #s.pets>128 or type(s.inventory)~="table" then return false end
  for _,key in ipairs({"tokens","nextID","playSeconds","rewardSeconds"})do
    local n=s[key];if type(n)~="number" or n~=n or n<0 or n>1e12 then return false end
  end
  if not whole(s.tokens,0,1000000000) or not whole(s.nextID,1,1000000)then return false end
  for key in pairs(P.items)do if not whole(s.inventory[key],0,10000000)then return false end end
  local ids={}
  for _,pet in ipairs(s.pets)do
    if type(pet)~="table" or not whole(pet.id,1,1000000) or ids[pet.id] or not whole(pet.species,1,4)
      or not whole(pet.rarity,1,5) or not whole(pet.level,1,100) or not whole(pet.best,0,100) or not whole(pet.wins,0,10000000)then return false end
    ids[pet.id]=true
    for _,key in ipairs({"health","food","happy","energy","age","born","xp"})do
      local n=pet[key];if type(n)~="number" or n~=n or n<0 or n>1e12 then return false end
    end
    if pet.health>100 or pet.food>100 or pet.happy>100 or pet.energy>100 then return false end
    if pet.deadAt~=nil and (type(pet.deadAt)~="number" or pet.deadAt~=pet.deadAt)then return false end
  end
  return true
end
function P.Init()
  local s=F.char.pets
  local invalid=s~=nil and not validSave(s)
  if invalid then F.char.petQuarantine=s;s=nil end
  if not s then
    s={version=1,pets={},active=nil,nextID=1,tokens=25,inventory={food=8,toy=4,medicine=4},playSeconds=0,rewardSeconds=0,share=false}
    F.char.pets=s
  end
  if invalid then s.review=true;P.notice="Invalid pet save preserved in quarantine. New progress is marked for review." end
  P.state=s;P.Audit();P.Save()
  -- Quitting mid-fight counts as a retreat, never a free healed battle.
  if s.battle then s.battle=nil;P.notice="Your pet retreated when the session ended." end
end
function P.Active()
  for _,pet in ipairs(P.state.pets)do if pet.id==P.state.active and not pet.deadAt then return pet end end
end
function P.Die(pet,reason)
  if pet.deadAt then return end
  pet.health=0;pet.deadAt=F.Now();pet.deathReason=reason;P.state.battle=nil
  P.notice=P.species[pet.species].." has died. Its level and lifespan are kept in the memorial."
end
function P.Adopt()
  P.Audit();local s=P.state
  if s.battle then return false,"Finish or retreat from the battle first." end
  if #s.pets>=128 then return false,"The collection and memorial are full (128 records)." end
  local living=0;for _,pet in ipairs(s.pets)do if not pet.deadAt then living=living+1 end end
  if living>=24 then return false,"Your stable holds 24 living pets." end
  local cost=living==0 and 0 or 25
  if s.tokens<cost then return false,"Adoption costs 25 pet tokens." end
  local roll=P.random(1,100);local rarity=roll<=55 and 1 or roll<=80 and 2 or roll<=94 and 3 or roll<=99 and 4 or 5
  local pet={id=s.nextID,species=P.random(1,4),rarity=rarity,level=1,xp=0,health=100,food=100,happy=100,energy=100,born=F.Now(),age=0,best=0,wins=0}
  s.nextID=s.nextID+1;s.tokens=s.tokens-cost;s.pets[#s.pets+1]=pet;s.active=pet.id
  P.notice="Adopted a "..P.rarities[rarity].." "..P.species[pet.species].."!";P.Save();return true
end
function P.Select(id)
  if P.state.battle then return false,"Finish or retreat from the battle first." end
  P.Audit()
  for _,pet in ipairs(P.state.pets)do if pet.id==id and not pet.deadAt then P.state.active=id;P.Save();return true end end
  return false,"This pet is in the memorial. Death is permanent."
end
function P.Buy(item)
  P.Audit();local entry=P.items[item];if not entry then return false,"Unknown item." end
  if P.state.tokens<entry.cost then return false,"Not enough pet tokens." end
  P.state.tokens=P.state.tokens-entry.cost;P.state.inventory[item]=P.state.inventory[item]+1;P.Save();return true
end
function P.Care(item)
  P.Audit();local pet=P.Active();if not pet then return false,"Adopt or select a living pet." end
  if P.state.battle then return false,"Use battle actions or retreat first." end
  if item=="rest" then pet.resting=not pet.resting;P.Save();return true end
  if not P.items[item] or P.state.inventory[item]<1 then return false,"Buy that care item with pet tokens first." end
  P.state.inventory[item]=P.state.inventory[item]-1
  if item=="food" then pet.food=clamp(pet.food+35);pet.health=clamp(pet.health+5)
  elseif item=="toy" then pet.happy=clamp(pet.happy+40)
  else pet.health=clamp(pet.health+40)end
  P.Save();return true
end
function P.Tick(seconds)
  if not P.state then return end
  local s=P.state;P.Audit()
  seconds=math.max(0,math.min(5,seconds)) -- No offline catch-up or long loading-screen penalties.
  local pet=P.Active()
  if pet then
    s.playSeconds=s.playSeconds+seconds;s.rewardSeconds=s.rewardSeconds+seconds
    if s.rewardSeconds>=300 then s.tokens=s.tokens+math.floor(s.rewardSeconds/300);s.rewardSeconds=s.rewardSeconds%300 end
    pet.age=pet.age+seconds
    if not s.battle then
      pet.food=clamp(pet.food-seconds/300);pet.happy=clamp(pet.happy-seconds/450)
      pet.energy=clamp(pet.energy+seconds/(pet.resting and 8 or 100))
      if pet.food<10 then pet.health=clamp(pet.health-seconds/60)
      elseif pet.resting and pet.food>=25 then pet.health=clamp(pet.health+seconds/30)end
      if pet.health<=0 then P.Die(pet,"Neglect")end
    end
  end
  P.Save()
end
function P.Enemy(floor)
  if not whole(floor,1,100)then return end
  local boss=floor%10==0
  return {floor=floor,maxHP=math.floor((30+floor*6)*(boss and 1.25 or 1)),attack=4+math.floor(floor*1.5),boss=boss,species=(floor-1)%4+1}
end
function P.Stats(pet)
  return 30+pet.level*6+pet.rarity*4,6+math.floor(pet.level*1.7)+pet.rarity*2
end
function P.AddXP(pet,amount)
  if not pet or pet.deadAt or pet.level>=100 then return 0 end
  amount=math.max(0,math.floor(amount));pet.xp=pet.xp+amount
  while pet.level<100 and pet.xp>=20+pet.level*5 do pet.xp=pet.xp-(20+pet.level*5);pet.level=pet.level+1 end
  if pet.level==100 then pet.xp=0 end
  return amount
end
-- Only server-reported killing blows by this character or its combat pet count.
-- This is a local abuse deterrent, not proof that a remote client is unmodified.
P.recentKills={}
function P.CombatKill(event,sourceGUID,destGUID)
  if event~="PARTY_KILL" or not P.state or not UnitGUID then return end
  local playerGUID,combatPetGUID=UnitGUID("player"),UnitGUID("pet")
  if not sourceGUID or (sourceGUID~=playerGUID and sourceGUID~=combatPetGUID) then return end
  if type(destGUID)~="string" or destGUID==playerGUID or destGUID==combatPetGUID then return end
  local isPlayer=destGUID:match("^Player%-")~=nil
  if not isPlayer and not destGUID:match("^Creature%-") then return end
  local pet=P.Active();if not pet or pet.level>=100 then return end
  local now=F.Now()
  for guid,when in pairs(P.recentKills)do if now-when>=300 then P.recentKills[guid]=nil end end
  if P.recentKills[destGUID] then return end
  if not P.combatWindow or now-P.combatWindow>=60 or now<P.combatWindow then P.combatWindow=now;P.combatXP=0 end
  local amount=math.min(isPlayer and 10 or 3,60-(P.combatXP or 0))
  if amount<=0 then return end
  P.Audit();P.recentKills[destGUID]=now;P.combatXP=(P.combatXP or 0)+amount
  P.AddXP(pet,amount)
  P.notice="+"..amount.." pet XP: "..(isPlayer and "PvP kill" or "NPC kill").."."
  P.Save()
end
function P.StartBattle(floor)
  P.Audit();local pet=P.Active();local enemy=P.Enemy(floor)
  if not pet or not enemy then return false,"Select a living pet and a floor from 1 to 100." end
  if P.state.battle then return false,"A battle is already active." end
  if floor>pet.best+1 then return false,"Clear the previous floor first." end
  if pet.health<40 or pet.energy<15 or pet.food<15 then return false,"Prepare your pet: 40 health, 15 energy and 15 food required." end
  local hp,attack=P.Stats(pet);pet.energy=pet.energy-15;pet.food=clamp(pet.food-5);pet.resting=false
  enemy.hp=enemy.maxHP
  P.state.battle={petID=pet.id,enemy=enemy,hp=math.ceil(hp*pet.health/100),maxHP=hp,attack=attack,turn=0,cooldown=0}
  P.notice="Battle is turn-based. Defeat permanently kills your pet. Retreat is always available.";P.Save();return true
end
function P.BattleAction(action)
  P.Audit();local s=P.state;local b=s.battle;local pet=P.Active()
  if not b or not pet or pet.id~=b.petID then return false,"No active battle." end
  if action=="retreat" then s.battle=nil;P.notice="Retreated safely. Spent energy and supplies are not refunded.";P.Save();return true end
  if action~="strike" and action~="guard" and action~="burst" and action~="heal" then return false,"Unknown action." end
  if action=="burst" and b.cooldown>0 then return false,"Special attack is cooling down." end
  if action=="heal" and s.inventory.medicine<1 then return false,"No healing herbs." end
  local charging=(b.turn+1)%3==0
  b.cooldown=math.max(0,b.cooldown-1)
  if action=="heal" then s.inventory.medicine=s.inventory.medicine-1;b.hp=math.min(b.maxHP,b.hp+math.ceil(b.maxHP*0.4))
  elseif action~="guard" then
    b.enemy.hp=math.max(0,b.enemy.hp-math.floor(b.attack*(action=="burst" and 1.7 or 1)*(0.85+P.random(0,30)/100)))
    if action=="burst" then b.cooldown=3 end
  end
  b.turn=b.turn+1
  if b.enemy.hp<=0 then
    local first=b.enemy.floor>pet.best;pet.best=math.max(pet.best,b.enemy.floor);pet.wins=pet.wins+1
    P.AddXP(pet,math.floor((15+b.enemy.floor*3)*(first and 1 or 0.35)))
    s.tokens=s.tokens+(first and 8+math.floor(b.enemy.floor/10) or 1);pet.happy=clamp(pet.happy+8)
    pet.health=clamp(b.hp/b.maxHP*100);s.battle=nil
    P.notice=pet.best==100 and "Tower conquered! All 100 floors cleared." or "Victory! Earned pet XP and tokens.";P.Save();return true
  end
  local damage=math.max(1,math.floor(b.enemy.attack*(charging and 1.7 or 1)*(action=="guard" and 0.3 or 1)))
  b.hp=math.max(0,b.hp-damage);pet.health=b.hp/b.maxHP*100
  P.notice="Enemy hit for "..damage..". "..((b.turn+1)%3==0 and "Heavy attack next turn: consider Guard!" or "Choose your next action.")
  if b.hp<=0 then P.Die(pet,"Tower floor "..b.enemy.floor)end
  P.Save();return true
end
function P.Age(seconds)
  return string.format("%dh %02dm",math.floor(seconds/3600),math.floor(seconds/60)%60)
end
P.peers={};P.flags={}
local prefix="FWLPet1"
function P.SetSharing(enabled)
  P.Audit();P.state.share=not not enabled;P.peers={};P.flags={};P.nextShare=F.Now()+2;P.Save()
end
function P.Packet()
  local p=P.Active();if not p then return end
  return table.concat({"1",p.species,p.rarity,p.level,math.floor(p.age),p.best,p.wins,P.state.review and 1 or 0},",")
end
function P.Receive(message,channel,sender)
  if not P.state or not P.state.share or (channel~="PARTY" and channel~="RAID" and channel~="GUILD")then return end
  if type(sender)~="string" or #sender>100 or sender:find("[|%c]") or type(message)~="string" or #message>180 then return end
  if sender==(UnitName and UnitName("player"))then return end
  local now=F.Now();local prior=P.peers[sender] or P.flags[sender]
  if prior and now-prior.seen<30 then return end
  local version,sp,rar,lv,age,best,wins,review=message:match("^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
  if version~="1" then return end
  sp,rar,lv,age,best,wins,review=tonumber(sp),tonumber(rar),tonumber(lv),tonumber(age),tonumber(best),tonumber(wins),tonumber(review)
  local valid=whole(sp,1,4) and whole(rar,1,5) and whole(lv,1,100) and whole(age,0,315360000) and whole(best,0,100) and whole(wins,0,10000000) and whole(review,0,1)
  local count=0;for _ in pairs(P.peers)do count=count+1 end;for _ in pairs(P.flags)do count=count+1 end
  if count>=40 and not prior then return end
  P.peers[sender]=nil;P.flags[sender]=nil
  if not valid or review==1 or best>wins then P.flags[sender]={seen=now,reason=valid and review==1 and "Save marked for review" or "Invalid reported stats"};return end
  P.peers[sender]={seen=now,species=sp,rarity=rar,level=lv,age=age,best=best,wins=wins}
end
function P.Share()
  if not P.state.share or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return end
  local packet=P.Packet();if not packet then return end
  if not P.registered and C_ChatInfo.RegisterAddonMessagePrefix then
    local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,prefix);P.registered=ok and (result==true or result==0)
  end
  if not P.registered then return end
  if IsInGuild and IsInGuild()then pcall(C_ChatInfo.SendAddonMessage,prefix,packet,"GUILD")end
  if IsInRaid and IsInRaid()then pcall(C_ChatInfo.SendAddonMessage,prefix,packet,"RAID")
  elseif IsInGroup and IsInGroup()then pcall(C_ChatInfo.SendAddonMessage,prefix,packet,"PARTY")end
end
local events=CreateFrame("Frame");P.events=events;events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
events:SetScript("OnEvent",function(_,event,p,message,channel,sender)
  if event=="COMBAT_LOG_EVENT_UNFILTERED" then
    if CombatLogGetCurrentEventInfo then
      local _,kind,_,sourceGUID,_,_,_,destGUID=CombatLogGetCurrentEventInfo()
      P.CombatKill(kind,sourceGUID,destGUID)
    end
  elseif p==prefix then P.Receive(message,channel,sender)end
end)
local elapsed=0
events:SetScript("OnUpdate",function(_,dt)
  if not P.state then return end
  elapsed=elapsed+dt;if elapsed<1 then return end
  P.Tick(elapsed);elapsed=0
  if F.Now()>=(P.nextShare or 0)then
    P.nextShare=F.Now()+120;P.Share()
    for _,list in ipairs({P.peers,P.flags})do for sender,entry in pairs(list)do if F.Now()-entry.seen>600 then list[sender]=nil end end end
  end
  if P.Render then P.Render()end
end)
