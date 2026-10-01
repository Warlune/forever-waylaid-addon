local F=...
local S=F.Style
local keys={'ledgerScale','compassScale','textSize','highContrast','reduceMotion'}
local saved={};for _,key in ipairs(keys)do saved[key]=F.db.settings[key]end
local width,height=UIParent.GetWidth,UIParent.GetHeight
UIParent.GetWidth=function()return 1920 end;UIParent.GetHeight=function()return 1080 end
assert(F.AccessibleScale(1.5,1040,704)<1.5,'Ledger is capped to the available screen height')
assert(F.AccessibleScale(1.5,300,372)==1.5,'Compass can grow independently')
assert(F.AccessibleScale('broken',300,372)==1,'Invalid saved scale falls back safely')
local size,color
local text={SetFontObject=function()size=10 end,GetFont=function()return 'font.ttf',size,'' end,
  SetFont=function(_,_,value)size=value end,SetTextColor=function(_,r,g,b)color={r,g,b}end}
F.db.settings.textSize=13
S.ReadableFont(text,'GameFontHighlightSmall');assert(size==13)
S.ReadableFont(text,'GameFontHighlightSmall');assert(size==13,'Repeated updates do not compound font size')
F.db.settings.textSize=0;S.ReadableFont(text,'GameFontHighlightSmall');assert(size==10,'Font restores to its original size')
F.db.settings.highContrast=true;S.TextColor(text,{0.2,0.3,0.4})
assert(color[1]==1 and color[2]==1 and color[3]==1)
assert(S.Theme().panel[1]<0.05 and S.Money(nil)=='Unpriced')
F.db.settings.highContrast=false;S.TextColor(text,text.fwColor);assert(color[1]==0.2,'Original color survives a contrast toggle')
F.db.settings.highContrast=true;F.db.settings.textSize=13;F.db.settings.reduceMotion=true
F.db.settings.ledgerScale=1.3;F.db.settings.compassScale=1.5
-- All supported font choices are absolute minimums, never compounded.
for _,minimum in ipairs({12,13,14,16})do
  F.db.settings.textSize=minimum;S.ReadableFont(text,'GameFontHighlightSmall');assert(size==minimum)
end
F.ResetAccessibility()
for _,key in ipairs(keys)do assert(F.db.settings[key]==F.defaults[key],'Reset restores '..key)end
assert(F.valueLabels[1]=='Best value' and F.valueLabels[5]=='High cost','Value ratings have non-color labels')
UIParent.GetWidth,UIParent.GetHeight=width,height
for _,key in ipairs(keys)do F.db.settings[key]=saved[key]end
F.ApplySettings()
print('PASS: accessible sizing, reversible readable text and contrast, reduced motion and reset')

-- Exercise dropdown selection and replacing one open menu with another.
local controls=F.accessibilityDropdowns
controls.textSize.button.scripts.OnClick()
assert(F.accessibilityMenu:IsShown() and F.accessibilityMenu.key=='textSize')
F.accessibilityMenu.choices[5].scripts.OnClick()
assert(F.db.settings.textSize==16 and not F.accessibilityMenu:IsShown())
controls.ledgerScale.button.scripts.OnClick()
controls.compassScale.button.scripts.OnClick()
assert(F.accessibilityMenu.key=='compassScale')
F.accessibilityMenu.choices[2].scripts.OnClick()
assert(F.db.settings.compassScale==1.15)
F.ResetAccessibility()
print('PASS: size dropdown selection, menu replacement and text-size presets')

-- WoW can retain a per-label SetFont override after SetFontObject.
local originalFont=GameFontHighlightSmall
GameFontHighlightSmall={GetFont=function()return 'base.ttf',10,'' end}
local stickySize=16
local sticky={SetFontObject=function()end,GetFont=function()return 'base.ttf',stickySize,'' end,
 SetFont=function(_,_,value)stickySize=value end}
F.db.settings.textSize=0;S.ReadableFont(sticky,'GameFontHighlightSmall');assert(stickySize==10)
F.db.settings.textSize=14;S.ReadableFont(sticky,'GameFontHighlightSmall');assert(stickySize==14)
F.db.settings.textSize=12;S.ReadableFont(sticky,'GameFontHighlightSmall');assert(stickySize==12)
GameFontHighlightSmall=originalFont
local savedSettings=F.db.settings
for _,case in ipairs({{old=true,expected=13},{old=false,expected=0},{old=true,current=16,expected=16}})do
 F.db.settings={largeText=case.old,textSize=case.current,valuePalette="sunset"}
 F.events.scripts.OnEvent(nil,'ADDON_LOADED','ForeverWaylaid')
 assert(F.db.settings.textSize==case.expected and F.db.settings.largeText==nil)
 assert(F.db.settings.valuePalette==nil and F.defaults.valuePalette==nil, "Retired palette preference is removed")
end
F.db.settings=savedSettings
F.ResetAccessibility()
print('PASS: sticky font override reset, smaller text selection, and legacy preference migration')
