local F=...
local old={}
for _,key in ipairs({'Render','UpdateNavigator','active','route','unresolved','routeSeconds','routeMode','guidance','flightGuidance','removedWrits','travel'})do old[key]=F[key]end
local oldPlayer,oldWorld,oldOptions=F.Route.Player,C_Map.GetWorldPosFromMapPos,F.Travel.Options
local oldOn,oldComplete,oldAfter=C_QuestLog.IsOnQuest,C_QuestLog.IsComplete,C_Timer.After
local oldPins,oldFlights,oldQuest,oldEnabled=F.char.pins,F.char.flights,F.char.navQuest,F.db.settings.flights
local ids={F.catalog.writs[1].questId,F.catalog.writs[2].questId,F.catalog.writs[3].questId}
local accepted={[ids[1]]=true,[ids[2]]=true,[ids[3]]=true}
local x=0
F.Render=function()end;F.UpdateNavigator=function()end
F.Route.Player=function()return {instance=1,mapID=1454,wx=x,wy=0,x=x/1000,y=0}end
C_Map.GetWorldPosFromMapPos=function(_,pos)local a,b=pos:GetXY();return 1,CreateVector2D(a*1000,b*1000)end
F.Travel.Options=function()return {links={},personal={},resources={}}end
C_QuestLog.IsOnQuest=function(id)return accepted[id]end
C_QuestLog.IsComplete=function()return true end
F.char.pins={};F.char.flights={nodes={},edges={}};F.db.settings.flights=false;F.removedWrits={}
for i,position in ipairs({0.1,0.2,0.9})do F.char.pins[ids[i]]={mapID=1454,x=position,y=0}end
F.char.navQuest=ids[3]
F.Refresh()
assert(#F.route==3 and F.guidance.stop.questID==ids[1] and F.char.navQuest==nil,'Old single-writ lock must not override the itinerary')
F.TrackDelivery(ids[3]);assert(F.guidance.stop.questID==ids[1],'Selecting a writ must keep the optimized multi-writ route')
local _,pins=F.DisplayRoute();assert(#pins==3,'Show the whole remaining itinerary')

-- Do not flush delayed callbacks: removing a writ must update immediately,
-- including when the quest API still reports it as accepted for a moment.
local queued={};C_Timer.After=function(_,fn)queued[#queued+1]=fn end
x=800
F.flightGuidance={stop=F.guidance.stop}
F.events.scripts.OnEvent(nil,'QUEST_REMOVED',ids[1],false)
assert(#F.route==2 and #queued==0,'Abandonment must not wait for a general log refresh')
assert(F.guidance.stop.questID==ids[3],'Replan from the current position, not the old route origin')
assert(F.flightGuidance==nil,'Discard cached guidance to the abandoned writ')
F.Refresh();assert(#F.route==2,'Stale IsOnQuest must not resurrect the abandoned delivery')
local segments;segments,pins=F.DisplayRoute()
for _,pin in ipairs(pins)do assert(pin.stop.questID~=ids[1],'Abandoned pin must disappear')end
assert(#segments==2 and #pins==2)

F.events.scripts.OnEvent(nil,'QUEST_TURNED_IN',ids[3],0,0)
assert(#F.route==1 and F.guidance.stop.questID==ids[2],'Turn-in must advance to the remaining customer')
F.events.scripts.OnEvent(nil,'QUEST_REMOVED',ids[2],false)
assert(#F.active==0 and #F.route==0 and not F.guidance,'Removing the last writ clears the compass')
segments,pins=F.DisplayRoute();assert(#segments==0 and #pins==0)

accepted[ids[2]]=false;accepted[ids[3]]=false
F.events.scripts.OnEvent(nil,'QUEST_ACCEPTED',ids[1])
for _,fn in ipairs(queued)do fn()end
assert(#F.route==1 and F.guidance.stop.questID==ids[1],'Reaccepting the same writ must restore it')
assert(F.char.pins[ids[1]],'Keep learned delivery coordinates for later writs')

for _,key in ipairs({'Render','UpdateNavigator','active','route','unresolved','routeSeconds','routeMode','guidance','flightGuidance','removedWrits','travel'})do F[key]=old[key]end
F.Route.Player,C_Map.GetWorldPosFromMapPos,F.Travel.Options=oldPlayer,oldWorld,oldOptions
C_QuestLog.IsOnQuest,C_QuestLog.IsComplete,C_Timer.After=oldOn,oldComplete,oldAfter
F.char.pins,F.char.flights,F.char.navQuest,F.db.settings.flights=oldPins,oldFlights,oldQuest,oldEnabled
print('PASS: immediate abandon/turn-in rerouting, stale quest data, current-position optimization, all-stop display, last-writ removal and reacceptance')
