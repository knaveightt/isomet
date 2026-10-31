-- Shared original art direction: sunlit dioramas, painted wood and parchment.
local V={ink={.18,.29,.32},muted={.35,.48,.48},paper={1,.96,.83},teal={.16,.57,.58},gold={.98,.72,.26}}
V.biomes={
 {tile={.88,.69,.48},edge={.56,.33,.27},trim={.97,.82,.57},roof={.84,.34,.25},leaf={.39,.65,.35}},
 {tile={.59,.84,.86},edge={.25,.49,.58},trim={.89,.95,.81},roof={.21,.60,.72},leaf={.34,.70,.56}},
 {tile={.86,.89,.96},edge={.43,.50,.72},trim={1,.94,.79},roof={.64,.43,.74},leaf={.36,.68,.66}},
 {tile={.64,.79,.43},edge={.39,.44,.25},trim={.91,.85,.56},roof={.78,.37,.28},leaf={.31,.62,.29}}
}
function V.color(c,a)love.graphics.setColor(c[1],c[2],c[3],a or c[4] or 1)end
function V.shade(c,v)return {math.min(1,c[1]*v),math.min(1,c[2]*v),math.min(1,c[3]*v)}end
-- Shared beveled controls: decoration stays inside the established hit regions.
function V.card(x,y,w,h,selected)
 local g=love.graphics;local r=math.min(18,h/3)
 for i=3,1,-1 do V.color({.12,.28,.30},.035*i);g.rectangle('fill',x-i,y+3+i,w+i*2,h+i*2,r,r)end
 V.color(selected and {.70,.40,.12} or {.50,.38,.24});g.rectangle('fill',x-3,y-3,w+6,h+9,r+2,r+2)
 V.color(selected and {1,.74,.22} or {.91,.75,.48});g.rectangle('fill',x-2,y-2,w+4,h+4,r,r)
 V.color({1,.99,.90});g.rectangle('fill',x,y,w,h,r-1,r-1)
 V.color(V.paper);g.rectangle('fill',x+3,y+5,w-6,h-8,r-2,r-2)
 V.color({.96,.89,.72});g.rectangle('fill',x+8,y+h-6,w-16,3,2,2)
 if selected then
  V.color({1,.90,.48});g.setLineWidth(2);g.rectangle('line',x+2,y+2,w-4,h-4,r-2,r-2);g.setLineWidth(1)
 end
end
function V.button(x,y,w,h,selected)
 local g=love.graphics;local mx,my=love.mouse.getPosition()
 local hover=mx>=x and mx<=x+w and my>=y and my<=y+h
 local dy=hover and love.mouse.isDown(1) and 2 or 0
 local base=selected and {.95,.57,.13} or {.16,.57,.54}
 if hover then base=V.shade(base,1.12)end
 V.color({.12,.26,.26},.20);g.rectangle('fill',x-1,y+5,w+2,h+2,13,13)
 V.color(selected and {.57,.30,.10} or {.10,.35,.35});g.rectangle('fill',x,y+3,w,h,12,12)
 V.color(selected and {1,.87,.47} or {.63,.86,.68});g.rectangle('fill',x,y+dy,w,h-2,12,12)
 V.color(base);g.rectangle('fill',x+2,y+3+dy,w-4,h-7,10,10)
 V.color(V.shade(base,1.23));g.rectangle('fill',x+5,y+4+dy,w-10,math.max(5,h*.36),9,9)
 V.color({1,1,.88},.55);g.rectangle('fill',x+12,y+4+dy,w-24,2,1,1)
end
function V.buttonText(text,x,y,w,h,font)
 local g=love.graphics;if font then g.setFont(font)end
 local yy=math.floor(y+(h-g.getFont():getHeight())/2)-1
 V.color({.10,.28,.27},.65);g.printf(text,x+8,yy+1,w-16,'center')
 V.color({1,1,.94});g.printf(text,x+8,yy,w-16,'center')
end
function V.heading(text,x,y,w,font)
 local g=love.graphics;g.setFont(font)
 V.color({1,1,.91},.85);g.printf(text,x,y+2,w,'center')
 V.color({.20,.38,.36});g.printf(text,x,y,w,'center')
 local half=math.min(64,w*.10);local cx=x+w/2;local yy=y+font:getHeight()+9
 V.color({.90,.66,.27});g.setLineWidth(2);g.line(cx-half,yy,cx-8,yy);g.line(cx+8,yy,cx+half,yy)
 g.polygon('fill',cx,yy-4,cx+4,yy,cx,yy+4,cx-4,yy);g.setLineWidth(1)
end
function V.badge(x,y)
 local g=love.graphics;V.color({.36,.43,.22});g.circle('fill',x,y+2,12)
 V.color({1,.83,.30});g.circle('fill',x,y,12);V.color({1,.97,.68});g.circle('fill',x,y,9)
 V.color({.28,.51,.29});g.setLineWidth(3);g.line(x-5,y,x-1,y+4,x+6,y-4);g.setLineWidth(1)
end
function V.progress(x,y,w,h,fraction)
 local g=love.graphics;V.color({.60,.52,.34});g.rectangle('fill',x-2,y-2,w+4,h+4,h/2,h/2)
 V.color({.85,.84,.65});g.rectangle('fill',x,y,w,h,h/2,h/2)
 local fill=math.max(0,math.min(1,fraction))*(w-4)
 if fill>0 then V.color({.32,.68,.39});g.rectangle('fill',x+2,y+2,fill,h-4,(h-4)/2,(h-4)/2)
 V.color({.68,.88,.42});g.rectangle('fill',x+3,y+2,math.max(1,fill-2),math.max(2,(h-4)*.4),3,3)end
end
function V.heart(x,y,full)
 local g=love.graphics
 V.color(full and {.61,.20,.20} or {.65,.64,.51})
 g.circle('fill',x-4,y,6);g.circle('fill',x+4,y,6);g.polygon('fill',x-10,y,x+10,y,x,y+13)
 V.color(full and {1,.43,.37} or {.83,.82,.68})
 g.circle('fill',x-4,y-1,4.5);g.circle('fill',x+4,y-1,4.5);g.polygon('fill',x-8,y,x+8,y,x,y+10)
 V.color({1,.91,.76},.8);g.ellipse('fill',x-4,y-3,2.5,1.5)
end
function V.icon(kind,x,y,s)
 local g=love.graphics;g.push();g.translate(x,y);g.scale(s or 1,s or 1)
 local function r(a,b,w,h,c)V.color(c);g.rectangle('fill',a,b,w,h,3,3)end
 if kind=='Satchel'then
  V.color({.38,.24,.17});g.setLineWidth(3);g.arc('line','open',10,6,5,math.pi,math.pi*2);g.setLineWidth(1)
  r(1,5,18,15,{.52,.29,.14});r(2,5,16,12,{.84,.52,.24});r(1,4,18,7,{1,.72,.34});r(8,8,4,5,{1,.91,.51})
 elseif kind=='Notebook'then
  r(1,1,18,19,{.50,.24,.19});r(4,1,15,17,{1,.95,.77});r(1,1,4,18,{.80,.37,.28})
  for yy=5,13,4 do r(7,yy,9,1,{.49,.65,.57})end
  r(14,1,2,8,{.94,.61,.23})
 elseif kind=='Map'then
  V.color({.81,.62,.29});g.polygon('fill',0,3,6,0,13,3,20,0,20,17,13,20,6,17,0,20)
  V.color({1,.94,.70});g.polygon('fill',1,4,6,2,13,5,19,2,19,16,13,18,6,15,1,18)
  V.color({.31,.65,.56});g.setLineWidth(2);g.line(3,12,7,8,11,12,16,7);g.setLineWidth(1)
  V.color({.91,.32,.20});g.circle('fill',16,7,3)
 elseif kind=='Pip'then
  V.color({1,.86,.31});g.ellipse('fill',5,6,5,7);g.ellipse('fill',15,6,5,7)
  V.color({.52,.84,.70});g.ellipse('fill',5,14,4,5);g.ellipse('fill',15,14,4,5)
  r(9,5,3,14,{.53,.34,.20});V.color({1,.96,.72});g.circle('fill',10,5,3)
 else
  V.color({.48,.29,.16});g.setLineWidth(5);g.line(12,13,19,20);g.setLineWidth(1)
  V.color({.92,.68,.29});g.circle('fill',8,8,8);V.color({.22,.53,.60});g.circle('fill',8,8,6)
  V.color({.70,.93,.94});g.circle('fill',8,8,4.5);V.color({1,1,1},.8);g.ellipse('fill',6,6,2,1)
 end
 g.pop()
end
function V.background(w,h,t)
 local g=love.graphics
 for y=0,h,4 do local p=y/h;g.setColor(.38+p*.23,.67+p*.14,.80+p*.05);g.rectangle('fill',0,y,w,4)end
 -- The bright void is still endless: slow clouds, distant islands and motes.
 for i=1,9 do local x=(i*237+t*(2+i*.3))%(w+260)-130;local y=h*(.22+(i%4)*.19)
  g.setColor(.94,1,.97,.17);g.ellipse('fill',x,y,100+(i%3)*35,14+i%3*5)
  g.setColor(.93,1,.98,.12);g.ellipse('fill',x+25,y-10,65,19)
 end
 for i=1,4 do local x=(i*353)%(w+100);local y=140+(i*157)%math.max(180,h-220)
  g.setColor(.41,.61,.65,.22);g.polygon('fill',x-22,y,x,y+32,x+26,y)
  g.setColor(.77,.91,.82,.3);g.polygon('fill',x-25,y,x,y-10,x+28,y,x,y+9)
 end
end
function V.box(project,x,y,w,d,z,height,c)
 local g=love.graphics
 local a,b=project(x,y,z+height);local e,f=project(x+w,y,z+height);local i,j=project(x+w,y+d,z+height);local m,n=project(x,y+d,z+height)
 local aa,bb=project(x,y,z);local ee,ff=project(x+w,y,z);local ii,jj=project(x+w,y+d,z);local mm,nn=project(x,y+d,z)
 V.color(V.shade(c,.72));g.polygon('fill',e,f,i,j,ii,jj,ee,ff)
 V.color(V.shade(c,.87));g.polygon('fill',m,n,i,j,ii,jj,mm,nn)
 V.color(c);g.polygon('fill',a,b,e,f,i,j,m,n)
end
function V.roof(project,x,y,w,d,z,height,c)
 local g=love.graphics
 local a,b=project(x,y,z);local e,f=project(x+w,y,z);local i,j=project(x+w,y+d,z);local m,n=project(x,y+d,z)
 local rx,ry=project(x,y+d/2,z+height);local sx,sy=project(x+w,y+d/2,z+height)
 V.color(V.shade(c,.75));g.polygon('fill',e,f,i,j,sx,sy)
 V.color(V.shade(c,1.12));g.polygon('fill',a,b,e,f,sx,sy,rx,ry)
 V.color(c);g.polygon('fill',m,n,i,j,sx,sy,rx,ry)
 for step=1,5 do local q=step/6
  local ax,ay=project(x,y+(d/2)*q,z+height*q);local bx,by=project(x+w,y+(d/2)*q,z+height*q)
  local cx,cy=project(x,y+d-(d/2)*q,z+height*q);local dx,dy=project(x+w,y+d-(d/2)*q,z+height*q)
  V.color(V.shade(c,.82));g.line(ax,ay,bx,by);g.line(cx,cy,dx,dy)
 end
 V.color(V.shade(c,1.20));g.setLineWidth(2);g.line(rx,ry,sx,sy);g.setLineWidth(1)
end
function V.title(w,h,t,font)
 V.background(w,h,t)
 local Art=require('cartoon');local g=love.graphics;local s=math.min(w/900,h/650)
 local cx,cy=w/2,h*.42
 Art.drawRect('terrain',4,cx-270*s,cy-72*s,540*s,330*s)
 Art.draw('scenery',1,cx-145*s,cy+70*s,165*s,190*s,.5,1)
 Art.draw('scenery',5,cx+175*s,cy+120*s,128*s,168*s,.5,1)
 -- A rounded magical threshold sits inside the same illustrated world as the maze.
 g.push();g.translate(cx+12*s,cy+52*s);g.scale(s,s)
 local arch={-52,39,-52,-47}
 for i=0,20 do local q=i/20;arch[#arch+1]=-52+104*q;arch[#arch+1]=-47-math.sin(q*math.pi)*49 end
 arch[#arch+1]=52;arch[#arch+1]=39
 V.color({.59,.41,.26});g.setLineWidth(27);g.line(arch)
 V.color({.99,.84,.57});g.setLineWidth(21);g.line(arch)
 V.color({1,.96,.79});g.setLineWidth(5);g.line(arch)
 for i=7,1,-1 do local q=i/7;g.setColor(.21,.57+q*.30,1,.19);g.ellipse('fill',0,-21,39*q,63*q)end
 g.setColor(.91,1,.97);g.setLineWidth(3);g.ellipse('line',0,-21,28+math.sin(t)*2,52)
 for i=1,14 do local a=i*2.4+t*.8;g.setColor(1,.95,.62,.7);g.circle('fill',math.cos(a)*39,-21+math.sin(a)*60,1.8)end
 g.setLineWidth(1);g.pop()
 g.setFont(font);local title='M I S W A N D E R';local ts=math.min(2.1,(w-80)/font:getWidth(title));local yy=h*.77
 g.setColor(.28,.32,.24);g.print(title,(w-font:getWidth(title)*ts)/2,yy+3,0,ts,ts)
 g.setColor(1,.94,.67);g.print(title,(w-font:getWidth(title)*ts)/2,yy,0,ts,ts)
end
return V
