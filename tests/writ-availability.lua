local F=...
local old={char=F.char,active=F.active,catalog=F.catalog,price=F.Price,goods=F.GoodsQuote,
  now=F.Now,quest=C_QuestLog,dates=C_DateAndTime,reset=GetQuestResetTime,removed=F.removedWrits,
  refresh=F.Refresh,filter=F.writFilter,owned=F.onlyOwned,tab=F.tab,sort=F.sortIndex,query=F.searchText}
local stamp,reset=1000,2000
local flags,on,ready={},{},{}
local a,b,c=F.catalog.writs[1],F.catalog.writs[2],F.catalog.writs[3]
F.Now=function()return stamp end
C_DateAndTime={GetSecondsUntilDailyReset=function()return reset-stamp end}
GetQuestResetTime=nil
C_QuestLog={IsOnQuest=function(id)return on[id]end,IsComplete=function(id)return ready[id]end,
  IsQuestFlaggedCompleted=function(id)return flags[id]end}
F.char={};F.removedWrits={};F.Refresh=function()end
assert(F.WritStatus(a.questId)==nil)
on[a.questId]=true
assert(F.WritStatus(a.questId)=='accepted')
ready[a.questId]=true
assert(F.WritStatus(a.questId)=='ready','Ready objectives are not a daily completion')
F.events.scripts.OnEvent(nil,'QUEST_REMOVED',a.questId)
assert(F.WritStatus(a.questId)==nil and not F.char.writCompletedUntil,'Abandon must not consume the daily')
F.events.scripts.OnEvent(nil,'QUEST_ACCEPTED',a.questId)
F.events.scripts.OnEvent(nil,'QUEST_TURNED_IN',a.questId)
assert(F.WritStatus(a.questId)=='completed','Turn-in must win over a stale quest log')
assert(F.char.writCompletedUntil[a.questId]==2000)
on[a.questId]=nil
local saved=F.char
F.char={};assert(F.WritStatus(a.questId)==nil,'Completion leaked to another character')
F.char=saved;F.removedWrits={}
assert(F.WritStatus(a.questId)=='completed','Saved completion must survive reload')
stamp=2000;reset=88400
assert(F.WritStatus(a.questId)==nil,'Daily reset must release the writ')
assert(not F.char.writCompletedUntil[a.questId])
flags[b.questId]=true
assert(F.WritStatus(b.questId)=='completed','Recover server completions from before installation/login')
flags[b.questId]=nil
assert(F.WritStatus(b.questId)==nil,'Do not retain a cleared server flag')
F.RecordWritCompletion(a.questId)
on[a.questId]=true;ready[a.questId]=false
F.events.scripts.OnEvent(nil,'QUEST_ACCEPTED',a.questId)
assert(F.WritStatus(a.questId)=='accepted','A new acceptance must clear an old local lockout')
on[a.questId]=nil
C_DateAndTime=nil;GetQuestResetTime=function()return 300 end
assert(F.WritDailyReset()==stamp+300,'Legacy reset API fallback')
GetQuestResetTime=function()return 1800000000 end
assert(F.WritDailyReset()==nil,'Reject invalid epoch-valued reset readings')
F.RecordWritCompletion(c.questId)
assert(F.WritStatus(c.questId)=='completed')
stamp=stamp+61
assert(F.WritStatus(c.questId)==nil,'Unknown reset must not create a permanent local lockout')

F.catalog={writs={a,b,c},crates={}}
local costs={[a.id]=100,[b.id]=10,[c.id]=30}
F.Price=function(id)return {price=costs[id] or 1,quantity=999,source='Test',time=stamp}end
F.GoodsQuote=function()return {cost=1,enough=true}end
F.active={{questID=a.questId,ready=true}};on[a.questId]=true;ready[a.questId]=true
flags[c.questId]=true
F.tab='Writs';F.sortIndex=1;F.searchText='';F.onlyOwned=false;F.writFilter=nil
local all=F.LedgerEntries()
assert(all[1].item==b and all[3].item==a,'Active writ must not override best-value sorting')
assert(all[3].writStatus=='ready' and all[2].writStatus=='completed')
F.sortIndex=2;assert(F.LedgerEntries()[1].item==b,'Active writ must not override total sorting')
F.sortIndex=3
local named=F.LedgerEntries()
for i=2,#named do assert(named[i-1].item.name<named[i].item.name)end
F.sortIndex=1;F.writFilter='available'
local available=F.LedgerEntries()
assert(#available==1 and available[1].item==b,'Available hides accepted/ready and completed writs')
assert(available[1].band==all[1].band,'Availability filtering must not change value bands')
F.writFilter='cargo'
assert(F.LedgerEntries()[1].item==a,'Cargo retains accepted writs')
F.char.realm='Test Realm';F.char.flights={nodes={},edges={}}
F.writFilter='all';F.Render()
assert(F.rows[2].reward.text:find('Completed today',1,true),'Completed row needs a written status')
F.RenderDetail(all[2])
local found=false
for _,row in ipairs(F.detailRows)do if row.shown and row.title.text=='Completed today' then found=true end end
assert(found,'Detail must explain the daily lockout')
F.ownedButton.scripts.OnClick()
assert(F.writFilter=='available' and F.ownedButton.text=='Show: Available')

F.char,F.active,F.catalog,F.Price,F.GoodsQuote=old.char,old.active,old.catalog,old.price,old.goods
F.Now,C_QuestLog,C_DateAndTime,GetQuestResetTime=old.now,old.quest,old.dates,old.reset
F.removedWrits,F.Refresh,F.writFilter,F.onlyOwned=old.removed,old.refresh,old.filter,old.owned
F.tab,F.sortIndex,F.searchText=old.tab,old.sort,old.query
print('PASS: writ sort order, accepted/ready/turned-in distinctions, character isolation, daily reset, missing APIs and availability filter')
