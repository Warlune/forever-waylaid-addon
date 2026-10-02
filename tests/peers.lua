local F=...
local oldChat,oldNow,oldUnit,oldRealm=C_ChatInfo,F.Now,UnitName,GetNormalizedRealmName
local oldGuild,oldGroup,oldRaid=IsInGuild,IsInGroup,IsInRaid
local oldLocal,oldPeers,oldRefresh=F.char.localPrices,F.char.peerPrices,F.Refresh
local now=200000
local sent={}
C_ChatInfo={RegisterAddonMessagePrefix=function()return 0 end,SendAddonMessage=function(p,msg,channel,target)sent[#sent+1]={p=p,msg=msg,channel=channel,target=target};return 0 end}
F.Now=function()return now end;UnitName=function()return 'Self' end;GetNormalizedRealmName=function()return 'TestRealm' end
IsInGuild=function()return true end;IsInGroup=function()return false end;IsInRaid=function()return false end
F.Refresh=function()end
local scope=GetRealmName()..':Horde'
F.char.localPrices={[scope]={[2840]={price=15,quantity=30,time=now-10,source='Waylaid Forever'}}};F.char.peerPrices={}
F.char.localPrices[scope][999999]={price=25,quantity=3,time=now-10,source='Waylaid Forever'}
local function tick()F.peerFrame.scripts.OnUpdate(nil,1)end
local function receive(msg,channel,sender)F.peerFrame.scripts.OnEvent(nil,'CHAT_MSG_ADDON','FWLPrice1',msg,channel or 'WHISPER',sender or 'Other-TestRealm')end
F.SetPeerSharing(false);now=now+60;tick();assert(#sent==0,'Default/disabled sharing sends nothing')
F.SetPeerSharing(true);now=now+20;tick()
assert(#sent==1 and sent[1].channel=='GUILD')
local token=sent[1].msg:match('|Q|(.+)$');assert(token)
local function packet(rows,nonce,realm,faction)return '1|'..(realm or 'testrealm')..'|'..(faction or 'Horde')..'|D|'..(nonce or token)..'|'..rows end
local row='2840,12,20,'..now..';'
receive(packet(row,'wrong'));receive(packet(row,nil,'otherrealm'));receive(packet(row,nil,nil,'Alliance'))
receive(packet(row),nil,'Other-AnotherRealm');assert(not F.char.peerPrices[scope],'Wrong scope or unsolicited data rejected')
receive(packet('2840,0,20,'..now..';'));receive(packet('2840,12,20,'..(now+120)..';'));receive(packet('2840,12,20,'..(now-86401)..';'))
receive(packet('99999999,12,20,'..now..';'));receive(packet('2840,12,20,'..now..';loadstring(evil);'))
assert(not F.char.peerPrices[scope],'Malformed, stale, future and unrelated prices rejected atomically')
receive(packet(';'..row))
receive(packet(row..';'))
assert(not F.char.peerPrices[scope],'Empty price records must be rejected')
receive(packet(row));assert(F.Price(2840).price==12 and F.Price(2840).time==now)
assert(F.Price(2840).source=='Peer scan (unverified)')
receive(packet('2840,1,20,'..(now-20)..';'));assert(F.Price(2840).price==12,'Older peers cannot displace newer data')
F.char.localPrices[scope][2840].time=now;assert(F.Price(2840).price==15,'Personal data wins timestamp ties')
F.char.peerPrices[scope][2589]={price=5,quantity=20,time=now,source='Peer scan (unverified)'}
local before=#sent
receive('1|testrealm|Horde|Q|123-456','GUILD','Requestor-TestRealm');tick()
assert(#sent==before+1 and sent[#sent].channel=='WHISPER' and sent[#sent].target=='Requestor-TestRealm')
assert(sent[#sent].msg:find('2840,15,30,'..now..';',1,true))
assert(not sent[#sent].msg:find('2589',1,true),'Received prices are not relayed as personal observations')
assert(not sent[#sent].msg:find('999999',1,true),'Full-market local prices do not expand the Waylaid peer protocol')
receive('1|testrealm|Horde|Q|123-456','GUILD','Requestor-TestRealm');tick();assert(#sent==before+1,'Repeated requests are rate limited')
F.SetPeerSharing(false);before=#sent;receive(packet('2840,1,20,'..(now+1)..';'));tick()
assert(#sent==before and F.Price(2840).price==15,'Opt-out stops sending, receiving and use of peer prices')
F.SetPeerSharing(true);F.char.localPrices[scope]={};now=now+86401
assert(F.Price(2840)==nil,'Expired peer prices cannot supply quotes')
F.SetPeerSharing(false)
C_ChatInfo,F.Now,UnitName,GetNormalizedRealmName=oldChat,oldNow,oldUnit,oldRealm
IsInGuild,IsInGroup,IsInRaid=oldGuild,oldGroup,oldRaid
F.char.localPrices,F.char.peerPrices,F.Refresh=oldLocal,oldPeers,oldRefresh
print('PASS: opt-in peer protocol, scope, timestamps, malformed payloads, direct-only sharing, throttling and opt-out')
