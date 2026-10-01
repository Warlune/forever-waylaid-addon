local F = {}
local frames = {}
local function object()
  local o = {scripts={},shown=true}
  return setmetatable(o,{__index=function(self,key)
    if key=="SetScript" or key=="HookScript" then return function(s,event,fn) s.scripts[event]=fn end end
    if key=="Show" then return function(s) s.shown=true end end
    if key=="Hide" then return function(s) s.shown=false end end
    if key=="IsShown" then return function(s) return s.shown end end
    if key=="SetText" then return function(s,text) assert(type(text)=="string" or type(text)=="number");s.text=text end end
    if key=="GetWidth" or key=="GetHeight" then return function()return 500 end end
    if key=="GetFrameLevel" then return function() return 1 end end
    if key=="CreateFontString" or key=="CreateTexture" or key=="CreateLine" then return object end
    return function() end
  end})
end
function CreateFrame() local o=object();frames[#frames+1]=o;return o end
UIParent=object();GameTooltip=object();ItemRefTooltip=object();UISpecialFrames={};SlashCmdList={}
DEFAULT_CHAT_FRAME={AddMessage=function()end}
GetServerTime=function()return 1000 end;time=GetServerTime;date=function()return "test date" end
GetRealmName=function()return "Test Realm"end;UnitFactionGroup=function()return "Horde"end
C_Timer={After=function(_,fn)fn()end}
function CreateVector2D(x,y)return{GetXY=function()return x,y end}end
C_Map={GetBestMapForUnit=function()return 1454 end,
 GetPlayerMapPosition=function()return CreateVector2D(0.5,0.5)end,
 GetWorldPosFromMapPos=function(_,v)return 1,v end,
 GetMapInfo=function()return{parentMapID=0}end}
C_QuestLog={IsOnQuest=function()return false end,IsComplete=function()return false end}
C_Item={GetItemCount=function()return 0 end}
Enum={}
local function load(name) assert(loadfile('ForeverWaylaid/'..name..'.lua'))('ForeverWaylaid',F) end
for _,name in ipairs({'Catalog','Prices','Core','Pricing','Routing','Tracking','Tooltips','UI','Map'}) do load(name) end
F.events.scripts.OnEvent(nil,'ADDON_LOADED','ForeverWaylaid')
F.events.scripts.OnEvent(nil,'PLAYER_LOGIN')
for _,tab in ipairs({'Crates','Writs','Route','Settings'}) do F.tab=tab;F.Render() end
assert(#F.catalog.crates==30 and #F.catalog.writs==150)
print('PASS: addon load, login, all four panels and catalogue')

local public={price=90,time=100,source='AHledger.com'}
assert(F.SelectPrice(public,{price=50,time=99})==public)
assert(F.SelectPrice(public,{price=50,time=100})==public)
assert(F.SelectPrice(public,{price=50}).price==90)
assert(F.SelectPrice(public,{price=50,time=101}).price==50)
assert(F.SelectPrice(nil,{price=50}).price==50)
F.bundledPrices={['forever.pvp.horde.us']={time=100,items={[123]={10,100},[1]={50,1},[2]={2,1}}}}
F.char.ruleset='pvp';F.char.localPrices={['Test Realm:Horde']={[123]={price=8,time=101,quantity=100,source='Auctionator'}}}
assert(F.Price(123).price==8)
F.db.settings.personal=false;assert(F.Price(123).price==10);F.db.settings.personal=true
UnitFactionGroup=function()return 'Alliance'end;assert(F.Price(123)==nil);UnitFactionGroup=function()return 'Horde'end
local crate={id=1,options={{itemId=123,qty=10,name='First'},{itemId=2,qty=10,name='Low stock'}}}
local _,best=F.CrateCosts(crate);assert(best.cost==80)
F.db.settings.includeCrate=true;_,best=F.CrateCosts(crate);assert(best.cost==130)
F.bundledPrices['forever.pvp.horde.us'].items[1]=nil;_,best=F.CrateCosts(crate);assert(best==nil)
print('PASS: source recency, ties, unknown age, market isolation, stock and crate totals')

local id=F.catalog.crates[1].options[1].itemId
F.SaveAuctionatorRows('full',{{auctionInfo={[3]=10,[10]=500,[17]=id}},{auctionInfo={[3]=5,[10]=100,[17]=id}}},'Test Realm:Horde',500)
local captured=F.char.localPrices['Test Realm:Horde'][id]
assert(captured.price==20 and captured.quantity==15 and captured.time==500)
F.SaveAuctionatorRows('incremental',{{itemKey={itemID=id},minPrice=25,totalQuantity=30}},'Test Realm:Horde',600)
assert(F.char.localPrices['Test Realm:Horde'][id].price==25)
print('PASS: Auctionator full and incremental scans preserve observation times and quantities')

local function p(x,y,instance)return{wx=x,wy=y or 0,instance=instance or 1}end
local flights={nodes={a=p(0),b=p(7000)},edges={a={b=50}}}
local walk=F.Route.Leg(p(0),p(7000),flights,false);assert(walk==1000)
local fly,steps=F.Route.Leg(p(0),p(7000),flights,true);assert(fly==65)
assert(steps[2].mode=='Fly')
local reverse=F.Route.Leg(p(7000),p(0),flights,true);assert(reverse==1000)
local no={nodes={},edges={}}
local stops={{point=p(21),id=3},{point=p(7),id=1},{point=p(14),id=2},{point=p(1,1,2),id=4},{id=5}}
local route,missing,total=F.Route.Plan(p(0),stops,no,true)
assert(#route==3 and #missing==2 and total==3 and route[1].stop.id==1 and route[3].stop.id==3)
local fixture={{point=p(2,9)},{point=p(-3,8)},{point=p(4,-3)},{point=p(8,7)},{point=p(1,0)}}
local function brute(at,left)
  if #left==0 then return 0 end
  local min=math.huge
  for i,stop in ipairs(left)do
    local rest={};for j,s in ipairs(left)do if j~=i then rest[#rest+1]=s end end
    min=math.min(min,F.Route.Distance(at,stop.point)/7+brute(stop.point,rest))
  end
  return min
end
local _,_,exact=F.Route.Plan(p(0),fixture,no,false);assert(math.abs(exact-brute(p(0),fixture))<0.00001)
local many={};for i=1,12 do many[i]={point=p(i*7)} end
local long,_,cost,mode=F.Route.Plan(p(0),many,no,false);assert(#long==12 and cost==12 and mode=='estimated')
print('PASS: directed flights, disabled flights, missing/cross-continent stops, exact ordering, large route fallback')

AucAdvanced={Const={ITEMID=1,COUNT=2,BUYOUT=3,TIME=4},Resources={ServerKeyHome='home'},Scan={
 GetImageCopy=function(key) assert(key=='home');return{{id,5,500,700},{id,10,500,700},{id,1,1,500}}end}}
F.ImportPersonal();assert(F.char.localPrices['Test Realm:Horde'][id].price==50)
assert(F.char.localPrices['Test Realm:Horde'][id].quantity==15)
local first=F.catalog.writs[1]
C_QuestLog.IsOnQuest=function(q)return q==first.questId end
C_QuestLog.IsComplete=function()return false end
C_QuestLog.GetNextWaypoint=function()return 1454,0.2,0.3 end
F.UpdateTracking();assert(#F.active==1 and #F.unresolved==1 and #F.route==0)
C_QuestLog.IsComplete=function()return true end
F.UpdateTracking();assert(#F.route==1)
F.char.pins[first.questId]={mapID=1454,x=0.7,y=0.8,manual=true}
C_QuestLog.IsComplete=function()return false end
F.UpdateTracking();assert(#F.route==1 and F.route[1].stop.manual)
C_QuestLog.IsOnQuest=function()return false end
F.UpdateTracking();assert(#F.route==0)
print('PASS: Auctioneer home-faction image, accepted/ready/pinned/removed writ lifecycle')

C_Map.GetMapChildrenInfo=function()return{{mapID=1454}}end
C_TaxiMap={GetTaxiNodesForMap=function()return{
 {nodeID=1,name='A',position=CreateVector2D(0.1,0.1),faction=1,isUndiscovered=false},
 {nodeID=2,name='B',position=CreateVector2D(0.8,0.8),faction=1,isUndiscovered=false},
 {nodeID=3,name='Locked',position=CreateVector2D(0.9,0.9),faction=1,isUndiscovered=true}}end}
NumTaxiNodes=function()return 3 end
TaxiNodeGetType=function(i)return ({'CURRENT','REACHABLE','UNREACHABLE'})[i]end
TaxiNodeName=function(i)return ({'A','B','Locked'})[i]end
F.LearnFlights();assert(F.char.flights.nodes[1] and F.char.flights.nodes[2] and not F.char.flights.nodes[3])
assert(F.char.flights.edges[1][2] and not F.char.flights.edges[2])
C_QuestLog.IsOnQuest=function(q)return q==first.questId end
F.UpdateTracking();F.tab='Route';F.Render()
WorldMapFrame=object();WorldMapFrame.ScrollContainer={Child=object()}
WorldMapFrame.GetMapID=function()return 1454 end
C_Map.GetMapPosFromWorldPos=function(_,v,map)return map,v end
F.InstallMap();local overlay=frames[#frames];overlay.scripts.OnUpdate(nil,2)
print('PASS: known/unknown flight filtering, directed routes, populated route UI and map overlay')
