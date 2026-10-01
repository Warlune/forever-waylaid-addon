local F,data=...
local R,G,roads=F.Route,F.Geometry,F.Roads
local oldData,oldWorld,oldProject,oldFaction,oldMode=F.roadData,C_Map.GetWorldPosFromMapPos,G.Project,UnitFactionGroup,F.db.settings.routeMode
C_Map.GetWorldPosFromMapPos=function(_,v)local x,y=v:GetXY();return 1,CreateVector2D(x*1000,y*1000)end
G.Project=function(p)return p.wx/1000,p.wy/1000 end
local function point(x,y)return R.World({mapID=1,x=x/1000,y=y/1000})end
local a,b=point(0,0),point(100,0)
F.roadData={lines={
  {name='Road around clearing',points={{1,0,0},{1,0,10},{1,10,10},{1,10,0}}},
  {name='Open clearing',kind='corridor',points={{1,0,0},{1,10,0}}},
}}
F.db.settings.routeMode='safer';roads.Invalidate()
local safe,steps=roads.Path(a,b)
assert(safe==300 and #steps==3,'Safer should prefer the road around a clearing')
F.db.settings.routeMode='fastest'
local fast,shortcut=roads.Path(a,b)
assert(fast==100 and #shortcut==1 and shortcut[1].terrain=='corridor','Fastest must actually use the shorter open-ground crossing')
local guide={walkSteps=shortcut,walkIndex=1}
F.AdvanceRoadGuidance(guide,a)
assert(guide.action=='Cross open ground' and guide.roadWarning,'Do not call open ground a safe road')
local seconds=R.Leg(a,b,{nodes={},edges={}},false)
assert(math.abs(seconds-fast/7)<0.00001,'ETA reports physical length, not safety penalties')
local trees=roads.stats.trees
for i=1,30 do roads.Path(point(i,0),b)end
assert(roads.stats.trees==trees,'Moving toward one target must reuse its destination search')

-- Faction filters must not be affected by the cosmetic Alliance preview.
F.db.settings.debugAlliance=true
F.roadData={lines={
  {name='Horde-only street',faction='Horde',points={{1,0,0},{1,10,0}}},
  {name='Public detour',points={{1,0,0},{1,0,10},{1,10,10},{1,10,0}}},
}}
UnitFactionGroup=function()return 'Horde' end;roads.Invalidate()
assert(roads.Path(a,b)==100)
UnitFactionGroup=function()return 'Alliance' end
assert(roads.Path(a,b)==300,'Changing real faction rebuilds the graph and drops opposing streets')
F.db.settings.debugAlliance=false
F.roadData={cityFactions={[1]='Horde'},lines={}}
roads.Invalidate()
assert(R.WalkDistance(a,b)==math.huge,'An opposing city must not become a straight-line fallback')

F.roadData={lines={
  {name='West road',points={{1,0,0},{1,0,10}}},
  {name='East road',points={{1,10,0},{1,10,10}}},
}}
roads.Invalidate()
assert(R.WalkDistance(a,b)==math.huge,'Disconnected mapped areas must not be bridged by a fictitious shortcut')
assert(R.WalkDistance(point(500,500),point(600,500))==100,'Unknown terrain retains an explicitly unverified estimate')

-- Scale test: many distant roads must not multiply nearby attachment work.
F.roadData={lines={{name='Local',points={{1,0,0},{1,10,0}}}}}
for i=1,1000 do
  F.roadData.lines[#F.roadData.lines+1]={name='Distant',points={{1,100+i,100},{1,100+i,110}}}
end
roads.Invalidate();roads.Path(a,b)
assert(roads.stats.snapChecks<20,'Nearby edge lookup must use a spatial index')

local maps,restricted,corridors,seams={},{},0,0
for _,line in ipairs(data.lines)do
  for _,p in ipairs(line.points)do maps[p[1]]=true end
  if line.faction=='Horde' or line.faction=='Alliance' then restricted[line.faction]=true end
  if line.kind=='corridor' then corridors=corridors+1 end
  if line.kind=='transition' then seams=seams+1 end
end
for _,id in ipairs(data.coverage)do assert(maps[id],'Coverage must contain real geometry for every listed map')end
assert(#data.coverage==50 and corridors>=15 and seams>=30 and restricted.Horde and restricted.Alliance)

-- Check production topology with separated local map coordinates. This is a
-- connectivity test, not an assertion about the client's world projection.
C_Map.GetWorldPosFromMapPos=function(map,v)local x,y=v:GetXY();return 1,CreateVector2D(map*10000+x*1000,y*1000)end
G.Project=function(p,map)return (p.wx-map*10000)/1000,p.wy/1000 end
F.roadData=data;UnitFactionGroup=function()return 'Horde' end;roads.Invalidate()
local function endpoint(name,last)
  for _,line in ipairs(data.lines)do if line.name==name then
    local p=line.points[last and #line.points or 1]
    return R.World({mapID=p[1],x=p[2]/100,y=p[3]/100})
  end end
  error('Missing test route: '..name)
end
assert(roads.Path(endpoint('Valley of Strength: south gate'),endpoint('Ratchet dock approach',true)), 'Orgrimmar connects to Ratchet')
assert(roads.Path(endpoint('Gold Road'),endpoint('Cenarion Hold road',true)), 'Kalimdor backbone connects the Barrens to Silithus')
assert(roads.Path(endpoint('Brill to Lordaeron approach'),endpoint('Eastern Plaguelands southern road',true)), 'Northern Eastern Kingdoms backbone connects across the Plaguelands')
UnitFactionGroup=function()return 'Alliance' end
assert(roads.Path(endpoint('Stormwind gate to Trade District'),endpoint('Burning Steppes highway',true)), 'Southern Eastern Kingdoms connects Stormwind and Burning Steppes')
assert(roads.Path(endpoint('Dun Morogh highway'),endpoint('Arathi main road',true)), 'Dun Morogh connects through the Loch, Wetlands and Arathi')
assert(roads.Path(endpoint('Valanaar western road'),endpoint('Zephras western trail',true)), 'Zephras roads connect without a mainland walking shortcut')
assert(roads.Path(endpoint('Powderfuse Port road',true),endpoint('Wheeler\'s Grange road',true)), 'Riverglades harbor reaches the southern road')
assert(not roads.Path(endpoint('Powderfuse Port road',true),endpoint('Steamwheedle trail',true)), 'Riverglades and Tanaris need transport, not an ocean walking edge')

local refresh,refreshes=F.Refresh,0
F.Refresh=function()refreshes=refreshes+1 end
F.saferRouteButton.scripts.OnClick();assert(F.db.settings.routeMode=='safer')
F.fastestRouteButton.scripts.OnClick();assert(F.db.settings.routeMode=='fastest' and refreshes==2)
F.Refresh=refresh

F.roadData,C_Map.GetWorldPosFromMapPos,G.Project,UnitFactionGroup,F.db.settings.routeMode=oldData,oldWorld,oldProject,oldFaction,oldMode
roads.Invalidate()
print('PASS: 50-map coverage, safer/fastest routing, physical ETA, faction access, bounded destination caching and indexed edge lookup')
