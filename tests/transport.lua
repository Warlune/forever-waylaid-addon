local F=...
local T,R,G=F.Travel,F.Route,F.Geometry
local oldWorld,oldProject,oldRace=C_Map.GetWorldPosFromMapPos,C_Map.GetMapPosFromWorldPos,UnitRace
-- Isolate zones in this fixture: only a transport can join them. Real game
-- positions come from C_Map, never these synthetic test coordinates.
C_Map.GetWorldPosFromMapPos=function(map,pos)
  local x,y=pos:GetXY()
  return map,CreateVector2D(x*100000,y*100000)
end
local race=1
UnitRace=function()return 'Localized race','Unused',race end
local function find(links,id,from,to)
  for _,link in ipairs(links)do
    if link.routeID==id and link.from.mapID==from and link.to.mapID==to then return link end
  end
end
local alliance=T.PublicLinks('Alliance')
local triangle='menethil-southshore-auberdine'
local outward=find(alliance,triangle,1437,1439)
assert(outward and #outward.via==1 and outward.via[1].mapID==1424,'Menethil to Auberdine must stop at Southshore')
assert(outward.rideSeconds==111+60+95,'Include intermediate dock dwell')
assert(outward.seconds==475/2+111+60+95+10,'Charge one boarding wait and an arrival allowance')
local back=find(alliance,triangle,1439,1437)
assert(back and #back.via==0 and back.rideSeconds==89,'Auberdine returns directly to Menethil')
local viaMenethil=find(alliance,triangle,1439,1424)
assert(#viaMenethil.via==1 and viaMenethil.via[1].mapID==1437,'Reverse trip must follow the cycle')
local triangleLinks={}
for _,link in ipairs(alliance)do if link.routeID==triangle then triangleLinks[#triangleLinks+1]=link end end
assert(#triangleLinks==6,'Three stops yield six journeys, not independent boats')
local seconds,steps=R.Leg(outward.from,outward.to,{nodes={},edges={}},false,{links=triangleLinks,personal={},resources={}})
assert(seconds==outward.seconds and #steps==1 and steps[1].detail==outward,'Planner should stay aboard, not pay to reboard')
assert(T.ViaText(outward)=='Stay aboard via Southshore dock')
assert(T.ViaText(back)==nil)

local neutral='steamwheedle-powderfuse'
local horde=T.PublicLinks('Horde')
assert(find(alliance,neutral,1446,2548) and find(horde,neutral,1446,2548),'Both factions can reach Riverglades')
local river=find(horde,neutral,1446,2548)
assert(find(horde,neutral,2548,1446).rideSeconds==83 and river.rideSeconds==82,'Preserve direction-specific times')
assert(find(alliance,'auberdine-stormwind',1439,1453),'New Stormwind boat is present')
assert(not find(horde,'auberdine-stormwind',1439,1453),'Avoid hostile Alliance docks')
assert(find(horde,'skywatcher-valanaar',1412,2521),'Horde can use the Mulgore skycutter')
assert(not find(alliance,'dalaran-valanaar',1416,2521),'Do not send other Alliance races through hostile Dalaran guards')
race=95;assert(find(T.PublicLinks('Alliance'),'dalaran-valanaar',1416,2521),'Alliance Skyborne can use Dalaran')
race=96;assert(not find(T.PublicLinks('Horde'),'dalaran-valanaar',1416,2521),'Horde Skyborne do not gain safe Dalaran access')
local failedMap=C_Map.GetWorldPosFromMapPos
C_Map.GetWorldPosFromMapPos=function(map,pos)if map~=1424 then return failedMap(map,pos)end end
for _,link in ipairs(T.PublicLinks('Alliance'))do assert(link.routeID~=triangle,'Do not skip an unresolved intermediate stop')end
C_Map.GetWorldPosFromMapPos=failedMap
local island={mapID=2521,instance=1,wx=0,wy=0}
assert(R.WalkDistance(island,{mapID=1412,instance=1,wx=10,wy=0})==math.huge,'Never walk across the sea to Zephras')

local oldGuide,oldQuest=F.guidance,F.char.navQuest
F.char.navQuest=123
F.guidance={steps=steps,stop={point=outward.to}}
local segments=F.DisplayRoute()
assert(#segments==2 and segments[1].to.mapID==1424 and segments[2].from.mapID==1424,'Map must show intermediate ports')
F.guidance,F.char.navQuest=oldGuide,oldQuest

-- The normal API rejects an off-map point. Invert a rotated/sheared basis
-- so a line to that point can still be clipped to the visible map boundary.
local oldBases=G.mapBases;G.mapBases={}
C_Map.GetMapPosFromWorldPos=function()return nil end
C_Map.GetWorldPosFromMapPos=function(_,pos)
  local x,y=pos:GetXY()
  return 1,CreateVector2D(100+20*x-200*y,50-100*x+10*y)
end
local x,y=G.Project({instance=1,wx=100+20*1.5-200*0.25,wy=50-100*1.5+10*0.25},1454)
assert(math.abs(x-1.5)<0.0001 and math.abs(y-0.25)<0.0001,'Project a destination outside the city boundary')
local _,_,right=G.Rect(0.5,0.25,x,y,0,0,1,1)
assert(right==1,'Off-map route is visible up to the city edge')
assert(G.Project({instance=2,wx=0,wy=0},1454)==nil,'Do not project another continent onto this map')
C_Map.GetWorldPosFromMapPos,C_Map.GetMapPosFromWorldPos,UnitRace=oldWorld,oldProject,oldRace
G.mapBases=oldBases
print('PASS: Forever transport cycles, wait/dwell estimates, Riverglades, safe skycutter access, intermediate map stops and off-map projection')
