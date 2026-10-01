local F=...
local P=F.Pets
local old=P.state;local oldRandom=P.random;local oldChar=F.char.pets
local oldNotice,oldWindow,oldPocket=P.notice,P.window,P.pocket
F.char.pets=nil;P.Init();assert(not P.state.share and not P.state.review)
local roll=1;P.random=function(a,b)return b==100 and roll or a end
local ranges={{1,1},{55,1},{56,2},{80,2},{81,3},{94,3},{95,4},{99,4},{100,5}}
P.state.tokens=1000
for _,range in ipairs(ranges)do roll=range[1];assert(P.Adopt());assert(P.Active().rarity==range[2])end
local pet=P.Active();local other=P.state.pets[1];local age,otherAge=pet.age,other.age
local food=pet.food;P.Tick(1)
assert(pet.food<food and pet.age==age+1 and other.age==otherAge,'Only active pet needs care')
local savedAge=pet.age;P.Init();assert(P.Active()==pet and pet.age==savedAge,'Reload must not age or decay offline pets')
P.Tick(100000);assert(pet.age==savedAge+5,'Long loading gaps are capped')
P.state.rewardSeconds=299;local tokens=P.state.tokens;P.Tick(1);assert(P.state.tokens==tokens+1)
pet.food=10;local stock=P.state.inventory.food;assert(P.Care('food'));assert(pet.food==45 and P.state.inventory.food==stock-1)
assert(P.Care('rest'));local energy=pet.energy;P.Tick(5);assert(pet.energy>=energy)
local supplies=P.state.inventory.toy;tokens=P.state.tokens;assert(P.Buy('toy'));assert(P.state.inventory.toy==supplies+1 and P.state.tokens==tokens-3)
for floor=1,100 do local enemy=P.Enemy(floor);assert(enemy and enemy.maxHP>0 and enemy.attack>0);assert(enemy.boss==(floor%10==0))end
assert(not P.Enemy(101) and not P.Enemy(0) and not P.Enemy(1.5))
pet.food=100;pet.health=100;pet.energy=100
assert(not P.StartBattle(2),'Cannot skip tower floors');assert(P.StartBattle(1));assert(not P.Select(other.id))
assert(not P.Care('food'),'Cannot bypass battle turns with care actions')
assert(P.BattleAction('burst'));assert(not P.BattleAction('burst'),'Special cooldown is enforced')
assert(P.BattleAction('retreat'));assert(not P.state.battle and pet.energy==85,'Retreat consumes entry energy')
pet.health=100;pet.energy=100;assert(P.StartBattle(1));P.state.battle.enemy.hp=1
assert(P.BattleAction('strike'));assert(pet.best==1 and pet.wins==1 and not pet.deadAt)
local deadPet=pet;pet.health=100;pet.energy=100;assert(P.StartBattle(2));P.state.battle.enemy.attack=100000
P.BattleAction('guard');assert(deadPet.deadAt and deadPet.deathReason=='Tower floor 2' and not P.Active())
P.Init();assert(deadPet.deadAt,'Death survives reload')
assert(not P.Select(deadPet.id) and not P.Care('medicine'),'Death cannot be reversed by care or switching')
local deadAge=deadPet.age;P.Tick(5);assert(deadPet.age==deadAge,'Memorial lifespan is frozen')
for _,p in ipairs(P.state.pets)do p.deadAt=p.deadAt or F.Now();p.health=0 end
P.state.tokens=0;assert(P.Adopt(),'Free replacement prevents a permanent soft lock')
pet=P.Active();pet.health=0.01;pet.food=0;P.Tick(5);assert(pet.deadAt and pet.deathReason=='Neglect')
assert(P.Adopt());pet=P.Active();P.state.review=true;P.state.seal=123;P.Init();assert(not P.state.review and not P.state.seal,'Old integrity flags are retired')
pet.level=100;pet.xp=0;pet.best=99;pet.wins=99;pet.health=100;pet.food=100;pet.energy=100;P.state.inventory.medicine=20
assert(P.StartBattle(100))
for turn=1,30 do
  local battle=P.state.battle;if not battle then break end
  local action=(battle.turn+1)%3==0 and 'guard' or battle.hp<battle.maxHP*0.65 and 'heal' or battle.cooldown==0 and 'burst' or 'strike'
  assert(P.BattleAction(action))
end
assert(not pet.deadAt and pet.best==100 and pet.level==100 and pet.xp==0,'Final boss is beatable with guard/heal timing and level stays capped')
assert(not P.StartBattle(101))
local oldGUID,oldCombat,oldNow=UnitGUID,CombatLogGetCurrentEventInfo,F.Now
local clock=10000;F.Now=function()return clock end
UnitGUID=function(unit)return unit=='player' and 'Player-self' or unit=='pet' and 'Pet-self' end
pet.level=1;pet.xp=0;P.recentKills={};P.combatWindow=nil
CombatLogGetCurrentEventInfo=function()return clock,'PARTY_KILL',false,'Player-self','Me',0,0,'Creature-first' end
P.events.scripts.OnEvent(nil,'COMBAT_LOG_EVENT_UNFILTERED');assert(pet.xp==3,'Actual combat event awards NPC XP')
P.CombatKill('PARTY_KILL','Player-self','Creature-first');assert(pet.xp==3,'Duplicate kill ignored')
P.CombatKill('UNIT_DIED','Player-self','Creature-other')
P.CombatKill('PARTY_KILL','Player-other','Creature-other')
P.CombatKill('PARTY_KILL','Player-self','Pet-enemy');assert(pet.xp==3,'Other players, nonkills and enemy pets give no XP')
P.CombatKill('PARTY_KILL','Pet-self','Player-enemy');assert(pet.xp==13,'Combat pet PvP killing blow awards XP')
P.CombatKill('PARTY_KILL','Player-self','Player-enemy');assert(pet.xp==13,'PvP repeat ignored')
for i=1,30 do P.CombatKill('PARTY_KILL','Player-self','Creature-'..i)end
assert(P.combatXP==60 and pet.level==3 and pet.xp==5,'Rate limit and level carry-over enforced')
clock=clock+61;P.CombatKill('PARTY_KILL','Player-self','Player-enemy');assert(pet.xp==5,'Repeat remains blocked across rate windows')
clock=clock+240;P.CombatKill('PARTY_KILL','Player-self','Player-enemy');assert(pet.xp==15,'Target can award again after five minutes')
pet.level=100;pet.xp=0;P.CombatKill('PARTY_KILL','Player-self','Creature-cap');assert(pet.xp==0,'Max-level pet gains no XP')
P.Die(pet,'test');P.CombatKill('PARTY_KILL','Player-self','Creature-dead');assert(pet.xp==0,'Dead pet gains no XP')
assert(P.Adopt());pet=P.Active()
UnitGUID,CombatLogGetCurrentEventInfo,F.Now=oldGUID,oldCombat,oldNow
P.SetSharing(true);P.Receive('2,1,2,20,100,3,3','PARTY','Other')
assert(P.peers.Other)
P.Receive('2,1,2,999,100,3,3','PARTY','Invalid');assert(not P.peers.Invalid)
P.Receive('2,1,2,20,100,3,3','WHISPER','Stranger');assert(not P.peers.Stranger)
P.SetSharing(false);P.Receive('2,1,2,20,100,3,3','PARTY','Off');assert(not P.peers.Off)
local oldChat,oldGuild,oldGroup,oldRaid=C_ChatInfo,IsInGuild,IsInGroup,IsInRaid
local oldIsPlayer,oldIsUnit,oldGetName=UnitIsPlayer,UnitIsUnit,GetUnitName
local sends,last=0,nil
C_ChatInfo={RegisterAddonMessagePrefix=function()return true end,SendAddonMessage=function(prefix,message,channel,target)
  assert(prefix=='FWLPet1' and #message<255 and (channel=='GUILD' or channel=='PARTY' or channel=='WHISPER'));sends=sends+1;last={message,channel,target}
end}
IsInGuild=function()return true end;IsInGroup=function()return true end;IsInRaid=function()return false end
UnitIsPlayer=function()return true end;UnitIsUnit=function()return false end;GetUnitName=function()return 'Visitor' end
P.Share();assert(sends==0,'No pet sharing without separate opt-in')
assert(not P.InspectTarget(),'Inspect requires opt-in')
P.SetSharing(true);P.Share();assert(sends==2,'One compact report per guild/group')
assert(P.InspectTarget());assert(last[1]=='ASK2' and last[2]=='WHISPER' and last[3]=='Visitor')
assert(not P.InspectTarget(),'Inspect requests are throttled')
P.Receive('2,4,5,20,100,3,3','WHISPER','Unrelated');assert(not P.peers.Unrelated)
P.Receive('2,4,5,20,100,3,3','WHISPER','Visitor');assert(P.peers.Visitor and P.inspectName=='Visitor' and not P.pendingInspect)
P.Receive('ASK2','WHISPER','Asker');assert(last[1]:match('^2,') and last[3]=='Asker','Opted-in player answers inspection')
local before=sends;P.Receive('ASK2','WHISPER','Asker');assert(sends==before,'Repeated requests are throttled')
P.SetSharing(false);P.Share();P.Receive('ASK2','WHISPER','Off');assert(sends==before and not next(P.peers),'Opt-out prevents replies and clears pets')
C_ChatInfo,IsInGuild,IsInGroup,IsInRaid=oldChat,oldGuild,oldGroup,oldRaid
UnitIsPlayer,UnitIsUnit,GetUnitName=oldIsPlayer,oldIsUnit,oldGetName
P.window=nil;P.pocket=nil;P.BuildUI();P.window:Show()
for _,mode in ipairs({'collection','tower','peers'})do P.mode=mode;P.Render()end
P.SetSharing(true);P.Receive('2,1,2,2,100,1,1','PARTY','Alpha');P.Receive('2,4,5,100,10000,100,100','PARTY','Zulu')
P.inspectName=nil;P.page=1;P.mode='peers';P.Render()
assert(P.window.social.text.text:find('Alpha',1,true),'Pet viewer sorts by name, never strength')
P.page=2;P.Render();assert(P.window.social.text.text:find('Zulu',1,true),'Every shared pet can be inspected')
P.SetSharing(false);P.Render();assert(not P.window.social.art.shown,'Opt-out hides cached portraits')
P.pocket:Show();P.Render();P.pocket.scripts.OnUpdate(nil,0.1)
F.char.pets={version=1,pets='broken'};P.Init();assert(not P.state.review and F.char.petQuarantine.pets=='broken','Unreadable save is backed up without accusing the player')
P.state=old;F.char.pets=oldChar;P.random=oldRandom;P.notice=oldNotice;P.window=oldWindow;P.pocket=oldPocket
print('PASS: pet rarity boundaries, care/persistence, permanent death/memorials, 100-floor gates, battle actions, NPC/PvP combat XP limits, save recovery, opt-in target inspection and pet UI')
