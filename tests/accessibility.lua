local F=...
local S=F.Style
local keys={'ledgerScale','compassScale','largeText','highContrast','reduceMotion'}
local saved={};for _,key in ipairs(keys)do saved[key]=F.db.settings[key]end
local width,height=UIParent.GetWidth,UIParent.GetHeight
UIParent.GetWidth=function()return 1920 end;UIParent.GetHeight=function()return 1080 end
assert(F.AccessibleScale(1.5,1040,704)<1.5,'Ledger is capped to the available screen height')
assert(F.AccessibleScale(1.5,300,372)==1.5,'Compass can grow independently')
assert(F.AccessibleScale('broken',300,372)==1,'Invalid saved scale falls back safely')
local size,color
local text={SetFontObject=function()size=10 end,GetFont=function()return 'font.ttf',size,'' end,
  SetFont=function(_,_,value)size=value end,SetTextColor=function(_,r,g,b)color={r,g,b}end}
F.db.settings.largeText=true
S.ReadableFont(text,'GameFontHighlightSmall');assert(size==13)
S.ReadableFont(text,'GameFontHighlightSmall');assert(size==13,'Repeated updates do not compound font size')
F.db.settings.largeText=false;S.ReadableFont(text,'GameFontHighlightSmall');assert(size==10,'Font restores to its original size')
F.db.settings.highContrast=true;S.TextColor(text,{0.2,0.3,0.4})
assert(color[1]==1 and color[2]==1 and color[3]==1)
assert(S.Theme().panel[1]<0.05 and S.Money(nil)=='Unpriced')
F.db.settings.highContrast=false;S.TextColor(text,text.fwColor);assert(color[1]==0.2,'Original color survives a contrast toggle')
F.db.settings.highContrast=true;F.db.settings.largeText=true;F.db.settings.reduceMotion=true
F.db.settings.ledgerScale=1.3;F.db.settings.compassScale=1.5
F.ResetAccessibility()
for _,key in ipairs(keys)do assert(F.db.settings[key]==F.defaults[key],'Reset restores '..key)end
assert(F.valueLabels[1]=='Best value' and F.valueLabels[5]=='High cost','Value ratings have non-color labels')
UIParent.GetWidth,UIParent.GetHeight=width,height
for _,key in ipairs(keys)do F.db.settings[key]=saved[key]end
F.ApplySettings()
print('PASS: accessible sizing, reversible readable text and contrast, reduced motion and reset')
