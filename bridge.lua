-- Beveled plank decks with grain, stout posts and curved rope handrails.
local V=require('visual')
local B={}
function B.draw(a,b,c,d,scale,opened)
 local g=love.graphics;local dx,dy=c-a,d-b;local length=math.sqrt(dx*dx+dy*dy);if length<1 then return end
 local ux,uy=dx/length,dy/length;local nx,ny=-uy,ux;local half=15*scale
 g.setLineWidth(34*scale);g.setColor(.21,.31,.27,.12);g.line(a,b+11*scale,c,d+11*scale)
 g.setColor(.45,.28,.16);g.polygon('fill',a+nx*half,b+ny*half,c+nx*half,d+ny*half,c+nx*half,d+ny*half+6*scale,a+nx*half,b+ny*half+6*scale)
 local count=math.max(1,math.ceil(length/(9*scale)))
 for i=0,count-1 do
  local q,r=i/count,(i+1)/count;local inset=.6*scale
  local ax,ay=a+dx*q+ux*inset,b+dy*q+uy*inset;local bx,by=a+dx*r-ux*inset,b+dy*r-uy*inset
  local color=opened and{.84+(i%3)*.035,.59+(i%3)*.035,.31+(i%3)*.025}or{.66,.65,.52}
  V.color(color);g.polygon('fill',ax-nx*half,ay-ny*half,bx-nx*half,by-ny*half,bx+nx*half,by+ny*half,ax+nx*half,ay+ny*half)
  V.color({1,.84,.53},.6);g.setLineWidth(scale);g.line(ax-nx*half,ay-ny*half,bx-nx*half,by-ny*half)
  V.color({.48,.29,.15},.25);g.line(ax-nx*half*.6,ay-ny*half*.6,bx+nx*half*.5,by+ny*half*.5)
 end
 local segments=math.max(1,math.ceil(length/(47*scale)))
 for _,side in ipairs({-1,1})do
  local lastX,lastY
  for i=0,segments do local q=i/segments;local x,y=a+dx*q+nx*half*side,b+dy*q+ny*half*side
   -- Rounded posts and their sunlit caps.
   V.color({.48,.29,.16});g.rectangle('fill',x-3*scale,y-24*scale,6*scale,26*scale,2*scale,2*scale)
   V.color({.90,.68,.38});g.rectangle('fill',x-2*scale,y-24*scale,3*scale,25*scale,scale,scale)
   V.color({1,.83,.48});g.ellipse('fill',x,y-24*scale,4*scale,2*scale)
   if lastX then
    local points={};for j=0,10 do local t=j/10;points[#points+1]=lastX+(x-lastX)*t;points[#points+1]=lastY+(y-lastY)*t-21*scale+math.sin(t*math.pi)*5*scale end
    V.color({.43,.29,.18});g.setLineWidth(3.4*scale);g.line(points)
    V.color({.98,.81,.50});g.setLineWidth(1.8*scale);g.line(points)
   end
   lastX,lastY=x,y
  end
 end
 g.setLineWidth(1)
end
return B
