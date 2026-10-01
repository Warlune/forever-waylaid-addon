local F=...
local old={route=F.route,guidance=F.guidance,flightGuidance=F.flightGuidance,travel=F.travel}
local oldPlayer,oldTaxi=F.Route.Player,UnitOnTaxi
local oldFlights,oldEnabled,oldNav=F.char.flights,F.db.settings.flights,F.UpdateNavigator
local function p(map,x,name)
  return {mapID=map,x=x/10000,y=0.5,wx=x,wy=500,instance=map==1411 and 1 or 0,name=name}
end
local org,dock=p(1411,0,'Orgrimmar'),p(1411,100,'Zeppelin tower')
local land,fp=p(1420,0,'Tirisfal zeppelin'),p(1420,100,'Undercity flight master')
local arrival,customer=p(1417,8000,'Hammerfall flight master'),p(1417,8100,'Customer')
local stop={questID=1,point=customer,npc='Customer',writ={name='Test writ'}}
local player,flying=org,false
F.Route.Player=function()return player end
UnitOnTaxi=function()return flying end
F.UpdateNavigator=function()end
F.char.flights={nodes={a=fp,b=arrival},edges={a={b=60}}};F.db.settings.flights=true
F.travel={links={{from=dock,to=land,mode='Zeppelin',seconds=20}},personal={},resources={}}
local seconds,steps=F.Route.Leg(org,customer,F.char.flights,true,F.travel)
assert(seconds<math.huge and #steps==5)
assert(steps[1].mode=='Travel' and steps[2].mode=='Zeppelin' and steps[3].mode=='Travel'
  and steps[4].mode=='Fly' and steps[5].mode=='Travel','Plan all walks between and after transport')
F.route={{steps=steps,stop=stop}};F.UpdateGuidance()
local shown=F.DisplayRoute()
assert(#shown==5 and shown[3].from==land and shown[3].to==fp)
assert(shown[5].from==arrival and shown[5].to==customer,'Future walk starts at Hammerfall, not current position in Orgrimmar')

-- Even while in Orgrimmar the Arathi zone must show the arrival-to-customer walk.
local overlay=F.CreateRouteOverlay(UIParent)
overlay.CreateLine=function()
  return {SetThickness=function()end,SetColorTexture=function(self,...)self.color={...}end,
    SetStartPoint=function(self,_,_,x,y)self.x,self.y=x,y end,
    SetEndPoint=function(self,_,_,x,y)self.toX,self.toY=x,y end,
    Show=function(self)self.shown=true end,Hide=function(self)self.shown=false end}
end
local function project(point)if point.mapID==1417 then return point.wx,point.wy end end
local function clip(x,y,u,v)return x,y,u,v end
F.DrawRouteOverlay(overlay,project,clip,function()return true end,false)
assert(#overlay.lines>1 and overlay.lines[1].x==arrival.wx,'Future unmapped walk renders on local zone map')
for _,line in ipairs(overlay.lines)do
  assert(line.x>=8000 and line.toX<=8100 and line.color[4]==0.65,'Unknown walk is dashed, never a solid claimed road')
end

player=land;F.UpdateGuidance();shown=F.DisplayRoute()
assert(#shown==3 and shown[1].mode=='Travel' and shown[1].from==land and shown[1].to==fp,
  'After disembarking keep the walk to the flight master')
assert(shown[3].from==arrival,'Updating current walking position cannot move a future walk origin')
player=fp;F.UpdateGuidance()
flying=true;F.RefreshMovingGuidance();shown=F.DisplayRoute()
assert(F.guidance.action=='In flight' and #shown==2 and shown[1].mode=='Fly',
  'Boarding immediately removes completed approach, retaining flight and final walk')
assert(shown[2].from==arrival and shown[2].to==customer)
flying=false;player=arrival;F.RefreshMovingGuidance();shown=F.DisplayRoute()
assert(#shown==1 and shown[1].mode=='Travel' and shown[1].from==arrival,'Landing immediately restores walking guidance')
player=p(1417,8040,'Walking');F.RefreshMovingGuidance();shown=F.DisplayRoute()
assert(shown[1].from==player and shown[1].to==customer,'Only the active walk follows the player arrow')

local later=p(1417,8300,'Second customer')
F.route[2]={stop={questID=2,point=later},steps={{from=customer,to=later,mode='Travel',road='unknown'}}}
shown=F.DisplayRoute();assert(#shown==2 and shown[2].from==customer,'Later writ keeps the previous customer as its origin')
F.route[2]=nil;assert(#F.DisplayRoute()==1,'Removing later writ removes its path')
F.route={};F.guidance=nil
F.DrawRouteOverlay(overlay,project,clip,function()return true end,false)
for _,line in ipairs(overlay.lines)do assert(not line.shown,'Last writ removal clears all paths')end
assert(F.CreateJourneyPanel==nil and F.UpdateJourneyPanel==nil,'No itinerary panel remains on the map')
F.route,F.guidance,F.flightGuidance,F.travel=old.route,old.guidance,old.flightGuidance,old.travel
F.Route.Player,UnitOnTaxi=oldPlayer,oldTaxi
F.char.flights,F.db.settings.flights,F.UpdateNavigator=oldFlights,oldEnabled,oldNav
print('PASS: Org walk/zeppelin/walk/flight/walk, future arrival anchoring, local-map dashes, boarding/landing, later writs and panel removal')
