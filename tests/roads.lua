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
F.AdvanceRoadGuidance(guide,point(0,99))
assert(guide.target==steps[2].to,'Arrow advances to the next bend')
F.AdvanceRoadGuidance(guide,point(100,99))
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
assert(#overlay.lines>3 and overlay.lines[1].shown,'Keep unknown walking visible as separate direction-only dashes')

local stop={questID=1,point=b}
local later={from=b,to=point(200,0),mode='Travel',road='mapped'}
F.route={{steps=steps,stop=stop},{steps={later},stop={questID=2,point=later.to}}}
F.guidance={stop=stop,steps=steps,walkSteps=steps,walkIndex=1,travelTarget=b,travelAction='Deliver to customer'}
local oldPath=roads.Path
local originalStart=steps[1].from
roads.Path=function()error('Redrawing must not recalculate paths')end
local live=point(0,40)
local displayed=F.DisplayRoute(live)
assert(displayed[1].from==live and displayed[1].to==steps[1].to,'Line begins at the live player arrow and keeps the next bend')
assert(displayed[2].from==steps[2].from and displayed[4].from==b,'Keep future bends and later deliveries fixed')
assert(steps[1].from==originalStart,'Do not mutate the planned route while trimming its display')
displayed=F.DisplayRoute(point(0,95))
assert(#displayed==4,'Do not cut across a corner before reaching it')
live=point(0,99);displayed=F.DisplayRoute(live)
assert(#displayed==3 and displayed[1].from==live and displayed[1].to==steps[2].to,'Remove the completed road section immediately')
F.guidance.walkIndex=1
displayed=F.DisplayRoute(point(50,40))
assert(displayed[1].road=='unknown','Drifting away from the road must not draw a new straight shortcut')
roads.Path=oldPath

fixture({{{1454,0,0},{1454,0,10}},{{1454,10,0},{1454,10,10}}})
assert(roads.Path(a,b)==nil,'Disconnected roads cannot be joined by proximity')
-- The local regression uses a synthetic common map scale. World regions
-- must not overlap it as they would under that deliberately simplified API.
local localLines={}
for _,line in ipairs(reviewedData.lines)do
  if line.points[1][1]==1411 or line.points[1][1]==1454 then localLines[#localLines+1]=line end
end
F.roadData={lines=localLines};roads.Invalidate()
local forecourt=R.World({mapID=1411,x=0.465,y=0.139})
local tower=R.World({mapID=1411,x=0.507,y=0.145})
local shortCost,shortPath=roads.Path(forecourt,tower)
assert(shortCost and #shortPath>0,'The reported forecourt position must connect to the tower approach')
for _,step in ipairs(shortPath)do
  assert(step.to.y<=0.14701,'Do not send the player south around the old forecourt detour')
end
local oldLines={}
for _,line in ipairs(localLines)do if line.name~='Zeppelin forecourt approach' then oldLines[#oldLines+1]=line end end
F.roadData={lines=oldLines};roads.Invalidate()
local detourCost=roads.Path(forecourt,tower)
assert(detourCost and shortCost<detourCost,'The added northern connection must beat the old southern approach')

local oldUpdate,oldNavigator,oldTaxi=F.UpdateGuidance,F.UpdateNavigator,UnitOnTaxi
local replans,redraws=0,0
local movingPlayer=point(0,0)
F.guidance={origin=movingPlayer}
R.Player=function()return movingPlayer end
UnitOnTaxi=function()return false end
F.UpdateGuidance=function()replans=replans+1;F.guidance={origin=movingPlayer}end
F.UpdateNavigator=function()redraws=redraws+1 end
F.RefreshMovingGuidance();assert(replans==0,'Standing still must not replan')
movingPlayer=point(0,2);F.RefreshMovingGuidance();assert(replans==0,'Ignore tiny position changes')
movingPlayer=point(0,4);F.RefreshMovingGuidance();assert(replans==1 and redraws==1,'Movement replans the active leg and refreshes its display')
F.RefreshMovingGuidance();assert(replans==1,'Do not repeatedly replan the same position')
movingPlayer=point(0,20);UnitOnTaxi=function()return true end
F.guidance.action='In flight'
F.RefreshMovingGuidance();assert(replans==1,'Keep booked flight guidance intact')
F.UpdateGuidance,F.UpdateNavigator,UnitOnTaxi=oldUpdate,oldNavigator,oldTaxi
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
