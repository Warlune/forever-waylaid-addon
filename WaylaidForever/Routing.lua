local _, F = ...
F.Route = {}
local R = F.Route

-- World positions are in yards; map fractions alone are not comparable.
function R.Distance(a, b)
  if not a or not b or a.instance ~= b.instance then return math.huge end
  return math.sqrt((a.wx - b.wx)^2 + (a.wy - b.wy)^2)
end
function R.World(point)
  if not point or not point.mapID or not point.x or not point.y then return nil end
  local instance, pos = C_Map.GetWorldPosFromMapPos(point.mapID, CreateVector2D(point.x, point.y))
  if not instance or not pos then return nil end
  local wx, wy = pos:GetXY()
  return { instance = instance, wx = wx, wy = wy, mapID = point.mapID, x = point.x, y = point.y, name = point.name }
end
function R.Player()
  local map = C_Map.GetBestMapForUnit("player")
  local pos = map and C_Map.GetPlayerMapPosition(map, "player")
  if pos then local x, y = pos:GetXY(); return R.World({ mapID = map, x = x, y = y }) end
end

-- Islands cannot be connected by a straight walking edge across the sea.
local function land(point)
  if point.mapID==2521 then return "Zephras Isle" end
  if point.mapID==1438 or point.mapID==1457 then return "Teldrassil" end
  if point.mapID==1444 and point.x and point.x<0.38 and point.y>0.30 and point.y<0.60 then return "Sardor" end
  return point.instance
end
local cities={[1453]="Alliance",[1455]="Alliance",[1457]="Alliance",[1454]="Horde",[1456]="Horde",[1458]="Horde"}
function R.WalkDistance(a,b)
  if land(a)~=land(b) then return math.huge end
  -- Writ walking uses direct dotted bearings. Do not load or call the
  -- archived street graph, even if a previous safer/fastest setting exists.
  local faction=UnitFactionGroup("player")
  if (cities[a.mapID] and cities[a.mapID]~=faction) or (cities[b.mapID] and cities[b.mapID]~=faction) then return math.huge end
  return R.Distance(a,b)
end

-- Build a temporary graph; guesses must never become saved observations or
-- count as a flight-master scan. A scanned departure (even an empty one) wins.
function R.PrepareFlights(flights)
  local graph={nodes=flights.nodes,edges={},estimated={},details={},source=flights}
  local function pathData(ids)
    if type(ids)~="table" or #ids<2 then return end
    local via,seen,seconds={}, {},0
    for i,id in ipairs(ids) do
      local point=flights.nodes[id]
      if not point or seen[id] then return end
      seen[id]=true
      if i>1 then
        local prior=flights.nodes[ids[i-1]]
        if prior.instance~=point.instance then return end
        local hop=flights.connections and flights.connections[ids[i-1]] and flights.connections[ids[i-1]][id]
        hop=hop or R.Distance(prior,point)/32*1.3
        if not F.Positive(hop) then return end
        seconds=seconds+hop
      end
      if i>1 and i<#ids then via[#via+1]=point end
    end
    return seconds,{via=via,flightPath=true}
  end
  local function put(from,to,seconds,detail,estimated)
    graph.edges[from]=graph.edges[from] or {}
    graph.details[from]=graph.details[from] or {}
    graph.estimated[from]=graph.estimated[from] or {}
    graph.edges[from][to]=seconds;graph.details[from][to]=detail;graph.estimated[from][to]=estimated
  end
  -- A scanned destination is a bookable journey, not necessarily one hop.
  -- Prefer its exact ordered preview over the old endpoint-only estimate.
  for from,row in pairs(flights.edges) do
    graph.edges[from]={}
    for to,seconds in pairs(row) do
      local ids=flights.paths and flights.paths[from] and flights.paths[from][to]
      local cost,detail
      if ids and ids[1]==from and ids[#ids]==to then cost,detail=pathData(ids) end
      put(from,to,cost or seconds,detail or {flightPathUnknown=true})
    end
  end
  -- Recover usable paths from older recorded directed hops. Do not reverse
  -- them, invent missing stops, or override an authoritative departure scan.
  local ids={};for id in pairs(flights.nodes) do ids[#ids+1]=id end
  table.sort(ids,function(a,b)return tostring(a)<tostring(b) end)
  for _,from in ipairs(ids) do
    local costs,previous,visited={[from]=0},{},{}
    for _=1,#ids do
      local at,cost
      for _,id in ipairs(ids) do
        if not visited[id] and costs[id] and (not cost or costs[id]<cost) then at,cost=id,costs[id] end
      end
      if not at then break end
      visited[at]=true
      for to,seconds in pairs(flights.connections and flights.connections[at] or {}) do
        if flights.nodes[to] and flights.nodes[at].instance==flights.nodes[to].instance and F.Positive(seconds) and not visited[to] then
          if not costs[to] or cost+seconds<costs[to] then costs[to],previous[to]=cost+seconds,at end
        end
      end
    end
    for to,cost in pairs(costs) do
      local observed=flights.edges[from]
      local existing=graph.details[from] and graph.details[from][to]
      if to~=from and (not observed or observed[to]) and not (existing and existing.flightPath) then
        local path,at={},to
        while at do table.insert(path,1,at);at=previous[at] end
        local _,detail=pathData(path)
        if detail then
          detail.estimatedPath=#path>2
          put(from,to,cost,detail)
        end
      end
    end
  end
  -- Legacy network estimates are only a fallback when no connecting path
  -- has been recorded. Never let a guessed straight edge beat known hops.
  for hub,row in pairs(flights.edges) do
    local members={[hub]=true}
    for to,seconds in pairs(row) do if F.Positive(seconds) and flights.nodes[to] then members[to]=true end end
    for from in pairs(members) do
      for to in pairs(members) do
        local a,b=flights.nodes[from],flights.nodes[to]
        if from~=to and a and b and a.instance==b.instance and not flights.edges[from] and not (graph.edges[from] and graph.edges[from][to]) then
          put(from,to,math.max(30,R.Distance(a,b)/32*1.6),{flightPathUnknown=true},true)
        end
      end
    end
  end
  return graph
end

function R.FlightNote(step)
  local detail=step.detail
  if detail and detail.estimatedConnection then
    return "Estimated connection — open this flight master to confirm available flights."
  elseif detail and detail.estimatedPath then
    return "Known connecting flights — open the departure flight master to confirm this itinerary."
  elseif detail and detail.flightPathUnknown then
    return "Connecting stops not recorded — open the departure flight master to update the route and time estimate."
  end
end

-- Ordinary travel is a static directed graph. Build it once per plan and
-- reuse each source's shortest-path tree for every delivery-order candidate.
-- Arrival by walking must not prevent taking another transport or a shorter
-- walking connection. Positive distances make walking detours unnecessary.
local plainFlight={mode="Fly"}
local function network(anchors,flights,useFlights,travel)
  local points,index,byPoint={},{},{}
  local function add(p)
    if byPoint[p] then return byPoint[p] end
    points[#points+1]=p;byPoint[p]=#points;return #points
  end
  for _,p in ipairs(anchors) do add(p) end
  if useFlights then
    local ids={};for id in pairs(flights.nodes) do ids[#ids+1]=id end
    table.sort(ids,function(a,b)return tostring(a)<tostring(b) end)
    for _,id in ipairs(ids) do index[id]=add(flights.nodes[id]) end
  end
  for _,link in ipairs(travel and travel.links or {}) do add(link.from);add(link.to) end
  -- Most possible connections are ordinary walks. Store their costs as
  -- numbers, with sparse metadata only for transport, instead of allocating
  -- a table per walking edge on every moving-compass update.
  local edges,edgeInfo={},{}
  local function edge(a,b,seconds,mode,detail)
    if a==b or seconds<0 or seconds>=math.huge then return end
    local old=edges[a][b]
    if not old or seconds<old then
      edges[a][b]=seconds
      if mode~="Travel" then
        edgeInfo[a]=edgeInfo[a] or {}
        edgeInfo[a][b]=mode=="Fly" and not detail and plainFlight or {mode=mode,detail=detail}
      elseif edgeInfo[a] then edgeInfo[a][b]=nil end
    end
  end
  for i,a in ipairs(points) do
    edges[i]={}
    for j,b in ipairs(points) do edge(i,j,R.WalkDistance(a,b)/7,"Travel") end
  end
  if useFlights then
    for from,row in pairs(flights.edges) do
      for to,seconds in pairs(row) do
        if index[from] and index[to] and F.Positive(seconds) then
          local estimated=flights.estimated and flights.estimated[from] and flights.estimated[from][to]
          local detail=flights.details and flights.details[from] and flights.details[from][to]
          if estimated then
            local copy={estimatedConnection=true}
            for key,value in pairs(detail or {}) do copy[key]=value end
            detail=copy
          end
          edge(index[from],index[to],seconds+15,"Fly",detail)
        end
      end
    end
  end
  for _,link in ipairs(travel and travel.links or {}) do
    edge(byPoint[link.from],byPoint[link.to],link.seconds,link.mode,link)
  end
  local trees={}
  return function(from,to)
    if from==to then return 0,{} end
    local source,target=byPoint[from],byPoint[to]
    local tree=trees[source]
    if not tree then
      local costs,previous,visited={[source]=0},{},{}
      for _=1,#points do
        local at,cost
        for i=1,#points do
          if not visited[i] and costs[i] and (not cost or costs[i]<cost) then at,cost=i,costs[i] end
        end
        if not at then break end
        visited[at]=true
        for nextPoint=1,#points do
          local e=edges[at][nextPoint]
          if e and not visited[nextPoint] and (not costs[nextPoint] or cost+e<costs[nextPoint]) then
            costs[nextPoint],previous[nextPoint]=cost+e,at
          end
        end
      end
      tree={costs=costs,previous=previous,paths={}};trees[source]=tree
    end
    local seconds=tree.costs[target] or math.huge
    if seconds==math.huge then return seconds,{} end
    if not tree.paths[target] then
      local steps,at={},target
      while tree.previous[at] do
        local prior=tree.previous[at];local info=edgeInfo[prior] and edgeInfo[prior][at]
        table.insert(steps,1,{from=points[prior],to=points[at],mode=info and info.mode or "Travel",detail=info and info.detail,road=not info and "unknown" or nil})
        at=prior
      end
      tree.paths[target]=steps
    end
    return seconds,tree.paths[target]
  end
end

local function planner(start,stops,flights,useFlights,travel)
  local anchors={start}
  for _,stop in ipairs(stops) do if stop.point then anchors[#anchors+1]=stop.point end end
  for _,p in ipairs(travel and travel.personal or {}) do anchors[#anchors+1]=p.to end
  local base=network(anchors,flights,useFlights,travel)
  local resources,resourceIndex={},{}
  for _,p in ipairs(travel and travel.personal or {}) do resourceIndex[p.resource]=true end
  for name in pairs(resourceIndex) do resources[#resources+1]=name end
  table.sort(resources)
  for i,name in ipairs(resources) do resourceIndex[name]=i end
  -- Between deliveries, origin-independent teleports need only be considered
  -- as the first move: walking or teleporting before the last teleport cannot
  -- improve arrival time. Waiting is charged against the trip's elapsed time.
  -- Keep the best arrival for EACH resource choice, including using none.
  local function choices(from,to,elapsed,used)
    local options,byResource={},{}
    local seconds,steps=base(from,to)
    if seconds<math.huge then options[#options+1]={seconds=seconds,steps=steps} end
    for _,p in ipairs(travel and travel.personal or {}) do
      local r=resourceIndex[p.resource]
      if (used[r] or 0)<((travel.resources or {})[p.resource] or 1) then
        local after,path=base(p.to,to)
        local wait=math.max(0,(p.wait or 0)-elapsed)
        local cost=wait+p.seconds+after
        if cost<math.huge and (not byResource[r] or cost<byResource[r].seconds) then
          byResource[r]={seconds=cost,resource=r,teleport=p,wait=wait,after=path}
        end
      end
    end
    for r=1,#resources do
      local option=byResource[r]
      if option then
        option.from=from
        options[#options+1]=option
      end
    end
    return options
  end
  return choices,resources
end

local function optionSteps(option)
  if option.steps then return option.steps end
  local p=option.teleport
  local steps={{from=option.from,to=p.to,mode=p.mode,detail={id=p.id,resource=p.resource,wait=option.wait}}}
  for _,step in ipairs(option.after) do steps[#steps+1]=step end
  return steps
end

function R.Leg(start,finish,flights,useFlights,travel,elapsed,used)
  if not start or not finish then return math.huge,{} end
  local choices,resources=planner(start,{{point=finish}},flights,useFlights,travel)
  local counts={};for i,name in ipairs(resources) do counts[i]=(used or {})[name] or 0 end
  local best,steps=math.huge,{}
  for _,option in ipairs(choices(start,finish,elapsed or 0,counts)) do
    if option.seconds<best then best,steps=option.seconds,optionSteps(option) end
  end
  return best,steps
end

-- Search delivery order AND remaining travel resources. Earlier arrival
-- dominates later arrival only for the same visited set, location and usage.
-- Large frontiers are ranked with an optimistic remaining-travel bound and
-- trimmed, keeping work bounded in the game client. Never call a trimmed
-- result exact. No zone names or particular delivery combinations are used.
function R.Plan(start,stops,flights,useFlights,travel)
  if not start then return {},stops,0,"exact" end
  local choices,resources=planner(start,stops,flights,useFlights,travel)
  local usable,unresolved={},{}
  for _,stop in ipairs(stops) do
    if stop.point and #choices(start,stop.point,0,{})>0 then usable[#usable+1]=stop
    else unresolved[#unresolved+1]=stop end
  end
  local n=#usable
  if n==0 then return {},unresolved,0,"exact" end
  local limit=n>12 and 12 or (n>9 and 48 or ((n<=6 or #resources==0) and 2048 or 128))
  local mode="exact"
  local optimistic={}
  for i=0,n do
    optimistic[i]={}
    for j=1,n do
      local best=math.huge
      if i~=j then
        -- Ignoring cooldowns and remaining charges is an optimistic bound,
        -- not a candidate journey. Actual choices below enforce both.
        for _,option in ipairs(choices(i==0 and start or usable[i].point,usable[j].point,math.huge,{})) do
          best=math.min(best,option.seconds)
        end
      end
      optimistic[i][j]=best
    end
  end
  local incoming={}
  for j=1,n do
    incoming[j]=math.huge
    for i=0,n do incoming[j]=math.min(incoming[j],optimistic[i][j]) end
  end
  local function rank(state)
    local bound,first=state.total,math.huge
    for j=1,n do
      if state.seen:byte(j)==48 then
        bound=bound+incoming[j]
        first=math.min(first,optimistic[state.at][j]-incoming[j])
      end
    end
    return bound+(first<math.huge and first or 0)
  end
  local empty={};for i=1,#resources do empty[i]=0 end
  local frontier={{at=0,seen=string.rep("0",n),used=empty,total=0,key=""}}
  local best=frontier[1]
  for _=1,n do
    local byKey={}
    for _,state in ipairs(frontier) do
      for j,stop in ipairs(usable) do
        if state.seen:byte(j)==48 then
          for _,option in ipairs(choices(state.at==0 and start or usable[state.at].point,stop.point,state.total,state.used)) do
            local counts={};for r=1,#resources do counts[r]=state.used[r]+(option.resource==r and 1 or 0) end
            local seen=state.seen:sub(1,j-1).."1"..state.seen:sub(j+1)
            local key=seen..":"..j..":"..table.concat(counts,",")
            local total=state.total+option.seconds
            if not byKey[key] or total<byKey[key].total then
              byKey[key]={at=j,seen=seen,used=counts,total=total,parent=state,option=option,key=key}
            end
          end
        end
      end
    end
    local nextFrontier={}
    for _,state in pairs(byKey) do nextFrontier[#nextFrontier+1]=state end
    if #nextFrontier==0 then break end
    if #nextFrontier>limit then
      mode="estimated"
      for _,state in ipairs(nextFrontier) do state.rank=rank(state) end
      table.sort(nextFrontier,function(a,b)
        if a.rank~=b.rank then return a.rank<b.rank end
        if a.total~=b.total then return a.total<b.total end
        return a.key<b.key
      end)
      for i=#nextFrontier,limit+1,-1 do nextFrontier[i]=nil end
    else
      table.sort(nextFrontier,function(a,b)
        if a.total~=b.total then return a.total<b.total end
        return a.key<b.key
      end)
    end
    frontier=nextFrontier;best=frontier[1]
    for _,state in ipairs(frontier) do if state.total<best.total then best=state end end
  end
  -- A bounded search must never discard a cheaper complete greedy route.
  -- Keep that inexpensive baseline as a candidate, not as the only strategy.
  if mode=="estimated" then
    local greedy={at=0,seen=string.rep("0",n),used=empty,total=0}
    for _=1,n do
      local choice,nextStop
      for j,stop in ipairs(usable) do
        if greedy.seen:byte(j)==48 then
          for _,option in ipairs(choices(greedy.at==0 and start or usable[greedy.at].point,stop.point,greedy.total,greedy.used)) do
            if not choice or option.seconds<choice.seconds then choice,nextStop=option,j end
          end
        end
      end
      if not choice then break end
      local counts={};for r=1,#resources do counts[r]=greedy.used[r]+(choice.resource==r and 1 or 0) end
      greedy={at=nextStop,seen=greedy.seen:sub(1,nextStop-1).."1"..greedy.seen:sub(nextStop+1),
        used=counts,total=greedy.total+choice.seconds,parent=greedy,option=choice}
    end
    local _,greedyCount=greedy.seen:gsub("1","")
    local _,bestCount=best.seen:gsub("1","")
    if greedyCount>bestCount or (greedyCount==bestCount and greedy.total<best.total) then best=greedy end
  end
  local result,at={},best
  while at.parent do
    table.insert(result,1,{stop=usable[at.at],seconds=at.option.seconds,steps=optionSteps(at.option)})
    at=at.parent
  end
  for j,stop in ipairs(usable) do if best.seen:byte(j)==48 then unresolved[#unresolved+1]=stop end end
  return result,unresolved,best.total,mode
end
