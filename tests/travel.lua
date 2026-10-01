local F=...
local R,T=F.Route,F.Travel
local function p(x,instance,name)return {wx=x,wy=0,instance=instance or 1,mapID=instance==0 and 1420 or 1411,x=0.5,y=0.5,name=name}end
local no={nodes={},edges={}}
local start,finish=p(0),p(100070,0)
local dock,arrival=p(70,1,'Departure'),p(100000,0,'Arrival')
local travel={links={{from=dock,to=arrival,mode='Zeppelin',seconds=240}},personal={},resources={}}
local seconds,steps=R.Leg(start,finish,no,true,travel)
assert(seconds==260 and #steps==3 and steps[2].mode=='Zeppelin')
assert(R.Leg(finish,start,no,true,travel)==math.huge,'One-way transport must not invent a reverse link')
local route,missing=R.Plan(start,{{questID=1,point=finish}},no,true,travel)
assert(#route==1 and #missing==0,'Cross-continent destinations must be routable')
local flights={nodes={a=p(100100,0),b=p(107000,0)},edges={a={b=40}}}
seconds,steps=R.Leg(start,p(107070,0),flights,true,travel)
local found=false;for _,step in ipairs(steps)do if step.mode=='Fly' then found=true end end
assert(found and seconds<400,'Use learned arrival-continent flights after the zeppelin')
local _,walkSteps=R.Leg(start,p(107070,0),flights,false,travel)
for _,step in ipairs(walkSteps)do assert(step.mode~='Fly')end
local island=p(0);island.mapID=1438
assert(R.WalkDistance(island,start)==math.huge,'Never walk straight across the sea from Teldrassil')

local home=p(7000)
local personal={links={},personal={{to=home,mode='Hearthstone',id=6948,wait=20,seconds=15,resource='hearth'}},resources={hearth=1}}
seconds,steps=R.Leg(start,home,no,false,personal)
assert(seconds==35 and steps[1].detail.wait==20)
assert(R.Leg(start,home,no,false,personal,30)==15,'Elapsed time reduces the remaining cooldown')
assert(R.Leg(start,home,no,false,personal,0,{hearth=1})==1000,'Consumed Hearthstone must not be reused')
personal.personal[1].wait=2000
assert(R.Leg(start,home,no,false,personal)==1000,'Do not wait on a slower Hearthstone')
personal.personal[1].wait=0
route=R.Plan(start,{{point=p(7000)},{point=p(7100)},{point=p(7200)}},no,false,personal)
local uses=0
for _,leg in ipairs(route)do for _,step in ipairs(leg.steps)do if step.mode=='Hearthstone' then uses=uses+1 end end end
assert(#route==3 and uses==1,'One-use personal resources must be reserved across the itinerary')

local oldClass,oldKnown,oldSpellBook,oldSpell,oldTime=UnitClass,IsSpellKnown,C_SpellBook,C_Spell,GetTime
local oldCount,oldCooldown=C_Item.GetItemCount,C_Item.GetItemCooldown
local oldBind,oldRank,oldHome,oldPlayer=GetBindLocation,F.ProfessionRank,F.char.home,R.Player
local oldFaction=UnitFactionGroup
local inventory={[6948]=1,[17031]=1,[17032]=1,[18986]=1}
local learned={[3567]=true,[11417]=true,[20219]=true}
local class,rank='WARLOCK',260
UnitClass=function()return class,class end
C_SpellBook=nil;IsSpellKnown=function(id)return learned[id]end
GetTime=function()return 100 end
C_Item.GetItemCount=function(id)return inventory[id] or 0 end
C_Item.GetItemCooldown=function()return 90,60,true end
C_Spell={GetSpellCooldown=function()return {startTime=0,duration=0,isEnabled=true}end}
GetBindLocation=function()return 'Test inn' end
F.ProfessionRank=function()return rank end
F.char.home={name='Test inn',point=home}
local options=T.Options()
assert(#options.personal==2,'Non-mage gets only eligible Hearthstone and engineering device')
for _,link in ipairs(options.links)do assert(link.mode~='Tram')end
for _,link in ipairs(options.personal)do assert(link.mode~='Portal' and link.mode~='Teleport')end
class='MAGE';options=T.Options();assert(#options.personal==4,'Mage can use known teleports and portals with reagents')
inventory[17031]=0;learned[11417]=false;options=T.Options();assert(#options.personal==2,'Missing reagent and unknown spell must be excluded')
rank=259;options=T.Options();assert(#options.personal==1,'Engineering rank must be sufficient')
rank=260;learned[20219]=false;options=T.Options();assert(#options.personal==1,'Engineering specialization must be known')
F.char.home.name='Old inn';options=T.Options();assert(#options.personal==0,'Changed binding invalidates stale coordinates')
R.Player=function()return p(50)end;T.RecordHome();assert(F.char.home.name=='Test inn' and F.char.home.point.wx==50)
local oldPending=F.hearthPending
F.char.home=nil;F.hearthPending=nil
-- A cancelled cast never emits SUCCEEDED and must not map the casting spot.
F.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','party1','test',8690)
assert(not F.hearthPending and not F.char.home)
F.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','test',8690)
assert(F.hearthPending and not F.char.home,'Wait for arrival before saving Hearthstone coordinates')
R.Player=function()return p(700)end
F.events.scripts.OnEvent(nil,'PLAYER_ENTERING_WORLD')
assert(F.char.home.point.wx==700 and not F.hearthPending,'Successful hearth learns the arrival position')
F.hearthPending=oldPending
C_Item.GetItemCooldown=function()return 0,0,false end;assert(#T.Options().personal==0,'Disabled item cooldown is unavailable')
UnitFactionGroup=function()return 'Alliance'end;options=T.Options()
for _,link in ipairs(options.links)do assert(link.mode~='Zeppelin','Do not send Alliance to hostile zeppelins')end

local oldTravel,oldActive,oldRoute,oldQuest,oldFlights,oldGuidance=F.travel,F.active,F.route,F.char.navQuest,F.char.flights,F.guidance
local oldTaxi=UnitOnTaxi
F.travel=travel;F.char.flights=no;F.char.navQuest=1
local stop={questID=1,point=finish,writ={name='Test writ'}}
F.active={stop};F.route={{stop=stop}};R.Player=function()return start end;UnitOnTaxi=function()return false end
F.UpdateGuidance();assert(F.guidance.target==dock and F.guidance.action=='Go to zeppelin boarding point')
R.Player=function()return dock end;F.UpdateGuidance();assert(F.guidance.action=='Board zeppelin')
R.Player=function()return arrival end;F.UpdateGuidance();assert(F.guidance.target==finish and F.guidance.action=='Deliver to customer')
F.char.flights={nodes={a=p(0,1)},edges={a={}}};F.UpdateNavigator()
assert(F.compass.flightNotice.text:find('Eastern Kingdoms',1,true) and F.compass.flightNotice.text:find('not be optimal',1,true))
F.char.flights.nodes.b=p(0,0);F.char.flights.edges.b={};F.UpdateNavigator();assert(not F.compass.flightNotice.shown)

UnitClass,IsSpellKnown,C_SpellBook,C_Spell,GetTime=oldClass,oldKnown,oldSpellBook,oldSpell,oldTime
C_Item.GetItemCount,C_Item.GetItemCooldown=oldCount,oldCooldown
GetBindLocation,F.ProfessionRank,F.char.home,R.Player=oldBind,oldRank,oldHome,oldPlayer
UnitFactionGroup,UnitOnTaxi=oldFaction,oldTaxi
F.travel,F.active,F.route,F.char.navQuest,F.char.flights,F.guidance=oldTravel,oldActive,oldRoute,oldQuest,oldFlights,oldGuidance
print('PASS: cross-continent transport, arrival flights, cooldowns, resource use, class/skill/reagent gates, hearth binding and compass progression')
