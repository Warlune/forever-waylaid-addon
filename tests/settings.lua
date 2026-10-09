local F=...
local oldAddons,oldScanner,oldAuc=C_AddOns,Auctionator,AucAdvanced
local oldGUID,oldPrices=UnitGUID,F.char.localPrices
local oldDebug,oldHide=F.db.settings.debugAlliance,F.db.settings.autoHideAuction
UnitGUID=function()return 'Player-Character-Override'end
Auctionator=nil;AucAdvanced=nil
local selected,level=nil,0
C_AddOns={GetAddOnEnableState=function(name,character)
  assert(character=='Player-Character-Override')
  return name==selected and level or 0
end}
for _,addon in ipairs(F.auctionAddons)do
  selected=addon[1];level=2
  local found,label=F.HasAuctionScanner()
  assert(found and label==addon[2],'Every registered auction addon is detected by character enable state')
  level=0;assert(not F.HasAuctionScanner(),'Disabled installs do not suppress our controls')
end
selected='TradeSkillMaster_AppHelper';level=2
assert(not F.HasAuctionScanner(),'A standalone helper is not the TSM auction addon')
selected='Blizzard_AuctionHouseUI';assert(not F.HasAuctionScanner(),'Blizzard auction UI does not count as a competitor')
C_AddOns={IsAddOnLoaded=function(name)return name=='TradeSkillMaster'end}
assert(F.HasAuctionScanner(),'Loaded-addon fallback works when enable-state API is unavailable')
C_AddOns.GetAddOnEnableState=function()return 0 end
assert(not F.HasAuctionScanner(),'Known disabled state wins over globals or loaded state awaiting reload')
F.char.localPrices={['Test Realm:Horde']={[2840]={price=7}},['Test Realm:Alliance']={[2840]={price=99}}}
local beforeScope=F.PersonalScanScope()
F.db.settings.debugAlliance=true;F.ApplySettings()
assert(F.Style.Faction()=='Horde' and F.Style.Theme().crest:find('Horde'),'Retired preview must not override actual faction')
assert(F.Price(2840).price==7 and F.PersonalScanScope()==beforeScope,'Retired preview cannot select Alliance prices or scan scope')
F.db.settings.debugAlliance=false;F.ApplySettings()
assert(F.Style.Faction()=='Horde' and F.Style.Theme().crest:find('Horde'))
C_AddOns,Auctionator,AucAdvanced=oldAddons,oldScanner,oldAuc
UnitGUID,F.char.localPrices=oldGUID,oldPrices
F.db.settings.debugAlliance,F.db.settings.autoHideAuction=oldDebug,oldHide
print('PASS: auction addon registry, disabled installs, helper exclusions, auto-hide and retired Alliance preview')

local oldMode,oldApply=F.db.settings.tooltipMode,F.ApplySettings
local applies=0;F.ApplySettings=function()applies=applies+1 end
for i,option in ipairs(F.tooltipModeOptions)do
 F.tooltipModeButton.scripts.OnClick();assert(F.tooltipMenu.shown)
 F.tooltipMenu.choices[i].scripts.OnClick()
 assert(F.db.settings.tooltipMode==option[1] and not F.tooltipMenu.shown,'Selection saves the mode and closes the menu')
end
assert(applies==4)
F.tooltipModeButton.scripts.OnClick();F.tooltipMenu.scripts.OnMouseDown(F.tooltipMenu)
assert(not F.tooltipMenu.shown,'Outside click closes the menu')
F.db.settings.tooltipMode,F.ApplySettings=oldMode,oldApply
