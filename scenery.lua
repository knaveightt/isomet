-- Illustrated diorama objects, sharing the game's original stable collision footprints.
local V=require('visual')
local Art=require('cartoon')
local S={}
function S.objects(room,origin,project,scale,time,progress)
 local objects={};local g=love.graphics
 local function add(x,y,draw)objects[#objects+1]={depth=x+y,draw=draw}end
 local function shadow(x,y,w,h)
  for i=3,1,-1 do g.setColor(.20,.31,.25,.035*i);g.ellipse('fill',x,y,w*scale*(1+i*.15),h*scale*(1+i*.15))end
 end
 local function sprite(index,x,y,w,h)
  local px,py=project(x,y,2);shadow(px,py,w*.27,w*.10);Art.draw('scenery',index,px,py,w*scale,h*scale,.5,.96)
 end
 add(1.65,1.70,function()
  sprite(room.slot==14 and 8+room.level or room.level,1.65,1.70,184,205)
 end)
 add(room.width-1.65,1.25,function()sprite(5,room.width-1.65,1.25,112,128)end)
 add(room.width-1.7,2.3,function()
  if origin=='Midwest'then
   local px,py=project(room.width-1.7,2.3);V.color({.65,.46,.28});g.ellipse('fill',px,py-6*scale,14*scale,8*scale);V.color({.38,.73,.72});g.ellipse('fill',px,py-8*scale,12*scale,6*scale)
  else sprite(7,room.width-1.7,2.3,92,70)end
 end)
 for _,pos in ipairs({{1,room.height-1.1},{room.width-1,room.height-1.1}})do local x,y=pos[1],pos[2]
  add(x,y,function()sprite(6,x,y,69,63)end)
 end
 if room.slot>=8 and room.slot~=14 then
  local x,y=2,room.height-2
  add(x,y,function()
   sprite(8,x,y,67,69)
   if progress and progress.solved[room.id]then
    local xx,yy=project(x,y,61);g.setColor(.47,.76,.35);g.circle('fill',xx,yy,7*scale);g.setColor(1,1,.85);g.setLineWidth(2*scale);g.line(xx-3*scale,yy,xx-1*scale,yy+2*scale,xx+4*scale,yy-3*scale);g.setLineWidth(1)
   end
  end)
 end
 add(room.width/2+.8,room.height/2-.6,function()
  local x,y=project(room.width/2+.8,room.height/2-.6,45+math.sin(time*3)*3)
  for i=3,1,-1 do g.setColor(1,.82,.32,.045);g.circle('fill',x,y,(8+i*4)*scale)end
  V.color({1,.96,.72});g.ellipse('fill',x-5*scale,y,7*scale,(4+math.sin(time*8)*1.5)*scale)
  V.color({.66,.94,.86});g.ellipse('fill',x+5*scale,y,7*scale,(4+math.sin(time*8)*1.5)*scale)
  V.color({.50,.34,.25});g.ellipse('fill',x,y,1.5*scale,5*scale)
 end)
 return objects
end
function S.blocked(room,x,y)
 return (x>.30 and x<2.8 and y>.35 and y<2.75)or
  (x>room.width-2.25 and x<room.width-.55 and y>.70 and y<2.85)
end
return S
