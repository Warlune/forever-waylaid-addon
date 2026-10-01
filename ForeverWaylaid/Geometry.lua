local _,F=...
local G={};F.Geometry=G
function G.Atan2(y,x)
  if math.atan2 then return math.atan2(y,x) end
  if x>0 then return math.atan(y/x) end
  if x<0 then return math.atan(y/x)+(y>=0 and math.pi or -math.pi) end
  return y>0 and math.pi/2 or y<0 and -math.pi/2 or 0
end
-- Clip segments even when both endpoints are outside the visible map.
function G.Rect(x1,y1,x2,y2,left,top,right,bottom)
  local dx,dy=x2-x1,y2-y1;local first,last=0,1
  local p,q={-dx,dx,-dy,dy},{x1-left,right-x1,y1-top,bottom-y1}
  for i=1,4 do
    if p[i]==0 then if q[i]<0 then return end
    else
      local r=q[i]/p[i]
      if p[i]<0 then first=math.max(first,r) else last=math.min(last,r) end
      if first>last then return end
    end
  end
  return x1+first*dx,y1+first*dy,x1+last*dx,y1+last*dy
end
function G.Circle(x1,y1,x2,y2,radius)
  local dx,dy=x2-x1,y2-y1;local a=dx*dx+dy*dy
  if a<0.00001 then if x1*x1+y1*y1<=radius*radius then return x1,y1,x2,y2 end;return end
  local b=2*(x1*dx+y1*dy);local c=x1*x1+y1*y1-radius*radius
  local disc=b*b-4*a*c;if disc<0 then return end
  local first=math.max(0,(-b-math.sqrt(disc))/(2*a));local last=math.min(1,(-b+math.sqrt(disc))/(2*a))
  if first>last then return end
  return x1+first*dx,y1+first*dy,x1+last*dx,y1+last*dy
end
-- C_Map world axes are north, west. UI axes are east, north.
function G.Relative(player,target,facing)
  if not player or not target or player.instance~=target.instance then return end
  local east,north=player.wy-target.wy,target.wx-player.wx
  local cos,sin=math.cos(facing or 0),math.sin(facing or 0)
  return east*cos+north*sin,-east*sin+north*cos
end
function G.Bearing(player,target,facing)
  local east,north=G.Relative(player,target,0);if not east then return end
  return G.Atan2(-east,north)-(facing or 0)
end
function G.Project(point,map)
  if not point then return end
  local id,pos=C_Map.GetMapPosFromWorldPos(point.instance,CreateVector2D(point.wx,point.wy),map)
  if id~=map or not pos then return end
  return pos:GetXY()
end
