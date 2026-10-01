local F,reviewedData=...
local R,G,roads=F.Route,F.Geometry,F.Roads
local oldData,oldWorld,oldProject=F.roadData,C_Map.GetWorldPosFromMapPos,G.Project
local oldRoute,oldGuide,oldPlayer=F.route,F.guidance,R.Player
C_Map.GetWorldPosFromMapPos=function(_,v)local x,y=v:GetXY();return 1,CreateVector2D(x*1000,y*1000)end
G.Project=function(p)return p.wx/1000,p.wy/1000 end
local function point(x,y)return R.World({mapID=1454,x=x/1000,y=y/1000})end
local function fixture(lines)
  F.roadData={lines={}}
  for _,coords in ipairs(lines)do F.roadData.lines[#F.roadData.lines+1]={name='Test road',points=coords}end
  roads.Invalidate()
end
fixture({{{1454,0,0},{1454,0,10},{1454,10,10},{1454,10,0}}})
local a,b=point(0,0),point(100,0)
local d,segments=roads.Path(a,b)
assert(d==300 and #segments==3,'Follow the U-shaped road instead of cutting across the obstacle')
assert(roads.Path(b,a)==300,'Road travel works in reverse')
local seconds,steps=R.Leg(a,b,{nodes={},edges={}},false)
assert(math.abs(seconds-300/7)<0.00001 and #steps==3,'ETA and renderer must use the same road geometry')
assert(steps[1].to.wx==0 and steps[1].to.wy==100 and steps[1].road=='mapped')
local withUnusedTaxi=R.Leg(a,b,{nodes={unused=point(50,0)},edges={}},true)
assert(math.abs(withUnusedTaxi-300/7)<0.00001,'An unused taxi node must not create two straight-line shortcuts across the obstacle')
local guide={walkSteps=steps,walkIndex=1,travelTarget=b,travelAction='Deliver to customer'}
F.AdvanceRoadGuidance(guide,a)
assert(guide.target==steps[1].to and guide.action=='Follow the road')
F.AdvanceRoadGuidance(guide,point(0,95))
assert(guide.target==steps[2].to,'Arrow advances to the next bend')
F.AdvanceRoadGuidance(guide,point(100,95))
assert(guide.target==steps[3].to)
F.AdvanceRoadGuidance(guide,b)
assert(guide.target==b and guide.action=='Deliver to customer','Arrival restores the delivery action')

local _,approach=roads.Path(point(10,20),b)
assert(approach[1].road=='approach','Off-road access must not masquerade as a traced path')
assert(roads.Path(point(500,500),b)==nil,'Do not snap distant positions across unknown terrain')
local _,unknown=R.Leg(point(500,500),b,{nodes={},edges={}},false)
assert(#unknown==1 and unknown[1].road=='unknown')
local unknownGuide={walkSteps=unknown,walkIndex=1}
F.AdvanceRoadGuidance(unknownGuide,point(500,500))
assert(unknownGuide.action=='Direction only' and unknownGuide.roadWarning)

F.route={{steps=steps,stop={point=b}}};F.guidance=nil;R.Player=function()return nil end
local overlay=F.CreateRouteOverlay(UIParent)
local function project(p)return p.wx+20,p.wy+20 end
local function clip(x,y,u,v)return x,y,u,v end
F.DrawRouteOverlay(overlay,project,clip,function()return true end,false)
assert(#overlay.lines==3,'Shared world/compass/minimap renderer must draw every road bend')
F.route={{steps=unknown,stop={point=b}}}
F.DrawRouteOverlay(overlay,project,clip,function()return true end,false)
for _,line in ipairs(overlay.lines)do assert(not line.shown,'Clear old lines and never draw the unknown straight shortcut')end

fixture({{{1454,0,0},{1454,0,10}},{{1454,10,0},{1454,10,10}}})
assert(roads.Path(a,b)==nil,'Disconnected roads cannot be joined by proximity')
for _,line in ipairs(reviewedData.lines)do
  assert(#line.points>=2 and type(line.name)=='string')
  for _,p in ipairs(line.points)do
    assert(p[1]>0 and p[2]>=0 and p[2]<=100 and p[3]>=0 and p[3]<=100,'Reviewed map coordinates must be within bounds')
  end
end
F.roadData,C_Map.GetWorldPosFromMapPos,G.Project=oldData,oldWorld,oldProject
F.route,F.guidance,R.Player=oldRoute,oldGuide,oldPlayer
roads.Invalidate()
print('PASS: traced road distances, shared bent lines, compass turn progression, disconnected roads and explicit unmapped approaches')
