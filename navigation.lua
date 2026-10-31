-- Room-local pathfinding, independent of screen projection and presentation art.
local Scenery=require('scenery')
local Shape=require('terrain_shape')
local N={}
function N.clear(room,x,y)
 if not Shape.contains(room,x,y)or Scenery.blocked(room,x,y)then return false end
 for _,p in ipairs(room.pillars)do if math.abs(x-p.x)<.48 and math.abs(y-p.y)<.48 then return false end end
 return true
end
function N.segment(room,x,y,tx,ty)
 local count=math.max(1,math.ceil(math.sqrt((tx-x)^2+(ty-y)^2)/.12))
 for i=0,count do local q=i/count;if not N.clear(room,x+(tx-x)*q,y+(ty-y)*q)then return false end end
 return true
end
function N.path(room,x,y,tx,ty)
 if not N.clear(room,tx,ty)then return nil end
 if N.segment(room,x,y,tx,ty)then return {{x=tx,y=ty}}end
 -- A half-tile grid preserves enough clearance around the existing pillars.
 local step=.5;local width=room.width*2-1;local height=room.height*2-1
 local function node(a,b)return(b-1)*width+a end
 local function coords(i)local a=(i-1)%width+1;local b=math.floor((i-1)/width)+1;return a*step,b*step end
 local function nearest(px,py)
  local best,dist
  for b=1,height do for a=1,width do local xx,yy=a*step,b*step
   local d=(xx-px)^2+(yy-py)^2
   if(not dist or d<dist)and N.clear(room,xx,yy)and N.segment(room,px,py,xx,yy)then
    best=node(a,b);dist=d
   end
  end end
  return best
 end
 local first,last=nearest(x,y),nearest(tx,ty);if not first or not last then return nil end
 local queue={first};local head=1;local parent={[first]=false}
 while head<=#queue do local current=queue[head];head=head+1
  if current==last then
   local path={{x=tx,y=ty}};local i=last
   while i do local xx,yy=coords(i);table.insert(path,1,{x=xx,y=yy});i=parent[i]end
   return path
  end
  local cx,cy=coords(current);local a,b=cx/step,cy/step
  for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}})do local aa,bb=a+d[1],b+d[2]
   if aa>=1 and aa<=width and bb>=1 and bb<=height then local next=node(aa,bb)
    if parent[next]==nil and N.clear(room,aa*step,bb*step)and N.clear(room,(cx+aa*step)/2,(cy+bb*step)/2)then parent[next]=current;queue[#queue+1]=next end
   end
  end
 end
 return nil
end
return N
