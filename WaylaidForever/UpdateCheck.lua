local _,F=...
local V={};F.VersionCheck=V
local prefix="WFVer1"
local frame=CreateFrame("Frame");V.frame=frame
local registered=false
local nextRequest,replyUntil,nextReply=0,0,0
local pending
local function parts(value)
  if type(value)~="string" or #value>16 then return end
  local a,b,c=value:match("^(%d+)%.(%d+)%.(%d+)$")
  a,b,c=tonumber(a),tonumber(b),tonumber(c)
  if not a or a>99 or b>999 or c>999 then return end
  return a,b,c
end
function V.Newer(a,b)
  local x,y,z=parts(a);local p,q,r=parts(b)
  if not x or not p then return false end
  return x>p or (x==p and (y>q or (y==q and z>r)))
end
function V.Observe(version)
  if not F.db or not V.Newer(version,F.version) then return end
  local seen=F.db.notifiedUpdateVersion
  if seen and not V.Newer(version,seen) then return end
  F.db.notifiedUpdateVersion=version
  F.Print("A newer Waylaid Forever version (v"..version..") was reported by another copy of the addon. Check CurseForge for an update.")
end
local function allowed()
  return registered and C_ChatInfo and C_ChatInfo.SendAddonMessage and
    not (C_ChatInfo.AreOutgoingAddonChatMessagesRestricted and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted())
end
local function send(message,channel,target)
  if allowed()then pcall(C_ChatInfo.SendAddonMessage,prefix,message,channel,target)end
end
function V.Initialize()
  if F.isDevelopment then return end
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,prefix)
    registered=ok and (result==true or result==0)
  end
  nextRequest=F.Now()+15+math.random(0,15)
end
frame:RegisterEvent("CHAT_MSG_ADDON");frame:RegisterEvent("GROUP_ROSTER_UPDATE");frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:SetScript("OnEvent",function(_,event,p,message,channel,sender)
  if not registered then return end
  if event~="CHAT_MSG_ADDON"then nextRequest=math.min(nextRequest,F.Now()+30);return end
  if p~=prefix or type(message)~="string" or #message>20 or type(sender)~="string" or #sender>150 or sender:find("[|%c]")then return end
  local kind,version=message:match("^([QV])|(.+)$")
  if not parts(version) then return end
  local group=channel=="GUILD" or channel=="PARTY" or channel=="RAID" or channel=="INSTANCE_CHAT"
  if not group and not (kind=="V" and channel=="WHISPER" and F.Now()<=replyUntil)then return end
  V.Observe(version)
  if kind=="Q" and group and V.Newer(F.version,version) and F.Now()>=nextReply and not pending then
    pending={sender=sender,at=F.Now()+math.random(1,5)}
  end
end)
local elapsed=0
frame:SetScript("OnUpdate",function(_,dt)
  if not registered or not F.db then return end
  elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
  local now=F.Now()
  if pending and now>=pending.at then
    send("V|"..F.version,"WHISPER",pending.sender);pending=nil;nextReply=now+60
  end
  if now<nextRequest then return end
  nextRequest=now+600;replyUntil=now+120
  if IsInGuild and IsInGuild()then send("Q|"..F.version,"GUILD")end
  if IsInRaid and IsInRaid()then send("Q|"..F.version,"RAID")
  elseif IsInGroup and IsInGroup()then send("Q|"..F.version,"PARTY")end
end)
