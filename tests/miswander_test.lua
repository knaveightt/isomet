local C=require('campaign');local P=require('progress');local M=require('match3');local W=require('world')
local function nextSwap(board)
 for y=1,7 do for x=1,7 do for _,d in ipairs({{1,0},{0,1}})do
  local xx,yy=x+d[1],y+d[2]
  if xx<=7 and yy<=7 then
   local a,b=(y-1)*7+x,(yy-1)*7+xx;board[a],board[b]=board[b],board[a]
   local _,n=M.matches(board);board[a],board[b]=board[b],board[a]
   if n>0 then return x,y,xx,yy end
  end
 end end end
end
for seed=1,200 do
 math.randomseed(seed)
 local rooms=C.generate(math.random);assert(C.validate(rooms))
 local loaded={};for id,r in ipairs(rooms)do loaded[id]=W.decode(W.encode(r),id)end;C.attach(loaded);C.validate(loaded)
 local p=P.new(1000)
 for l=1,4 do
  -- Early inspection is recoverable; story clues do not unlock prematurely.
  assert(#p:missing(C.id(l,13))>0)
  assert(p:locked(C.id(l,15)))
  for _,n in ipairs({1,2,3,5,6,7,8})do
   local id=C.id(l,7+n);assert(#p:missing(id)==0,'Circular dependency at '..id)
   assert(not p:locked(id),'Required route locked at '..id)
   assert(p:complete(id));assert(not p:complete(id),'Unique reward duplicated')
  end
 end
 assert(p:items()['Orchard Key'] and p:items()['Homeward Sequence'])
 p.profile.name='Zoë: = %';p.profile.origin=({'City','Suburb','Midwest'})[seed%3+1]
 p.unlocked['1-2']=true;p.x=3.5;p.y=4.5;p:note('quote','Text: 100%\nSecond line')
 local encoded=p:encode();local decoded=P.decode(encoded);assert(decoded:encode()==encoded,'Save roundtrip failed')
 local oldItems=p:items();p.room=47;p.hearts=5;assert(p:loseLife(1000));assert(p.hearts==4 and p.room==46)
 for item in pairs(oldItems)do assert(p:items()[item],'Death lost a quest item')end
 assert(not p:regenerate(2199));assert(p:regenerate(2200) and p.hearts==5)
 local board=M.new(math.random,5,18);local _,n=M.matches(board.board);assert(n==0 and M.hasMove(board.board))
 assert(not board:swap(1,1,7,7) and board.moves==18)
 local safety=0
 while not board.won and not board.failed do
  local x,y,xx,yy=nextSwap(board.board);assert(x,'Dead board not reshuffled')
  local moves=board.moves;assert(board:swap(x,y,xx,yy) and board.moves==moves-1)
  safety=safety+1;assert(safety<=18)
 end
 assert(board.won,'Basic goal should be achievable with valid moves')
end
-- One failed board consumes its final valid move and cannot be played again.
local board=M.new(math.random,100000,1);local a,b,c,d=nextSwap(board.board);board:swap(a,b,c,d)
assert(board.failed and not board:swap(a,b,c,d))
local p=P.new(1000);for i=1,5 do assert(p:loseLife(1000))end
assert(p.hearts==0 and not p:loseLife(1000));assert(not p:regenerate(2199));assert(p:regenerate(2200) and p.hearts==1)
-- Orchard finale needs both independent branches.
p=P.new();for _,n in ipairs({1,2,3,5,7})do p:complete(C.id(4,7+n))end
assert(p:locked(60));p:complete(C.id(4,13));assert(not p:locked(60))
p=P.new();for _,n in ipairs({1,2,3,5,6})do p:complete(C.id(4,7+n))end
assert(p:locked(60));p:complete(C.id(4,14));assert(not p:locked(60))
print('MISWANDER: 200 campaign layouts / dependency routes / save roundtrips / match-three boards passed; lives, optional rewards and finale gates verified.')
-- Optional economy never blocks or destroys unique quest rewards.
p=P.new(1000);p:addMaterial('shards',30);p:addMaterial('scrap',4)
assert(p.materials.shards==30 and p.overflow.scrap==4)
p:complete(8);assert(p:items()["Potter's Mitts"])
p.materials.shards=2;p:claimMaterials();assert(p.materials.scrap==4 and p.overflow.scrap==0)
assert(p:craftCell() and p.cells==2 and p.materials.shards==0 and p.materials.scrap==3)
p:addMaterial('thread',2);assert(p:expand() and p.capacity==40)
assert(p:freeCell(1000) and not p:freeCell(2199) and p:freeCell(2200))
local count=p.materials.thread;p:complete(11);p:complete(11);assert(p.materials.thread==count+1)
assert(P.decode(p:encode()):encode()==p:encode())
print('Crafting, storage overflow, free recharge and unique optional material rewards passed.')
-- A no-match neighboring swap uses an attempt, reverts pieces, and can fail once.
board=M.new(math.random,5,1)
local tested=false
for y=1,7 do if tested then break end;for x=1,6 do
 local a,b=(y-1)*7+x,(y-1)*7+x+1;local va,vb=board.board[a],board.board[b]
 board.board[a],board.board[b]=vb,va;local _,n=M.matches(board.board);board.board[a],board.board[b]=va,vb
 if n==0 then assert(not board:swap(x,y,x+1,y));assert(board.moves==0 and board.failed and board.board[a]==va and board.board[b]==vb);tested=true;break end
end end
assert(tested)
print('Scored no-match attempts revert correctly and exhaust the board allowance.')
p=P.new();p:addMaterial('shards',30);p:addMaterial('scrap',1)
assert(p.materials.scrap==0 and p.overflow.scrap==1)
assert(p:craftCell() and p.materials.shards==28 and p.overflow.scrap==0,'Full material storage blocked a valid recipe')
print('Recipes can use the overflow tray without a storage deadlock.')
