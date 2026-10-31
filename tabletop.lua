-- Connected, persistent-discovery tabletop presentation. Room IDs and rules stay stable.
local V=require('visual')
local Scenery=require('scenery')
local Campaign=require('campaign')
local P=require('progress')
local Art=require('cartoon')
local Bridge=require('bridge')
local Environment=require('environment')
local Shape=require('terrain_shape')
local T={zoom=.68,panX=0,panY=0}
-- Geometry is a presentation layout, independent of saved room-local coordinates.
local layout={{0,0},{1,0},{2,0},{2,1},{0,1},{1,2},{2,3},{-1,0},{1,-1},{3,0},{0,-1},{3,1},{-1,1},{1,3},{3,3}}
local offsets={{0,0},{-.65,.8},{.7,-.6},{-.8,.45},{.6,-.7},{-.45,.7},{.65,-.7},{.4,-.45},{-.5,.55},{.7,.6},{-.65,.4},{.55,-.4},{-.55,.6},{.5,-.6},{-.4,.7}}
function T.origin(id)
 local level,slot=Campaign.info(id);local gx,gy=layout[slot][1],layout[slot][2]
 local shapes={{14,14,0,0},{15.2,13.6,.6,.3},{13.8,15.4,.75,.5},{14.6,14.2,-.65,.7}}
 local shape=shapes[level]
 return gx*shape[1]+gy*shape[3]+offsets[slot][1],gy*shape[2]+gx*shape[4]+offsets[slot][2]
end
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
 local points={{ax,ay}};for _,point in ipairs(Shape.route(gx,gy,hx,hy,side,opposite))do points[#points+1]=point end;points[#points+1]={bx,by}
 T.walk={points=points,time=0};T.panX=0;T.panY=0
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
  for i=1,#points-1 do local a,b=points[i],points[i+1];lengths[i]=math.sqrt((b[1]-a[1])^2+(b[2]-a[2])^2);total=total+lengths[i]end
  local distance=walk.time*total
  for i=1,#points-1 do if distance<=lengths[i] or i==#points-1 then
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
local function arch(project,r,side,target,p,time)
 local g=love.graphics;local x,y=T.gate(r,side);local s=T.renderScale or T.zoom;local dx,dy=0,0
 if side=='NE'or side=='SW'then dx=.92 else dy=.92 end
 local ax,ay=project(x-dx,y-dy);local bx,by=project(x+dx,y+dy)
 local opened=p.unlocked[P.edge(r.id,target)]
 local path={ax,ay}
 for i=0,18 do local q=i/18;path[#path+1]=ax+(bx-ax)*q;path[#path+1]=ay+(by-ay)*q-34*s-math.sin(q*math.pi)*23*s end
 path[#path+1]=bx;path[#path+1]=by
 -- The door plane follows its room edge, keeping exits readable in all directions.
 local door={ax,ay}
 for i=0,18 do local q=i/18;door[#door+1]=ax+(bx-ax)*q;door[#door+1]=ay+(by-ay)*q-34*s-math.sin(q*math.pi)*23*s end
 door[#door+1]=bx;door[#door+1]=by
 V.color(opened and {.12,.28,.27}or {.29,.17,.10});g.polygon('fill',door)
 if not opened then
  for i=1,6 do local q=i/7;local px=ax+(bx-ax)*q;local py=ay+(by-ay)*q
   V.color({.57+(i%2)*.04,.36,.18});g.setLineWidth(5*s);g.line(px,py-3*s,px,py-32*s-math.sin(q*math.pi)*22*s)
  end
 end
 g.setLineJoin('bevel');g.setLineWidth(20*s);V.color(r.level==1 and {.28,.27,.27}or{.44,.44,.37});g.line(path)
 g.setLineWidth(14*s);V.color(r.level==3 and {.84,.88,.95}or{.81,.76,.59});g.line(path)
 -- Masonry joints make the arch read as stacked stone rather than a smooth hoop.
 for i=2,#path-3,4 do V.color({.39,.39,.34},.6);g.setLineWidth(s);g.line(path[i-1]-5*s,path[i]-2*s,path[i-1]+5*s,path[i]+2*s)end
 local px,py=project(x,y,27)
 if not opened then
  V.color({.97,.73,.22});g.rectangle('fill',px-7*s,py-3*s,14*s,13*s,3*s,3*s)
  g.setLineWidth(3*s);g.arc('line','open',px,py-3*s,5*s,math.pi,math.pi*2)
  V.color({.39,.27,.12});g.circle('fill',px,py+2*s,2*s);g.line(px,py+3*s,px,py+6*s)
 else V.color({.94,.80,.37},.5);g.ellipse('fill',px,py+24*s,12*s,5*s)end
 -- Warm lanterns tie the otherwise surreal doors to the stolen-home theme.
 local lx,ly=ax-10*s,ay-31*s
 local pulse=.87+.12*math.sin(time*.85+r.id*.7)
 for i=3,1,-1 do g.setColor(1,.63,.17,.05*pulse);g.circle('fill',lx,ly,(5+i*4)*s*pulse)end
 V.color({.33,.25,.16});g.rectangle('fill',lx-4*s,ly-6*s,8*s,13*s,2*s,2*s)
 V.color({1,.82,.32});g.rectangle('fill',lx-2*s,ly-4*s,4*s,8*s*pulse,1,1)
 g.setLineWidth(1)
end
local function column(project,p,level)
 local g=love.graphics;local s=T.renderScale or T.zoom;local x,y=project(p.x,p.y)
 local seed=math.floor(p.x*13+p.y*19+level*7);local height=14+seed%19;local width=8+seed%8
 local c=level==3 and {.66,.79,.90}or(level==1 and {.40,.36,.29}or{.49,.57,.39})
 g.setColor(.13,.22,.19,.18);g.ellipse('fill',x,y,width*s,5*s)
 V.color(V.shade(c,.7));g.polygon('fill',x-width*s,y,x-width*.7*s,y-height*.7*s,x+width*.15*s,y-height*s,x+width*s,y-height*.3*s,x+width*.75*s,y+3*s)
 V.color(c);g.polygon('fill',x-width*.7*s,y-height*.7*s,x+width*.15*s,y-height*s,x+width*.4*s,y-height*.3*s,x-width*.3*s,y)
 if level==3 then V.color({.92,.96,1});g.polygon('fill',x-width*.7*s,y-height*.7*s,x+width*.15*s,y-height*s,x+width*.6*s,y-height*.6*s,x,y-height*.65*s)end
end
local function fog(project,r,time,strength)
 strength=strength or 1
 local g=love.graphics;local s=T.renderScale or T.zoom
 -- Anonymous soft banks conceal destinations without revealing their features.
 local cx,cy=project(r.width/2,r.height/2)
 local tint=r.level==1 and {.76,.75,.78}or(r.level==3 and {.87,.89,.97}or{.88,.94,.91})
 for layer=8,1,-1 do g.setColor(tint[1],tint[2],tint[3],.028*strength);g.ellipse('fill',cx,cy,(r.width+r.height)*12*s+layer*7*s,(r.width+r.height)*6*s+layer*5*s)end
 for i=1,25 do local x=.3+((i*19+r.id*7)%89)/10;local y=.3+((i*23+r.id*11)%89)/10
  local xx,yy=project(math.min(r.width-.2,x),math.min(r.height-.2,y),10+math.sin(time*.22+i)*4)
  for layer=5,1,-1 do local size=layer/5;g.setColor(tint[1],tint[2],tint[3],.055*strength);g.ellipse('fill',xx,yy,(27+i%3*12)*s*size,(16+i%3*5)*s*size)end
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
function T.screenToWorld(x,y)
 local f=T.frame;if not f then return nil end
 local a=(x-f.ox)/(30*f.scale);local b=(y-f.oy)/(15*f.scale)
 return (a+b)/2,(b-a)/2
end
function T.pick(x,y,rooms,id,p)
 local f=T.frame;if not f then return nil end
 local r=rooms[id];local rx,ry=T.origin(id)
 local function screen(lx,ly,z)local gx,gy=rx+lx,ry+ly;return f.ox+(gx-gy)*30*f.scale,f.oy+(gx+gy)*15*f.scale-(z or 0)*f.scale end
 for _,side in ipairs({'NE','SE','SW','NW'})do local target=r.visualExits[side]
  if target then local gx,gy=T.gate(r,side);local sx,sy=screen(gx,gy,24)
   if ((x-sx)/(30*f.scale))^2+((y-sy)/(42*f.scale))^2<=1 then return {side=side,target=target}end
  end
 end
 if r.slot>=8 and r.slot~=14 then local sx,sy=screen(2,r.height-2,25)
  if (x-sx)^2+(y-sy)^2<(30*f.scale)^2 then return {inspect=true}end
 end
 local gx,gy=T.screenToWorld(x,y);local lx,ly=gx-rx,gy-ry
 if require('terrain_shape').contains(r,lx,ly)then return {x=lx,y=ly}end
 -- Tapping an adjacent discovered courtyard routes to its actual connecting gate.
 for side,target in pairs(r.visualExits)do if p.seen[target]then local ox,oy=T.origin(target);local other=rooms[target]
  if gx>=ox and gy>=oy and gx<=ox+other.width and gy<=oy+other.height then return {side=side,target=target}end
 end end
 return nil
end
function T.draw(rooms,id,player,p,character,time,fonts)
 local g=love.graphics;local w,h=g.getDimensions();local current=rooms[id]
 local s=T.zoom*math.max(1,math.min(w/1200,h/800));T.renderScale=s;local cx,cy=T.cx,T.cy
 if not cx then cx,cy=T.position(id,player.x,player.y)end
 local ox=w/2-(cx-cy)*30*s+T.panX;local oy=h*.49-(cx+cy)*15*s+T.panY
 local function global(x,y,z)return ox+(x-y)*30*s,oy+(x+y)*15*s-(z or 0)*s end
 local function projection(roomId)local rx,ry=T.origin(roomId);return function(x,y,z)return global(rx+x,ry+y,z)end end
 T.project=global
 T.frame={ox=ox,oy=oy,scale=s}
 Environment.background(current.level,w,h,time,T.panX)
 local visible,frontier=T.visibility(rooms,id,p)
 table.sort(visible,function(a,b)local ax,ay=T.origin(a);local bx,by=T.origin(b);return ax+ay<bx+by end)
 -- Most connections are broad shared land; selected ravines retain bridges.
 local links={}
 for _,roomId in ipairs(visible)do local r=rooms[roomId]
  for side,target in pairs(r.visualExits)do if not p.seen[target]or roomId<target then
   local gx,gy=T.gate(r,side);local ax,ay=T.position(roomId,gx,gy)
   local opposite=({NE='SW',SW='NE',SE='NW',NW='SE'})[side]
   local hx,hy=T.gate(rooms[target],opposite);local bx,by=T.position(target,hx,hy)
   local route=Shape.route(ax,ay,bx,by,side,opposite)
   if not p.seen[target]then while #route>12 do table.remove(route)end;bx,by=route[#route][1],route[#route][2]end
   links[#links+1]={route=route,ax=ax,ay=ay,bx=bx,by=by,level=r.level,bridge=Environment.isBridge(roomId,target,r.level),opened=p.unlocked[P.edge(roomId,target)],key='link'..P.edge(roomId,target)..(p.seen[target]and 'known'or'fog')}
  end end
 end
 for _,link in ipairs(links)do local a,b=global(link.ax,link.ay);local c,d=global(link.bx,link.by);Environment.channel(a,b,c,d,s,link.level,time)end
 Environment.land(rooms,visible,links,T.origin,global,s)
 for _,link in ipairs(links)do if link.bridge then
  for i=1,#link.route-1,4 do local j=math.min(#link.route,i+4);local a,b=global(link.route[i][1],link.route[i][2]);local c,d=global(link.route[j][1],link.route[j][2]);Bridge.draw(a,b,c,d,s,link.opened,link.level==2 or link.level==3)end
 end end
 local objects={}
 for _,roomId in ipairs(visible)do
  local r=rooms[roomId];local rp=projection(roomId);local rx,ry=T.origin(roomId)
  for _,o in ipairs(Scenery.objects(r,p.profile.origin,rp,s,time,p))do o.depth=o.depth+rx+ry;objects[#objects+1]=o end
  for _,pos in ipairs(r.pillars)do local pp=pos;if not Scenery.blocked(r,pp.x,pp.y)then objects[#objects+1]={depth=rx+ry+pp.x+pp.y,draw=function()column(rp,pp,r.level)end}end end
  for side,target in pairs(r.visualExits)do local side1,target1=side,target;local x,y=T.gate(r,side1)
   objects[#objects+1]={depth=rx+ry+x+y,draw=function()arch(rp,r,side1,target1,p,time)end}
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
  local hx,hy=love.mouse.getPosition()
  if math.abs(hx-x)<90 and math.abs(hy-y)<18 and x>-180 and x<w+180 and y>120 and y<h-120 then
   g.setFont(fonts.small);local width=math.min(240,fonts.small:getWidth(r.name)+16);V.card(x-width/2,y,width,22,false);V.color(V.ink);g.printf(r.name,x-width/2,y+4,width,'center')
  end
 end end
 return current
end
return T
