local World=require('world')
local Characters=require('characters')
local Intro=require('intro')
local Campaign=require('campaign')
local Progress=require('progress')
local Adventure=require('adventure')
local Scenery=require('scenery')
local Savefile=require('savefile')
local journey,adventure
local ready=false
local splashTime=0
local splashImage
local saveTimer=0
local campaignStarted=false
local saveStatus=''
local changeRoom
local hudHits={}
local suspended=false
local rooms, roomId, player, visited, stars = {},1,{x=3,y=3}, {},{}
local time,fade,steps,won=0,0,0,false
local fonts, character, errorText = {},nil,nil
local sides={'NE','SE','SW','NW'}
local palette={{.16,.22,.31},{.21,.19,.32},{.14,.25,.29},{.25,.20,.29}}
local function saveWorld(world)
  assert(love.filesystem.createDirectory('miswander-rooms'))
  for _,r in ipairs(world) do assert(love.filesystem.write('miswander-rooms/'..r.id..'.room',World.encode(r))) end
  assert(love.filesystem.write('miswander-world.txt',tostring(#world)..'\n'))
end
local function teleport(id)
  roomId=id; local r=rooms[id]; player.x=r.width/2;player.y=r.height/2;fade=1
  if journey then journey.room=id;journey.x=player.x;journey.y=player.y;journey.seen[id]=true end
end
local function saveJourney()
  if not campaignStarted then return true end
  journey.room=roomId;journey.x=player.x;journey.y=player.y
  local ok,err=Savefile.write('miswander-journey.txt',journey:encode())
  saveStatus=ok and '' or ('Save failed: '..tostring(err))
  return ok
end
local function bindAdventure()
  adventure=Adventure.new({rooms=rooms,save=saveJourney,room=function()return roomId end,move=function(side)changeRoom(side)end,teleport=teleport},journey)
end
local function newCharacter()
  campaignStarted=false;journey=Progress.new();bindAdventure();teleport(1)
  Characters.active=true;Characters.name='';Characters.message=nil;Intro.active=false
  love.keyboard.setTextInput(true);love.keyboard.setKeyRepeat(true)
end
local function resumeJourney()
  campaignStarted=true;Characters.active=false;Intro.active=false
  Characters.name=journey.profile.name;Characters.selected=journey.profile.variant;character=Characters.images[Characters.selected]
  love.keyboard.setTextInput(false);love.keyboard.setKeyRepeat(false)
  teleport(journey.room)
end
local function start(fresh)
  errorText=nil
  local ok,result=pcall(function()
    if fresh or not love.filesystem.getInfo('miswander-world.txt') then
      local w=Campaign.generate(love.math.random);Campaign.validate(w);saveWorld(w);return w
    end
    local count=tonumber((love.filesystem.read('miswander-world.txt')));assert(count==60,'Miswander expects 60 corridor/interior rooms')
    local w={};for id=1,count do w[id]=World.decode(assert(love.filesystem.read('miswander-rooms/'..id..'.room')),id)end
    Campaign.attach(w);Campaign.validate(w);return w
  end)
  if not ok then errorText=tostring(result);return end
  rooms=result
  local saved=Savefile.read('miswander-journey.txt')
  if saved and not fresh then
    local success,p=pcall(Progress.decode,saved)
    if not success then errorText='Journey file: '..tostring(p);return end
    journey=p;bindAdventure();roomId=journey.room;player.x=journey.x or rooms[roomId].width/2;player.y=journey.y or rooms[roomId].height/2
    adventure:show('Welcome back to Miswander','Your progress, discoveries, quest items and unlocked passages are saved.',{
      {'Continue journey',function()
        local x,y=journey.x,journey.y;local id=journey.room
        resumeJourney();if x and y then player.x=math.max(.4,math.min(rooms[id].width-.4,x));player.y=math.max(.4,math.min(rooms[id].height-.4,y))end
        adventure:close()
      end},
      {'New journey',function()
        adventure:show('Begin again?','This replaces your Miswander journey after the introduction. Earlier ISOMET room files are preserved.',{
          {'Choose a new traveler',newCharacter},{'Keep this journey',function()start(false)end}})
      end}})
  else newCharacter() end
end
local function setup()
  ready=true
  Characters.load();character=Characters.images[1]
  for i=1,180 do stars[i]={x=love.math.random(),y=love.math.random(),z=love.math.random(),phase=love.math.random()*6.28}end
  start(false)
end
function love.load()
  love.graphics.setDefaultFilter('nearest','nearest')
  fonts.title=love.graphics.newFont(26);fonts.body=love.graphics.newFont(16);fonts.small=love.graphics.newFont(12)
  love.math.setRandomSeed(os.time())
  splashImage=love.graphics.newImage('assets/miswander-title.png');splashImage:setFilter('linear','linear')
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
changeRoom=function(side)
  local target=rooms[roomId].exits[side]; if not target then return end
  roomId=target; local r=rooms[roomId]; local entry=World.opposite[side]
  player.x,player.y=gatePosition(r,entry)
  if entry=='NE' then player.y=1 elseif entry=='SW' then player.y=r.height-1 elseif entry=='NW' then player.x=1 else player.x=r.width-1 end
  visited[roomId]=true; steps=steps+1; fade=1
  if journey then journey.room=roomId;journey.seen[roomId]=true end
end
function love.update(dt)
  if suspended then return end
  dt=math.min(dt,.05); time=time+dt; fade=math.max(0,fade-dt*2)
  if not ready then splashTime=splashTime+dt;if splashTime>=3 then setup() end;return end
  if os.getenv('ISOMET_SMOKE') and time>3.8 then if errorText then io.stderr:write(errorText..'\n');love.event.quit(1)else love.event.quit()end end
  if os.getenv('ISOMET_SMOKE') and time>3.6 and not love._smokeCaptured then love.graphics.captureScreenshot('smoke.png'); love._smokeCaptured=true end
  if errorText then return end
  if adventure and campaignStarted then adventure:update(dt) end
  if adventure and adventure:active() then return end
  if Characters.active then return end
  if Intro.active then
    if Intro.update(dt) then
      campaignStarted=true
      journey.profile={name=Characters.name,variant=Characters.selected,origin=({'City','Suburb','Midwest'})[Intro.selected],companion=Intro.companion}
      teleport(1);saveJourney();adventure:arrival()
    end
    return
  end
  adventure:travel(dt)
  saveTimer=saveTimer+dt;if saveTimer>=10 then saveJourney();saveTimer=0 end
  local dx,dy=0,0
  if love.keyboard.isDown('up','w') then dy=dy-1 end
  if love.keyboard.isDown('down','s') then dy=dy+1 end
  if love.keyboard.isDown('left','a') then dx=dx-1 end
  if love.keyboard.isDown('right','d') then dx=dx+1 end
  if love.mouse.isDown(1) or #love.touch.getTouches()>0 then
    local tx,ty=love.mouse.getPosition();local touches=love.touch.getTouches();if touches[1] then tx,ty=love.touch.getPosition(touches[1])end
    for _,hit in ipairs(hudHits)do if hit.dx and tx>=hit.x and tx<=hit.x+hit.w and ty>=hit.y and ty<=hit.y+hit.h then dx,dy=hit.dx,hit.dy end end
  end
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
  if side and r.exits[side] then
    -- Step inward before presenting a board so cancelling never reopens it immediately.
    player.x=math.max(.8,math.min(r.width-.8,player.x));player.y=math.max(.8,math.min(r.height-.8,player.y))
    adventure:enter(side,r.exits[side])
  else player.x=math.max(.35,math.min(r.width-.35,player.x));player.y=math.max(.35,math.min(r.height-.35,player.y))end
end
function love.textinput(text)
  if ready and Characters.active and not errorText and not (adventure and adventure:active()) then Characters.textinput(text) end
end
function love.focus(focused)
  suspended=not focused
  if not focused and ready and campaignStarted then saveJourney()end
end
function love.touchmoved(_,x,y,dx,dy)
  if adventure and adventure.panel then adventure:wheelmoved(0,dy/45)end
end
function love.wheelmoved(x,y)if adventure then adventure:wheelmoved(x,y)end end
function love.quit()if ready and campaignStarted then saveJourney()end end
function love.mousepressed(x,y,button)
  if not ready then return end
  if adventure and adventure:active() then adventure:mousepressed(x,y,button);return end
  if campaignStarted and not Intro.active and not Characters.active and button==1 then
    for _,hit in ipairs(hudHits)do if hit.action and x>=hit.x and x<=hit.x+hit.w and y>=hit.y and y<=hit.y+hit.h then hit.action();return end end
  end
  if Intro.active and not errorText then Intro.mousepressed(x,y,button); return end
  if Characters.active and not errorText and Characters.mousepressed(x,y,button) then character=Characters.images[Characters.selected]; Intro.begin(Characters) end
end
function love.keypressed(key)
  if not ready then if key=='escape' then love.event.quit()end;return end
  if errorText then
    if key=='o' then love.system.openURL('file://'..love.filesystem.getSaveDirectory())elseif key=='f5' then start(false)elseif key=='escape' then love.event.quit()end
    return
  end
  if adventure and adventure:active() then adventure:keypressed(key);return end
  if Intro.active and not errorText then
    if key=='escape' then love.event.quit() else Intro.keypressed(key) end
    return
  end
  if Characters.active and not errorText then
    if key=='escape' then love.event.quit()
    elseif Characters.keypressed(key) then character=Characters.images[Characters.selected]; Intro.begin(Characters) end
    return
  end
  if key=='escape' then
    saveJourney();adventure:show('Between moments','Your journey is saved. Take your time.',{
      {'Resume',function()adventure:close()end},{'Notebook',function()adventure:notebook()end},{'Satchel',function()adventure:satchel()end},{'Save and quit',function()if saveJourney()then love.event.quit()end end}})
  elseif key=='e' then adventure:inspect()
  elseif key=='j' then adventure:notebook()
  elseif key=='i' then adventure:satchel()
  elseif key=='m' then adventure:map()
  elseif key=='p' then adventure:hint()
  elseif key=='l' then adventure:lamp()
  elseif key=='f5' then saveJourney();start(false)
  elseif key=='n' and love.keyboard.isDown('lctrl','rctrl') then
    adventure:show('Start a new journey?','This resets quest progress and lives after character creation and the introduction.',{{'New traveler',newCharacter},{'Keep exploring',function()adventure:close()end}})
  elseif key=='o' then love.system.openURL('file://'..love.filesystem.getSaveDirectory())end
end
function love.draw()
  local g=love.graphics; local w,h=g.getDimensions()
  g.clear(.027,.035,.075)
  if not ready then
    local iw,ih=splashImage:getDimensions();local fit=math.min(w/iw,(h-65)/ih)
    color(1,1,1,math.min(1,splashTime*2,(3-splashTime)*2));g.draw(splashImage,(w-iw*fit)/2,(h-ih*fit)/2,0,fit,fit)
    g.setFont(fonts.body);color(.85,.79,.63);g.printf('A familiar place, taken apart. A way home, waiting to be found.',20,h-45,w-40,'center')
    return
  end
  for i=1,7 do color(.15,.12,.28,.055); g.ellipse('fill',w*.5+math.sin(time*.025+i)*w*.3,h*.5+math.cos(time*.02+i)*h*.3,w*.4,h*.16) end
  for _,s in ipairs(stars) do
    local x=(s.x*w+time*(2+s.z*6))%w; local y=(s.y*h+math.sin(time*.08+s.phase)*8)%h
    color(.5,.65,.9,.2+.35*(.5+.5*math.sin(time*.6+s.phase))); g.circle('fill',x,y,s.z>.9 and 1.6 or .8)
  end
  g.setFont(fonts.body)
  if errorText then color(1,.7,.7); g.printf('Could not load room data\n\n'..errorText..'\n\nPress O to open the data folder and correct the files.\nF5: retry loading',60,150,w-120,'center'); return end
  if adventure and adventure:active() then adventure:draw(fonts);return end
  if Characters.active then Characters.draw(fonts,time); return end
  if Intro.active then Intro.draw(fonts); return end
  local r=rooms[roomId]
  scale=math.min((w-120)/((r.width+r.height)*30),(h-240)/((r.width+r.height)*15+80),1.5)
  ox=w/2-(r.width-r.height)*15*scale; oy=h/2-(r.width+r.height)*7.5*scale+35
  local a,b=project(0,0); local c,d=project(r.width,0); local e,f=project(r.width,r.height); local j,k=project(0,r.height)
  color(.055,.07,.13); g.polygon('fill',j,k,e,f,e,f+20*scale,j,k+20*scale)
  color(.08,.10,.18); g.polygon('fill',c,d,e,f,e,f+20*scale,c,d+20*scale)
  local base=Campaign.worlds[r.level].color
  for x=0,r.width-1 do for y=0,r.height-1 do local v=((x*17+y*31+roomId*7)%9)*.003; diamond(x,y,base[1]+v,base[2]+v,base[3]+v) end end
  Scenery.draw(r,journey.profile.origin,project,scale,time)
  -- Small inlaid marks establish scale without cluttering the floor.
  for _,side in ipairs(sides) do if r.exits[side] then
    local x,y=gatePosition(r,side); local px,py=project(x,y)
    local locked=journey:locked(r.exits[side]);color(locked and .95 or .6,locked and .65 or .86,locked and .3 or .85,.9);g.circle('fill',px,py,3*scale)
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
  color(.90,.77,.46);g.setFont(fonts.small);g.print('M I S W A N D E R  /  '..Campaign.worlds[r.level].name:upper(),32,25)
  g.setFont(fonts.title);local heading=Characters.name..'  /  '..r.name
  g.print(heading,32,55,0,math.min(1,(w-64)/fonts.title:getWidth(heading)),1)
  g.setFont(fonts.body);color(.88,.74,.65)
  local lives='Hearts '..journey.hearts..' / 5'
  if journey.hearts<5 then local wait=journey:wait();lives=lives..string.format(' · Next %02d:%02d',math.floor(wait/60),wait%60)end
  g.printf(lives,30,92,w-60,'right')
  g.setFont(fonts.small);local labels={}
  for _,side in ipairs(sides)do local id=r.exits[side];if id then local _,_,d=Campaign.info(id);labels[#labels+1]=side..': '..(d and d[1] or rooms[id].name)..(journey:locked(id) and ' [sealed]' or '')end end
  color(.72,.81,.84);g.printf(table.concat(labels,'   /   '),80,h-135,w-160,'center')
  if r.slot==11 then color(.025,.035,.065,journey.lightOn and .04 or .42);g.rectangle('fill',0,130,w,h-280)end
  hudHits={}
  local buttons={{'Inspect',function()adventure:inspect()end},{'Satchel',function()adventure:satchel()end},{'Notebook',function()adventure:notebook()end},{'Map',function()adventure:map()end},{'Pip',function()adventure:hint()end}}
  local bw=math.floor(math.min(140,(w-210)/5));local left=math.max(150,math.floor((w-bw*5-24)/2))
  for i,b in ipairs(buttons)do local x=left+(i-1)*(bw+6);local y=h-77
    color(.15,.27,.32);g.rectangle('fill',x,y,bw,42,5,5);color(.91,.89,.76);g.setFont(fonts.body);g.printf(b[1],x,y+12,bw,'center')
    hudHits[#hudHits+1]={x=x,y=y,w=bw,h=42,action=b[2]}
  end
  -- Mouse/touch movement pad; desktop arrow/WASD controls remain available.
  local pad={{'NE',0,-1,50,h-106},{'NW',-1,0,6,h-62},{'SE',1,0,94,h-62},{'SW',0,1,50,h-18}}
  for _,b in ipairs(pad)do local y=math.min(h-37,b[5]);color(.16,.26,.32,.9);g.rectangle('fill',b[4],y,42,34,4,4);color(.8,.87,.89);g.setFont(fonts.small);g.printf(b[1],b[4],y+10,42,'center');hudHits[#hudHits+1]={x=b[4],y=y,w=42,h=34,dx=b[2],dy=b[3]}end
  color(.50,.65,.71);g.setFont(fonts.small);g.printf('Arrows / WASD: move · Shift: run · E: inspect · I / J / M / P: tools · Esc: pause',150,h-21,w-170,'center')
  if saveStatus~='' then color(1,.6,.45);g.printf(saveStatus,20,118,w-40,'center')end
  if fade>0 then color(.03,.04,.09,fade*.65);g.rectangle('fill',0,130,w,h-280)end
end
