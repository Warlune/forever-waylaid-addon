local F=...
local oldAH,oldAuctionator,oldFrame=C_AuctionHouse,Auctionator,AuctionHouseFrame
local oldAuc=AucAdvanced
local oldNow,oldMap,oldRefresh=F.Now,C_Map.GetBestMapForUnit,F.Refresh
local oldPrices,oldLast=F.char.localPrices,F.char.nativeScanLastAttempt
local oldPeers,oldSharing=F.char.peerPrices,F.db.settings.peerSharing
local now,calls,refreshes=100000,0,0
local rows={}
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
assert(not prices[2589] and not prices[999999],'Ignore bid-only and unrelated auctions')
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
now=now+901;C_AuctionHouse.ReplicateItems=function()error('unavailable')end
assert(not F.StartNativeScan() and not F.nativeScanActive,'Rejected API call releases active state')
C_AuctionHouse=nil;assert(not F.StartNativeScan(),'Unsupported client degrades safely')
event('AUCTION_HOUSE_CLOSED')
local oldAddons=C_AddOns
local oldUnitName=UnitName;UnitName=function()return 'CurrentCharacter' end
local states={Auctionator=0,['Auc-Advanced']=0}
C_AddOns={GetAddOnEnableState=function(name,character)assert(character=='CurrentCharacter');return states[name]end}
Auctionator={};AucAdvanced={}
F.UpdateScanUI();assert(F.scanButton.shown and F.cancelScanButton.shown and F.scanStatus.shown,'Disabled installations must expose native controls, including before reload')
states.Auctionator=1
F.UpdateScanUI();assert(not F.scanButton.shown and not F.cancelScanButton.shown and not F.scanStatus.shown,'Auctionator enabled for this character hides native controls')
states.Auctionator=0;states['Auc-Advanced']=2
F.UpdateScanUI();assert(not F.scanButton.shown,'Enabled Auctioneer hides native controls')
states['Auc-Advanced']=0;Auctionator=nil;AucAdvanced=nil
F.UpdateScanUI();assert(F.scanButton.shown,'Both disabled exposes native controls')
UnitName=oldUnitName
C_AddOns=nil;F.UpdateScanUI();assert(F.scanButton.shown,'No third-party scanner exposes native controls')
C_AddOns=oldAddons
C_AuctionHouse,Auctionator,AuctionHouseFrame=oldAH,oldAuctionator,oldFrame
AucAdvanced=oldAuc
F.Now,C_Map.GetBestMapForUnit,F.Refresh=oldNow,oldMap,oldRefresh
F.char.localPrices,F.char.nativeScanLastAttempt=oldPrices,oldLast
F.char.peerPrices,F.db.settings.peerSharing=oldPeers,oldSharing
print('PASS: standalone AH snapshots, scoped prices, totals, freshness, cooldown, cancellation, late events and partial failures')
