local World=require('world')
local Characters=require('characters')
local Intro=require('intro')
local Campaign=require('campaign')
local Progress=require('progress')
local Adventure=require('adventure')
local Scenery=require('scenery')
local V=require('visual')
local Tabletop=require('tabletop')
local Savefile=require('savefile')
local journey,adventure
local ready=false
local splashTime=0
local saveTimer=0
local campaignStarted=false
local saveStatus=''
local changeRoom
local hudHits={}
local suspended=false
local pinchDistance
local rooms,roomId,player,visited={},1,{x=3,y=3},{}
local time,fade,steps=0,0,0
local fonts, character, errorText = {},nil,nil
local sides={'NE','SE','SW','NW'}
local function saveWorld(world)
  assert(love.filesystem.createDirectory('miswander-rooms'))
  for _,r in ipairs(world) do assert(love.filesystem.write('miswander-rooms/'..r.id..'.room',World.encode(r))) end
  assert(love.filesystem.write('miswander-world.txt',tostring(#world)..'\n'))
end
local function teleport(id,animate)
  local from=roomId;local old={x=player.x,y=player.y}
  roomId=id; local r=rooms[id]; player.x=r.width/2;player.y=r.height/2;fade=1
  if animate and rooms[from].level==r.level then
    local side;for candidate,target in pairs(rooms[from].visualExits)do if target==id then side=candidate end end
    if side then Tabletop.cross(from,old,id,player,side,World.opposite[side],rooms)else Tabletop.glide(from,old,id,player)end
  else Tabletop.snap(id,player)end
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
  start(false)
end
function love.load()
  love.graphics.setDefaultFilter('linear','linear')
  fonts.title=love.graphics.newFont(26);fonts.body=love.graphics.newFont(16);fonts.small=love.graphics.newFont(12)
  love.math.setRandomSeed(os.time())
  -- The startup diorama shares the same original isometric art as the game.
end
local function color(r,g,b,a)love.graphics.setColor(r,g,b,a or 1)end
local function gatePosition(r,side)return Tabletop.gate(r,side)end
changeRoom=function(side)
  local target=rooms[roomId].visualExits[side]; if not target then return end
  local from=roomId;local old={x=player.x,y=player.y}
  roomId=target; local r=rooms[roomId]; local entry=World.opposite[side]
  player.x,player.y=gatePosition(r,entry)
  if entry=='NE' then player.y=1 elseif entry=='SW' then player.y=r.height-1 elseif entry=='NW' then player.x=1 else player.x=r.width-1 end
  visited[roomId]=true; steps=steps+1; fade=0
  Tabletop.cross(from,old,target,player,side,entry,rooms)
  if journey then journey.room=roomId;journey.seen[roomId]=true end
end
function love.update(dt)
  if suspended then return end
  dt=math.min(dt,.05); time=time+dt; fade=math.max(0,fade-dt*2)
  if not ready then splashTime=splashTime+dt;if splashTime>=3 then setup() end;return end
  if os.getenv('ISOMET_SMOKE') and time>3.8 then if errorText then io.stderr:write(errorText..'\n');love.event.quit(1)else love.event.quit()end end
  if os.getenv('ISOMET_SMOKE') and time>3.6 and not love._smokeCaptured then love.graphics.captureScreenshot('smoke.png'); love._smokeCaptured=true end
  if errorText then return end
  if adventure and campaignStarted then adventure:update(dt);Tabletop.update(dt,rooms,roomId,player,journey) end
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
  if Tabletop.walk then return end
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
    if Scenery.blocked(r,x,y)then return false end
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
  if side and r.visualExits[side] then
    -- Step inward before presenting a board so cancelling never reopens it immediately.
    player.x=math.max(.8,math.min(r.width-.8,player.x));player.y=math.max(.8,math.min(r.height-.8,player.y))
    adventure:enter(side,r.visualExits[side])
  else player.x=math.max(.35,math.min(r.width-.35,player.x));player.y=math.max(.35,math.min(r.height-.35,player.y))end
end
function love.textinput(text)
  if ready and Characters.active and not errorText and not (adventure and adventure:active()) then Characters.textinput(text) end
end
function love.focus(focused)
  suspended=not focused
  if not focused and ready and campaignStarted then saveJourney()end
end
function love.touchpressed()pinchDistance=nil end
function love.touchreleased()pinchDistance=nil end
function love.touchmoved(_,x,y,dx,dy)
 if adventure and adventure.panel then adventure:wheelmoved(0,dy/45)
 elseif campaignStarted and not Intro.active and not adventure:active()then
  local ids=love.touch.getTouches()
  if #ids>=2 then
   local ax,ay=love.touch.getPosition(ids[1]);local bx,by=love.touch.getPosition(ids[2]);local distance=math.sqrt((bx-ax)^2+(by-ay)^2)
   if pinchDistance then Tabletop.zoomBy((distance-pinchDistance)/500)end
   pinchDistance=distance;Tabletop.drag(dx*.5,dy*.5)
  end
 end
end
function love.wheelmoved(x,y)
  if adventure and adventure:active()then adventure:wheelmoved(x,y)
  elseif campaignStarted and not Intro.active then Tabletop.zoomBy(y*.06)end
end
function love.mousemoved(x,y,dx,dy)
 if campaignStarted and not Intro.active and not adventure:active() and love.mouse.isDown(2)then Tabletop.drag(dx,dy)end
end
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
  elseif key=='=' or key=='+' then Tabletop.zoomBy(.08)
  elseif key=='-' then Tabletop.zoomBy(-.08)
  elseif key=='f' then Tabletop.recenter()
  elseif key=='f5' then saveJourney();start(false)
  elseif key=='n' and love.keyboard.isDown('lctrl','rctrl') then
    adventure:show('Start a new journey?','This resets quest progress and lives after character creation and the introduction.',{{'New traveler',newCharacter},{'Keep exploring',function()adventure:close()end}})
  elseif key=='o' then love.system.openURL('file://'..love.filesystem.getSaveDirectory())end
end
function love.draw()
  local g=love.graphics; local w,h=g.getDimensions()
  g.clear(.027,.035,.075)
  if not ready then
    V.title(w,h,splashTime,fonts.title)
    g.setFont(fonts.body);V.color(V.ink);g.printf('A familiar place, taken apart. A way home, waiting to be found.',20,h-45,w-40,'center')
    return
  end
  V.background(w,h,time)
  g.setFont(fonts.body)
  if errorText then color(1,.7,.7); g.printf('Could not load room data\n\n'..errorText..'\n\nPress O to open the data folder and correct the files.\nF5: retry loading',60,150,w-120,'center'); return end
  if adventure and adventure:active() then adventure:draw(fonts);return end
  if Characters.active then Characters.draw(fonts,time); return end
  if Intro.active then Intro.draw(fonts); return end
  local r=Tabletop.draw(rooms,roomId,player,journey,character,time,fonts)
  V.card(20,16,w-40,99,false)
  V.color(V.teal);g.setFont(fonts.small);g.print('M I S W A N D E R  /  '..Campaign.worlds[r.level].name:upper(),32,25)
  V.color(V.ink);g.setFont(fonts.title);local heading=Characters.name..'  /  '..r.name
  g.print(heading,32,55,0,math.min(1,(w-64)/fonts.title:getWidth(heading)),1)
  g.setFont(fonts.body);V.color({.68,.32,.24})
  local lives='Hearts '..journey.hearts..' / 5'
  if journey.hearts<5 then local wait=journey:wait();lives=lives..string.format(' · Next %02d:%02d',math.floor(wait/60),wait%60)end
  g.printf(lives,30,92,w-60,'right')
  g.setFont(fonts.small);local labels={}
  for _,side in ipairs(sides)do local id=r.visualExits[side];if id then local _,_,d=Campaign.info(id);labels[#labels+1]=side..': '..(journey.seen[id]and rooms[id].name or(d and d[1]or'Unexplored passage'))..(journey:locked(id) and ' [sealed]' or '')end end
  V.card(73,h-143,w-146,48,false);V.color(V.ink);g.printf(table.concat(labels,'   /   '),80,h-135,w-160,'center')
  hudHits={}
  local buttons={{'Inspect',function()adventure:inspect()end},{'Satchel',function()adventure:satchel()end},{'Notebook',function()adventure:notebook()end},{'Map',function()adventure:map()end},{'Pip',function()adventure:hint()end}}
  local bw=math.floor(math.min(140,(w-210)/5));local left=math.max(150,math.floor((w-bw*5-24)/2))
  for i,b in ipairs(buttons)do local x=left+(i-1)*(bw+6);local y=h-77
    V.button(x,y,bw,42,false);V.icon(b[1],x+8,y+10,1);color(1,1,.94);g.setFont(fonts.body);g.printf(b[1],x+28,y+12,bw-30,'center')
    hudHits[#hudHits+1]={x=x,y=y,w=bw,h=42,action=b[2]}
  end
  -- Mouse/touch movement pad; desktop arrow/WASD controls remain available.
  local pad={{'NE',0,-1,50,h-106},{'NW',-1,0,6,h-62},{'SE',1,0,94,h-62},{'SW',0,1,50,h-18}}
  for _,b in ipairs(pad)do local y=math.min(h-37,b[5]);V.button(b[4],y,42,34,false);color(1,1,.94);g.setFont(fonts.small);g.printf(b[1],b[4],y+10,42,'center');hudHits[#hudHits+1]={x=b[4],y=y,w=42,h=34,dx=b[2],dy=b[3]}end
  V.color(V.ink);g.setFont(fonts.small);g.printf('Move: arrows / WASD · E: inspect · Wheel / +/-: zoom · Right-drag: pan · F: follow',150,h-21,w-170,'center')
  if saveStatus~='' then color(1,.6,.45);g.printf(saveStatus,20,118,w-40,'center')end
  if adventure.toastTime and adventure.toastTime>0 then V.card(w/2-240,127,480,30,false);V.color(V.teal);g.printf(adventure.toast,w/2-230,134,460,'center')end
end
