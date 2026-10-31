-- Illustrated pieces share one cached transparent atlas with seals and power-ups.
local Art=require('cartoon')
local P={colors={{1,.43,.23},{.24,.83,1},{.75,.47,1},{1,.82,.22},{.37,.88,.37},{1,.48,.71}}}
local specialIndex={row=7,column=8,bloom=9,star=10}
function P.piece(x,y,size,color,special,alpha)
 Art.draw('puzzle',specialIndex[special]or color,x+size/2,y+size/2,size*.91,size*.91,.5,.5,alpha)
 -- Small colored enamel stud retains the matching color of a special.
 if special then
  local g=love.graphics;local c=P.colors[color]
  g.setColor(.25,.30,.28,alpha or 1);g.circle('fill',x+size*.79,y+size*.79,size*.105)
  g.setColor(c[1],c[2],c[3],alpha or 1);g.circle('fill',x+size*.79,y+size*.78,size*.08)
  g.setColor(1,1,.92,(alpha or 1)*.85);g.circle('fill',x+size*.77,y+size*.75,size*.025)
 end
end
function P.seal(x,y,size)
 Art.draw('puzzle',11,x+size/2,y+size/2,size*.97,size*.97,.5,.5)
end
return P
