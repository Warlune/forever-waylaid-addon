local _,F=...
local P,S=F.Pets,F.Style
local sizes={{1,"100%"},{1.15,"115%"},{1.3,"130%"},{1.5,"150%"}}
local fonts={{0,"Default"},{12,"12 point"},{13,"13 point"},{14,"14 point"},{16,"16 point"}}
function F.AccessibleScale(requested,width,height)
  requested=tonumber(requested) or 1
  if requested~=requested then requested=1 end
  return math.max(0.1,math.min(math.max(1,math.min(1.5,requested)),(UIParent:GetWidth()-40)/width,(UIParent:GetHeight()-40)/height))
end
function F.PlaceDesktop()
  local window=F.compass;if not window then return end
  local p=F.char.petPosition
  window:ClearAllPoints()
  if type(p)=="table" and type(p.x)=="number" and type(p.y)=="number" then
    window:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",p.x,p.y)
  else window:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-40,-220)end
end
function F.BuildDesktop()
  local c=S.Panel(UIParent,0,0,300,400);F.compass=c
  F.PlaceDesktop();c:SetFrameStrata("MEDIUM");c:SetClampedToScreen(true);c:SetMovable(true);c:EnableMouse(true);c:RegisterForDrag("LeftButton")
  c:SetScript("OnDragStart",c.StartMoving)
  c:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing()
    local scale=self:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local x=self:GetRight()*scale-UIParent:GetWidth()
    local y=self:GetTop()*scale-UIParent:GetHeight()
    F.char.petPosition={x=x,y=y}
  end)
  S.Text(c,"COMPANIONS FOREVER",12,-12,250,"GameFontNormalSmall",S.gold)
  local close=CreateFrame("Button",nil,c,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-1,-1)
  close:SetScript("OnClick",function()P.ToggleCompass(false)end)
  P.BuildCompass(c);P.mini:ClearAllPoints();P.mini:SetPoint("TOPLEFT",8,-34)
  -- Independent minimap launcher; no delivery addon is required.
  if Minimap then
    local button=CreateFrame("Button","CompanionsForeverMinimapButton",Minimap)
    F.minimapButton=button;button:SetSize(32,32);button:SetPoint("TOPLEFT",Minimap,"TOPLEFT",-12,-10)
    button:SetFrameStrata("MEDIUM");button:SetFrameLevel(Minimap:GetFrameLevel()+16)
    local icon=button:CreateTexture(nil,"ARTWORK");icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastTaming");icon:SetSize(21,21);icon:SetPoint("CENTER")
    local border=button:CreateTexture(nil,"OVERLAY");border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");border:SetSize(54,54);border:SetPoint("TOPLEFT",-1,1)
    button:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button:SetScript("OnClick",function(_,key)if key=="RightButton" then P.ToggleCompass()else P.Toggle()end end)
    button:SetScript("OnEnter",function(self)
      GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:SetText("Companions Forever")
      GameTooltip:AddLine("Left-click: camp and tower",1,1,1);GameTooltip:AddLine("Right-click: compact window",1,1,1);GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function()GameTooltip:Hide()end)
  end
  F.UpdateNavigator()
end
function F.UpdateNavigator()
  local c=F.compass;if not c then return end
  local height=398+(P.miniMode=="tower" and 90 or 0)
  c:SetHeight(height);c:SetScale(F.AccessibleScale(F.db.settings.compassScale,300,height))
  c:SetShown(not not F.char.navPets);P.mini:SetShown(not not F.char.navPets)
  P.RenderCompass()
end
function F.ApplySettings()
  S.ApplyTheme();F.UpdateNavigator();P.Render()
  for key,control in pairs(F.dropdowns or {})do
    local label=control.options[1][2]
    for _,option in ipairs(control.options)do if F.db.settings[key]==option[1]then label=option[2]end end
    control.button:SetText(label.."  |TInterface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up:16:16|t")
  end
end
function F.OpenSettings()
  if F.settings then F.settings:Show();F.ApplySettings();return end
  local w=S.Panel(UIParent,0,0,560,470);F.settings=w
  w:ClearAllPoints();w:SetPoint("CENTER");w:SetFrameStrata("FULLSCREEN_DIALOG");w:SetFrameLevel(210)
  w:SetClampedToScreen(true);w:EnableMouse(true)
  w:SetScale(F.AccessibleScale(1,560,470))
  local close=CreateFrame("Button",nil,w,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-3,-3);close:SetScript("OnClick",function()w:Hide()end)
  S.Text(w,"Companions Forever settings",20,-18,490,"GameFontNormalLarge",S.gold)
  local popup=CreateFrame("Frame","CompanionsForeverSizeMenu",w);popup:SetAllPoints(w);popup:SetFrameLevel(220);popup:EnableMouse(true)
  popup:SetScript("OnMouseDown",function(self)self:Hide()end)
  UISpecialFrames[#UISpecialFrames+1]="CompanionsForeverSizeMenu"
  w:SetScript("OnHide",function()popup:Hide()end)
  local menu=S.Panel(popup,0,0,246,160);menu:EnableMouse(true);local choices={}
  F.dropdowns={}
  local function dropdown(key,title,x,y,options)
    S.Text(w,title,x,y,246,"GameFontNormal",S.gold)
    local button=S.Button(w,"",x,y-25,246,function()
      if popup:IsShown() and popup.key==key then popup:Hide();return end
      popup.key=key;menu:ClearAllPoints();menu:SetPoint("TOPLEFT",F.dropdowns[key].button,"BOTTOMLEFT",0,-2);menu:SetHeight(#options*30+12)
      for i,option in ipairs(options)do
        if not choices[i] then choices[i]=S.Button(menu,"",6,-6-(i-1)*30,234,function()end)end
        local value=option[1];choices[i]:SetText(option[2]);choices[i]:Show()
        choices[i]:SetScript("OnClick",function()F.db.settings[key]=value;popup:Hide();F.ApplySettings()end)
      end
      for i=#options+1,#choices do choices[i]:Hide()end
      popup:Show()
    end)
    F.dropdowns[key]={button=button,options=options}
  end
  dropdown("ledgerScale","Large window",20,-62,sizes)
  dropdown("compassScale","Compact window",294,-62,sizes)
  dropdown("textSize","Minimum text size",20,-128,fonts)
  S.Text(w,"Color filters: use WoW's\nAccessibility > Colors.",294,-137,240,"GameFontHighlightSmall",S.muted)
  S.Check(w,"High contrast",18,-202,"highContrast")
  S.Check(w,"Reduced motion",18,-238,"reduceMotion")
  S.Check(w,"Preview Alliance artwork",18,-274,"debugAlliance")
  S.Text(w,"These settings affect only Companions Forever.",20,-317,520,"GameFontHighlightSmall",S.muted)
  local notice=S.Text(w,"",20,-385,516,"GameFontHighlightSmall",S.gold);notice:SetHeight(65)
  local import=S.Button(w,"Import old Waylaid pets",20,-346,260,function()
    popup:Hide()
    if F.char.legacyImportedAt then notice:SetText("Already imported. Your current progress has been kept.");return end
    if F.Pets.state.battle then notice:SetText("Finish your battle first.");return end
    local legacy=WaylaidForeverCharDB or ForeverWaylaidCharDB
    if not (type(legacy)=="table" and type(legacy.pets)=="table")then
      notice:SetText("Enable updated Waylaid Forever on this character and log in once, then try again.");return
    end
    F.confirmImport:Show()
  end)
  local confirm=S.Panel(w,20,-342,520,118);F.confirmImport=confirm;confirm:SetFrameLevel(225);confirm:EnableMouse(true)
  S.Text(confirm,"Replace your stable with old Waylaid pets?\nYour current stable will be saved as a backup.",12,-10,496,"GameFontHighlightSmall",S.gold)
  S.Button(confirm,"Import",12,-73,160,function()
    local _,message=F.ImportLegacy(true);confirm:Hide();notice:SetText(message);P.Render()
  end)
  S.Button(confirm,"Keep current",184,-73,160,function()confirm:Hide()end)
  confirm:Hide();popup:Hide();F.ApplySettings()
end
