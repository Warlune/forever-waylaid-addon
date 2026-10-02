local F=...
local R,T=F.Route,F.Travel
local oldFaction,oldRace,oldWorld=UnitFactionGroup,UnitRace,C_Map.GetWorldPosFromMapPos
local oldFlights,oldEnabled,oldCache=F.char.flights,F.db.settings.flights,F.routingFlights
local faction,race='Alliance',1
UnitFactionGroup=function()return faction end
UnitRace=function()return 'Test race','Test',race end
-- Deliberately isolated zones: a missing transport cannot accidentally pass
-- because a synthetic walking shortcut crosses an ocean. Not real-world ETAs.
C_Map.GetWorldPosFromMapPos=function(map,pos)
  local x,y=pos:GetXY();return map,CreateVector2D(x*10000,y*10000)
end
local function clone(p,dx)
  local q={};for k,v in pairs(p)do q[k]=v end
  q.wx=q.wx+(dx or 0);return q
end
local function same(a,b)
  return a.instance==b.instance and math.abs(a.wx-b.wx)<.001 and math.abs(a.wy-b.wy)<.001
end
local function validate(start,stops,route,missing,total,flights,options)
  local at,seen,used,sum=start,{},{},0
  for _,leg in ipairs(route)do
    assert(not seen[leg.stop],'Duplicate delivery');seen[leg.stop]=true
    for _,step in ipairs(leg.steps)do
      assert(same(at,step.from),'Discontinuous journey')
      if step.mode=='Fly' then
        assert(flights.nodes[step.from.nodeID] and flights.nodes[step.to.nodeID],'Unknown FP used')
        assert(flights.edges[step.from.nodeID][step.to.nodeID],'Unavailable flight used')
      elseif step.mode=='Travel' then
        assert(R.WalkDistance(step.from,step.to)<math.huge,'Walk across disconnected land')
      elseif step.detail and step.detail.resource then
        local key=step.detail.resource;used[key]=(used[key] or 0)+1
      else
        local found=false
        for _,link in ipairs(options.links)do if step.detail==link then found=true end end
        assert(found,'Transport not available to this faction')
      end
      at=step.to
    end
    assert(same(at,leg.stop.point),'Delivery not reached');sum=sum+leg.seconds
  end
  for _,stop in ipairs(missing)do assert(not seen[stop]);seen[stop]=true end
  for _,stop in ipairs(stops)do assert(seen[stop],'Lost delivery')end
  for key,n in pairs(used)do assert(n<=(options.resources[key] or 0),'Overspent '..key)end
  assert(math.abs(sum-total)<.00001,'Wrong journey total')
end

-- Independently resolve the static graph with Floyd-Warshall, then use a
-- subset dynamic program for the exact open delivery tour (no return home).
-- This does not call production Leg/Plan or its pruning/ranking functions.
local function reference(start,stops,flights,links)
  local points,index={},{ }
  local function add(p)if not index[p]then points[#points+1]=p;index[p]=#points end end
  add(start);for _,s in ipairs(stops)do add(s.point)end
  for _,p in pairs(flights.nodes)do add(p)end
  for _,l in ipairs(links)do add(l.from);add(l.to)end
  local d={}
  for i,a in ipairs(points)do
    d[i]={}
    for j,b in ipairs(points)do
      -- All matrix destinations are mainland; each test zone is isolated.
      d[i][j]=a.instance==b.instance and math.sqrt((a.wx-b.wx)^2+(a.wy-b.wy)^2)/7 or math.huge
    end
  end
  for from,row in pairs(flights.edges)do for to,t in pairs(row)do
    local a,b=index[flights.nodes[from]],index[flights.nodes[to]]
    d[a][b]=math.min(d[a][b],t+15)
  end end
  for _,l in ipairs(links)do local a,b=index[l.from],index[l.to];d[a][b]=math.min(d[a][b],l.seconds)end
  for k=1,#points do for i=1,#points do if d[i][k]<math.huge then
    for j=1,#points do d[i][j]=math.min(d[i][j],d[i][k]+d[k][j])end
  end end end
  local n,memo=#stops,{}
  local function solve(at,mask)
    if mask==2^n-1 then return 0 end
    local key=mask*(n+1)+at
    if memo[key]then return memo[key]end
    local best=math.huge
    local from=at==0 and index[start] or index[stops[at].point]
    for j,s in ipairs(stops)do local bit=2^(j-1)
      if math.floor(mask/bit)%2==0 then best=math.min(best,d[from][index[s.point]]+solve(j,mask+bit))end
    end
    memo[key]=best;return best
  end
  return solve(0,0)
end

local services=0
for _,side in ipairs({'Alliance','Horde'})do
  faction=side;race=side=='Alliance' and 95 or 96
  local links=T.PublicLinks(side)
  local present={}
  for _,l in ipairs(links)do present[l.routeID]=true end
  for _,data in ipairs(F.TransportRoutes)do
    local expected=data.faction=='Neutral' or data.faction==side
    expected=expected and (not data.raceID or data.raceID==race)
    assert(not not present[data.id]==not not expected,'Faction/race service filter: '..data.id)
  end
  for _,link in ipairs(links)do
    local stops={{point=link.to}}
    local options={links={link},personal={},resources={}}
    local empty={nodes={},edges={}}
    local route,missing,total=R.Plan(link.from,stops,empty,true,options)
    assert(#route==1 and #missing==0,'Missing public service '..link.routeID)
    -- Same-zone Feralas may instead have a shorter permitted walk.
    assert(total<=link.seconds+.001,'Ignored direct public service '..link.routeID)
    validate(link.from,stops,route,missing,total,empty,options)
    services=services+1
  end
end
faction='Alliance';race=1
local links=T.PublicLinks(faction)
local function find(id,from,to)
  for _,l in ipairs(links)do if l.routeID==id and l.from.mapID==from and l.to.mapID==to then return l end end
  error('Missing service '..id)
end
local tram=find('deeprun-tram',1455,1453)
local boat=find('auberdine-stormwind',1453,1439)
local start=clone(tram.from,70)
local stops={{point=clone(boat.to,70)}}
local options={links=links,personal={},resources={}}
local empty={nodes={},edges={}}
local route,missing,total=R.Plan(start,stops,empty,true,options)
local modes={};for _,step in ipairs(route[1].steps)do modes[#modes+1]=step.mode end
assert(table.concat(modes,',')=='Travel,Tram,Travel,Boat,Travel','IF to Auberdine must retain walks between services')
validate(start,stops,route,missing,total,empty,options)
print('COVERAGE: Alliance Ironforge > walk > tram > walk to Stormwind harbor > new boat > walk to customer')

-- Six observed-flight coverage profiles, both factions, 1..6 and 12 writs,
-- two deterministic layouts each. Real public-service registry; synthetic
-- local geometry and flight times. No unobserved destination is introduced.
local profiles={'none','nodes-only','one-departure','partial','complete','flights-disabled'}
local seed=101
local function random(n)seed=(seed*97+13)%65521;return seed%n+1 end
local count,large,gaps,maxGap,slowest=0,0,0,0,0
local bySize={}
for _,side in ipairs({'Alliance','Horde'})do
  faction=side;race=1
  links=T.PublicLinks(side)
  local mapA,mapB=side=='Alliance' and 1453 or 1411,side=='Alliance' and 1439 or 1420
  local centers={}
  for _,l in ipairs(links)do
    for _,p in ipairs({l.from,l.to})do if p.mapID==mapA or p.mapID==mapB then centers[p.mapID]=p end end
  end
  for _,profile in ipairs(profiles)do for _,n in ipairs({1,2,3,4,5,6,12})do for variant=1,2 do
    local saved={nodes={},edges={}}
    if profile~='none' then
      for i=1,6 do
        local p=clone(centers[i<=3 and mapA or mapB],(i%3-1)*2400)
        p.nodeID=i;saved.nodes[i]=p
      end
      for i=1,6 do
        if profile=='complete' or profile=='flights-disabled' or (profile=='partial' and i%3~=0) or (profile=='one-departure' and i==1) then
          saved.edges[i]={}
          for j=1,6 do if i~=j and saved.nodes[i].instance==saved.nodes[j].instance then saved.edges[i][j]=40+math.abs(i-j)*20 end end
        end
      end
    end
    local flights=R.PrepareFlights(saved)
    local use=profile~='flights-disabled'
    start=clone(centers[variant==1 and mapA or mapB],-1700)
    stops={}
    for i=1,n do
      local map=i%2==0 and mapA or mapB
      local p=clone(centers[map],random(5600)-2800);p.wy=p.wy+random(1000)
      stops[i]={questID=i,point=p}
    end
    options={links=links,personal={},resources={}}
    local begin=os.clock()
    local mode
    route,missing,total,mode=R.Plan(start,stops,flights,use,options)
    slowest=math.max(slowest,os.clock()-begin)
    assert(#route==n and #missing==0,side..' '..profile..' lost reachable writ')
    validate(start,stops,route,missing,total,flights,options)
    if not use then for _,leg in ipairs(route)do for _,step in ipairs(leg.steps)do assert(step.mode~='Fly')end end end
    local optimum=reference(start,stops,use and flights or empty,links)
    assert(total>=optimum-.001,'Impossible faster-than-reference route')
    if mode=='exact' then assert(math.abs(total-optimum)<.001,'Exact-mode route differs from reference')end
    local gap=(total/optimum-1)*100
    bySize[n]=bySize[n] or {count=0,gaps=0,max=0}
    local stats=bySize[n];stats.count=stats.count+1;stats.max=math.max(stats.max,gap)
    if gap>.001 then
      stats.gaps=stats.gaps+1
      print(string.format('COVERAGE GAP: %s / %s / %d writs / layout %d: %.2f%% (%.1fs vs %.1fs)',side,profile,n,variant,gap,total,optimum))
    end
    if gap>.001 then gaps=gaps+1 end
    maxGap=math.max(maxGap,gap)
    count=count+1;if n==12 then large=large+1 end
  end end end
end
print(string.format('COVERAGE: %d faction/flight-profile/layout rounds, including %d twelve-writ rounds; %d above exact optimum, max gap %.2f%%; slowest Plan %.3fs',count,large,gaps,maxGap,slowest))
for _,n in ipairs({1,2,3,4,5,6,12})do local s=bySize[n]
  print(string.format('COVERAGE SIZE: %d writs / %d tests / %d above optimum / largest gap %.2f%%',n,s.count,s.gaps,s.max))
end

-- Exercise real class/reagent/engineering gates on both factions, including
-- twelve-delivery rounds with consumable travel choices and cooldowns.
local oldClass,oldKnown,oldBook,oldSpell,oldTime=UnitClass,IsSpellKnown,C_SpellBook,C_Spell,GetTime
local oldCount,oldCooldown=C_Item.GetItemCount,C_Item.GetItemCooldown
local oldBind,oldRank,oldHome=GetBindLocation,F.ProfessionRank,F.char.home
local class,rank,inventory='WARRIOR',0,{}
UnitClass=function()return class,class end
C_SpellBook=nil;IsSpellKnown=function()return true end
GetTime=function()return 100 end
C_Spell={GetSpellCooldown=function()return {startTime=0,duration=0,isEnabled=true}end}
C_Item.GetItemCount=function(id)return inventory[id] or 0 end
C_Item.GetItemCooldown=function()return 50,150,true end
GetBindLocation=function()return 'Fixture inn' end
F.ProfessionRank=function()return rank end
local personalRounds=0
for _,side in ipairs({'Alliance','Horde'})do
  faction=side
  for _,kind in ipairs({'no-reagents','mage','engineer'})do
    class=kind=='engineer' and 'WARRIOR' or 'MAGE';rank=kind=='engineer' and 300 or 0
    inventory={[6948]=1,[17031]=kind=='mage' and 2 or 0,[17032]=kind=='mage' and 1 or 0,[18986]=1,[18984]=1}
    local first=side=='Alliance' and 1453 or 1411
    local second=side=='Alliance' and 1439 or 1420
    local places={}
    for _,l in ipairs(T.PublicLinks(side))do for _,p in ipairs({l.from,l.to})do places[p.mapID]=p end end
    F.char.home={name='Fixture inn',point=places[second]}
    options=T.Options()
    assert(#options.personal==(kind=='mage' and 7 or kind=='engineer' and 3 or 1),'Incorrect capability gating')
    for _,spell in ipairs(options.personal)do
      if spell.mode=='Teleport' or spell.mode=='Portal' then
        local own=side=='Alliance' and {[1453]=true,[1455]=true,[1457]=true} or {[1454]=true,[1456]=true,[1458]=true}
        assert(own[spell.to.mapID],'Off-faction mage destination')
      end
    end
    for _,n in ipairs({1,6,12})do
      start=places[first];stops={}
      for i=1,n do stops[i]={questID=i,point=clone(places[i%2==0 and first or second],i*70)}end
      route,missing,total=R.Plan(start,stops,empty,true,options)
      assert(#route==n and #missing==0,'Personal travel lost a reachable writ')
      validate(start,stops,route,missing,total,empty,options)
      personalRounds=personalRounds+1
    end
  end
end
UnitClass,IsSpellKnown,C_SpellBook,C_Spell,GetTime=oldClass,oldKnown,oldBook,oldSpell,oldTime
C_Item.GetItemCount,C_Item.GetItemCooldown=oldCount,oldCooldown
GetBindLocation,F.ProfessionRank,F.char.home=oldBind,oldRank,oldHome
print('PASS: '..personalRounds..' both-faction rounds with actual mage, reagent, engineering and hearth option gates')

-- Taximap learning must reject undiscovered/opposite-faction destinations
-- before they ever reach the planner, while retaining neutral connections.
local oldTaxi,oldNum,oldType,oldName=C_TaxiMap,NumTaxiNodes,TaxiNodeGetType,TaxiNodeName
local oldChildren,oldBest=C_Map.GetMapChildrenInfo,C_Map.GetBestMapForUnit
local oldRoutes,oldSlot=GetNumRoutes,TaxiGetNodeSlot
C_Map.GetMapChildrenInfo=function()return {}end
C_Map.GetBestMapForUnit=function()return 1411 end
GetNumRoutes=nil;TaxiGetNodeSlot=nil
NumTaxiNodes=function()return 5 end
TaxiNodeGetType=function(i)return i==1 and 'CURRENT' or 'REACHABLE'end
TaxiNodeName=function(i)return 'Coverage node '..i end
for _,side in ipairs({'Alliance','Horde'})do
  faction=side
  local own=side=='Horde' and 1 or 2
  C_TaxiMap={GetTaxiNodesForMap=function()
    local nodes={}
    for i=1,5 do nodes[i]={nodeID=i,name=TaxiNodeName(i),faction=i==3 and (3-own) or i==5 and 0 or own,
      isUndiscovered=i==4,position=CreateVector2D(.1*i,.2)}end
    return nodes
  end}
  F.char.flights={nodes={},edges={}}
  F.LearnFlights()
  assert(F.char.flights.nodes[1] and F.char.flights.nodes[2] and F.char.flights.nodes[5])
  assert(not F.char.flights.nodes[3] and not F.char.flights.nodes[4],'Learned hostile or undiscovered FP')
  assert(F.char.flights.edges[1][2] and F.char.flights.edges[1][5])
  assert(not F.char.flights.edges[1][3] and not F.char.flights.edges[1][4])
end
C_TaxiMap,NumTaxiNodes,TaxiNodeGetType,TaxiNodeName=oldTaxi,oldNum,oldType,oldName
C_Map.GetMapChildrenInfo,C_Map.GetBestMapForUnit=oldChildren,oldBest
GetNumRoutes,TaxiGetNodeSlot=oldRoutes,oldSlot
print('PASS: both-faction taxi scans exclude undiscovered/hostile FPs and retain neutral nodes')

for _,side in ipairs({'Alliance','Horde'})do
  faction=side
  local first=side=='Alliance' and 1453 or 1411
  local second=side=='Alliance' and 1439 or 1420
  local places={}
  links=T.PublicLinks(side)
  for _,l in ipairs(links)do for _,p in ipairs({l.from,l.to})do places[p.mapID]=p end end
  local book={nodes={},edges={}}
  for i=1,60 do
    local p=clone(places[i%2==0 and first or second],i*110)
    p.nodeID=i;p.wy=p.wy+(i%7)*100;book.nodes[i]=p
  end
  for i=1,60 do book.edges[i]={}
    for j=1,60 do if i~=j and i%2==j%2 then book.edges[i][j]=40+math.abs(i-j)*8 end end
  end
  book=R.PrepareFlights(book)
  start=places[first];stops={}
  for i=1,12 do stops[i]={point=clone(book.nodes[i*5],70)}end
  options={links=links,personal={},resources={}}
  local begin=os.clock()
  route,missing,total=R.Plan(start,stops,book,true,options)
  local elapsed=os.clock()-begin
  assert(#route==12 and #missing==0)
  validate(start,stops,route,missing,total,book,options)
  print(string.format('COVERAGE STRESS: %s / 60 FPs / 12 writs / all public links: %.3fs',side,elapsed))
end

-- Twelve real catalogue quests through the tracking/compass/map lifecycle,
-- including alternating abandonment and completion before the quest API
-- catches up. This is deliberately not just another direct Plan call.
local keys={'Render','UpdateNavigator','active','route','unresolved','routeSeconds','routeMode','guidance','flightGuidance','removedWrits','travel'}
local old={};for _,key in ipairs(keys)do old[key]=F[key]end
local oldPlayer,oldOptions=R.Player,T.Options
local oldOn,oldComplete,oldAfter=C_QuestLog.IsOnQuest,C_QuestLog.IsComplete,C_Timer.After
local oldPins,oldQuest=F.char.pins,F.char.navQuest
F.Render=function()end;F.UpdateNavigator=function()end
C_Timer.After=function()end
T.Options=function()return {links={},personal={},resources={}}end
C_QuestLog.IsComplete=function()return true end
for _,side in ipairs({'Alliance','Horde'})do
  faction=side
  local map=side=='Alliance' and 1453 or 1454
  local accepted,ids={},{}
  F.char.pins={};F.char.flights={nodes={},edges={}};F.char.navQuest=nil
  F.removedWrits={};F.db.settings.flights=false
  for i=1,12 do
    local id=F.catalog.writs[i].questId;ids[i]=id;accepted[id]=true
    F.char.pins[id]={mapID=map,x=.1+i*.02,y=.2}
  end
  C_QuestLog.IsOnQuest=function(id)return accepted[id]end
  local player=R.World({mapID=map,x=.1,y=.2})
  R.Player=function()return player end
  F.Refresh();assert(#F.route==12 and #F.active==12)
  local _,pins=F.DisplayRoute();assert(#pins==12,'Not all twelve map destinations shown')
  for i=1,12 do
    local removed=F.guidance.stop.questID
    player=F.guidance.stop.point
    F.events.scripts.OnEvent(nil,i%2==0 and 'QUEST_TURNED_IN' or 'QUEST_REMOVED',removed,false)
    assert(#F.route==12-i and #F.active==12-i,'Wrong remaining quest count')
    F.Refresh();assert(#F.route==12-i,'Stale quest API resurrected removed writ')
    local segments;segments,pins=F.DisplayRoute()
    assert(#pins==12-i,'Stale map destination')
    for _,pin in ipairs(pins)do assert(pin.stop.questID~=removed)end
    if i==12 then assert(not F.guidance and #segments==0,'Last writ left stale compass/line')end
  end
end
for _,key in ipairs(keys)do F[key]=old[key]end
R.Player,T.Options=oldPlayer,oldOptions
C_QuestLog.IsOnQuest,C_QuestLog.IsComplete,C_Timer.After=oldOn,oldComplete,oldAfter
F.char.pins,F.char.navQuest=oldPins,oldQuest
print('PASS: Horde and Alliance twelve-writ tracking, full map itinerary, 24 removals/turn-ins and stale quest-event handling')

-- Continent warning reflects actual departures, not just remembered nodes.
for _,side in ipairs({'Alliance','Horde'})do
  faction=side;F.db.settings.flights=true
  F.char.flights={nodes={[1]={instance=0},[2]={instance=1}},edges={}}
  assert(table.concat(F.MissingFlightContinents(),',')=='Eastern Kingdoms,Kalimdor')
  F.char.flights.edges[1]={};assert(table.concat(F.MissingFlightContinents())=='Kalimdor')
  F.char.flights.edges={[2]={}};assert(table.concat(F.MissingFlightContinents())=='Eastern Kingdoms')
  F.char.flights.edges[1]={};assert(#F.MissingFlightContinents()==0)
  F.db.settings.flights=false;F.char.flights.edges={};assert(#F.MissingFlightContinents()==0)
end
UnitFactionGroup,UnitRace,C_Map.GetWorldPosFromMapPos=oldFaction,oldRace,oldWorld
F.char.flights,F.db.settings.flights,F.routingFlights=oldFlights,oldEnabled,oldCache
print('PASS: '..services..' directed public services, Alliance tram/boat transfers, both-faction delivery matrix and incomplete-continent warnings')
