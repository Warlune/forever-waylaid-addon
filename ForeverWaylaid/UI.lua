local _, F = ...
local gold, muted = "|cffffd36a", "|cffaaaaaa"
local function label(parent, text, x, y, font)
  local l = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
  l:SetPoint("TOPLEFT", x, y); l:SetText(text); return l
end
local function button(parent, text, x, y, width, callback)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 24); b:SetPoint("TOPLEFT", x, y); b:SetText(text); b:SetScript("OnClick", callback); return b
end
local function check(parent, text, x, y, key)
  local b = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  b:SetPoint("TOPLEFT", x, y); b:SetSize(26,26)
  label(b, text, 30, -7, "GameFontHighlightSmall")
  b:SetScript("OnShow", function(self) self:SetChecked(F.db.settings[key]) end)
  b:SetScript("OnClick", function(self) F.db.settings[key] = self:GetChecked(); F.Refresh() end)
  return b
end
function F.BuildUI()
  local w = CreateFrame("Frame", "ForeverWaylaidFrame", UIParent, "BackdropTemplate")
  F.window = w; w:SetSize(770,580); w:SetPoint("CENTER"); w:SetFrameStrata("DIALOG")
  w:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=32, insets={left=10,right=10,top=10,bottom=10}})
  w:EnableMouse(true); w:SetMovable(true); w:SetClampedToScreen(true); w:RegisterForDrag("LeftButton")
  w:SetScript("OnDragStart", w.StartMoving); w:SetScript("OnDragStop", w.StopMovingOrSizing)
  local close = CreateFrame("Button", nil, w, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -6,-6)
  label(w, "FOREVER WAYLAID", 26,-24, "GameFontNormalLarge")
  label(w, "Crates, customers & the road between them", 27,-48,"GameFontHighlightSmall")
  F.status = label(w, "", 27,-102,"GameFontHighlightSmall"); F.status:SetWidth(712); F.status:SetJustifyH("LEFT")
  F.tab = "Crates"
  for i, title in ipairs({"Crates", "Writs", "Route", "Settings"}) do
    button(w, title, 26+(i-1)*126,-70,118,function() F.tab=title; F.offset=0; F.Render() end)
  end
  F.body = CreateFrame("Frame",nil,w); F.body:SetPoint("TOPLEFT",26,-144); F.body:SetSize(716,350)
  F.rows={}
  for i=1,8 do
    local row = CreateFrame("Button",nil,F.body); row:SetSize(716,40); row:SetPoint("TOPLEFT",0,-(i-1)*43)
    local bg = row:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1,0.8,0.4,i%2 == 1 and 0.05 or 0.02)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.text=label(row,"",8,-4,"GameFontHighlight"); row.text:SetWidth(696); row.text:SetJustifyH("LEFT")
    row.detail=label(row,"",8,-22,"GameFontHighlightSmall"); row.detail:SetWidth(696); row.detail:SetJustifyH("LEFT")
    row:SetScript("OnClick",function(self) if self.action then self.action() end end)
    row:SetScript("OnEnter",function(self)
      if self.itemID then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetHyperlink("item:"..self.itemID) end
    end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    F.rows[i]=row
  end
  F.prev=button(w,"Previous",26,-508,95,function() F.offset=math.max(0,(F.offset or 0)-8); F.Render() end)
  F.next=button(w,"Next",128,-508,95,function() F.offset=(F.offset or 0)+8; F.Render() end)
  F.pageLabel=label(w,"",238,-515,"GameFontHighlightSmall")
  button(w,"Recalculate",619,-508,122,function() F.Refresh() end)
  label(w,"AHledger.com · price & travel estimates · v0.1.0",27,-550,"GameFontDisableSmall")
  F.settings=CreateFrame("Frame",nil,w); F.settings:SetAllPoints(F.body)
  label(F.settings,"Tooltip options",8,0)
  check(F.settings,"Show cheapest fill cost",8,-28,"cheapest")
  check(F.settings,"Include crate purchase price in fill totals",8,-61,"includeCrate")
  check(F.settings,"Show all fill costs and each material",8,-94,"allCosts")
  check(F.settings,"Use my Auctionator / Auctioneer scans",8,-127,"personal")
  check(F.settings,"Use learned flight routes",8,-160,"flights")
  label(F.settings,"AHledger market (your character's faction is automatic)",8,-211)
  for i, ruleset in ipairs({"pvp","normal","rp"}) do
    button(F.settings,ruleset:upper(),8+(i-1)*114,-237,105,function() F.char.ruleset=ruleset; F.Refresh() end)
  end
  button(F.settings,"Read personal prices",8,-282,185,function() F.ImportPersonal(); F.Refresh() end)
  button(F.settings,"Forget learned flights",211,-282,190,function() F.char.flights={nodes={},edges={}}; F.Refresh() end)
  label(F.settings,"Update AHledger with the companion tool, then /reload. No upload is required.",8,-325,"GameFontHighlightSmall")
  w:EnableMouseWheel(true)
  w:SetScript("OnMouseWheel",function(_,delta)
    if F.tab ~= "Settings" then F.offset=math.max(0,math.min(F.lastPage or 0,(F.offset or 0)-delta*8)); F.Render() end
  end)
  w:SetScript("OnShow",F.Refresh)
  -- Recalculate after movement, with no per-frame graph work while hidden.
  local elapsed=0
  w:SetScript("OnUpdate",function(_,dt) elapsed=elapsed+dt; if elapsed>5 then elapsed=0; if F.tab=="Route" then F.Refresh() end end end)
  UISpecialFrames[#UISpecialFrames+1]="ForeverWaylaidFrame"
  w:Hide()
end
function F.Render()
  if not F.window then return end
  local market=F.Market(); local feed=market and F.bundledPrices[market]
  local when=feed and date("%b %d %H:%M",feed.time) or "No AHledger snapshot — run companion updater"
  F.status:SetText((market or "Select your market in Settings") .. "\n" .. muted .. when .. "|r")
  local settings=F.tab=="Settings"
  F.settings:SetShown(settings); F.body:SetShown(not settings)
  F.prev:SetShown(not settings); F.next:SetShown(not settings); F.pageLabel:SetShown(not settings)
  if settings then return end
  local entries={}
  local function add(text,detail,item,action) entries[#entries+1]={text=text,detail=detail,item=item,action=action} end
  if F.tab=="Crates" then
    for _,crate in ipairs(F.catalog.crates) do
      local _,best=F.CrateCosts(crate)
      add(crate.name .. "  " .. gold .. F.Money(best and best.cost) .. "|r",
        best and (best.option.qty.." × "..best.option.name.." · "..best.quote.source) or "No complete priced option. Hover for requirements.",crate.id)
    end
  elseif F.tab=="Writs" then
    local active={}; for _,stop in ipairs(F.active or {}) do active[stop.questID]=stop end
    for _,writ in ipairs(F.catalog.writs) do
      local stop,quote=active[writ.questId],F.Price(writ.targetId)
      local prefix=stop and (stop.ready and "|cff80dd80[READY]|r " or "|cffffd36a[ACCEPTED]|r ") or ""
      add(prefix..writ.name, writ.qty.." × "..writ.targetName.." · "..F.Money(quote and quote.price*writ.qty).." · "..writ.rep.." rep",writ.id)
    end
    table.sort(entries,function(a,b) return (a.text:find("[",1,true) and 0 or 1) < (b.text:find("[",1,true) and 0 or 1) end)
  else
    local count=0; for _ in pairs(F.char.flights.nodes) do count=count+1 end
    F.status:SetText("Delivery route · " .. #(F.active or {}) .. " accepted · " .. count .. " known flight points\n"..muted.."~"..math.ceil((F.routeSeconds or 0)/60).." min travel estimate · open flight masters to learn routes|r")
    for i,leg in ipairs(F.route or {}) do
      local stop=leg.stop
      add(gold..i..". "..stop.writ.targetName.."|r", (stop.ready and "Ready" or "Gather materials first").." · ~"..math.ceil(leg.seconds/60).." min · click to show delivery on map", nil,function() F.Navigate(stop.point,stop.questID) end)
      for _,step in ipairs(leg.steps) do
        if step.mode=="Fly" then
          add("    Fly: "..(step.from.name or "Flight master").." → "..(step.to.name or "Flight master"),"Click to navigate to the departure flight master",nil,function() F.Navigate(step.from) end)
        end
      end
    end
    for _,stop in ipairs(F.unresolved or {}) do
      add((stop.ready and "Ready: " or "Prepare: ")..stop.writ.targetName,
        stop.point and "Other continent / location unavailable: travel, then recalculate." or
        stop.owned.."/"..stop.writ.qty.." items · pin: /fwl pin "..stop.questID.." MAP_ID X Y",stop.writ.id)
    end
    if #entries==0 then add("Your delivery book is empty", "Accept a Craftsman's Writ and it will appear here automatically.") end
  end
  F.lastPage=math.max(0,math.floor((#entries-1)/8)*8)
  F.offset=math.min(F.offset or 0,F.lastPage)
  for i,row in ipairs(F.rows) do
    local entry=entries[F.offset+i]
    row:SetShown(entry~=nil)
    if entry then row.text:SetText(entry.text); row.detail:SetText(entry.detail); row.itemID=entry.item; row.action=entry.action end
  end
  F.prev:SetEnabled(F.offset>0); F.next:SetEnabled(F.offset<F.lastPage)
  F.pageLabel:SetText(math.floor(F.offset/8)+1 .. " / " .. math.floor(F.lastPage/8)+1)
end
