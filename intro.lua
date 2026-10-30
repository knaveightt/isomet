-- A small, explicit cinematic state machine; no room data is changed here.
local V=require('visual')
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
 I.font=require('pixel_font')(); I.small=I.font
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
 local g=love.graphics
 local function plant(x,y)
  rect(x-5,y-8,10,8,.83,.43,.28);rect(x-7,y-10,14,3,.98,.68,.37)
  rect(x-1,y-25,2,15,.28,.56,.30);rect(x-9,y-22,9,5,.42,.72,.39);rect(x+1,y-28,8,6,.60,.79,.40)
 end
 if location==1 or location==2 then
  -- Cutaway room: lit plaster walls, painted trim and a parquet floor.
  rect(0,0,320,180,.95,.86,.67);rect(0,0,13,163,.84,.72,.55)
  rect(13,10,307,96,location==1 and .57 or .89,location==1 and .72 or .77,location==1 and .80 or .62)
  rect(0,106,320,74,.79,.59,.40);rect(0,102,320,6,.99,.91,.74)
  for y=111,180,12 do rect(0,y,320,1,.68,.46,.30);for x=(y%24==15 and 0 or 16),320,32 do rect(x,y,1,12,.72,.50,.32)end end
  rect(21,20,72,67,.99,.92,.76);rect(25,24,64,59,.12,.23,.40)
  if location==1 then
   rect(69,29,9,9,.99,.94,.63)
   for i=0,5 do local h=14+(i*13)%25;rect(27+i*10,83-h,8,h,.18,.30,.46);rect(29+i*10,87-h,2,3,1,.80,.37)end
  else
   rect(26,25,62,58,.45,.77,.81);rect(26,62,62,21,.48,.68,.36)
   for x=28,86,7 do rect(x,63,3,20,.98,.91,.71)end
  end
  rect(55,24,3,59,.99,.91,.73);rect(25,52,64,3,.99,.91,.73)
  rect(15,19,8,67,.83,.47,.35);rect(92,19,8,67,.83,.47,.35)
  plant(209,115);plant(13,152)
  if location==1 then
   -- Blue quilt, golden bedposts, a rug and a friendly little television cabinet.
   rect(23,137,132,21,.48,.64,.63);rect(29,141,120,2,.76,.86,.70)
   rect(28,94,110,16,.73,.45,.28);rect(28,111,110,34,.32,.65,.75)
   rect(31,116,103,3,.65,.85,.85)
   for x=32,134,12 do for y=124,142,9 do rect(x,y,5,4,.85,.94,.81)end end
   rect(34,104,34,13,1,.97,.84);rect(75,104,34,13,1,.97,.84)
   rect(28,145,5,10,.68,.42,.25);rect(129,145,5,10,.68,.42,.25)
   rect(112,31,9,16,.99,.94,.78);rect(114,34,5,3,.27,.42,.45)
   for x=151,181,5 do rect(x,80,3,25,.93,.86,.69)end
   rect(224,106,70,29,.71,.46,.29);rect(228,111,62,2,.93,.70,.41)
   rect(246,115,2,17,.50,.33,.23);rect(268,115,2,17,.50,.33,.23)
   rect(226,60,66,43,.30,.43,.43);rect(230,64,58,35,.83,.87,.73);rect(234,67,45,29,.32,.72,.82)
   for y=69,94,5 do rect(235,y,43,1,.66,.89,.90)end
   rect(280,74,4,4,1,.78,.37);rect(242+math.floor(t*3)%23,76,9,10,.97,.90,.59)
   rect(156,99,23,23,.77,.52,.33);rect(153,95,29,4,.96,.75,.48);rect(162,85,10,10,.47,.75,.67)
  else
   rect(80,22,39,66,.98,.91,.72);rect(83,25,33,60,.43,.72,.71);rect(99,25,2,60,.97,.90,.72)
   for x=84,113,6 do rect(x,61,2,23,.90,.79,.57)end
   -- Turned legs and a tabletop with a visible isometric front edge.
   rect(100,143,93,17,.69,.48,.37)
   for _,x in ipairs({111,175})do rect(x,87,8,54,.59,.37,.25);rect(x+2,88,3,39,.91,.65,.38)end
   rect(86,122,110,13,.66,.39,.25);rect(89,119,104,8,.94,.72,.45)
   rect(95,135,7,27,.55,.32,.23);rect(181,135,7,27,.55,.32,.23)
   for _,x in ipairs({114,157})do rect(x,118,19,5,1,.97,.83);rect(x+5,117,8,4,.48,.69,.29);rect(x+8,117,4,3,.96,.48,.26)end
   rect(143,108,3,13,.98,.88,.61);rect(143,104,3,4,1,.69,.26)
   rect(242,26,48,80,.73,.44,.26);rect(244,28,44,76,1,.80,.42);rect(248,32,36,68,.47,.74,.78)
   rect(252,36,3,58,.83,.97,.94);rect(258,40,21,2,.72,.91,.89)
   rect(149,0,2,22,.46,.36,.24);rect(137,22,26,8,.99,.77,.36)
  end
 else
  -- Pastoral ranch: layered hills, orchard trees, terracotta roofs and ripe corn.
  rect(0,0,320,180,.51,.82,.91);rect(0,62,320,118,.66,.80,.39)
  for i=1,5 do rect(i*73-80,43-i%2*6,94,30,.52,.72,.37)end
  rect(261,19,17,17,1,.91,.49)
  rect(32,47,60,42,1,.88,.62);rect(24,43,76,8,.83,.39,.26);rect(32,37,60,8,.95,.52,.30)
  rect(53,63,14,26,.34,.64,.65);rect(35,58,10,12,.53,.80,.84);rect(75,58,10,12,.53,.80,.84)
  rect(205,53,58,35,.87,.39,.29);rect(198,46,72,8,.40,.57,.58);rect(206,40,56,7,.48,.69,.65)
  rect(225,64,20,24,.99,.88,.64);rect(228,67,14,21,.65,.33,.24);rect(235,67,2,21,.98,.83,.56)
  for x=4,315,17 do rect(x,86,3,20,.98,.90,.68)end
  rect(0,91,320,3,1,.94,.75);rect(0,100,320,3,1,.94,.75)
  for y=114,179,17 do for x=6,315,14 do if y<126 or x<50 or x>286 or y>166 then
   rect(x,y-12,2,18,.36,.58,.26);rect(x-4,y-8,9,3,.49,.72,.29);rect(x-2,y-15,5,7,.99,.79,.28);rect(x-1,y-14,2,5,1,.94,.47)
  end end end
  rect(51,128,234,37,.83,.72,.47)
  rect(236,136,49,12,.32,.65,.70);rect(243,133,34,17,.41,.77,.80);rect(247,137,25,2,.84,.98,.92)
  plant(16,89);plant(292,89)
 end
end
local function dog(x,y,s,alpha)
 local g=love.graphics; g.push(); g.translate(math.floor(x),math.floor(y)); g.scale(s,s)
 rect(-8,-9,13,7,.71,.47,.27,alpha); rect(2,-14,7,9,.83,.62,.38,alpha)
 rect(2,-14,3,6,.32,.22,.19,alpha); rect(8,-10,3,3,.21,.16,.17,alpha)
 rect(6,-12,1,1,.10,.10,.14,alpha); rect(-7,-2,3,3,.47,.29,.20,alpha); rect(1,-2,3,3,.47,.29,.20,alpha)
 rect(-11,-12,3,6,.71,.47,.27,alpha);rect(2,-6,7,2,.27,.67,.68,alpha);rect(-6,-8,7,2,.93,.73,.46,alpha);g.pop()
end
local function person(image,x,y,s,alpha)
 local g=love.graphics; g.setColor(1,1,1,alpha); g.draw(image,math.floor(x-8*s),math.floor(y-16*s),0,s/2,s/2)
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
 if loc~=3 and np<1 then person(I.characters.images[I.companion],nx+(tx-nx)*np,ny+(ty-ny)*np,(loc==1 and 1.05 or 1.6)*(1-np),1-np*.6) end
 if loc==3 and dp<1 then dog(dx+(tx-dx)*dp,dy+(ty-dy)*dp,1.4*(1-dp),1-dp*.6) end
 -- A small shared gesture establishes the relationship before the theft.
 if t>1.3 and t<2.8 then
  if loc==1 then rect(px+9,py-17,9,3,.94,.72,.52);rect(nx-13,ny-17,8,3,.94,.72,.52)
  elseif loc==2 then rect(px+10,py-14,4,3,.94,.72,.52);rect(nx-14,ny-14,4,3,.94,.72,.52)
  else local ball=progress(t,1.3,2.8);rect(px+20+(dx-px-30)*ball,py-5-math.sin(ball*math.pi)*13,4,4,.93,.66,.30)end
 end
 local chase=progress(t,9,11)
 local jump=t>=6.8 and t<9 and math.abs(math.sin((t-6.8)*9))*7 or 0
 if chase<1 then person(I.characters.images[I.characters.selected],px+(tx-px)*chase,py+(ty-py)*chase-jump,1.6*(1-chase),1-chase*.6) end
 if t>=6.8 and t<9 then
  rect(px-10,py-48-jump,23,14,.95,.94,.83); rect(px-1,py-34-jump,4,4,.95,.94,.83)
  g.setFont(I.font); g.setColor(.20,.16,.25); g.print('!!!',px-8,math.floor(py-46-jump))
 end
 -- Console-style caption strip and cinematic letterboxing.
 rect(0,0,320,12,.025,.03,.07); rect(0,163,320,17,.025,.03,.07)
 g.setFont(I.small); g.setColor(.96,.96,.88)
 local captions={'TV NIGHT. YOUR CHILD RETURNS A HIGH FIVE.','DINNER TOGETHER. THE SAME OLD JOKE.','FETCH ON THE RANCH. YOUR DOG WAGS.'}
 local caption=captions[loc]
 if t>=3 and t<5 then caption='Something on the other side is waking.'
 elseif t>=5 and t<8 then caption=loc==1 and 'THE VOID TAKES YOUR CHILD.' or (loc==2 and 'THE VOID TAKES YOUR PARTNER.' or 'THE VOID TAKES YOUR DOG.')
 elseif t>=8 and t<9 then caption='No! Wait!'
 elseif t>=9 then caption='You follow. Whatever waits beyond.' end
 g.printf(caption:upper(),8,167,304,'center')
 g.printf(locations[loc]:upper()..' / BEFORE THE SILENCE',8,3,304,'left')
 local darkness=math.max(1-clamp(t/1.1),progress(t,11,12.5))
 rect(0,0,320,180,0,0,0,darkness)
end
function I.draw(fonts)
 local g=love.graphics
 if I.phase=='location' then
  local w,h,card,left,top=layout()
  g.setFont(fonts.title); V.color(V.ink); g.printf('Where does your story begin?',0,top-105,w,'center')
  g.setFont(fonts.body); V.color(V.muted); g.printf('A familiar place. An ordinary evening.',0,top-62,w,'center')
  for n=1,3 do
   local x=left+(n-1)*(card+16)
   V.card(x,top,card,180,n==I.selected)
   local previous=g.getCanvas(); g.setCanvas(I.canvas); g.clear(); environment(n,0); g.setCanvas(previous)
   g.setColor(1,1,1); g.draw(I.canvas,x+8,top+8,0,(card-16)/320,(card-16)/320)
   V.color(n==I.selected and V.gold or {.63,.75,.63})
   g.setLineWidth(2); g.rectangle('line',x,top,card,180); g.setLineWidth(1)
   V.color(V.ink);g.setFont(fonts.body); g.printf(locations[n],x,top+151,card,'center')
  end
  V.button(w/2-130,top+220,260,44,true)
  g.setColor(.89,.95,.95); g.setFont(fonts.body); g.printf('Begin your story',w/2-130,top+234,260,'center')
  g.setFont(fonts.small); V.color(V.muted); g.printf('Click a place or use arrow keys · Enter to begin',0,top+289,w,'center')
 else
  local previous=g.getCanvas(); g.setCanvas(I.canvas); g.clear(); I.renderScene(); g.setCanvas(previous)
  local w,h=g.getDimensions(); local s=math.max(1,math.floor(math.min(w/320,h/180)))
  g.setColor(.025,.03,.07); g.rectangle('fill',0,0,w,h)
  g.setColor(1,1,1); g.draw(I.canvas,math.floor((w-320*s)/2),math.floor((h-180*s)/2),0,s,s)
 end
end
return I
