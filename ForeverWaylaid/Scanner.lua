local _,F=...
local cooldown=15*60
local frame=CreateFrame("Frame")
F.scanFrame=frame
local state,opened
local status="Open a faction-capital AH to scan."

function F.HasAuctionScanner()
  local enabled=C_AddOns and C_AddOns.GetAddOnEnableState
  local character=UnitName and UnitName("player")
  for _,name in ipairs({"Auctionator","Auc-Advanced"})do
    local checked=false
    if enabled then
      local ok,value=pcall(enabled,name,character)
      if ok and type(value)=="number" then
        checked=true
        if value>0 then return true end
      end
    end
    -- Older clients can still detect a running scanner. A known disabled
    -- state wins even if its globals remain until the next reload.
    if not checked and ((name=="Auctionator" and Auctionator) or (name=="Auc-Advanced" and AucAdvanced))then return true end
  end
  return false
end

local function isOpen()
  return opened or (AuctionHouseFrame and AuctionHouseFrame:IsShown())
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
function F.UpdateScanUI()
  if not F.scanButton then return end
  local available=not F.HasAuctionScanner()
  F.scanButton:SetShown(available);F.cancelScanButton:SetShown(available);F.scanStatus:SetShown(available)
  if not available then return end
  F.scanButton:SetText(state and "Scanning…" or "Scan AH prices")
  F.scanButton:SetEnabled(not state and isOpen() and supported() and F.db.settings.personal and F.PersonalScanScope()~=nil and remaining()==0)
  F.cancelScanButton:SetEnabled(state~=nil)
  local text=status
  if not state and remaining()>0 then text=text.." Next scan in "..math.ceil(remaining()/60).."m." end
  F.scanStatus:SetText(text)
end
local function finish(message)
  state=nil;F.nativeScanActive=false;status=message;F.UpdateScanUI()
end
function F.CancelNativeScan(message)
  if not state then return end
  finish(message or "Scan cancelled. Previous prices kept.")
end
function F.StartNativeScan()
  if state then return false end
  if not isOpen() then status="Open a faction-capital AH to scan.";F.UpdateScanUI();return false end
  if not supported() then status="This client's auction snapshot API is unavailable.";F.UpdateScanUI();return false end
  if not F.db.settings.personal then status="Enable personal scan prices above first.";F.UpdateScanUI();return false end
  local scope,city=F.PersonalScanScope()
  if not scope then status="Scan at your faction's capital AH, not a neutral AH.";F.UpdateScanUI();return false end
  if remaining()>0 then status="Auction snapshot is on cooldown.";F.UpdateScanUI();return false end
  local other=Auctionator and Auctionator.State
  if other and ((other.FullScanFrameRef and other.FullScanFrameRef.inProgress) or (other.IncrementalScanFrameRef and other.IncrementalScanFrameRef.doingFullScan)) then
    status="Wait for the other auction scan to finish.";F.UpdateScanUI();return false
  end
  local now=F.Now()
  state={scope=scope,city=city,observed=now,elapsed=0,phase="waiting",snapshot={},incomplete={}}
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
  if state.phase~="reading" then return end
  if C_AuctionHouse.GetNumReplicateItems()~=state.total then finish("AH snapshot changed. Previous prices kept.");return end
  -- Read a bounded batch each frame to keep the game responsive. Item names,
  -- links and owner metadata are unnecessary for unit prices.
  for index=state.index,math.min(state.index+249,state.total-1)do
    local _,_,count,_,_,_,_,_,_,buyout,_,_,_,_,_,_,id=C_AuctionHouse.GetReplicateItemInfo(index)
    if F.catalogIDs[id] then
      if not F.Positive(count) or type(buyout)~="number" or buyout<0 or buyout~=buyout then
        state.incomplete[id]=true
      elseif F.Positive(buyout) then
        local row=state.snapshot[id]
        if row then row.price=math.min(row.price,buyout/count);row.quantity=row.quantity+count
        else state.snapshot[id]={price=buyout/count,quantity=count}end
      end
    end
  end
  state.index=math.min(state.index+250,state.total)
  status="Reading auctions: "..state.index.." / "..state.total
  F.UpdateScanUI()
  if state.index>=state.total then
    -- Only complete item observations replace existing prices. Items absent
    -- from this snapshot retain their previous price and original timestamp.
    local skipped=0
    for id in pairs(state.incomplete)do state.snapshot[id]=nil;skipped=skipped+1 end
    local count=F.SaveNativeSnapshot(state.snapshot,state.scope,state.observed)
    local text="Saved "..count.." item prices. Missing listings keep older prices."
    if skipped>0 then text=text.." "..skipped.." incomplete items skipped."end
    finish(text);F.Refresh()
  end
end)
