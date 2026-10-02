local _, F = ...
local function append(tooltip, id)
  if not F.db or not F.char then return end
  local crate, writ = F.cratesByID[id], F.writsByID[id]
  if not F.catalogIDs[id] and (F.db.settings.generalAuctionTooltips==false or F.ShouldHideAuctionExtras()) then return end
  local market=F.Price(id)
  if not crate and not writ and not market then return end
  if tooltip.fwlItem == id then return end
  tooltip.fwlItem = id
  local related=F.catalogIDs[id]
  if related then
    tooltip:AddLine(" ")
    tooltip:AddLine("Waylaid Forever", 0.87, 0.74, 0.39)
  end
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
    tooltip:HookScript("OnTooltipCleared", function(self) self.fwlItem = nil end)
  end
  if TooltipDataProcessor and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      if data and data.id then append(tooltip, data.id) end
    end)
  else
    for _, tooltip in ipairs({GameTooltip, ItemRefTooltip}) do
      tooltip:HookScript("OnTooltipSetItem", function(self)
        local _, link = self:GetItem()
        local id = link and tonumber(link:match("item:(%d+)"))
        if id then append(self, id) end
      end)
    end
  end
end
