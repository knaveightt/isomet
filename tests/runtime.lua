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
 local attempts=0;local limit=adventure.board.moves
 while adventure.board do
  local b=adventure.board;local best,bestScore
  -- Choose legal moves for the actual objective, including special activations.
  -- A private repeatable RNG makes previews independent of the real refill RNG.
  for y=1,7 do for x=1,7 do for _,d in ipairs({{1,0},{0,1}})do
   local xx,yy=x+d[1],y+d[2]
   if xx<=7 and yy<=7 then
    local seed=12345;local copy={}
    for k,v in pairs(b)do if type(v)=='table'then copy[k]={};for i,z in pairs(v)do copy[k][i]=z end else copy[k]=v end end
    copy.random=function(lo,hi)seed=(seed*16807)%2147483647;return lo+seed%(hi-lo+1)end
    setmetatable(copy,getmetatable(b))
    if copy:swap(x,y,xx,yy)then
     local score=(copy:progress()-b:progress())*100+(copy.count-b.count)
     if copy.won then score=score+10000 end
     for _ in pairs(copy.specials)do score=score+2 end
     if not bestScore or score>bestScore then bestScore=score;best={x,y,xx,yy}end
    end
   end
  end end end
  assert(best,'No legal move after reshuffle');assert(b:swap(unpack(best)))
  attempts=attempts+1;assert(attempts<=limit)
  assert(not b.failed,'Objective solver exhausted its move budget: '..b:objectiveText())
  adventure:finishBoard()
  if adventure.panel and adventure.panel.title=='The pattern holds' then adventure.panel.buttons[1][2]() end
 end
end
function love.load()
 originalLoad()
 love.math.setRandomSeed(913)
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
 -- Exercise every new objective and the help overlay with real callbacks.
 for _,objective in ipairs({{kind='clay',goal=6,moves=24},{kind='collect',color=2,goal=15,moves=22}})do
  adventure:startBoard('Pip’s passage challenge',function()end,nil,objective)
  local board=adventure.board
  if objective.kind=='clay'then
   board.specials[2]='row';board.specials[4]='bloom';board.specials[6]='star'
   capture('test-clay-specials')
   love.keypressed('h');assert(adventure.panel and adventure.board==board);capture('test-puzzle-guide')
   love.keypressed('escape');assert(not adventure.panel and adventure.board==board and board.moves==24)
  else capture('test-collect-objective')end
  solveBoard()
 end
 -- Real selection callbacks must show effects before advancing a winning board.
 local completed=0
 adventure:startBoard('A little lantern magic',function()completed=completed+1 end,1)
 local animated=adventure.board
 for y=1,7 do for x=1,7 do animated.board[(y-1)*7+x]=(x+y*2)%6+1 end end
 animated.board[23]=1;animated.board[24]=1;animated.board[25]=2;animated.board[26]=1;animated.board[18]=1
 adventure:boardSelect(4,3);adventure:boardSelect(4,4)
 assert(animated.won and adventure.boardResolving and completed==0)
 local moves=animated.moves;adventure:boardSelect(1,1);adventure:boardSelect(2,1);assert(animated.moves==moves)
 adventure:update(.12);capture('test-puzzle-match-burst')
 adventure:boardHelp();local fxTime=adventure.puzzleFX.time;adventure:update(.25);assert(adventure.puzzleFX.time==fxTime)
 love.keypressed('escape');adventure:update(2);assert(completed==1 and not adventure.board)
 adventure:update(2);assert(completed==1,'Winning effect repeated its reward')
 adventure:startBoard('Lanterns in the void',function()end,1000)
 animated=adventure.board
 for y=1,7 do for x=1,7 do animated.board[(y-1)*7+x]=(x+y*2)%6+1 end end
 animated.specials[17]='row';animated.specials[18]='bloom';animated.specials[20]='star'
 adventure:boardSelect(3,3);adventure:boardSelect(4,3);adventure:update(.10);capture('test-puzzle-special-burst')
 assert(#adventure.puzzleFX.beams>0 and #adventure.puzzleFX.rings>0)
 adventure:close();assert(not adventure.puzzleFX and not adventure.boardResolving)
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
