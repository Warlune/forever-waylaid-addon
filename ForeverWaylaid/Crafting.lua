local _,F=...
-- Aggregate every parent's demand before rounding shared intermediate batches.
-- This mirrors the website's verified graph and uses minimum guaranteed yields.
local function single(id,qty,override)
  local data=F.recipeData;local visited,order={},{}
  local faction=UnitFactionGroup("player"):lower()
  local reason
  local function recipe(key) return key==id and override or data.recipes[tostring(key)] end
  local function visit(key)
    if visited[key]==1 then reason="Recipe cycle detected";return end
    if visited[key]==2 then return end
    visited[key]=1
    local r=recipe(key)
    if r then
      if r[1] then reason="Nested recipe alternatives need review";return end
      if r.allowedFactions then
        local allowed=false;for _,f in ipairs(r.allowedFactions)do if f==faction then allowed=true end end
        if not allowed then reason=r.name..": recipe unavailable for your faction";return end
      end
      for _,mat in ipairs(r.reagents)do visit(mat.itemId)end
    elseif not data.metadata.leaves[tostring(key)] then reason="No verified recipe or material data" end
    visited[key]=2;order[#order+1]=key
  end
  visit(id)
  if reason then return {enough=false,reason=reason,materials={},steps={}} end
  local demand={[id]=qty};local steps,materials={},{};local variable=false
  for i=#order,1,-1 do
    local key=order[i];local r=recipe(key)
    if r then
      local crafts=math.ceil((demand[key] or 0)/r.outputMin)
      steps[#steps+1]={itemId=key,name=r.name,crafts=crafts,profession=r.profession,skill=r.skill,
        outputMin=r.outputMin,outputMax=r.outputMax,spellId=r.spellId}
      variable=variable or r.outputMin~=r.outputMax
      for _,mat in ipairs(r.reagents)do demand[mat.itemId]=(demand[mat.itemId] or 0)+crafts*mat.qty end
    end
  end
  local cost,enough,missing,short=0,true,false,false
  for _,key in ipairs(order)do
    if not recipe(key) then
      local leaf=data.metadata.leaves[tostring(key)];local count=demand[key] or 0
      local quote=F.Price(key);local unit=quote and quote.price;local vendor=leaf.vendorCopper
      local useVendor=vendor and (not unit or vendor<=unit)
      if useVendor then unit=vendor end
      local value=unit and unit*count
      local stock=not useVendor and quote and quote.quantity
      if not value then missing=true;enough=false else cost=cost+value end
      if stock and stock<count then short=true;enough=false end
      materials[#materials+1]={itemId=key,name=leaf.name,qty=count,cost=value,unit=unit,
        source=useVendor and "Vendor base price" or quote and quote.source or "Unpriced",quantity=stock,time=not useVendor and quote and quote.time}
    end
  end
  local reverse={};for i=#steps,1,-1 do reverse[#reverse+1]=steps[i]end
  return {cost=not missing and cost or nil,enough=enough,materials=materials,steps=reverse,variableYield=variable,
    reason=missing and "Some raw materials are unpriced" or short and "Some auction materials have short stock" or nil}
end
function F.CraftQuote(id,qty)
  local r=F.recipeData.recipes[tostring(id)]
  if not r or not r[1] then return single(id,qty) end
  local choices={}
  for _,variant in ipairs(r)do choices[#choices+1]=single(id,qty,variant)end
  table.sort(choices,function(a,b)
    if a.enough~=b.enough then return a.enough end
    return (a.cost or math.huge)<(b.cost or math.huge)
  end)
  choices[1].alternativeCount=#choices
  return choices[1]
end
function F.GoodsQuote(id,qty)
  local auction=F.Price(id)
  if F.db.settings.craftGoods then return F.CraftQuote(id,qty),auction end
  return {cost=auction and auction.price*qty,enough=auction and (not auction.quantity or auction.quantity>=qty),
    reason=not auction and "No auction price" or auction.quantity and auction.quantity<qty and "Short auction stock" or nil},auction
end
function F.LedgerCrateCosts(crate)
  local rows,best={},nil
  for _,option in ipairs(crate.options)do
    local goods,auction=F.GoodsQuote(option.itemId,option.qty)
    local row={option=option,quote=auction,cost=goods.cost,enough=goods.enough,craft=F.db.settings.craftGoods and goods or nil}
    rows[#rows+1]=row
    if row.cost and row.enough and (not best or row.cost<best.cost)then best=row end
  end
  table.sort(rows,function(a,b)return (a.cost or math.huge)<(b.cost or math.huge)end)
  return rows,best
end
