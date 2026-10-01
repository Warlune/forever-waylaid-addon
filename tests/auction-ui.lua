local F=...
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
local coords
ui.art.SetTexCoord=function(_,...)coords={...}end
local poses={}
for _=1,8 do
  ui.page.scripts.OnUpdate(nil,0.24)
  assert(coords[3]<0.5 and coords[4]<=0.5,'Horde uses the upper two rows')
  poses[coords[1]..':'..coords[3]]=true
end
local count=0;for _ in pairs(poses)do count=count+1 end
assert(count==8,'All eight distinct writing poses are animated')
local oldFaction=UnitFactionGroup;UnitFactionGroup=function()return 'Alliance'end
ui.page.scripts.OnUpdate(nil,0.24);assert(coords[3]>=0.5 and coords[4]<=1,'Alliance uses the lower two rows')
UnitFactionGroup=oldFaction
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
enabled=0;F.UpdateScanUI();assert(ui.tab:IsShown(),'Disabled installed scanners expose the Scan tab')
F.auctionScanUI=nil
AuctionHouseFrame,C_AuctionHouse,C_AddOns,AuctionHouseFrameDisplayMode=oldAH,oldAPI,oldAddons,oldMode
hooksecurefunc,PanelTemplates_TabResize,PanelTemplates_SelectTab,PanelTemplates_DeselectTab=oldHook,oldResize,oldSelect,oldDeselect
F.Now,F.char.nativeScanLastAttempt,F.Refresh=oldNow,oldLast,oldRefresh
print('PASS: auction Scan tab, manual-only requests, faction animation, live statistics, cooldown and scanner visibility')
