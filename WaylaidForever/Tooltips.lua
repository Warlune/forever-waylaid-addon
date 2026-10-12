local _, F = ...
F.tooltipModeOptions={{"both","Show both"},{"crates","Only crates / writs"},{"materials","Only materials"},{"none","None"}}
function F.TooltipMode()
  local mode=F.db.settings.tooltipMode
  for _,option in ipairs(F.tooltipModeOptions)do if mode==option[1]then return option[1],option[2]end end
  return "both","Show both"
end
-- Index direct fill bundles once; crafting ingredients are not automatically crate goods.
local crateUses={}
for _,crate in ipairs(F.catalog.crates)do
  for _,option in ipairs(crate.options)do
    local uses=crateUses[option.itemId] or {};crateUses[option.itemId]=uses
    uses[#uses+1]={name=crate.name,qty=option.qty}
  end
end
-- Private weak keys avoid leaving our bookkeeping on Blizzard/other-addon frames.
local items=setmetatable({},{__mode="k"})
local clearHooks=setmetatable({},{__mode="k"})
local itemHooks=setmetatable({},{__mode="k"})
local processors=setmetatable({},{__mode="k"})
local function watchClear(tooltip)
  if not clearHooks[tooltip] and tooltip.HookScript then
    tooltip:HookScript("OnTooltipCleared",function(self)items[self]=nil end)
    clearHooks[tooltip]=true
  end
end
local function append(tooltip, id)
  if not F.db or not F.char then return end
  watchClear(tooltip)
  if items[tooltip]==id then return end
  local uses=F.db.settings.crateUseTooltips~=false and crateUses[id]
  local mode=F.TooltipMode()
  local crate,writ=F.cratesByID[id],F.writsByID[id]
  local related=F.catalogIDs[id]
  local details=mode~="none"
    and (mode~="crates" or crate or writ)
    and (mode~="materials" or (not crate and not writ and related))
    and (related or (F.db.settings.generalAuctionTooltips~=false and not F.ShouldHideAuctionExtras()))
  local market=details and F.Price(id)
  if not uses and not (details and (crate or writ or market))then return end
  items[tooltip]=id
  if related or uses then
    tooltip:AddLine(" ")
    tooltip:AddLine("Waylaid Forever",0.87,0.74,0.39)
  end
  if uses then
    tooltip:AddLine("Used to fill a Waylaid supply crate",0.45,1,0.6)
    for _,use in ipairs(uses)do
      tooltip:AddDoubleLine(use.name:gsub("^Waylaid Crate: ",""),use.qty.." needed",1,1,1,1,1,1)
    end
    tooltip:AddLine("One accepted bundle fills a crate.",0.8,0.8,0.8)
  end
  if not details or (not crate and not writ and not market)then tooltip:Show();return end
  if market then
    tooltip:AddDoubleLine("AH buyout (each)",F.Style.Money(market.price),1,1,1,1,1,1)
    if related then tooltip:AddLine(market.source.." · "..F.Style.Age(market.time),0.65,0.65,0.65)end
  end
  if not related then tooltip:Show();return end
  if crate then
    local rows, best = F.CrateCosts(crate)
    if F.db.settings.cheapest then
      tooltip:AddDoubleLine("Cheapest " .. (F.db.settings.includeCrate and "total" or "fill"), best and F.Style.Money(best.cost) or "Unpriced / low stock", 1,1,1, 1,1,1)
      if best then tooltip:AddLine(best.option.qty .. " × " .. best.option.name, 0.8,0.8,0.8) end
    end
    if F.db.settings.allCosts then
      for _, row in ipairs(rows) do
        tooltip:AddDoubleLine(row.option.qty .. " × " .. row.option.name, F.Style.Money(row.cost), 0.9,0.9,0.9, 1,1,1)
        if row.quote then
          local note = row.quote.source .. (row.quote.quantity and (" · " .. row.quote.quantity .. " listed") or " · stock unknown")
          tooltip:AddLine(note, 0.65,0.65,0.65)
        end
      end
    end
    if best and best.quote then tooltip:AddLine("Source: " .. best.quote.source, 0.65,0.65,0.65) end
  elseif writ then
    local status=F.WritStatus(writ.questId)
    if status then
      tooltip:AddLine(F.writStatusLabels[status],1,1,1)
      if status=="completed"then tooltip:AddLine("Available again after the daily reset.",0.8,0.8,0.8)end
    end
    local quote = F.Price(writ.targetId)
    tooltip:AddDoubleLine(writ.qty .. " × " .. writ.targetName, F.Style.Money(quote and quote.price * writ.qty), 1,1,1, 1,1,1)
    tooltip:AddLine(writ.rep .. " reputation · keep the writ for delivery", 0.8,0.8,0.8)
    if quote then tooltip:AddLine("Source: " .. quote.source, 0.65,0.65,0.65) end
  end
  tooltip:AddLine("Lowest-buyout estimates; check listings.", 0.65,0.65,0.65)
  tooltip:Show()
end
function F.InstallTooltips()
  for _, tooltip in ipairs({GameTooltip, ItemRefTooltip}) do
    watchClear(tooltip)
  end
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    if processors[TooltipDataProcessor]then return end
    processors[TooltipDataProcessor]=true
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      if data and data.id then append(tooltip, data.id) end
    end)
  else
    for _, tooltip in ipairs({GameTooltip, ItemRefTooltip}) do
      if not itemHooks[tooltip]then
      itemHooks[tooltip]=true
      tooltip:HookScript("OnTooltipSetItem", function(self)
        local _, link = self:GetItem()
        local id = link and tonumber(link:match("item:(%d+)"))
        if id then append(self, id) end
      end)
      end
    end
  end
end
