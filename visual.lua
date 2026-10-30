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
function V.card(x,y,w,h,selected)
 local g=love.graphics
 V.color({.16,.30,.35},.2);g.rectangle('fill',x,y+5,w,h,9,9)
 V.color(selected and {.99,.84,.45}or{.77,.83,.69});g.rectangle('fill',x-2,y-2,w+4,h+4,9,9)
 V.color(V.paper);g.rectangle('fill',x,y,w,h,8,8)
 V.color({1,1,.96});g.rectangle('fill',x+5,y+3,w-10,3,2,2)
end
function V.button(x,y,w,h,selected)
 local g=love.graphics
 V.color({.13,.35,.36});g.rectangle('fill',x,y+4,w,h,7,7)
 V.color(selected and {.93,.64,.21}or{.22,.61,.57});g.rectangle('fill',x,y,w,h,7,7)
 V.color(selected and {1,.81,.42}or{.40,.77,.65});g.rectangle('fill',x+3,y+2,w-6,5,3,3)
end
function V.icon(kind,x,y,s)
 local g=love.graphics;g.push();g.translate(math.floor(x),math.floor(y));g.scale(s or 1,s or 1)
 local function r(a,b,w,h,c)V.color(c);g.rectangle('fill',a,b,w,h)end
 if kind=='Satchel'then
  r(2,5,16,13,{.63,.36,.20});r(1,4,18,7,{.89,.61,.30});r(5,1,10,4,{.55,.33,.23});r(7,1,6,2,{1,.82,.48});r(8,9,4,5,{1,.85,.42});r(9,10,2,2,{.66,.39,.23})
 elseif kind=='Notebook'then
  r(2,1,15,18,{.75,.39,.34});r(5,2,13,16,{1,.94,.75});r(7,5,8,1,{.51,.63,.55});r(7,8,7,1,{.51,.63,.55});r(7,11,8,1,{.51,.63,.55});r(2,1,3,18,{.62,.29,.27})
 elseif kind=='Map'then
  r(0,3,6,15,{1,.89,.58});r(6,1,7,15,{1,.96,.76});r(13,3,6,15,{.87,.86,.56});r(3,8,11,2,{.37,.67,.55});r(10,6,2,8,{.37,.67,.55});r(13,11,3,3,{.87,.37,.27})
 elseif kind=='Pip'then
  V.color({1,.91,.55});g.polygon('fill',0,2,10,9,4,17);V.color({.59,.88,.77});g.polygon('fill',20,2,10,9,16,17);r(9,6,2,12,{.54,.36,.25})
 else
  V.color({.33,.62,.66});g.circle('fill',8,8,7);V.color({.75,.94,.91});g.circle('fill',8,8,4);r(13,13,4,6,{.70,.44,.24});r(6,5,2,3,{1,1,.87})
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
 local g=love.graphics;local s=math.min(w/800,h/540);g.push();g.translate(w/2,h/2-35);g.scale(s,s)
 -- A welcoming floating threshold, painted entirely with original pixel geometry.
 local function p(x,y,z)return (x-y)*36,(x+y)*18-(z or 0)end
 V.box(p,-3,-3,6,6,-26,26,{.57,.76,.48})
 V.box(p,-2.6,-2.6,5.2,5.2,0,6,{.96,.86,.64})
 for _,x in ipairs({-1.65,1.05})do V.box(p,x,-.45,.60,.60,6,125,{.96,.85,.62})end
 V.box(p,-1.65,-.45,3.3,.60,131,18,{1,.89,.65})
 for i=1,6 do local q=i/6;g.setColor(.29,.60+q*.3,.95,.35);g.ellipse('fill',0,-55,35-i*3,61-i*5)end
 g.setColor(.94,1,.94);g.setLineWidth(3);g.ellipse('line',0,-55,23+math.sin(t)*2,49);g.setLineWidth(1)
 for _,x in ipairs({-110,110})do g.setColor(.30,.52,.31);g.rectangle('fill',x-4,-12,8,40);g.setColor(.48,.72,.35);g.circle('fill',x,-22,27);g.setColor(.68,.84,.42);g.circle('fill',x-6,-31,19);g.setColor(.97,.58,.30);g.rectangle('fill',x+9,-29,6,7)end
 g.pop()
 g.setFont(font);local title='M I S W A N D E R';local ts=math.min(2.1,(w-80)/font:getWidth(title))
 local yy=h*.70;g.setColor(.30,.30,.22);g.print(title,(w-font:getWidth(title)*ts)/2,yy+3,0,ts,ts)
 g.setColor(1,.92,.57);g.print(title,(w-font:getWidth(title)*ts)/2,yy,0,ts,ts)
end
return V
