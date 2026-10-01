local F=...
local oldInfo,oldPrint=C_Item.GetItemInfo,F.Print
local message
F.Print=function(text)message=text end
C_Item.GetItemInfo=function()return 'Localized Copper Bar' end
IsShiftKeyDown=function()return true end
AuctionFrame={IsShown=function()return true end}
local search,tab,submitted
AuctionatorTabs_Shopping={Click=function()tab=true end}
AuctionatorShoppingFrame={SearchOptions={SetSearchTerm=function(_,term)search=term end},DoSearch=function()submitted=true end}
local icon=F.detailRows[1].icon
F.Style.SetIcon(icon,2840)
local selected=false;icon.selectItem=function()selected=true end
F.window:Show()
icon.scripts.OnMouseUp(icon,'LeftButton')
assert(tab and search=='"Localized Copper Bar"' and not submitted,'Shift-click must fill Auctionator without submitting')
assert(not selected and F.window.shown,'Shift-click must keep the ledger open without selecting another entry')
IsShiftKeyDown=function()return false end
icon.scripts.OnMouseUp(icon,'LeftButton');assert(selected,'Normal icon click still selects its entry after rebinding')
selected=false;IsShiftKeyDown=function()return true end
assert(not F.ItemClick(2840,'RightButton'),'Right-click must not search')
AuctionatorShoppingFrame=nil;AuctionatorTabs_Shopping=nil
BrowseName={SetText=function(_,term)search=term end}
AuctionFrameTab1={Click=function()tab=true end}
BrowseResetButton={Click=function()search=nil end}
assert(F.SearchAuctionItem(2840) and search=='Localized Copper Bar','Legacy AH search should fill after resetting filters')
assert(F.window.shown,'Legacy AH search must keep the ledger open')
AuctionFrame=nil;BrowseName=nil;AuctionFrameTab1=nil;BrowseResetButton=nil
AuctionHouseFrame={IsShown=function()return true end,SetSearchText=function(_,term)search=term end}
assert(F.SearchAuctionItem(2840) and search=='Localized Copper Bar','Modern native AH search should fill')
assert(F.window.shown,'Modern AH search must keep the ledger open')
C_Item.GetItemInfo=function()end
assert(F.SearchAuctionItem(2840) and search=='Copper Bar','Uncached goods must use catalogue names')
AuctionHouseFrame=nil;search=nil;F.window:Show()
assert(not F.SearchAuctionItem(2840) and not search and F.window.shown and message:find('Open the auction house',1,true))
icon.selectItem=nil;IsShiftKeyDown=nil;C_Item.GetItemInfo=oldInfo;F.Print=oldPrint

local flights,guide=F.char.flights,F.guidance
F.guidance=nil
F.char.flights={nodes={},edges={}};F.db.settings.flights=true
assert(F.NeedsFlightScan(),'New characters need a flight scan warning')
F.UpdateNavigator();assert(F.compass.flightNotice.shown)
F.Render();assert(F.stats[3].caption.text=='FLIGHT PATHS NOT SCANNED')
F.char.flights.nodes[1]={};assert(F.NeedsFlightScan(),'Unverified nodes alone cannot clear the warning')
local oldTaxi=C_TaxiMap;C_TaxiMap=nil;F.LearnFlights();assert(F.NeedsFlightScan(),'Unsupported/failed scans must not clear the warning')
C_TaxiMap=oldTaxi;F.char.flights={nodes={},edges={}}
F.LearnFlights();assert(not F.NeedsFlightScan(),'A successfully recorded departure clears the warning')
F.char.flights={nodes={[1]={}},edges={[1]={}}}
assert(not F.NeedsFlightScan(),'A valid scan with no reachable destinations must not demand a paid flight')
F.UpdateNavigator();assert(not F.compass.flightNotice.shown)
F.char.flights={nodes={},edges={}};F.db.settings.flights=false
assert(not F.NeedsFlightScan(),'Do not warn when flight routing is disabled')
F.char.flights=flights;F.guidance=guide;F.db.settings.flights=true
print('PASS: Shift-click Auctionator/native searches, uncached names, no submission, ordinary clicks and flight scan warning lifecycle')
