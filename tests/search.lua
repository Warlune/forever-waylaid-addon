local F=...
local oldInfo,oldPrint,oldFocus=C_Item.GetItemInfo,F.Print,GetCurrentKeyBoardFocus
local message,search,focused,cursor
F.Print=function(text)message=text end
C_Item.GetItemInfo=function()return 'Localized Copper Bar' end
IsShiftKeyDown=function()return true end
AuctionFrame={IsShown=function()return true end}
local function forbidden()error('Must not switch tabs, choose Shopping, reset filters or submit searches')end
AuctionatorTabs_Shopping={Click=forbidden}
AuctionatorShoppingFrame={SearchOptions={SetSearchTerm=forbidden},DoSearch=forbidden}
AuctionFrameTab1={Click=forbidden};BrowseResetButton={Click=forbidden}
BrowseName={SetText=forbidden}
local box={
  IsObjectType=function(_,kind)return kind=='EditBox' end,
  IsShown=function()return true end,
  SetText=function(_,term)search=term end,
  SetFocus=function()focused=true end,
  SetCursorPosition=function(_,position)cursor=position end,
}
GetCurrentKeyBoardFocus=function()return box end
local icon=F.detailRows[1].icon
F.Style.SetIcon(icon,2840)
local selected=false;icon.selectItem=function()selected=true end
F.window:Show()
icon.scripts.OnMouseUp(icon,'LeftButton')
assert(search=='Localized Copper Bar' and focused and cursor==#search,'Fill only the focused box and keep its caret at the end')
assert(not selected and F.window.shown,'Shift-click must keep the ledger open and selection intact')
IsShiftKeyDown=function()return false end
icon.scripts.OnMouseUp(icon,'LeftButton');assert(selected,'Normal icon click still selects its entry')
selected=false;IsShiftKeyDown=function()return true end
assert(not F.ItemClick(2840,'RightButton'),'Right-click must not search')
AuctionFrame=nil
AuctionHouseFrame={IsShown=function()return true end,SetSearchText=forbidden}
assert(F.SearchAuctionItem(2840) and F.window.shown,'Modern AH must also use only the focused box')
C_Item.GetItemInfo=function()end
assert(F.SearchAuctionItem(2840) and search=='Copper Bar','Uncached goods must use catalogue names')
search=nil;GetCurrentKeyBoardFocus=function()end
assert(not F.SearchAuctionItem(2840) and not search and not message,'No focus must be a silent no-op')
GetCurrentKeyBoardFocus=function()return box end
box.IsShown=function()return false end
assert(not F.SearchAuctionItem(2840) and not search and not message,'Hidden fields must not be filled')
box.IsShown=function()return true end
AuctionHouseFrame={IsShown=function()return false end}
assert(not F.SearchAuctionItem(2840) and not search and not message,'Closed AH must be silent even with a focused field')
AuctionHouseFrame=nil
assert(not F.SearchAuctionItem(2840) and not search and F.window.shown and not message,'Unloaded AH must be silent')
AuctionatorShoppingFrame=nil;AuctionatorTabs_Shopping=nil;AuctionFrameTab1=nil;BrowseResetButton=nil;BrowseName=nil
icon.selectItem=nil;IsShiftKeyDown=nil;C_Item.GetItemInfo=oldInfo;F.Print=oldPrint;GetCurrentKeyBoardFocus=oldFocus

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
print('PASS: Shift-click focused text fields, uncached names, no submission, ordinary clicks and flight scan warning lifecycle')
