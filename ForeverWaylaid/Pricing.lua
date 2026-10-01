local _, F = ...

-- Compare observation times per item, never import/receive times. The first
-- source wins ties; direct personal observations take precedence over peers.
function F.SelectPrice(preferred, candidate)
  if not preferred then return candidate end
  if not candidate then return preferred end
  if (candidate.time or 0) > (preferred.time or 0) then return candidate end
  return preferred
end
function F.Price(id)
  local scope = F.char.realm .. ":" .. UnitFactionGroup("player")
  local personal = F.db.settings.personal and F.char.localPrices[scope]
  local peers=F.db.settings.peerSharing and F.char.peerPrices and F.char.peerPrices[scope]
  local peer=peers and peers[id]
  if peer and (not peer.time or F.Now()-peer.time>86400 or peer.time>F.Now()+60) then peer=nil end
  return F.SelectPrice(personal and personal[id],peer)
end
function F.CrateCosts(crate, includeCrate)
  local rows, best = {}, nil
  if includeCrate==nil then includeCrate=F.db.settings.includeCrate end
  local box = includeCrate and F.Price(crate.id) or nil
  for _, option in ipairs(crate.options) do
    local quote = F.Price(option.itemId)
    local cost = quote and quote.price * option.qty or nil
    if includeCrate then cost = cost and box and cost + box.price or nil end
    local enough = quote and (not quote.quantity or quote.quantity >= option.qty)
    if includeCrate and box and box.quantity and box.quantity < 1 then enough = false end
    local row = { option = option, quote = quote, cost = cost, enough = enough }
    rows[#rows + 1] = row
    if cost and enough and (not best or cost < best.cost) then best = row end
  end
  table.sort(rows, function(a, b) return (a.cost or math.huge) < (b.cost or math.huge) end)
  return rows, best
end

local function save(target, id, price, observed, source, quantity, allItems)
  if not F.Positive(id) or id~=math.floor(id) or (not allItems and not F.catalogIDs[id]) or not F.Positive(price) then return end
  if observed and (not F.Positive(observed) or observed > F.Now() + 300) then return end
  local row = { price = math.ceil(price), time = observed, source = source, quantity = quantity }
  target[id] = F.SelectPrice(target[id], row)
  return target[id]==row
end
function F.ImportPersonal(silent)
  local scope = F.char.realm .. ":" .. UnitFactionGroup("player")
  local target = F.char.localPrices[scope] or {}
  F.char.localPrices[scope] = target
  local used = {}
  -- Auctionator's historical API does not consistently expose observation time
  -- and auction-house faction. Capture completed scans below instead.
  if Auctionator then used[#used + 1] = "Auctionator (completed scans captured while enabled)" end
  -- Read the home faction image explicitly: a neutral AH must not change scope.
  local auc = AucAdvanced
  if auc and auc.Scan and auc.Scan.GetImageCopy and auc.Const and auc.Const.COUNT and auc.Const.BUYOUT and auc.Const.TIME and (auc.Const.ITEMID or auc.Const.ID) and auc.Resources and auc.Resources.ServerKeyHome then
    local ok, rows = pcall(auc.Scan.GetImageCopy, auc.Resources.ServerKeyHome)
    if ok and type(rows) == "table" then
      local c, snapshot = auc.Const, {}
      for _, row in ipairs(rows) do
        local id = row[c.ITEMID or c.ID]
        local count, buyout, stamp = row[c.COUNT], row[c.BUYOUT], row[c.TIME]
        if F.catalogIDs[id] and F.Positive(count) and F.Positive(buyout) and F.Positive(stamp) and stamp <= F.Now() + 300 then
          local price = math.ceil(buyout / count)
          local existing = snapshot[id]
          if not existing or stamp > existing.time then
            snapshot[id] = { price = price, time = stamp, quantity = count }
          elseif stamp == existing.time then
            existing.price = math.min(existing.price, price)
            existing.quantity = existing.quantity + count
          end
        end
      end
      for id, row in pairs(snapshot) do save(target, id, row.price, row.time, "Auctioneer", row.quantity) end
      used[#used + 1] = "Auctioneer"
    end
  end
  if not silent then F.Print(#used > 0 and ("Read personal prices: " .. table.concat(used, ", ") .. ".") or "Use Scan AH prices in Settings to collect prices without another scanner.")end
end

local capitals = {
  Horde = {[1454]=true,[1456]=true,[1458]=true,[1954]=true},
  Alliance = {[1453]=true,[1455]=true,[1457]=true,[1947]=true},
}
local function scanScope()
  local faction = UnitFactionGroup("player")
  local allowed = capitals[faction]
  if not allowed then return end
  local map = C_Map.GetBestMapForUnit("player")
  for _=1,8 do
    if allowed[map] then return GetRealmName()..":"..faction, map end
    local info = map and C_Map.GetMapInfo(map)
    map = info and info.parentMapID
    if not map or map==0 then break end
  end
end
F.PersonalScanScope=scanScope
function F.SaveNativeSnapshot(snapshot,scope,observed)
  local target=F.char.localPrices[scope] or {};F.char.localPrices[scope]=target
  local count=0
  for id,row in pairs(snapshot)do
    if save(target,id,row.price,observed,"Forever Waylaid",row.quantity,true) then count=count+1 end
  end
  return count
end
function F.SaveAuctionatorRows(kind, rows, scope, observed)
  if type(rows) ~= "table" then return end
  local snapshot = {}
  for _, row in ipairs(rows) do
    local id, price, quantity
    if kind == "incremental" then
      id = row.itemKey and row.itemKey.itemID; price = row.minPrice; quantity = row.totalQuantity
    else
      local info = row.replicateInfo or row.auctionInfo
      if info then
        id, quantity = info[17], info[3]
        if F.Positive(info[10]) and F.Positive(quantity) then price=info[10]/quantity end
      end
    end
    if F.catalogIDs[id] and F.Positive(price) and F.Positive(quantity) then
      local existing = snapshot[id]
      if existing then existing.price=math.min(existing.price,price); existing.quantity=existing.quantity+quantity
      else snapshot[id]={price=price,quantity=quantity} end
    end
  end
  local target=F.char.localPrices[scope] or {}; F.char.localPrices[scope]=target
  for id,row in pairs(snapshot) do save(target,id,row.price,observed,"Auctionator",row.quantity) end
end
function F.RegisterAuctionator()
  if not Auctionator or not Auctionator.EventBus then return end
  local phases, names, pending = {}, {}, nil
  for _, kind in ipairs({"full","incremental"}) do
    local module = kind=="full" and Auctionator.FullScan or Auctionator.IncrementalScan
    local e = module and module.Events
    if e and e.ScanStart and e.ScanComplete and e.ScanFailed then
      for phase,name in pairs({start=e.ScanStart,complete=e.ScanComplete,failed=e.ScanFailed}) do
        phases[name]={kind=kind,phase=phase}; names[#names+1]=name
      end
    end
  end
  local listener={}
  function listener:ReceiveEvent(name,rows)
    local e=phases[name]
    if not e or not F.char then return end
    if e.phase=="start" then
      if F.CancelNativeScan then F.CancelNativeScan("Stopped: another auction scan started. Previous prices kept.")end
      local scope,city=scanScope(); pending=scope and {scope=scope,city=city,kind=e.kind}
    elseif e.phase=="failed" then pending=nil
    elseif e.phase=="complete" then
      local scope,city=scanScope(); local started=pending;pending=nil
      if F.db.settings.personal and started and started.scope==scope and started.city==city and started.kind==e.kind then
        F.SaveAuctionatorRows(e.kind,rows,scope,F.Now());F.Refresh()
      end
    end
  end
  if #names>0 then Auctionator.EventBus:Register(listener,names) end
end

-- Import optional third-party data silently when the auction house closes.
local frame = CreateFrame("Frame")
frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
frame:SetScript("OnEvent", function()
  if F.char and F.db.settings.personal then F.ImportPersonal(true); F.Refresh() end
end)
