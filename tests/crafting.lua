local F=...
local originalPrice=F.Price
local function testPrice(id)return {price=id%101+1,quantity=100000,source="Test market",time=1000}end
F.Price=testPrice
local expected=dofile('tests/crafting-expected.lua')
for _,faction in ipairs({'Horde','Alliance'})do
  UnitFactionGroup=function()return faction end
  for _,case in ipairs(expected[faction])do
    local result=F.CraftQuote(case.id,case.qty)
    assert(result.cost==case.cost,faction..' craft cost mismatch: '..case.id)
    assert(not not result.enough==case.enough,'Stock/eligibility mismatch: '..case.id)
    assert(#result.materials==case.materials and #result.steps==case.steps,'Recipe path mismatch: '..case.id)
  end
end
UnitFactionGroup=function()return 'Horde' end
F.db.settings.craftGoods=true
F.tab='Writs';F.onlyOwned=false;F.searchText='';F.Render()
local first=F.catalog.writs[1]
local entry={item=first,owned=0,goods=F.CraftQuote(first.targetId,first.qty)}
F.RenderDetail(entry)
local found=false
for _,row in ipairs(F.detailRows)do
  if row.itemID==first.targetId then
    found=true;local link
    GameTooltip.SetHyperlink=function(_,value)link=value end
    row.scripts.OnEnter(row);assert(link=='item:'..first.targetId)
  end
end
assert(found,'Required goods must expose item hover tooltip')
local scroll=0
F.detailChild.GetHeight=function()return 900 end
F.detailScroll.GetHeight=function()return 300 end
F.detailScroll.GetVerticalScroll=function()return scroll end
F.detailScroll.SetVerticalScroll=function(_,value)scroll=value end
local offset=F.offset
F.detailScroll.scripts.OnMouseWheel(nil,-1);assert(scroll==65 and F.offset==offset)
F.ScrollDetails(-100);assert(scroll==600);F.ScrollDetails(100);assert(scroll==0)
F.db.settings.navigator=true;F.compass:Show()
F.char.navExpanded=false
local facing=0;GetPlayerFacing=function()return facing end
F.guidance={target={instance=1,wx=100,wy=0.5},stop={}}
local heading
F.compass.arrow.SetRotation=function(_,value)heading=value end
F.compass.heading=nil;F.UpdateCompassPose();local initial=heading
facing=math.pi/2;F.UpdateCompassPose();assert(heading<initial,'Arrow must update when facing changes')
local d=F.recipeData
F.recipeData={recipes={['100']={itemId=100,name='Shared batch',outputMin=1,outputMax=1,profession='Test',skill=1,spellId=100,reagents={{itemId=200,qty=1},{itemId=300,qty=1}}},
 ['200']={itemId=200,name='Left',outputMin=1,outputMax=1,reagents={{itemId=400,qty=1}}},
 ['300']={itemId=300,name='Right',outputMin=1,outputMax=1,reagents={{itemId=400,qty=1}}},
 ['400']={itemId=400,name='Intermediate',outputMin=2,outputMax=4,reagents={{itemId=500,qty=3}}}},
 metadata={leaves={['500']={name='Raw',vendorCopper=10}}}}
F.Price=function()return {price=20,quantity=1,source='Test'}end
local batch=F.CraftQuote(100,1)
assert(batch.cost==30 and batch.enough and batch.variableYield and batch.materials[1].qty==3)
F.recipeData.metadata.leaves['500'].vendorCopper=nil
batch=F.CraftQuote(100,1);assert(batch.cost==60 and not batch.enough)
F.Price=function()end;assert(F.CraftQuote(100,1).cost==nil)
assert(F.CraftQuote(999,1).reason and not F.CraftQuote(999,1).enough)
F.recipeData=d;F.Price=originalPrice;F.db.settings.craftGoods=false
print('PASS: 492 website craft comparisons, factions, nested batches, vendor fallback, missing/short stock and goods tooltips')
