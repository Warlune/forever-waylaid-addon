local F,reviewedData=...
for city,name in pairs(reviewedData.cityExits)do
  local found
  for _,line in ipairs(reviewedData.lines)do
    if line.name==name then
      assert(#line.points==2 and (line.points[1][1]==city or line.points[2][1]==city),'Gate must use a reviewed city boundary crossing')
      assert(line.faction==reviewedData.cityFactions[city],'Gate must belong to the city faction')
      found=true
    end
  end
  assert(found,'Missing reviewed city gate: '..name)
end
local R=F.Roads
local oldData,oldWorld,oldProject,oldFaction=F.roadData,C_Map.GetWorldPosFromMapPos,F.Geometry.Project,UnitFactionGroup
C_Map.GetWorldPosFromMapPos=function(_,pos)local x,y=pos:GetXY();return 1,CreateVector2D(x*1000,y*1000)end
F.Geometry.Project=function(p)return p.wx/1000,p.wy/1000 end
UnitFactionGroup=function()return 'Horde'end
F.roadData={cityFactions={[1454]='Horde'},cityExits={[1454]='Test city gate'},lines={
  {name='Test city gate',faction='Horde',points={{1454,10,10},{1411,10,20}}},
}}
R.Invalidate()
local function point(map,x,y)return F.Route.World({mapID=map,x=x/1000,y=y/1000})end
local inside,outside=point(1454,400,400),point(1411,400,700)
local d,steps=R.Path(inside,outside)
assert(d and #steps==3 and steps[1].to.cityGate,'An off-street departure must aim at its known gate')
assert(steps[1].to.mapID==1454 and steps[3].from.mapID==1411 and steps[2].to.wy==200,'Cross from the inside to the outside gate anchor')
assert(steps[1].road=='unknown' and steps[3].road=='unknown','Do not present off-street bearings as mapped paths')
assert(steps[3].to==outside and d>F.Route.Distance(inside,outside),'Distance includes the gate detour')
local guide={walkSteps=steps,walkIndex=1}
F.AdvanceRoadGuidance(guide,inside)
assert(guide.action=='Go to city gate' and guide.target==steps[1].to)
local seconds=F.Route.Leg(inside,outside,{nodes={},edges={}},false)
assert(math.abs(seconds-d/7)<0.001,'Planner and displayed gate route agree on the estimate')
local back,reverse=R.Path(outside,inside)
assert(math.abs(back-d)<0.001 and reverse[1].to.mapID==1411 and reverse[3].from.mapID==1454,'Entering uses the same gate in reverse')
assert(R.Path(inside,point(1454,600,600))==nil,'A same-city trip must not detour out through the gate')
UnitFactionGroup=function()return 'Alliance'end
assert(F.Route.WalkDistance(inside,outside)==math.huge,'Enemy city gate must not become an allowed fallback')
F.roadData,C_Map.GetWorldPosFromMapPos,F.Geometry.Project,UnitFactionGroup=oldData,oldWorld,oldProject,oldFaction
R.Invalidate()
print('PASS: off-street city exit/entry anchors, honest unverified approaches, gate guidance, distance and faction restrictions')
