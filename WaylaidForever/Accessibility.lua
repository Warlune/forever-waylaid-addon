local _,F=...
local S=F.Style
local sizeOptions={{1,"100% (default)"},{1.15,"115%"},{1.3,"130%"},{1.5,"150%"}}
local textOptions={{0,"Default"},{12,"12 point"},{13,"13 point"},{14,"14 point"},{16,"16 point"}}
function F.AccessibleScale(requested,width,height)
  requested=tonumber(requested) or 1
  if requested~=requested then requested=1 end
  return math.max(0.1,math.min(math.max(1,math.min(1.5,requested)),
    (UIParent:GetWidth()-40)/width,(UIParent:GetHeight()-40)/height))
end
function F.ApplyAccessibility()
  if not F.db then return end
  local settings=F.db.settings
  if F.window then F.window:SetScale(F.AccessibleScale(settings.ledgerScale,1040,F.ledgerHeight or 704))end
  if F.compass then F.compass:SetScale(F.AccessibleScale(settings.compassScale,300,F.compassLayoutHeight or 450))end
  for key,control in pairs(F.accessibilityDropdowns or {})do
    local label=control.options[1][2]
    for _,option in ipairs(control.options)do if option[1]==settings[key] then label=option[2];break end end
    control.button:SetText(label.."  |TInterface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up:16:16|t")
  end
end
function F.ResetAccessibility()
  for _,key in ipairs({"ledgerScale","compassScale","textSize","highContrast","reduceMotion"})do
    F.db.settings[key]=F.defaults[key]
  end
  F.ApplySettings()
  for key,check in pairs(F.accessibilityChecks or {})do check:SetChecked(F.db.settings[key])end
end
function F.BuildAccessibility(parent)
  local panel=S.Panel(parent,24,-221,990,310);F.accessibility=panel
  S.Text(panel,"Accessibility",25,-18,620,"GameFontNormalLarge",S.gold)
  S.Button(panel,"Back to settings",740,-14,220,function()F.accessibilityView=false;F.Render()end)
  -- One shared popup closes on selection, outside click, Escape or leaving this panel.
  local popup=CreateFrame("Frame","WaylaidForeverAccessibilityMenu",panel)
  popup:SetAllPoints(parent);popup:SetFrameStrata("DIALOG");popup:EnableMouse(true)
  popup:SetScript("OnMouseDown",function(self)self:Hide()end)
  local menu=S.Panel(popup,0,0,430,160);menu:EnableMouse(true)
  popup.choices={};F.accessibilityMenu=popup
  UISpecialFrames[#UISpecialFrames+1]="WaylaidForeverAccessibilityMenu"
  panel:SetScript("OnHide",function()popup:Hide()end)
  F.accessibilityDropdowns={}
  local function dropdown(key,title,x,y,options)
    S.Text(panel,title,x,y,430,"GameFontNormal",S.gold)
    local button=S.Button(panel,"",x,y-24,430,function()
      if popup:IsShown() and popup.key==key then popup:Hide();return end
      popup.key=key
      menu:ClearAllPoints();menu:SetPoint("TOPLEFT",F.accessibilityDropdowns[key].button,"BOTTOMLEFT",0,-2)
      menu:SetHeight(#options*29+12)
      for i,option in ipairs(options)do
        local choice=popup.choices[i]
        if not choice then choice=S.Button(menu,"",6,-6-(i-1)*29,418,function()end);popup.choices[i]=choice end
        local value,label=option[1],option[2]
        choice:SetText((F.db.settings[key]==value and "|TInterface\\Buttons\\UI-CheckBox-Check:16:16|t " or "")..label)
        choice:SetScript("OnClick",function()F.db.settings[key]=value;popup:Hide();F.ApplySettings()end)
        choice:Show()
      end
      for i=#options+1,#popup.choices do popup.choices[i]:Hide()end
      popup:Show()
    end)
    F.accessibilityDropdowns[key]={button=button,options=options}
  end
  dropdown("ledgerScale","Ledger size",25,-60,sizeOptions)
  dropdown("compassScale","Compass size",500,-60,sizeOptions)
  dropdown("textSize","Minimum text size",25,-128,textOptions)
  S.Text(panel,"Color filters",500,-128,430,"GameFontNormal",S.gold)
  S.Text(panel,"Use WoW Settings > Accessibility > Colors.",500,-155,430,"GameFontHighlightSmall",S.muted)
  S.Text(panel,"Size is limited to fit your screen. Text size keeps headings at least as large as body text.",25,-194,930,"GameFontHighlightSmall",S.muted)
  F.accessibilityChecks={}
  F.accessibilityChecks.highContrast=S.Check(panel,"High contrast",23,-222,"highContrast")
  F.accessibilityChecks.reduceMotion=S.Check(panel,"Reduced motion: pause the scribe",498,-222,"reduceMotion")
  S.Button(panel,"Reset accessibility",25,-270,260,F.ResetAccessibility)
  S.Text(panel,"Applies immediately; saved for your account.",310,-277,640,"GameFontHighlightSmall",S.muted)
  popup:Hide();panel:Hide()
end
