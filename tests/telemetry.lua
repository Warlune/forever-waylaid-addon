local F=...
local T=F.Telemetry
local oldChat,oldNow,oldUnit,oldRealm,oldClass,oldLevel,oldBuild=C_ChatInfo,F.Now,UnitName,GetNormalizedRealmName,UnitClass,UnitLevel,GetBuildInfo
local oldGet,oldSet=geterrorhandler,seterrorhandler
local oldDB,oldChar,oldPlayer,oldActive,oldMissing,oldSeconds,oldMode=F.db,F.char,F.Route.Player,F.active,F.unresolved,F.routeSeconds,F.routeMode
local oldCollectors=T.collectors
local stamp,name,restricted=1800000000,'Tester One',false
local sent,errors={},{}
local original=function(msg)errors[#errors+1]=msg end
local handler=original
geterrorhandler=function()return handler end;seterrorhandler=function(fn)handler=fn end
UnitName=function()return name end;GetNormalizedRealmName=function()return 'TestRealm'end
UnitClass=function()return 'Mage','MAGE',8 end;UnitLevel=function()return 60 end
GetBuildInfo=function()return '1.60.1','70124' end
F.Now=function()return stamp end
T.collectors={{name='Collector One',realm='Test Realm',faction='Horde'}}
C_ChatInfo={RegisterAddonMessagePrefix=function()return 0 end,
 AreOutgoingAddonChatMessagesRestricted=function()return restricted end,
 SendAddonMessage=function(p,msg,channel,target)
   assert(p=='WFDiag1' and channel=='WHISPER' and #msg<=254)
   sent[#sent+1]={msg=msg,target=target};return 0
 end}
F.db={settings={telemetry=false}};F.char={flights={nodes={[1]={}},edges={[1]={}}}}
F.Route.Player=function()return {mapID=1411,x=.46,y=.13}end
F.active={};for i=1,12 do F.active[i]={questID=90000+i}end
F.unresolved={F.active[12]};F.routeSeconds=1400;F.routeMode='estimated'
local client=F.db
local function tick(seconds)stamp=stamp+(seconds or 1);T.frame.scripts.OnUpdate(nil,1)end
local function receive(msg,sender,channel)
  T.frame.scripts.OnEvent(nil,'CHAT_MSG_ADDON','WFDiag1',msg,channel or 'WHISPER',sender)
end
T.Initialize();T.Record('R','unresolved');tick()
assert(#sent==0 and not F.db.telemetryOutbox and handler==original,'Default must neither collect nor send')
T.SetEnabled(true)
assert(#F.db.telemetryOutbox==1 and handler~=original)
local body=F.db.telemetryOutbox[1].body
local parsed=assert(T.Parse(body));assert(parsed[6]=='8' and parsed[12]=='12' and parsed[13]=='1')
assert(not body:find(name,1,true) and not body:find('Test Realm',1,true))
T.CaptureRoute();assert(#F.db.telemetryOutbox==1,'Duplicate route report')
handler('Interface/AddOns/OtherAddon/Core.lua:2: other error')
handler('Interface/AddOns/WaylaidForever/Routing.lua:321: PRIVATE SECRET DATA')
assert(#errors==2 and #F.db.telemetryOutbox==2,'Forward all errors, collect ours only')
assert(not F.db.telemetryOutbox[2].body:find('PRIVATE',1,true),'Never record raw error data')
T.frame.scripts.OnEvent(nil,'ADDON_ACTION_BLOCKED','WaylaidForever','ProtectedCall')
assert(#F.db.telemetryOutbox==3)
T.Record('S','stopped');assert(#F.db.telemetryOutbox==4)
tick();local hello=sent[#sent].msg;local token=assert(hello:match('^H|(%d+)$'))
assert(sent[#sent].target=='Collector One-TestRealm')
receive('R|'..token,'Imposter-TestRealm');tick(3)
assert(sent[#sent].msg==hello,'Untrusted receiver must not request reports')
receive('R|'..token,'Collector One-TestRealm','GUILD');tick(3)
assert(sent[#sent].msg==hello,'Wrong channel accepted')
receive('R|99999999','Collector One-TestRealm');tick(3)
assert(sent[#sent].msg==hello,'Wrong nonce accepted')

-- Receiver handshakes and ACKs without keeping the sender's character name.
local collector={settings={telemetry=false}}
F.db=collector;name='Collector One';T.Initialize()
receive(hello,'Tester One-TestRealm');assert(sent[#sent].msg=='R|'..token..'|'..F.version)
local ready=sent[#sent].msg
F.db=client;name='Tester One';receive(ready,'Collector One-TestRealm');tick(3)
local packet=sent[#sent].msg;assert(packet:match('^D|'))
local before=#client.telemetryOutbox
receive('A|'..token..'|wrong-id','Collector One-TestRealm');assert(#client.telemetryOutbox==before)
F.db=collector;name='Collector One'
receive(packet,'Tester One-TestRealm');assert(#collector.telemetryInbox==1)
local ack=sent[#sent].msg;assert(ack:match('^A|'))
for key in pairs(collector.telemetryInbox[1])do assert(key=='id' or key=='time' or key=='body')end
receive(packet,'Tester One-TestRealm');assert(#collector.telemetryInbox==1,'Retry duplicated inbox entry')
receive(packet..'|execute-code','Tester One-TestRealm');assert(#collector.telemetryInbox==1)
receive(packet,'Unknown-TestRealm');assert(#collector.telemetryInbox==1,'No handshake')
F.db=client;name='Tester One';receive(ack,'Collector One-TestRealm')
assert(#client.telemetryOutbox==before-1,'ACK did not remove report')

restricted=true;local messages=#sent;tick(3);assert(#sent==messages,'Must respect realm messaging restrictions')
restricted=false
T.SetEnabled(false);assert(not client.telemetryOutbox and handler==original)
receive(ready,'Collector One-TestRealm');tick(600);assert(#sent==messages,'Opt-out must stop sending immediately')
T.SetEnabled(true)
local savedHandler=handler
for i=1,80 do T.Record('E','Core.lua:'..i)end
assert(#client.telemetryOutbox<=40,'Unbounded local queue')
-- A later error handler may wrap ours. Do not remove somebody else's hook.
local external=function(msg)return savedHandler(msg)end
handler=external;T.SetEnabled(false);assert(handler==external)
T.SetEnabled(true);local errorCount=#errors;handler('ordinary error');assert(#errors==errorCount+1,'Error chain recurses or swallows errors')
T.SetEnabled(false)
client.telemetryOutbox={{id='1',time=stamp-604801,body=body}}
client.settings.telemetry=true;T.Initialize();assert(#client.telemetryOutbox==0,'Expired report survived login')
T.SetEnabled(false)
name='Other Alt';F.db=collector;T.Initialize();assert(#collector.telemetryInbox==1,'Developer inbox erased on alt login')
stamp=stamp+1209601;T.Initialize();assert(#collector.telemetryInbox==0,'Expired received report survived')
assert(not T.Parse(body..'|extra') and not T.Parse(body:gsub('|H|','|X|')) and not T.Parse(string.rep('x',221)))
T.collectors={};F.db=client;T.SetEnabled(true);T.Record('R','unresolved');assert(not client.telemetryOutbox or #client.telemetryOutbox==0,'No receiver must mean no new collection')
T.SetEnabled(false)
T.collectors=oldCollectors
C_ChatInfo,F.Now,UnitName,GetNormalizedRealmName,UnitClass,UnitLevel,GetBuildInfo=oldChat,oldNow,oldUnit,oldRealm,oldClass,oldLevel,oldBuild
geterrorhandler,seterrorhandler=oldGet,oldSet
F.db,F.char,F.Route.Player,F.active,F.unresolved,F.routeSeconds,F.routeMode=oldDB,oldChar,oldPlayer,oldActive,oldMissing,oldSeconds,oldMode
print('PASS: opt-in telemetry, silent handshake/ACK delivery, impersonation/malformed rejection, deduplication, bounded retention, error-handler chaining, restrictions and opt-out')
