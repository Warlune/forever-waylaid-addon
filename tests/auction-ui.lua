local F=...
do
  local oldColor=CreateColor
  CreateColor=function(r,g,b,a)return {r,g,b,a}end
  local ends
  local texture={SetAlpha=function()end,SetColorTexture=function()end,
    SetGradient=function(_,_,left,right)ends={left,right}end}
  F.Style.Accent(texture,0.32)
  F.db.settings.debugAlliance=true;F.Style.Accent(texture)
  assert(ends[1][4]==0.32 and ends[2][4]==0.32,'Both gradient endpoints retain opacity after a faction change')
  F.db.settings.debugAlliance=false;F.Style.Accent(texture)
  assert(ends[1][4]==0.32 and ends[2][4]==0.32,'Returning to Horde retains opacity')
  CreateColor=oldColor
end
local oldAH,oldAPI,oldAddons,oldMode=AuctionHouseFrame,C_AuctionHouse,C_AddOns,AuctionHouseFrameDisplayMode
local oldHook,oldResize,oldSelect,oldDeselect=hooksecurefunc,PanelTemplates_TabResize,PanelTemplates_SelectTab,PanelTemplates_DeselectTab
local oldNow,oldLast,oldRefresh=F.Now,F.char.nativeScanLastAttempt,F.Refresh
local now,calls,enabled=200000,0,0
F.Now=function()return now end;F.char.nativeScanLastAttempt=nil;F.Refresh=function()end
C_AddOns={GetAddOnEnableState=function()return enabled end}
AuctionHouseFrameDisplayMode={Buy={},Auctions={}}
AuctionHouseFrame=CreateFrame('Frame');AuctionHouseFrame.Tabs={CreateFrame('Button'),CreateFrame('Button'),CreateFrame('Button')}
AuctionHouseFrame.SetDisplayMode=function(self,mode)self.displayMode=mode end
hooksecurefunc=function(object,name,fn)
  local original=object[name];object[name]=function(...)original(...);fn(...)end
end
PanelTemplates_TabResize=function()end
PanelTemplates_SelectTab=function(tab)tab.selected=true end
PanelTemplates_DeselectTab=function(tab)tab.selected=false end
C_AuctionHouse={ReplicateItems=function()calls=calls+1 end,GetNumReplicateItems=function()return 251 end,
  GetReplicateItemInfo=function()return nil,nil,2,nil,nil,nil,nil,nil,nil,100,nil,nil,nil,nil,nil,nil,2840 end}
F.InstallAuctionScanUI()
local ui=F.auctionScanUI
assert(ui and ui.tab:IsShown() and not ui.page:IsShown())
F.InstallAuctionScanUI();assert(ui==F.auctionScanUI,'Installing twice must not duplicate tabs')
for _=1,3 do
  ui.tab.scripts.OnClick();assert(ui.page:IsShown() and ui.tab.selected)
  AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
  assert(not ui.page:IsShown() and not ui.tab.selected)
end
assert(calls==0,'Opening and switching Scan tabs never requests a scan')
ui.tab.scripts.OnClick()
local coords,nextCoords,alpha,texture
ui.art.SetTexCoord=function(_,...)coords={...}end
ui.nextArt.SetTexCoord=function(_,...)nextCoords={...}end
ui.nextArt.SetAlpha=function(_,value)alpha=value end
ui.art.SetTexture=function(_,value)texture=value end
local poses={}
for _=1,16 do
  ui.page.scripts.OnUpdate(nil,0.25)
  assert(coords[2]-coords[1]==0.25 and coords[4]-coords[3]==0.25,'Each pose occupies one complete atlas cell')
  poses[coords[1]..':'..coords[3]]=true
end
local count=0;for _ in pairs(poses)do count=count+1 end
assert(count==16 and coords[1]==0 and coords[3]==0,'All 16 authored poses run and wrap to the start')
ui.page.scripts.OnUpdate(nil,0.125)
assert(math.abs(alpha-0.5)<0.00001 and nextCoords[1]==0.25,'Adjacent poses blend smoothly at the midpoint')
ui.page.scripts.OnUpdate(nil,3.625)
assert(coords[1]==0.75 and coords[3]==0.75 and nextCoords[1]==0 and nextCoords[3]==0,'The final pose blends into the first without a hold or reset')
local oldFaction=UnitFactionGroup;UnitFactionGroup=function()return 'Alliance'end
ui.pose();assert(texture:find('AuctionScribeAlliance16'),'Alliance uses its own 16-pose atlas')
UnitFactionGroup=oldFaction
F.db.settings.debugAlliance=true;F.Style.ApplyTheme()
assert(texture:find('Alliance16') and UnitFactionGroup('player')=='Horde','Debug preview switches the scribe immediately without changing faction')
F.db.settings.debugAlliance=false;F.Style.ApplyTheme();assert(texture:find('Horde16'),'Turning the preview off restores the actual faction')
ui.start.scripts.OnClick();assert(calls==1 and F.GetScanProgress().phase=='waiting')
F.scanFrame.scripts.OnEvent(nil,'REPLICATE_ITEM_LIST_UPDATE')
F.scanFrame.scripts.OnUpdate(nil,0.25)
local info=F.GetScanProgress()
assert(info.active and info.processed==250 and info.total==251 and info.matched==1 and info.saved==0)
assert(ui.stats[1].text=='250 / 251' and ui.stats[2].text==1 and ui.stats[3].text==1,'Displayed counts reflect real batches')
F.scanFrame.scripts.OnUpdate(nil,0.25)
info=F.GetScanProgress()
assert(not info.active and info.processed==251 and info.saved==1 and info.elapsed==0.5)
assert(ui.stats[4].text==1 and not info.canStart,'Finished report remains visible during cooldown')
now=now+901;ui.start.scripts.OnClick();ui.cancel.scripts.OnClick()
assert(not F.GetScanProgress().active and F.GetScanProgress().saved==0,'Cancel never reports committed prices')
enabled=2;F.UpdateScanUI()
assert(not ui.tab:IsShown() and not ui.page:IsShown() and AuctionHouseFrame.displayMode==AuctionHouseFrameDisplayMode.Buy)
F.db.settings.autoHideAuction=false;F.ApplySettings()
assert(ui.tab:IsShown(),'Auto-hide switch can restore the native Scan tab')
now=now+901;ui.start.scripts.OnClick();assert(F.nativeScanActive)
F.db.settings.autoHideAuction=true;F.ApplySettings()
assert(not ui.tab:IsShown() and not F.nativeScanActive,'Re-enabling auto-hide cancels an active native scan without committing it')
enabled=0;F.UpdateScanUI();assert(ui.tab:IsShown(),'Disabled installed scanners expose the Scan tab')
F.auctionScanUI=nil
AuctionHouseFrame,C_AuctionHouse,C_AddOns,AuctionHouseFrameDisplayMode=oldAH,oldAPI,oldAddons,oldMode
hooksecurefunc,PanelTemplates_TabResize,PanelTemplates_SelectTab,PanelTemplates_DeselectTab=oldHook,oldResize,oldSelect,oldDeselect
F.Now,F.char.nativeScanLastAttempt,F.Refresh=oldNow,oldLast,oldRefresh
print('PASS: auction Scan tab, manual-only requests, faction animation, live statistics, cooldown and scanner visibility')
