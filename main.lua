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
local Navigation=require('navigation')
local walkPath,walkAction
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
  walkPath=nil;walkAction=nil
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
        resumeJourney();if x and y and Navigation.clear(rooms[id],x,y)then player.x=x;player.y=y end
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
  fonts.title=love.graphics.newFont('assets/fonts/OpenSans-ExtraBold.ttf',26,'normal',3);fonts.body=love.graphics.newFont('assets/fonts/OpenSans-Semibold.ttf',16,'normal',3);fonts.small=love.graphics.newFont('assets/fonts/OpenSans-Semibold.ttf',12,'normal',3)
  love.math.setRandomSeed(os.time())
  -- The startup diorama shares the same original isometric art as the game.
end
local function color(r,g,b,a)love.graphics.setColor(r,g,b,a or 1)end
local function gatePosition(r,side)return Tabletop.gate(r,side)end
changeRoom=function(side)
  walkPath=nil;walkAction=nil
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
  if adventure and adventure:active() then walkPath=nil;walkAction=nil;return end
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
  if dx~=0 or dy~=0 then walkPath=nil;walkAction=nil end
  local r=rooms[roomId];local speed=love.keyboard.isDown('lshift','rshift')and 4.6 or 2.9
  if walkPath then
    local target=walkPath[1];local vx,vy=target.x-player.x,target.y-player.y;local distance=math.sqrt(vx*vx+vy*vy)
    if distance<=speed*dt then
      player.x,player.y=target.x,target.y;table.remove(walkPath,1)
      if #walkPath==0 then local action=walkAction;walkPath=nil;walkAction=nil;if action then action();return end end
    else dx,dy=vx/distance,vy/distance end
  end
  if dx~=0 and dy~=0 and not walkPath then dx=dx*.7071; dy=dy*.7071 end
  local function clear(x,y)return Navigation.clear(r,x,y)end
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
  end
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
    for _,hit in ipairs(hudHits)do if hit.dx and x>=hit.x and x<=hit.x+hit.w and y>=hit.y and y<=hit.y+hit.h then walkPath=nil;walkAction=nil;return end end
    if Tabletop.walk then return end
    local pick=Tabletop.pick and Tabletop.pick(x,y,rooms,roomId,journey)
    if pick then
      local r=rooms[roomId];local tx,ty=pick.x,pick.y;local action
      if pick.side then
        tx,ty=gatePosition(r,pick.side);tx=math.max(.8,math.min(r.width-.8,tx));ty=math.max(.8,math.min(r.height-.8,ty))
        local side,target=pick.side,pick.target;action=function()adventure:enter(side,target)end
      elseif pick.inspect then
        tx,ty=r.width/2,r.height/2;action=function()adventure:inspect()end
      end
      walkPath=Navigation.path(r,player.x,player.y,tx,ty);walkAction=walkPath and action or nil
      if not walkPath then adventure.toast='Choose a clear path in this room, or a connected doorway.';adventure.toastTime=2 end
    end
    return

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
  local uiScale=math.max(1,math.min(w/1200,h/800));g.push();g.scale(uiScale);w=w/uiScale;h=h/uiScale
  local headerW=math.min(420,w*.54)
  V.overlay(16,14,headerW,88)
  require('cartoon').traveler(character,50,92,48,67)
  g.setFont(fonts.small);V.color({.95,.84,.58});g.print('MISWANDER · '..Campaign.worlds[r.level].name,84,23)
  g.setFont(fonts.title);local heading=r.name;local hs=math.min(.78,(headerW-84)/fonts.title:getWidth(heading))
  V.color({1,.97,.86});g.print(heading,84,44,0,hs,hs)
  g.setFont(fonts.small);V.color({.88,.91,.81});g.print(Characters.name,85,77)
  V.overlay(w-190,14,174,76)
  for i=1,5 do V.heart(w-165+(i-1)*29,35,i<=journey.hearts)end
  g.setFont(fonts.small);V.color({1,.94,.77})
  local lives='Hearts '..journey.hearts..' / 5'
  if journey.hearts<5 then local wait=journey:wait();lives=string.format('Next heart %02d:%02d',math.floor(wait/60),wait%60)end
  g.printf(lives,w-186,60,166,'center')
  hudHits={}
  local buttons={{'Inspect',function()adventure:inspect()end},{'Satchel',function()adventure:satchel()end},{'Notebook',function()adventure:notebook()end},{'Map',function()adventure:map()end},{'Pip',function()adventure:hint()end}}
  local bw=math.floor(math.min(100,(w-185)/5))
  for i,b in ipairs(buttons)do local x=18+(i-1)*(bw+8);local y=h-81
    V.overlay(x,y,bw,59);V.icon(b[1],x+bw/2-14,y+5,1.35)
    V.color({1,.96,.82});g.setFont(fonts.small);g.printf(b[1],x,y+38,bw,'center')
    hudHits[#hudHits+1]={x=x,y=y,w=bw,h=59,action=b[2]}
  end
  local pad={{'NE',0,-1,w-89,h-118},{'NW',-1,0,w-133,h-74},{'SE',1,0,w-45,h-74},{'SW',0,1,w-89,h-37}}
  for _,b in ipairs(pad)do V.overlay(b[4],b[5],38,31);V.buttonText(b[1],b[4],b[5],38,31,fonts.small);hudHits[#hudHits+1]={x=b[4],y=b[5],w=38,h=31,dx=b[2],dy=b[3]}end
  for _,hit in ipairs(hudHits)do hit.x=hit.x*uiScale;hit.y=hit.y*uiScale;hit.w=hit.w*uiScale;hit.h=hit.h*uiScale end
  -- The destination hint appears only while a doorway is hovered.
  local mx,my=love.mouse.getPosition();local hover=Tabletop.pick(mx,my,rooms,roomId,journey)
  if hover and hover.side then
    local target=hover.target;local _,_,door=Campaign.info(target)
    local label=journey.seen[target]and rooms[target].name or(door and door[1]or'Unexplored passage')
    label=label..(journey:locked(target)and ' · Needs a quest item'or(journey.unlocked[Progress.edge(roomId,target)]and ' · Open passage'or' · Match-three to unlock'))
    local tw=math.min(550,w-220);V.overlay((w-tw)/2,h-127,tw,32);V.color({1,.95,.77});g.setFont(fonts.small);g.printf(label,(w-tw)/2+8,h-119,tw-16,'center')
  end
  V.color({1,.97,.87},.85);g.setFont(fonts.small);g.printf('Click a path or doorway · Arrows / WASD · Wheel: zoom · Right-drag: pan',20,h-17,w-185,'left')
  if saveStatus~='' then color(1,.6,.45);g.printf(saveStatus,20,118,w-40,'center')end
  if adventure.toastTime and adventure.toastTime>0 then V.card(w/2-240,127,480,30,false);V.color(V.teal);g.printf(adventure.toast,w/2-230,134,460,'center')end
  g.pop()
end
