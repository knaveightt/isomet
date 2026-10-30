-- Small isometric dioramas with original roofs, foliage and recurring home props.
local V=require('visual')
local S={}
function S.objects(room,origin,project,scale,time,progress)
 local objects={};local g=love.graphics;local biome=V.biomes[room.level]
 local function add(x,y,draw)objects[#objects+1]={depth=x+y,draw=draw}end
 local function box(x,y,w,d,z,h,c)V.box(project,x,y,w,d,z,h,c)end
 local function leaf(x,y,z,r,c)
  local px,py=project(x,y,z);V.color(V.shade(c,.7));g.rectangle('fill',px-r*scale,py-r*.55*scale,r*2*scale,r*1.1*scale)
  V.color(c);g.rectangle('fill',px-(r-3)*scale,py-(r*.6+5)*scale,(r*2-6)*scale,r*scale)
  V.color(V.shade(c,1.18));g.rectangle('fill',px-(r-5)*scale,py-(r*.6+5)*scale,r*scale,5*scale)
 end
 local function flower(x,y)
  local px,py=project(x,y);V.color({.28,.56,.31});g.rectangle('fill',px,py-10*scale,2*scale,10*scale)
  V.color(room.level==3 and {.89,.47,.71}or{1,.76,.29});g.rectangle('fill',px-3*scale,py-13*scale,8*scale,6*scale);V.color({1,.95,.64});g.rectangle('fill',px,py-12*scale,2*scale,2*scale)
 end
 local function tree(x,y,s)
  box(x-.10,y-.10,.20,.20,0,32*s,{.55,.34,.22})
  leaf(x,y,38*s,20*s,biome.leaf);leaf(x-.2,y-.15,54*s,16*s,V.shade(biome.leaf,1.15))
  for i=1,3 do local px,py=project(x+(i-2)*.25,y,37*s+i%2*9);V.color(room.level==3 and {1,.92,.76}or{1,.52,.23});g.rectangle('fill',px-2*scale,py,5*scale,5*scale)end
 end
 add(1.55,1.55,function()
  if room.slot==14 then
   -- A distinct miniature guardian is visible inside each discovered arena.
   box(.65,.65,1.8,1.8,0,7,biome.trim)
   if room.level==1 then
    box(1,1,.9,.8,7,41,{.57,.34,.27});box(.98,.98,.94,.84,48,19,{.90,.56,.30})
    local x,y=project(1.5,1.85,57);V.color({1,.91,.42});g.rectangle('fill',x-8*scale,y,6*scale,4*scale);g.rectangle('fill',x+3*scale,y,6*scale,4*scale)
    box(2,1.4,.16,.16,7,58,{.67,.42,.24});box(1.65,1.2,.80,.50,59,17,{.50,.57,.57})
   elseif room.level==2 then
    for i=0,5 do box(1-i*.06,1-i*.06,.8+i*.12,.8+i*.12,7+i*8,8,{.25+i*.025,.64+i*.025,.74+i*.02})end
    local x,y=project(1.4,1.6,60);V.color({.93,.99,.88});g.rectangle('fill',x-8*scale,y,5*scale,4*scale);g.rectangle('fill',x+4*scale,y,5*scale,4*scale)
   elseif room.level==3 then
    box(.95,1,.9,.8,7,35,{.83,.80,.92});box(.84,.90,1.12,1,42,25,{1,.97,.85})
    local x,y=project(1.45,1.90,59);V.color({.31,.41,.54});g.rectangle('fill',x-11*scale,y-3*scale,8*scale,9*scale);g.rectangle('fill',x+3*scale,y-3*scale,8*scale,9*scale)
    V.color({1,.71,.28});g.polygon('fill',x-4*scale,y+8*scale,x+4*scale,y+8*scale,x,y+15*scale)
    box(.65,1.15,.28,.85,12,33,{.66,.63,.82});box(1.95,1.15,.28,.85,12,33,{.66,.63,.82})
   else
    box(1,1,.85,.85,7,52,{.53,.36,.23});box(.7,1.2,.4,.4,8,32,{.48,.34,.22});box(1.9,1.2,.4,.4,8,32,{.48,.34,.22})
    leaf(1.45,1.45,68,25,{.36,.66,.30});leaf(1.4,1.35,78,17,{.58,.78,.36})
    local x,y=project(1.45,1.9,48);V.color({1,.85,.44});g.rectangle('fill',x-7*scale,y,5*scale,4*scale);g.rectangle('fill',x+3*scale,y,5*scale,4*scale)
   end
   return
  end
  if room.level==1 then
   -- Cream plaster kiln shop, deep terracotta roof, brick chimney and pottery.
   box(.60,.65,1.85,1.5,0,54,{.98,.83,.58})
   V.roof(project,.45,.50,2.15,1.82,54,26,biome.roof)
   box(.80,.72,.40,.42,65,37,{.77,.40,.29});box(.75,.67,.50,.52,102,5,{.99,.80,.52})
   box(1.05,2.16,.60,.04,6,31,{.37,.60,.62});box(1.10,2.20,.50,.04,13,21,{.51,.83,.84})
   box(2.47,1.05,.04,.50,19,19,{.40,.65,.70});box(2.47,1.26,.05,.04,19,19,{1,.90,.63})
   for i=1,3 do local x,y=project(.96,.90,110+i*8+math.sin(time+i)*2);g.setColor(1,.96,.84,.38-i*.07);g.rectangle('fill',x-i*2*scale,y,8*scale,5*scale)end
   for i=1,3 do box(.7+i*.35,2.5,.27,.27,0,9+i%2*4,{.83,.43,.26})end
  elseif room.level==2 then
   -- A little waterside cottage on boardwalk pilings, with an impossible sail.
   for i=0,5 do box(.5+i*.34,.6,.30,2.0,0,5,{.74,.55,.33})end
   box(.65,.7,1.6,1.2,5,45,{.95,.92,.72})
   V.roof(project,.49,.54,1.92,1.52,50,22,biome.roof)
   box(1.05,1.92,.52,.04,6,26,{.33,.64,.68});box(2.28,.95,.04,.6,18,17,{.99,.78,.31})
   box(.4,2.1,2.2,.15,9,6,{.97,.86,.60})
   local px,py=project(1.2,1.2,94);V.color({.61,.42,.27});g.rectangle('fill',px,py-27*scale,3*scale,35*scale);V.color({1,.96,.82});g.polygon('fill',px+4*scale,py-26*scale,px+29*scale,py-3*scale,px+4*scale,py-3*scale)
  elseif room.level==3 then
   -- Snow-topped prize chalet with striped awning and colored lanterns.
   box(.6,.7,1.9,1.5,0,46,{.73,.57,.79})
   V.roof(project,.43,.53,2.24,1.84,46,26,biome.roof);V.roof(project,.45,.55,2.2,1.80,48,27,{.95,.97,1})
   box(.65,2.15,1.8,.4,25,6,{.96,.89,.67})
   for i=0,4 do box(.65+i*.36,2.15,.18,.4,31,2,i%2==0 and {.88,.37,.46}or{1,.95,.80})end
   box(.85,2.12,1.3,.04,8,16,{.27,.56,.66})
   for i=0,3 do local px,py=project(.9+i*.4,2.35,30);V.color(({ {1,.76,.29},{.54,.85,.83},{.97,.58,.70} })[i%3+1]);g.rectangle('fill',px-3*scale,py,6*scale,8*scale)end
  else
   -- A small orchard barn, weathered beams, bright roof, apple crates.
   box(.65,.65,1.75,1.5,0,47,{.90,.65,.37})
   V.roof(project,.47,.47,2.11,1.86,47,27,biome.roof)
   box(.95,2.17,.92,.04,0,35,{.62,.36,.24});box(1.37,2.19,.06,.05,0,35,{1,.88,.63})
   box(2.5,1.3,.50,.6,0,12,{.71,.49,.25});for i=1,4 do local x,y=project(2.5+(i%2)*.22,1.3+math.floor(i/2)*.14,14);V.color({.96,.36,.22});g.rectangle('fill',x-3*scale,y-4*scale,6*scale,6*scale)end
  end
 end)
 add(room.width-1.6,1.5,function()
  tree(room.width-1.6,1.4,.9)
  box(room.width-2,2.0,.9,.7,0,5,{.66,.47,.28})
  if origin=='Midwest' then
   box(room.width-2,2.0,.9,.7,5,4,{.46,.75,.71});box(room.width-1.1,2,.28,.28,0,14,{.93,.74,.34})
  else
   -- The same blue kitchen chair recurs among alien scenery.
   box(room.width-1.95,2.1,.5,.5,14,5,{.29,.68,.73});box(room.width-1.95,2.1,.5,.10,19,20,{.34,.74,.79})
   for _,d in ipairs({{0,0},{.4,0},{0,.4},{.4,.4}})do box(room.width-1.95+d[1],2.1+d[2],.08,.08,0,14,{.78,.55,.31})end
  end
 end)
 if room.slot>=8 and room.slot~=14 then
  local x,y=2,room.height-2
  add(x,y,function()
   local open=progress and progress.solved[room.id]
   box(x-.4,y-.3,.8,.6,0,12,{.69,.41,.24})
   box(x-.43,y-.33,.86,.66,open and 24 or 12,5,{.91,.65,.32})
   box(x-.08,y+.31,.16,.04,5,11,{1,.84,.38})
   local px,py=project(x,y,open and 19 or 31)
   V.color(open and {.48,.74,.49}or{1,.92,.51});g.rectangle('fill',px-3*scale,py,6*scale,6*scale)
  end)
 end
 -- Edge planting and paving details leave all collision and exit paths intact.
 for _,p in ipairs({{1,room.height-1.2},{room.width-1.0,room.height-1.2}})do local x,y=p[1],p[2];add(x,y,function()
  box(x-.25,y-.25,.5,.5,0,7,{.83,.62,.38});leaf(x,y,13,10,biome.leaf);flower(x+.18,y)
 end)end
 add(room.width/2+.8,room.height/2-.6,function()
  local x,y=project(room.width/2+.8,room.height/2-.6,37+math.sin(time*3)*3)
  g.setColor(.98,.78,.27,.18);g.circle('fill',x,y,13*scale)
  V.color({1,.96,.72});g.polygon('fill',x-9*scale,y-5*scale,x,y,x-5*scale,y+5*scale)
  V.color({.66,.94,.86});g.polygon('fill',x+9*scale,y-5*scale,x,y,x+5*scale,y+5*scale)
  V.color({.50,.34,.25});g.rectangle('fill',x-1*scale,y-3*scale,2*scale,7*scale)
 end)
 return objects
end
function S.blocked(room,x,y)
 return (x>.30 and x<2.8 and y>.35 and y<2.75) or
  (x>room.width-2.25 and x<room.width-.55 and y>.70 and y<2.85)
end
return S
