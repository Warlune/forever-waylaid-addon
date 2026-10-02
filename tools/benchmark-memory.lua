-- Run from the repository root with Lua 5.1. These measure Lua allocations,
-- not the WoW process, texture memory, or a player's SavedVariables size.
local F={Style={},Geometry={},Positive=function(n)return type(n)=='number' and n>0 and n<math.huge end}
local root=(...) or 'WaylaidForever'
UnitFactionGroup=function()return 'Horde'end
assert(loadfile(root..'/Routing.lua'))('WaylaidForever',F)
assert(loadfile(root..'/Navigator.lua'))('WaylaidForever',F)
local function p(x,y)return {wx=x,wy=y or 0,instance=0,mapID=1415,x=.5,y=.5}end
local start=p(0)
local flights={nodes={},edges={}}
for i=1,60 do flights.nodes[i]=p(i*700,(i%7)*600);flights.edges[i]={} end
for i=1,60 do for j=1,60 do
  if i~=j then flights.edges[i][j]=F.Route.Distance(flights.nodes[i],flights.nodes[j])/32 end
end end
flights=F.Route.PrepareFlights(flights)
local travel={links={},personal={{to=p(15000),id=1,mode='Hearthstone',resource='hearth',wait=40,seconds=15}},resources={hearth=1}}
local stops={};for i=1,6 do stops[i]={questID=i,point=p(i*4000,(i%3)*2000)} end
local function measure(name,fn)
  collectgarbage('collect');collectgarbage('stop')
  local before,started=collectgarbage('count'),os.clock()
  local value=fn()
  local allocated,seconds=collectgarbage('count')-before,os.clock()-started
  collectgarbage('restart');collectgarbage('collect')
  local retained=collectgarbage('count')-before
  print(string.format('%s: allocated=%.1f KiB retained=%.1f KiB time=%.4fs',name,allocated,retained,seconds))
  return value
end
measure('10 active-leg calculations',function()
  local result
  for _=1,10 do local _,steps=F.Route.Leg(start,stops[6].point,flights,true,travel);result=steps end
  return result
end)
F.route=measure('6-delivery plan',function()return F.Route.Plan(start,stops,flights,true,travel)end)
F.Route.Player=function()return start end
local segments,markers={},{}
measure('1000 map route builds',function()
  local result
  for _=1,1000 do result=F.DisplayRoute(start,segments,markers) end
  return result
end)
