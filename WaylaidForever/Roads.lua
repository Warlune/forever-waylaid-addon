local _,F=...
local R={};F.Roads=R
local cell=128
local function distance(a,b)return F.Route.Distance(a,b)end
local function sameFloor(a,b)return not a.z or not b.z or math.abs(a.z-b.z)<4 end
local function faction()return UnitFactionGroup("player") or "Unknown" end
function R.Mode()return F.db and F.db.settings.routeMode=="fastest" and "fastest" or "safer" end
function F.SetRouteMode(mode)
  if mode~="safer" and mode~="fastest" then return end
  F.db.settings.routeMode=mode;R.Invalidate();F.Refresh()
end
local function multiplier(kind)return R.Mode()=="safer" and (kind=="corridor" and 4 or kind=="transition" and 2 or 1) or 1 end
local function key(p)return table.concat({p.instance,p.wx,p.wy,p.z or "?"},":")end
local function bucket(instance,x,y)return instance..":"..x..":"..y end
function R.Invalidate() R.graph=nil;R.cache={};R.cacheSize=0;R.trees={};R.treeCount=0;R.stats={trees=0,snapChecks=0} end
function R.Graph()
  local context=faction()..":"..R.Mode()
  if R.context~=context then R.Invalidate();R.context=context end
  if R.graph then return R.graph end
  local g={nodes={},edges={},adj={},buckets={},grid={},components={},exits={}}
  local function node(p)
    local k=bucket(p.instance,math.floor(p.wx),math.floor(p.wy))
    for _,i in ipairs(g.buckets[k] or {})do if distance(p,g.nodes[i])<0.1 and sameFloor(p,g.nodes[i])then return i end end
    local i=#g.nodes+1;g.nodes[i]=p;g.buckets[k]=g.buckets[k] or {};table.insert(g.buckets[k],i);g.adj[i]={};return i
  end
  local function edge(a,b,kind)
    local length=distance(a,b)
    if length<0.1 or length==math.huge then return end
    local i,j=node(a),node(b);if i==j then return end
    local id=#g.edges+1
    g.edges[id]={a=i,b=j,length=length,kind=kind,weight=length*multiplier(kind)}
    g.adj[i][#g.adj[i]+1]={to=j,edge=id};g.adj[j][#g.adj[j]+1]={to=i,edge=id}
    -- Long zone handoffs cannot attract a player standing beside an imagined
    -- segment through a mountain. Only actual road/corridor edges are snapped.
    if kind~="transition" then
      for x=math.floor(math.min(a.wx,b.wx)/cell),math.floor(math.max(a.wx,b.wx)/cell)do
        for y=math.floor(math.min(a.wy,b.wy)/cell),math.floor(math.max(a.wy,b.wy)/cell)do
          local k=bucket(a.instance,x,y);g.grid[k]=g.grid[k] or {};g.grid[k][#g.grid[k]+1]=id
        end
      end
    end
  end
  for _,line in ipairs(F.roadData.lines)do
    local owner=line.faction
    if not owner or owner=="Both" or owner==faction() then
      local previous
      for _,p in ipairs(line.points)do
        local world=F.Route.World({mapID=p[1],x=p[2]/100,y=p[3]/100,name=line.name})
        if previous and world then edge(previous,world,line.kind or "road")end
        previous=world
      end
      for city,name in pairs(F.roadData.cityExits or {})do
        if name==line.name and #line.points==2 then
          local a,b=line.points[1],line.points[2]
          if b[1]==city then a,b=b,a end
          if a[1]==city then
            local inside=F.Route.World({mapID=a[1],x=a[2]/100,y=a[3]/100,name=name})
            local outside=F.Route.World({mapID=b[1],x=b[2]/100,y=b[3]/100,name=name})
            if inside and outside then
              inside.cityGate=true;outside.cityGate=true
              g.exits[city]={inside=inside,outside=outside}
            end
          end
        end
      end
    end
  end
  -- Component checks make impossible destination queries constant-time.
  for i=1,#g.nodes do if not g.components[i] then
    local stack={i};g.components[i]=i
    while #stack>0 do
      local at=table.remove(stack)
      for _,e in ipairs(g.adj[at])do if not g.components[e.to] then g.components[e.to]=i;stack[#stack+1]=e.to end end
    end
  end end
  R.graph=g;return g
end
local function closest(p,g)
  local best,seen=nil,{}
  for x=math.floor((p.wx-45)/cell),math.floor((p.wx+45)/cell)do
    for y=math.floor((p.wy-45)/cell),math.floor((p.wy+45)/cell)do
      for _,i in ipairs(g.grid[bucket(p.instance,x,y)] or {})do if not seen[i] then
        seen[i]=true;R.stats.snapChecks=R.stats.snapChecks+1
        local e=g.edges[i];local a,b=g.nodes[e.a],g.nodes[e.b]
        if sameFloor(p,a) and sameFloor(p,b)then
          local dx,dy=b.wx-a.wx,b.wy-a.wy
          local t=math.max(0,math.min(1,((p.wx-a.wx)*dx+(p.wy-a.wy)*dy)/(dx*dx+dy*dy)))
          local q={instance=a.instance,wx=a.wx+t*dx,wy=a.wy+t*dy,mapID=a.mapID,name=a.name or "Follow the road"}
          q.x,q.y=F.Geometry.Project(q,a.mapID)
          local gap=distance(p,q)
          if gap<=45 and (not best or gap<best.gap-0.01 or (math.abs(gap-best.gap)<=0.01 and e.weight/e.length<g.edges[best.edge].weight/g.edges[best.edge].length))then best={edge=i,t=t,point=q,gap=gap}end
        end
      end end
    end
  end
  return best
end
local function destinationTree(last,g)
  local k=last.edge..":"..last.t
  if R.trees[k]then return R.trees[k]end
  local e=g.edges[last.edge]
  local tree={costs={[e.a]=last.t*e.weight,[e.b]=(1-last.t)*e.weight},next={},edges={}}
  local heap,visited={},{}
  local function push(at,cost)
    local i=#heap+1;heap[i]={at=at,cost=cost}
    while i>1 do local p=math.floor(i/2);if heap[p].cost<=cost then break end;heap[i],heap[p]=heap[p],heap[i];i=p end
  end
  local function pop()
    local root=heap[1];local tail=table.remove(heap)
    if #heap>0 then
      heap[1]=tail;local i=1
      while i*2<=#heap do local c=i*2;if c<#heap and heap[c+1].cost<heap[c].cost then c=c+1 end
        if heap[i].cost<=heap[c].cost then break end;heap[i],heap[c]=heap[c],heap[i];i=c end
    end
    return root.at,root.cost
  end
  for at,cost in pairs(tree.costs)do push(at,cost)end
  while #heap>0 do
    local at,cost=pop()
    if not visited[at]then
      visited[at]=true
      for _,entry in ipairs(g.adj[at])do
        local to,edge=entry.to,g.edges[entry.edge];local new=cost+edge.weight
        if not visited[to] and (not tree.costs[to] or new<tree.costs[to])then
          tree.costs[to]=new;tree.next[to]=at;tree.edges[to]=entry.edge;push(to,new)
        end
      end
    end
  end
  -- Bounded destination cache: moving the start does not rebuild these trees.
  if R.treeCount>=128 then R.trees={};R.treeCount=0 end
  R.trees[k]=tree;R.treeCount=R.treeCount+1;R.stats.trees=R.stats.trees+1
  return tree
end
function R.Restricted(p)
  local owner=F.roadData.cityFactions and F.roadData.cityFactions[p.mapID]
  return owner and owner~=faction()
end
local function findPath(a,b,g)
  if a.instance~=b.instance then return nil end
  if R.Restricted(a) or R.Restricted(b)then return nil,nil,true end
  local first,last=closest(a,g),closest(b,g)
  if not first or not last then return nil end
  local e,target=g.edges[first.edge],g.edges[last.edge]
  if g.components[e.a]~=g.components[target.a]then return nil,nil,true end
  local tree=destinationTree(last,g)
  local at=e.a;local cost=(tree.costs[at] or math.huge)+first.t*e.weight
  local other=(tree.costs[e.b] or math.huge)+(1-first.t)*e.weight
  if other<cost then at,cost=e.b,other end
  local direct=first.edge==last.edge and math.abs(last.t-first.t)*e.weight or math.huge
  local segments,total={},0
  local function segment(from,to,kind)
    local d=distance(from,to)
    if d>0.2 then
      segments[#segments+1]={from=from,to=to,mode="Travel",road=(kind=="road" or kind=="corridor") and "mapped" or kind,terrain=kind,distance=d}
      total=total+d
    end
  end
  segment(a,first.point,"approach")
  if direct<=cost then segment(first.point,last.point,e.kind)
  else
    segment(first.point,g.nodes[at],e.kind)
    while tree.next[at]do
      local to=tree.next[at];segment(g.nodes[at],g.nodes[to],g.edges[tree.edges[at]].kind);at=to
    end
    segment(g.nodes[at],last.point,target.kind)
  end
  segment(last.point,b,"approach")
  return total,segments
end
local function throughCityGates(a,b,g)
  if a.mapID==b.mapID then return end
  local departure,arrival=g.exits[a.mapID],g.exits[b.mapID]
  if not departure and not arrival then return end
  local anchors={a}
  if departure then anchors[#anchors+1]=departure.inside;anchors[#anchors+1]=departure.outside end
  if arrival then anchors[#anchors+1]=arrival.outside;anchors[#anchors+1]=arrival.inside end
  anchors[#anchors+1]=b
  local total,segments=0,{}
  for index=2,#anchors do
    local from,to=anchors[index-1],anchors[index]
    local gap=distance(from,to)
    if gap==math.huge then return end
    if gap>0.2 then
      local d,part,blocked=findPath(from,to,g)
      if blocked then return nil,nil,true end
      if not d then
        d=gap;part={{from=from,to=to,mode="Travel",road="unknown",distance=gap}}
      end
      total=total+d
      for _,step in ipairs(part)do segments[#segments+1]=step end
    end
  end
  return total,segments
end
function R.Path(a,b)
  if not a or not b then return nil end
  local g=R.Graph();local k=key(a)..":"..key(b)
  local cached=R.cache[k];if cached then return cached[1],cached[2],cached[3]end
  local d,segments,blocked=findPath(a,b,g)
  if not d and not blocked then d,segments,blocked=throughCityGates(a,b,g)end
  if R.cacheSize>=256 then R.cache={};R.cacheSize=0 end
  R.cache[k]={d,segments,blocked};R.cacheSize=R.cacheSize+1
  return d,segments,blocked
end
R.Invalidate()
