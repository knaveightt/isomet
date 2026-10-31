local Campaign=require('campaign')
local Progress=require('progress')
local Match=require('match3')
local V=require('visual')
local PuzzleArt=require('puzzle_art')
local PuzzleFX=require('puzzle_fx')
local A={};A.__index=A
local function sortedKeys(t)local keys={};for k in pairs(t) do keys[#keys+1]=k end;table.sort(keys);return keys end
function A.new(context,p)return setmetatable({ctx=context,p=p,clock=0,choice=1,scroll=0,attempt=0},A)end
function A:save()return self.ctx.save()end
function A:show(title,text,buttons)
 self.hits={}
 self.panel={title=title,text=text,buttons=buttons or {{'Back to exploration',function()self:close()end}}};self.choice=1;self.scroll=0
end
function A:close()self.panel=nil;self.board=nil;self.timing=nil;self.hits={};self.puzzleFX=nil;self.boardResolving=false end
function A:retreat()
 self:close()
 local l,s=Campaign.info(self.p.room)
 if s>=8 and s<=13 then
  local anchors={1,2,3,1,4,5};self.ctx.teleport(Campaign.id(l,anchors[s-7]),true)
 end
 self:save()
end
function A:arrival()
 self.p.room=self.ctx.room();self.p.seen[self.p.room]=true;self:save()
 local l,s,d=Campaign.info(self.p.room)
 if d then self.toast='Room revealed. Press E or Inspect to explore.';self.toastTime=3 elseif s==1 and not self.p.notes['arrival'..l] then
  local origin=Campaign.origins[self.p.profile.origin]
  local text='Pip, a paper moth folded from discarded maps, settles near your lantern.\n\nPip: "Doors remember the way you open them. I can help when you are lost."\n\nWarden: "Welcome. Recover what is familiar. I will help you find a way."\n\n'..origin.anchors[(l-1)%3+1]..' rests where it does not belong. You followed '..origin.companion..' here.'
  self.p:note('arrival'..l,text);self:save();self:show(Campaign.worlds[l].name,text)
 end
end
function A:enter(side,target)
 local _,_,door=Campaign.info(target)
 if self.p.hearts<=0 and door and (door[3]=='hazard' or door[3]=='guardian' or door[3]=='optional')then self:noLives();return end
 local reason=self.p:locked(target)
 if reason then
  self.p.inspected[target]=true;self.p:note('lock'..target,reason);self:save()
  self:show('A marked doorway',reason..'\n\nInspection costs no life. Explore other doors and return with the missing object.');return
 end
 local edge=Progress.edge(self.p.room,target)
 if self.p.unlocked[edge] then self.ctx.move(side);self:arrival();return end
 if self.p.hearts<=0 then self:noLives();return end
 self:startBoard('Unseal the passage',function()
  self.p.unlocked[edge]=true;self.ctx.move(side);self:arrival()
 end, nil, Match.profile(self.p.room,target))
end
function A:startBoard(title,callback,goal,objective)
 self.attempt=self.attempt+1;self.hits={};self.puzzleFX=nil;self.boardResolving=false
 self.panel=nil;self.timing=nil;self.board=Match.new(love.math.random,goal or 5,18,objective);self.boardTitle=title;self.boardDone=callback;self.cursor={x=1,y=1};self.choice=1
end
function A:finishBoard()
 if not self.board or self.boardResolving then return end
 if self.board.won then
  local callback=self.boardDone;self.board=nil
  callback();self:save()
  if not self.panel then self.toast='Passage unlocked — the fog lifts!';self.toastTime=3 end
 elseif self.board.failed then self.board=nil;self:fail('Challenge failed. You lost 1 life.') end
end
function A:fail(message)
 if self.failedAttempt==self.attempt then return end
 self.failedAttempt=self.attempt
 self.board=nil;self.timing=nil
 if not self.p:loseLife() then self:noLives();return end
 self.ctx.teleport(self.p.room);self:save()
 self:show(message,'You dissolve into sparks.\n\nProgress, quest items, clues and opened passages are retained.\nPip recorded: '..Campaign.worlds[Campaign.info(self.p.room)].warning,
 {{'Return to maze',function()self:close();if self.p.hearts<=0 then self:noLives()end end}})
end
function A:noLives()
 self:show('No lives remaining','Your journey is saved. One free heart returns every 20 minutes. You can still read your notebook and satchel.',{
 {'Notebook',function()self:notebook()end},{'Satchel',function()self:satchel()end},{'Wait / return to maze',function()self:close()end}})
end
function A:reward(id)
 local fresh=self.p:complete(id);local l,s,d=Campaign.info(id);self:save()
 local text=d[6]..'\n\n'..(fresh and ('Received: '..(d[4] or 'Passage opened')..'.') or 'This room is already complete. Its unique reward is retained.')
 if d[3]=='story' then text=text..'\n\n'..Campaign.origins[self.p.profile.origin].traces[l]..'\n\n'..Campaign.worlds[l].record end
 local buttons={{'Return to maze',function()self:retreat()end}}
 if s==11 then buttons[#buttons+1]={'Use discovered side exit',function()self:shortcut(Campaign.id(l,5))end};self.p:note('shortcut'..l,'The optional room has a safe side exit to '..Campaign.worlds[l].anchors[5]..'.');self:save() end
 self:show(d[2],text,buttons)
end
function A:shortcut(target)
 local key=Progress.edge(self.p.room,target)
 local function cross()self.p.unlocked[key]=true;self:close();self.ctx.teleport(target,true);self:arrival()end
 if self.p.unlocked[key]then cross()
 elseif self.p.hearts<=0 then self:noLives()
 else self:startBoard('Unseal the side passage',cross,nil,Match.profile(self.p.room,target))end
end
function A:inspect()
 local id=self.p.room;local l,s,d=Campaign.info(id);self.p.inspected[id]=true;self:save()
 if not d then
  local origin=Campaign.origins[self.p.profile.origin]
  self:show(Campaign.worlds[l].anchors[s],origin.anchors[(s+l-2)%3+1]..' has been moved here. Familiar, but assembled incorrectly.\n\nPip: "Look at the marks above each arch. Every door has a story."\n\nE: inspect a room. J: notebook. I: satchel. M: discovered map. P: Pip hint.');return
 end
 if self.p.solved[id] then
  if d[3]=='exit' then self:crossChapter(l);return end
  if d[3]=='finale' then self:finale();return end
  local buttons={{'Return to corridor',function()self:retreat()end}}
  if d[3]=='match' then buttons[#buttons+1]={'Practice board (optional)',function()
   if self.p.hearts<=0 then self:noLives();return end
   self:startBoard('Practice — no duplicate quest reward',function()
    local kind=self.p:practiceReward();self:save();self:show('Practice reward','Received 1 '..kind..'. Overflow is safely held in the claim tray.')
   end)
  end} end
  if s==11 then buttons[#buttons+1]={'Use discovered side exit',function()self:shortcut(Campaign.id(l,5))end} end
  self:show(d[2],'Completed. '..(d[4] or 'The route')..' remains available.\n\n'..d[6],buttons);return
 end
 local missing=self.p:missing(id)
 if #missing>0 then
  self.p:note('need'..id,d[2]..' — Need: '..table.concat(missing,', '));self:save()
  self:show(d[1],d[6]..'\n\nNeed: '..table.concat(missing,', ')..'\n\nYou can safely retreat. No item or life is consumed.');return
 end
 local buttons={{'Continue',function()self:task(id)end},{'Retreat safely',function()self:retreat()end}}
 self:show(d[1],d[6]..'\n\n'..((d[3]=='guardian' or d[3]=='hazard') and ('Warning: '..Campaign.worlds[l].warning..' Mistiming a crossing or strike costs one life.') or 'Quest rewards are granted once and retained.'),buttons)
end
function A:task(id)
 self.attempt=self.attempt+1;self.hits={}
 local l,_,d=Campaign.info(id)
 if d[3]=='match' then self:startBoard(d[2],function()self:reward(id)end)
 elseif d[3]=='guardian' or d[3]=='hazard' then
  if self.p.hearts<=0 then self:noLives();return end
  self.panel=nil;self.timing={id=id,cleared=0,time=0,assist=false};self.choice=1
 elseif d[3]=='optional' then
  if self.p.hearts<=0 then self:noLives();return end
  self:show('The misleading room',d[6]..'\n\nPip: "The safe side exit is there. You may leave without risking anything."',{
   {'Follow the safe side exit',function()self:reward(id)end},
   {'Ignore the warning (fatal risk)',function()self:fail('You died. You lost 1 life.')end},
   {'Refuse / return safely',function()self:retreat()end}})
 elseif d[3]=='picture' then self.pictureStep=0;self:picture(id)
 elseif d[3]=='exit' then self.p:complete(id);self:crossChapter(l)
 elseif d[3]=='finale' then self:finale()
 else self:reward(id) end
end
function A:picture(id)
 local correct={'House','Family','Open door'}
 local buttons={}
 for _,label in ipairs({'Open door','House','Family'}) do local text=label;buttons[#buttons+1]={text,function()
  if text==correct[self.pictureStep+1] then self.pictureStep=self.pictureStep+1 else self.pictureStep=0 end
  if self.pictureStep==3 then self:reward(id) else self:picture(id) end
 end}end
 buttons[#buttons+1]={'Return safely',function()self:retreat()end}
 self:show('The unfinished family picture','The frame reads: "First a HOUSE, then a FAMILY, then an OPEN DOOR."\n\nPlace the three picture fragments in that order.\nCorrect fragments: '..self.pictureStep..' / 3. Wrong placements cost no life.',buttons)
end
function A:strike()
 local task=self.timing;if not task then return end
 local phase=(task.time/(task.assist and 5 or 3.6))%1
 if phase<.48 then
  task.cleared=task.cleared+1;task.time=0
  if task.cleared>=3 then self.timing=nil;self:reward(task.id) end
 else self:fail('You died. You lost 1 life.') end
end
function A:crossChapter(l)
 local text=Campaign.origins[self.p.profile.origin].traces[l]..'\n\nWarden: "'..Campaign.worlds[l].warden..'"\n\nPip: "'..Campaign.worlds[l].pip..'"'
 self.p:note('crossing'..l,text);self:save()
 self:show('Beyond the threshold',text,{{'Follow the passage',function()
  self:close();self.ctx.teleport(Campaign.id(l+1,1));self:arrival()
 end}})
end
function A:finale()
 local id=60
 local missing=self.p:missing(id);if #missing>0 then self:show('The inner latch','Need: '..table.concat(missing,', '));return end
 local actions={'Cool the handle with the Mitts','Redirect the flow with the Wheel','Choose the real shadow','Strike the resonant latch'}
 local step=self.p.finalStep
 if step<4 then
  self:show('The companion’s chamber','Your companion opens the inner latch. The Warden draws the stolen rooms together.\n\nWarden: "It could be right this time. Stay."\n\nPip: "A home needs a way out. Let them choose."\n\nUse what you learned. Escape sequence: '..step..' / 4. Each step is saved.',{
   {actions[step+1],function()self.p.finalStep=step+1;self:save();self:finale()end},
   {'Pause / return to maze',function()self:close()end}})
 else
  self.p.rescued=true;self.p:complete(60);self.p:note('ending',Campaign.origins[self.p.profile.origin].reunion);self:save()
  self:show('Home, with a way out','The Warden releases the final catch. You and '..Campaign.origins[self.p.profile.origin].companion..' return through the original portal. Other captives find their own exits.\n\n'..Campaign.origins[self.p.profile.origin].reunion..'\n\nLater, the portal briefly shows a different place asking for help. Your rescue is complete.',{
   {'Read the notebook',function()self:notebook()end},{'Keep exploring the refuge',function()self:close()end}})
 end
end
function A:notebook()
 local lines={'Pip’s notebook — evidence remains after failure.'}
 for _,key in ipairs(sortedKeys(self.p.notes)) do lines[#lines+1]=self.p.notes[key] end
 self:show('Notebook',table.concat(lines,'\n\n'))
end
function A:satchel(tab)
 tab=tab or 'Quest'
 local lines={};local buttons={}
 if tab=='Quest' then
  lines={'Unlimited quest storage. Nothing here can be sold, discarded, or lost on death.'}
  for _,name in ipairs(sortedKeys(self.p:items()))do
   local status='Owned: 1 · retained'
   if name=='Dozing Stone' and self.p.solved[54]then status='Installed at the bridge plate'end
   if name=='Knotwake Rope' and self.p.solved[55]then status='Anchored at the rootshaft'end
   lines[#lines+1]=name..' — '..status
   for id in pairs(self.p.inspected)do local _,_,d=Campaign.info(id)
    if d then for _,need in ipairs(d[5])do if need==name then lines[#lines+1]='Known use: '..d[2]end end end
   end
  end
 elseif tab=='Supplies' then
  lines={'Power Cells: '..self.p.cells,'Stored bright light: '..math.ceil(self.p.bright)..' seconds. A cell supplies 5 minutes. Light is optional; a dim return path is always visible.','Timers pause during puzzles, reading, menus and cutscenes. Free recharge: 1 cell every 20 minutes.'}
  buttons[#buttons+1]={'Use / toggle lantern',function()self:lamp();self:satchel('Supplies')end}
  buttons[#buttons+1]={'Claim free recharge',function()
   local ok=self.p:freeCell();self:save()
   self:show(ok and 'Power Cell received' or 'Recharge not ready',ok and 'One free cell added to Supplies.' or ('Next cell in '..math.ceil(math.max(0,self.p.freeCellAt-os.time())/60)..' minutes.'))
  end}
 elseif tab=='Materials' then
  local m=self.p.materials;local o=self.p.overflow
  lines={'Storage '..(m.shards+m.scrap+m.thread)..' / '..self.p.capacity,
   'Glow Shards: '..m.shards..' · Copper Scrap: '..m.scrap..' · Thread: '..m.thread,
   'Claim tray: '..o.shards..' shards, '..o.scrap..' scrap, '..o.thread..' thread. Overflow is never destroyed. Recipes can use the claim tray.',
   'Power Cell recipe: 2 Glow Shards + 1 Copper Scrap.',
   'Expand storage +10: 3 Copper Scrap + 2 Thread.',
   'Practice boards alternate a shard and scrap. Each optional room gives one Thread on its first completion. Crafting is never a story gate.'}
  buttons[#buttons+1]={'Craft a Power Cell',function()local ok=self.p:craftCell();self:save();self:show(ok and 'Cell crafted' or 'Missing materials',ok and 'One cell added to Supplies.' or 'Need 2 Glow Shards and 1 Copper Scrap. Play optional practice boards.')end}
  buttons[#buttons+1]={'Expand storage +10',function()local ok=self.p:expand();self:save();self:show(ok and 'Satchel expanded' or 'Missing materials',ok and 'Capacity increased by 10. The claim tray has been checked.' or 'Need 3 Copper Scrap and 2 Thread. No purchase is needed.')end}
  buttons[#buttons+1]={'Claim overflow',function()self.p:claimMaterials();self:save();self:satchel('Materials')end}
 elseif tab=='Memories' then
  lines={'Companion traces and evidence remain in the notebook.'}
  for _,key in ipairs(sortedKeys(self.p.notes))do if key:match('trace') or key:match('evidence') or key=='ending'then lines[#lines+1]=self.p.notes[key]end end
 elseif tab=='Wardrobe' then lines={'Selected traveler: '..self.p.profile.name,'All eight starting looks are free. Additional outfits, lantern shells and pet appearances remain future art work. No shop or payments are enabled.'}end
 buttons[#buttons+1]={'Switch satchel tab',function()
  local choices={};for _,label in ipairs({'Quest','Supplies','Materials','Memories','Wardrobe'})do local t=label;choices[#choices+1]={label,function()self:satchel(t)end}end
  choices[#choices+1]={'Return to maze',function()self:close()end};self:show('The satchel','Choose a compartment.',choices)
 end}
 buttons[#buttons+1]={'Return to maze',function()self:close()end}
 self:show('Satchel / '..tab,table.concat(lines,'\n\n'),buttons)
end
function A:lamp()
 if self.p.bright>0 then self.p.lightOn=not self.p.lightOn
 elseif self.p.cells>0 then self.p.cells=self.p.cells-1;self.p.bright=300;self.p.lightOn=true
 else self:show('A dim return-path glow','No cells. Claim a free recharge or craft a cell in the satchel. Required routes remain visible.')end
 self:save()
end
function A:travel(dt)
 if self.p.lightOn then self.p.bright=math.max(0,self.p.bright-dt);if self.p.bright==0 then self.p.lightOn=false end end
end
function A:map()
 local lines={};local l=Campaign.info(self.p.room)
 for _,id in ipairs(sortedKeys(self.p.seen)) do local rl,s,d=Campaign.info(id)
  if rl==l then local r=self.ctx.rooms[id];local exits={}
   for side,target in pairs(r.visualExits or r.exits) do local _,_,dest=Campaign.info(target);exits[#exits+1]=side..': '..(self.p.seen[target] and self.ctx.rooms[target].name or (self.p.inspected[target] and (dest and dest[1] or 'Inspected passage') or 'Unexplored')) end
   table.sort(exits);lines[#lines+1]=(id==self.p.room and '> ' or '')..r.name..'\n'..table.concat(exits,' · ')
  end
 end
 self:show('Discovered map',table.concat(lines,'\n\n'))
end
function A:hint()
 local l=Campaign.info(self.p.room)
 for _,n in ipairs({1,2,3,5,6,7,8}) do local id=Campaign.id(l,7+n)
  if not self.p.solved[id] then local d=Campaign.doors[l][n]
   local text='Pip: "Look for '..d[1]..'."\n\n'..d[6]
   if n==6 then text=text..'\n\nInspect the complete companion trace after the previous mechanism.' end
   self:show('Pip’s hint',text);return
  end
 end
 self:show('Pip’s hint','The next passage is ready. Return to the exit landing.')
end
function A:update(dt)
 self.clock=self.clock+dt
 if self.puzzleFX and not self.panel then
  if self.puzzleFX:update(dt)then
   self.puzzleFX=nil;self.boardResolving=false;self:finishBoard()
  end
 end
 self.toastTime=math.max(0,(self.toastTime or 0)-dt)
 if self.p:regenerate() then self:save() end
 if self.timing then self.timing.time=self.timing.time+dt end
 if self.panel and self.panel.title=='No lives remaining'then
  local wait=self.p:wait()
  self.panel.text=self.p.hearts>0 and 'A free heart is ready. Return to the maze when you are ready.' or ('Your journey is saved. Next free heart in '..string.format('%02d:%02d',math.floor(wait/60),wait%60)..'.\n\nYou can still read the notebook and satchel. One free heart returns every 20 minutes, including time away.')
 end
end
function A:active()return self.panel or self.board or self.timing end
function A:boardHelp()
 self:show('Pip’s puzzle guide',
  'Complete the goal above the board before your swaps run out. Each doorway asks for matches, a particular gem color, or clay seals.\n\nLantern Spark: match four in a line. Match it again to clear its entire row or column, shown by its stripe.\n\nVoid Bloom: make an intersecting T or L match. Match the Bloom to clear a 3 × 3 area.\n\nMemory Star: match five in a line. Swap the Star with any neighboring gem to clear that color.\n\nSwap two special pieces together to activate both. Effects can trigger other special pieces.\n\nClay stays on its tile while gems fall. A match on or beside it breaks the seal; special blasts break seals too.\n\nEvery neighboring swap uses one move, even if it makes no match. A board with no legal moves reshuffles free. Retreat costs no life; running out of swaps costs one heart.',
  {{'Return to puzzle',function()self.panel=nil end}})
end
function A:boardSelect(x,y)
 local b=self.board;if not b or self.boardResolving then return end
 if b.selected then local previous=b.selected;b.selected=nil
  if math.abs(previous.x-x)+math.abs(previous.y-y)==1 then
   if b:swap(previous.x,previous.y,x,y)then
    self.puzzleFX=PuzzleFX.new(b.events);self.boardResolving=true
   else self:finishBoard()end
  else b.selected={x=x,y=y} end
 else b.selected={x=x,y=y} end
end
function A:keypressed(key)
 if self.board then
  if self.panel then if key=='escape'then self.panel=nil else self:panelKey(key)end;return end
  if key=='h'then self:boardHelp();return end
  if key=='escape' then self:show('Retreat safely?','Leaving costs no life. This unfinished board will reset.',{{'Return to board',function()self.panel=nil end},{'Return to maze',function()self:retreat()end}});return end
  local c=self.cursor
  if key=='left' then c.x=math.max(1,c.x-1) elseif key=='right' then c.x=math.min(7,c.x+1)
  elseif key=='up' then c.y=math.max(1,c.y-1) elseif key=='down' then c.y=math.min(7,c.y+1)
  elseif key=='space' or key=='return' then self:boardSelect(c.x,c.y) end
 elseif self.timing then
  if key=='escape' then self:retreat() elseif key=='p' then self.timing.assist=not self.timing.assist;self.timing.time=0
  elseif key=='space' or key=='return' then self:strike() end
 elseif self.panel then self:panelKey(key) end
end
function A:panelKey(key)
 if key=='escape' then self:close()
 elseif key=='up' then self.choice=(self.choice-2)%#self.panel.buttons+1
 elseif key=='down' then self.choice=self.choice%#self.panel.buttons+1
 elseif key=='pageup' then self.scroll=math.max(0,self.scroll-150)
 elseif key=='pagedown' then self.scroll=self.scroll+150
 elseif key=='return' or key=='space' then self.panel.buttons[self.choice][2]() end
end
function A:wheelmoved(_,y)if self.panel then self.scroll=math.max(0,self.scroll-y*45) end end
function A:draw(fonts)
 local g=love.graphics;local w,h=g.getDimensions();self.hits={}
 V.background(w,h,self.clock)
 V.card(16,16,w-32,h-32,false)
 if self.panel then
  local left=math.max(24,(w-850)/2);local width=w-left*2
  V.heading(self.panel.title,left,31,width,fonts.title)
  local buttonHeight=44;local bottom=h-30;local buttonsY=bottom-#self.panel.buttons*(buttonHeight+8)
  local textTop=90;local textHeight=math.max(60,buttonsY-textTop-24)
  V.color({.99,.97,.88});g.rectangle('fill',left-8,textTop-6,width+16,textHeight+12,10,10)
  g.setFont(fonts.body);local _,lines=fonts.body:getWrap(self.panel.text,width-12);local maxScroll=math.max(0,#lines*fonts.body:getHeight()*1.2-textHeight)
  self.scroll=math.min(self.scroll,maxScroll)
  g.setScissor(left,textTop,width,textHeight);V.color(V.ink);g.printf(self.panel.text,left,textTop-self.scroll,width-12,'left');g.setScissor()
  if maxScroll>0 then g.setFont(fonts.small);V.color(V.muted);g.printf('Scroll / Page Up & Down to read more',left,buttonsY-20,width,'right') end
  for i,button in ipairs(self.panel.buttons) do
   local y=buttonsY+(i-1)*(buttonHeight+8);V.button(left,y,width,buttonHeight,i==self.choice)
   V.buttonText(button[1],left,y,width,buttonHeight,fonts.body)
   self.hits[#self.hits+1]={x=left,y=y,w=width,h=buttonHeight,action=button[2]}
  end
 elseif self.board then
  local b=self.board;local size=math.floor(math.min(62,(h-250)/7,(w-80)/7));local left=math.floor((w-size*7)/2);local top=130
  self.boardLayout={left=left,top=top,size=size}
  V.card(left-8,top-8,size*7+16,size*7+16,false)
  V.heading(self.boardTitle,20,16,w-40,fonts.title)
  g.setFont(fonts.body);V.color(V.ink);g.printf(b:objectiveText()..'     Swaps '..b.moves..'     Hearts '..self.p.hearts..' / 5',0,68,w,'center')
  V.progress(left,103,size*7,12,b:progress()/b.goal)
  for y=1,7 do for x=1,7 do local xx,yy=left+(x-1)*size,top+(y-1)*size
   V.color({.60,.72,.63});g.rectangle('fill',xx+2,yy+3,size-4,size-4,8,8)
   V.color((x+y)%2==0 and {.91,.96,.85}or{.80,.90,.79});g.rectangle('fill',xx+2,yy+1,size-4,size-5,8,8)
   V.color({1,1,.93},.6);g.rectangle('fill',xx+8,yy+3,size-16,2,1,1)
   local index=(y-1)*7+x
   if b.clay[index]then
    PuzzleArt.seal(xx,yy,size)
    PuzzleArt.piece(xx+size*.1,yy+size*.1,size*.8,b.board[index],b.specials[index])
   else PuzzleArt.piece(xx,yy,size,b.board[index],b.specials[index])end
   if (b.selected and b.selected.x==x and b.selected.y==y) or (self.cursor.x==x and self.cursor.y==y) then
    g.setColor(.98,.55,.15);g.setLineWidth(2);g.rectangle('line',xx+2,yy+2,size-4,size-4,4,4);g.setLineWidth(1)
   end
  end end
  if self.puzzleFX then self.puzzleFX:draw(left,top,size)end
  g.setFont(fonts.body);V.color(V.ink);g.printf(b.message,24,top+size*7+17,w-48,'center')
  g.setFont(fonts.small);V.color(V.muted);g.printf('Match a special to fire it. Swap a Star with any gem, or combine two specials. Esc: retreat.',20,h-80,w-40,'center')
  V.color(V.muted);g.printf('4: line Spark · T/L: blast Bloom · 5: color Star · Match beside clay to break it',20,h-58,w-40,'center')
  self.hits[1]={x=w/2-110,y=h-36,w=220,h=28,action=function()self:retreat()end};V.button(w/2-110,h-36,220,28,false);V.buttonText('Return safely to maze',w/2-110,h-36,220,28,fonts.small)
  V.button(32,h-36,140,28,false);V.buttonText('How to play · H',32,h-36,140,28,fonts.small);self.hits[2]={x=32,y=h-36,w=140,h=28,action=function()self:boardHelp()end}
 elseif self.timing then
  local task=self.timing;local l,_,d=Campaign.info(task.id);local phase=(task.time/(task.assist and 5 or 3.6))%1;local safe=phase<.48
  V.heading(d[2],20,50,w-40,fonts.title)
  g.setFont(fonts.body);V.color(V.ink);g.printf(Campaign.worlds[l].warning..'\n\n'..(d[3]=='guardian' and 'Seals cooled: ' or 'Safe crossings: ')..task.cleared..' / 3',70,130,w-140,'center')
  g.setFont(fonts.small);V.color(V.muted);g.printf('Space / Enter: cross or strike · P: slower assist · Esc: retreat',30,220,w-60,'center')
  local left,width=80,w-160;V.card(left-6,h/2-6,width+12,42,false);g.setColor(.26,.65,.78);g.rectangle('fill',left,h/2,width*.48,30);g.setColor(.76,.29,.27);g.rectangle('fill',left+width*.48,h/2,width*.52,30)
  V.color({.35,.29,.18});g.rectangle('fill',left+width*phase-5,h/2-7,10,44,4,4);V.color({1,.96,.69});g.rectangle('fill',left+width*phase-3,h/2-9,6,44,3,3)
  g.setFont(fonts.title);g.setColor(safe and .15 or .71,safe and .49 or .26,safe and .53 or .20);g.printf(safe and 'SAFE — cross / strike now' or (phase<.65 and 'WARNING — stay in shelter' or 'DANGER — stay in shelter'),0,h/2+65,w,'center')
  local buttons={{'Cross / strike',function()self:strike()end},{task.assist and 'Pip assist: ON' or 'Pip assist: slower warnings',function()task.assist=not task.assist;task.time=0 end},{'Retreat safely',function()self:retreat()end}}
  for i,b in ipairs(buttons)do local yy=h-155+(i-1)*46;V.button(w/2-230,yy,460,38,i==1);V.buttonText(b[1],w/2-230,yy,460,38,fonts.body);self.hits[i]={x=w/2-230,y=yy,w=460,h=38,action=b[2]}end
 end
end
function A:mousepressed(x,y,button)
 if button~=1 then return end
 for _,hit in ipairs(self.hits or {}) do if x>=hit.x and y>=hit.y and x<=hit.x+hit.w and y<=hit.y+hit.h then hit.action();return end end
 if self.board and not self.panel and self.boardLayout then local l=self.boardLayout;local xx,yy=math.floor((x-l.left)/l.size)+1,math.floor((y-l.top)/l.size)+1
  if xx>=1 and xx<=7 and yy>=1 and yy<=7 then self.cursor={x=xx,y=yy};self:boardSelect(xx,yy) end
 end
end
return A
