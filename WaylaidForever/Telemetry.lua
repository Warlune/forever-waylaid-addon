local _,F=...
local T={};F.Telemetry=T
-- Explicit developer destinations, never discovered from another player's packet.
-- Beta destination confirmed by the developer; review before launch.
T.collectors={{name="War Lune",realm="Classic Beta PvP 2",faction="Horde"}}
local prefix="WFDiag1"
local frame=CreateFrame("Frame");T.frame=frame
local registered,previousHandler,errorHandler
local nextHello,nextSend,untilReady,nonce=0,0,0,nil
local sessions,limits,dedup={},{},{}
local sequence=0
local function now()return F.Now()end
local function enabled()return F.db and F.db.settings.telemetry==true end
local function cleanRealm(s)return type(s)=="string" and s:gsub("[%s%-]",""):lower() or ""end
local function realm()return cleanRealm(GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName())end
local function ownName()return UnitName and UnitName("player") or ""end
local function matchName(sender,entry)
  if type(sender)~="string" or #sender>150 then return false end
  sender=sender:lower()
  return sender==entry.name:lower() or sender==(entry.name.."-"..entry.realm):lower()
    or sender==(entry.name.."-"..entry.realm:gsub("%s", "")):lower()
end
function T.Destination()
  for _,entry in ipairs(T.collectors)do
    if cleanRealm(entry.realm)==realm() and entry.faction==UnitFactionGroup("player") then return entry end
  end
end
function T.IsCollector()
  local entry=T.Destination()
  return entry and ownName():lower()==entry.name:lower()
end
local function number(n,max)
  n=tonumber(n);return n and n==n and n>=0 and n<=max and n==math.floor(n)
end
local kinds={R=true,E=true,B=true,S=true}
-- Numeric, bounded diagnostic schema. No chat, item links, raw error strings,
-- player/account names, guild rosters or arbitrary table serialization.
function T.Parse(body)
  if type(body)~="string" or #body>220 or body:find("[^%w|:.,_-]") then return end
  local fields={};for s in (body.."|"):gmatch("([^|]*)|")do fields[#fields+1]=s end
  if #fields~=20 or fields[1]~="1" or not fields[2]:match("^%d+%.%d+%.%d+$") then return end
  local bounds={[3]=99999999,[4]=9999999999,[6]=99,[7]=999,[9]=99999,[10]=10000,[11]=10000,
    [12]=100,[13]=100,[14]=10000,[15]=10000,[16]=9999999,[17]=1}
  for i,max in pairs(bounds)do if not number(fields[i],max)then return end end
  if not ({A=true,H=true,U=true})[fields[5]] or not kinds[fields[8]] then return end
  if #fields[18]>40 or not fields[18]:match("^[%w_.:-]+$") or #fields[19]>100 then return end
  local quests=0
  if fields[19]~="" then
    if not fields[19]:match("^%d[%d,]*%d$") and not fields[19]:match("^%d+$") then return end
    if fields[19]:find(",,",1,true)then return end
    for id in fields[19]:gmatch("%d+")do quests=quests+1;if not number(id,9999999)then return end end
  end
  if quests>12 or not number(fields[20],999999)then return end
  return fields
end
local function trim(rows,limit,age)
  local kept={}
  for _,row in ipairs(type(rows)=="table" and rows or {})do
    if type(row)=="table" and type(row.time)=="number" and row.time>=now()-age and row.time<=now()+60
      and type(row.id)=="string" and #row.id<=32 and row.id:match("^[%d-]+$") and T.Parse(row.body) then kept[#kept+1]=row end
  end
  while #kept>limit do table.remove(kept,1)end
  return kept
end
local function count(rows)local n=0;for _ in pairs(rows or {})do n=n+1 end;return n end
local function integer(n,max)return math.floor(math.max(0,math.min(tonumber(n) or 0,max)))end
function T.Record(kind,code)
  if not enabled() or not T.Destination() or not kinds[kind] then return end
  code=type(code)=="string" and code or "unknown"
  if not code:match("^[%w_.:-]+$") or #code>40 then return end
  local stamp=now()
  local key=kind..":"..code
  if dedup[key] and stamp-dedup[key]<600 then return end
  if count(dedup)>=50 then return end
  dedup[key]=stamp
  local p=F.Route and F.Route.Player()
  local class
  if UnitClass then local _,_,id=UnitClass("player");class=id end
  local build=GetBuildInfo and select(2,GetBuildInfo()) or 0
  local ids={};for _,s in ipairs(F.active or {})do if #ids<12 and number(s.questID,9999999)then ids[#ids+1]=s.questID end end
  table.sort(ids)
  local flights=F.char and F.char.flights or {}
  sequence=sequence+1
  local data={"1",F.version,integer(build,99999999),stamp,({Alliance="A",Horde="H"})[UnitFactionGroup("player")] or "U",
    integer(class,99),integer(UnitLevel and UnitLevel("player"),999),kind,integer(p and p.mapID,99999),
    integer(p and p.x and p.x*10000,10000),integer(p and p.y and p.y*10000,10000),integer(#(F.active or {}),100),
    integer(#(F.unresolved or {}),100),integer(count(flights.nodes),10000),integer(count(flights.edges),10000),
    integer(F.routeSeconds,9999999),F.routeMode=="estimated" and 1 or 0,code,table.concat(ids,","),integer(sequence,999999)}
  local body=table.concat(data,"|");if not T.Parse(body)then return end
  F.db.telemetryOutbox=trim(F.db.telemetryOutbox,39,604800)
  F.db.telemetryOutbox[#F.db.telemetryOutbox+1]={id=stamp.."-"..math.random(100000,999999),time=stamp,body=body}
end
function T.CaptureRoute()
  if not enabled() or #(F.active or {})==0 then return end
  T.Record("R",#(F.unresolved or {})>0 and "unresolved" or F.routeMode=="estimated" and "estimated" or "planned")
end
local function send(text,target)
  if not registered or #text>254 then return false end
  if C_ChatInfo.AreOutgoingAddonChatMessagesRestricted and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted()then return false end
  local ok,result=pcall(C_ChatInfo.SendAddonMessage,prefix,text,"WHISPER",target)
  return ok and (result==true or result==0)
end
local function installHandler()
  if errorHandler or not geterrorhandler or not seterrorhandler then return end
  previousHandler=geterrorhandler()
  if type(previousHandler)~="function"then return end
  local forward=previousHandler
  errorHandler=function(message)
    pcall(function()
    if enabled() and type(message)=="string"then
      local file,line=message:match("WaylaidForever[/\\]([%w_]+%.lua):(%d+)")
      if file then T.Record("E",file..":"..line)end
    end
    end)
    return forward(message)
  end
  seterrorhandler(errorHandler)
end
function T.Initialize()
  if not F.db then return end
  F.db.telemetryOutbox=enabled() and trim(F.db.telemetryOutbox,40,604800) or nil
  -- Account-wide inbox survives logging into the developer's other characters.
  if T.IsCollector() or F.db.telemetryInbox then F.db.telemetryInbox=trim(F.db.telemetryInbox,300,1209600)end
  if (enabled() or T.IsCollector()) and C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix and not registered then
    local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,prefix);registered=ok and (result==true or result==0)
  end
  if enabled()then installHandler()end
end
function T.SetEnabled(value)
  F.db.settings.telemetry=value==true
  nonce=nil;untilReady=0;nextHello=0;dedup={}
  if not enabled()then
    F.db.telemetryOutbox=nil
    if errorHandler and geterrorhandler and geterrorhandler()==errorHandler then seterrorhandler(previousHandler);errorHandler=nil end
  end
  T.Initialize();T.CaptureRoute()
end
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("ADDON_ACTION_BLOCKED");frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
frame:SetScript("OnEvent",function(_,event,p,message,channel,sender)
  if event~="CHAT_MSG_ADDON"then
    if p=="WaylaidForever" then T.Record("B",event=="ADDON_ACTION_BLOCKED" and "blocked" or "forbidden")end
    return
  end
  if not registered or p~=prefix or channel~="WHISPER" or type(message)~="string" or #message>254
    or type(sender)~="string" or #sender>150 or sender:find("[|%c]")then return end
  local op,token,rest=message:match("^([HRDA])|([%d-]+)|?(.*)$")
  if not op or #token>32 then return end
  local stamp=now()
  if T.IsCollector() then
    if op=="H" and rest==""then
      if limits[sender] and stamp-limits[sender]<60 then return end
      if not sessions[sender] and count(sessions)>=50 then return end
      limits[sender]=stamp;sessions[sender]={token=token,untilTime=stamp+120,received=0}
      send("R|"..token.."|"..(F.isDevelopment and "" or F.version),sender)
    elseif op=="D"then
      local session=sessions[sender]
      if not session or token~=session.token or stamp>session.untilTime or session.received>=40 then return end
      local id,body=rest:match("^([%d-]+)|(.+)$")
      if not id or #id>32 or not T.Parse(body)then return end
      session.received=session.received+1
      local inbox=trim(F.db.telemetryInbox,300,1209600)
      local found=false;for _,row in ipairs(inbox)do if row.id==id then found=true end end
      if not found then
        if #inbox>=300 then table.remove(inbox,1)end
        inbox[#inbox+1]={id=id,body=body,time=stamp}
      end
      F.db.telemetryInbox=inbox
      send("A|"..token.."|"..id,sender)
    end
  elseif enabled()then
    local target=T.Destination()
    if not target or not matchName(sender,target) or token~=nonce then return end
    if op=="R" and (rest=="" or rest:match("^%d+%.%d+%.%d+$"))then
      untilReady=stamp+120
      if F.VersionCheck then F.VersionCheck.Observe(rest)end
    elseif op=="A" and stamp<=untilReady then
      local rows=F.db.telemetryOutbox or {}
      if rows[1] and rows[1].id==rest then table.remove(rows,1)end
    end
  end
end)
local tick=0
frame:SetScript("OnUpdate",function(_,dt)
  tick=tick+dt;if tick<1 then return end;tick=0
  local stamp=now()
  for sender,session in pairs(sessions)do if stamp>session.untilTime then sessions[sender]=nil;limits[sender]=nil end end
  for key,time in pairs(dedup)do if stamp-time>=600 then dedup[key]=nil end end
  if not enabled() or T.IsCollector()then return end
  local target=T.Destination();if not target then return end
  if not F.db.telemetryOutbox or #F.db.telemetryOutbox==0 then return end
  if stamp>=nextHello and stamp>untilReady then
    F.db.telemetryOutbox=trim(F.db.telemetryOutbox,40,604800)
    nonce=tostring(math.random(100000,999999));nextHello=stamp+600
    send("H|"..nonce,target.name.."-"..target.realm:gsub("%s", ""))
  elseif nonce and stamp<=untilReady and stamp>=nextSend then
    nextSend=stamp+3
    local row=F.db.telemetryOutbox[1]
    send("D|"..nonce.."|"..row.id.."|"..row.body,target.name.."-"..target.realm:gsub("%s", ""))
  end
end)

function F.ShowTelemetry()
  if not T.panel then
    local S=F.Style
    local panel=S.Panel(UIParent,0,0,620,350);T.panel=panel;panel:ClearAllPoints();panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG");panel:SetFrameLevel(150);panel:SetClampedToScreen(true)
    S.Text(panel,"Optional diagnostics",22,-20,455,"GameFontNormalLarge",S.gold)
    S.Button(panel,"Close",500,-14,95,function()panel:Hide()end)
    local check=S.Check(panel,"Automatically share diagnostics",22,-60,"telemetry");T.check=check
    check:SetScript("OnClick",function(self)T.SetEnabled(not not self:GetChecked());F.ShowTelemetry()end)
    S.Text(panel,"Help find bugs without writing a report each time. Small reports wait locally and use addon messages to reach the developer.",24,-100,565,"GameFontHighlight")
    S.Text(panel,"Shares version, faction/class/level, map position, up to 12 writ IDs, route/flight counts, scan outcomes and error file/line. No chat or raw error text. Your character name is visible in transit, but not saved in reports.",24,-154,565,"GameFontHighlight")
    S.Text(panel,"Off by default. Disable to clear unsent reports. Queue: 40 / 7 days. Inbox: 300 / 14 days. Delivery is not guaranteed.",24,-244,565,"GameFontHighlightSmall",S.muted)
    T.status=S.Text(panel,"",24,-300,565,"GameFontHighlightSmall",S.gold)
    panel:SetHeight(425)
    local edit=CreateFrame("EditBox",nil,panel,"InputBoxTemplate");T.feedbackURL=edit
    edit:SetPoint("TOPLEFT",28,-370);edit:SetSize(565,24);edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
    edit:SetText("https://github.com/Warlune/forever-waylaid-addon/issues/new/choose")
    S.Text(panel,"GitHub bug reports — click the address, Ctrl+A, Ctrl+C:",24,-340,565,"GameFontHighlightSmall",S.muted)
  end
  T.check:SetChecked(enabled())
  T.status:SetText(T.IsCollector() and ("Developer inbox: "..#(F.db.telemetryInbox or {}).." reports.") or
    not enabled() and "Diagnostics off." or not T.Destination() and "Paused: no receiver for this faction/realm. No reports collected." or
    ("Enabled — "..#(F.db.telemetryOutbox or {}).." reports waiting. Nothing is posted to public chat."))
  T.panel:SetScale(F.AccessibleScale(F.db.settings.ledgerScale,620,425));T.panel:Show()
end
