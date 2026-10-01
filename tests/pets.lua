local F=...
local P=F.Pets
local old=P.state;local oldRandom=P.random;local oldChar=F.char.pets
local oldNotice,oldWindow,oldMini=P.notice,P.window,P.mini
F.char.pets=nil;P.Init();assert(not P.state.share and not P.state.review)
assert(#P.species==100 and #P.packs==6)
local names={};for _,name in ipairs(P.species)do assert(not names[name]);names[name]=true end
local roll=1;P.random=function(a,b)return b==100 and roll or a end
P.state.tokens=100000
for index,pack in ipairs(P.packs)do
  local total=0
  for rarity,chance in ipairs(pack.odds)do
    if chance>0 then
      for _,value in ipairs({total+1,total+chance})do
        roll=value;local tokens=P.state.tokens
        local ok,pet=P.Adopt(index);assert(ok and pet.rarity==rarity and pet.species<=84)
        assert(P.state.tokens==tokens-pack.cost,'Exactly the displayed cost is charged')
      end
    end
    total=total+chance
  end
  assert(total==100)
end
local pet=P.Active();local other=P.state.pets[#P.state.pets]
assert(pet.id==1 and pet~=other,'Adoption does not replace an equipped companion')
assert(P.Select(other.id));pet=P.Active()
local age=pet.age;local otherAge=P.state.pets[1].age;local food=pet.food
P.Tick(1);assert(pet.food<food and pet.age==age+1 and P.state.pets[1].age==otherAge)
P.Init();assert(P.Active()==pet and pet.age==age+1,'Reload preserves collection without offline decay')
P.Tick(100000);assert(pet.age==age+6)
P.state.rewardSeconds=299;local tokens=P.state.tokens;P.Tick(1);assert(P.state.tokens==tokens+2)
pet.food=10;local stock=P.state.inventory.food;assert(P.Care('food'));assert(pet.food==45 and P.state.inventory.food==stock-1)
assert(P.Care('rest'));local energy=pet.energy;P.Tick(5);assert(pet.energy>=energy)
local supplies=P.state.inventory.toy;tokens=P.state.tokens;assert(P.Buy('toy'));assert(P.state.inventory.toy==supplies+1 and P.state.tokens==tokens-3)
P.state.packs[6]=1;tokens=P.state.tokens;assert(P.Adopt(6));assert(P.state.tokens==tokens and P.state.packs[6]==0)
assert(not P.Adopt(0) and not P.Adopt(7) and not P.Rescue())
for floor=1,100 do
  local enemies=P.Enemies(floor);assert(#enemies==(floor<=33 and 1 or floor<=66 and 2 or 3))
  assert(enemies[1].boss==(floor%10==0))
  for _,e in ipairs(enemies)do assert(e.maxHP>0 and e.attack>0 and e.species<=100)end
end
assert(not P.Enemy(101) and not P.Enemy(0) and not P.Enemy(1.5))
pet.health=100;pet.energy=100;pet.food=100;pet.rarity=1
assert(not P.StartBattle(2));assert(P.StartBattle(1));assert(not P.Select(other.id) and not P.Adopt())
assert(not P.Care('food') and not P.BattleAction('burst'),'Common pets cannot use abilities')
assert(P.BattleAction('retreat'));assert(pet.energy==85)
pet.rarity=3;pet.health=100;pet.energy=100;assert(P.StartBattle(1))
P.state.battle.enemy.hp=10000
assert(P.BattleAction('burst') and not P.BattleAction('burst'))
assert(P.BattleAction('retreat'))
pet.health=100;pet.energy=100;assert(P.StartBattle(1));P.state.battle.enemy.hp=1
assert(P.BattleAction('strike'));assert(pet.best==1 and pet.wins==1)
pet.health=100;pet.energy=100;assert(P.StartBattle(2));P.state.battle.enemy.attack=100000
P.BattleAction('guard');assert(pet.deadAt and not P.Active() and not P.Select(pet.id))
P.Init();assert(pet.deadAt and not P.Care('medicine'))
for _,p in ipairs(P.state.pets)do p.deadAt=p.deadAt or F.Now();p.health=0 end
P.state.tokens=0;assert(not P.Adopt());assert(P.Rescue(),'Common rescue prevents an empty stable soft lock')
pet=P.Active();assert(pet.rarity==1);pet.health=0.01;pet.food=0;P.Tick(5);assert(pet.deadAt)
assert(P.Rescue());pet=P.Active();P.state.review=true;P.state.seal=123;P.Init();assert(not P.state.review and not P.state.seal)
-- At matching level, every species and rarity can beat the final encounter with
-- supplies. This is a viability test, not a promise of survival at low health.
local wins=0;local maxHerbs=0
for species=1,100 do
  for rarity=1,5 do
    pet.species=species;pet.rarity=rarity;pet.level=100;pet.xp=0;pet.best=99;pet.wins=0
    pet.health=100;pet.food=100;pet.energy=100;pet.deadAt=nil;P.state.active=pet.id
    P.state.inventory.medicine=30
    assert(P.StartBattle(100))
    for tick=1,1600 do if not P.state.battle then break end;P.AdvanceBattle(0.25,true)end
    assert(not P.state.battle and not pet.deadAt and pet.best==100,'Level 100 encounter viability: '..species..' / '..rarity)
    wins=wins+1;maxHerbs=math.max(maxHerbs,30-P.state.inventory.medicine)
  end
end
print('PASS: 100 Warcraft species, exact six-pack odds and costs, collection persistence, permanent death, 500 final-floor matchups; max herbs '..maxHerbs)
assert(wins==500 and not P.StartBattle(101))
pet.species=1;pet.rarity=3
local oldLevel,oldEffective,oldGray=UnitLevel,UnitEffectiveLevel,UnitQuestTrivialLevelRange
local oldGUID,oldAccess,oldSecret,oldNow=UnitGUID,canaccessvalue,issecretvalue,F.Now
local clock=10000;F.Now=function()return clock end
UnitGUID=function(unit)return unit=='player' and 'Player-self' or unit=='pet' and 'Pet-self' end
UnitLevel=function()return 20 end;UnitEffectiveLevel=function()return 20 end;UnitQuestTrivialLevelRange=function()return 6 end
local function observed(guid,level)P.enemyLevels[guid]={level=level or 20,seen=clock}end
for _,guid in ipairs({'Creature-first','Creature-other','Player-enemy','Creature-cap','Creature-dead'})do observed(guid)end
for i=1,30 do observed('Creature-'..i)end
pet.level=1;pet.xp=0;P.recentKills={};P.combatWindow=nil
assert(P.events.events.PARTY_KILL,'Standalone Forever kill event registered')
P.events.scripts.OnEvent(nil,'PARTY_KILL','Player-self','Creature-first');assert(pet.xp==3,'Standalone kill event awards NPC XP')
local secret=setmetatable({},{__eq=function()error('Restricted value compared')end,__tostring=function()error('Restricted value stringified')end})
canaccessvalue=function(value)return not rawequal(value,secret)end
P.events.scripts.OnEvent(nil,'PARTY_KILL',secret,'Creature-secret')
P.events.scripts.OnEvent(nil,'PARTY_KILL','Player-self',secret)
UnitGUID=function()return secret end;P.events.scripts.OnEvent(nil,'PARTY_KILL','Player-self','Creature-secret')
UnitGUID=function(unit)return unit=='player' and 'Player-self' or unit=='pet' and 'Pet-self' end
canaccessvalue=nil;issecretvalue=function(value)return rawequal(value,secret)end
P.events.scripts.OnEvent(nil,'PARTY_KILL',secret,'Creature-secret')
assert(pet.xp==3 and not P.recentKills['Creature-secret'],'Restricted identities ignored without comparison or XP')
canaccessvalue,issecretvalue=oldAccess,oldSecret
P.CombatKill('PARTY_KILL','Player-self','Creature-first');assert(pet.xp==3,'Duplicate kill ignored')
P.CombatKill('UNIT_DIED','Player-self','Creature-other')
P.CombatKill('PARTY_KILL','Player-other','Creature-other')
P.CombatKill('PARTY_KILL','Player-self','Pet-enemy');assert(pet.xp==3,'Other players, nonkills and enemy pets give no XP')
P.CombatKill('PARTY_KILL','Pet-self','Player-enemy');assert(pet.xp==13,'Combat pet PvP killing blow awards XP')
P.CombatKill('PARTY_KILL','Player-self','Player-enemy');assert(pet.xp==13,'PvP repeat ignored')
for i=1,30 do P.CombatKill('PARTY_KILL','Player-self','Creature-'..i)end
assert(P.combatXP==60 and pet.level==3 and pet.xp==5,'Rate limit and level carry-over enforced')
clock=clock+61;P.CombatKill('PARTY_KILL','Player-self','Player-enemy');assert(pet.xp==5,'Repeat remains blocked across rate windows')
clock=clock+240;observed('Player-enemy');P.CombatKill('PARTY_KILL','Player-self','Player-enemy');assert(pet.xp==15,'Target can award again after five minutes')
pet.level=100;pet.xp=0;P.CombatKill('PARTY_KILL','Player-self','Creature-cap');assert(pet.xp==0,'Max-level pet gains no XP')
P.Die(pet,'test');P.CombatKill('PARTY_KILL','Player-self','Creature-dead');assert(pet.xp==0,'Dead pet gains no XP')
assert(P.Rescue());pet=P.Active()
observed('Creature-low',14);observed('Creature-high',26);observed('Creature-gray',15)
assert(not P.EligibleKill('Creature-low') and not P.EligibleKill('Creature-high'),'Out-of-range enemies rejected')
UnitQuestTrivialLevelRange=function()return 4 end
assert(not P.EligibleKill('Creature-gray'),'Gray enemy rejected even within five levels')
UnitQuestTrivialLevelRange=function()return 6 end
observed('Creature-edge',15);assert(P.EligibleKill('Creature-edge'),'Non-gray lower boundary accepted')
observed('Creature-edge',25);assert(P.EligibleKill('Creature-edge'),'Upper boundary accepted')
clock=clock+61;assert(not P.EligibleKill('Creature-edge'),'Stale observation rejected')
assert(not P.EligibleKill('Creature-unseen'),'Unseen enemy gets no guessed XP')
observed('Creature-known',20)
canaccessvalue=function(value)return not rawequal(value,secret)end
UnitEffectiveLevel=function()return secret end
assert(not P.EligibleKill('Creature-known'),'Restricted character level gives no XP')
UnitEffectiveLevel=function()return 20 end;UnitQuestTrivialLevelRange=function()return secret end
assert(not P.EligibleKill('Creature-known'),'Restricted gray threshold gives no XP')
UnitLevel,UnitEffectiveLevel,UnitQuestTrivialLevelRange=oldLevel,oldEffective,oldGray
UnitGUID,canaccessvalue,issecretvalue,F.Now=oldGUID,oldAccess,oldSecret,oldNow
P.SetSharing(true);P.Receive('3,1,2,20,100,3,3','PARTY','Other')
assert(P.peers.Other)
P.Receive('3,1,2,999,100,3,3','PARTY','Invalid');assert(not P.peers.Invalid)
P.Receive('3,1,2,20,100,3,3','WHISPER','Stranger');assert(not P.peers.Stranger)
P.SetSharing(false);P.Receive('3,1,2,20,100,3,3','PARTY','Off');assert(not P.peers.Off)
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
assert(P.InspectTarget());assert(last[1]=='ASK3' and last[2]=='WHISPER' and last[3]=='Visitor')
assert(not P.InspectTarget(),'Inspect requests are throttled')
P.Receive('3,4,5,20,100,3,3','WHISPER','Unrelated');assert(not P.peers.Unrelated)
P.Receive('3,4,5,20,100,3,3','WHISPER','Visitor');assert(P.peers.Visitor and P.inspectName=='Visitor' and not P.pendingInspect)
P.Receive('ASK3','WHISPER','Asker');assert(last[1]:match('^3,') and last[3]=='Asker','Opted-in player answers inspection')
local before=sends;P.Receive('ASK3','WHISPER','Asker');assert(sends==before,'Repeated requests are throttled')
P.SetSharing(false);P.Share();P.Receive('ASK3','WHISPER','Off');assert(sends==before and not next(P.peers),'Opt-out prevents replies and clears pets')
C_ChatInfo,IsInGuild,IsInGroup,IsInRaid=oldChat,oldGuild,oldGroup,oldRaid
UnitIsPlayer,UnitIsUnit,GetUnitName=oldIsPlayer,oldIsUnit,oldGetName
P.window=nil;P.BuildUI();P.window:Show()
local oldPreview=F.db.settings.debugAlliance
local background
P.window.scene.bg.SetTexture=function(_,path)background=path end
F.db.settings.debugAlliance=true;P.Render();assert(background:find('Alliance',1,true),'Alliance scene follows preview')
F.db.settings.debugAlliance=false;P.Render();assert(background:find('Horde',1,true),'Horde scene uses its own artwork')
F.db.settings.debugAlliance=oldPreview
for _,mode in ipairs({'collection','tower','peers'})do P.mode=mode;P.Render()end
P.SetSharing(true);P.Receive('3,1,2,2,100,1,1','PARTY','Alpha');P.Receive('3,4,5,100,10000,100,100','PARTY','Zulu')
P.inspectName=nil;P.page=1;P.mode='peers';P.Render()
assert(P.window.social.text.text:find('Alpha',1,true),'Pet viewer sorts by name, never strength')
P.page=2;P.Render();assert(P.window.social.text.text:find('Zulu',1,true),'Every shared pet can be inspected')
P.SetSharing(false);P.Render();assert(not P.window.scene.pet.shown,'Opt-out hides cached portraits')
local oldExpanded,oldPets=F.char.navExpanded,F.char.navPets
P.ToggleCompass(true);assert(F.char.navPets and not F.char.navExpanded and P.mini.shown and not F.compass.map.shown)
P.window:Hide();P.Render();assert(P.mini.stats.text:find('Lv',1,true),'Compact game renders while large window is closed')
P.miniMode='care';P.Render();local oldFood=P.Active().food;P.Active().food=50;P.mini.care[1].scripts.OnClick();assert(P.Active().food==85,'Compass care uses the same active pet')
P.Active().food=oldFood
P.mini.towerButton.scripts.OnClick();assert(P.miniMode=='tower' and P.mini.enter.shown and not P.mini.care[1].shown)
P.floor=1;P.Active().energy=100;P.Active().food=100;P.Active().health=100;P.mini.enter.scripts.OnClick();assert(P.state.battle,'Tower starts inside compass')
P.mini.battle[3].scripts.OnClick();assert(not P.state.battle,'Retreat works inside compass')
P.Active().health=100;P.Active().energy=100;assert(P.StartBattle(1))
local b=P.state.battle
P.AdvanceBattle(100,false);assert(b.turn==0,'Hidden battles pause')
P.PauseBattle();for i=1,20 do P.AdvanceBattle(0.1,true)end;assert(b.turn==0,'Explicit pause prevents attacks')
P.PauseBattle();P.AdvanceBattle(100,true);assert(b.turn==0,'Loading gap does not fast-forward combat')
for i=1,16 do P.AdvanceBattle(0.1,true)end;assert(b.turn==1 and P.lastRound,'Visible battles progress with animation records')
P.BattleAction('retreat')

P.mini.scene.scripts.OnUpdate(P.mini.scene,0.1)
F.compass.expand.scripts.OnClick();assert(F.char.navExpanded and not F.char.navPets and not P.mini.shown and F.compass.map.shown,'Map and pet switch without covering route')
F.char.navExpanded,F.char.navPets=oldExpanded,oldPets;F.UpdateNavigator()
-- Inspect supports all new species and derives the same family stats.
P.SetSharing(true);P.Receive('3,100,4,50,100,20,30','PARTY','BossOwner')
assert(P.peers.BossOwner and P.Stats(P.peers.BossOwner)>0)
P.Receive('3,101,4,50,100,20,30','PARTY','BadSpecies');assert(not P.peers.BadSpecies)
P.SetSharing(false)
-- Collection rows only preview; Equip is deliberate and blocked during combat.
P.mode='collection';P.window:Show();P.page=1;P.Render()
local equipped=P.state.active
P.window.collection.rows[1].scripts.OnClick(P.window.collection.rows[1])
assert(P.state.active==equipped and P.viewID==P.state.pets[1].id)
P.OpenAdopt();assert(P.adoption:IsShown() and #P.adoption.cards==6)
P.RenderAdopt();P.adoption:Hide()
local priorSpecies=P.Active().species;P.viewID=P.Active().id
P.window.scene.pet.SetTexCoord=function(_,left,right,top,bottom)
  assert(left>=0 and left<=1 and right>=0 and right<=1 and top>=0 and bottom<=1 and top<bottom)
end
for species=1,100 do P.Active().species=species;P.Render()end
P.Active().species=priorSpecies
-- Each actor has its own visible turn, with speed affecting order.
pet=P.Active();pet.best=66;pet.level=67;pet.health=100;pet.food=100;pet.energy=100;pet.species=35;pet.rarity=1
assert(P.StartBattle(67));local multi=P.state.battle;assert(#multi.enemies==3)
P.BattleAction('strike');assert(#P.lastRound.events==4 and P.lastRound.events[1].actor~=0)
P.BattleAction('retreat')
-- A full first-clear climb is possible with a common rescue and regular care.
pet.species=1;pet.level=1;pet.rarity=1;pet.best=0;pet.xp=0;pet.wins=0
local climbHerbs=0
for floor=1,100 do
  pet.health=100;pet.food=100;pet.energy=100;P.state.inventory.medicine=30
  assert(P.StartBattle(floor))
  for tick=1,1600 do if not P.state.battle then break end;P.AdvanceBattle(0.25,true)end
  assert(not pet.deadAt and not P.state.battle and pet.best==floor,'First-clear common climb at floor '..floor)
  climbHerbs=climbHerbs+30-P.state.inventory.medicine
end
print('PASS: 100-floor common-pet climb with care between floors; herbs '..climbHerbs..', final level '..pet.level)
-- Successful server encounter pairs only; no reward on wipes, duplicates,
-- outdoor elites, mismatched instances, restricted values or an unpaired end.
local savedInfo,savedNow=GetInstanceInfo,F.Now
local kind,map,now='party',33,1000000
GetInstanceInfo=function()return 'Test dungeon',kind,1,'Normal',5,0,false,map end
F.Now=function()return now end
P.random=function(a,b)return a end
local beforeTokens=P.state.tokens;local packs=P.state.packs[2]
P.EncounterEnd(1,'Test boss',1);assert(P.state.tokens==beforeTokens)
P.EncounterStart(1,'Test boss');P.EncounterEnd(1,'Test boss',0);assert(P.state.tokens==beforeTokens)
P.encounterEvents.scripts.OnEvent(nil,'ENCOUNTER_START',1,'Test boss',1,5)
P.encounterEvents.scripts.OnEvent(nil,'ENCOUNTER_END',1,'Test boss',1,5,1)
assert(P.state.tokens==beforeTokens+3 and P.state.packs[2]==packs+1)
P.Init();P.EncounterStart(1,'Test boss');P.EncounterEnd(1,'Test boss',1)
assert(P.state.tokens==beforeTokens+3,'Boss cooldown survives reload')
now=now+86400;P.EncounterStart(1,'Test boss');P.EncounterEnd(1,'Test boss',1)
assert(P.state.tokens==beforeTokens+6)
beforeTokens=P.state.tokens
kind='none';P.EncounterStart(2,'Outdoor elite');P.EncounterEnd(2,'Outdoor elite',1);assert(P.state.tokens==beforeTokens)
kind='party';P.EncounterStart(2,'Test boss');map=34;P.EncounterEnd(2,'Test boss',1);assert(P.state.tokens==beforeTokens)
local safeAccess=canaccessvalue
canaccessvalue=function(value)return type(value)~='table' end
P.EncounterStart({},'Test boss');P.EncounterEnd({},'Test boss',1);assert(P.state.tokens==beforeTokens)
canaccessvalue=safeAccess
kind='raid';map=409
P.EncounterStart(3,'Ragnaros');P.EncounterEnd(3,'Ragnaros',1)
assert(P.state.bossEggs[85]==1 and P.state.tokens==beforeTokens+10)
local count=#P.state.pets;assert(P.ClaimBoss(85));assert(#P.state.pets==count+1)
local boss=P.state.pets[#P.state.pets];assert(boss.species==85 and boss.rarity==4 and not P.ClaimBoss(85))
P.EncounterStart(4,'Unknown Forever boss');P.EncounterEnd(4,'Unknown Forever boss',1)
assert(P.state.bossEggs[85]==0,'Unknown raid boss never awards a guessed species')
now=now+86400;P.EncounterStart(3,'Ragnaros');P.EncounterEnd(3,'Ragnaros',1);assert(P.state.bossEggs[85]==0)
now=now+604800;P.EncounterStart(3,'Ragnaros');P.EncounterEnd(3,'Ragnaros',1);assert(P.state.bossEggs[85]==1)
-- A lost drop roll still consumes the cooldown; reload cannot reroll it.
P.random=function(a,b)return b end
P.EncounterStart(5,'Onyxia');P.EncounterEnd(5,'Onyxia',1);assert(not P.state.bossEggs[86])
P.Init();P.random=function(a,b)return a end
P.EncounterStart(5,'Onyxia');P.EncounterEnd(5,'Onyxia',1);assert(not P.state.bossEggs[86])
GetInstanceInfo,F.Now=savedInfo,savedNow
print('PASS: preview/equip separation, six-pack UI, 1v3 speed-ordered turns, dungeon/raid rewards, persistent cooldowns and boss claims')
F.char.pets={version=1,pets='broken'};P.Init();assert(not P.state.review and F.char.petQuarantine.pets=='broken','Unreadable save is backed up without accusing the player')
P.state=old;F.char.pets=oldChar;P.random=oldRandom;P.notice=oldNotice;P.window=oldWindow;P.mini=oldMini
print('PASS: pet rarity boundaries, care/persistence, permanent death/memorials, 100-floor gates, battle actions, NPC/PvP combat XP limits, save recovery, opt-in target inspection and compass/large pet UI')
