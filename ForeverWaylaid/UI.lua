local _,F=...
local S=F.Style
local pageSize=6
local tiers={"All tiers","Apprentice","Journeyman","Expert","Artisan"}
local function short(name) return name:gsub("^Waylaid Crate: ",""):gsub("^Craftsman's Writ: ","") end
local function match(text,query) return query=="" or text:lower():find(query,1,true) end

function F.LedgerEntries()
  local entries={};local query=(F.searchText or ""):lower();local active={}
  for _,stop in ipairs(F.active or {}) do active[stop.questID]=stop end
  if F.tab=="Crates" then
    for _,item in ipairs(F.catalog.crates) do
      local rows,best=F.CrateCosts(item,false);local hay=item.name
      for _,o in ipairs(item.options) do hay=hay.." "..o.name end
      if match(hay,query) and (not F.tierIndex or F.tierIndex==1 or item.tier==tiers[F.tierIndex]) and
        (not F.onlyOwned or S.Count(item.id)>0) then
        entries[#entries+1]={item=item,rows=rows,best=best,cost=best and best.cost,reward=item.favor,owned=S.Count(item.id)}
      end
    end
  elseif F.tab=="Writs" then
    for _,item in ipairs(F.catalog.writs) do
      if match(item.name.." "..item.targetName,query) and (not F.onlyOwned or active[item.questId] or S.Count(item.id)>0) then
        local quote=F.Price(item.targetId)
        entries[#entries+1]={item=item,cost=quote and quote.price*item.qty,reward=item.rep,quote=quote,stop=active[item.questId],owned=S.Count(item.id)}
      end
    end
  elseif F.tab=="Route" then
    for index,leg in ipairs(F.route or {}) do entries[#entries+1]={item=leg.stop.writ,stop=leg.stop,leg=leg,index=index} end
    for _,stop in ipairs(F.unresolved or {}) do entries[#entries+1]={item=stop.writ,stop=stop} end
    return entries
  end
  table.sort(entries,function(a,b)
    if F.tab=="Writs" and (a.stop~=nil)~=(b.stop~=nil) then return a.stop~=nil end
    if F.sortIndex==3 then return a.item.name<b.item.name end
    local av,bv=a.cost or math.huge,b.cost or math.huge
    if F.sortIndex~=2 then av=av/(a.reward or 1);bv=bv/(b.reward or 1) end
    if av==bv then return a.item.id<b.item.id end
    return av<bv
  end)
  return entries
end

local function showItem(row)
  if row.itemID then GameTooltip:SetOwner(row,"ANCHOR_RIGHT");GameTooltip:SetHyperlink("item:"..row.itemID) end
end
function F.BuildUI()
  local w=CreateFrame("Frame","ForeverWaylaidFrame",UIParent,"BackdropTemplate");F.window=w
  w:SetSize(1040,704);w:SetPoint("CENTER");w:SetFrameStrata("HIGH")
  w:SetScale(math.min(1,(UIParent:GetWidth()-40)/1040,(UIParent:GetHeight()-40)/704))
  w:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=10,right=10,top=10,bottom=10}})
  w:SetBackdropBorderColor(0.86,0.72,0.46,1)
  local backing=w:CreateTexture(nil,"BACKGROUND",nil,-8);backing:SetPoint("TOPLEFT",10,-10);backing:SetPoint("BOTTOMRIGHT",-10,10);backing:SetColorTexture(0.055,0.039,0.025,0.98)
  w:EnableMouse(true);w:SetMovable(true);w:SetClampedToScreen(true);w:RegisterForDrag("LeftButton")
  w:SetScript("OnDragStart",w.StartMoving);w:SetScript("OnDragStop",w.StopMovingOrSizing)
  S.Icon(w,23,-18,58,nil,S.icons.crate)
  S.Text(w,"FOREVER WAYLAID",94,-22,470,"GameFontNormalHuge",S.gold)
  F.factionTitle=S.Text(w,"THE MERCHANT'S FIELD LEDGER",95,-49,500,"GameFontHighlightSmall",S.muted)
  local close=CreateFrame("Button",nil,w,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-7,-7)
  F.status=S.Text(w,"",660,-37,343,"GameFontHighlightSmall",S.muted);F.status:SetJustifyH("RIGHT")
  F.tab="Crates";F.sortIndex=1;F.tierIndex=1;F.selected={};F.tabButtons={}
  for i,tab in ipairs({"Crates","Writs","Route","Settings"}) do
    F.tabButtons[tab]=S.Button(w,tab,24+(i-1)*154,-82,144,function()F.tab=tab;F.offset=0;F.Render()end)
  end
  S.Button(w,"Travel compass",844,-82,168,function()F.db.settings.navigator=not F.db.settings.navigator;F.UpdateNavigator()end)
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
  F.body=S.Panel(w,24,-221,588,415);F.listTitle=S.Text(F.body,"",12,-11,550,"GameFontNormalSmall",S.gold)
  F.rows={}
  for i=1,pageSize do
    local row=CreateFrame("Button",nil,F.body);row:SetPoint("TOPLEFT",7,-31-(i-1)*62);row:SetSize(574,60)
    row.bg=row:CreateTexture(nil,"BACKGROUND");row.bg:SetAllPoints();row.bg:SetColorTexture(1,0.78,0.34,0.035)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
    row.icon=S.Icon(row,5,-5,48)
    row.text=S.Text(row,"",64,-8,327,"GameFontNormal",S.gold)
    row.detail=S.Text(row,"",64,-28,340,"GameFontHighlightSmall",S.muted)
    row.text:SetMaxLines(1);row.detail:SetMaxLines(2)
    row.reward=S.Text(row,"",421,-33,144,"GameFontHighlightSmall",S.muted);row.reward:SetJustifyH("RIGHT")
    row.cost=S.Text(row,"",399,-9,166,"GameFontHighlight");row.cost:SetJustifyH("RIGHT")
    row:SetScript("OnClick",function(self)F.selected[F.tab]=self.entry.item.id;F.Render()end)
    row:SetScript("OnEnter",showItem);row:SetScript("OnLeave",function()GameTooltip:Hide()end)
    F.rows[i]=row
  end
  F.empty=S.Text(F.body,"",30,-160,520,"GameFontNormalLarge",S.gold);F.empty:SetJustifyH("CENTER")
  F.detailPanel=S.Panel(w,627,-221,387,415,true)
  F.detailScroll=CreateFrame("ScrollFrame",nil,F.detailPanel,"UIPanelScrollFrameTemplate")
  F.detailScroll:SetPoint("TOPLEFT",10,-10);F.detailScroll:SetPoint("BOTTOMRIGHT",-30,10)
  F.detailChild=CreateFrame("Frame",nil,F.detailScroll);F.detailChild:SetSize(340,390);F.detailScroll:SetScrollChild(F.detailChild)
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
  S.Text(w,"AHledger.com  •  market estimates, not guaranteed purchase prices",27,-684,730,"GameFontDisableSmall")
  S.Text(w,"v"..F.version,948,-684,65,"GameFontDisableSmall")
  F.settings=S.Panel(w,24,-221,990,415)
  S.Text(F.settings,"Make the ledger your own",25,-18,800,"GameFontNormalLarge",S.gold)
  S.Text(F.settings,"TOOLTIPS & PRICES",25,-57,400,"GameFontNormalSmall",S.muted)
  S.Check(F.settings,"Show cheapest crate fill",23,-80,"cheapest")
  S.Check(F.settings,"Include crate price in tooltip totals",23,-115,"includeCrate")
  S.Check(F.settings,"Show every material's fill cost",23,-150,"allCosts")
  S.Check(F.settings,"Use my Auctionator / Auctioneer scans",23,-185,"personal")
  S.Text(F.settings,"MAPS & TRAVEL",515,-57,400,"GameFontNormalSmall",S.muted)
  S.Check(F.settings,"Show the travel compass",513,-80,"navigator")
  S.Check(F.settings,"Show routes on the world map",513,-115,"worldRoute")
  S.Check(F.settings,"Show routes on the minimap",513,-150,"minimapRoute")
  S.Check(F.settings,"Consider my learned flight routes",513,-185,"flights")
  S.Rule(F.settings,25,-232,934)
  S.Text(F.settings,"Choose the AHledger market matching your realm",25,-252,850,"GameFontNormal",S.gold)
  for i,ruleset in ipairs({"pvp","normal","rp"}) do
    S.Button(F.settings,ruleset:upper(),25+(i-1)*112,-282,102,function()F.char.ruleset=ruleset;F.Refresh()end)
  end
  S.Button(F.settings,"Read personal prices",515,-282,200,function()F.ImportPersonal();F.Refresh()end)
  S.Button(F.settings,"Reset compass position",727,-282,231,function()F.ResetNavigator()end)
  S.Text(F.settings,"The addon works on its own. The optional helper only refreshes AHledger snapshots.\nScan in a faction capital with Auctionator, or use Auctioneer's saved prices.",25,-337,920,"GameFontHighlight",S.muted)
  w:EnableMouseWheel(true);w:SetScript("OnMouseWheel",function(_,delta)
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
    local height=heading and 67 or (description and description:find("\n",1,true) and 69 or 51)
    row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-y);row:SetHeight(height);row:Show();row.icon:SetShown(icon~=nil)
    row.title:ClearAllPoints();row.title:SetPoint("TOPLEFT",icon and 43 or 4,-5);row.title:SetWidth(amount and 170 or (icon and 286 or 326))
    row.title:SetFontObject(heading and "GameFontNormalLarge" or "GameFontNormal");row.title:SetTextColor(unpack(S.ink));row.title:SetText(title)
    row.description:ClearAllPoints();row.description:SetPoint("TOPLEFT",icon and 43 or 4,heading and -43 or -26);row.description:SetWidth(icon and 286 or 326);row.description:SetText(description or "")
    row.amount:SetText(amount or "");if icon then S.SetIcon(row.icon,icon)end
    local titleHeight=row.title:GetStringHeight() or 16
    local descriptionTop=math.max(heading and 43 or 26,titleHeight+10)
    row.description:ClearAllPoints();row.description:SetPoint("TOPLEFT",icon and 43 or 4,-descriptionTop)
    height=math.max(height,descriptionTop+(row.description:GetStringHeight() or 14)+10)
    row:SetHeight(height)
    y=y+height;F.detailChild:SetHeight(math.max(390,y+8))
  end
end
function F.RenderDetail(entry)
  local detailKey=F.tab..":"..tostring(entry and entry.item.id)
  if F.detailKey~=detailKey then F.detailScroll:SetVerticalScroll(0);F.detailKey=detailKey end
  local add=detailWriter();F.detailEntry=entry
  F.trackButton:SetShown(entry and entry.stop~=nil);F.mapButton:SetShown(entry and entry.stop~=nil)
  F.mapButton:SetEnabled(entry and entry.stop and entry.stop.point~=nil)
  if not entry then add("A page waiting to be filled","Select a crate or writ to inspect its requirements.",nil,nil,true);return end
  local item=entry.item
  add(short(item.name),item.questId and "CRAFTSMAN'S WRIT" or (item.tier:upper().." SUPPLY CRATE"),item.id,nil,true)
  if not item.questId then
    add("Merchant's Favor",(item.favor or 0).." favor per turn-in • requires level "..(item.level or "?"))
    local crate=F.Price(item.id);local total=entry.cost and (entry.owned>0 and entry.cost or crate and entry.cost+crate.price)
    add("Best fill",entry.best and (entry.best.option.qty.." × "..entry.best.option.name) or "No fully priced, sufficiently stocked option",nil,S.Money(entry.cost))
    add(entry.owned>0 and "Total • crate in your bags" or "Total • buy crate + fill",entry.cost and "Fill / favor: "..S.Money(entry.cost/item.favor) or "Some prices are unavailable",nil,S.Money(total))
    add("Choose your cargo","Each option below fills this crate on its own.")
    for _,row in ipairs(entry.rows) do
      local quote=row.quote;local status=quote and (quote.quantity and quote.quantity.." listed" or "stock unknown") or "No market price"
      add(row.option.qty.." × "..row.option.name,"Bags: "..S.Count(row.option.itemId).." • "..status..(row==entry.best and " • BEST FILL" or ""),row.option.itemId,S.Money(row.cost))
      if quote then add(quote.source,S.Age(quote.time)..(row.enough and " • observed stock covers this fill" or " • not enough observed stock"))end
    end
  else
    add("Reputation reward",item.rep.." reputation • keep the writ in your bags")
    add("Required goods",S.Count(item.targetId).." / "..item.qty.." in bags",item.targetId,S.Money(entry.cost or (F.Price(item.targetId) and F.Price(item.targetId).price*item.qty)))
    local quote=entry.quote or F.Price(item.targetId)
    if quote then add("Market estimate",quote.source.." • "..S.Age(quote.time).."\n"..(quote.quantity and quote.quantity.." units listed" or "Stock unknown"),nil,S.Money(quote.price*item.qty/item.rep).." / rep")end
    if entry.stop then
      local stop=entry.stop
      add(stop.ready and "Ready for delivery" or "Gather the requested goods",stop.ready and "Your customer is waiting." or "The route stays in your ledger while you prepare.")
      add("Recipient",stop.npc or stop.deliveryText or "Customer name not supplied by this quest")
      add("Destination",F.DestinationText(stop.point))
      if entry.leg then
        add("Travel plan","~"..math.ceil(entry.leg.seconds/60).." min • estimated travel time")
        for _,step in ipairs(entry.leg.steps) do
          if step.mode=="Fly" then add("Take a flight",(step.from.name or "Flight master").." → "..(step.to.name or "Destination"))end
        end
      end
      if not stop.point then add("Set the customer pin","/fwl pin "..stop.questID.." MAP_ID X Y\nUse the delivery location shown by your quest.")end
    else add("Not accepted yet","Open this writ in your bags to add its delivery to the route.") end
  end
end

function F.Render()
  if not F.window then return end
  local market=F.Market();local feed=market and F.bundledPrices[market]
  F.status:SetText((market or "Choose your market in Settings").."\n"..(feed and "AHledger snapshot • "..S.Age(feed.time) or "Personal scans available • no AHledger snapshot"))
  F.factionTitle:SetText(UnitFactionGroup("player")=="Horde" and "DUROTAR SUPPLY & LOGISTICS  /  FIELD LEDGER" or "AZEROTH COMMERCE AUTHORITY  /  FIELD LEDGER")
  local settings=F.tab=="Settings"
  F.settings:SetShown(settings);F.body:SetShown(not settings);F.detailPanel:SetShown(not settings)
  F.filters:SetShown(F.tab=="Crates" or F.tab=="Writs")
  F.prev:SetShown(not settings);F.next:SetShown(not settings);F.pageLabel:SetShown(not settings)
  for tab,b in pairs(F.tabButtons) do b:SetEnabled(tab~=F.tab)end
  local ready=0;for _,stop in ipairs(F.active or {})do if stop.ready then ready=ready+1 end end
  local flightCount=0;for _ in pairs(F.char.flights.nodes)do flightCount=flightCount+1 end
  local stats={{"YOUR DELIVERY BOOK",#(F.active or {}).." accepted writs"},{"READY TO HAND IN",ready.." customers waiting"},{"KNOWN FLIGHT POINTS",flightCount.." destinations"},{"PLANNED JOURNEY","~"..math.ceil((F.routeSeconds or 0)/60).." min • estimate"}}
  for i,stat in ipairs(stats)do F.stats[i].caption:SetText(stat[1]);F.stats[i].value:SetText(stat[2])end
  if settings then F.trackButton:Hide();F.mapButton:Hide();return end
  F.tierButton:SetShown(F.tab=="Crates");F.tierButton:SetText("Tier: "..(tiers[F.tierIndex or 1] or "All"))
  F.sortButton:SetText("Sort: "..({"Best value","Lowest fill","Name"})[F.sortIndex or 1])
  F.ownedButton:SetText(F.onlyOwned and "Show: My cargo" or "Show: All")
  local entries=F.LedgerEntries();F.entries=entries
  F.lastPage=math.max(0,math.floor((#entries-1)/pageSize)*pageSize);F.offset=math.min(F.offset or 0,F.lastPage)
  F.listTitle:SetText(F.tab=="Route" and "YOUR DELIVERY ITINERARY" or F.tab:upper().."  /  "..#entries.." entries  /  click to inspect")
  local selected
  for _,e in ipairs(entries)do if e.item.id==F.selected[F.tab] then selected=e end end
  selected=selected or entries[F.offset+1];F.selected[F.tab]=selected and selected.item.id
  for i,row in ipairs(F.rows)do
    local entry=entries[F.offset+i];row:SetShown(entry~=nil)
    if entry then
      row.entry=entry;row.itemID=entry.item.id;S.SetIcon(row.icon,entry.item.id)
      row.bg:SetColorTexture(1,0.72,0.23,entry==selected and 0.19 or (i%2==0 and 0.045 or 0.018))
      row.text:SetText((entry.index and entry.index..". " or "")..short(entry.item.name))
      if F.tab=="Route" then
        row.cost:SetText(entry.leg and "~"..math.ceil(entry.leg.seconds/60).." min" or "Needs location")
        row.detail:SetText(entry.stop.npc or entry.stop.deliveryText or F.DestinationText(entry.stop.point))
        row.reward:SetText(entry.stop.ready and "|cff88cc77Ready|r" or "Preparing")
      else
        row.cost:SetText(S.Money(entry.cost))
        row.detail:SetText(entry.best and entry.best.option.qty.." × "..entry.best.option.name or entry.item.questId and entry.item.qty.." × "..entry.item.targetName or "Price missing / short stock")
        row.reward:SetText(entry.stop and (entry.stop.ready and "|cff88cc77Ready to deliver|r" or "|cffffd36aAccepted|r") or (entry.reward or 0)..(F.tab=="Crates" and " favor" or " reputation"))
      end
    end
  end
  F.empty:SetShown(#entries==0);F.empty:SetText(F.tab=="Route" and "No deliveries yet\n\nAccept a writ to begin your journey." or "No cargo matches these filters.")
  F.prev:SetEnabled(F.offset>0);F.next:SetEnabled(F.offset<F.lastPage)
  F.pageLabel:SetText("Page "..(math.floor(F.offset/pageSize)+1).." / "..(math.floor(F.lastPage/pageSize)+1).."   •   scroll to browse")
  F.RenderDetail(selected)
end
