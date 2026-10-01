local F=...
local oldPrice,oldCraft,oldTab=F.Price,F.db.settings.craftGoods,F.tab
F.Price=function()return {price=100,source="Test",time=1000}end
F.tab="Crates";F.db.settings.craftGoods=true
local function bundle(id,name,cost,enough,skill)
  return {option={itemId=id,name=name,qty=5},cost=cost,enough=enough,craft={cost=cost,enough=enough,
    materials={{itemId=id+10,name=name.." material",qty=3,cost=cost,source="Test"}},
    steps={{itemId=id,name=name,crafts=5,outputMin=1,profession=skill,skill=100}}}}
end
local cheap=bundle(700001,"Chosen goods",20,true,"Engineering")
local other=bundle(700002,"Other goods",40,true,"Tailoring")
local short=bundle(700003,"Short stock",10,false,"Alchemy")
local entry={item={id=700000,name="Test crate",level=1,favor=10},rows={short,cheap,other},best=cheap,cost=20}
local function rendered()
  F.RenderDetail(entry)
  local texts={};local materials=0
  for _,row in ipairs(F.detailRows)do if row.shown then
    texts[#texts+1]=row.title.text or ""
    texts[#texts+1]=row.description.text or ""
    if row.title.text=="Materials to source" then materials=materials+1 end
  end end
  return table.concat(texts,"\n"),materials
end
local text,count=rendered()
assert(count==1 and text:find('Chosen goods material',1,true),'Only the chosen bundle has a material plan')
assert(not text:find('Other goods',1,true) and not text:find('Short stock',1,true),'Other bundles must not look like extra requirements')
assert(text:find('Fill ONE bundle',1,true) and text:find('Engineering',1,true))
assert(not text:find('Tailoring',1,true) and not text:find('Alchemy',1,true),'Only the chosen profession is required')
cheap.enough=false;entry.best=short;entry.cost=10
text,count=rendered();assert(count==0 and text:find('No fully priced, stocked option',1,true),'Incomplete alternatives cannot be labeled the cheapest plan')
cheap.enough=true;entry.best=cheap;entry.cost=20;F.db.settings.craftGoods=false
text,count=rendered();assert(count==0 and text:find('Other goods',1,true),'AH mode still compares alternative bundles')
F.Price,F.db.settings.craftGoods,F.tab=oldPrice,oldCraft,oldTab
print('PASS: crate crafting shows one cheapest complete bundle, one material plan and only its professions')
