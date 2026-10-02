local F=...
local R=F.Route
local no={nodes={},edges={}}
local function p(name,x,y,world,map)
  return {name=name,wx=x,wy=y or 0,instance=world or 0,mapID=map or 1411,x=.5,y=.5}
end
local checked=0
local function check(route,missing,total,start,stops,resources)
  local seen,used,at,sum={},{},start,0
  for _,leg in ipairs(route) do
    assert(not seen[leg.stop],'Duplicate turn-in');seen[leg.stop]=true
    for _,step in ipairs(leg.steps) do
      assert(at.instance==step.from.instance and math.abs(at.wx-step.from.wx)<.001 and math.abs(at.wy-step.from.wy)<.001,'Broken journey continuity')
      at=step.to
      local resource=step.detail and step.detail.resource
      if resource then used[resource]=(used[resource] or 0)+1 end
    end
    assert(at.instance==leg.stop.point.instance and math.abs(at.wx-leg.stop.point.wx)<.001 and math.abs(at.wy-leg.stop.point.wy)<.001,'Missed recipient')
    sum=sum+leg.seconds
  end
  for _,stop in ipairs(missing) do assert(not seen[stop]);seen[stop]=true end
  for _,stop in ipairs(stops) do assert(seen[stop],'Silently dropped a writ') end
  for resource,count in pairs(used) do assert(count<=(resources[resource] or 1),'Overspent a travel resource') end
  assert(math.abs(sum-total)<.00001,'Incorrect total time')
  checked=checked+1
end
local function show(name,route,missing,total)
  local modes={}
  for _,leg in ipairs(route) do
    for _,step in ipairs(leg.steps) do modes[#modes+1]=step.mode end
    modes[#modes+1]='turn in '..leg.stop.point.name
  end
  print('MOCK: '..name..' | '..table.concat(modes,' > ')..string.format(' | %.1fs, %d unresolved',total,#missing))
end

-- Times and positions below are synthetic; they exercise decision making,
-- not the real duration or geometry of a particular Azeroth journey.
local start=p('Start',0)
local goal=p('Customer',700)
local remote=p('Remote flight master',7000)
local finishFP=p('Arrival flight master',630)
local flights={nodes={a=remote,b=finishFP},edges={a={b=1}}}
local stops={{point=goal}}
local route,missing,total=R.Plan(start,stops,flights,true)
assert(total==100 and #route[1].steps==1 and route[1].steps[1].mode=='Travel','A cheap flight is not worth a long walk to its departure')
check(route,missing,total,start,stops,{})
show('Nearby customer beats remote cheap flight',route,missing,total)

local other=p('Other continent',70,0,1)
local travel={links={{from=start,to=other,seconds=180,mode='Zeppelin'}},
  personal={{to=other,wait=900,seconds=15,id=6948,resource='hearth',mode='Hearthstone'}},resources={hearth=1}}
stops={{point=other}}
route,missing,total=R.Plan(start,stops,no,true,travel)
assert(total==180 and route[1].steps[1].mode=='Zeppelin','Use transport rather than wait fifteen minutes for hearth')
check(route,missing,total,start,stops,travel.resources)
show('Hearth cooling down',route,missing,total)
travel.personal[1].wait=0
route,missing,total=R.Plan(start,stops,no,true,travel)
assert(total==15 and route[1].steps[1].mode=='Hearthstone')
check(route,missing,total,start,stops,travel.resources)
show('Same trip with hearth ready',route,missing,total)

stops={{point=p('Writ A',70)},{point=p('Writ B',70)},{point=p('Writ C',140)}}
route,missing,total=R.Plan(start,stops,no,true)
assert(#route==3 and total==20,'Co-located writs must both be turned in without duplicate travel')
check(route,missing,total,start,stops,{})
show('Two writs at one location',route,missing,total)

local island=p('Island customer',70,0,0,1438)
stops={{point=island}}
route,missing,total=R.Plan(start,stops,no,true)
assert(#route==0 and #missing==1,'No walking route across the sea')
check(route,missing,total,start,stops,{})
show('Island without a known transport',route,missing,total)
travel={links={{from=start,to=island,seconds=90,mode='Boat'}},personal={},resources={}}
route,missing,total=R.Plan(start,stops,no,true,travel)
assert(#route==1 and total==90)
check(route,missing,total,start,stops,{})
show('Same island with a boat',route,missing,total)

-- Independent all-pairs shortest paths plus exhaustive delivery permutations.
-- Unlike the older dense fixtures, these include missing/one-way services,
-- disconnected worlds, zero reagent counts and partially reachable rounds.
local seed=18013
local function random(n)seed=(seed*97+13)%65521;return seed%n+1 end
for case=1,240 do
  local count=case%17==0 and 5 or 4
  local nodes={p('Start',0)}
  for i=2,count+4 do nodes[i]=p('Stop '..i,random(14000),random(8000),random(3)-1) end
  local graph={nodes={},edges={}}
  local options={links={},personal={},resources={hearth=case%2,runes=case%3,engineering=1}}
  local distances={}
  for i,a in ipairs(nodes) do
    graph.nodes[i]=a;graph.edges[i]={};distances[i]={}
    for j,b in ipairs(nodes) do
      distances[i][j]=a.instance==b.instance and math.sqrt((a.wx-b.wx)^2+(a.wy-b.wy)^2)/7 or math.huge
      if i~=j and a.instance==b.instance and random(4)==1 then
        graph.edges[i][j]=random(400)
        distances[i][j]=math.min(distances[i][j],graph.edges[i][j]+15)
      elseif i~=j and a.instance~=b.instance and random(7)==1 then
        local seconds=80+random(500)
        options.links[#options.links+1]={from=a,to=b,mode=i%2==0 and 'Boat' or 'Zeppelin',seconds=seconds}
        distances[i][j]=math.min(distances[i][j],seconds)
      end
    end
  end
  for i,key in ipairs({'hearth','runes','runes','engineering'}) do
    options.personal[i]={to=nodes[count+i],wait=random(1000)-1,seconds=15,id=i,resource=key,mode=i==1 and 'Hearthstone' or i==4 and 'Engineering teleport' or 'Teleport'}
  end
  for k=1,#nodes do for i=1,#nodes do for j=1,#nodes do distances[i][j]=math.min(distances[i][j],distances[i][k]+distances[k][j]) end end end
  local bestCount,bestTime=0,0
  local function exhaustive(at,time,visited,used,n)
    if n>bestCount or (n==bestCount and time<bestTime) then bestCount,bestTime=n,time end
    if n==count or (bestCount==count and time>=bestTime) then return end
    for j=2,count+1 do
      if not visited[j] then
        visited[j]=true
        if distances[at][j]<math.huge then exhaustive(j,time+distances[at][j],visited,used,n+1) end
        for i,spell in ipairs(options.personal) do
          if (used[spell.resource] or 0)<options.resources[spell.resource] and distances[count+i][j]<math.huge then
            used[spell.resource]=(used[spell.resource] or 0)+1
            exhaustive(j,math.max(time,spell.wait)+spell.seconds+distances[count+i][j],visited,used,n+1)
            used[spell.resource]=used[spell.resource]-1
          end
        end
        visited[j]=nil
      end
    end
  end
  exhaustive(1,0,{},{},0)
  stops={};for i=2,count+1 do stops[#stops+1]={point=nodes[i]} end
  local mode
  route,missing,total,mode=R.Plan(nodes[1],stops,graph,true,options)
  assert(mode=='exact','Unexpected truncation in small mock case '..case)
  assert(#route==bestCount and math.abs(total-bestTime)<.00001,'Oracle mismatch in mock '..case..': '..#route..' / '..bestCount..', '..total..' / '..bestTime)
  check(route,missing,total,nodes[1],stops,options.resources)
end
print('PASS: '..checked..' additional mock journeys including 240 exhaustive sparse/partial transport comparisons')

-- Independently measure (rather than assume) the bounded search's tradeoff
-- on larger rounds against an exact Held-Karp walking-only reference.
local largestGap,nonOptimal=0,0
for case=1,12 do
  local n,points=10,{[0]=start}
  stops={}
  for i=1,n do points[i]=p('Large stop '..i,random(20000),random(20000));stops[i]={point=points[i]} end
  local d={}
  for i=0,n do
    d[i]={}
    for j=1,n do d[i][j]=math.sqrt((points[i].wx-points[j].wx)^2+(points[i].wy-points[j].wy)^2)/7 end
  end
  local memo={}
  local function exact(at,mask)
    if mask==2^n-1 then return 0 end
    local key=mask*(n+1)+at
    if memo[key] then return memo[key] end
    local best=math.huge
    for j=1,n do
      local bit=2^(j-1)
      if math.floor(mask/bit)%2==0 then best=math.min(best,d[at][j]+exact(j,mask+bit)) end
    end
    memo[key]=best;return best
  end
  local optimum=exact(0,0)
  local greedy,at,visited=0,0,{}
  for _=1,n do
    local best,nextStop=math.huge
    for j=1,n do if not visited[j] and d[at][j]<best then best,nextStop=d[at][j],j end end
    greedy=greedy+best;at=nextStop;visited[at]=true
  end
  local mode
  route,missing,total,mode=R.Plan(start,stops,no,false)
  assert(#route==n and #missing==0 and mode=='estimated')
  assert(total<=greedy+.0001 and total>=optimum-.0001,'Bounded result must be feasible and never worse than its greedy baseline')
  check(route,missing,total,start,stops,{})
  local gap=(total/optimum-1)*100
  if gap>.0001 then nonOptimal=nonOptimal+1 end
  largestGap=math.max(largestGap,gap)
end
print(string.format('MOCK: 12 ten-delivery rounds vs exact reference: %d non-optimal, largest gap %.2f%%',nonOptimal,largestGap))
