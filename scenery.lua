-- Small original pixel props. Shared origin anchors recur unchanged in alien places.
local S={}
local function block(x,y,w,h,c)love.graphics.setColor(c);love.graphics.rectangle('fill',math.floor(x),math.floor(y),w,h)end
local brass={.79,.59,.32};local wood={.47,.29,.22};local pale={.83,.78,.62};local blue={.30,.65,.78}
function S.draw(room,origin,project,scale,time)
 local g=love.graphics;local x,y=project(1.5,1.5)
 g.push();g.translate(math.floor(x),math.floor(y));g.scale(scale*2,scale*2)
 if room.level==1 then
  block(-10,-32,20,32,{.39,.24,.23});block(-6,-25,12,10,{.12,.11,.17});block(-3,-21,6,6,{.95,.49,.25})
  block(-5,-53,10,21,{.29,.22,.24});block(-7,-55,14,4,brass)
  for i=1,4 do block(-4+math.sin(time*.5+i)*3,-55-i*7,6+i,4,{.41,.37,.44,.24}) end
 elseif room.level==2 then
  block(-20,-35,40,4,wood);block(-15,-31,30,7,wood);block(-10,-24,20,5,brass)
  block(-2,-56,2,20,pale);block(0,-51,17,12,pale)
  for i=1,3 do block(-20,-3+i*3,35,1,{.37,.68,.79,.5})end
 elseif room.level==3 then
  block(-18,-33,36,4,pale);block(-18,-29,4,28,wood);block(14,-29,4,28,wood)
  block(-20,-42,40,9,{.62,.30,.43});block(-15,-44,30,3,pale)
  for i=1,4 do block(-13+i*6,-27,3,4,({blue,brass,pale})[(i-1)%3+1])end
  block(-18,-1,36,7,{.54,.44,.59})
 else
  block(-7,-53,14,53,wood);block(-18,-36,36,7,wood);block(-24,-48,48,15,{.34,.48,.29})
  block(-19,-53,38,10,{.40,.54,.31});for i=1,5 do block(-23+i*7,-42+(i%2)*4,4,5,{.84,.47,.30})end
  block(-24,-1,48,3,wood)
 end
 g.pop()
 -- The same recognizable anchor silhouettes recur across all environments.
 local ax,ay=project(room.width-1.5,2)
 g.push();g.translate(math.floor(ax),math.floor(ay));g.scale(scale*2,scale*2)
 if origin=='City' or origin=='Suburb' then
  block(-8,-28,16,12,wood);block(-8,-15,16,4,wood);block(-8,-11,3,11,wood);block(5,-11,3,11,wood)
  if origin=='City' then block(14,-17,7,17,pale);block(15,-15,5,2,brass);block(16,-10,3,3,blue)
  else block(-4,-19,8,5,pale);block(-2,-18,4,1,blue)end
 else
  block(-16,-7,29,6,wood);block(-14,-12,24,5,{.44,.57,.61});block(16,-13,7,13,brass);block(17,-19,3,9,wood)
  for i=1,4 do block(-20-i*3,-15-i*3,3,17,{.55,.64,.31})end
 end
 g.pop()
 -- A folded-map moth hovers beside the player-independent room center.
 local mx,my=project(room.width/2+.8,room.height/2-.6,43+math.sin(time*2)*3)
 g.setColor(.96,.87,.58,.9);g.polygon('fill',mx-7*scale,my-4*scale,mx,my,mx-4*scale,my+5*scale)
 g.setColor(.74,.88,.84,.9);g.polygon('fill',mx+7*scale,my-4*scale,mx,my,mx+4*scale,my+5*scale)
end
return S
