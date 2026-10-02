local F=...
local V=F.VersionCheck
local oldDB,oldPrint,oldVersion,oldNow,oldChat=F.db,F.Print,F.version,F.Now,C_ChatInfo
local oldGuild,oldGroup,oldRaid=IsInGuild,IsInGroup,IsInRaid
local alerts,sent={},{}
local now,restricted=1000,false
F.db={settings={telemetry=false}};F.version='0.14.8';F.Print=function(s)alerts[#alerts+1]=s end;F.Now=function()return now end
C_ChatInfo={RegisterAddonMessagePrefix=function()return 0 end,
  AreOutgoingAddonChatMessagesRestricted=function()return restricted end,
  SendAddonMessage=function(p,m,c,t)sent[#sent+1]={prefix=p,message=m,channel=c,target=t};return 0 end}
IsInGuild=function()return true end;IsInGroup=function()return true end;IsInRaid=function()return false end
assert(V.Newer('0.14.10','0.14.9') and not V.Newer('0.14.8','0.14.8'))
assert(not V.Newer('evil','0.14.8') and not V.Newer('1000.0.0','0.14.8'))
V.Initialize();now=1040;V.frame.scripts.OnUpdate(nil,1)
assert(#sent==2 and sent[1].message=='Q|0.14.8','Version-only check independent of telemetry opt-in')
local function receive(message,channel)V.frame.scripts.OnEvent(nil,'CHAT_MSG_ADDON','WFVer1',message,channel or 'GUILD','Tester-TestRealm')end
receive('Q|0.14.9');assert(#alerts==1)
receive('Q|0.14.9');receive('V|0.14.9','WHISPER');assert(#alerts==1,'Duplicate update alert')
V.Initialize();receive('Q|0.14.9');assert(#alerts==1,'Notice must survive reinitialization/reload')
receive('Q|0.14.10');assert(#alerts==2,'Notify once for the next newer version')
receive('Q|0.14.8');receive('Q|0.14.7');receive('Q|bad');receive('Q|0.99.1','SAY');assert(#alerts==2)
now=5000;receive('V|0.99.1','WHISPER');assert(#alerts==2,'Ignore unsolicited late whispers')
restricted=true;local n=#sent;V.frame.scripts.OnUpdate(nil,1);assert(#sent==n)
F.db,F.Print,F.version,F.Now,C_ChatInfo=oldDB,oldPrint,oldVersion,oldNow,oldChat
IsInGuild,IsInGroup,IsInRaid=oldGuild,oldGroup,oldRaid
print('PASS: version comparison, one notice per newer version across reloads, version-only group exchange and messaging restrictions')
