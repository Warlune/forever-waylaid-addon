local F=...
local oldRoute,oldGuide,oldPlayer,oldInfo=F.route,F.guidance,F.Route.Player,C_Map.GetMapInfo
local maps={[947]={parentMapID=0},[1414]={parentMapID=947},[1415]={parentMapID=947},
  [1411]={parentMapID=1414,name='Durotar'},[1420]={parentMapID=1415,name='Tirisfal'},[1421]={parentMapID=1415,name='Silverpine'}}
C_Map.GetMapInfo=function(id)return maps[id]end
local function p(map,x,name)return{mapID=map,x=x/1000,y=0.5,wx=x,wy=500,instance=map==1411 and 1 or 0,name=name}end
local a,bend,b=p(1411,100,'You'),p(1411,150,'Bend'),p(1411,200,'Dock')
local via,c,d=p(1420,250,'Intermediate dock'),p(1420,300,'Arrival / flight master'),p(1421,400,'Arrival flight master')
local customer,final=p(1421,500,'First customer'),p(1411,600,'Second customer')
local stop1={questID=1,point=customer,npc='First customer',writ={name='First writ'}}
local stop2={questID=2,point=final,npc='Second customer',writ={name='Second writ'}}
local boat={via={via}}
local steps={{from=a,to=bend,mode='Travel',road='mapped'},
  {from=bend,to=b,mode='Travel',road='mapped'},
  {from=b,to=c,mode='Boat',detail=boat},
  {from=c,to=c,mode='Travel',road='unknown'}, -- no phantom walking stage between transports
  {from=c,to=d,mode='Fly'},
  {from=d,to=customer,mode='Travel',road='unknown'}}
F.route={{steps=steps,stop=stop1},{steps={{from=customer,to=final,mode='Travel',road='unknown'}},stop=stop2}}
F.guidance=nil;F.Route.Player=function()return nil end
local segments,stops=F.DisplayRoute();local stages=F.BuildJourney(segments)
assert(#stages==5 and #stages[1].points==3,'Group walking bends, not whole delivery legs')
assert(stages[1].mode=='Travel' and stages[2].mode=='Boat' and stages[3].mode=='Fly' and stages[4].mode=='Travel')
assert(#stages[2].points==3 and stages[2].points[2]==via,'Retain intermediate ports within the boat stage')
assert(stages[4].delivery==1 and stages[5].delivery==2,'Keep consecutive walks for different writs distinct')
assert(stages[4].unmapped and not stages[1].unmapped)
assert(F.JourneyTitle(stages[4]):find('Turn%-in: First customer'))
assert(F.JourneyMap(stages,stops)==947,'Overview must include later deliveries on other continents')
assert(F.JourneyMap({stages[3]})==1415,'A flight stage focuses its common continent')
assert(F.JourneyMap({stages[1]})==1411,'Local walking stage focuses its zone')

F.guidance={stop=stop1,steps=steps,walkSteps={steps[1],steps[2]},walkIndex=2}
local live=p(1411,170,'Live position')
stages=F.BuildJourney(F.DisplayRoute(live))
assert(stages[1].from==live and stages[1].to==b and stages[2].from==b,'Trim only completed walking; keep future stages anchored')
assert(steps[1].from==a and not steps[1].stage,'Building the view must not mutate the planned route')
F.guidance=nil

local viewed
local map={ScrollContainer=UIParent,SetMapID=function(_,id)viewed=id end}
local overlay=F.CreateRouteOverlay(UIParent);overlay.journey=stages;overlay.journeyStops=stops
local panel=F.CreateJourneyPanel(map,overlay)
F.UpdateJourneyPanel(panel,map,overlay)
assert(panel.shown and panel.rows[1].stage.number==1 and panel.rows[3].stage.number==3)
panel.overview.scripts.OnClick();assert(viewed==947)
panel.rows[3].scripts.OnClick(panel.rows[3]);assert(viewed==1415,'Stage click changes map, not the selected delivery')
panel.next.scripts.OnClick();assert(panel.page==2 and panel.rows[1].stage.delivery==1 and panel.rows[2].stage.delivery==2)
panel.header.scripts.OnClick();assert(panel.collapsed and not panel.rows[1].shown and panel.overview.shown)
panel.header.scripts.OnClick();assert(not panel.collapsed and panel.rows[1].shown)
F.route={F.route[1]};segments,stops=F.DisplayRoute();overlay.journey=F.BuildJourney(segments);overlay.journeyStops=stops
F.UpdateJourneyPanel(panel,map,overlay)
assert(not panel.rows[2].shown,'Removed writ must vanish from the full journey')
F.route={};overlay.journey=F.BuildJourney(F.DisplayRoute());F.UpdateJourneyPanel(panel,map,overlay)
assert(not panel.shown,'No stale journey panel after the last delivery is removed')

F.route={{steps={{from=a,to=b,mode='Travel',road='unknown'}},stop=stop1}}
local function project(point)return point.wx,point.wy end
local function clip(x,y,u,v)return x,y,u,v end
F.DrawRouteOverlay(overlay,project,clip,function()return true end,false,false,nil,false)
assert(#overlay.lines==0,'Unmapped ground stays hidden in local navigation')
F.DrawRouteOverlay(overlay,project,clip,function()return true end,false,false,nil,true)
assert(#overlay.lines>1 and #overlay.lines<=80,'Overview draws bounded, dashed direction-only connections')
F.DrawRouteOverlay(overlay,project,clip,function()return true end,false,false,nil,false)
for _,line in ipairs(overlay.lines)do assert(not line.shown,'Overview dashes disappear on return to local navigation')end
F.route,F.guidance,F.Route.Player,C_Map.GetMapInfo=oldRoute,oldGuide,oldPlayer,oldInfo
print('PASS: full mixed-transport journey, later writs, live trim, intermediate ports, overview/focus controls, removal and direction-only dashes')
