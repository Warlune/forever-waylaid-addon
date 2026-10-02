local F = {}
unpack=unpack or table.unpack
local frames = {}
local function object()
  local o = {scripts={},shown=true}
  return setmetatable(o,{__index=function(self,key)
    if key=="RegisterEvent" then return function(s,event)
      assert(event~="COMBAT_LOG_EVENT_UNFILTERED" and event~="COMBAT_LOG_EVENT",'Forever forbids addon combat-log registration')
      s.events=rawget(s,'events') or {};s.events[event]=true
    end end
    if key=="SetScript" or key=="HookScript" then return function(s,event,fn) s.scripts[event]=fn end end
    if key=="Show" then return function(s) s.shown=true end end
    if key=="Hide" then return function(s) s.shown=false end end
    if key=="IsShown" then return function(s) return s.shown end end
    if key=="SetShown" then return function(s,value)s.shown=value end end
    if key=="SetText" then return function(s,text) assert(type(text)=="string" or type(text)=="number");s.text=text end end
    if key=="GetWidth" or key=="GetHeight" then return function()return 500 end end
    if key=="SetFrameStrata" then return function(s,value)s.frameStrata=value end end
    if key=="SetFrameLevel" then return function(s,value)s.frameLevel=value end end
    if key=="EnableMouse" then return function(s,value)s.mouseEnabled=value end end
    if key=="SetValue" then return function(s,value)s.value=value end end
    if key=="SetStatusBarColor" then return function(s,...)s.barColor={...} end end
    if key=="SetAtlas" then return function(s,value)s.atlas=value end end
    if key=="GetFrameLevel" then return function(s) return rawget(s,'frameLevel') or 1 end end
    if key=="CreateTexture" then return function(s,name,layer,template,sublevel)local t=object();t.drawLayer=layer;t.drawSublevel=sublevel;return t end end
    if key=="CreateFontString" or key=="CreateLine" or key=="CreateMaskTexture" then return object end
    if key=="GetStatusBarTexture" then return function(s) s.barTexture=rawget(s,"barTexture") or object();return s.barTexture end end
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
local function load(name) assert(loadfile('WaylaidForever/'..name..'.lua'))('WaylaidForever',F) end
for _,name in ipairs({'Catalog','Recipes','Core','Diagnostics','Pricing','Scanner','Peers','Crafting','Style','Accessibility','AuctionScanUI','Geometry','Routing','TransportData','Travel','Tracking','Tooltips','UI','Journey','Map','Navigator'}) do load(name) end
assert(F.Roads==nil and F.roadData==nil, "Advanced road engine must not be loaded")
F.events.scripts.OnEvent(nil,'ADDON_LOADED','WaylaidForever')
F.events.scripts.OnEvent(nil,'PLAYER_LOGIN')
F.window:Show()
for _,tab in ipairs({'Crates','Writs','Route','Settings'}) do F.tab=tab;F.Render() end
assert(#F.catalog.crates==30 and #F.catalog.writs==150)
print('PASS: addon load, login, all four panels and catalogue')

local public={price=90,time=100,source='Peer scan (unverified)'}
assert(F.SelectPrice(public,{price=50,time=99})==public)
assert(F.SelectPrice(public,{price=50,time=100})==public)
assert(F.SelectPrice(public,{price=50}).price==90)
assert(F.SelectPrice(public,{price=50,time=101}).price==50)
assert(F.SelectPrice(nil,{price=50}).price==50)
F.db.settings.peerSharing=true
F.char.peerPrices={['Test Realm:Horde']={[123]={price=10,time=100,quantity=100,source='Peer scan (unverified)'},[1]={price=50,time=100,quantity=1},[2]={price=2,time=100,quantity=1}}}
F.char.localPrices={['Test Realm:Horde']={[123]={price=8,time=101,quantity=100,source='Auctionator'}}}
assert(F.Price(123).price==8)
F.db.settings.personal=false;assert(F.Price(123).price==10);F.db.settings.personal=true
UnitFactionGroup=function()return 'Alliance'end;assert(F.Price(123)==nil);UnitFactionGroup=function()return 'Horde'end
local crate={id=1,options={{itemId=123,qty=10,name='First'},{itemId=2,qty=10,name='Low stock'}}}
local _,best=F.CrateCosts(crate);assert(best.cost==80)
F.db.settings.includeCrate=true;_,best=F.CrateCosts(crate);assert(best.cost==130)
F.char.peerPrices['Test Realm:Horde'][1]=nil;_,best=F.CrateCosts(crate);assert(best==nil)
F.db.settings.peerSharing=false
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
F.InstallMap();local overlay=F.worldOverlay;overlay.scripts.OnUpdate(nil,2)
print('PASS: known/unknown flight filtering, directed routes, populated route UI and map overlay')

local G=F.Geometry
local x,y,u,v=G.Rect(-10,50,110,50,0,0,100,100)
assert(x==0 and y==50 and u==100 and v==50)
assert(G.Rect(-10,-10,-2,-2,0,0,100,100)==nil)
x,y,u,v=G.Circle(-20,0,20,0,10);assert(x==-10 and u==10 and y==0 and v==0)
assert(G.Circle(-20,20,20,20,10)==nil)
local center=p(0,0)
assert(math.abs(G.Bearing(center,p(100,0),0))<0.001)
assert(math.abs(G.Bearing(center,p(0,-100),0)+math.pi/2)<0.001)
x,y=G.Relative(center,p(0,100),math.pi/2);assert(math.abs(x)<0.001 and y>99)
F.tab='Crates';F.onlyOwned=false;F.searchText='peacebloom';F.tierIndex=1
local entries=F.LedgerEntries();assert(#entries==1 and entries[1].item.id==248682)
F.searchText='';F.tierIndex=2;entries=F.LedgerEntries();for _,entry in ipairs(entries)do assert(entry.item.tier=='Apprentice')end
F.tab='Route';F.UpdateGuidance();assert(F.guidance and F.guidance.stop.questID==first.questId)
F.window:Hide();F.UpdateNavigator();assert(F.compass:IsShown())
F.char.navExpanded=true;F.UpdateNavigator();assert(F.compass.map:IsShown())
F.db.settings.navigator=false;F.UpdateNavigator();assert(not F.compass:IsShown())
print('PASS: circle/rectangle clipping, cardinal bearings, rotated minimap, material search, tiers, independent compass')

-- The compass must guide to departure, keep the arrival while airborne,
-- and then guide to the customer even with the ledger closed.
local oldPlayer=F.Route.Player
local player=p(-100);player.mapID=1454;player.x=0.5;player.y=0.5
F.Route.Player=function()return player end
local customer=p(7100);customer.mapID=1454;customer.x=0.7;customer.y=0.5
local stop={questID=first.questId,writ=first,point=customer,ready=true,npc='Test Customer'}
F.char.flights=flights;F.db.settings.flights=true;F.char.navQuest=first.questId
F.active={stop};F.route={{stop=stop}};UnitOnTaxi=function()return false end
F.UpdateGuidance();assert(F.guidance.target==flights.nodes.a and F.guidance.action=='Direction only')
player.wx=0;F.UpdateGuidance();assert(F.guidance.action:find('Take flight',1,true))
UnitOnTaxi=function()return true end;player.wx=4000
F.UpdateGuidance();assert(F.guidance.target==flights.nodes.b and F.guidance.action=='In flight')
UnitOnTaxi=function()return false end;player.wx=7000
F.UpdateGuidance();assert(F.guidance.target==customer and F.guidance.action=='Direction only')
F.Route.Player=oldPlayer
Minimap=object();Minimap.GetZoom=function()return 0 end
C_Minimap={GetViewRadius=function()return 200 end}
GetCVar=function()return '0' end
F.BuildNavigator();F.DrawMinimap();assert(F.minimapButton and F.minimapOverlay)
F.minimapButton.scripts.OnClick(nil,'LeftButton');assert(F.window:IsShown())
F.db.settings.navigator=true;F.minimapButton.scripts.OnClick(nil,'RightButton');assert(not F.compass:IsShown())
print('PASS: departure/in-flight/customer guidance, minimap overlay and launcher controls')
assert(loadfile('tests/crafting.lua'))(F)
assert(loadfile('tests/ledger.lua'))(F)
assert(loadfile('tests/search.lua'))(F)
assert(loadfile('tests/scanner.lua'))(F)
assert(loadfile('tests/peers.lua'))(F)
assert(loadfile('tests/auction-ui.lua'))(F)
assert(loadfile('tests/tooltips.lua'))(F)
assert(loadfile('tests/settings.lua'))(F)
assert(loadfile('tests/accessibility.lua'))(F)
assert(loadfile('tests/travel.lua'))(F)
assert(loadfile('tests/transport.lua'))(F)

-- Manual compass zoom must survive route refreshes and follow the player's
-- current zone instead of pinning the map to a previously visited city.
do
  local oldInfo,oldPlayer,oldDraw,oldGuide=C_Map.GetMapInfo,F.Route.Player,F.DrawTravelRoute,F.guidance
  local maps={
    [947]={name='Azeroth',mapType=1,parentMapID=946},
    [1414]={name='Kalimdor',mapType=2,parentMapID=947},
    [1454]={name='Orgrimmar',mapType=3,parentMapID=1414},
    [1411]={name='Durotar',mapType=3,parentMapID=1414},
    [1415]={name='Eastern Kingdoms',mapType=2,parentMapID=947},
  }
  local zone=1454
  C_Map.GetMapInfo=function(id)return maps[id]end
  F.Route.Player=function()return {mapID=zone}end
  F.DrawTravelRoute=function()end
  F.guidance={target={mapID=1415}}
  local map=F.CreateTravelMap(UIParent,0,0,284,189)
  map.zoomIn.SetEnabled=function(self,on)self.enabled=on end
  map.zoomOut.SetEnabled=function(self,on)self.enabled=on end
  F.UpdateTravelMap(map)
  assert(map.mapID==947 and not map.zoomOut.enabled and map.zoomIn.enabled)
  map.zoomIn.scripts.OnClick();assert(map.mapID==1414)
  map.zoomIn.scripts.OnClick();assert(map.mapID==1454 and not map.zoomIn.enabled)
  F.UpdateTravelMap(map);assert(map.mapID==1454,'Refresh must preserve the selected zoom')
  zone=1411;F.UpdateTravelMap(map);assert(map.mapID==1411,'Zone zoom should follow the player')
  map.zoomOut.scripts.OnClick();assert(map.mapID==1414)
  map.zoomOut.scripts.OnClick();assert(map.mapID==947 and not map.zoomOut.enabled)
  F.ZoomTravelMap(map,-1);assert(map.mapID==947,'Do not zoom past the world into cosmic maps')
  F.Route.Player=function()return nil end;F.UpdateTravelMap(map)
  assert(not map.zoomIn.enabled and not map.zoomOut.enabled,'Disable zoom when player position is unavailable')
  C_Map.GetMapInfo,F.Route.Player,F.DrawTravelRoute,F.guidance=oldInfo,oldPlayer,oldDraw,oldGuide
  print('PASS: compass world/continent/zone zoom, limits, refresh persistence and zone transitions')
end

assert(loadfile('tests/requirements.lua'))(F)
assert(loadfile('tests/reroute.lua'))(F)
assert(loadfile('tests/map-layers.lua'))(F)
assert(loadfile('tests/journey.lua'))(F)
assert(F.Pets==nil and F.PetData==nil,'Waylaid does not load any companion engine or catalogue')
local companions=assert(loadfile('tests/companions.lua'))(F)
assert(loadfile('tests/pets.lua'))(companions)

assert(loadfile('tests/security-memory.lua'))(F,companions)

assert(loadfile('tests/crate-details.lua'))(F)
assert(loadfile('tests/rename.lua'))(F,companions)
print("ALL ADDON TESTS PASSED")
