local F=...
local R=F.Route
local old={}
for _,key in ipairs({'route','guidance','flightGuidance','travel','routingFlights'}) do old[key]=F[key] end
local oldFlights,oldEnabled=F.char.flights,F.db.settings.flights
local oldTaxi,oldCount,oldType,oldName=C_TaxiMap,NumTaxiNodes,TaxiNodeGetType,TaxiNodeName
local oldRoutes,oldSlot,oldChildren=GetNumRoutes,TaxiGetNodeSlot,C_Map.GetMapChildrenInfo
local oldWorld,oldPlayer,oldOnTaxi=R.World,R.Player,UnitOnTaxi
local function p(id,name,x,y)return {nodeID=id,name=name,wx=x,wy=y,instance=0,mapID=1415,x=.5,y=.5}end
local nodes={p(1,'Departure',0,0),p(2,'Connection B',0,14000),p(3,'Connection C',14000,14000),p(4,'Arrival',14000,0)}
local byName={};for _,node in ipairs(nodes) do byName[node.name]=node end
C_Map.GetMapChildrenInfo=function()return {}end
C_TaxiMap={GetTaxiNodesForMap=function()
  local result={}
  for _,node in ipairs(nodes) do result[#result+1]={nodeID=node.nodeID,name=node.name,faction=1,position=CreateVector2D(.5,.5)} end
  return result
end}
R.World=function(point)return byName[point.name]end
NumTaxiNodes=function()return 4 end
TaxiNodeName=function(slot)return nodes[slot].name end
TaxiNodeGetType=function(slot)return slot==1 and 'CURRENT' or 'REACHABLE'end
GetNumRoutes=function(slot)return slot-1 end
TaxiGetNodeSlot=function(slot,hop,source)return source and hop or hop+1 end
F.char.flights={nodes={},edges={}}
F.LearnFlights()
local saved=F.char.flights
local hop=14000/32*1.3
assert(#saved.paths[1][4]==4 and saved.paths[1][4][2]==2 and saved.paths[1][4][3]==3)
assert(math.abs(saved.edges[1][4]-3*hop)<.0001,'Sum the real connecting legs instead of endpoint distance')
local graph=R.PrepareFlights(saved)
assert(#graph.details[1][4].via==2 and not graph.details[1][4].estimatedPath)
local seconds,steps=R.Leg(nodes[1],nodes[4],graph,true)
assert(math.abs(seconds-(3*hop+15))<.0001,'Charge boarding once for the whole bookable flight')
assert(#steps==1 and steps[1].mode=='Fly' and steps[1].to==nodes[4],'Do not ask to rebook at connecting stops')
assert(steps[1].detail.via[1]==nodes[2] and steps[1].detail.via[2]==nodes[3])
assert(F.Travel.ViaText(steps[1].detail):find('Stay aboard',1,true))
local alternative={links={{from=nodes[1],to=nodes[4],mode='Boat',seconds=1200}},personal={},resources={}}
local boatTime,boatSteps=R.Leg(nodes[1],nodes[4],graph,true,alternative)
assert(boatTime==1200 and boatSteps[1].mode=='Boat','A long connecting flight must lose to a genuinely faster alternative')

local player,flying=nodes[1],false
R.Player=function()return player end;UnitOnTaxi=function()return flying end
F.travel={links={},personal={},resources={}};F.db.settings.flights=true
F.route={{stop={questID=77,point=nodes[4],writ={name='Connection test'}},steps=steps}}
F.UpdateGuidance()
assert(F.guidance.nextStep.to==nodes[4] and F.guidance.action=='Take flight to Arrival')
local segments=F.DisplayRoute()
assert(#segments==3 and segments[1].to==nodes[2] and segments[2].to==nodes[3] and segments[3].to==nodes[4])
assert(segments[1].connectionTo and segments[2].connectionFrom and not segments[3].connectionTo)
local overlay=F.CreateRouteOverlay(UIParent)
F.DrawRouteOverlay(overlay,function(point)return point.wx/100,point.wy/100 end,
  function(a,b,c,d)return a,b,c,d end,function()return true end,false)
local connectionPins=0
for _,pin in ipairs(overlay.pins) do
  if pin.pinText and pin.pinText:find('Connection ',1,true) then
    assert(pin.pinText:find('stay aboard',1,true) and not pin.pinText:find('Land:',1,true))
    connectionPins=connectionPins+1
  end
end
assert(connectionPins>=2,'Intermediate map pins must explain that the player stays aboard')
flying=true;player=nodes[2];F.UpdateGuidance()
assert(F.guidance.action=='In flight' and F.guidance.target==nodes[4],'Keep final landing as guidance through intermediate stops')

-- Old saves already contain some observed connecting hops. Correct their
-- cheap flat edges immediately, but distinguish a reconstructed itinerary.
saved.paths=nil;saved.edges[1][4]=1
graph=R.PrepareFlights(saved)
assert(math.abs(graph.edges[1][4]-3*hop)<.0001 and graph.details[1][4].estimatedPath)
assert(graph.details[1][4].via[2]==nodes[3])
saved.connections=nil
graph=R.PrepareFlights(saved)
assert(graph.details[1][4].flightPathUnknown and R.FlightNote({detail=graph.details[1][4]}))

-- A malformed/partial client preview is never saved as a complete path.
TaxiGetNodeSlot=function(slot,hop,source)
  if slot==4 and hop==2 and source then return 1 end
  return source and hop or hop+1
end
F.LearnFlights();assert(not saved.paths[1][4] and saved.paths[1][3])

for key,value in pairs(old) do F[key]=value end
-- pairs skips saved nil values.
F.route,F.guidance,F.flightGuidance,F.travel,F.routingFlights=old.route,old.guidance,old.flightGuidance,old.travel,old.routingFlights
F.char.flights,F.db.settings.flights=oldFlights,oldEnabled
C_TaxiMap,NumTaxiNodes,TaxiNodeGetType,TaxiNodeName=oldTaxi,oldCount,oldType,oldName
GetNumRoutes,TaxiGetNodeSlot,C_Map.GetMapChildrenInfo=oldRoutes,oldSlot,oldChildren
R.World,R.Player,UnitOnTaxi=oldWorld,oldPlayer,oldOnTaxi
print('PASS: ordered flight previews, summed connecting costs, single boarding, route competition, map connections, final-arrival guidance, legacy recovery and malformed preview rejection')
