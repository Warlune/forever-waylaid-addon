local F=...
local oldRoute,oldGuidance=F.route,F.guidance
local function p(x)return {wx=x,wy=0,instance=0,mapID=1415,x=.5,y=.5}end
local a,b,c=p(0),p(700),p(1400)
local stop={questID=701,point=c}
F.guidance=nil
F.route={{stop=stop,steps={{from=a,to=c,mode='Fly',detail={via={b},flightPath=true}}}}}
local segments,stops={},{}
F.DisplayRoute(a,segments,stops)
local first,marker=segments[1],stops[1]
local snapshot,snapshotStops=F.DisplayRoute(a)
local other,otherStops={},{}
F.DisplayRoute(a,other,otherStops)
assert(other[1]~=first and snapshot[1]~=first,'Each map and ordinary caller owns its route tables')
assert(#segments==2 and segments[1].connectionTo and segments[2].connectionFrom)
F.DisplayRoute(a,segments,stops)
assert(segments[1]==first and stops[1]==marker,'Repeated redraws must reuse route and stop rows')

stop={questID=702,point=b}
F.route={{stop=stop,steps={{from=a,to=b,mode='Travel',road='unknown'}}}}
F.DisplayRoute(a,segments,stops)
assert(#segments==1 and segments[1]==first and #stops==1 and stops[1].stop==stop)
assert(not first.detail and not first.connectionFrom and not first.connectionTo and first.road=='unknown','Reused rows must not retain flight connections or prior details')
assert(#snapshot==2 and snapshot[1].mode=='Fly' and snapshotStops[1].stop.questID==701,'Reusing one map must not mutate a previous snapshot')
assert(#other==2 and other[1].connectionTo,'Other map remains independent')
F.route={};F.DisplayRoute(a,segments,stops)
assert(#segments==0 and #stops==0,'Last delivery removal releases all scratch-row references')

local overlay=F.CreateRouteOverlay(UIParent)
overlay.routeSegments[1]={from=a,to=b};overlay.routeStops[1]={stop=stop}
F.ClearRouteOverlay(overlay,true)
assert(#overlay.routeSegments==1,'Draw setup keeps reusable route storage')
F.ClearRouteOverlay(overlay)
assert(#overlay.routeSegments==0 and #overlay.routeStops==0,'Hidden/disabled overlay releases route references')
F.route,F.guidance=oldRoute,oldGuidance
print('PASS: reusable route buffers, snapshot isolation, stale-field clearing, removal and disabled-overlay cleanup')

-- Hidden minimaps must not query position or rebuild routes, and must release references.
do
  local oldMap,oldOverlay,oldPlayer,oldSetting=Minimap,F.minimapOverlay,F.Route.Player,F.db.settings.minimapRoute
  local visible=false
  Minimap={IsVisible=function()return visible end}
  F.minimapOverlay=overlay;F.db.settings.minimapRoute=true
  overlay.routeSegments[1]={from=a,to=b};overlay.routeStops[1]={stop=stop}
  local queries=0;F.Route.Player=function()queries=queries+1;return nil end
  for i=1,100 do F.DrawMinimap()end
  assert(queries==0 and #overlay.routeSegments==0 and #overlay.routeStops==0,'Hidden minimap should skip work and release route references')
  visible=true;F.DrawMinimap();assert(queries==1,'Showing minimap must resume refresh')
  F.db.settings.minimapRoute=false;F.DrawMinimap();assert(queries==1,'Disabled minimap must skip position queries')
  Minimap,F.minimapOverlay,F.Route.Player,F.db.settings.minimapRoute=oldMap,oldOverlay,oldPlayer,oldSetting
end
