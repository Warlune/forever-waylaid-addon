local F=...
local R=F.Route
local none={nodes={},edges={}}
local function p(x,y,instance)
  return {wx=x,wy=y or 0,instance=instance or 0,mapID=1411,x=0.5,y=0.5}
end
local function checkJourney(route,start,total,limits)
  local at,seconds,seen,used=start,0,{},{}
  for _,leg in ipairs(route) do
    assert(not seen[leg.stop],'A delivery can only be visited once');seen[leg.stop]=true
    for _,step in ipairs(leg.steps) do
      assert(R.Distance(at,step.from)<0.001,'Each step must continue from the preceding arrival')
      at=step.to
      local resource=step.detail and step.detail.resource
      if resource then used[resource]=(used[resource] or 0)+1 end
    end
    assert(R.Distance(at,leg.stop.point)<0.001,'Each leg must reach its recipient')
    seconds=seconds+leg.seconds
  end
  for resource,count in pairs(used) do assert(count<=(limits[resource] or 1),'Shared charges/reagents overspent') end
  assert(math.abs(seconds-total)<0.00001,'Itinerary total must equal all its legs')
end

-- More than three deliveries: save the hearth until the nearby work is done.
local start,home=p(0),p(7000)
local travel={links={},personal={{to=home,mode='Hearthstone',id=6948,wait=0,seconds=15,resource='hearth'}},resources={hearth=1}}
local stops={{point=home},{point=p(140)},{point=p(147)},{point=p(154)}}
local route,missing,total,mode=R.Plan(start,stops,none,true,travel)
assert(#route==4 and #missing==0 and math.abs(total-37)<0.00001 and mode=='exact')
assert(route[#route].stop.point==home,'Save the hearth rather than taking the cheapest next delivery')
checkJourney(route,start,total,travel.resources)

-- Parallel public services must compete by total cost, not list position.
local landing=p(0,0,1)
local services={links={{from=start,to=landing,mode='Boat',seconds=90},{from=start,to=landing,mode='Zeppelin',seconds=300}},personal={},resources={}}
local seconds,steps=R.Leg(start,landing,none,true,services)
assert(seconds==90 and steps[1].mode=='Boat')
services.links[1],services.links[2]=services.links[2],services.links[1]
assert(R.Leg(start,landing,none,true,services)==90)
assert(R.Leg(landing,start,none,true,services)==math.huge,'Do not fabricate a return service')

-- Transfer walking and final walking belong in the comparison too.
local dock,arrival,airport,landed,target=p(70),p(70,0,1),p(140,0,1),p(14000,0,1),p(14070,0,1)
local flights={nodes={a=airport,b=landed},edges={a={b=60}}}
services.links={{from=dock,to=arrival,mode='Boat',seconds=90}}
seconds,steps=R.Leg(start,target,flights,true,services)
assert(seconds==195 and #steps==5)
assert(steps[1].mode=='Travel' and steps[2].mode=='Boat' and steps[3].mode=='Travel' and steps[4].mode=='Fly' and steps[5].mode=='Travel')

-- Two destinations can each be reachable from the start while a single
-- shared charge prevents completing both. Keep the other stop unresolved.
local other=p(0,0,2)
local limited={links={},personal={
  {to=landing,mode='Teleport',id=1,wait=0,seconds=10,resource='rune'},
  {to=other,mode='Teleport',id=2,wait=0,seconds=15,resource='rune'},
},resources={rune=1}}
route,missing,total=R.Plan(start,{{point=landing},{point=other},{point=nil}},none,true,limited)
assert(#route==1 and #missing==2 and total==10,'Do not spend the same last reagent twice or hide unresolved deliveries')
checkJourney(route,start,total,limited.resources)

-- Time spent finishing another delivery counts toward the initial cooldown.
local cooling={links={},personal={{to=home,mode='Hearthstone',id=6948,wait=30,seconds=5,resource='hearth'}},resources={hearth=1}}
route,missing,total=R.Plan(start,{{point=home},{point=p(70)}},none,true,cooling)
assert(#route==2 and total==35 and route[2].steps[1].detail.wait==20)
checkJourney(route,start,total,cooling.resources)

-- An independent Floyd-Warshall + exhaustive permutation oracle. It tries
-- each spell separately (including shared reagent pools), waits out cooldowns,
-- and does not call the production leg solver to obtain its expected answer.
local seed=8301
local function random(max)
  seed=(seed*16807)%2147483647
  return math.floor(seed/2147483647*max)+1
end
for case=1,24 do
  local nodes={p(0,0,0)}
  for i=2,7 do nodes[i]=p(random(18000),random(6000),i%2) end
  local routes={links={},personal={},resources={hearth=1,rune=case%3+1}}
  local flightData={nodes={},edges={}}
  for i,node in ipairs(nodes) do flightData.nodes[i]=node;flightData.edges[i]={} end
  -- Every fixture can cross continents both ways. Extra directed flights
  -- and services vary the winning transport and order between test cases.
  for i=1,7 do
    for j=1,7 do
      if i~=j then
        if nodes[i].instance~=nodes[j].instance then
          routes.links[#routes.links+1]={from=nodes[i],to=nodes[j],mode='Boat',seconds=100+random(500)}
        elseif random(3)==1 then flightData.edges[i][j]=30+random(200) end
      end
    end
  end
  for i=1,3 do routes.personal[i]={to=nodes[i+4],mode=i==1 and 'Hearthstone' or 'Teleport',id=i,wait=random(300)-1,seconds=10+i,resource=i==1 and 'hearth' or 'rune'} end
  local distances={}
  for i=1,7 do
    distances[i]={}
    for j=1,7 do
      distances[i][j]=nodes[i].instance==nodes[j].instance and R.Distance(nodes[i],nodes[j])/7 or math.huge
      if flightData.edges[i][j] then distances[i][j]=math.min(distances[i][j],flightData.edges[i][j]+15) end
    end
  end
  for _,link in ipairs(routes.links) do
    local a,b
    for i,node in ipairs(nodes) do if node==link.from then a=i end;if node==link.to then b=i end end
    distances[a][b]=math.min(distances[a][b],link.seconds)
  end
  for k=1,7 do for i=1,7 do for j=1,7 do distances[i][j]=math.min(distances[i][j],distances[i][k]+distances[k][j]) end end end
  local expected=math.huge
  local function brute(at,elapsed,visited,used,count)
    if count==4 then expected=math.min(expected,elapsed);return end
    if elapsed>=expected then return end
    for j=2,5 do
      if not visited[j] then
        visited[j]=true
        brute(j,elapsed+distances[at][j],visited,used,count+1)
        for i,spell in ipairs(routes.personal) do
          if (used[spell.resource] or 0)<routes.resources[spell.resource] then
            used[spell.resource]=(used[spell.resource] or 0)+1
            brute(j,math.max(elapsed,spell.wait)+spell.seconds+distances[i+4][j],visited,used,count+1)
            used[spell.resource]=used[spell.resource]-1
          end
        end
        visited[j]=nil
      end
    end
  end
  brute(1,0,{},{},0)
  stops={};for i=2,5 do stops[#stops+1]={point=nodes[i]} end
  route,missing,total,mode=R.Plan(nodes[1],stops,flightData,true,routes)
  assert(#route==4 and #missing==0 and mode=='exact')
  assert(math.abs(total-expected)<0.00001,'Complete journey differs from exhaustive oracle in case '..case..': '..total..' / '..expected)
  checkJourney(route,nodes[1],total,routes.resources)
end

-- Larger rounds remain bounded and share the ordinary graph across every
-- candidate order. Count geometry evaluations rather than a flaky time limit.
local oldDistance=R.WalkDistance
local evaluations=0
R.WalkDistance=function(a,b)evaluations=evaluations+1;return oldDistance(a,b)end
stops={};for i=1,25 do stops[i]={point=p(i*140,(i%4)*35)} end
local before=os.clock()
route,missing,total,mode=R.Plan(start,stops,none,true,travel)
local elapsed=os.clock()-before
R.WalkDistance=oldDistance
assert(#route==25 and #missing==0 and mode=='estimated')
assert(evaluations<=27*27,'Rebuilding the ordinary graph per candidate would cause in-game stalls')
checkJourney(route,start,total,travel.resources)
print(string.format('PASS: general journey engine; 24 exhaustive mixed-transport/resource oracles, 4-stop hearth strategy, transfers, parallel services; 25 stops %.3fs / %d geometry checks',elapsed,evaluations))
