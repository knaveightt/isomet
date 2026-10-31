-- Appended to a temporary copy of main.lua by run_love_tests.py.
-- This exercises the real callbacks while keeping production saves isolated.
local originalLoad=love.load
function love.errorhandler(message)io.stderr:write(tostring(message)..'\n'..debug.traceback()..'\n');os.exit(1)end
local function capture(name)
 local g=love.graphics;local w,h=g.getDimensions();local canvas=g.newCanvas(w,h)
 local old=g.getCanvas();g.setCanvas(canvas);love.draw();g.setCanvas(old)
 canvas:newImageData():encode('png',name..'.png')
end
local function solveBoard()
 local attempts=0
 while adventure.board do
  local b=adventure.board;local found=false
  for y=1,7 do if found then break end;for x=1,7 do if found then break end;for _,d in ipairs({{1,0},{0,1}})do
   local xx,yy=x+d[1],y+d[2]
   if xx<=7 and yy<=7 then
    local a,bb=(y-1)*7+x,(yy-1)*7+xx;b.board[a],b.board[bb]=b.board[bb],b.board[a]
    local _,n=require('match3').matches(b.board);b.board[a],b.board[bb]=b.board[bb],b.board[a]
    if n>0 then b:swap(x,y,xx,yy);found=true;break end
   end
  end end end
  assert(found);attempts=attempts+1;assert(attempts<=18)
  adventure:finishBoard()
  if adventure.panel and adventure.panel.title=='The pattern holds' then adventure.panel.buttons[1][2]() end
 end
end
function love.load()
 originalLoad()
 splashTime=1.5;capture('test-splash')
 for i=1,61 do love.update(.05)end
 assert(ready and not errorText and #rooms==60 and Characters.active)
 capture('test-character-selection')
 love.textinput('Mira');love.keypressed('down');love.keypressed('return')
 assert(Intro.active and Characters.selected==5)
 capture('test-location-selection')
 Intro.selected=2;Intro.choose();Intro.time=12.49;love.update(.02)
 assert(campaignStarted and journey.profile.origin=='Suburb' and roomId==1)
 adventure:close();fade=0;capture('test-maze')
 -- A passage remains closed until the real match-three rules report success.
 local side;for s,id in pairs(rooms[1].visualExits)do if id==8 then side=s end end;assert(side)
 adventure:enter(side,8);assert(roomId==1 and adventure.board)
 capture('test-match3');solveBoard();assert(roomId==8 and journey.unlocked['1-8'])
 adventure:close();adventure:task(8);assert(journey:items()["Potter's Mitts"])
 adventure:close();changeRoom(World.opposite[side]);assert(roomId==1)
 adventure:enter(side,8);assert(roomId==8 and not adventure.board,'Backtracking replayed board')
 adventure:close()
 -- Explore a corridor chain through real passage boards, then capture the connected view.
 teleport(1)
 for _,target in ipairs({2,3,4,5})do
  local side;for s,id in pairs(rooms[roomId].visualExits)do if id==target then side=s end end;assert(side)
  adventure:enter(side,target);if adventure.board then solveBoard()end;adventure:close()
  for tick=1,30 do love.update(.05)end
  assert(journey.seen[target]and not Tabletop.walk)
 end
 Tabletop.zoom=.55;capture('test-tabletop-revealed');Tabletop.zoom=.68
 -- Walk the complete authored dependency chain and exercise every task type.
 for l=1,4 do
  teleport(Campaign.id(l,1));adventure:close();capture('test-biome-'..l)
  for _,n in ipairs({1,2,3,4,5,6,7,8})do
   local id=Campaign.id(l,7+n);teleport(id);adventure:close()
   if not journey.solved[id]then
    assert(#journey:missing(id)==0)
    local d=rooms[id].door;adventure:task(id)
    if d[3]=='match' then solveBoard()
    elseif d[3]=='hazard' or d[3]=='guardian' then
     assert(adventure.timing);if n==7 and l==1 then capture('test-guardian')end
     for hit=1,3 do adventure.timing.time=0;adventure:strike()end
    elseif d[3]=='optional' then adventure.panel.buttons[1][2]()
    elseif d[3]=='picture' then
     for _,label in ipairs({'House','Family','Open door'})do
      local action;for _,b in ipairs(adventure.panel.buttons)do if b[1]==label then action=b[2]end end;assert(action);action()
     end
    elseif d[3]=='exit' then
     assert(adventure.panel.title=='Beyond the threshold');adventure.panel.buttons[1][2]();assert(roomId==Campaign.id(l+1,1))
    elseif d[3]=='finale' then
     for step=1,4 do adventure.panel.buttons[1][2]()end
     assert(journey.rescued and journey.finalStep==4);capture('test-ending')
    end
    if n~=8 then assert(journey.solved[id],'Task did not grant reward '..id)end
   end
   adventure:close()
  end
 end
 adventure:notebook();capture('test-notebook');adventure:satchel();capture('test-satchel');adventure:satchel('Materials');capture('test-materials');adventure:close()
 -- Failure: exactly one heart, current-world entrance, persistent progress.
 teleport(55);local count=0;for _ in pairs(journey.solved)do count=count+1 end
 adventure:task(59);adventure.timing.time=2.8;adventure:strike()
 assert(journey.hearts==4 and roomId==46 and not adventure.timing)
 adventure:fail('Duplicate event');assert(journey.hearts==4,'A failure deducted twice')
 local after=0;for _ in pairs(journey.solved)do after=after+1 end;assert(after==count)
 adventure:close();assert(saveJourney())
 local persisted=Progress.decode(assert(love.filesystem.read('miswander-journey.txt')))
 assert(persisted.rescued and persisted.room==46 and persisted.hearts==4)
 start(false);assert(adventure.panel.title=='Welcome back to Miswander');adventure.panel.buttons[1][2]()
 assert(campaignStarted and journey.rescued and Characters.name=='Mira' and roomId==46)
 love.window.setMode(800,600);adventure:close();capture('test-small-maze')
 adventure:startBoard('Unseal the passage',function()end);capture('test-small-match3')
 adventure:close();adventure:task(59);capture('test-small-guardian');adventure:close()
 -- Inspect the densest menus and setup screens at the minimum window size.
 adventure:satchel('Materials');capture('test-small-materials')
 adventure.panel.buttons[#adventure.panel.buttons-1][2]();capture('test-small-satchel-tabs')
 assert(#adventure.hits==6)
 for _,hit in ipairs(adventure.hits)do assert(hit.y>=0 and hit.y+hit.h<=600)end
 adventure:close();Characters.active=true;capture('test-small-characters');Characters.active=false
 Intro.begin(Characters);capture('test-small-locations');Intro.active=false
 -- Check all origin-specific cinematic rendering and separate campaigns.
 for _,origin in ipairs({'City','Suburb','Midwest'})do
  Intro.begin(Characters);Intro.selected=({City=1,Suburb=2,Midwest=3})[origin];Intro.choose();Intro.time=2
  capture('test-intro-'..origin);Intro.active=false
 end
 print('LOVE INTEGRATION PASS: deferred splash, creation, introduction, first-time passage, all 32 tasks, complete rescue, failure retention, resume and 800x600 rendering.')
 print('Screenshots: '..love.filesystem.getSaveDirectory())
 campaignStarted=false;love.event.quit()
end
