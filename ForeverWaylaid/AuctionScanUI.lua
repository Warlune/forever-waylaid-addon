local _,F=...
local S=F.Style
local scanMode={}

local function centered(parent,text,y,width,font,color)
  local label=S.Text(parent,text,0,y,width,font,color)
  label:ClearAllPoints();label:SetPoint("TOP",0,y);label:SetJustifyH("CENTER")
  return label
end

function F.CreateScanScribe(parent,size)
  local art=parent:CreateTexture(nil,"ARTWORK")
  art:SetSize(size,size);art:SetPoint("CENTER")
  art:SetTexture("Interface\\AddOns\\ForeverWaylaid\\Art\\AuctionScribes.tga")
  local ui={art=art}
  local phase,elapsed=0,0
  local function pose()
    local row=S.Faction()=="Alliance" and 1 or 0
    art:SetTexCoord(phase/4,(phase+1)/4,row/2,(row+1)/2)
  end
  pose()
  ui.pose=pose
  ui.animate=function(_,dt)
    if F.db.settings.reduceMotion then return end
    elapsed=elapsed+dt
    local interval=ui.active and 0.22 or 0.48
    if elapsed>=interval then elapsed=elapsed%interval;phase=(phase+1)%4;pose()end
  end
  return ui
end

function F.CreateScanProgressBar(parent,width)
  local bar=CreateFrame("StatusBar",nil,parent)
  bar:SetSize(width,12)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(unpack(S.gold));bar:SetMinMaxValues(0,1);bar:SetValue(0)
  local bg=bar:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(0.18,0.13,0.08,1)
  -- Native Classic XP-bar trim and nineteen dividers make twenty cells.
  local xpTexture="Interface\\MainMenuBar\\UI-XP-Bar"
  local left=bar:CreateTexture(nil,"OVERLAY")
  left:SetTexture(xpTexture);left:SetSize(14,14)
  left:SetPoint("RIGHT",bar,"LEFT",11,0)
  left:SetTexCoord(0.1875,0.4375,0.015625,0.265625)
  local right=bar:CreateTexture(nil,"OVERLAY")
  right:SetTexture(xpTexture);right:SetSize(14,14)
  right:SetPoint("LEFT",bar,"RIGHT",-11,0)
  right:SetTexCoord(0.1875,0.4375,0.296875,0.546875)
  local middle=bar:CreateTexture(nil,"OVERLAY")
  middle:SetTexture("Interface\\MainMenuBar\\UI-XP-Mid")
  middle:SetHorizTile(true)
  middle:SetPoint("TOPLEFT",left,"TOPRIGHT")
  middle:SetPoint("BOTTOMRIGHT",right,"BOTTOMLEFT")
  for _,trim in ipairs({left,right,middle})do trim:SetVertexColor(0.7451,0.6353,0.5176)end
  for i=1,19 do
    local divider=bar:CreateTexture(nil,"OVERLAY")
    divider:SetTexture(xpTexture);divider:SetSize(9,9)
    divider:SetTexCoord(0.015625,0.15625,0.015625,0.171875)
    divider:SetPoint("CENTER",bar,"LEFT",width*i/20,1)
    divider:SetVertexColor(0.7451,0.6353,0.5176)
  end
  return bar
end

function F.UpdateAuctionScanUI(info)
  local ui=F.auctionScanUI
  if not ui then return end
  -- Keep our optional tab outside the native parentArray. Other auction
  -- addons anchor their row to the last entry in host.Tabs, even if hidden.
  local previous=ui.host.Tabs[#ui.host.Tabs]
  local library=LibStub and LibStub("LibAHTab-1-0",true)
  local tabs=library and library.internalState and library.internalState.Tabs
  if tabs then
    for _,other in ipairs(tabs)do if other:IsShown() then previous=other end end
  end
  if previous then
    ui.tab:ClearAllPoints();ui.tab:SetPoint("TOPLEFT",previous,"TOPRIGHT",3,0)
  end
  ui.tab:SetShown(info.available)
  if not info.available and ui.page:IsShown() then
    ui.host:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
  end
  ui.start:SetEnabled(info.canStart);ui.cancel:SetEnabled(info.active)
  ui.start:SetText(info.active and "Copying prices…" or "Scan auction house")
  ui.status:SetText(info.status)
  ui.stats[1]:SetText(info.total and (info.processed.." / "..info.total) or "—")
  ui.stats[2]:SetText(info.unique);ui.stats[3]:SetText(info.matched);ui.stats[4]:SetText(info.saved)
  local seconds=math.floor(info.elapsed)
  ui.stats[5]:SetText(string.format("%d:%02d",math.floor(seconds/60),seconds%60))
  local progress=info.total and info.total>0 and info.processed/info.total or 0
  if info.phase=="complete" then progress=1 end
  ui.progress:SetValue(progress)
  local captions={waiting="Awaiting the auctioneer's ledger…",reading="Recording today's market prices",validating="Checking incomplete auction records"}
  ui.caption:SetText(info.active and captions[info.phase] or "Your faction's auction scribe")
  ui.active=info.active
end

function F.InstallAuctionScanUI()
  if F.auctionScanUI or not F.db or not AuctionHouseFrame or not AuctionHouseFrame.Tabs then return end
  local host=AuctionHouseFrame
  local previous=host.Tabs[#host.Tabs]
  if not previous then return end
  local page=S.Panel(host,8,-29,784,480)
  page:ClearAllPoints();page:SetPoint("TOPLEFT",8,-29);page:SetPoint("BOTTOMRIGHT",-8,29)
  page:SetFrameLevel(host:GetFrameLevel()+10);page:EnableMouse(true);page:Hide()
  local tabHost=CreateFrame("Frame",nil,host)
  tabHost:SetAllPoints(host)
  local tab=CreateFrame("Button","ForeverWaylaidAuctionScanTab",tabHost,"AuctionHouseFrameDisplayModeTabTemplate")
  -- Match PanelTemplates_AnchorTabs, which lays out the native AH tabs.
  tab:ClearAllPoints();tab:SetPoint("TOPLEFT",previous,"TOPRIGHT",3,0);tab:SetText("Scan")
  PanelTemplates_TabResize(tab,20,nil,70);PanelTemplates_DeselectTab(tab)
  local ui={host=host,tabHost=tabHost,page=page,tab=tab,stats={}}
  F.auctionScanUI=ui

  centered(page,"THE AUCTION SCRIBE",-15,600,"GameFontNormalLarge",S.gold)
  ui.caption=centered(page,"Your faction's auction scribe",-40,600,"GameFontHighlightSmall",S.muted)
  local scribe=F.CreateScanScribe(page,218)
  scribe.art:ClearAllPoints();scribe.art:SetPoint("TOP",0,-55)
  ui.art=scribe.art;ui.pose=scribe.pose
  page:SetScript("OnUpdate",function(_,dt)scribe.active=ui.active;scribe.animate(nil,dt)end)
  local labels={"Auctions read","All item types","Relevant items","Prices saved","Time elapsed"}
  local strip=CreateFrame("Frame",nil,page);strip:SetSize(742,62);strip:SetPoint("TOP",0,-280)
  for i,label in ipairs(labels)do
    local box=S.Panel(strip,(i-1)*150,0,142,62,true)
    ui.stats[i]=centered(box,i==1 and "—" or (i==5 and "0:00" or "0"),-11,132,"GameFontNormal",S.ink)
    centered(box,label,-38,132,"GameFontHighlightSmall",S.ink)
  end
  local bar=F.CreateScanProgressBar(page,624);bar:SetPoint("TOP",0,-352)
  ui.progress=bar
  ui.status=centered(page,"",-375,710,"GameFontHighlightSmall",S.gold);ui.status:SetHeight(30)
  ui.start=S.Button(page,"Scan auction house",0,0,200,F.StartNativeScan)
  ui.start:ClearAllPoints();ui.start:SetPoint("TOP",-55,-412)
  ui.cancel=S.Button(page,"Cancel",0,0,100,function()F.CancelNativeScan()end)
  ui.cancel:ClearAllPoints();ui.cancel:SetPoint("LEFT",ui.start,"RIGHT",10,0)
  centered(page,"Manual scan • Keep the auction house open • 15-minute cooldown",-452,720,"GameFontHighlightSmall",S.muted)

  tab:SetScript("OnClick",function()
    if F.ShouldHideAuctionExtras() then return end
    host:SetDisplayMode(scanMode)
    for _,nativeTab in ipairs(host.Tabs)do PanelTemplates_DeselectTab(nativeTab)end
    PanelTemplates_SelectTab(tab);host:SetTitle("Forever Waylaid — Auction Scribe")
    page:Show();F.UpdateScanUI()
  end)
  hooksecurefunc(host,"SetDisplayMode",function(_,mode)
    if mode~=scanMode then page:Hide();PanelTemplates_DeselectTab(tab)end
  end)
  host:HookScript("OnHide",function()page:Hide();PanelTemplates_DeselectTab(tab)end)
  -- Auction addons can add their tabs later in the same AH-open event.
  host:HookScript("OnShow",function()C_Timer.After(0,F.UpdateScanUI)end)
  C_Timer.After(0,F.UpdateScanUI)
  F.UpdateScanUI()
end

local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED");events:RegisterEvent("PLAYER_LOGIN");events:RegisterEvent("AUCTION_HOUSE_SHOW")
events:SetScript("OnEvent",function()F.InstallAuctionScanUI();F.UpdateScanUI()end)
