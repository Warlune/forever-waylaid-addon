local _,F=...
local prefix="FWLPrice1"
local frame=CreateFrame("Frame");F.peerFrame=frame
local queue,answered,limits,seen={},{},{},{}
local registered=false
local nextRequest,sendElapsed,uiElapsed=0,0,0
local requestToken,requestUntil
local dirty=false
local ttl=86400

local function enabled()return F.db and F.db.settings.peerSharing end
local function realmKey()
  local realm=GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
  return realm:gsub("[%s%-]",""):lower()
end
local function envelope(kind,body)
  return "1|"..realmKey().."|"..UnitFactionGroup("player").."|"..kind.."|"..body
end
local function validSender(sender)
  if type(sender)~="string" or #sender==0 or #sender>100 or sender:find("[|%c]")then return false end
  local name,realm=sender:match("^([^-]+)%-(.+)$")
  if realm and realm:gsub("[%s%-]",""):lower()~=realmKey()then return false end
  name=name or sender
  local own=UnitName and UnitName("player")
  return name~=own
end
local function integer(value,min,max)
  return type(value)=="number" and value==math.floor(value) and value>=min and value<=max
end
local function eligible(row)
  return row and integer(row.price,1,100000000000) and integer(row.time,F.Now()-ttl,F.Now()+60)
    and (row.quantity==nil or integer(row.quantity,1,100000000))
end
local function add(message,channel,target)
  if #message<=254 and #queue<240 then queue[#queue+1]={message=message,channel=channel,target=target,tries=0}end
end
function F.UpdatePeerUI()
  if not F.peerStatus then return end
  if not enabled()then F.peerStatus:SetText("Peer sharing is off. No prices sent or received.");return end
  if not registered then F.peerStatus:SetText("Peer messaging is unavailable in this client.");return end
  local count=0
  for _,time in pairs(seen)do if F.Now()-time<600 then count=count+1 end end
  F.peerStatus:SetText("Sharing with guild / group • "..count.." peer(s) seen recently.")
end
function F.InitializePeers()
  if not registered and C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix and C_ChatInfo.SendAddonMessage then
    local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,prefix)
    registered=ok and (result==true or result==0 or (Enum and Enum.RegisterAddonMessagePrefixResult and result==Enum.RegisterAddonMessagePrefixResult.Success))
  end
  -- Stored peer prices never survive indefinitely, even while sharing is off.
  for _,rows in pairs(F.char.peerPrices)do
    for id,row in pairs(rows)do if not F.catalogIDs[id] or not eligible(row)then rows[id]=nil end end
  end
  nextRequest=F.Now()+5+math.random(0,10)
  F.UpdatePeerUI()
end
function F.SetPeerSharing(value)
  F.db.settings.peerSharing=not not value
  queue={};answered={};limits={};seen={};requestToken=nil;requestUntil=nil
  if value then F.InitializePeers()end
  F.UpdatePeerUI();F.Refresh()
end
local function request()
  requestToken=string.format("%d-%d",F.Now(),math.random(1,999999))
  requestUntil=F.Now()+180
  local message=envelope("Q",requestToken)
  if IsInGuild and IsInGuild()then add(message,"GUILD")end
  if IsInRaid and IsInRaid()then add(message,"RAID")
  elseif IsInGroup and IsInGroup()then add(message,"PARTY")end
  nextRequest=F.Now()+300+math.random(0,30)
end
local function respond(sender,token)
  if not token:match("^%d+%-%d+$") or #token>32 then return end
  if answered[sender] and F.Now()-answered[sender]<300 then return end
  local peers=0;for _ in pairs(answered)do peers=peers+1 end
  if peers>=50 then return end
  answered[sender]=F.Now()
  local scope=F.char.realm..":"..UnitFactionGroup("player")
  local ids={}
  for id,row in pairs(F.char.localPrices[scope] or {})do
    if F.catalogIDs[id] and eligible(row)then ids[#ids+1]=id end
  end
  table.sort(ids)
  local header=envelope("D",token.."|")
  local message=header
  for _,id in ipairs(ids)do
    local row=F.char.localPrices[scope][id]
    local record=string.format("%d,%d,%d,%d;",id,row.price,row.quantity or 0,row.time)
    if #message+#record>240 then add(message,"WHISPER",sender);message=header end
    message=message..record
  end
  if #message>#header then add(message,"WHISPER",sender)end
end
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:SetScript("OnEvent",function(_,event,p,message,channel,sender)
  if not enabled() or not registered then return end
  if event~="CHAT_MSG_ADDON"then nextRequest=math.min(nextRequest,F.Now()+60);return end
  if p~=prefix or type(message)~="string" or #message>254 or not validSender(sender)then return end
  local version,realm,faction,kind,body=message:match("^(%d+)|([^|]+)|([^|]+)|([QD])|(.+)$")
  if version~="1" or realm~=realmKey() or faction~=UnitFactionGroup("player")then return end
  if kind=="Q" then
    if channel~="GUILD" and channel~="PARTY" and channel~="RAID"then return end
    respond(sender,body);return
  end
  if channel~="WHISPER" or not requestToken or F.Now()>requestUntil then return end
  local token,records=body:match("^([^|]+)|(.+)$")
  if token~=requestToken or not records or records:sub(-1)~=";" or records:sub(1,1)==";" or records:find(";;",1,true) then return end
  local limit=limits[sender]
  if not limit then
    local count=0;for _ in pairs(limits)do count=count+1 end
    if count>=50 then return end
    limit={time=F.Now(),count=0};limits[sender]=limit
  end
  if F.Now()-limit.time>=60 then limit.time=F.Now();limit.count=0 end
  limit.count=limit.count+1;if limit.count>120 then return end
  local parsed={};local count=0
  for record in records:gmatch("([^;]+);")do
    local id,price,qty,time=record:match("^(%d+),(%d+),(%d+),(%d+)$")
    id,price,qty,time=tonumber(id),tonumber(price),tonumber(qty),tonumber(time)
    if not id or not F.catalogIDs[id] or not integer(price,1,100000000000) or not integer(qty,0,100000000)
      or not integer(time,F.Now()-ttl,F.Now()+60)then return end
    count=count+1;if count>10 then return end
    parsed[id]={price=price,quantity=qty>0 and qty or nil,time=time,source="Peer scan (unverified)",peer=sender}
  end
  if count==0 then return end
  local scope=F.char.realm..":"..faction
  local target=F.char.peerPrices[scope] or {};F.char.peerPrices[scope]=target
  for id,row in pairs(parsed)do target[id]=F.SelectPrice(target[id],row)end
  seen[sender]=F.Now();dirty=true
end)
frame:SetScript("OnUpdate",function(_,dt)
  if not enabled() or not registered then return end
  if F.Now()>=nextRequest then
    for sender,time in pairs(answered)do if F.Now()-time>=300 then answered[sender]=nil end end
    for sender,time in pairs(seen)do if F.Now()-time>=600 then seen[sender]=nil end end
    limits={};request()
  end
  sendElapsed=sendElapsed+dt;uiElapsed=uiElapsed+dt
  if sendElapsed>=0.5 and #queue>0 then
    sendElapsed=0
    local row=queue[1]
    local ok,result=pcall(C_ChatInfo.SendAddonMessage,prefix,row.message,row.channel,row.target)
    row.tries=row.tries+1
    if (ok and (result==0 or result==true)) or row.tries>=3 then table.remove(queue,1)end
  end
  if uiElapsed>=2 then
    uiElapsed=0;F.UpdatePeerUI()
    if dirty then dirty=false;F.Refresh()end
  end
end)
