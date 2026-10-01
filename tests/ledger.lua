local F=...
for _,item in ipairs(F.catalog.writs)do assert(type(item.level)=='number','Writ levels must be available without the item cache')end
for _,recipe in pairs(F.recipeData.recipes)do
  for _,variant in ipairs(recipe[1] and recipe or {recipe})do assert(variant.skill and variant.skill>0,'Missing profession rank')end
end
local catalog,price,active,quote=F.catalog,F.Price,F.active,F.GoodsQuote
F.catalog={crates={},writs={}}
for id=1,7 do
  F.catalog.writs[id]={id=id,questId=id,name=string.char(65+id),targetName='Goods',targetId=100+id,qty=2,rep=10}
  F.catalog.crates[id]={id=id,name=string.char(65+id),tier='Apprentice',level=1,favor=10,options={{itemId=100+id,name='Goods',qty=2}}}
end
F.Price=function(id)
  if id==1 or id==102 then return end
  return {price=id>100 and id-100 or 10,quantity=100,source='Test',time=1000}
end
F.db.settings.craftGoods=false;F.onlyOwned=false;F.searchText='';F.tierIndex=1
F.active={{questID=1}}
for _,tab in ipairs({'Writs','Crates'})do
  F.tab=tab
  for sort=1,3 do
    F.sortIndex=sort
    local entries=F.LedgerEntries()
    for index,entry in ipairs(entries)do
      assert(entry.fullyPriced==(index<=5),'Incomplete prices must sort last, even accepted or alphabetically first')
      assert((entry.total~=nil)==(index<=5))
      if entry.total then assert(entry.total==10+2*entry.item.id,'Total includes item plus whole goods bundle')end
    end
  end
end
F.tab='Writs';F.sortIndex=1
local entries=F.LedgerEntries()
for i=1,5 do assert(entries[i].band==i,'Website value bands must span green to red')end
F.searchText='H';local filtered=F.LedgerEntries()
assert(#filtered==1 and filtered[1].band==5,'Filtering must not change value bands')
F.searchText='';F.GoodsQuote=function()return {cost=0,enough=true}end
entries=F.LedgerEntries()
assert(entries[1].fullyPriced and entries[1].total==10,'Zero goods cost is a price, not missing')
for i=1,6 do assert(entries[i].band==1,'Equal cost per reward must have the same band')end
F.GoodsQuote=function()return {cost=nil,enough=false}end
entries=F.LedgerEntries();for _,e in ipairs(entries)do assert(not e.fullyPriced and not e.band)end
F.db.settings.craftGoods=true
F.GoodsQuote=function()return {cost=77,enough=true,materials={},steps={}}end
entries=F.LedgerEntries();assert(entries[1].total==87,'Craft mode must value its materials, plus the writ')
F.RenderDetail(entries[1])
local totalRow
for _,row in ipairs(F.detailRows)do if row.shown and row.title.text=='Total' then totalRow=row end end
assert(totalRow and totalRow.amount.text==F.Style.Money(87),'Detail and list must agree about full cost')
F.GoodsQuote=function()return {cost=77,enough=false,materials={},steps={}}end
entries=F.LedgerEntries();assert(entries[1].fullyPriced and not entries[1].band,'Short stock keeps its estimate but cannot win a value band')
local req=F.CraftRequirements({steps={{profession='Tailoring',skill=40},{profession='Tailoring',skill=150},
  {profession='Alchemy',skill=0},{profession='Engineering',skill=200,caveat='Requires Goblin Engineering.'}}})
assert(req:find('Tailoring • skill 150',1,true) and not req:find('skill 40',1,true))
assert(req:find('Alchemy • skill level unverified',1,true) and req:find('Requires Goblin Engineering.',1,true))
F.catalog,F.Price,F.active,F.GoodsQuote=catalog,price,active,quote
F.db.settings.craftGoods=false;F.searchText='';F.sortIndex=1
print('PASS: complete prices sort first in every mode, full totals, stable website value colors, ties, zero costs and crafting requirements')
