-- Decorative workers use time-driven poses and articulated tools, not game timers.
local Art=require('cartoon')
local V=require('visual')
local N={}
local jobs={
 {'Firing pottery','Casting moulds','Cleaning a flue','Mixing glaze','Selling cloth','Stoking embers','Cooling tiles','Sorting mitts','Pumping water','Checking vents','Dusting an armchair','Polishing glass','Stitching fabric','Hammering an anvil','Measuring steam'},
 {'Fishing','Mending a net','Selling shells','Reading charts','Watching the tide','Turning a winch','Coiling rope','Stocking shelves','Measuring water','Turning archive pages','Serving supper','Tending a lamp','Checking passengers','Working a floodgate','Scraping frost'},
 {'Selling tickets','Waxing a sled','Polishing a mirror','Sorting prizes','Tuning chimes','Cleaning a lens','Shoveling snow','Hanging coats','Scraping ice','Lighting lanterns','Dusting a mirror','Mending a toy','Winding a music box','Charting stars','Clearing a hatch'},
 {'Tending flowers','Pruning branches','Gathering herbs','Ringing a bell','Restoring a portrait','Brushing stone','Reading a sundial','Balancing weights','Tightening rope','Carving wood','Arranging offerings','Tuning stone bells','Turning family pages','Tending roots','Repairing a latch'}
}
function N.job(r)return jobs[r.level][r.slot]end
function N.position(r)return r.width-1.6,1.5 end
function N.light(x,y,scale,time,seed)
 local g=love.graphics;local pulse=.84+.12*math.sin(time*.85+seed*.7)
 for i=4,1,-1 do g.setColor(1,.67,.24,.025*pulse);g.circle('fill',x,y,(7+i*7)*scale*pulse)end
 g.setColor(1,.76,.27,.8);g.ellipse('fill',x,y,2.7*scale*pulse,5*scale*pulse)
 g.setColor(1,.96,.65,.9);g.ellipse('fill',x,y+scale,1.2*scale,2.8*scale*pulse)
end
function N.draw(r,project,scale,time)
 local g=love.graphics;local seed=r.id;local x,y=N.position(r);local px,py=project(x,y)
 local phase=(time*.22+seed*.17)%1;local wave=math.sin(phase*math.pi*2);local job=N.job(r)
 local fishing=job=='Fishing';local selling=job:find('Selling')~=nil;local ice=job:find('Scrap')or job:find('Shovel')or job:find('Clearing')
 local index=(seed*3)%8+1
 local lean=(ice and .065 or .025)*wave;local bob=math.abs(wave)*(ice and 1.3 or .55)
 g.setColor(.13,.22,.20,.19);g.ellipse('fill',px,py,10*scale,4*scale)
 Art.traveler({index=index},px,py+bob*scale,33*scale,51*scale,1,lean)
 g.push();g.translate(px,py);g.scale(scale,scale)
 local hx,hy=9+wave*3,-24+wave*2
 V.color({.79,.54,.35});g.setLineWidth(3);g.line(5,-28,hx,hy)
 if fishing then
  local angle=-.8+wave*.30;local tx,ty=hx+math.cos(angle)*38,hy+math.sin(angle)*38
  V.color({.44,.29,.15});g.setLineWidth(2);g.line(hx,hy,tx,ty)
  local bx,by=52+math.sin(time*.7+seed)*5,12+math.sin(time*2)*2
  local points={};for i=0,14 do local q=i/14;points[#points+1]=tx+(bx-tx)*q;points[#points+1]=ty+(by-ty)*q+math.sin(q*math.pi)*10 end
  g.setColor(.90,.94,.80,.8);g.setLineWidth(.8);g.line(points)
  V.color({.94,.37,.20});g.circle('fill',bx,by,2);g.setColor(.73,.94,.98,.5);g.ellipse('line',bx,by+2,5+phase*3,2)
 elseif selling then
  V.color({.43,.28,.14});g.rectangle('fill',17,-18,28,19,3,3)
  V.color({.76,.54,.28});g.rectangle('fill',15,-20,32,4,2,2)
  for i=1,5 do V.color({.91,.42+i%2*.17,.18});g.circle('fill',19+i*4,-23-i%2*2,3)end
  local reach=(1-math.cos(phase*math.pi*2))/2
  V.color({.85,.61,.39});g.setLineWidth(3);g.line(hx,hy,15+reach*18,-26)
  V.color({.98,.77,.26});g.circle('fill',15+reach*18,-28,3)
  Art.traveler({index=index%8+1},54,-1+math.sin(time*1.6)*.6,30,47,1,-lean,true)
  V.color({.84,.61,.40});g.setLineWidth(3);g.line(49,-27,39+reach*2,-26)
 elseif ice then
  V.color({.66,.85,.94});g.ellipse('fill',29,5,17,6)
  local tx,ty=29+wave*12,3+math.cos(phase*math.pi*2)*3
  V.color({.49,.33,.18});g.setLineWidth(2);g.line(hx,hy,tx,ty)
  V.color({.78,.84,.83});g.polygon('fill',tx-6,ty-2,tx+5,ty-1,tx+7,ty+3,tx-5,ty+2)
  for i=1,5 do local q=(phase+i*.15)%1;g.setColor(.90,.98,1,(1-q)*.8);g.circle('fill',tx+q*(8+i),ty-q*12+q*q*13,1+i%2*.4)end
 else
  -- Other jobs have individually timed reaching/turning/hammering motions.
  local toolX,toolY=18+wave*7,-9+math.cos(phase*math.pi*2)*(job:find('Hammer')and 9 or 3)
  V.color({.49,.31,.17});g.setLineWidth(2);g.line(hx,hy,toolX,toolY)
  if job:find('Hammer')or job:find('stone')then V.color({.57,.62,.64});g.rectangle('fill',toolX-6,toolY-3,11,5,2,2)
  elseif job:find('pages')or job:find('Reading')or job:find('Charts')then V.color({1,.92,.71});g.polygon('fill',toolX-8,toolY-5,toolX,toolY-3,toolX+8,toolY-7,toolX+7,toolY+3,toolX,toolY+5,toolX-8,toolY+2)
  else V.color({.70,.74,.43});g.ellipse('fill',toolX,toolY,3.4,2)end
 end
 -- Every worker has a small warm task light with a gentle asynchronous pulse.
 V.color({.31,.25,.15});g.rectangle('fill',-17,-10,7,10,1,1)
 N.light(-13.5,-5,1,time,seed)
 g.setLineWidth(1);g.pop()
end
return N
