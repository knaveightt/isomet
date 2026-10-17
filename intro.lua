-- A small, explicit cinematic state machine; no room data is changed here.
local I={active=false,phase='location',selected=1,time=0}
local locations={'City','Suburb','Midwest'}
local function clamp(v) return math.max(0,math.min(1,v)) end
local function progress(t,a,b) local v=clamp((t-a)/(b-a)); return v*v*(3-2*v) end
local function rect(x,y,w,h,r,g,b,a)
 love.graphics.setColor(r,g,b,a or 1); love.graphics.rectangle('fill',math.floor(x),math.floor(y),w,h)
end
function I.begin(characters)
 I.characters=characters; I.active=true; I.phase='location'; I.selected=1; I.time=0
 -- Indices 1–4 are male, 5–8 female. Choose the other group once per introduction.
 I.companion=love.math.random(1,4)+(characters.selected<=4 and 4 or 0)
 I.canvas=love.graphics.newCanvas(320,180); I.canvas:setFilter('nearest','nearest')
 I.font=love.graphics.newFont(8); I.small=love.graphics.newFont(6)
end
function I.choose() I.phase='cutscene'; I.time=0 end
function I.keypressed(key)
 if I.phase~='location' then return end
 if key=='left' or key=='up' then I.selected=(I.selected-2)%3+1
 elseif key=='right' or key=='down' then I.selected=I.selected%3+1
 elseif key=='return' or key=='kpenter' then I.choose() end
end
local function layout()
 local w,h=love.graphics.getDimensions(); local card=math.min(280,(w-96)/3)
 return w,h,card,(w-(card*3+32))/2,h/2-70
end
function I.mousepressed(x,y,button)
 if button~=1 or I.phase~='location' then return end
 local w,h,card,left,top=layout()
 for n=1,3 do local cx=left+(n-1)*(card+16)
  if x>=cx and x<=cx+card and y>=top and y<=top+180 then I.selected=n end
 end
 if x>=w/2-130 and x<=w/2+130 and y>=top+220 and y<=top+264 then I.choose() end
end
function I.update(dt)
 if not I.active or I.phase~='cutscene' then return false end
 I.time=I.time+dt
 if I.time>=12.5 then I.active=false; I.phase='done'; return true end
 return false
end
local function environment(location,t)
 if location==1 then
  rect(0,0,320,180,.12,.14,.24); rect(0,106,320,74,.24,.20,.29)
  for y=113,179,12 do rect(0,y,320,1,.32,.26,.33) end
  -- Night window and a city skyline.
  rect(21,18,72,65,.39,.39,.50); rect(24,21,66,59,.035,.055,.14)
  rect(70,27,8,8,.86,.86,.66)
  for n=0,5 do local x=26+n*10; local h=16+(n*13)%27
   rect(x,80-h,8,h,.10,.13,.24); rect(x+2,84-h,2,3,.72,.59,.35)
  end
  rect(55,21,2,59,.39,.39,.50)
  -- Bed, headboard, pillows, and blanket establish a bedroom.
  rect(28,94,110,24,.24,.15,.24); rect(28,112,110,34,.35,.31,.52)
  rect(34,104,34,13,.80,.76,.73); rect(75,104,34,13,.80,.76,.73)
  rect(28,126,110,20,.39,.40,.62); rect(32,146,5,8,.16,.13,.20); rect(128,146,5,8,.16,.13,.20)
  rect(232,111,54,27,.25,.17,.20); rect(245,100,28,4,.25,.22,.29)
  rect(226,60,66,43,.10,.10,.16); rect(232,65,52,31,.32,.49,.59)
  -- Slow horizontal television scan lines.
  for y=67,94,4 do rect(233,y,50,1,.46,.64,.66,.6) end
  rect(238+math.floor(t*3)%24,74,10,12,.64,.69,.73)
 elseif location==2 then
  rect(0,0,320,180,.38,.27,.31); rect(0,110,320,70,.31,.22,.22)
  for x=0,319,16 do rect(x,0,1,110,.48,.35,.36) end
  rect(0,103,320,5,.68,.49,.34)
  rect(23,21,48,54,.21,.14,.23); rect(28,26,38,44,.18,.24,.36)
  rect(46,26,2,44,.66,.49,.35); rect(28,47,38,2,.66,.49,.35)
  -- Dining furniture and food.
  rect(113,88,8,54,.30,.16,.15); rect(173,88,8,54,.30,.16,.15)
  rect(86,122,110,12,.53,.29,.19); rect(95,134,7,29,.27,.15,.15); rect(181,134,7,29,.27,.15,.15)
  rect(89,124,104,4,.77,.61,.43)
  rect(114,120,19,3,.89,.83,.68); rect(157,120,19,3,.89,.83,.68)
  rect(119,117,8,3,.50,.66,.32); rect(161,117,9,3,.77,.40,.22)
  rect(143,111,3,10,.85,.70,.44); rect(143,107,3,4,1,.83,.45)
  -- Tall wall mirror, with a substantial gold frame.
  rect(242,26,48,80,.65,.46,.28); rect(247,31,38,70,.32,.43,.50)
  rect(251,35,3,58,.59,.66,.66); rect(257,40,20,2,.49,.58,.60)
  rect(149,0,2,22,.22,.16,.21); rect(137,22,26,8,.80,.61,.34)
 else
  rect(0,0,320,180,.35,.46,.60); rect(0,69,320,111,.46,.40,.22)
  rect(260,20,15,15,.95,.77,.48)
  -- Ranch house, barn, fence, and rows of corn on every side of the clearing.
  rect(30,46,60,42,.62,.45,.29); rect(23,43,74,8,.34,.26,.24)
  rect(31,37,57,8,.34,.26,.24); rect(52,64,14,24,.26,.24,.24)
  rect(35,57,10,12,.76,.78,.60); rect(73,57,10,12,.76,.78,.60)
  rect(205,52,58,35,.62,.24,.21); rect(199,47,70,7,.33,.22,.23)
  rect(226,65,18,22,.30,.21,.21)
  for x=4,315,17 do rect(x,87,3,19,.66,.55,.35) end
  rect(0,91,320,3,.76,.66,.44); rect(0,100,320,3,.76,.66,.44)
  for y=108,175,17 do for x=6,315,14 do
   if y<126 or x<50 or x>286 or y>166 then
    rect(x,y-12,2,18,.37,.43,.18); rect(x-3,y-8,7,2,.58,.58,.24)
    rect(x-2,y-13,5,5,.83,.69,.29)
   end
  end end
  rect(52,128,230,37,.49,.42,.28)
  rect(236,136,49,12,.22,.31,.38); rect(243,133,34,17,.27,.39,.46)
  rect(247,137,25,2,.49,.60,.60)
 end
end
local function dog(x,y,s,alpha)
 local g=love.graphics; g.push(); g.translate(math.floor(x),math.floor(y)); g.scale(s,s)
 rect(-8,-9,13,7,.71,.47,.27,alpha); rect(2,-14,7,9,.83,.62,.38,alpha)
 rect(2,-14,3,6,.32,.22,.19,alpha); rect(8,-10,3,3,.21,.16,.17,alpha)
 rect(6,-12,1,1,.10,.10,.14,alpha); rect(-7,-2,3,3,.47,.29,.20,alpha); rect(1,-2,3,3,.47,.29,.20,alpha)
 rect(-11,-12,3,6,.71,.47,.27,alpha); g.pop()
end
local function person(image,x,y,s,alpha)
 local g=love.graphics; g.setColor(1,1,1,alpha); g.draw(image,math.floor(x-8*s),math.floor(y-16*s),0,s,s)
end
function I.renderScene()
 local g=love.graphics; local t=I.time; local loc=I.selected
 environment(loc,t)
 local tx,ty=258,84
 if loc==2 then tx,ty=266,67 elseif loc==3 then tx,ty=260,143 end
 local disturbance=progress(t,3,5)
 if disturbance>0 then
  for n=1,4 do
   local a=t*3+n; local r=8+n*2+math.sin(a)*2
   rect(tx-r,ty-r,2*r,2*r,.33+n*.07,.25+n*.06,.63+n*.05,disturbance*.12)
  end
  -- Pixel particles converge into the cursed object.
  for n=1,22 do local p=(t*.45+n*.047)%1; local a=n*2.4
   rect(tx+math.cos(a)*60*(1-p),ty+math.sin(a)*35*(1-p),2,2,.73,.62,1,disturbance*p)
  end
 end
 local px,py,nx,ny,dx,dy=100,121,151,121,183,150
 if loc==1 then px,py,nx,ny,dx,dy=63,123,105,123,163,148
 elseif loc==3 then px,py,nx,ny,dx,dy=107,151,157,146,194,156 end
 local np=progress(t,5,7); local dp=progress(t,6,8)
 if np<1 then person(I.characters.images[I.companion],nx+(tx-nx)*np,ny+(ty-ny)*np,1.6*(1-np),1-np*.6) end
 if dp<1 then dog(dx+(tx-dx)*dp,dy+(ty-dy)*dp,1.4*(1-dp),1-dp*.6) end
 local chase=progress(t,9,11)
 local jump=t>=6.8 and t<9 and math.abs(math.sin((t-6.8)*9))*7 or 0
 if chase<1 then person(I.characters.images[I.characters.selected],px+(tx-px)*chase,py+(ty-py)*chase-jump,1.6*(1-chase),1-chase*.6) end
 if t>=6.8 and t<9 then
  rect(px-10,py-48-jump,23,14,.95,.94,.83); rect(px-1,py-34-jump,4,4,.95,.94,.83)
  g.setFont(I.font); g.setColor(.20,.16,.25); g.print('!!!',px-5,math.floor(py-45-jump))
 end
 -- Console-style caption strip and cinematic letterboxing.
 rect(0,0,320,12,.025,.03,.07); rect(0,163,320,17,.025,.03,.07)
 g.setFont(I.small); g.setColor(.76,.83,.89)
 local captions={'A quiet night. The television murmurs.','Dinner together. A familiar reflection.','Home, among the corn. Rain has just passed.'}
 local caption=captions[loc]
 if t>=3 and t<5 then caption='Something on the other side is waking.'
 elseif t>=5 and t<8 then caption='The void takes those you love.'
 elseif t>=8 and t<9 then caption='No! Wait!'
 elseif t>=9 then caption='You follow. Whatever waits beyond.' end
 g.printf(caption,8,168,304,'center')
 g.printf(locations[loc]:upper()..' / BEFORE THE SILENCE',8,3,304,'left')
 local darkness=math.max(1-clamp(t/1.1),progress(t,11,12.5))
 rect(0,0,320,180,0,0,0,darkness)
end
function I.draw(fonts)
 local g=love.graphics
 if I.phase=='location' then
  local w,h,card,left,top=layout()
  g.setFont(fonts.title); g.setColor(.82,.89,.94); g.printf('Where does your story begin?',0,top-105,w,'center')
  g.setFont(fonts.body); g.setColor(.56,.70,.79); g.printf('A familiar place. An ordinary evening.',0,top-62,w,'center')
  for n=1,3 do
   local x=left+(n-1)*(card+16)
   rect(x,top,card,180,.07,.11,.18)
   local previous=g.getCanvas(); g.setCanvas(I.canvas); g.clear(); environment(n,0); g.setCanvas(previous)
   g.setColor(1,1,1); g.draw(I.canvas,x+8,top+8,0,(card-16)/320,(card-16)/320)
   g.setColor(n==I.selected and .61 or .23,n==I.selected and .88 or .32,n==I.selected and .89 or .43)
   g.setLineWidth(2); g.rectangle('line',x,top,card,180); g.setLineWidth(1)
   g.setFont(fonts.body); g.printf(locations[n],x,top+151,card,'center')
  end
  rect(w/2-130,top+220,260,44,.22,.40,.47)
  g.setColor(.89,.95,.95); g.setFont(fonts.body); g.printf('Begin your story',w/2-130,top+234,260,'center')
  g.setFont(fonts.small); g.setColor(.62,.73,.81); g.printf('Click a place or use arrow keys · Enter to begin',0,top+289,w,'center')
 else
  local previous=g.getCanvas(); g.setCanvas(I.canvas); g.clear(); I.renderScene(); g.setCanvas(previous)
  local w,h=g.getDimensions(); local s=math.max(1,math.floor(math.min(w/320,h/180)))
  g.setColor(.025,.03,.07); g.rectangle('fill',0,0,w,h)
  g.setColor(1,1,1); g.draw(I.canvas,math.floor((w-320*s)/2),math.floor((h-180*s)/2),0,s,s)
 end
end
return I
