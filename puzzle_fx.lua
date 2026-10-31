-- Lightweight presentation consumes rule snapshots; it never uses gameplay RNG.
local Art=require('cartoon')
local Palette=require('puzzle_art').colors
local F={};F.__index=F
function F.new(events)
 local self=setmetatable({time=0,bursts={},rings={},beams={},ghosts={},duration=0},F)
 local function particles(index,color,delay,count,clay)
  for n=1,count do if #self.bursts<360 then
   local angle=n*2.39996+index*.71;local speed=.5+(n%5)*.18
   self.bursts[#self.bursts+1]={index=index,color=color,delay=delay,life=.38+(n%4)*.07,vx=math.cos(angle)*speed,vy=math.sin(angle)*speed-.35,shard=clay,turn=angle}
  end end
 end
 for step,event in ipairs(events or {})do if step>7 then break end
  local delay=(step-1)*.12
  for _,cell in ipairs(event.cleared)do
   particles(cell.index,cell.color,delay,6)
   self.ghosts[#self.ghosts+1]={index=cell.index,color=cell.color,delay=delay}
  end
  for _,index in ipairs(event.clay)do particles(index,4,delay,8,true)end
  for _,cell in ipairs(event.born)do
   self.rings[#self.rings+1]={index=cell.index,delay=delay,kind='birth'};particles(cell.index,4,delay,12)
  end
  for _,cell in ipairs(event.fired)do
   self.rings[#self.rings+1]={index=cell.index,delay=delay,kind=cell.kind}
   if cell.kind=='row'or cell.kind=='column'then self.beams[#self.beams+1]={index=cell.index,delay=delay,kind=cell.kind}end
   particles(cell.index,cell.color,delay,14)
  end
  self.duration=delay+.72
 end
 return self
end
function F:update(dt)self.time=self.time+dt;return self.time>=self.duration end
local function center(index,left,top,size)return left+((index-1)%7+.5)*size,top+(math.floor((index-1)/7)+.5)*size end
function F:draw(left,top,size)
 local g=love.graphics
 -- Clip effects to the board plus its decorative frame, keeping controls readable.
 local sx,sy,sw,sh=g.getScissor();g.setScissor(left-7,top-7,size*7+14,size*7+14)
 for _,v in ipairs(self.ghosts)do local age=self.time-v.delay
  if age>=0 and age<.23 then local x,y=center(v.index,left,top,size)
   local c=Palette[v.color];g.setColor(c[1],c[2],c[3],(1-age/.23)*.5);g.circle('fill',x,y,size*(.28+age))
   g.setColor(1,1,.85,(1-age/.23)*.7);g.circle('fill',x,y,size*.15)
  end
 end
 for _,v in ipairs(self.beams)do local age=self.time-v.delay
  if age>=0 and age<.35 then local x,y=center(v.index,left,top,size);local alpha=1-age/.35
   g.setColor(1,.80,.29,.3*alpha)
   if v.kind=='row'then g.rectangle('fill',left,y-size*.22,size*7,size*.44,8,8)else g.rectangle('fill',x-size*.22,top,size*.44,size*7,8,8)end
   g.setColor(1,1,.83,alpha*.85)
   if v.kind=='row'then g.rectangle('fill',left,y-2,size*7,4)else g.rectangle('fill',x-2,top,4,size*7)end
  end
 end
 for _,v in ipairs(self.rings)do local age=self.time-v.delay
  if age>=0 and age<.55 then local x,y=center(v.index,left,top,size);local progress=age/.55
   local c=v.kind=='star'and {.72,.66,1}or {1,.86,.36}
   g.setColor(c[1],c[2],c[3],(1-progress)*.75);g.setLineWidth(3*(1-progress)+1)
   g.circle('line',x,y,size*(.15+progress*(v.kind=='bloom'and 1.6 or .9)))
   Art.draw('puzzle',12,x,y,size*(.6+progress),size*(.6+progress),.5,.5,1-progress,progress*.4)
  end
 end
 for _,v in ipairs(self.bursts)do local age=self.time-v.delay
  if age>=0 and age<v.life then local x,y=center(v.index,left,top,size);local q=age/v.life;local c=Palette[v.color]
   x=x+v.vx*age*size*2;y=y+v.vy*age*size*2+age*age*size
   g.setColor(v.shard and .79 or c[1],v.shard and .47 or c[2],v.shard and .24 or c[3],1-q)
   local r=size*(v.shard and .055 or .045)*(1-q*.65)
   if v.shard then g.push();g.translate(x,y);g.rotate(v.turn+age*4);g.rectangle('fill',-r,-r,r*2,r*1.5,1,1);g.pop()
   else
    g.circle('fill',x,y,r);g.setColor(1,1,.85,(1-q)*.9)
    if v.turn%3<1 then g.polygon('fill',x,y-r*2.2,x+r*.5,y,x,y+r*2.2,x-r*.5,y);g.polygon('fill',x-r*2.2,y,x,y-r*.5,x+r*2.2,y,x,y+r*.5)
    else g.circle('fill',x-r*.2,y-r*.2,r*.5)end
   end
  end
 end
 g.setLineWidth(1);if sx then g.setScissor(sx,sy,sw,sh)else g.setScissor()end;g.setColor(1,1,1)
end
return F
