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
  local elite=floor%10==0;local count=#enemies;local hp,attack=0,0
  for i,enemy in ipairs(enemies)do
    assert(enemy.elite==(elite and i==1),'Only milestone leaders are elite')
    hp=hp+enemy.maxHP;attack=attack+enemy.attack
    if elite and i>1 then assert(enemies[1].maxHP>enemy.maxHP and enemies[1].attack>enemy.attack,'Elite leader is stronger than its support')end
  end
  local baseHP=(42+floor*8)*(1+(count-1)*0.1);local baseAttack=5+floor*1.8
  if elite then
    assert(hp>=baseHP*1.55-count and attack>=baseAttack*1.25-count)
    assert(enemies[1].armor==math.floor(floor/12)+3)
  else assert(hp==math.floor(baseHP/count)*count and attack==math.floor(baseAttack/count)*count,'Ordinary floors retain their tuning')end
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
local function playerGuidedTick()
  local battle=P.state.battle
  if battle and battle.hp<battle.maxHP*0.6 and (battle.turn+1)%3~=0 and not battle.pendingHeal then P.RequestHeal()end
  P.AdvanceBattle(0.25,true)
end
local wins=0;local maxHerbs=0
for species=1,100 do
  for rarity=1,5 do
    pet.species=species;pet.rarity=rarity;pet.level=100;pet.xp=0;pet.best=99;pet.wins=0
    pet.health=100;pet.food=100;pet.energy=100;pet.deadAt=nil;P.state.active=pet.id
    P.state.inventory.medicine=30
    assert(P.StartBattle(100))
    for tick=1,1600 do if not P.state.battle then break end;playerGuidedTick()end
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
assert(F.window.frameStrata=='HIGH' and P.window.frameStrata=='DIALOG','Pet window renders above every ledger child')
assert(P.window.mouseEnabled and P.window.scene.bg.drawLayer=='BORDER' and P.window.scene.pet.drawLayer=='ARTWORK','Scene lies above panel fill and below sprites')
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
-- Compact care meters and status symbols track the same pet without changing needs.
do
  local pet=P.Active();local saved={pet.food,pet.happy,pet.energy,pet.resting}
  local clock,motion=P.sceneClock,F.db.settings.reduceMotion
  pet.food=24;pet.happy=24;pet.energy=42;pet.resting=true
  P.Render()
  assert(P.mini.food.label.text=='Food 24' and P.mini.happy.label.text=='Happy 24' and P.mini.energy.label.text=='Energy 42')
  assert(P.mini.happy:IsShown() and P.mini.energy:IsShown())
  local f=P.mini.scene;local n=f.needs
  assert(n.sleep[1]:IsShown() and n.sleep[2]:IsShown() and n.sleep[3]:IsShown())
  assert(n.hungry:IsShown() and n.angry:IsShown(),'Low food and happiness can appear together with sleep')
  local positions={}
  local oldPoint=n.sleep[1].SetPoint
  n.sleep[1].SetPoint=function(_,_,_,_,x,y)positions[#positions+1]={x,y}end
  F.db.settings.reduceMotion=false;P.sceneClock=0.4;f.scripts.OnUpdate(f)
  P.sceneClock=1.3;f.scripts.OnUpdate(f)
  assert(positions[1][2]~=positions[2][2],'Sleep marks float upward')
  F.db.settings.reduceMotion=true;P.sceneClock=2;f.scripts.OnUpdate(f)
  P.sceneClock=3;f.scripts.OnUpdate(f)
  assert(positions[3][1]==positions[4][1] and positions[3][2]==positions[4][2],'Reduced motion keeps status marks still')
  n.sleep[1].SetPoint=oldPoint
  pet.food=25;pet.happy=25;pet.resting=false;P.Render()
  assert(not n.sleep[1]:IsShown() and not n.hungry:IsShown() and not n.angry:IsShown(),'Care clears cues at the threshold')
  pet.food=0;pet.happy=0;pet.resting=true;P.miniMode='tower';P.Render()
  assert(not P.mini.happy:IsShown() and not P.mini.energy:IsShown() and not n.sleep[1]:IsShown() and not n.hungry:IsShown(),'Tower controls and combat art stay unobstructed')
  P.miniMode='care';f.needsPet=false;f.scripts.OnUpdate(f)
  assert(not n.sleep[1]:IsShown() and not n.angry:IsShown(),'No companion means no need indicators')
  pet.food,pet.happy,pet.energy,pet.resting=unpack(saved)
  P.sceneClock,F.db.settings.reduceMotion=clock,motion;P.Render()
end
P.mini.towerButton.scripts.OnClick();assert(P.miniMode=='tower' and P.mini.enter.shown and not P.mini.care[1].shown)
P.floor=1;P.Active().energy=100;P.Active().food=100;P.Active().health=100;P.mini.enter.scripts.OnClick();assert(P.state.battle,'Tower starts inside compass')
P.state.battle.hp=math.floor(P.state.battle.maxHP*0.5);P.mini.battle[3].scripts.OnClick();assert(P.state.battle.pendingHeal,'Manual Heal queues inside compass');P.BattleAction('retreat')
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
assert(P.adoption.frameStrata=='FULLSCREEN_DIALOG' and P.window.frameStrata=='DIALOG' and P.adoption.mouseEnabled,'Adoption stays above pets and blocks clicks through the panel')
for _,crate in ipairs(P.packs)do assert(crate.name:find('Adoption Crate',1,true) and crate.icon=='INV_Crate_01')end
P.RenderAdopt();P.adoption:Hide()
-- Client focus can raise a top-level window far beyond its creation-time level.
local petWindowLevel=P.window:GetFrameLevel()
P.window:SetFrameLevel(5000)
P.OpenStore();assert(P.store:IsShown() and not P.adoption:IsShown())
P.OpenAdopt();assert(P.adoption:IsShown() and not P.store:IsShown())
assert(P.adoption.frameStrata=='FULLSCREEN_DIALOG' and P.window.frameStrata=='DIALOG',
  'Adoption remains above Pets after focus raises the pet frame')
P.OpenStore();assert(P.store:IsShown() and not P.adoption:IsShown())
assert(P.store.frameStrata=='FULLSCREEN_DIALOG','Reopened store remains in the higher layer')
P.store:Hide();P.window:SetFrameLevel(petWindowLevel)
local priorSpecies=P.Active().species;P.viewID=P.Active().id
P.window.scene.pet.SetTexCoord=function(_,left,right,top,bottom)
  assert(left>=0 and left<=1 and right>=0 and right<=1 and top>=0 and bottom<=1 and top<bottom)
end
for species=1,100 do P.Active().species=species;P.Render()end
P.Active().species=priorSpecies
local oldFloor,oldMode,oldMiniMode=P.floor,P.mode,P.miniMode
local oldBest=P.Active().best;P.Active().best=99
P.floor=10;P.mode='tower';P.miniMode='tower';P.window:Show();P.mini:Show();P.Render()
assert(P.window.scene.enemyHP[1].detail.text=='ELITE' and P.mini.scene.enemyHP[1].detail.text=='ELITE','Both views identify elite floors')
assert(P.window.tower.info.text:find('ELITE CHAMBER',1,true))
assert(P.window.scene.leftHP.healthFrame and P.mini.health.healthFrame,'Pet health bars use framed styling')
assert(P.window.scene.enemyHP[1].eliteDragon:IsShown() and P.mini.scene.enemyHP[1].eliteDragon:IsShown(),'Elite health bars show the dragon in both views')
assert(P.window.scene.enemyHP[1].hp.barColor[2]==0.85,'Elite health remains green like the normal WoW unit frame')
assert(P.window.scene.enemyHP[1].percent.text=='100%' and P.window.scene.enemyHP[1].amount.text==tostring(P.Enemy(10).maxHP),'Preview shows percentage and actual enemy HP')
assert(P.window.scene.enemyHP[1].name.text==P.species[P.Enemy(10).species] and P.window.scene.enemyHP[1].level.text==10,'Unit frames identify the enemy and floor')
assert(P.mini.scene.height==227,'Compass tower has room for the unit frames')
P.floor=11;P.Render();assert(P.window.scene.enemyHP[1].detail.text=='Enemy 1' and P.mini.scene.enemyHP[1].detail.text=='Enemy 1','Normal floors clear elite markers')
assert(not P.window.scene.enemyHP[1].eliteDragon:IsShown() and not P.mini.scene.enemyHP[1].eliteDragon:IsShown(),'Normal enemies never retain the elite dragon')
P.floor=70;P.Render()
for _,scene in ipairs({P.window.scene,P.mini.scene})do
  assert(scene.enemyHP[3]:IsShown() and not scene.enemyHP[2].eliteDragon:IsShown(),'Supporting enemies have their own ordinary unit frames')
  assert(scene.arenaHeight>60,'Three enemies leave space for the battle below their frames')
end
P.miniMode='care';P.RenderCompass();assert(P.mini.scene.height==137 and not P.mini.scene.leftHP:IsShown(),'Camp restores its compact layout and hides battle frames')
P.floor,P.mode,P.miniMode=oldFloor,oldMode,oldMiniMode;P.Active().best=oldBest
-- Each actor has its own visible turn, with speed affecting order.
pet=P.Active();pet.best=66;pet.level=67;pet.health=100;pet.food=100;pet.energy=100;pet.species=35;pet.rarity=1
assert(P.StartBattle(67));local multi=P.state.battle;assert(#multi.enemies==3)
P.BattleAction('strike');assert(#P.lastRound.events==4 and P.lastRound.events[1].actor~=0)
P.mode='tower';P.miniMode='tower';P.floor=67;P.Render()
P.window.scene.scripts.OnUpdate(P.window.scene)
local event=P.lastRound.events[1]
assert(P.window.scene.leftHP.amount.text==tostring(event.hp),'Pet frame follows the displayed combat event')
for i=1,3 do assert(P.window.scene.enemyHP[i].amount.text==tostring(event.enemyHP[i]),'Enemy frames follow displayed damage independently')end
P.BattleAction('retreat')
-- A full first-clear climb is possible with a common rescue and regular care.
do
  local savedHealth,savedEnergy,savedFood=pet.health,pet.energy,pet.food
  local savedFloor,savedMode,savedMini=P.floor,P.mode,P.miniMode
  local savedNav,savedNavigator=F.char.navPets,F.db.settings.navigator
  local savedWindow=P.window:IsShown()
  for _,view in ipairs({'large','compass'})do
    P.mode='tower';P.miniMode='tower';P.floor=10
    P.window:SetShown(view=='large');P.ToggleCompass(view=='compass')
    pet.health=69.82456;pet.energy=6.43784;pet.food=35.93186;P.Render()
    local button=view=='large' and P.window.fight[1] or P.mini.enter
    local status=view=='large' and P.window.readiness or P.mini.readiness
    assert(status.text=='Need: Energy 6/15','Readiness explains the same low-energy state in both views')
    button.scripts.OnClick()
    assert(not P.state.battle and pet.energy==6.43784 and pet.food==35.93186,'Rejected clicks never consume resources')
    assert(P.notice:find('Rest in Camp',1,true),'Rejected fight tells the player how to recover')
    pet.energy=15;P.Render();assert(status.text=='Ready to fight')
    button.scripts.OnClick()
    assert(P.state.battle and pet.energy==0 and pet.food==30.93186,'Real button handler starts a fight at the exact threshold')
    for tick=1,8 do P.AdvanceBattle(0.25,P.BattleVisible())end
    assert(P.state.battle and P.state.battle.turn>0,'Both views advance the fight after the button click')
    P.BattleAction('retreat')
  end
  pet.health,pet.energy,pet.food=savedHealth,savedEnergy,savedFood
  P.floor,P.mode,P.miniMode=savedFloor,savedMode,savedMini
  P.window:SetShown(savedWindow);P.ToggleCompass(savedNav);F.db.settings.navigator=savedNavigator
end
print('PASS: large and compass Fight clicks, explicit energy requirements, exact threshold, no failed-click costs and automatic turns')
pet.species=1;pet.level=1;pet.rarity=1;pet.best=0;pet.xp=0;pet.wins=0
local climbHerbs=0
for floor=1,100 do
  pet.health=100;pet.food=100;pet.energy=100;P.state.inventory.medicine=30
  assert(P.StartBattle(floor))
  for tick=1,1600 do if not P.state.battle then break end;playerGuidedTick()end
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
local oldClock,oldMotion=P.sceneClock,F.db.settings.reduceMotion
P.sceneClock=100;F.db.settings.reduceMotion=false
pet=P.Active();pet.species=47;pet.rarity=4;pet.level=100;pet.best=66;pet.health=100;pet.food=100;pet.energy=100
P.mode='tower';P.miniMode='tower';P.window:Show();P.ToggleCompass(true)
assert(P.StartBattle(67));local encounter=P.state.battle
encounter.enemies[1].hp=1;encounter.enemies[2].hp=10000;encounter.enemies[3].hp=10000
P.BattleAction('strike');assert(P.state.battle and not P.victory,'Partial kills do not win the floor')
P.Render()
local alpha;P.window.scene.enemies[1].SetAlpha=function(_,value)alpha=value end
local deathTime=encounter.enemies[1].defeatedAt
P.sceneClock=deathTime-0.01;P.window.scene.scripts.OnUpdate(P.window.scene);assert(alpha==1,'No fade before the lethal hit')
P.sceneClock=deathTime+0.325;P.window.scene.scripts.OnUpdate(P.window.scene);assert(math.abs(alpha-0.5)<0.001,'Defeated enemies fade smoothly')
F.db.settings.reduceMotion=true;P.window.scene.scripts.OnUpdate(P.window.scene);assert(alpha==0,'Reduced motion hides defeated enemies immediately')
F.db.settings.reduceMotion=false;P.sceneClock=deathTime+3
encounter.enemies[2].hp=1;encounter.enemies[3].hp=1
P.BattleAction('burst');local victory=P.victory
assert(victory and victory.first and victory.floor==67 and victory.tokens==11 and P.FloorStatus(67)=='Completed')
P.Render();assert(not P.window.scene.victory.shown,'Victory waits for the final turn and fade')
P.sceneClock=victory.readyAt+4;P.Render()
assert(P.window.scene.victory.shown and P.mini.scene.victory.shown,'Both tower views show victory')
assert(alpha==0 and P.window.scene.displayEnemies==victory.round.enemies,'Enemies do not reappear after the old three-second timeout')
assert(P.window.tower.info.text:find('Completed',1,true) and P.mini.enter.label.text=='Replay')
local awarded=P.state.tokens;P.Render();P.Render();assert(P.state.tokens==awarded,'Rendering cannot duplicate rewards')
P.mini.scene.victory.next.scripts.OnClick()
assert(P.floor==68 and not P.state.battle and not P.window.scene.victory.shown and P.FloorStatus(68)=='Not cleared','Next selects without auto fighting')
pet.energy=100;pet.food=100;pet.health=100;assert(P.StartBattle(67));P.Render()
assert(not P.victory and alpha==1,'Replay resets enemy opacity and old victory')
P.BattleAction('retreat');assert(not P.CurrentVictory(),'Retreat has no victory panel')
pet.best=99;pet.health=100;pet.food=100;pet.energy=100;assert(P.StartBattle(100))
for _,enemy in ipairs(P.state.battle.enemies)do enemy.hp=1 end
P.BattleAction('burst');P.sceneClock=P.victory.readyAt+1;P.Render()
assert(P.window.scene.victory.title.text=='TOWER CONQUERED' and P.window.scene.victory.next.text=='Done')
P.window.scene.victory.next.scripts.OnClick()
assert(P.floor==100 and not P.state.battle and not P.window.scene.victory.shown,'Final floor never advances beyond 100')
P.Init();assert(P.FloorStatus(67)=='Completed' and not P.victory,'Completion survives reload, presentation is transient')
P.sceneClock=oldClock;F.db.settings.reduceMotion=oldMotion
print('PASS: timed enemy fade, reduced motion, shared victory panels, persistent completion, replay reset and no auto-start/reward duplication')
do
  F.char.pets=nil;P.Init();P.random=function(a,b)return a end;assert(P.Rescue())
  local companion=P.Active();companion.species=45;companion.rarity=3;companion.level=100;companion.health=40
  P.state.tokens=20;P.state.inventory.medicine=5
  assert(P.StartBattle(1));local battle=P.state.battle;battle.enemy.hp=10000;battle.enemy.attack=1
  local hp=battle.hp
  local function nextRound()
    local turn=battle.turn
    for i=1,20 do P.AdvanceBattle(0.25,true);if not P.state.battle or battle.turn>turn then return end end
    error('Expected a battle round')
  end
  nextRound()
  assert(battle.hp<hp and P.state.inventory.medicine==5 and P.state.tokens==20 and battle.cooldown==0,'No automatic healing, including healing abilities')
  assert(P.RequestHeal() and battle.pendingHeal=='burst' and not P.RequestHeal())
  hp=battle.hp;nextRound();assert(battle.hp>hp and P.state.inventory.medicine==5 and P.state.tokens==20,'Click can use a ready healing ability for free')
  battle.hp=math.floor(battle.maxHP*0.3);assert(P.RequestHeal());nextRound()
  assert(P.state.inventory.medicine==4 and P.state.tokens==20,'Manual heal consumes one herb before tokens')
  companion.rarity=1;P.state.inventory.medicine=0;battle.hp=math.floor(battle.maxHP*0.3)
  local happy=companion.happy
  assert(P.RequestHeal() and P.state.tokens==20,'Queueing costs nothing')
  P.PauseBattle();P.AdvanceBattle(100,true);assert(P.state.tokens==20 and battle.pendingHeal)
  P.PauseBattle();nextRound()
  assert(P.state.tokens==16 and companion.happy<happy,'Manual fallback costs four tokens and hits reduce happiness')
  P.state.tokens=3;battle.hp=1;assert(not P.RequestHeal(),'Cannot queue unaffordable healing')
  P.state.tokens=20;assert(P.RequestHeal());battle.enemy.speed=1000;battle.enemy.attack=100000
  nextRound();assert(companion.deadAt and P.state.tokens==20,'Faster lethal enemy prevents healing and does not charge tokens')
  -- Online tokens require a living equipped pet; the store only adds stock.
  P.state.rewardSeconds=299;P.Tick(1);assert(P.state.tokens==20)
  assert(P.Rescue());companion=P.Active();P.Tick(1);assert(P.state.tokens==22)
  P.OpenStore();local food=P.state.inventory.food;local hunger=companion.food
  assert(P.store.frameStrata=='FULLSCREEN_DIALOG' and P.window.frameStrata=='DIALOG' and P.store.mouseEnabled,'Store stays above pets and blocks clicks through the panel')
  P.store.buy.food.scripts.OnClick()
  assert(P.state.inventory.food==food+1 and P.state.tokens==20 and companion.food==hunger)
  P.store:Hide()
  -- Thresholds stay explicit: hunger hurts, zero energy or happiness alone do not.
  companion.food=0;companion.health=50;companion.happy=0;companion.energy=0;P.Tick(5)
  assert(companion.health<50 and companion.energy>0 and companion.happy==0)
  companion.food=100;hp=companion.health;P.Tick(5);assert(companion.health==hp)
  assert(not P.StartBattle(1),'Insufficient energy blocks new fights')
  -- Tower treats only roll on first clears; ten percent includes the boundary.
  companion.level=100;companion.energy=100;companion.health=100
  P.random=function(a,b)return b==100 and 10 or a end
  food=P.state.inventory.food;assert(P.StartBattle(1));P.state.battle.enemy.hp=1;P.BattleAction('strike')
  assert(P.victory.treats==1 and P.state.inventory.food==food+1)
  companion.energy=100;companion.health=100;assert(P.StartBattle(1));P.state.battle.enemy.hp=1;P.BattleAction('strike')
  assert(P.victory.treats==0 and P.state.inventory.food==food+1,'Repeat floors never grant treats')
  companion.energy=100;companion.health=100;P.random=function(a,b)return b==100 and 11 or a end
  assert(P.StartBattle(2));P.state.battle.enemy.hp=1;P.BattleAction('strike');assert(P.victory.treats==0)
  -- NPC treats: eligible player kills only, one percent, saved 30-minute cap.
  local savedGUID,savedEligible,savedTime=UnitGUID,P.EligibleKill,F.Now
  local now=2000000;F.Now=function()return now end
  UnitGUID=function(unit)return unit=='player' and 'Player-me' or unit=='pet' and 'Pet-me' end
  P.EligibleKill=function(guid)return guid~='Creature-gray' end
  P.recentKills={};P.combatWindow=nil;P.state.nextTreatDrop=0
  P.random=function(a,b)return 2 end
  food=P.state.inventory.food;P.CombatKill('PARTY_KILL','Player-me','Creature-miss');assert(P.state.inventory.food==food)
  P.random=function(a,b)return 1 end
  P.CombatKill('PARTY_KILL','Player-me','Creature-gray')
  P.CombatKill('PARTY_KILL','Player-me','Player-enemy')
  P.CombatKill('PARTY_KILL','Pet-me','Creature-petkill');assert(P.state.inventory.food==food)
  P.CombatKill('PARTY_KILL','Player-me','Creature-hit');assert(P.state.inventory.food==food+1,'Max-level pet can still receive a treat')
  P.Init();P.CombatKill('PARTY_KILL','Player-me','Creature-cooldown');assert(P.state.inventory.food==food+1)
  now=now+1800;P.CombatKill('PARTY_KILL','Player-me','Creature-next');assert(P.state.inventory.food==food+2)
  P.CombatKill('PARTY_KILL','Player-me','Creature-next');assert(P.state.inventory.food==food+2)
  UnitGUID,P.EligibleKill,F.Now=savedGUID,savedEligible,savedTime
end
print('PASS: manual-only healing, token fallback, no charge before lethal turn, hit happiness, store purchases, pet-online income and rare bounded treat drops')
F.char.pets={version=1,pets='broken'};P.Init();assert(not P.state.review and F.char.petQuarantine.pets=='broken','Unreadable save is backed up without accusing the player')
P.state=old;F.char.pets=oldChar;P.random=oldRandom;P.notice=oldNotice;P.window=oldWindow;P.mini=oldMini
print('PASS: pet rarity boundaries, care/persistence, permanent death/memorials, 100-floor gates, battle actions, NPC/PvP combat XP limits, save recovery, opt-in target inspection and compass/large pet UI')
