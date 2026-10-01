local _,F=...
local R={};F.Roads=R
-- Road geometry comes from reviewed, revealed map art; see RoadData.lua.
-- Only explicit adjoining edges are connected. Close roads are not joined
-- automatically across walls, riverbanks or different floors.
local function distance(a,b)return F.Route.Distance(a,b)end
local function sameFloor(a,b)
  return not a.z or not b.z or math.abs(a.z-b.z)<4
end
function R.Invalidate() R.graph=nil;R.cache={};R.cacheSize=0 end
function R.Graph()
  if R.graph then return R.graph end
  local g={nodes={},edges={},adj={},buckets={}}
  local function node(p)
    local key=p.instance..":"..math.floor(p.wx)..":"..math.floor(p.wy)
    for _,i in ipairs(g.buckets[key] or {})do if distance(p,g.nodes[i])<1 and sameFloor(p,g.nodes[i]) then return i end end
    local i=#g.nodes+1;g.nodes[i]=p;g.buckets[key]=g.buckets[key] or {};table.insert(g.buckets[key],i);g.adj[i]={};return i
  end
  local function edge(a,b,source)
    if distance(a,b)<0.1 or distance(a,b)==math.huge then return end
    local i,j=node(a),node(b)
    if i==j then return end
    g.edges[#g.edges+1]={a=i,b=j,length=distance(a,b),source=source}
    g.adj[i][#g.adj[i]+1]={to=j,length=distance(a,b)}
    g.adj[j][#g.adj[j]+1]={to=i,length=distance(a,b)}
  end
  for _,line in ipairs(F.roadData.lines)do
    local previous
    for _,p in ipairs(line.points)do
      local world=F.Route.World({mapID=p[1],x=p[2]/100,y=p[3]/100,name=line.name})
      if previous and world then edge(previous,world,"mapped")end
      previous=world
    end
  end
  R.graph=g;return g
end
local function closest(p,g)
  local best
  for i,e in ipairs(g.edges)do
    local a,b=g.nodes[e.a],g.nodes[e.b]
    if p.instance==a.instance and sameFloor(p,a) and sameFloor(p,b) then
      local dx,dy=b.wx-a.wx,b.wy-a.wy
      local t=math.max(0,math.min(1,((p.wx-a.wx)*dx+(p.wy-a.wy)*dy)/(dx*dx+dy*dy)))
      local q={instance=a.instance,wx=a.wx+t*dx,wy=a.wy+t*dy,mapID=a.mapID,name=a.name or "Follow the road"}
      q.x,q.y=F.Geometry.Project(q,a.mapID)
      local gap=distance(p,q)
      if gap<=45 and (not best or gap<best.gap)then best={edge=i,t=t,point=q,gap=gap}end
    end
  end
  return best
end
local function findPath(a,b)
  if a.instance~=b.instance then return nil end
  local g=R.Graph();local first,last=closest(a,g),closest(b,g)
  if not first or not last then return nil end
  local costs,prev,visited={}, {},{}
  local firstEdge=g.edges[first.edge]
  costs[firstEdge.a]=first.gap+first.t*firstEdge.length
  costs[firstEdge.b]=first.gap+(1-first.t)*firstEdge.length
  local targetEdge=g.edges[last.edge]
  local heap={}
  local function push(at,cost)
    local i=#heap+1;heap[i]={at=at,cost=cost}
    while i>1 do local parent=math.floor(i/2);if heap[parent].cost<=cost then break end;heap[i],heap[parent]=heap[parent],heap[i];i=parent end
  end
  local function pop()
    local root=heap[1];local last=table.remove(heap)
    if #heap>0 then
      heap[1]=last;local i=1
      while i*2<=#heap do
        local c=i*2;if c<#heap and heap[c+1].cost<heap[c].cost then c=c+1 end
        if heap[i].cost<=heap[c].cost then break end
        heap[i],heap[c]=heap[c],heap[i];i=c
      end
    end
    return root.at,root.cost
  end
  for at,cost in pairs(costs)do push(at,cost)end
  while #heap>0 do
    local at,cost=pop()
    if not visited[at] then
      visited[at]=true
      if visited[targetEdge.a] and visited[targetEdge.b] then break end
      for _,e in ipairs(g.adj[at])do
        local to=e.to
        if not visited[to] and (not costs[to] or cost+e.length<costs[to])then
          costs[to]=cost+e.length;prev[to]=at;push(to,costs[to])
        end
      end
    end
  end
  local finalEdge=g.edges[last.edge]
  local endNode=finalEdge.a;local total=(costs[endNode] or math.huge)+last.t*finalEdge.length+last.gap
  local reverse=(costs[finalEdge.b] or math.huge)+(1-last.t)*finalEdge.length+last.gap
  if reverse<total then endNode,total=finalEdge.b,reverse end
  local direct=first.edge==last.edge
  local directCost=direct and (first.gap+math.abs(last.t-first.t)*firstEdge.length+last.gap) or math.huge
  if math.min(total,directCost)==math.huge then return nil end
  local points={};local source=firstEdge.source
  if directCost<=total then total=directCost
  else
    local at=endNode
    while at do
      table.insert(points,1,g.nodes[at]);at=prev[at]
    end
  end
  table.insert(points,1,first.point);points[#points+1]=last.point
  local segments={}
  local function segment(from,to,kind)
    if distance(from,to)>0.2 then segments[#segments+1]={from=from,to=to,mode="Travel",road=kind,distance=distance(from,to)}end
  end
  segment(a,first.point,"approach")
  for i=1,#points-1 do segment(points[i],points[i+1],source)end
  segment(last.point,b,"approach")
  return total,segments
end
function R.Path(a,b)
  if not a or not b then return nil end
  R.cache=R.cache or {};R.cacheSize=R.cacheSize or 0
  local key=table.concat({a.instance,a.wx,a.wy,a.z or "?",b.instance,b.wx,b.wy,b.z or "?"},":")
  local cached=R.cache[key]
  if cached then return cached[1],cached[2] end
  local d,segments=findPath(a,b)
  if R.cacheSize>=5000 then R.cache={};R.cacheSize=0 end
  R.cache[key]={d,segments};R.cacheSize=R.cacheSize+1
  return d,segments
end
