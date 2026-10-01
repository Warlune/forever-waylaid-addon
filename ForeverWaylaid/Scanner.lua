local _,F=...
local cooldown=15*60
local frame=CreateFrame("Frame")
F.scanFrame=frame
local state,opened
local lastReport={}
local status="Open a faction-capital AH to scan."
-- Addon identifiers only; no third-party implementation is embedded here.
F.auctionAddons={
  {"Auctionator","Auctionator"},{"Auc-Advanced","Auctioneer"},{"Auctioneer","Auctioneer"},
  {"TradeSkillMaster","TSM"},{"aux-addon","Aux"},{"AuctionLite","AuctionLite"},
  {"AuctionFaster","AuctionFaster"},{"AuctionDB","AHDB"},
  {"AuctionMaster","AuctionMaster"},
  {"AuctionBuddy","AuctionBuddy"},{"Midas","Midas"},{"GoldCap","GoldCap"},
}

local function addonEnabled(name)
  local enabled=C_AddOns and C_AddOns.GetAddOnEnableState
  local character=(UnitGUID and UnitGUID("player")) or (UnitName and UnitName("player"))
  if enabled then
    local ok,value=pcall(enabled,name,character)
    if ok and type(value)=="number" then return value>0 end
  end
  local loaded=C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
  if loaded then local ok,value=pcall(loaded,name);if ok and value then return true end end
  return not not ((name=="Auctionator" and Auctionator) or (name=="Auc-Advanced" and AucAdvanced))
end
function F.HasAuctionScanner()
  for _,addon in ipairs(F.auctionAddons)do
    if addonEnabled(addon[1]) then return true,addon[2] end
  end
  return false
end
-- Only these integrations can currently supply personal prices to Waylaid.
-- Other auction addons may hide our AH tab, but must not hide the manual fallback.
function F.ShouldHideNativeScan()
  return F.db.settings.autoHideAuction~=false and
    (addonEnabled("Auctionator") or addonEnabled("Auc-Advanced") or addonEnabled("Auctioneer"))
end
function F.ShouldHideAuctionExtras()
  return F.db.settings.autoHideAuction~=false and F.HasAuctionScanner()
end

local function isOpen()
  if opened~=nil then return opened end
  return AuctionHouseFrame and AuctionHouseFrame:IsShown()
end
local function supported()
  return C_AuctionHouse and C_AuctionHouse.ReplicateItems and C_AuctionHouse.GetNumReplicateItems and C_AuctionHouse.GetReplicateItemInfo
end
local function remaining()
  local last=F.char and F.char.nativeScanLastAttempt or 0
  local external=Auctionator and Auctionator.SavedState and Auctionator.SavedState.TimeOfLastReplicateScan
  if type(external)=="number" then last=math.max(last,external)end
  return math.max(0,cooldown-(F.Now()-last))
end
function F.GetScanProgress()
  local report=state or lastReport
  local text=status
  local wait=remaining()
  if not state then
    if not isOpen() then text="Open a faction-capital AH to scan."
    elseif not supported() then text="This client's auction snapshot API is unavailable."
    elseif not F.db.settings.personal then text="Enable personal scan prices in Waylaid Settings first."
    elseif not F.PersonalScanScope() then text="Visit your faction's capital auction house to scan."
    elseif wait>0 then text=text.." Next scan in "..math.ceil(wait/60).."m." end
  end
  local available=not F.ShouldHideAuctionExtras()
  return {active=state~=nil,available=available,nativeAvailable=not F.ShouldHideNativeScan(),open=not not isOpen(),status=text,phase=report.phase,
    processed=report.index or 0,total=report.total,unique=report.unique or 0,matched=report.matched or 0,
    saved=report.saved or 0,elapsed=report.elapsed or 0,cooldown=wait,
    canStart=not not (not F.ShouldHideNativeScan() and not state and isOpen() and supported() and F.db.settings.personal and F.PersonalScanScope() and wait==0)}
end
function F.UpdateScanUI()
  if not F.db then return end
  local info=F.GetScanProgress()
  if F.auctionCompatibility then
    local found,label=F.HasAuctionScanner()
    F.auctionCompatibility:SetText(found and ("Detected: "..label..(F.db.settings.autoHideAuction~=false and " • extras hidden" or " • auto-hide off")) or "No supported auction addon enabled.")
  end
  if F.scanButton then
    F.scanFooter:SetShown(info.nativeAvailable)
    F.ledgerHeight=info.nativeAvailable and 774 or 704
    F.window:SetHeight(F.ledgerHeight)
    F.footerNote:SetPoint("TOPLEFT",27,-F.ledgerHeight+20)
    F.versionLabel:SetPoint("TOPLEFT",948,-F.ledgerHeight+20)
    F.ApplyAccessibility()
    F.cancelScanButton:SetShown(info.active)
    F.scanButton:SetText(info.active and "Scanning…" or "Scan AH prices")
    F.scanButton:SetEnabled(info.canStart);F.cancelScanButton:SetEnabled(info.active)
    F.scanStatus:SetText(info.status)
    F.scanStatus:ClearAllPoints();F.scanStatus:SetPoint("TOPLEFT",info.active and 270 or 180,-8)
    F.scanStatus:SetWidth(info.active and 635 or 725)
    F.scanFooter.progress:SetShown(info.open)
    F.scanFooter.scribe.art:SetShown(info.open)
    F.scanFooter.scribe.active=info.active
    F.scanFooter.scribe.pose()
    F.scanFooter.progress:SetValue(info.phase=="complete" and 1 or (info.total and info.total>0 and info.processed/info.total or 0))
  end
  if F.UpdateAuctionScanUI then F.UpdateAuctionScanUI(info)end
end
local function finish(message,saved)
  if state then
    lastReport={index=state.index,total=state.total,unique=state.unique,matched=state.matched,elapsed=state.elapsed,saved=saved or 0,phase=saved and "complete" or "stopped"}
  end
  state=nil;F.nativeScanActive=false;status=message;F.UpdateScanUI()
end
function F.CancelNativeScan(message)
  if not state then return end
  finish(message or "Scan cancelled. Previous prices kept.")
end
function F.StartNativeScan()
  if state then return false end
  if F.ShouldHideNativeScan() then status="Use your enabled auction scanner.";F.UpdateScanUI();return false end
  if not isOpen() then status="Open a faction-capital AH to scan.";F.UpdateScanUI();return false end
  if not supported() then status="This client's auction snapshot API is unavailable.";F.UpdateScanUI();return false end
  if not F.db.settings.personal then status="Enable personal scan prices in Waylaid Settings first.";F.UpdateScanUI();return false end
  local scope,city=F.PersonalScanScope()
  if not scope then status="Scan at your faction's capital AH, not a neutral AH.";F.UpdateScanUI();return false end
  if remaining()>0 then status="Auction snapshot is on cooldown.";F.UpdateScanUI();return false end
  local other=Auctionator and Auctionator.State
  if other and ((other.FullScanFrameRef and other.FullScanFrameRef.inProgress) or (other.IncrementalScanFrameRef and other.IncrementalScanFrameRef.doingFullScan)) then
    status="Wait for the other auction scan to finish.";F.UpdateScanUI();return false
  end
  local now=F.Now()
  state={scope=scope,city=city,observed=now,elapsed=0,unique=0,seen={},matched=0,phase="waiting",snapshot={},incomplete={},unresolved={}}
  F.nativeScanActive=true
  local ok=pcall(C_AuctionHouse.ReplicateItems)
  if not ok then finish("The AH could not start a snapshot. Previous prices kept.");return false end
  F.char.nativeScanLastAttempt=now
  status="Waiting for the AH snapshot… Keep the AH open."
  F.UpdateScanUI();return true
end

frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
frame:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
frame:SetScript("OnEvent",function(_,event)
  if event=="AUCTION_HOUSE_SHOW" then
    opened=true
    if not state then status="Ready. One full snapshot; no purchases." end
  elseif event=="AUCTION_HOUSE_CLOSED" then
    opened=false;F.CancelNativeScan("AH closed. Scan cancelled; previous prices kept.")
  elseif event=="REPLICATE_ITEM_LIST_UPDATE" and state and state.phase=="waiting" then
    local total=C_AuctionHouse.GetNumReplicateItems()
    if type(total)~="number" or total<0 or total~=math.floor(total) then finish("Invalid AH response. Previous prices kept.");return end
    state.total=total;state.index=0;state.phase="reading"
  end
  if F.char then F.UpdateScanUI()end
end)
local uiElapsed=0
local function readRow(index)
  local _,_,count,_,_,_,_,_,_,buyout,_,_,_,_,_,_,id=C_AuctionHouse.GetReplicateItemInfo(index)
  if not F.Positive(id) or id~=math.floor(id) then return false end
  if not state.seen[id] then state.seen[id]=true;state.unique=state.unique+1 end
  if not F.Positive(count) or type(buyout)~="number" or buyout<0 or buyout~=buyout or buyout==math.huge then
    state.incomplete[id]=true
  elseif F.Positive(buyout) then
    local row=state.snapshot[id]
    if row then row.price=math.min(row.price,buyout/count);row.quantity=row.quantity+count
    else
      state.snapshot[id]={price=buyout/count,quantity=count}
      if F.catalogIDs[id] then state.matched=state.matched+1 end
    end
  end
  return true
end
local function commit()
  local skipped=0
  for id in pairs(state.incomplete)do state.snapshot[id]=nil;skipped=skipped+1 end
  local count=F.SaveNativeSnapshot(state.snapshot,state.scope,state.observed)
  local text="Saved "..count.." item prices. Missing listings keep older prices."
  if skipped>0 then text=text.." "..skipped.." incomplete items skipped."end
  finish(text,count);F.Refresh()
end
frame:SetScript("OnUpdate",function(_,dt)
  uiElapsed=uiElapsed+dt
  if uiElapsed>=1 then uiElapsed=0;if F.char then F.UpdateScanUI()end end
  if not state then return end
  state.elapsed=state.elapsed+dt
  if state.elapsed>120 then finish("AH snapshot timed out. Previous prices kept; try after cooldown.");return end
  local scope,city=F.PersonalScanScope()
  if not isOpen() or scope~=state.scope or city~=state.city or not F.db.settings.personal then
    F.CancelNativeScan("Scan interrupted. Previous prices kept.");return
  end
  if state.phase~="reading" and state.phase~="validating" then return end
  if C_AuctionHouse.GetNumReplicateItems()~=state.total then finish("AH snapshot changed. Previous prices kept.");return end
  if state.phase=="validating" then
    state.retryWait=state.retryWait-dt
    if state.retryWait>0 then return end
    for _=1,250 do
      local index=state.unresolved[state.retryIndex]
      if index==nil then break end
      if not readRow(index) then state.retryNext[#state.retryNext+1]=index end
      state.retryIndex=state.retryIndex+1
    end
    if state.retryIndex>#state.unresolved then
      state.unresolved=state.retryNext
      if #state.unresolved==0 then commit();return end
      state.retryPass=state.retryPass+1
      if state.retryPass>=3 then finish("Incomplete AH snapshot: "..#state.unresolved.." unidentified auctions. Previous prices kept.");return end
      state.retryIndex=1;state.retryNext={};state.retryWait=1
    end
    status="Checking "..#state.unresolved.." unidentified auctions…";F.UpdateScanUI();return
  end
  -- Read a bounded batch each frame to keep the game responsive. Item names,
  -- links and owner metadata are unnecessary for unit prices.
  for index=state.index,math.min(state.index+249,state.total-1)do
    if not readRow(index) then state.unresolved[#state.unresolved+1]=index end
  end
  state.index=math.min(state.index+250,state.total)
  status="Reading auctions: "..state.index.." / "..state.total
  F.UpdateScanUI()
  if state.index>=state.total then
    -- Only complete item observations replace existing prices. Items absent
    -- from this snapshot retain their previous price and original timestamp.
    if #state.unresolved>0 then
      state.phase="validating";state.retryIndex=1;state.retryNext={};state.retryPass=0;state.retryWait=1
      status="Checking "..#state.unresolved.." unidentified auctions…";F.UpdateScanUI()
    else commit()end
  end
end)
