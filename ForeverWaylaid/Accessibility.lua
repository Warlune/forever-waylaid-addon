local _,F=...
local S=F.Style
local sizes={1,1.15,1.3,1.5}
function F.AccessibleScale(requested,width,height)
  requested=tonumber(requested) or 1
  if requested~=requested then requested=1 end
  return math.max(0.1,math.min(math.max(1,math.min(1.5,requested)),
    (UIParent:GetWidth()-40)/width,(UIParent:GetHeight()-40)/height))
end
function F.ApplyAccessibility()
  if not F.db then return end
  local settings=F.db.settings
  if F.window then F.window:SetScale(F.AccessibleScale(settings.ledgerScale,1040,704))end
  if F.compass then F.compass:SetScale(F.AccessibleScale(settings.compassScale,300,372))end
  if F.accessibilitySizes then
    for key,button in pairs(F.accessibilitySizes)do
      button:SetText((key=="ledgerScale" and "Ledger size: " or "Compass size: ")..math.floor((tonumber(settings[key]) or 1)*100+0.5).."%")
    end
  end
end
function F.ResetAccessibility()
  for _,key in ipairs({"ledgerScale","compassScale","largeText","highContrast","reduceMotion"})do
    F.db.settings[key]=F.defaults[key]
  end
  F.ApplySettings()
  if F.accessibilityChecks then
    for key,check in pairs(F.accessibilityChecks)do check:SetChecked(F.db.settings[key])end
  end
end
function F.BuildAccessibility(parent)
  local panel=S.Panel(parent,24,-221,990,415);F.accessibility=panel
  S.Text(panel,"Accessibility",25,-18,620,"GameFontNormalLarge",S.gold)
  S.Button(panel,"Back to settings",740,-14,220,function()F.accessibilityView=false;F.Render()end)
  S.Text(panel,"Make the ledger easier to read",25,-57,800,"GameFontHighlight",S.gold)
  F.accessibilitySizes={}
  for index,key in ipairs({"ledgerScale","compassScale"})do
    F.accessibilitySizes[key]=S.Button(panel,"",25+(index-1)*475,-88,430,function()
      local current=tonumber(F.db.settings[key]) or 1
      local nextSize=sizes[1]
      for _,size in ipairs(sizes)do if size>current+0.001 then nextSize=size;break end end
      F.db.settings[key]=nextSize;F.ApplySettings()
    end)
  end
  S.Text(panel,"Click to cycle 100%, 115%, 130% and 150%. Windows stay within your screen.",25,-126,930,"GameFontHighlightSmall",S.muted)
  F.accessibilityChecks={}
  F.accessibilityChecks.largeText=S.Check(panel,"Larger text (minimum 13-point)",23,-157,"largeText")
  F.accessibilityChecks.highContrast=S.Check(panel,"High contrast: white text, dark backgrounds",23,-198,"highContrast")
  F.accessibilityChecks.reduceMotion=S.Check(panel,"Reduced motion: pause the auction scribe",23,-239,"reduceMotion")
  S.Text(panel,"Value ratings always include words, such as Best value or High cost.\nHigh contrast removes the colored row fills and parchment. Item icons keep their rarity borders.\nThe navigation arrow still updates so it can guide you.",25,-284,930,"GameFontHighlightSmall",S.muted)
  S.Button(panel,"Reset accessibility",25,-367,260,F.ResetAccessibility)
  S.Text(panel,"These settings apply immediately and are saved for your account.",310,-375,640,"GameFontHighlightSmall",S.muted)
  panel:Hide()
end
