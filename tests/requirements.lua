local F=...
local oldSkills,oldCount,oldInfo,oldTrade,oldLevel=C_SkillInfo,GetNumSkillLines,GetSkillLineInfo,C_TradeSkillUI,UnitLevel
local oldRanks,oldComplete=F.professionRanks,F.professionsComplete
local oldContrast=F.db.settings.highContrast
F.db.settings.highContrast=false
local open=false
local engineering=90
C_TradeSkillUI={GetTradeSkillDisplayName=function(id)if id==202 then return "Ingenieurkunst" end end}
C_SkillInfo={
  GetNumSkillLines=function()return open and 3 or 1 end,
  GetSkillLineInfo=function(i)
    if i==1 then return {name="Professions",isHeader=true,isExpanded=open} end
    if i==2 then return {name="Ingenieurkunst",rank=engineering} end
    return {name="Mining",rank=65}
  end,
  ExpandSkillHeader=function(i)assert(i==1);open=true end,
  CollapseSkillHeader=function(i)assert(i==1);open=false end,
}
F.ReadProfessions()
assert(not open,'Profession reading must restore collapsed headers')
assert(F.ProfessionRank('Engineering')==90 and F.ProfessionRank('Mining')==65)
assert(F.ProfessionRank('Tailoring')==0,'Absent profession is unlearned after a complete scan')
local craft={steps={{profession='Engineering',skill=105},{profession='Mining',skill=65}}}
local text=F.CraftRequirements(craft)
assert(text:find('|cffa0000090 / 105 (15 more)|r',1,true))
assert(text:find('|cff176b2165 / 65|r',1,true),'Exact requirement counts as met')
engineering=110;F.events.scripts.OnEvent(nil,'SKILL_LINES_CHANGED');text=F.CraftRequirements(craft)
assert(text:find('|cff176b21110 / 105|r',1,true),'Skill-up invalidates the character snapshot')
text=F.CraftRequirements({steps={{profession='Tailoring',skill=75}}})
assert(text:find('0 / 75 (75 more)',1,true) and text:find('not learned',1,true))
C_SkillInfo=nil;GetNumSkillLines=function()return 1 end
GetSkillLineInfo=function()return 'Engineering',false,false,105 end
F.ReadProfessions();assert(F.ProfessionRank('Engineering')==105,'Classic tuple adapter')
GetNumSkillLines=nil;GetSkillLineInfo=nil;F.ReadProfessions()
assert(F.ProfessionRank('Engineering')==nil,'Unavailable API must not report unlearned')
assert(F.RequirementNumber(30,20)=='|cffa0000030 (10 more)|r')
assert(F.RequirementNumber(20,20)=='|cff176b2120|r')
assert(F.RequirementNumber(10,20)=='|cff176b2110|r')
assert(F.RequirementNumber(10,nil)=='10 (yours unknown)')
UnitLevel=function(unit)assert(unit=='player');return 20 end
local entry={item={id=123,questId=456,targetId=789,targetName='Test goods',qty=1,rep=75,level=30,name='Test writ'},goods={cost=1,enough=true},cost=1}
F.RenderDetail(entry)
assert(F.detailRows[1].description.text:find('Requires level |cffa0000030 (10 more)|r',1,true))
entry.item.level=10;F.RenderDetail(entry)
assert(F.detailRows[1].description.text:find('Requires level |cff176b2110|r',1,true))
F.db.settings.highContrast=true
assert(F.RequirementNumber(30,20)=='30 (10 more)')
assert(F.RequirementNumber(20,20)=='20 (met)')
C_SkillInfo,GetNumSkillLines,GetSkillLineInfo,C_TradeSkillUI,UnitLevel=oldSkills,oldCount,oldInfo,oldTrade,oldLevel
F.professionRanks,F.professionsComplete=oldRanks,oldComplete
F.db.settings.highContrast=oldContrast
print('PASS: profession API adapters, collapsed headers, localization, skill-up refresh, unmet/met/missing ranks, character levels and high contrast')

