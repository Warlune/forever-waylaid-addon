local _,F=...
local P,D=F.Pets,F.PetData
P.packs=D.packs
local function clamp(v)return math.max(0,math.min(100,v))end
local function integer(v,lo,hi)return type(v)=="number" and v==math.floor(v) and v>=lo and v<=hi end
local function readable(v)return canaccessvalue and canaccessvalue(v) or not canaccessvalue and (not issecretvalue or not issecretvalue(v))end
function P.LivingCount()
  local n=0;for _,pet in ipairs(P.state.pets)do if not pet.deadAt then n=n+1 end end;return n
end
local function room()
  if P.state.battle then return false,"Finish the battle first." end
  if #P.state.pets>=512 then return false,"The stable and memorial have reached 512 records." end
  if P.LivingCount()>=100 then return false,"Your stable holds 100 living companions." end
  return true
end
local function addPet(species,rarity,source)
  local s=P.state
  local pet={id=s.nextID,species=species,rarity=rarity,level=1,xp=0,health=100,food=100,happy=100,energy=100,born=F.Now(),age=0,best=0,wins=0,source=source}
  s.nextID=s.nextID+1;s.pets[#s.pets+1]=pet
  if not P.Active()then s.active=pet.id;P.floor=1 end
  P.viewID=pet.id;P.page=math.ceil(#s.pets/3)
  P.notice="Adopted "..P.rarities[rarity].." "..P.species[species]..(s.active==pet.id and " - equipped." or ". Select Equip to travel together.")
  return true,pet
end
function P.Rescue()
  local ok,msg=room();if not ok then return ok,msg end
  if P.LivingCount()>0 then return false,"A free common rescue is available only when no pets are alive." end
  return addPet(P.random(1,84),1,"Rescue")
end
function P.Adopt(index)
  index=index or 1
  if not integer(index,1,6)then return false,"Choose an adoption pack." end
  local ok,msg=room();if not ok then return ok,msg end
  local s,pack=P.state,D.packs[index]
  local owned=s.packs[index]>0
  if not owned and s.tokens<pack.cost then return false,"This pack costs "..pack.cost.." pet tokens." end
  local roll,total,rarity=P.random(1,100),0,1
  for i,chance in ipairs(pack.odds)do total=total+chance;if roll<=total then rarity=i;break end end
  local species=P.random(1,84) -- Raid bosses never come from purchased packs.
  if owned then s.packs[index]=s.packs[index]-1 else s.tokens=s.tokens-pack.cost end
  return addPet(species,rarity,pack.name)
end
function P.ClaimBoss(species)
  local ok,msg=room();if not ok then return ok,msg end
  if not integer(species,85,100) or (P.state.bossEggs[species] or 0)<1 then return false,"No boss companion waiting." end
  P.state.bossEggs[species]=P.state.bossEggs[species]-1
  return addPet(species,4,"Raid boss reward")
end
function P.Ability(pet)
  if pet and pet.rarity>=3 then return D.families[D.species[pet.species].family]end
end
function P.AbilityHelp(effect)
  return ({bite="180% attack damage.",flurry="165% attack damage.",cleave="90% attack damage to every enemy.",renew="80% attack damage and restore 18% max health.",drain="110% attack damage; heal for 60% of that hit.",shield="Strike and reduce later hits this round by 55%."})[effect].." Three-round cooldown."
end
function P.IsHealingAbility(ability)
  return ability and (ability.effect=="renew" or ability.effect=="drain")
end
function P.HealChoice()
  local b=P.state.battle;if not b then return nil,"Start a battle first." end
  if b.hp>=b.maxHP then return nil,"Your pet is already at full health." end
  local ability=P.Ability(P.Active())
  if P.IsHealingAbility(ability) and b.cooldown==0 then return "burst",ability.ability.." (free ability)" end
  if P.state.inventory.medicine>0 then return "heal","Use 1 healing herb" end
  if P.state.tokens>=P.items.medicine.cost then return "heal","Heal for "..P.items.medicine.cost.." tokens" end
  return nil,"Need a healing herb or "..P.items.medicine.cost.." tokens."
end
function P.RequestHeal()
  local b=P.state.battle
  if b and b.pendingHeal then return false,"A heal is already queued for your pet's next turn." end
  local action,description=P.HealChoice();if not action then return false,description end
  b.pendingHeal=action;P.notice=description.." queued for your pet's next turn."
  return true
end
function P.Stats(pet)
  local family=D.families[D.species[pet.species].family]
  local quality=1+(pet.rarity-1)*0.06
  return math.floor((55+pet.level*9)*family.hp*quality),math.floor((9+pet.level*2.4)*family.attack*quality),
    family.armor+pet.rarity-1,family.speed+math.floor(pet.level/10)
end
function P.Unlocked()
  local pet=P.Active();return math.min(100,pet and pet.best+1 or 1)
end
function P.FloorStatus(floor)
  local pet=P.Active()
  return pet and floor<=pet.best and "Completed" or floor<=P.Unlocked() and "Not cleared" or "Locked"
end
function P.CurrentVictory()
  local pet=P.Active();local result=P.victory
  if result and pet and result.petID==pet.id and result.floor==(P.floor or 1) and not P.state.battle then return result end
end
function P.Enemies(floor)
  if not integer(floor,1,100)then return end
  local count=floor<=33 and 1 or floor<=66 and 2 or 3
  local result={};local boss=floor%10==0
  -- Split the encounter budget: extra opponents never triple the difficulty.
  local totalHP=(42+floor*8)*(boss and 1.18 or 1)*(1+(count-1)*0.1)
  local totalAttack=(5+floor*1.8)*(boss and 1.1 or 1)
  for i=1,count do
    result[i]={floor=floor,maxHP=math.floor(totalHP/count),attack=math.max(1,math.floor(totalAttack/count)),
      armor=math.floor(floor/12),speed=7+math.floor(floor/10)+(i-1)*3,boss=boss and i==1,
      species=boss and i==1 and 85+(math.floor(floor/10)-1)%16 or 1+(floor*7+i*13)%84,index=i}
  end
  return result
end
function P.Enemy(floor)local enemies=P.Enemies(floor);return enemies and enemies[1]end
function P.StartBattle(floor)
  local pet=P.Active();local enemies=P.Enemies(floor)
  if not pet or not enemies then return false,"Equip a living pet and select a floor from 1 to 100." end
  if P.state.battle then return false,"A battle is already active." end
  if floor>P.Unlocked()then return false,"Clear the previous floor first." end
  if pet.health<40 or pet.energy<15 or pet.food<15 then return false,"Prepare your pet: 40 health, 15 energy and 15 food required." end
  local hp,attack,armor,speed=P.Stats(pet)
  pet.energy=pet.energy-15;pet.food=clamp(pet.food-5);pet.resting=false
  for _,enemy in ipairs(enemies)do enemy.hp=enemy.maxHP end
  P.state.battle={petID=pet.id,enemies=enemies,enemy=enemies[1],floor=floor,hp=math.ceil(hp*pet.health/100),
    maxHP=hp,attack=attack,armor=armor,speed=speed,turn=0,cooldown=0,elapsed=0,paused=false}
  P.lastRound=nil;P.victory=nil;P.floor=floor
  P.notice="Floor "..floor..": 1 versus "..#enemies..". Auto battle - defeat is permanent."
  return true
end
local function damage(power,armor)return math.max(1,math.floor(power*(1-armor/100)))end
function P.BattleAction(action)
  local s=P.state;local b=s.battle;local pet=P.Active()
  if not b or not pet or pet.id~=b.petID then return false,"No active battle." end
  if action=="retreat" then s.battle=nil;P.lastRound=nil;P.notice="Retreated safely. Spent supplies and lost health remain.";return true end
  if action~="strike" and action~="guard" and action~="burst" and action~="heal" then return false,"Unknown action." end
  local ability=P.Ability(pet)
  if action=="burst" and (not ability or b.cooldown>0)then return false,ability and "Ability is cooling down." or "Special abilities require Rare quality or higher." end
  if action=="heal" and s.inventory.medicine<1 and s.tokens<P.items.medicine.cost then return false,"Need a healing herb or 4 tokens." end
  local round={at=P.sceneClock or 0,action=action,enemy=b.enemy,enemies=b.enemies,pet=pet,events={},maxHP=b.maxHP,hit=0,heal=0,hurt=0}
  P.lastRound=round;b.cooldown=math.max(0,b.cooldown-1)
  local actors={{player=true,speed=b.speed}}
  for i,e in ipairs(b.enemies)do if e.hp>0 then actors[#actors+1]={index=i,speed=e.speed}end end
  table.sort(actors,function(a,c)if a.speed==c.speed then return (a.index or 0)<(c.index or 0)end;return a.speed>c.speed end)
  local shield=false
  local function record(actor,label,amount,target)
    local event={actor=actor,label=label,amount=amount,target=target,hp=b.hp,enemyHP={}}
    for i,e in ipairs(b.enemies)do
      event.enemyHP[i]=e.hp
      if e.hp<=0 and not e.defeatedAt then e.defeatedAt=round.at+#round.events*0.55+0.2 end
    end
    round.events[#round.events+1]=event
  end
  for _,actor in ipairs(actors)do
    if b.hp<=0 then break end
    if actor.player then
      local target;for _,e in ipairs(b.enemies)do if e.hp>0 then target=e;break end end
      if not target then break end
      if action=="heal" then
        local label="Healing herb"
        if s.inventory.medicine>0 then s.inventory.medicine=s.inventory.medicine-1
        else s.tokens=s.tokens-P.items.medicine.cost;label="Token heal" end
        local before=b.hp;b.hp=math.min(b.maxHP,b.hp+math.ceil(b.maxHP*0.4));round.heal=b.hp-before
        record(0,label,round.heal)
      elseif action=="guard" then record(0,"Guard",0)
      else
        local effect=action=="burst" and ability.effect or "strike"
        local power=b.attack*(0.9+P.random(0,20)/100)
        local multiplier=effect=="bite" and 1.8 or effect=="flurry" and 1.65 or effect=="cleave" and 0.9 or effect=="renew" and 0.8 or effect=="drain" and 1.1 or 1
        local hit=damage(power*multiplier,target.armor)
        target.hp=math.max(0,target.hp-hit);round.hit=hit
        if effect=="cleave" then for _,e in ipairs(b.enemies)do if e~=target and e.hp>0 then e.hp=math.max(0,e.hp-damage(power*0.9,e.armor))end end end
        if effect=="renew" or effect=="drain" then b.hp=math.min(b.maxHP,b.hp+math.floor(effect=="renew" and b.maxHP*0.18 or hit*0.6))end
        shield=effect=="shield"
        if action=="burst" then b.cooldown=3 end
        record(0,action=="burst" and ability.ability or "Strike",hit,target.index)
      end
    else
      local e=b.enemies[actor.index]
      if e.hp>0 then
        local heavy=(b.turn+1)%3==0
        local hit=damage(e.attack*(heavy and 1.6 or 1)*(action=="guard" and 0.25 or shield and 0.45 or 1),b.armor)
        b.hp=math.max(0,b.hp-hit);round.hurt=round.hurt+hit
        pet.happy=clamp(pet.happy-math.min(5,hit/b.maxHP*20))
        record(actor.index,heavy and "Heavy attack" or "Attack",hit)
      end
    end
  end
  b.turn=b.turn+1;pet.health=clamp(b.hp/b.maxHP*100)
  round.duration=math.max(1.6,#round.events*0.55+0.3)
  if b.hp<=0 then P.Die(pet,"Tower floor "..b.floor);return true end
  local living=0;for _,e in ipairs(b.enemies)do if e.hp>0 then living=living+1;b.enemy=e end end
  if living==0 then
    local first=b.floor>pet.best;pet.best=math.max(pet.best,b.floor);pet.wins=pet.wins+1
    local xp=P.AddXP(pet,math.floor((30+b.floor*6)*(first and 1 or 0.4)))
    -- First clears are the main income; repeat farming gives only one token.
    local reward=first and 5+math.floor(b.floor/10) or 1
    local treat=first and P.random(1,100)<=10 and 1 or 0
    s.inventory.food=s.inventory.food+treat
    s.tokens=s.tokens+reward;pet.happy=clamp(pet.happy+8);s.battle=nil
    P.victory={petID=pet.id,floor=b.floor,first=first,xp=xp,tokens=reward,treats=treat,round=round,readyAt=round.at+round.duration}
    P.notice="Floor "..b.floor.." cleared! +"..reward.." tokens. "..(treat>0 and "+1 trail treat! " or "")..(pet.best==100 and "Tower conquered!" or first and "Next floor unlocked." or "Repeat clear.")
  else P.notice="Round "..b.turn.." - "..living.." enemies remaining. "..((b.turn+1)%3==0 and "Heavy attacks next round." or "Fighting automatically.")end
  return true
end
function P.AdvanceBattle(dt,visible)
  local b=P.state and P.state.battle
  if not b or b.paused or not visible then return end
  b.elapsed=(b.elapsed or 0)+math.min(dt,0.25)
  if b.elapsed<(P.lastRound and P.lastRound.duration or 1.6)then return end
  b.elapsed=0
  local ability=P.Ability(P.Active())
  local action=b.pendingHeal
  b.pendingHeal=nil
  if action=="heal" and P.state.inventory.medicine<1 and P.state.tokens<P.items.medicine.cost then
    b.paused=true;P.notice="Queued heal needs a healing herb or 4 tokens. Battle paused."
    if P.Render then P.Render()end
    return
  end
  action=action or ((b.turn+1)%3==0 and "guard" or ability and not P.IsHealingAbility(ability) and b.cooldown==0 and "burst" or "strike")
  P.BattleAction(action);if P.Render then P.Render()end
end

-- Rewards are virtual addon items. A paired successful encounter event is the
-- evidence of a boss kill; arbitrary elite kills and other players' messages are not.
local function instance()
  if not GetInstanceInfo then return end
  local ok,_,kind,_,_,_,_,_,id=pcall(GetInstanceInfo)
  if ok and readable(kind) and readable(id) and (kind=="party" or kind=="raid") and integer(id,1,100000)then return kind,id end
end
function P.EncounterStart(id,name)
  P.encounter=nil
  if not P.state or not readable(id) or not readable(name) or not integer(id,1,100000) or type(name)~="string" then return end
  local kind,map=instance();if not kind then return end
  P.encounter={id=id,name=name,kind=kind,map=map}
end
function P.EncounterEnd(id,name,success)
  local e=P.encounter;P.encounter=nil
  if not e or not readable(id) or not readable(name) or not readable(success) or success~=1 or id~=e.id or name~=e.name then return end
  local kind,map=instance();if kind~=e.kind or map~=e.map then return end
  local now=F.Now();local key=map..":"..id;local claims=P.state.bossClaims
  local cooldown=kind=="raid" and 604800 or 86400
  if claims[key] and now-claims[key]<cooldown then return end
  for claim,when in pairs(claims)do if now-when>=604800 then claims[claim]=nil end end
  claims[key]=now
  if kind=="party" then
    P.state.tokens=P.state.tokens+3
    if P.random(1,100)<=20 then
      local roll=P.random(1,100);local pack=roll<=60 and 2 or roll<=90 and 3 or 4
      P.state.packs[pack]=P.state.packs[pack]+1
      P.notice="Dungeon boss reward: "..D.packs[pack].name.."! Open it free in Adopt. +3 tokens."
    else P.notice="Dungeon boss defeated: +3 pet tokens." end
  else
    P.state.tokens=P.state.tokens+10
    local species=D.bosses[name]
    if species and P.random(1,100)<=5 then
      P.state.bossEggs[species]=(P.state.bossEggs[species] or 0)+1
      P.notice=name.." companion earned! Claim it in Adopt. +10 tokens."
    else P.notice="Raid boss defeated: +10 pet tokens." end
  end
  if P.Render then P.Render()end
end
local events=CreateFrame("Frame");P.encounterEvents=events
events:RegisterEvent("ENCOUNTER_START");events:RegisterEvent("ENCOUNTER_END")
events:SetScript("OnEvent",function(frame,event,id,name,difficulty,groupSize,success)
  if event=="ENCOUNTER_START" then P.EncounterStart(id,name)else P.EncounterEnd(id,name,success)end
end)
