local F=...
local oldAH,oldAuctionator,oldFrame=C_AuctionHouse,Auctionator,AuctionHouseFrame
local oldAuc=AucAdvanced
local oldNow,oldMap,oldRefresh=F.Now,C_Map.GetBestMapForUnit,F.Refresh
local oldPrices,oldLast=F.char.localPrices,F.char.nativeScanLastAttempt
local oldPeers,oldSharing=F.char.peerPrices,F.db.settings.peerSharing
local now,calls,refreshes=100000,0,0
local rows,reads={},{}
F.Now=function()return now end
C_Map.GetBestMapForUnit=function()return 1454 end
F.Refresh=function()refreshes=refreshes+1 end
F.char.localPrices={};F.char.nativeScanLastAttempt=nil;F.db.settings.personal=true
F.char.peerPrices={};F.db.settings.peerSharing=true
Auctionator=nil;AuctionHouseFrame=nil;AucAdvanced=nil
C_AuctionHouse={
  ReplicateItems=function()calls=calls+1 end,
  GetNumReplicateItems=function()return #rows end,
  GetReplicateItemInfo=function(i)
    reads[i]=(reads[i] or 0)+1
    local row=rows[i+1]
    return nil,nil,row.qty,nil,nil,nil,nil,nil,nil,row.buyout,nil,nil,nil,nil,nil,nil,row.id
  end,
}
local function event(name)F.scanFrame.scripts.OnEvent(nil,name)end
local function tick(dt)F.scanFrame.scripts.OnUpdate(nil,dt or 0.02)end
local function response()
  event('REPLICATE_ITEM_LIST_UPDATE')
  for _=1,10 do if F.nativeScanActive then tick()end end
  assert(not F.nativeScanActive)
end
assert(not F.StartNativeScan() and calls==0,'Closed AH cannot initiate requests')
for _=1,5 do event('AUCTION_HOUSE_SHOW');tick();event('AUCTION_HOUSE_CLOSED')end
assert(calls==0,'Repeated AH open/close must never start a scan')
event('AUCTION_HOUSE_SHOW')
C_Map.GetBestMapForUnit=function()return 1434 end
assert(not F.StartNativeScan() and calls==0,'Neutral/unknown markets cannot pollute faction prices')
C_Map.GetBestMapForUnit=function()return 1454 end
rows={{id=2840,qty=10,buyout=105},{id=2840,qty=5,buyout=100},{id=2589,qty=4,buyout=0},{id=999999,qty=5,buyout=200}}
assert(F.StartNativeScan() and calls==1,'Scan works with Auctionator absent')
assert(not F.StartNativeScan() and calls==1,'Cannot submit twice while running')
now=now+5;response()
local scope=GetRealmName()..':Horde'
local prices=F.char.localPrices[scope]
assert(prices[2840].price==11 and prices[2840].quantity==15 and prices[2840].time==100000 and prices[2840].source=='Forever Waylaid')
assert(not prices[2589],'Bid-only auctions do not invent buyout values')
assert(prices[999999].price==40 and prices[999999].quantity==5,'Save buyouts for unrelated items too')
assert(F.GetScanProgress().saved==2,'Saved prices include every item with a valid buyout')
assert(F.GetScanProgress().unique==3 and F.GetScanProgress().matched==1,'All distinct item IDs include unrelated and bid-only items; retained prices are separate')
assert(F.Price(2840).source=='Forever Waylaid')
F.char.peerPrices[scope]={[2840]={time=now+1,price=8,quantity=50,source='Peer scan (unverified)'}}
assert(F.Price(2840).source=='Peer scan (unverified)','Newer eligible peer price wins when sharing is on')
F.db.settings.peerSharing=false;assert(F.Price(2840).source=='Forever Waylaid','Disabled peers must not affect personal prices')
assert(not F.StartNativeScan() and calls==1,'Full snapshot cooldown must persist between attempts')
local saved=prices[2840]
now=now+901;rows={}
for i=1,251 do rows[i]={id=2840,qty=1,buyout=1}end
assert(F.StartNativeScan());event('REPLICATE_ITEM_LIST_UPDATE');tick()
assert(F.nativeScanActive and prices[2840]==saved,'Partial batches never replace saved prices')
F.CancelNativeScan();tick();assert(prices[2840]==saved)
now=now+901;assert(F.StartNativeScan());event('AUCTION_HOUSE_CLOSED')
response();assert(prices[2840]==saved,'Late response after close must be ignored')
now=now+901;event('AUCTION_HOUSE_SHOW');assert(F.StartNativeScan());tick(121)
assert(not F.nativeScanActive and prices[2840]==saved,'Timeout preserves prices')
now=now+901;assert(F.StartNativeScan());C_Map.GetBestMapForUnit=function()return 1456 end;tick()
assert(not F.nativeScanActive and prices[2840]==saved,'A market/location change cancels atomically')
C_Map.GetBestMapForUnit=function()return 1454 end
now=now+901;rows={{id=2840,qty=1,buyout=1},{id=2840,qty=0,buyout=1}}
assert(F.StartNativeScan());response();assert(prices[2840]==saved,'Incomplete item totals must not replace valid observations')
now=now+901;rows={};assert(F.StartNativeScan());response()
assert(prices[2840]==saved and prices[2840].time==100000,'Empty snapshot does not redate missing prices')
now=now+901;rows={{qty=5,buyout=500},{id=2840,qty=2,buyout=100}}
local beforeRetry=calls
assert(F.StartNativeScan());event('REPLICATE_ITEM_LIST_UPDATE');tick()
assert(F.GetScanProgress().phase=='validating' and prices[2840]==saved,'Unidentified rows prevent a partial commit')
rows[1].id=2840;tick(1.1)
assert(not F.nativeScanActive and prices[2840].quantity==7 and prices[2840].price==50,'Late row is counted once, including all stock')
assert(calls==beforeRetry+1,'Retry reads the existing snapshot without another server request')
saved=prices[2840]
now=now+901;rows={{qty=5,buyout=500}}
assert(F.StartNativeScan());event('REPLICATE_ITEM_LIST_UPDATE');tick()
for _=1,3 do tick(1.1)end
assert(not F.nativeScanActive and F.GetScanProgress().saved==0 and prices[2840]==saved,'Permanently unidentified rows fail visibly and preserve saved prices')
now=now+901;rows={};reads={}
for i=1,751 do rows[i]={id=900000+i,qty=1,buyout=100}end
rows[251]={id=2840,qty=4,buyout=120};rows[501]={id=2840,qty=3,buyout=60}
assert(F.StartNativeScan());response()
for i=0,750 do assert(reads[i]==1,'Every snapshot row is read exactly once across batch boundaries')end
assert(F.GetScanProgress().processed==751 and F.GetScanProgress().unique==750 and F.GetScanProgress().matched==1)
assert(F.GetScanProgress().saved==750 and prices[900751].price==100,'All-market prices survive the final batch')
assert(prices[2840].price==20 and prices[2840].quantity==7,'Relevant rows across separate batches contribute to the same quote')
local unrelated=prices[900751]
now=now+901;rows={{id=900751,qty=2,buyout=40},{id=900751,qty=0,buyout=10}}
assert(F.StartNativeScan());response()
assert(prices[900751]==unrelated,'Invalid unrelated rows preserve the previous quote too')
now=now+901;C_AuctionHouse.ReplicateItems=function()error('unavailable')end
assert(not F.StartNativeScan() and not F.nativeScanActive,'Rejected API call releases active state')
C_AuctionHouse=nil;assert(not F.StartNativeScan(),'Unsupported client degrades safely')
event('AUCTION_HOUSE_CLOSED')
local oldAddons=C_AddOns
local oldUnitName,oldGUID=UnitName,UnitGUID;UnitName=function()return 'Display Name' end
UnitGUID=function()return 'Player-Test-123' end
local states={Auctionator=0,['Auc-Advanced']=0}
C_AddOns={GetAddOnEnableState=function(name,character)assert(character=='Player-Test-123');return states[name]end}
Auctionator={};AucAdvanced={}
F.UpdateScanUI();assert(F.scanFooter.shown and not F.cancelScanButton.shown and not F.scanFooter.progress.shown,'Disabled installations expose idle controls without cancel or progress away from the AH')
states.Auctionator=1
F.UpdateScanUI();assert(not F.scanFooter.shown,'Auctionator enabled for this character hides native controls')
states.Auctionator=0;states['Auc-Advanced']=2
F.UpdateScanUI();assert(not F.scanFooter.shown,'Enabled Auctioneer hides native controls')
states['Auc-Advanced']=0;Auctionator=nil;AucAdvanced=nil
F.UpdateScanUI();assert(F.scanFooter.shown,'Both disabled exposes native controls')
-- TSM hides the AH tab, but cannot supply prices through a supported import.
states.TradeSkillMaster=2
C_AuctionHouse={ReplicateItems=function()calls=calls+1 end,GetNumReplicateItems=function()return 0 end,GetReplicateItemInfo=function()end}
now=now+901
F.UpdateScanUI()
assert(F.ShouldHideAuctionExtras() and not F.ShouldHideNativeScan())
assert(F.scanFooter.shown and not F.GetScanProgress().canStart)
local beforeOpen=calls
event('AUCTION_HOUSE_SHOW')
assert(F.GetScanProgress().canStart and F.scanFooter.progress.shown and F.scanFooter.scribe.art.shown)
assert(calls==beforeOpen,'Opening the AH never starts the fallback scanner')
assert(F.StartNativeScan() and calls==beforeOpen+1)
assert(F.cancelScanButton.shown,'Cancel appears only for an active scan')
F.ApplySettings();assert(F.nativeScanActive,'TSM auto-hide must not cancel the fallback scan')
event('AUCTION_HOUSE_CLOSED')
assert(not F.nativeScanActive and not F.cancelScanButton.shown and not F.scanFooter.progress.shown and not F.scanFooter.scribe.art.shown)
states.TradeSkillMaster=0
UnitName=oldUnitName;UnitGUID=oldGUID
C_AddOns=nil;F.UpdateScanUI();assert(F.scanFooter.shown,'No third-party scanner exposes native controls')
C_AddOns=oldAddons
C_AuctionHouse,Auctionator,AuctionHouseFrame=oldAH,oldAuctionator,oldFrame
AucAdvanced=oldAuc
F.Now,C_Map.GetBestMapForUnit,F.Refresh=oldNow,oldMap,oldRefresh
F.char.localPrices,F.char.nativeScanLastAttempt=oldPrices,oldLast
F.char.peerPrices,F.db.settings.peerSharing=oldPeers,oldSharing
print('PASS: standalone AH snapshots, scoped prices, totals, freshness, cooldown, cancellation, late events and partial failures')
