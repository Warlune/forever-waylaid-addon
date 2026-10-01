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

-- A complete walking graph plus directed, observed taxi routes. Dijkstra
-- returns the actual selected steps, so the route list explains its estimate.
function R.Leg(start, finish, flights, useFlights)
  local points, index = {start, finish}, {}
  if useFlights then
    for id, node in pairs(flights.nodes) do
      if node.instance == start.instance then points[#points + 1] = node; index[id] = #points end
    end
  end
  local costs, visited, previous, modes = {[1] = 0}, {}, {}, {}
  local flightEdges = {}
  if useFlights then
    for from, edges in pairs(flights.edges) do
      if index[from] then
        flightEdges[index[from]] = {}
        for to, seconds in pairs(edges) do
          if index[to] and F.Positive(seconds) then flightEdges[index[from]][index[to]] = seconds + 15 end
        end
      end
    end
  end
  for _ = 1, #points do
    local at, cost
    for i = 1, #points do
      if not visited[i] and costs[i] and (not cost or costs[i] < cost) then at, cost = i, costs[i] end
    end
    if not at or at == 2 then break end
    visited[at] = true
    for to = 1, #points do
      if not visited[to] then
        local weight, mode = R.Distance(points[at], points[to]) / 7, "Travel"
        local taxi = flightEdges[at] and flightEdges[at][to]
        if taxi and taxi < weight then weight, mode = taxi, "Fly" end
        if weight < math.huge and (not costs[to] or cost + weight < costs[to]) then
          costs[to], previous[to], modes[to] = cost + weight, at, mode
        end
      end
    end
  end
  local steps, at = {}, 2
  while previous[at] do
    table.insert(steps, 1, { from = points[previous[at]], to = points[at], mode = modes[at] })
    at = previous[at]
  end
  return costs[2] or math.huge, steps
end

-- Exact open-path visit order for up to 9 stops; nearest-next beyond that.
-- Missing/cross-continent routes are left unresolved, never treated as free.
function R.Plan(start, stops, flights, useFlights)
  local usable, unresolved = {}, {}
  for _, stop in ipairs(stops) do
    if start and stop.point and stop.point.instance == start.instance then usable[#usable + 1] = stop
    else unresolved[#unresolved + 1] = stop end
  end
  local n, matrix, paths = #usable, {}, {}
  if n == 0 then return {}, unresolved, 0, "exact" end
  for i = 0, n do
    matrix[i], paths[i] = {}, {}
    for j = 1, n do
      if i ~= j then matrix[i][j], paths[i][j] = R.Leg(i == 0 and start or usable[i].point, usable[j].point, flights, useFlights) end
    end
  end
  local order, mode = {}, n <= 9 and "exact" or "estimated"
  if n <= 9 then
    local memo = {}
    local function solve(at, mask)
      if mask == 2^n - 1 then return 0 end
      local key = at .. ":" .. mask
      if memo[key] then return memo[key].cost end
      local best, nextStop = math.huge, nil
      for j = 1, n do
        local bit = 2^(j - 1)
        if math.floor(mask / bit) % 2 == 0 then
          local cost = matrix[at][j] + solve(j, mask + bit)
          if cost < best then best, nextStop = cost, j end
        end
      end
      memo[key] = {cost = best, nextStop = nextStop}
      return best
    end
    solve(0, 0)
    local at, mask = 0, 0
    for _ = 1, n do
      local j = memo[at .. ":" .. mask].nextStop
      if not j then break end
      order[#order + 1] = j; at, mask = j, mask + 2^(j - 1)
    end
  else
    local seen, at = {}, 0
    for _ = 1, n do
      local best, nextStop = math.huge, nil
      for j = 1, n do if not seen[j] and matrix[at][j] < best then best, nextStop = matrix[at][j], j end end
      if not nextStop then break end
      order[#order + 1] = nextStop; seen[nextStop], at = true, nextStop
    end
  end
  local result, total, at, seen = {}, 0, 0, {}
  for _, j in ipairs(order) do
    result[#result + 1] = { stop = usable[j], seconds = matrix[at][j], steps = paths[at][j] }
    total, at, seen[j] = total + matrix[at][j], j, true
  end
  for j, stop in ipairs(usable) do if not seen[j] then unresolved[#unresolved + 1] = stop end end
  return result, unresolved, total, mode
end
