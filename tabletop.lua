-- Connected, persistent-discovery tabletop presentation. Room IDs and rules stay stable.
local V=require('visual')
local Scenery=require('scenery')
local Campaign=require('campaign')
local P=require('progress')
local Art=require('cartoon')
local Bridge=require('bridge')
local T={zoom=.68,panX=0,panY=0}
-- Geometry is a presentation layout, independent of saved room-local coordinates.
local layout={{0,0},{1,0},{2,0},{2,1},{0,1},{1,2},{2,3},{-1,0},{1,-1},{3,0},{0,-1},{3,1},{-1,1},{1,3},{3,3}}
function T.origin(id)local _,s=Campaign.info(id);return layout[s][1]*14,layout[s][2]*14 end
function T.position(id,x,y)local ox,oy=T.origin(id);return ox+x,oy+y end
function T.gate(r,side)
 if side=='NE'then return r.width/2,.15 elseif side=='SW'then return r.width/2,r.height-.15 elseif side=='NW'then return .15,r.height/2 else return r.width-.15,r.height/2 end
end
function T.snap(id,player)
 T.cx,T.cy=T.position(id,player.x,player.y);T.px,T.py=T.cx,T.cy;T.walk=nil;T.panX=0;T.panY=0
end
function T.cross(from,old,target,player,side,opposite,rooms)
 local ax,ay=T.position(from,old.x,old.y);local bx,by=T.position(target,player.x,player.y)
 local gx,gy=T.gate(rooms[from],side);gx,gy=T.position(from,gx,gy)
 local hx,hy=T.gate(rooms[target],opposite);hx,hy=T.position(target,hx,hy)
 T.walk={points={{ax,ay},{gx,gy},{hx,hy},{bx,by}},time=0};T.panX=0;T.panY=0
end
function T.update(dt,rooms,id,player,p)
 if p then
  if T.journey~=p then
   T.journey=p;T.known={};T.reveals={};for seen in pairs(p.seen)do T.known[seen]=true end
  else
   for seen in pairs(p.seen)do if not T.known[seen]then T.known[seen]=true;T.reveals[seen]=0 end end
   for seen,age in pairs(T.reveals)do age=age+dt;if age>=1 then T.reveals[seen]=nil else T.reveals[seen]=age end end
  end
 end
 local x,y=T.position(id,player.x,player.y)
 if T.walk then
  local walk=T.walk;walk.time=math.min(1,walk.time+dt/1.1)
  local points=walk.points;local lengths,total={},0
  for i=1,3 do local a,b=points[i],points[i+1];lengths[i]=math.sqrt((b[1]-a[1])^2+(b[2]-a[2])^2);total=total+lengths[i]end
  local distance=walk.time*total
  for i=1,3 do if distance<=lengths[i] or i==3 then
   local q=lengths[i]>0 and math.min(1,distance/lengths[i])or 1;local a,b=points[i],points[i+1];x=a[1]+(b[1]-a[1])*q;y=a[2]+(b[2]-a[2])*q;break
  else distance=distance-lengths[i]end end
  if walk.time>=1 then T.walk=nil end
 end
 if T.px then
  local delta=(x-y)-(T.px-T.py);if math.abs(delta)>.002 then T.face=delta<0 and -1 or 1 end
  T.moving=math.abs(x-T.px)+math.abs(y-T.py)>.002
 end
 T.px,T.py=x,y
 if not T.cx then T.cx,T.cy=x,y end
 local f=1-math.exp(-dt*5);T.cx=T.cx+(x-T.cx)*f;T.cy=T.cy+(y-T.cy)*f
end
function T.drag(dx,dy)T.panX=T.panX+dx;T.panY=T.panY+dy end
function T.zoomBy(amount)T.zoom=math.max(.38,math.min(1.25,T.zoom+amount))end
function T.recenter()T.panX=0;T.panY=0 end
local function floor(project,r,id,p)
 local a,b=project(0,0);local left=project(0,r.height);local right=project(r.width,0)
 local width=right-left
 local atlas=Art.load('terrain');local rect=atlas.rects[r.level]
 local height=width*rect[4]/rect[3]
 -- The illustrated top surface is a 2:1 diamond, with soil/stone depth below.
 Art.drawRect('terrain',r.level,left,b-2*T.zoom,width,height)
 if r.slot==11 and not p.lightOn then
  local g=love.graphics;local c,d=project(r.width,0);local e,f=project(r.width,r.height);local j,k=project(0,r.height)
  g.setColor(.10,.21,.31,.24);g.polygon('fill',a,b,c,d,e,f,j,k)
 end
end
local function arch(project,r,side,target,p)
 local g=love.graphics;local x,y=T.gate(r,side);local s=T.zoom;local dx,dy=0,0
 if side=='NE'or side=='SW'then dx=.7 else dy=.7 end
 local ax,ay=project(x-dx,y-dy);local bx,by=project(x+dx,y+dy)
 local path={ax,ay}
 for i=0,18 do local q=i/18;path[#path+1]=ax+(bx-ax)*q;path[#path+1]=ay+(by-ay)*q-31*s-math.sin(q*math.pi)*20*s end
 path[#path+1]=bx;path[#path+1]=by
 g.setLineJoin('bevel');g.setLineWidth(21*s);V.color({.61,.41,.25});g.line(path)
 g.setLineWidth(16*s);V.color({.99,.85,.60});g.line(path)
 g.setLineWidth(4*s);V.color({1,.96,.78});g.line(path)
 for _,point in ipairs({{ax,ay},{bx,by}})do
  V.color({.67,.45,.27});g.ellipse('fill',point[1],point[2],11*s,5*s)
  V.color({.98,.82,.54});g.ellipse('fill',point[1],point[2]-4*s,11*s,5*s)
 end
 local px,py=project(x,y,58);V.color(p:locked(target)and{.98,.65,.22}or{.24,.70,.69});g.circle('fill',px,py,9*s)
 V.color({1,.93,.70});g.setLineWidth(1.5*s);g.circle('line',px,py,9*s);g.setLineWidth(1)
 V.color({1,.97,.80});g.circle('fill',px,py-1*s,2.4*s);g.polygon('fill',px-1.5*s,py,px+1.5*s,py,px+2*s,py+5*s,px-2*s,py+5*s)
end
local function column(project,p,level)
 local g=love.graphics;local s=T.zoom;local x,y=project(p.x,p.y)
 g.setColor(.20,.29,.22,.17);g.ellipse('fill',x,y,13*s,5*s)
 V.color({.67,.49,.33});g.rectangle('fill',x-6*s,y-26*s,12*s,25*s,4*s,4*s)
 V.color({.95,.82,.58});g.rectangle('fill',x-4*s,y-26*s,7*s,25*s,3*s,3*s)
 Art.draw('scenery',6,x,y-22*s,42*s,40*s,.5,1)
end
local function fog(project,r,time,strength)
 strength=strength or 1
 local g=love.graphics
 -- Only anonymous mist is drawn: unrevealed buildings, labels and rewards never render.
 local cx,cy=project(r.width/2,r.height/2)
 for layer=4,1,-1 do g.setColor(.85,.92,.94,.16*strength);g.ellipse('fill',cx,cy,(r.width+r.height)*13*T.zoom+layer*7*T.zoom,(r.width+r.height)*6.5*T.zoom+layer*5*T.zoom)end
 for i=1,19 do local x=.5+((i*19)%81)/10;local y=.5+((i*23)%79)/10
  local xx,yy=project(math.min(r.width-.4,x),math.min(r.height-.4,y),8+math.sin(time*.6+i)*3)
  g.setColor(.93,.97,.98,.75*strength);g.ellipse('fill',xx,yy,(32+i%3*9)*T.zoom,(16+i%3*3)*T.zoom)
 end

end
function T.visibility(rooms,id,p)
 local visible,frontier={},{}
 for roomId in pairs(p.seen)do if rooms[roomId].level==rooms[id].level then
  visible[#visible+1]=roomId
  for _,target in pairs(rooms[roomId].visualExits)do if not p.seen[target]then frontier[target]=true end end
 end end
 return visible,frontier
end
function T.glide(from,old,target,player)
 local ax,ay=T.position(from,old.x,old.y);local bx,by=T.position(target,player.x,player.y)
 T.walk={points={{ax,ay},{ax,ay},{bx,by},{bx,by}},time=0};T.panX=0;T.panY=0
end
function T.draw(rooms,id,player,p,character,time,fonts)
 local g=love.graphics;local w,h=g.getDimensions();local current=rooms[id]
 local s=T.zoom;local cx,cy=T.cx,T.cy
 if not cx then cx,cy=T.position(id,player.x,player.y)end
 local ox=w/2-(cx-cy)*30*s+T.panX;local oy=h*.49-(cx+cy)*15*s+T.panY
 local function global(x,y,z)return ox+(x-y)*30*s,oy+(x+y)*15*s-(z or 0)*s end
 local function projection(roomId)local rx,ry=T.origin(roomId);return function(x,y,z)return global(rx+x,ry+y,z)end end
 T.project=global
 local visible,frontier=T.visibility(rooms,id,p)
 table.sort(visible,function(a,b)local ax,ay=T.origin(a);local bx,by=T.origin(b);return ax+ay<bx+by end)
 -- Bridges are drawn below platforms and exist only where both endpoints are known.
 for _,roomId in ipairs(visible)do local r=rooms[roomId];local rp=projection(roomId)
  for side,target in pairs(r.visualExits)do if not p.seen[target] or roomId<target then
   local tx,ty=T.gate(r,side);local a,b=rp(tx,ty)
   local opposite=({NE='SW',SW='NE',SE='NW',NW='SE'})[side];local tx1,ty1=T.gate(rooms[target],opposite);local c,d=projection(target)(tx1,ty1)
   if not p.seen[target]then c=a+(c-a)*.55;d=b+(d-b)*.55 end
   Bridge.draw(a,b,c,d,s,p.unlocked[P.edge(roomId,target)])
  end end
 end
 local objects={}
 for _,roomId in ipairs(visible)do
  local r=rooms[roomId];local rp=projection(roomId);floor(rp,r,roomId,p);local rx,ry=T.origin(roomId)
  for _,o in ipairs(Scenery.objects(r,p.profile.origin,rp,s,time,p))do o.depth=o.depth+rx+ry;objects[#objects+1]=o end
  for _,pos in ipairs(r.pillars)do local pp=pos;if not Scenery.blocked(r,pp.x,pp.y)then objects[#objects+1]={depth=rx+ry+pp.x+pp.y,draw=function()column(rp,pp,r.level)end}end end
  for side,target in pairs(r.visualExits)do local side1,target1=side,target;local x,y=T.gate(r,side1)
   objects[#objects+1]={depth=rx+ry+x+y,draw=function()arch(rp,r,side1,target1,p)end}
  end
  if r.portal then objects[#objects+1]={depth=rx+ry+(r.width+r.height)/2,draw=function()
   local x,y=rp(r.width/2,r.height/2,26);for i=1,4 do g.setColor(.45,.64+i*.07,1,.8-i*.12);g.setLineWidth(3*s);g.ellipse('line',x,y,(16+i)*s,(26+i*2)*s)end;g.setLineWidth(1)
  end}end
 end
 for roomId in pairs(frontier)do fog(projection(roomId),rooms[roomId],time)end
 local px,py=T.px,T.py;if not px then px,py=T.position(id,player.x,player.y)end
 objects[#objects+1]={depth=px+py,draw=function()
  local x,y=global(px,py,3);g.setColor(.20,.31,.26,.23);g.ellipse('fill',x,y,12*s,5*s)
  local bob=T.moving and math.sin(time*13)*1.7 or 0;Art.traveler(character,x,y+bob*s,40*s,60*s,1,T.moving and math.sin(time*6)*.025 or 0,T.face==-1)
  V.color({1,.88,.34});g.polygon('fill',x-4*s,y-70*s,x+4*s,y-70*s,x,y-62*s)
 end}
 table.sort(objects,function(a,b)return a.depth<b.depth end);for _,o in ipairs(objects)do o.draw()end
 for roomId,age in pairs(T.reveals or {})do if rooms[roomId].level==current.level then fog(projection(roomId),rooms[roomId],time,1-age)end end
 -- The player locator is above roofs and arches even when the sprite is occluded.
 local lx,ly=global(px,py,3);V.color({1,.76,.18});g.setLineWidth(2);g.ellipse('line',lx,ly,15*s,7*s);g.setLineWidth(1)
 V.color({1,.89,.39});g.polygon('fill',lx-6*s,ly-74*s,lx+6*s,ly-74*s,lx,ly-66*s)
 -- Labels only for discovered rooms; keep the active room readable in the main HUD.
 for _,roomId in ipairs(visible)do if roomId~=id then local r=rooms[roomId];local x,y=projection(roomId)(r.width/2,r.height+.5)
  if x>-180 and x<w+180 and y>120 and y<h-120 then
   g.setFont(fonts.small);local width=math.min(240,fonts.small:getWidth(r.name)+16);V.card(x-width/2,y,width,22,false);V.color(V.ink);g.printf(r.name,x-width/2,y+4,width,'center')
  end
 end end
 return current
end
return T
