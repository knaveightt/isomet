local World=require('world')
local Characters=require('characters')
local rooms, roomId, player, visited, stars = {},1,{x=3,y=3}, {},{}
local time,fade,steps,won=0,0,0,false
local fonts, character, errorText = {},nil,nil
local sides={'NE','SE','SW','NW'}
local palette={{.16,.22,.31},{.21,.19,.32},{.14,.25,.29},{.25,.20,.29}}
local function saveWorld(world)
  assert(love.filesystem.createDirectory('rooms'))
  for _,r in ipairs(world) do assert(love.filesystem.write('rooms/'..r.id..'.room',World.encode(r))) end
  assert(love.filesystem.write('world.txt',tostring(#world)..'\n'))
end
local function start(fresh)
  errorText=nil
  local ok,result=pcall(function()
    if fresh or not love.filesystem.getInfo('world.txt') then local w=World.generate(love.math.random); World.validate(w); saveWorld(w); return w end
    local count=tonumber((love.filesystem.read('world.txt'))); assert(count and count>=1 and count<=100,'Invalid world manifest')
    local w={}; for id=1,count do w[id]=World.decode(assert(love.filesystem.read('rooms/'..id..'.room')),id) end
    World.validate(w); return w
  end)
  if not ok then errorText=tostring(result); return end
  rooms=result; roomId=1; player={x=rooms[1].width/2,y=rooms[1].height/2}; visited={[1]=true}; steps=0; won=false; fade=1
end
function love.load()
  love.graphics.setDefaultFilter('nearest','nearest')
  fonts.title=love.graphics.newFont(26); fonts.body=love.graphics.newFont(14); fonts.small=love.graphics.newFont(12)
  love.math.setRandomSeed(os.time()); Characters.load(); character=Characters.images[1]
  for i=1,180 do stars[i]={x=love.math.random(),y=love.math.random(),z=love.math.random(),phase=love.math.random()*6.28} end
  start(false)
  if os.getenv("ISOMET_SMOKE") and errorText then io.stderr:write(errorText.."\n"); love.event.quit(1) end
end
local ox,oy,scale=0,0,1
local function project(x,y,z) return ox+(x-y)*30*scale,oy+(x+y)*15*scale-(z or 0)*scale end
local function color(r,g,b,a) love.graphics.setColor(r,g,b,a or 1) end
local function diamond(x,y,r,g,b)
  local a,b1=project(x,y); local c,d=project(x+1,y); local e,f=project(x+1,y+1); local g1,h=project(x,y+1)
  color(r,g,b); love.graphics.polygon('fill',a,b1,c,d,e,f,g1,h)
  color(.6,.8,.9,.055); love.graphics.polygon('line',a,b1,c,d,e,f,g1,h)
end
local function gatePosition(r,side)
  if side=='NE' then return r.width/2,.15 elseif side=='SW' then return r.width/2,r.height-.15 elseif side=='NW' then return .15,r.height/2 else return r.width-.15,r.height/2 end
end
local function arch(r,side)
  local x,y=gatePosition(r,side); local dx,dy=0,0
  if side=='NE' or side=='SW' then dx=.70 else dy=.70 end
  local ax,ay=project(x-dx,y-dy); local bx,by=project(x+dx,y+dy)
  local h=65*scale
  -- Open center: the floor remains visible through the doorway.
  color(.1,.13,.22); love.graphics.setLineWidth(13*scale); love.graphics.line(ax,ay,ax,ay-h,bx,by-h,bx,by)
  color(.38,.53,.64); love.graphics.setLineWidth(8*scale); love.graphics.line(ax-2*scale,ay,ax-2*scale,ay-h,bx-2*scale,by-h,bx-2*scale,by)
  color(.48,.92,.9,.8); love.graphics.setLineWidth(2*scale); love.graphics.line(ax,ay-h+7*scale,bx,by-h+7*scale)
  love.graphics.setLineWidth(1)
end
local function pillar(p)
  local x,y=project(p.x,p.y); local w,h=12*scale,56*scale
  color(.11,.14,.23); love.graphics.polygon('fill',x-w,y-h,x,y-h+6*scale,x,y+5*scale,x-w,y)
  color(.24,.29,.39); love.graphics.polygon('fill',x,y-h+6*scale,x+w,y-h,x+w,y,x,y+5*scale)
  color(.42,.49,.58); love.graphics.polygon('fill',x-w,y-h,x,y-h-6*scale,x+w,y-h,x,y-h+6*scale)
  color(.55,.82,.83,.6); love.graphics.rectangle('fill',x+4*scale,y-h+14*scale,2*scale,12*scale)
end
local function portal(r)
  local x,y=project(r.width/2,r.height/2,27)
  color(.47,.26,.9,.12); love.graphics.ellipse('fill',x,y,32*scale,47*scale)
  for i=1,4 do color(.45+i*.1,.55+i*.09,1,.9-i*.13); love.graphics.setLineWidth((5-i)*scale); love.graphics.ellipse('line',x,y,(19+i*2+math.sin(time*2+i))*scale,(30+i*2)*scale) end
  for i=1,12 do local a=i*2.4+time; color(.8,.8,1,.6); love.graphics.circle('fill',x+math.cos(a)*27*scale,y+math.sin(a)*40*scale,1.5*scale) end
  love.graphics.setLineWidth(1)
end
local function changeRoom(side)
  local target=rooms[roomId].exits[side]; if not target then return end
  roomId=target; local r=rooms[roomId]; local entry=World.opposite[side]
  player.x,player.y=gatePosition(r,entry)
  if entry=='NE' then player.y=1 elseif entry=='SW' then player.y=r.height-1 elseif entry=='NW' then player.x=1 else player.x=r.width-1 end
  visited[roomId]=true; steps=steps+1; fade=1
end
function love.update(dt)
  dt=math.min(dt,.05); time=time+dt; fade=math.max(0,fade-dt*2)
  if os.getenv('ISOMET_SMOKE') and time>.7 then love.event.quit() end
  if os.getenv('ISOMET_SMOKE') and time>.55 and not love._smokeCaptured then love.graphics.captureScreenshot('smoke.png'); love._smokeCaptured=true end
  if errorText or Characters.active or won then return end
  local dx,dy=0,0
  if love.keyboard.isDown('up','w') then dy=dy-1 end
  if love.keyboard.isDown('down','s') then dy=dy+1 end
  if love.keyboard.isDown('left','a') then dx=dx-1 end
  if love.keyboard.isDown('right','d') then dx=dx+1 end
  if dx~=0 and dy~=0 then dx=dx*.7071; dy=dy*.7071 end
  local r=rooms[roomId]; local speed=love.keyboard.isDown('lshift','rshift') and 4.6 or 2.9
  local function clear(x,y)
    for _,p in ipairs(r.pillars) do if math.abs(x-p.x)<.48 and math.abs(y-p.y)<.48 then return false end end
    return true
  end
  local nx,ny=player.x+dx*dt*speed,player.y+dy*dt*speed
  if clear(nx,player.y) then player.x=nx end
  if clear(player.x,ny) then player.y=ny end
  local side
  if player.y<.32 and math.abs(player.x-r.width/2)<.65 then side='NE'
  elseif player.y>r.height-.32 and math.abs(player.x-r.width/2)<.65 then side='SW'
  elseif player.x<.32 and math.abs(player.y-r.height/2)<.65 then side='NW'
  elseif player.x>r.width-.32 and math.abs(player.y-r.height/2)<.65 then side='SE' end
  if side and r.exits[side] then changeRoom(side) else player.x=math.max(.35,math.min(r.width-.35,player.x)); player.y=math.max(.35,math.min(r.height-.35,player.y)) end
  r=rooms[roomId]
  if r.portal and (player.x-r.width/2)^2+(player.y-r.height/2)^2<.55^2 then won=true end
end
function love.textinput(text)
  if Characters.active and not errorText then Characters.textinput(text) end
end
function love.mousepressed(x,y,button)
  if Characters.active and not errorText and Characters.mousepressed(x,y,button) then character=Characters.images[Characters.selected] end
end
function love.keypressed(key)
  if Characters.active and not errorText then
    if key=='escape' then love.event.quit()
    elseif Characters.keypressed(key) then character=Characters.images[Characters.selected] end
    return
  end
  if key=='escape' then love.event.quit() elseif key=='f5' then start(false)
  elseif key=='n' and love.keyboard.isDown('lctrl','rctrl') then start(true)
  elseif key=='o' then love.system.openURL('file://'..love.filesystem.getSaveDirectory()) end
end
function love.draw()
  local g=love.graphics; local w,h=g.getDimensions()
  g.clear(.027,.035,.075)
  for i=1,7 do color(.15,.12,.28,.055); g.ellipse('fill',w*.5+math.sin(time*.025+i)*w*.3,h*.5+math.cos(time*.02+i)*h*.3,w*.4,h*.16) end
  for _,s in ipairs(stars) do
    local x=(s.x*w+time*(2+s.z*6))%w; local y=(s.y*h+math.sin(time*.08+s.phase)*8)%h
    color(.5,.65,.9,.2+.35*(.5+.5*math.sin(time*.6+s.phase))); g.circle('fill',x,y,s.z>.9 and 1.6 or .8)
  end
  g.setFont(fonts.body)
  if errorText then color(1,.7,.7); g.printf('Could not load room data\n\n'..errorText..'\n\nPress O to open the data folder and correct the files.\nF5: reload    Ctrl+N: replace with a new maze',60,150,w-120,'center'); return end
  if Characters.active then Characters.draw(fonts,time); return end
  local r=rooms[roomId]
  scale=math.min((w-120)/((r.width+r.height)*30),(h-240)/((r.width+r.height)*15+80),1.5)
  ox=w/2-(r.width-r.height)*15*scale; oy=h/2-(r.width+r.height)*7.5*scale+35
  local a,b=project(0,0); local c,d=project(r.width,0); local e,f=project(r.width,r.height); local j,k=project(0,r.height)
  color(.055,.07,.13); g.polygon('fill',j,k,e,f,e,f+20*scale,j,k+20*scale)
  color(.08,.10,.18); g.polygon('fill',c,d,e,f,e,f+20*scale,c,d+20*scale)
  local base=palette[(roomId-1)%#palette+1]
  for x=0,r.width-1 do for y=0,r.height-1 do local v=((x*17+y*31+roomId*7)%9)*.003; diamond(x,y,base[1]+v,base[2]+v,base[3]+v) end end
  -- Small inlaid marks establish scale without cluttering the floor.
  for _,side in ipairs(sides) do if r.exits[side] then
    local x,y=gatePosition(r,side); local px,py=project(x,y)
    color(.6,.86,.85,.7); g.circle('fill',px,py,3*scale)
  end end
  local objects={}
  for _,p in ipairs(r.pillars) do objects[#objects+1]={depth=p.x+p.y,draw=function() pillar(p) end} end
  for _,side in ipairs(sides) do if r.exits[side] then local s=side; local x,y=gatePosition(r,s); objects[#objects+1]={depth=x+y,draw=function() arch(r,s) end} end end
  if r.portal then objects[#objects+1]={depth=(r.width+r.height)/2,draw=function() portal(r) end} end
  objects[#objects+1]={depth=player.x+player.y,draw=function()
    local x,y=project(player.x,player.y); color(0,0,0,.3); g.ellipse('fill',x,y,12*scale,5*scale)
    local moving=love.keyboard.isDown('up','down','left','right','w','a','s','d') and not won
    local bob=moving and math.sin(time*15)*1.5 or 0
    color(1,1,1); g.draw(character,x-16*scale,y-31*scale+bob*scale,0,2*scale,2*scale)
  end}
  table.sort(objects,function(l,r1) return l.depth<r1.depth end); for _,o in ipairs(objects) do o.draw() end
  color(.8,.89,.94); g.setFont(fonts.small); g.print('I S O M E T   /   T H E   Q U I E T   B E T W E E N',32,27)
  g.setFont(fonts.title)
  local heading=Characters.name..'  /  '..r.name
  local headingScale=math.min(1,(w-64)/fonts.title:getWidth(heading))
  g.print(heading,32,58,0,headingScale,headingScale)
  local count=0; for _ in pairs(visited) do count=count+1 end
  g.setFont(fonts.body); color(.52,.67,.76); g.printf(string.format('%02d / %02d chambers discovered',count,#rooms),w-330,36,298,'right')
  color(.7,.8,.84); g.printf('Find the violet portal. Follow the luminous arches.',0,h-92,w,'center')
  g.setFont(fonts.small); color(.46,.57,.67); g.printf('Up: NE    Right: SE    Down: SW    Left: NW      •      Shift: run      •      F5: restart      •      O: room files      •      Ctrl+N: new maze',20,h-54,w-40,'center')
  if steps==0 then color(.62,.76,.8,.7); g.printf('You have fallen outside the world. Somewhere, there is a way back.',0,99,w,'center') end
  if fade>0 then color(.03,.04,.09,fade*.65); g.rectangle('fill',0,120,w,h-230) end
  if won then
    color(.025,.03,.07,.9); g.rectangle('fill',0,0,w,h)
    color(.77,.67,1); g.setFont(fonts.title); g.printf('THE VOID RELEASES YOU',0,h/2-65,w,'center')
    g.setFont(fonts.body); color(.75,.82,.9); g.printf('You found the last threshold.\n'..count..' chambers discovered · '..steps..' thresholds crossed\n\nF5: explore this maze again     Ctrl+N: generate another',0,h/2-12,w,'center')
  end
end
