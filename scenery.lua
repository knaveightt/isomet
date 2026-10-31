-- Illustrated diorama objects, sharing the game's original stable collision footprints.
local V=require('visual')
local Art=require('cartoon')
local NPC=require('ambient_npc')
local S={}
local lightPoints={
 {{.79,.73},{.78,.37},{.56,.57},{.54,.60},{.22,.48},{.49,.59},{.72,.47},{.82,.37},{.62,.49},{.36,.68},{.14,.31},{.15,.35},{.14,.35},{.59,.51},{.50,.53}},
 {{.24,.48},{.22,.32},{.20,.36},{.75,.52},{.60,.12},{.10,.19},{.87,.55},{.30,.35},{.42,.42},{.84,.38},{.44,.30},{.53,.52},{.82,.35},{.45,.30},{.58,.30}},
 {{.80,.27},{.40,.62},{.35,.42},{.10,.45},{.10,.65},{.55,.60},{.60,.60},{.22,.34},{.10,.36},{.50,.30},{.33,.34},{.50,.25},{.23,.41},{.38,.77},{.80,.45}},
 {{.50,.45},{.40,.69},{.52,.50},{.28,.70},{.66,.39},{.68,.29},{.60,.60},{.88,.40},{.40,.50},{.62,.35},{.44,.75},{.25,.50},{.68,.65},{.55,.65},{.74,.50}},
}
function S.objects(room,origin,project,scale,time,progress)
 local objects={};local g=love.graphics
 local function add(x,y,draw)objects[#objects+1]={depth=x+y,draw=draw}end
 local function shadow(x,y,w,h)
  for i=3,1,-1 do g.setColor(.20,.31,.25,.035*i);g.ellipse('fill',x,y,w*scale*(1+i*.15),h*scale*(1+i*.15))end
 end
 local function sprite(index,x,y,w,h)
  local px,py=project(x,y,2);shadow(px,py,w*.27,w*.10);Art.draw('scenery',index,px,py,w*scale,h*scale,.5,.96)
 end
 -- Buildings are independent cutaways, placed on irregular shared terrain.
 add(1.6,1.7,function()
  local x,y=project(1.6,1.7)
  local sheets={'kiln','harbor','snowfair','orchard'}
  local sheet=sheets[room.level];local index=room.slot
  local width,height=(350+room.slot%3*18)*scale,(275+room.slot%4*10)*scale
  Art.draw(sheet,index,x,y+16*scale,width,height,.5,.88)
  local rect=Art.load(sheet).rects[index];local fit=math.min(width/rect[3],height/rect[4]);local hotspot=lightPoints[room.level][room.slot]
  local lx=x+(hotspot[1]-.5)*rect[3]*fit;local ly=y+16*scale+(hotspot[2]-.88)*rect[4]*fit
  NPC.light(lx,ly,scale*(room.level==1 and 1.3 or .8),time,room.id)
  if room.level==1 and(room.slot==1 or room.slot==3 or room.slot==10 or room.slot==14)then
   for i=1,6 do local q=(time*.07+i*.165+room.id*.1)%1
    g.setColor(.77,.77,.79,(1-q)*.085);g.ellipse('fill',x+math.sin(q*6+i)*9*scale,y-height*.60-q*45*scale,(5+q*13)*scale,(4+q*9)*scale)
   end
  end
 end)
 local nx,ny=NPC.position(room);add(nx,ny,function()NPC.draw(room,project,scale,time)end)
 if room.slot>=8 and room.slot~=14 then
  local x,y=2,room.height-2
  add(x,y,function()
   if not progress or not progress.solved[room.id]then
    local xx,yy=project(x,y,28)
    for i=4,1,-1 do g.setColor(1,.72,.15,.035);g.circle('fill',xx,yy,(11+i*8)*scale)end
    local kx,ky=project(x,y,84+math.sin(time*2.5)*3)
    V.color({1,.83,.27});g.setLineWidth(3*scale);g.circle('line',kx,ky,5*scale);g.line(kx+3*scale,ky-3*scale,kx+15*scale,ky-15*scale,kx+18*scale,ky-12*scale);g.setLineWidth(1)
   end
   sprite(8,x,y,67,69)
   if progress and progress.solved[room.id]then
    local xx,yy=project(x,y,61);g.setColor(.47,.76,.35);g.circle('fill',xx,yy,7*scale);g.setColor(1,1,.85);g.setLineWidth(2*scale);g.line(xx-3*scale,yy,xx-1*scale,yy+2*scale,xx+4*scale,yy-3*scale);g.setLineWidth(1)
   end
  end)
 end
 if not progress or progress.room==room.id then add(room.width/2+.8,room.height/2-.6,function()
  local x,y=project(room.width/2+.8,room.height/2-.6,45+math.sin(time*3)*3)
  for i=3,1,-1 do g.setColor(1,.82,.32,.045);g.circle('fill',x,y,(8+i*4)*scale)end
  V.color({1,.96,.72});g.ellipse('fill',x-5*scale,y,7*scale,(4+math.sin(time*8)*1.5)*scale)
  V.color({.66,.94,.86});g.ellipse('fill',x+5*scale,y,7*scale,(4+math.sin(time*8)*1.5)*scale)
  V.color({.50,.34,.25});g.ellipse('fill',x,y,1.5*scale,5*scale)
 end)end
 return objects
end
function S.blocked(room,x,y)
 return (x>.30 and x<2.8 and y>.35 and y<2.75)or
  (x>room.width-2.25 and x<room.width-.55 and y>.70 and y<2.85)
end
return S
