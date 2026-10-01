local F=...
local oldPrices,oldAddons,oldPersonal=F.char.localPrices,C_AddOns,F.db.settings.personal
local oldProcessor,oldType=TooltipDataProcessor,Enum.TooltipDataType
local oldGeneral,oldHide=F.db.settings.generalAuctionTooltips,F.db.settings.autoHideAuction
local enabled={Auctionator=0,['Auc-Advanced']=0}
C_AddOns={GetAddOnEnableState=function(name)return enabled[name]end}
F.db.settings.personal=true
local scope=F.char.realm..':Horde'
local unrelated,ingredient=999999,2840
local crate,writ=F.catalog.crates[1],F.catalog.writs[1]
F.char.localPrices={[scope]={}}
for _,id in ipairs({unrelated,ingredient,crate.id,writ.id,writ.targetId})do
  F.char.localPrices[scope][id]={price=12345,time=900,source='Forever Waylaid',quantity=10000}
end
local callback
Enum.TooltipDataType={Item=1}
TooltipDataProcessor={AddTooltipPostCall=function(_,fn)callback=fn end}
F.InstallTooltips()
local function tip()
  return {lines={},AddLine=function(self,text)self.lines[#self.lines+1]=text end,
    AddDoubleLine=function(self,left,right)self.lines[#self.lines+1]=left..'='..right end,
    Show=function()end}
end
local function text(t)return table.concat(t.lines,'\n')end
local t=tip();callback(t,{id=unrelated})
assert(text(t):find('AH buyout %(each%)=1g 23s 45c') and text(t):find('Forever Waylaid · 1m ago'))
local count=#t.lines;callback(t,{id=unrelated});assert(#t.lines==count,'Repeated processing must not duplicate the price')
GameTooltip.scripts.OnTooltipCleared(t);t.lines={};callback(t,{id=unrelated});assert(#t.lines==count,'Clearing allows the same item to render again')
for _,addon in ipairs(F.auctionAddons)do
  local scanner=addon[1]
  enabled[scanner]=2
  t=tip();callback(t,{id=unrelated});assert(#t.lines==0,'Another enabled scanner owns unrelated tooltips')
  t=tip();callback(t,{id=ingredient});assert(text(t):find('AH buyout'),'Waylaid ingredients retain our prices')
  t=tip();callback(t,{id=crate.id});assert(text(t):find('Cheapest'),'Crate fill information remains visible')
  t=tip();callback(t,{id=writ.id});assert(text(t):find('reputation'),'Writ delivery information remains visible')
  enabled[scanner]=0
end
t=tip();callback(t,{id=unrelated});assert(#t.lines>0,'Installed but disabled scanners do not hide our prices')
enabled.TradeSkillMaster=2;F.db.settings.autoHideAuction=false
t=tip();callback(t,{id=unrelated});assert(#t.lines>0,'Turning off auto-hide restores general tooltip additions')
F.db.settings.generalAuctionTooltips=false
t=tip();callback(t,{id=unrelated});assert(#t.lines==0,'Manual tooltip toggle wins even when auto-hide is off')
t=tip();callback(t,{id=writ.id});assert(text(t):find('reputation'),'Waylaid information survives the general tooltip switch')
enabled.TradeSkillMaster=0;F.db.settings.autoHideAuction=true;F.db.settings.generalAuctionTooltips=true
t=tip();callback(t,{id=999998});assert(#t.lines==0,'Missing prices must not invent an AH value')
F.db.settings.personal=false;t=tip();callback(t,{id=unrelated});assert(#t.lines==0,'Personal-price setting is respected')
F.db.settings.personal=true
local oldFaction=UnitFactionGroup;UnitFactionGroup=function()return 'Alliance'end
t=tip();callback(t,{id=unrelated});assert(#t.lines==0,'Other-faction prices cannot leak into tooltips')
UnitFactionGroup=oldFaction
-- Also exercise the legacy item-link hook used on clients without the processor.
TooltipDataProcessor=nil;F.InstallTooltips()
t=tip();t.GetItem=function()return 'Item','item:'..unrelated end
GameTooltip.scripts.OnTooltipSetItem(t);assert(text(t):find('AH buyout'))
F.char.localPrices,C_AddOns,F.db.settings.personal=oldPrices,oldAddons,oldPersonal
F.db.settings.generalAuctionTooltips,F.db.settings.autoHideAuction=oldGeneral,oldHide
TooltipDataProcessor,Enum.TooltipDataType=oldProcessor,oldType
print('PASS: all-item AH tooltips, source age, scanner coexistence, Waylaid exceptions, deduplication and faction isolation')
