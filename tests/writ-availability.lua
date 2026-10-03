local F=...
local old={char=F.char,active=F.active,catalog=F.catalog,price=F.Price,goods=F.GoodsQuote,
  now=F.Now,quest=C_QuestLog,dates=C_DateAndTime,reset=GetQuestResetTime,removed=F.removedWrits,
  refresh=F.Refresh,tab=F.tab,sort=F.sortIndex,query=F.searchText,count=C_Item.GetItemCount,hide=F.db.settings.hideCompletedWrits,navigator=F.db.settings.navigator}
local stamp,reset=1000,2000
local flags,on,ready,bags={},{},{},{}
C_Item.GetItemCount=function(id)return bags[id] or 0 end
F.db.settings.hideCompletedWrits=false
local a,b,c=F.catalog.writs[1],F.catalog.writs[2],F.catalog.writs[3]
F.Now=function()return stamp end
C_DateAndTime={GetSecondsUntilDailyReset=function()return reset-stamp end}
GetQuestResetTime=nil
C_QuestLog={IsOnQuest=function(id)return on[id]end,IsComplete=function(id)return ready[id]end,
  IsQuestFlaggedCompleted=function(id)return flags[id]end}
F.char={};F.removedWrits={};F.Refresh=function()end
assert(F.WritStatus(a.questId)==nil)
bags[a.id]=1;assert(F.WritStatus(a.questId)=='bag','Carried writ must show In Bag')
on[a.questId]=true
assert(F.WritStatus(a.questId)=='quest')
ready[a.questId]=true
assert(F.WritStatus(a.questId)=='quest','Ready objectives are not a daily completion')
F.events.scripts.OnEvent(nil,'QUEST_REMOVED',a.questId)
assert(F.WritStatus(a.questId)=='bag' and not F.char.writCompletedUntil,'Abandoned writ still in bags must show In Bag')
bags[a.id]=nil;assert(F.WritStatus(a.questId)==nil,'No quest or item means no mark')
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
assert(F.WritStatus(a.questId)=='quest','A new acceptance must clear an old local lockout')
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
F.tab='Writs';F.sortIndex=1;F.searchText=''
local all=F.LedgerEntries()
assert(all[1].item==b and all[3].item==a,'Active writ must not override best-value sorting')
assert(all[3].writStatus=='quest' and all[2].writStatus=='completed')
F.sortIndex=2;assert(F.LedgerEntries()[1].item==b,'Active writ must not override total sorting')
F.sortIndex=3
local named=F.LedgerEntries()
for i=2,#named do assert(named[i-1].item.name<named[i].item.name)end
F.sortIndex=1
F.char.realm='Test Realm';F.char.flights={nodes={},edges={}}
F.Render()
assert(F.rows[2].status.text=='(Completed today)','Completed marker must follow the name')
assert(F.rows[3].status.text=='(On Quest)','Active and ready quests share the On Quest marker')
assert(not F.rows[3].reward.text:find('On Quest',1,true),'Status must not occupy the reward line')
F.RenderDetail(all[2])
local found=false
for _,row in ipairs(F.detailRows)do if row.shown and row.title.text=='Completed today' then found=true end end
assert(found,'Detail must explain the daily lockout')

bags[b.id]=1
assert(F.WritStatus(b.questId)=='bag')
F.hideCompleted.GetChecked=function()return true end
F.hideCompleted.scripts.OnClick(F.hideCompleted)
local visible=F.LedgerEntries()
assert(F.db.settings.hideCompletedWrits and #visible==2 and visible[1].item==b and visible[2].item==a,
  'Hide completed must retain In Bag and On Quest in value order')
assert(visible[1].band==all[1].band,'Checkbox must not recalculate value ratings')
F.Render();assert(F.rows[1].status.text=='(In Bag)')
F.tab='Crates';F.Render();assert(not F.hideCompleted.shown,'Writ-only filter must hide on crates')
F.db.settings.navigator=true;F.UpdateNavigator()
F.compass.hide.scripts.OnClick()
assert(F.db.settings.navigator==false and not F.compass.shown,'Hide button must persist compass visibility')
F.UpdateNavigator();assert(not F.compass.shown,'A refresh must not reopen the compass')
F.db.settings.navigator=true;F.UpdateNavigator();assert(F.compass.shown,'Existing toggle can restore the compass')
C_Item.GetItemCount=old.count
F.db.settings.hideCompletedWrits,F.db.settings.navigator=old.hide,old.navigator

F.char,F.active,F.catalog,F.Price,F.GoodsQuote=old.char,old.active,old.catalog,old.price,old.goods
F.Now,C_QuestLog,C_DateAndTime,GetQuestResetTime=old.now,old.quest,old.dates,old.reset
F.removedWrits,F.Refresh=old.removed,old.refresh
F.tab,F.sortIndex,F.searchText=old.tab,old.sort,old.query
print('PASS: writ sort order, accepted/ready/turned-in distinctions, character isolation, daily reset, missing APIs and availability filter')
