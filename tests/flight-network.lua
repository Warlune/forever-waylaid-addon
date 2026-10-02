local F=...
local R=F.Route
local function point(id,name,x,y,instance)
  return {nodeID=id,name=name,wx=x,wy=y,instance=instance or 0,mapID=1415,x=0.5,y=0.5}
end
-- Reproduce a character who learned southern destinations at Undercity,
-- but has never opened the Hammerfall flight master after arriving there.
local nodes={
  [11]=point(11,'Undercity',1568,268),
  [17]=point(17,'Hammerfall',-916,-3497),
  [20]=point(20,"Grom'gol",-12414,146),
  [56]=point(56,'Stonard',-10457,-3279),
  [22]=point(22,'Thunder Bluff',-1197,30,1),
}
local saved={nodes=nodes,edges={[11]={[17]=183,[20]=568,[56]=509}}}
local network=R.PrepareFlights(saved)
assert(not saved.edges[17] and not saved.connections,'Never save an inferred flight as an observation')
assert(network.edges[17][20] and network.estimated[17][20])
assert(not network.edges[17][22] and not network.edges[22],'No flight inferred to a different continent or an isolated node')
local arathi=point(nil,'Arathi delivery',-1200,-3100)
local dusk=point(nil,'Duskwood delivery',-10500,-500)
local old=R.Leg(arathi,dusk,saved,true)
local seconds,steps=R.Leg(arathi,dusk,network,true)
assert(seconds<old,'Known southern flight points must beat walking the entire continent')
assert(steps[1].mode=='Travel' and steps[1].to==nodes[17],'Walk from the first customer back to Hammerfall')
assert(steps[#steps].mode=='Travel' and steps[#steps].to==dusk,'Walk from the southern arrival to the next customer')
local flight=steps[2]
assert(flight.mode=='Fly' and (flight.to==nodes[20] or flight.to==nodes[56]))
assert(R.FlightNote(flight),'Estimated connectivity must be disclosed')
local west=point(nil,'Western Duskwood',-11000,700)
local east=point(nil,'Eastern Duskwood',-10500,-2300)
local _,westSteps=R.Leg(arathi,west,network,true)
local _,eastSteps=R.Leg(arathi,east,network,true)
assert(westSteps[2].to==nodes[20] and eastSteps[2].to==nodes[56],'Compare arrival airports against the actual recipient, not only the zone')
assert(R.Leg(arathi,dusk,network,false)==R.Distance(arathi,dusk)/7)

local travel={links={},personal={{to=nodes[11],mode='Hearthstone',id=6948,wait=0,seconds=15,resource='hearth'}},resources={hearth=1}}
local route,missing,total=R.Plan(nodes[22],{{questID=1,point=arathi},{questID=2,point=dusk}},network,true,travel)
assert(#route==2 and #missing==0 and route[1].stop.point==arathi)
local uses=0
for _,leg in ipairs(route) do for _,step in ipairs(leg.steps) do if step.mode=='Hearthstone' then uses=uses+1 end end end
assert(uses==1 and route[2].steps[1].from==arathi,'Keep personal resources and future-leg origins consistent')
assert(route[2].steps[2].mode=='Fly')
print(string.format('PASS: TB/UC/Arathi/Duskwood regression; second leg %.0fs vs %.0fs before; round %.0fs',seconds,old,total))

-- An explicit scan of a departure is authoritative, even if empty.
saved.edges[17]={}
network=R.PrepareFlights(saved)
assert(next(network.edges[17])==nil and not network.estimated[17])
saved.edges[17]={[56]=410}
network=R.PrepareFlights(saved)
assert(network.edges[17][56]==410 and not network.edges[17][20])
saved.edges[17]=nil;saved.connections={[17]={[56]=400}}
network=R.PrepareFlights(saved)
assert(network.edges[17][56]==400 and not network.estimated[17][56],'Observed route-preview hops beat estimates')

-- A nearby first stop can be worse for the whole trip. Preserve hearth until
-- after visiting that stop when doing so saves the complete delivery round.
local no={nodes={},edges={}}
local start=point(nil,'Start',0,0)
local near=point(nil,'Near',-70,0)
local home=point(nil,'Home',7000,0)
travel.personal[1].to=home
route,missing,total=R.Plan(start,{{point=home},{point=near}},no,false,travel)
assert(#route==2 and route[1].stop.point==near and total==25,'Compare full orders and save the hearth for the later delivery')

local oldRoute,oldTravel,oldPlayer,oldGuidance,oldFlight=F.route,F.travel,R.Player,F.guidance,F.flightGuidance
local oldCharacterFlights=F.char.flights
F.route={{stop={point=home},steps={{from=start,to=home,mode='Travel'}}}}
F.travel=travel;F.char.flights=no;R.Player=function()return start end
F.UpdateGuidance()
for _,step in ipairs(F.guidance.steps) do assert(step.mode~='Hearthstone','Live compass must respect a hearth reserved for later') end
F.route,F.travel,R.Player,F.guidance,F.flightGuidance=oldRoute,oldTravel,oldPlayer,oldGuidance,oldFlight
F.char.flights=oldCharacterFlights

-- Read real route preview APIs without taking a flight or changing the map.
local oldTaxi,oldCount,oldType,oldName=C_TaxiMap,NumTaxiNodes,TaxiNodeGetType,TaxiNodeName
local oldRoutes,oldSlot,oldChildren=GetNumRoutes,TaxiGetNodeSlot,C_Map.GetMapChildrenInfo
local oldWorld,oldFlights=R.World,F.char.flights
C_Map.GetMapChildrenInfo=function() return {} end
C_TaxiMap={GetTaxiNodesForMap=function()return {
  {nodeID=11,name='A',faction=1,position=CreateVector2D(.1,.1)},
  {nodeID=17,name='B',faction=1,position=CreateVector2D(.2,.2)},
  {nodeID=56,name='C',faction=1,position=CreateVector2D(.3,.3)},
  {nodeID=99,name='Invalid',faction=1,position=CreateVector2D(2,-1)},
}end}
R.World=function(p)return point(({A=11,B=17,C=56})[p.name],p.name,p.x*10000,p.y*10000)end
NumTaxiNodes=function()return 4 end
TaxiNodeName=function(i)return ({'A','B','C','Invalid'})[i]end
TaxiNodeGetType=function(i)return i==1 and 'CURRENT' or 'REACHABLE'end
GetNumRoutes=function(slot)return slot==3 and 2 or 1 end
TaxiGetNodeSlot=function(slot,hop,source)
  if slot==3 then return source and hop or hop+1 end
  return source and 1 or slot
end
F.char.flights={nodes={},edges={}}
F.LearnFlights()
assert(not F.char.flights.nodes[99],'Reject taxi coordinates outside a map')
assert(F.char.flights.connections[17][56] and not F.char.flights.edges[17])
assert(not F.char.flights.connections[56],'Directed route previews must not fabricate reverse hops')
network=R.PrepareFlights(F.char.flights)
assert(network.edges[17][56] and not network.estimated[17][56])
C_TaxiMap,NumTaxiNodes,TaxiNodeGetType,TaxiNodeName=oldTaxi,oldCount,oldType,oldName
GetNumRoutes,TaxiGetNodeSlot,C_Map.GetMapChildrenInfo=oldRoutes,oldSlot,oldChildren
R.World,F.char.flights=oldWorld,oldFlights
print('PASS: authoritative empty/departure scans, directed preview hops, coordinate filtering, and complete-order personal travel')
