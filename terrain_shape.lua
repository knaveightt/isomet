-- Stable area identities drive unique organic shorelines and flowing connections.
local S={cache={}}
function S.outline(r)
 local cacheKey=(r.id or r.slot or 1)..':'..r.width..':'..r.height
 if S.cache[cacheKey]then return S.cache[cacheKey]end
 local result={};local seed=r.id or r.slot or 1;local power=2.7+(seed%7)*.20
 for i=0,39 do local angle=i*math.pi/20;local c,s=math.cos(angle),math.sin(angle)
  local radius=(math.abs(c)^power+math.abs(s)^power)^(-1/power)
  local swell=1+.048*math.sin(angle*3+seed*1.9)+.034*math.sin(angle*7+seed*.71)
  result[#result+1]={r.width/2+c*radius*(r.width/2+1.05)*swell,r.height/2+s*radius*(r.height/2+1.30)*swell}
 end
 S.cache[cacheKey]=result;return result
end
function S.contains(r,x,y)
 local polygon=S.outline(r);local inside=false;local last=#polygon
 for i=1,#polygon do local a,b=polygon[i],polygon[last]
  if(a[2]>y)~=(b[2]>y)and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1]then inside=not inside end
  last=i
 end
 return inside
end
local directions={NE={0,-1},SW={0,1},NW={-1,0},SE={1,0}}
function S.route(ax,ay,bx,by,side,opposite)
 local first,last=directions[side],directions[opposite]
 local distance=math.sqrt((bx-ax)^2+(by-ay)^2);local reach=math.min(7,distance*.40)
 local cx,cy=ax+first[1]*reach,ay+first[2]*reach
 local dx,dy=bx+last[1]*reach,by+last[2]*reach
 local result={}
 for i=0,20 do local t=i/20;local q=1-t
  result[#result+1]={q^3*ax+3*q*q*t*cx+3*q*t*t*dx+t^3*bx,q^3*ay+3*q*q*t*cy+3*q*t*t*dy+t^3*by}
 end
 return result
end
return S
