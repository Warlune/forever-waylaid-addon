local F=...
local oldDB,oldChar,oldLegacy,oldLoader,oldAPI=WaylaidForeverDB,WaylaidForeverCharDB,ForeverWaylaidDB,WaylaidForeverLegacyLoader,C_AddOns
local oldCommand=SlashCmdList.WAYLAIDFOREVER
local account={settings={ledgerScale=.85,compassScale=1.3,textSize=16,highContrast=true,reduceMotion=true,
  personal=false,navigator=false,worldRoute=false,telemetry=false,hideCompletedWrits=true,debugAlliance=true},notifiedUpdateVersion='0.14.9'}
local character={ledgerPosition={point='TOPLEFT',relativePoint='TOPLEFT',x=120,y=-90},
  navPosition={point='RIGHT',x=-73,y=41},minimapAngle=144,navExpanded=true,
  flights={nodes={[1]={name='My flight'}},edges={[1]={}}},pins={[123]={mapID=1411,x=.3,y=.4}},
  localPrices={market={[2840]={price=13,time=100}}},recipients={[123]={npc='Customer'}}}
WaylaidForeverDB,WaylaidForeverCharDB,ForeverWaylaidDB=account,character,{settings={ledgerScale=9}}
WaylaidForeverLegacyLoader=true;C_AddOns={IsAddOnLoaded=function()return false end}
local loaded={};assert(loadfile('WaylaidForever/Core.lua'))('WaylaidForever',loaded)
for _=1,2 do loaded.events.scripts.OnEvent(nil,'ADDON_LOADED','WaylaidForever')end
assert(loaded.db==account and loaded.char==character,'Upgrade replaced save tables')
assert(account.settings.ledgerScale==.85 and account.settings.compassScale==1.3 and account.settings.textSize==16)
assert(account.settings.hideCompletedWrits==true,'Saved completed-writ filter must survive upgrades')
assert(account.settings.highContrast and account.settings.reduceMotion and not account.settings.personal and not account.settings.navigator)
assert(not account.settings.worldRoute and account.settings.telemetry==false and account.notifiedUpdateVersion=='0.14.9')
assert(account.settings.debugAlliance==nil,'Retired preview must be removed')
assert(character.navPosition.x==-73 and character.minimapAngle==144 and character.navExpanded)
assert(character.flights.nodes[1].name=='My flight' and character.pins[123].x==.3 and character.localPrices.market[2840].price==13)
assert(character.recipients[123].npc=='Customer' and character.ledgerPosition.x==120)
local oldFChar=F.char;F.char=character
local got
local frame={ClearAllPoints=function()end,SetPoint=function(_,...)got={...}end,
  GetPoint=function()return 'BOTTOMRIGHT',UIParent,'BOTTOMRIGHT',-65,82 end}
F.RestoreLedgerPosition(frame);assert(got[1]=='TOPLEFT' and got[4]==120 and got[5]==-90)
F.SaveLedgerPosition(frame);F.RestoreLedgerPosition(frame)
assert(got[1]=='BOTTOMRIGHT' and got[4]==-65 and got[5]==82,'Ledger position not saved/restored')
F.char=oldFChar
WaylaidForeverDB,WaylaidForeverCharDB,ForeverWaylaidDB,WaylaidForeverLegacyLoader,C_AddOns=oldDB,oldChar,oldLegacy,oldLoader,oldAPI
SlashCmdList.WAYLAIDFOREVER=oldCommand
print('PASS: upgrades preserve saved data, explicit false settings, accessibility, compass/minimap positions and ledger drag position')
