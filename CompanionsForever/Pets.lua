local _,F=...
local P={};F.Pets=P
P.species=F.PetData.names
P.rarities={"Common","Uncommon","Rare","Epic","Legendary"}
P.colors={{0.9,0.9,0.9},{0.2,1,0.2},{0.3,0.6,1},{0.8,0.4,1},{1,0.6,0.15}}
P.items={food={name="Trail treats",cost=2},toy={name="Chew toy",cost=3},medicine={name="Healing herbs",cost=4}}
P.random=math.random
local function clamp(n)return math.max(0,math.min(100,n))end
local function whole(n,min,max)return type(n)=="number" and n==math.floor(n) and n>=min and n<=max end
local function readable(value)
  if canaccessvalue then return canaccessvalue(value)end
  return not issecretvalue or not issecretvalue(value)
end
P.enemyLevels={}
function P.ObserveEnemy(unit)
  if not UnitGUID or not UnitLevel then return end
  local guid,level=UnitGUID(unit),UnitLevel(unit)
  if not readable(guid) or not readable(level) or type(guid)~="string" then return end
  if not whole(level,1,1000) then P.enemyLevels[guid]=nil;return end
  local now=F.Now();local count=0
  for key,entry in pairs(P.enemyLevels)do if now-entry.seen>60 then P.enemyLevels[key]=nil else count=count+1 end end
  if count<128 or P.enemyLevels[guid] then P.enemyLevels[guid]={level=level,seen=now}end
end
function P.EligibleKill(guid)
  for _,unit in ipairs({"target","focus","mouseover"})do P.ObserveEnemy(unit)end
  local entry=P.enemyLevels[guid]
  if not entry or F.Now()-entry.seen>60 then return false end
  local level
  if UnitEffectiveLevel then level=UnitEffectiveLevel("player") elseif UnitLevel then level=UnitLevel("player")end
  local grayRange=UnitQuestTrivialLevelRange and UnitQuestTrivialLevelRange("player")
  if not readable(level) or not readable(grayRange) or not whole(level,1,1000) or not whole(grayRange,0,1000) then return false end
  local diff=entry.level-level
  return math.abs(diff)<=5 and not (diff < -4 and -diff>grayRange)
end
local function validSave(s)
  if type(s)~="table" or s.version~=1 or type(s.pets)~="table" or #s.pets>512 or type(s.inventory)~="table" then return false end
  for _,key in ipairs({"tokens","nextID","playSeconds","rewardSeconds"})do
    local n=s[key];if type(n)~="number" or n~=n or n<0 or n>1e12 then return false end
  end
  if not whole(s.tokens,0,1000000000) or not whole(s.nextID,1,1000000)then return false end
  for key in pairs(P.items)do if not whole(s.inventory[key],0,10000000)then return false end end
  local ids={}
  for _,pet in ipairs(s.pets)do
    if type(pet)~="table" or not whole(pet.id,1,1000000) or ids[pet.id] or not whole(pet.species,1,100)
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
  P.victory=nil;P.lastRound=nil
  local s=F.char.pets
  local invalid=s~=nil and not validSave(s)
  if invalid then F.char.petQuarantine=s;s=nil end
  if not s then
    s={version=1,pets={},active=nil,nextID=1,tokens=25,inventory={food=8,toy=4,medicine=4},playSeconds=0,rewardSeconds=0,share=false}
    F.char.pets=s
  end
  if invalid then P.notice="Unreadable pet save preserved in a backup. Started a fresh stable." end
  s.review=nil;s.seal=nil -- Retire preview integrity flags; this is a personal game.
  s.packs=type(s.packs)=="table" and s.packs or {}
  for i=1,6 do if not whole(s.packs[i],0,100000)then s.packs[i]=0 end end
  s.bossClaims=type(s.bossClaims)=="table" and s.bossClaims or {}
  s.bossEggs=type(s.bossEggs)=="table" and s.bossEggs or {}
  if not whole(s.nextTreatDrop,0,1e12)then s.nextTreatDrop=0 end
  for key,value in pairs(s.bossEggs)do if not whole(key,85,100) or not whole(value,0,100000)then s.bossEggs[key]=nil end end
  for key,value in pairs(s.bossClaims)do if type(key)~="string" or type(value)~="number" or value~=value or F.Now()-value>604800 then s.bossClaims[key]=nil end end
  P.state=s
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
function P.Select(id)
  if P.state.battle then return false,"Finish the battle first." end
  for _,pet in ipairs(P.state.pets)do if pet.id==id and not pet.deadAt then P.state.active=id;P.floor=math.min(100,pet.best+1);P.notice="Equipped "..P.species[pet.species]..".";return true end end
  return false,"This pet is in the memorial. Death is permanent."
end
function P.Buy(item)
  local entry=P.items[item];if not entry then return false,"Unknown item." end
  if P.state.tokens<entry.cost then return false,"Not enough pet tokens." end
  P.state.tokens=P.state.tokens-entry.cost;P.state.inventory[item]=P.state.inventory[item]+1;return true
end
function P.Care(item)
  local pet=P.Active();if not pet then return false,"Adopt or select a living pet." end
  if P.state.battle then return false,"Use the tower Heal button during battle." end
  if item=="rest" then pet.resting=not pet.resting;return true end
  if not P.items[item] or P.state.inventory[item]<1 then return false,"Buy that care item with pet tokens first." end
  P.state.inventory[item]=P.state.inventory[item]-1
  if item=="food" then pet.food=clamp(pet.food+35);pet.health=clamp(pet.health+5)
  elseif item=="toy" then pet.happy=clamp(pet.happy+40)
  else pet.health=clamp(pet.health+40)end
  return true
end
function P.Tick(seconds)
  if not P.state then return end
  local s=P.state
  seconds=math.max(0,math.min(5,seconds)) -- No offline catch-up or long loading-screen penalties.
  local pet=P.Active()
  if pet then
    s.rewardSeconds=s.rewardSeconds+seconds
    if s.rewardSeconds>=300 then s.tokens=s.tokens+math.floor(s.rewardSeconds/300)*2;s.rewardSeconds=s.rewardSeconds%300 end
    s.playSeconds=s.playSeconds+seconds
    pet.age=pet.age+seconds
    if not s.battle then
      pet.food=clamp(pet.food-seconds/300);pet.happy=clamp(pet.happy-seconds/450)
      pet.energy=clamp(pet.energy+seconds/(pet.resting and 8 or 100))
      if pet.food<10 then pet.health=clamp(pet.health-seconds/60)
      elseif pet.resting and pet.food>=25 then pet.health=clamp(pet.health+seconds/30)end
      if pet.health<=0 then P.Die(pet,"Neglect")end
    end
  end
end
function P.AddXP(pet,amount)
  if not pet or pet.deadAt or pet.level>=100 then return 0 end
  amount=math.max(0,math.floor(amount));pet.xp=pet.xp+amount
  while pet.level<100 and pet.xp>=20+pet.level*5 do pet.xp=pet.xp-(20+pet.level*5);pet.level=pet.level+1 end
  if pet.level==100 then pet.xp=0 end
  return amount
end
-- Only server-reported killing blows by this character or its combat pet count.
-- Small rewards and repeat limits keep casual combat progression balanced.
P.recentKills={}
function P.CombatKill(event,sourceGUID,destGUID)
  if event~="PARTY_KILL" or not P.state or not UnitGUID then return end
  -- Forever's standalone kill event may carry restricted identities. Never
  -- compare, parse, stringify or retain those values in addon code.
  if not readable(sourceGUID) or not readable(destGUID) then return end
  local playerGUID,combatPetGUID=UnitGUID("player"),UnitGUID("pet")
  if not readable(playerGUID) or not readable(combatPetGUID) then return end
  if not sourceGUID or (sourceGUID~=playerGUID and sourceGUID~=combatPetGUID) then return end
  if type(destGUID)~="string" or destGUID==playerGUID or destGUID==combatPetGUID then return end
  local isPlayer=destGUID:match("^Player%-")~=nil
  if not isPlayer and not destGUID:match("^Creature%-") then return end
  if not P.EligibleKill(destGUID) then return end
  local pet=P.Active();if not pet then return end
  local now=F.Now()
  for guid,when in pairs(P.recentKills)do if now-when>=300 then P.recentKills[guid]=nil end end
  if P.recentKills[destGUID] then return end
  if not P.combatWindow or now-P.combatWindow>=60 or now<P.combatWindow then P.combatWindow=now;P.combatXP=0 end
  local amount=math.min(isPlayer and 10 or 3,60-(P.combatXP or 0))
  local canDrop=not isPlayer and sourceGUID==playerGUID and now>=P.state.nextTreatDrop
  if amount<=0 and not canDrop then return end
  P.recentKills[destGUID]=now;P.combatXP=(P.combatXP or 0)+amount
  local earned=P.AddXP(pet,amount)
  if earned>0 then P.notice="+"..earned.." pet XP: "..(isPlayer and "PvP kill" or "NPC kill").."." end
  -- One percent from eligible personal NPC kills; at most one per 30 minutes.
  -- The cooldown is saved, and the existing level/repeat guards still apply.
  if canDrop and P.random(1,100)==1 then
    P.state.inventory.food=P.state.inventory.food+1;P.state.nextTreatDrop=now+1800
    P.notice="Found a rare trail treat! +1 treat in the pet store."..(earned>0 and " +"..earned.." pet XP." or "")
  end
end
function P.UseCare(item)
  if not P.Active() or P.state.battle then return P.Care(item)end
  if P.items[item] and P.state.inventory[item]<1 then
    local ok,message=P.Buy(item);if not ok then return ok,message end
  end
  local ok,message=P.Care(item)
  if ok then P.notice=item=="rest" and (P.Active().resting and "Resting beside the camp." or "Ready for adventure.") or "Your companion enjoyed the care." end
  return ok,message
end
function P.PauseBattle()
  if not P.state.battle then return false,"Start a battle first." end
  P.state.battle.paused=not P.state.battle.paused;return true
end
function P.Age(seconds)
  return string.format("%dh %02dm",math.floor(seconds/3600),math.floor(seconds/60)%60)
end
P.peers={};P.replyTimes={}
local prefix="FWLPet1"
local function peerKey(name)
  local key=name:lower():gsub("%s","")
  local realm=GetRealmName and GetRealmName():lower():gsub("%s","")
  local short,suffix=key:match("^([^%-]+)%-(.+)$")
  return suffix==realm and short or key
end
function P.RegisterSharing()
  if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return false end
  if not P.registered and C_ChatInfo.RegisterAddonMessagePrefix then
    local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,prefix);P.registered=ok and (result==true or result==0)
  end
  return P.registered
end
function P.SetSharing(enabled)
  P.state.share=not not enabled;P.peers={};P.replyTimes={};P.pendingInspect=nil;P.nextShare=F.Now()+2
  if enabled then P.RegisterSharing()end
end
function P.Packet()
  local p=P.Active();if not p then return end
  return table.concat({"3",p.species,p.rarity,p.level,math.floor(p.age),p.best,p.wins},",")
end
function P.InspectTarget()
  if not P.state.share then return false,"Enable pet sharing before inspecting another player." end
  if not UnitIsPlayer or not UnitIsPlayer("target") or (UnitIsUnit and UnitIsUnit("target","player")) then return false,"Target another player with Companions Forever." end
  local name=GetUnitName and GetUnitName("target",true) or UnitName("target")
  if not name or name=="" or not P.RegisterSharing() then return false,"Pet inspection is unavailable." end
  if P.nextInspect and F.Now()<P.nextInspect then return false,"Wait a few seconds before inspecting again." end
  P.nextInspect=F.Now()+5;P.pendingInspect={name=peerKey(name),expires=F.Now()+10}
  local ok=pcall(C_ChatInfo.SendAddonMessage,prefix,"ASK3","WHISPER",name)
  if not ok then P.pendingInspect=nil;return false,"Could not request this player's pet." end
  P.notice="Requested pet from "..name..". They need pet sharing enabled.";return true
end
function P.Receive(message,channel,sender)
  if not P.state or not P.state.share then return end
  if type(sender)~="string" or #sender==0 or #sender>100 or sender:find("[|%c]") or type(message)~="string" or #message>180 then return end
  if sender==(UnitName and UnitName("player"))then return end
  local now=F.Now()
  if channel=="WHISPER" then
    if message=="ASK3" then
      if not P.RegisterSharing() or now<(P.nextReply or 0) or now-(P.replyTimes[sender] or -1000)<30 then return end
      P.replyTimes[sender]=now;P.nextReply=now+1
      pcall(C_ChatInfo.SendAddonMessage,prefix,P.Packet() or "NONE3","WHISPER",sender);return
    end
    if not P.pendingInspect or now>P.pendingInspect.expires or peerKey(sender)~=P.pendingInspect.name then return end
    if message=="NONE3" then P.pendingInspect=nil;P.notice=sender.." has no active companion.";return end
  elseif channel~="PARTY" and channel~="RAID" and channel~="GUILD" then return end
  local prior=P.peers[sender]
  if channel~="WHISPER" and prior and now-prior.seen<30 then return end
  local version,sp,rar,lv,age,best,wins=message:match("^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
  if version~="3" then return end
  sp,rar,lv,age,best,wins=tonumber(sp),tonumber(rar),tonumber(lv),tonumber(age),tonumber(best),tonumber(wins)
  if not (whole(sp,1,100) and whole(rar,1,5) and whole(lv,1,100) and whole(age,0,315360000) and whole(best,0,100) and whole(wins,0,10000000)) then return end
  local count=0;for _ in pairs(P.peers)do count=count+1 end
  if count>=40 and not prior then
    if channel~="WHISPER" then return end
    local oldest;for name,entry in pairs(P.peers)do if not oldest or entry.seen<P.peers[oldest].seen then oldest=name end end
    if oldest then P.peers[oldest]=nil end
  end
  P.peers[sender]={seen=now,species=sp,rarity=rar,level=lv,age=age,best=best,wins=wins}
  if channel=="WHISPER" then P.pendingInspect=nil;P.inspectName=sender;P.notice="Viewing "..sender.."'s companion." end
end
function P.Share()
  if not P.state.share or not P.RegisterSharing() then return end
  local packet=P.Packet();if not packet then return end
  if IsInGuild and IsInGuild()then pcall(C_ChatInfo.SendAddonMessage,prefix,packet,"GUILD")end
  if IsInRaid and IsInRaid()then pcall(C_ChatInfo.SendAddonMessage,prefix,packet,"RAID")
  elseif IsInGroup and IsInGroup()then pcall(C_ChatInfo.SendAddonMessage,prefix,packet,"PARTY")end
end
local events=CreateFrame("Frame");P.events=events;events:RegisterEvent("CHAT_MSG_ADDON")
-- COMBAT_LOG_EVENT_UNFILTERED is forbidden to addons on Forever. PARTY_KILL
-- is a separate supported event with (attackerGUID, targetGUID) payload.
events:RegisterEvent("PARTY_KILL")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_FOCUS_CHANGED")
events:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
events:SetScript("OnEvent",function(_,event,p,message,channel,sender)
  if not P.state then return end
  if event=="PARTY_KILL" then
    P.CombatKill(event,p,message)
  elseif event=="PLAYER_TARGET_CHANGED" then P.ObserveEnemy("target")
  elseif event=="PLAYER_FOCUS_CHANGED" then P.ObserveEnemy("focus")
  elseif event=="UPDATE_MOUSEOVER_UNIT" then P.ObserveEnemy("mouseover")
  elseif p==prefix then P.Receive(message,channel,sender)end
end)
local elapsed=0
events:SetScript("OnUpdate",function(_,dt)
  if not P.state then return end
  P.sceneClock=(P.sceneClock or 0)+math.min(dt,0.25)
  P.AdvanceBattle(dt,P.BattleVisible and P.BattleVisible())
  elapsed=elapsed+dt;if elapsed<1 then return end
  P.ObserveEnemy("target")
  P.Tick(elapsed);elapsed=0
  if F.Now()>=(P.nextShare or 0)then
    P.nextShare=F.Now()+120;P.Share()
    for sender,entry in pairs(P.peers)do if F.Now()-entry.seen>600 then P.peers[sender]=nil end end
    for sender,when in pairs(P.replyTimes)do if F.Now()-when>60 then P.replyTimes[sender]=nil end end
  end
  if P.pendingInspect and F.Now()>P.pendingInspect.expires then P.pendingInspect=nil;P.notice="No pet reply. Both players need compatible companions and pet sharing enabled." end
  if P.Render then P.Render()end
end)
