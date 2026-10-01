local _,F=...
local S=F.Style
local pageSize=6
local tiers={"All tiers","Apprentice","Journeyman","Expert","Artisan"}
local function short(name) return name:gsub("^Waylaid Crate: ",""):gsub("^Craftsman's Writ: ","") end
local function match(text,query) return query=="" or text:lower():find(query,1,true) end

-- Match the website's five relative value bands, including identical-price ties.
F.valueLabels={"Best value","Good value","Middle","Low value","High cost"}
F.valueColors={{88/255,215/255,165/255},{166/255,216/255,111/255},{241/255,207/255,114/255},{239/255,164/255,108/255},{241/255,133/255,131/255}}
local neutral={129/255,145/255,163/255}
function F.PriceEntry(entry)
  entry.purchase=F.Price(entry.item.id)
  entry.total=entry.purchase and entry.cost and entry.purchase.price+entry.cost or nil
  entry.fullyPriced=entry.total~=nil
  local goods=entry.goods or entry.best
  entry.stockReady=goods and goods.enough and entry.purchase and (not entry.purchase.quantity or entry.purchase.quantity>=1) or false
end
function F.ScoreEntries(entries)
  local ranked={}
  for _,entry in ipairs(entries)do
    entry.band=nil
    if entry.total and entry.stockReady and (entry.reward or 0)>0 then ranked[#ranked+1]=entry end
  end
  table.sort(ranked,function(a,b)return a.total/a.reward<b.total/b.reward end)
  local previous,first
  for index,entry in ipairs(ranked)do
    local value=entry.total/entry.reward
    if value~=previous then first=index end
    entry.band=#ranked==1 and 1 or math.floor((first-1)*4/(#ranked-1)+0.5)+1
    previous=value
  end
end

function F.LedgerEntries()
  local entries,all={},{};local query=(F.searchText or ""):lower();local active={}
  for _,stop in ipairs(F.active or {}) do active[stop.questID]=stop end
  if F.tab=="Crates" then
    for _,item in ipairs(F.catalog.crates) do
      local rows,best=F.LedgerCrateCosts(item);local hay=item.name
      for _,o in ipairs(item.options) do hay=hay.." "..o.name end
      local chosen=best or rows[1]
      local entry={item=item,rows=rows,best=chosen,cost=chosen and chosen.cost,reward=item.favor,owned=S.Count(item.id)}
      all[#all+1]=entry
      if match(hay,query) and (not F.tierIndex or F.tierIndex==1 or item.tier==tiers[F.tierIndex]) and
        (not F.onlyOwned or S.Count(item.id)>0) then
        entries[#entries+1]=entry
      end
    end
  elseif F.tab=="Writs" then
    for _,item in ipairs(F.catalog.writs) do
      local goods,quote=F.GoodsQuote(item.targetId,item.qty)
      local entry={item=item,cost=goods.cost,goods=goods,reward=item.rep,quote=quote,stop=active[item.questId],owned=S.Count(item.id)}
      all[#all+1]=entry
      if match(item.name.." "..item.targetName,query) and (not F.onlyOwned or active[item.questId] or S.Count(item.id)>0) then
        entries[#entries+1]=entry
      end
    end
  elseif F.tab=="Route" then
    for index,leg in ipairs(F.route or {}) do entries[#entries+1]={item=leg.stop.writ,stop=leg.stop,leg=leg,index=index} end
    for _,stop in ipairs(F.unresolved or {}) do entries[#entries+1]={item=stop.writ,stop=stop} end
    return entries
  end
  for _,entry in ipairs(all)do F.PriceEntry(entry)end
  F.ScoreEntries(all)
  table.sort(entries,function(a,b)
    if a.fullyPriced~=b.fullyPriced then return a.fullyPriced end
    if F.tab=="Writs" and (a.stop~=nil)~=(b.stop~=nil) then return a.stop~=nil end
    if F.sortIndex==3 then return a.item.name<b.item.name end
    local av,bv=a.total or math.huge,b.total or math.huge
    if F.sortIndex~=2 then av=av/math.max(1,a.reward or 0);bv=bv/math.max(1,b.reward or 0) end
    if av==bv then return a.item.id<b.item.id end
    return av<bv
  end)
  return entries
end

function F.BuildUI()
  local w=CreateFrame("Frame","ForeverWaylaidFrame",UIParent,"BackdropTemplate");F.window=w
  w:SetSize(1040,704);w:SetPoint("CENTER");w:SetFrameStrata("HIGH")
  w:SetScale(math.min(1,(UIParent:GetWidth()-40)/1040,(UIParent:GetHeight()-40)/704))
  w:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=10,right=10,top=10,bottom=10}})
  w:SetBackdropColor(unpack(S.Theme().bg))
  w:SetBackdropBorderColor(0.86,0.72,0.46,1)
  local backing=w:CreateTexture(nil,"BACKGROUND",nil,-8);backing:SetPoint("TOPLEFT",10,-10);backing:SetPoint("BOTTOMRIGHT",-10,10);backing:SetColorTexture(0.055,0.039,0.025,0.98)
  w:EnableMouse(true);w:SetMovable(true);w:SetClampedToScreen(true);w:RegisterForDrag("LeftButton")
  w:SetScript("OnDragStart",w.StartMoving);w:SetScript("OnDragStop",w.StopMovingOrSizing)
  local banner=w:CreateTexture(nil,"ARTWORK");banner:SetPoint("TOPLEFT",14,-14);banner:SetSize(1012,60);S.Accent(banner,0.32)
  local crest=w:CreateTexture(nil,"OVERLAY");crest:SetPoint("TOPLEFT",25,-18);crest:SetSize(58,58);crest:SetTexture(S.Theme().crest)
  F.banner,F.crest=banner,crest
  S.Text(w,"FOREVER WAYLAID",94,-22,470,"GameFontNormalHuge",S.gold)
  F.factionTitle=S.Text(w,"THE MERCHANT'S FIELD LEDGER",95,-49,500,"GameFontHighlightSmall",S.muted)
  local close=CreateFrame("Button",nil,w,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-7,-7)
  F.status=S.Text(w,"",660,-37,343,"GameFontHighlightSmall",S.muted);F.status:SetJustifyH("RIGHT")
  F.tab="Crates";F.sortIndex=1;F.tierIndex=1;F.selected={};F.tabButtons={}
  for i,tab in ipairs({"Crates","Writs","Route","Settings"}) do
    F.tabButtons[tab]=S.Button(w,tab,24+(i-1)*154,-82,144,function()F.tab=tab;F.offset=0;F.Render()end)
  end
  S.Button(w,"Travel compass",844,-82,168,function()F.db.settings.navigator=not F.db.settings.navigator;F.UpdateNavigator()end)
  F.craftButton=S.Button(w,"Goods: Buy at AH",640,-82,194,function()
    F.db.settings.craftGoods=not F.db.settings.craftGoods;F.offset=0;F.Render()
  end)
  F.filters=CreateFrame("Frame",nil,w);F.filters:SetPoint("TOPLEFT",24,-120);F.filters:SetSize(988,28)
  local edit=CreateFrame("EditBox",nil,F.filters,"InputBoxTemplate");edit:SetPoint("TOPLEFT",8,0);edit:SetSize(278,26);edit:SetAutoFocus(false)
  edit:SetTextInsets(7,7,0,0);edit:SetScript("OnEscapePressed",edit.ClearFocus)
  edit:SetScript("OnTextChanged",function(self)F.searchText=self:GetText();F.offset=0;F.Render()end)
  local placeholder=S.Text(edit,"Search names or materials…",8,-7,250,"GameFontDisableSmall")
  edit:HookScript("OnTextChanged",function(self)placeholder:SetShown(self:GetText()=="")end)
  F.search=edit
  F.tierButton=S.Button(F.filters,"Tier: All",308,0,160,function()F.tierIndex=F.tierIndex%#tiers+1;F.offset=0;F.Render()end)
  F.sortButton=S.Button(F.filters,"Sort: Best value",480,0,176,function()F.sortIndex=F.sortIndex%3+1;F.offset=0;F.Render()end)
  F.ownedButton=S.Button(F.filters,"Show: All",668,0,166,function()F.onlyOwned=not F.onlyOwned;F.offset=0;F.Render()end)
  S.Button(F.filters,"Clear filters",846,0,140,function()F.searchText="";edit:SetText("");F.onlyOwned=false;F.tierIndex=1;F.offset=0;F.Render()end)
  F.stats={}
  for i=1,4 do
    local box=S.Panel(w,24+(i-1)*249,-159,240,50)
    box.caption=S.Text(box,"",12,-8,214,"GameFontHighlightSmall",S.muted)
    box.value=S.Text(box,"",12,-25,214,"GameFontNormal",S.gold);F.stats[i]=box
  end
  local warning=CreateFrame("Button",nil,F.stats[3]);F.flightWarning=warning
  warning:SetSize(24,24);warning:SetPoint("RIGHT",-8,0)
  warning:SetNormalTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
  warning:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText("Flight points not scanned")
    for _,name in ipairs(F.MissingFlightContinents())do GameTooltip:AddLine(name,1,0.82,0)end
    GameTooltip:AddLine("Open a flight master's map on each missing continent. No flight purchase needed.",1,1,1,true)
    GameTooltip:AddLine("Only discovered destinations and observed routes are recorded.",0.7,0.7,0.7,true)
    GameTooltip:Show()
  end)
  warning:SetScript("OnLeave",function()GameTooltip:Hide()end)
  F.body=S.Panel(w,24,-221,588,415);F.listTitle=S.Text(F.body,"",12,-11,550,"GameFontNormalSmall",S.gold)
  F.rows={}
  for i=1,pageSize do
    local row=CreateFrame("Button",nil,F.body);row:SetPoint("TOPLEFT",7,-31-(i-1)*62);row:SetSize(574,60)
    row.bg=row:CreateTexture(nil,"BACKGROUND");row.bg:SetAllPoints();row.bg:SetColorTexture(1,0.78,0.34,0.035)
    row.stripe=row:CreateTexture(nil,"ARTWORK");row.stripe:SetPoint("TOPLEFT");row.stripe:SetPoint("BOTTOMLEFT");row.stripe:SetWidth(3)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
    row.icon=S.Icon(row,5,-5,48)
    row.text=S.Text(row,"",64,-8,295,"GameFontNormal",S.gold)
    row.detail=S.Text(row,"",64,-26,295,"GameFontHighlightSmall",S.muted)
    row.text:SetMaxLines(1);row.detail:SetMaxLines(1)
    row.reward=S.Text(row,"",64,-43,295,"GameFontHighlightSmall",S.muted);row.reward:SetMaxLines(1)
    row.cost=S.Text(row,"",370,-6,195,"GameFontHighlightSmall");row.cost:SetJustifyH("RIGHT")
    row:SetScript("OnClick",function(self,button)
      if F.ItemClick(self.entry.item.id,button)then return end
      F.selected[F.tab]=self.entry.item.id;F.Render()
    end)
    row.cost:SetSpacing(3)
    row.icon.selectItem=function()F.selected[F.tab]=row.entry.item.id;F.Render()end
    F.rows[i]=row
  end
  F.empty=S.Text(F.body,"",30,-160,520,"GameFontNormalLarge",S.gold);F.empty:SetJustifyH("CENTER")
  F.detailPanel=S.Panel(w,627,-221,387,415,true)
  F.detailScroll=CreateFrame("ScrollFrame",nil,F.detailPanel,"UIPanelScrollFrameTemplate")
  F.detailScroll:SetPoint("TOPLEFT",10,-10);F.detailScroll:SetPoint("BOTTOMRIGHT",-30,10)
  F.detailChild=CreateFrame("Frame",nil,F.detailScroll);F.detailChild:SetSize(340,390);F.detailScroll:SetScrollChild(F.detailChild)
  F.ScrollDetails=function(delta)
    local range=math.max(0,F.detailChild:GetHeight()-F.detailScroll:GetHeight())
    F.detailScroll:SetVerticalScroll(math.max(0,math.min(range,F.detailScroll:GetVerticalScroll()-delta*65)))
  end
  F.detailScroll:EnableMouseWheel(true)
  F.detailScroll:SetScript("OnMouseWheel",function(_,delta)F.ScrollDetails(delta)end)
  F.detailRows={}
  F.prev=S.Button(w,"Previous",24,-645,102,function()F.offset=math.max(0,(F.offset or 0)-pageSize);F.Render()end)
  F.next=S.Button(w,"Next",135,-645,102,function()F.offset=(F.offset or 0)+pageSize;F.Render()end)
  F.pageLabel=S.Text(w,"",257,-653,340,"GameFontHighlightSmall",S.muted)
  F.trackButton=S.Button(w,"Track delivery",627,-645,187,function()
    if F.detailEntry and F.detailEntry.stop then F.TrackDelivery(F.detailEntry.stop.questID) end
  end)
  F.mapButton=S.Button(w,"Show on map",827,-645,187,function()
    if F.detailEntry and F.detailEntry.stop then F.Navigate(F.detailEntry.stop.point,F.detailEntry.stop.questID) end
  end)
  F.footerNote=S.Text(w,"Personal & opt-in peer scans  •  market estimates, not guaranteed purchase prices",27,-684,730,"GameFontDisableSmall")
  F.versionLabel=S.Text(w,"v"..F.version,948,-684,65,"GameFontDisableSmall")
  F.settings=S.Panel(w,24,-221,990,415)
  S.Text(F.settings,"Make the ledger your own",25,-18,620,"GameFontNormalLarge",S.gold)
  S.Button(F.settings,"Accessibility",740,-14,220,function()F.accessibilityView=true;F.Render()end)
  F.BuildAccessibility(w)
  S.Text(F.settings,"TOOLTIPS & PRICES",25,-57,400,"GameFontNormalSmall",S.muted)
  S.Check(F.settings,"Show cheapest crate fill",23,-80,"cheapest")
  S.Check(F.settings,"Include crate price in tooltip totals",23,-110,"includeCrate")
  S.Check(F.settings,"Show every material's fill cost",23,-140,"allCosts")
  S.Check(F.settings,"Use personal scan prices",23,-170,"personal")
  S.Text(F.settings,"MAPS & TRAVEL",515,-57,400,"GameFontNormalSmall",S.muted)
  S.Check(F.settings,"Show the travel compass",513,-80,"navigator")
  S.Check(F.settings,"Show routes on the world map",513,-110,"worldRoute")
  S.Check(F.settings,"Show routes on the minimap",513,-140,"minimapRoute")
  S.Check(F.settings,"Consider my learned flight routes",513,-170,"flights")
  S.Check(F.settings,"AH tooltips on unrelated items",23,-200,"generalAuctionTooltips")
  S.Check(F.settings,"Auto-hide extras with another AH addon",23,-230,"autoHideAuction")
  S.Check(F.settings,"Debug: preview Alliance appearance",513,-200,"debugAlliance")
  F.auctionCompatibility=S.Text(F.settings,"",515,-239,440,"GameFontHighlightSmall",S.muted)
  S.Rule(F.settings,25,-268,934)
  local peerToggle=S.Check(F.settings,"Opt in: share scan prices with guild / party / raid",23,-279,"peerSharing")
  peerToggle:SetScript("OnClick",function(self)F.SetPeerSharing(not not self:GetChecked())end)
  F.peerStatus=S.Text(F.settings,"Peer sharing is off.",25,-311,476,"GameFontHighlightSmall",S.muted)
  S.Button(F.settings,"Read personal prices",515,-309,200,function()F.ImportPersonal();F.Refresh()end)
  S.Button(F.settings,"Reset compass position",727,-309,231,function()F.ResetNavigator()end)
  local footer=CreateFrame("Frame",nil,w);footer:SetPoint("TOPLEFT",24,-681);footer:SetSize(990,64)
  F.scanFooter=footer
  F.scanButton=S.Button(footer,"Scan AH prices",0,-3,170,F.StartNativeScan)
  F.cancelScanButton=S.Button(footer,"Cancel",180,-3,80,function()F.CancelNativeScan()end)
  F.scanStatus=S.Text(footer,"",180,-8,725,"GameFontHighlightSmall",S.muted)
  F.scanStatus:SetHeight(35)
  footer.progress=F.CreateScanProgressBar(footer,895);footer.progress:SetPoint("TOPLEFT",4,-47)
  footer.scribe=F.CreateScanScribe(footer,64)
  footer.scribe.art:ClearAllPoints();footer.scribe.art:SetPoint("BOTTOMRIGHT",0,0)
  footer:SetScript("OnUpdate",footer.scribe.animate)
  F.UpdateScanUI()
  S.Text(F.settings,"Debug changes appearance only. Auto-hide affects our Scan tab and unrelated AH tooltips; Waylaid details remain.\nPeer prices are unverified and expire after 24 hours. Sharing sends observed prices, stock and scan times.",25,-354,920,"GameFontHighlightSmall",S.muted)
  w:EnableMouseWheel(true);w:SetScript("OnMouseWheel",function(_,delta)
    if F.detailPanel:IsMouseOver() and F.tab~="Settings" then F.ScrollDetails(delta);return end
    if F.tab~="Settings" then F.offset=math.max(0,math.min(F.lastPage or 0,(F.offset or 0)-delta*pageSize));F.Render()end
  end)
  w:SetScript("OnShow",F.Refresh);UISpecialFrames[#UISpecialFrames+1]="ForeverWaylaidFrame";w:Hide()
end

local function detailWriter()
  for _,row in ipairs(F.detailRows) do row:Hide() end
  local index,y=0,0
  return function(title,description,icon,amount,heading)
    index=index+1;local row=F.detailRows[index]
    if not row then
      row=CreateFrame("Frame",nil,F.detailChild);row:SetWidth(340)
      row.icon=S.Icon(row,0,-3,34)
      row.title=S.Text(row,"",43,-5,286,"GameFontNormal",S.ink)
      row.description=S.Text(row,"",43,-25,288,"GameFontHighlightSmall",{0.36,0.26,0.14})
      row.amount=S.Text(row,"",222,-5,112,"GameFontHighlight",S.ink);row.amount:SetJustifyH("RIGHT")
      F.detailRows[index]=row
    end
    local height=heading and 58 or (icon and 43 or description and 42 or 25)
    row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-y);row:SetHeight(height);row:Show();row.icon:SetShown(icon~=nil)
    row.title:ClearAllPoints();row.title:SetPoint("TOPLEFT",icon and 43 or 4,-5);row.title:SetWidth(amount and 170 or (icon and 286 or 326))
    S.ReadableFont(row.title,heading and "GameFontNormalLarge" or "GameFontNormal");S.TextColor(row.title,S.ink);row.title:SetText(title)
    local cargo=icon and (F.cratesByID[icon] or F.writsByID[icon])
    row.title:SetShadowColor(0,0,0,cargo and 1 or 0);row.title:SetShadowOffset(1,-1)
    if cargo then local r,g,b=S.RarityColor(icon);S.TextColor(row.title,{r,g,b})end
    row.description:ClearAllPoints();row.description:SetPoint("TOPLEFT",icon and 43 or 4,heading and -43 or -26);row.description:SetWidth(icon and 286 or 326);row.description:SetText(description or "")
    row.amount:SetText(amount or "");if icon then S.SetIcon(row.icon,icon)end
    local titleHeight=row.title:GetStringHeight() or 16
    local descriptionTop=titleHeight+9
    row.description:ClearAllPoints();row.description:SetPoint("TOPLEFT",icon and 43 or 4,-descriptionTop)
    height=math.max(height,description and descriptionTop+(row.description:GetStringHeight() or 14)+9 or titleHeight+10)
    row:SetHeight(height)
    y=y+height;F.detailChild:SetHeight(math.max(390,y+8))
  end
end
local function sourceText(quote)
  return quote and quote.source.." • "..S.Age(quote.time) or "No price available"
end
local function itemLevel(item)
  if item.level then return "Requires level "..item.level end
  local info=C_Item and C_Item.GetItemInfo or GetItemInfo
  if info then
    local name,_,_,_,level=info(item.id)
    if name and level then return level>0 and "Requires level "..level or "No item level requirement" end
  end
  return "Required level not cached"
end
function F.RenderDetail(entry)
  local craftMode=F.db.settings.craftGoods
  local detailKey=F.tab..":"..tostring(entry and entry.item.id)..":"..tostring(craftMode)
  if F.detailKey~=detailKey then F.detailScroll:SetVerticalScroll(0);F.detailKey=detailKey end
  local add=detailWriter();F.detailEntry=entry
  F.trackButton:SetShown(entry and entry.stop~=nil);F.mapButton:SetShown(entry and entry.stop~=nil)
  F.mapButton:SetEnabled(entry and entry.stop and entry.stop.point~=nil)
  if not entry then add("A page waiting to be filled","Select a crate or writ to inspect its requirements.",nil,nil,true);return end
  local item=entry.item
  if item.questId and not entry.goods then
    entry.goods,entry.quote=F.GoodsQuote(item.targetId,item.qty);entry.cost=entry.goods.cost
  end
  F.PriceEntry(entry)
  local craft=craftMode and (item.questId and entry.goods or entry.best and entry.best.craft)
  local reward=(item.rep or item.favor or 0)..(item.questId and " reputation" or " favor")
  add(short(item.name),reward.." • "..itemLevel(item),item.id,nil,true)
  if craft then add(#craft.steps>0 and "To craft" or "Sourcing",F.CraftRequirements(craft))end
  add(item.questId and "Writ" or "Crate",nil,nil,S.Money(entry.purchase and entry.purchase.price))
  add(craftMode and "Goods (craft)" or "Goods (AH)",nil,nil,S.Money(entry.cost))
  add("Total",nil,nil,S.Money(entry.total))
  local value=entry.band and F.valueLabels[entry.band] or entry.fullyPriced and "Stock incomplete / value unverified" or "Missing price"
  add(value,entry.total and "Full purchase value • "..S.Money(entry.total/math.max(1,item.rep or item.favor or 1))..(item.questId and " / rep" or " / favor") or "Both the writ/crate and goods need a price.")
  local function craftDetails(quote)
    if not quote then return end
    if quote.reason then add("Availability",quote.reason)end
    if #quote.steps==0 then return end
    add("Materials to source",nil)
    for _,mat in ipairs(quote.materials)do
      local count=S.Count(mat.itemId)
      add(mat.qty.." × "..mat.name,"Bags "..count.." • need "..math.max(0,mat.qty-count).." • "..mat.source,mat.itemId,S.Money(mat.cost))
    end
    add("Craft in order","Requires learned recipes"..(quote.variableYield and " • minimum yields used" or ""))
    for n,step in ipairs(quote.steps)do
      add(n..". "..step.crafts.." × "..step.name,step.profession.." • makes "..step.crafts*step.outputMin,step.itemId)
    end
  end
  if not item.questId then
    add("Choose one bundle",entry.best and "Total uses the selected bundle below." or "No bundle is priced yet.")
    for _,row in ipairs(entry.rows)do
      local option=row.option
      add(option.qty.." × "..option.name,(row==entry.best and "SELECTED • " or "").."Bags "..S.Count(option.itemId).." / "..option.qty..(row.enough and "" or " • price / stock incomplete"),option.itemId,S.Money(row.cost))
      if craftMode then
        if row~=entry.best and #row.craft.steps>0 then add("To craft this bundle",F.CraftRequirements(row.craft))end
        craftDetails(row.craft)
      end
    end
  else
    add(item.qty.." × "..item.targetName,"Deliver • bags "..S.Count(item.targetId).." / "..item.qty,item.targetId)
    if craftMode then craftDetails(craft)
    elseif entry.goods.reason then add("Availability",entry.goods.reason)end
    if entry.stop then
      local stop=entry.stop
      add(stop.ready and "Ready for delivery" or "Accepted • gather goods",(stop.npc or stop.deliveryText or "Recipient unknown").."\n"..F.DestinationText(stop.point))
      if entry.leg then
        add("Travel plan","~"..math.ceil(entry.leg.seconds/60).." min • estimate")
        for _,step in ipairs(entry.leg.steps)do
          if step.mode=="Fly" then add("Fly",(step.from.name or "Flight master").." → "..(step.to.name or "Destination"))end
        end
      end
      if not stop.point then add("Set the customer pin","/fwl pin "..stop.questID.." MAP_ID X Y")end
    else add("Not accepted","Open the writ in your bags to start its route.")end
  end
  local quote=entry.quote or entry.best and entry.best.quote
  local sources=(item.questId and "Writ: " or "Crate: ")..sourceText(entry.purchase)
  if not craftMode then sources=sources.."\nGoods: "..sourceText(quote)end
  add("Price sources",sources)
end

function F.Render()
  pageSize=S.MinimumTextSize()>=16 and 5 or 6
  if not F.window then return end
  F.craftButton:SetText(F.db.settings.craftGoods and "Goods: Craft" or "Goods: Buy at AH")
  F.status:SetText(F.char.realm.." • "..UnitFactionGroup("player").."\nPersonal scans"..(F.db.settings.peerSharing and " + unverified peer prices" or " • peer sharing off"))
  F.factionTitle:SetText(S.Faction()=="Horde" and "DUROTAR SUPPLY & LOGISTICS  /  FIELD LEDGER" or "AZEROTH COMMERCE AUTHORITY  /  FIELD LEDGER")
  local settings=F.tab=="Settings"
  F.settings:SetShown(settings and not F.accessibilityView);F.accessibility:SetShown(settings and F.accessibilityView);F.body:SetShown(not settings);F.detailPanel:SetShown(not settings)
  F.filters:SetShown(F.tab=="Crates" or F.tab=="Writs")
  F.prev:SetShown(not settings);F.next:SetShown(not settings);F.pageLabel:SetShown(not settings)
  for tab,b in pairs(F.tabButtons) do b:SetEnabled(tab~=F.tab)end
  local ready=0;for _,stop in ipairs(F.active or {})do if stop.ready then ready=ready+1 end end
  local flightCount=0;for _ in pairs(F.char.flights.nodes)do flightCount=flightCount+1 end
  local stats={{"YOUR DELIVERY BOOK",#(F.active or {}).." accepted writs"},{"READY TO HAND IN",ready.." customers waiting"},{"KNOWN FLIGHT POINTS",flightCount.." destinations"},{"PLANNED JOURNEY","~"..math.ceil((F.routeSeconds or 0)/60).." min • estimate"}}
  if F.NeedsFlightScan()then stats[3]={S.MinimumTextSize()>=16 and "FLIGHTS NOT SCANNED" or "FLIGHT PATHS NOT SCANNED","Visit a flight master"}end
  for i,stat in ipairs(stats)do F.stats[i].caption:SetText(stat[1]);F.stats[i].value:SetText(stat[2])end
  local missing=F.MissingFlightContinents()
  F.flightWarning:SetShown(#missing>0)
  F.stats[3].value:SetWidth(#missing>0 and 185 or 214)
  S.TextColor(F.stats[3].caption,F.NeedsFlightScan() and S.gold or S.muted)
  if settings then F.trackButton:Hide();F.mapButton:Hide();return end
  F.tierButton:SetShown(F.tab=="Crates");F.tierButton:SetText("Tier: "..(tiers[F.tierIndex or 1] or "All"))
  F.sortButton:SetText("Sort: "..({"Best value","Lowest total","Name"})[F.sortIndex or 1])
  F.ownedButton:SetText(F.onlyOwned and "Show: My cargo" or "Show: All")
  local entries=F.LedgerEntries();F.entries=entries
  F.lastPage=math.max(0,math.floor((#entries-1)/pageSize)*pageSize);F.offset=math.min(F.offset or 0,F.lastPage)
  F.listTitle:SetText(F.tab=="Route" and "YOUR DELIVERY ITINERARY" or F.tab:upper().."  /  "..#entries.." entries  /  click to inspect")
  local selected
  for _,e in ipairs(entries)do if e.item.id==F.selected[F.tab] then selected=e end end
  selected=selected or entries[F.offset+1];F.selected[F.tab]=selected and selected.item.id
  for i,row in ipairs(F.rows)do
    local large=S.MinimumTextSize()>=16
    row:ClearAllPoints();row:SetPoint("TOPLEFT",7,-31-(i-1)*(large and 74 or 62));row:SetHeight(large and 72 or 60)
    row.detail:ClearAllPoints();row.detail:SetPoint("TOPLEFT",64,large and -30 or -26)
    row.reward:ClearAllPoints();row.reward:SetPoint("TOPLEFT",64,large and -52 or -43)
    local entry=i<=pageSize and entries[F.offset+i] or nil;row:SetShown(entry~=nil)
    if entry then
      row.entry=entry;row.itemID=entry.item.id;S.SetIcon(row.icon,entry.item.id)
      local r,g,b=S.RarityColor(entry.item.id)
      S.TextColor(row.text,{r,g,b})
      local color=entry.band and F.valueColors[entry.band] or neutral
      if S.HighContrast() then row.bg:SetColorTexture(1,1,1,entry==selected and 0.2 or 0.025)
      else row.bg:SetColorTexture(color[1],color[2],color[3],entry==selected and 0.27 or 0.11)end
      if S.HighContrast() then row.stripe:SetColorTexture(1,1,1,entry==selected and 1 or 0.3)
      else row.stripe:SetColorTexture(color[1],color[2],color[3],1)end
      row.text:SetText((entry.index and entry.index..". " or "")..short(entry.item.name))
      if F.tab=="Route" then
        S.TextColor(row.reward,S.muted)
        row.cost:SetText(entry.leg and "~"..math.ceil(entry.leg.seconds/60).." min" or "Needs location")
        row.detail:SetText(entry.stop.npc or entry.stop.deliveryText or F.DestinationText(entry.stop.point))
        row.reward:SetText(entry.stop.ready and (S.HighContrast() and "Ready" or "|cff88cc77Ready|r") or "Preparing")
      else
        row.cost:SetText((entry.item.questId and "Writ " or "Crate ")..S.Money(entry.purchase and entry.purchase.price).."\nGoods "..S.Money(entry.cost).."\nTotal "..S.Money(entry.total))
        row.detail:SetText(entry.best and entry.best.option.qty.." × "..entry.best.option.name or entry.item.questId and entry.item.qty.." × "..entry.item.targetName or "Price missing / short stock")
        local status=entry.stop and (entry.stop.ready and " • Ready" or " • Accepted") or ""
        row.reward:SetText((entry.reward or 0)..(F.tab=="Crates" and " favor" or " rep").." • "..(entry.band and F.valueLabels[entry.band] or entry.fullyPriced and "Stock / value unverified" or "Unpriced")..status)
        S.TextColor(row.reward,entry.band and F.valueColors[entry.band] or neutral)
      end
    end
  end
  F.empty:SetShown(#entries==0);F.empty:SetText(F.tab=="Route" and "No deliveries yet\n\nAccept a writ to begin your journey." or "No cargo matches these filters.")
  F.prev:SetEnabled(F.offset>0);F.next:SetEnabled(F.offset<F.lastPage)
  F.pageLabel:SetText("Page "..(math.floor(F.offset/pageSize)+1).." / "..(math.floor(F.lastPage/pageSize)+1).."   •   scroll to browse")
  F.RenderDetail(selected)
end
