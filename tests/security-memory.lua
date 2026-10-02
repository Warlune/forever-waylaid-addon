local F,C=...
assert(F.Roads==nil and F.roadData==nil,'No advanced road tables or caches at login')
local from={instance=1,wx=0,wy=0,mapID=1454}
local to={instance=1,wx=700,wy=0,mapID=1411}
local oldMode=F.db.settings.routeMode
for _,mode in ipairs({'safer','fastest'})do
  F.db.settings.routeMode=mode
  local seconds,path=F.Route.Leg(from,to,{nodes={},edges={}},false)
  assert(seconds==100 and #path==1 and path[1].road=='unknown','Legacy preferences cannot re-enable road bends in Orgrimmar')
end
F.db.settings.routeMode=oldMode
local oldCosts,shown=F.LedgerCrateCosts,F.window:IsShown()
F.LedgerCrateCosts=function()error('Hidden ledger must not recalculate item lists')end
F.window:Hide();F.Render();F.LedgerCrateCosts=oldCosts;F.window:SetShown(shown)
local oldPrint=F.Print;local messages={};F.Print=function(s)messages[#messages+1]=s end
SlashCmdList.WAYLAIDFOREVER('pin '..F.catalog.writs[1].questId..' 1454 .. 50')
assert(messages[#messages]=='Invalid writ, map or coordinates.','Malformed pin coordinates do not crash')
F.ReportMemory();assert(#messages>=3);F.Print=oldPrint
print('PASS: direct writ navigation, unloaded road graph, hidden-ledger work suppression, malformed pin safety and memory diagnostics')

-- Reused map pins must keep one handler while acting on their current delivery.
local oldDisplay,oldTrack=F.DisplayRoute,F.TrackDelivery
local selected,quest=0,101
F.TrackDelivery=function(id)selected=id end
F.DisplayRoute=function()return {},{{point=to,number=1,stop={questID=quest}}}end
local overlay=F.CreateRouteOverlay(UIParent)
local function draw()F.DrawRouteOverlay(overlay,function()return 10,10 end,function()end,function()return true end,false,false,from)end
draw();local pin=overlay.pins[1];local click=pin.scripts.OnClick
click(pin);assert(selected==101)
quest=202;draw();assert(pin.scripts.OnClick==click,'Redrawing must reuse pin handlers')
click(pin);assert(selected==202,'Reused handler must follow the current pin, not a captured old writ')
F.ClearRouteOverlay(overlay);assert(rawget(pin,'routeStop')==nil and rawget(pin,'pinText')==nil)
F.DisplayRoute,F.TrackDelivery=oldDisplay,oldTrack
local P=C.Pets;local sharing=P.state.share
P.state.share=true
local invalid={'','|cffff0000','\n','3,1,1,1,0,0','3,1,1,1,0,0,0,999','3,101,1,1,0,0,0','3,1,6,1,0,0,0',string.rep('9',181)}
for _,message in ipairs(invalid)do
  for _,channel in ipairs({'WHISPER','GUILD','PARTY','RAID','SAY'})do
    assert(pcall(P.Receive,message,channel,'Audit-peer'))
  end
end
assert(P.peers['Audit-peer']==nil,'Invalid pet messages must not create peer records')
P.Receive('3,1,1,1,0,0,0','GUILD','');assert(P.peers['']==nil)
P.state.share=sharing
print('PASS: reusable map handlers follow current writs; invalid pet packets and sender names are rejected')
