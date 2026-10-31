local M=require('match3')
math.randomseed(913)
local function k(x,y)return(y-1)*7+x end
local function fixture(o)
 local b=M.new(math.random,10000,40,o)
 for y=1,7 do for x=1,7 do b.board[k(x,y)]=(x+y*2)%6+1 end end
 return b
end
local function four(b)
 b.board[k(2,4)]=1;b.board[k(3,4)]=1;b.board[k(4,4)]=2;b.board[k(5,4)]=1;b.board[k(4,3)]=1
end
local b=fixture();four(b);assert(b:swap(4,3,4,4));assert(b.specials[k(4,4)]=='row','Four should leave a row Spark at the swapped tile')
b=fixture();four(b);local rotated={};for y=1,7 do for x=1,7 do rotated[k(x,y)]=b.board[k(y,x)]end end;b.board=rotated
assert(b:swap(3,4,4,4));local column=false;for _,s in pairs(b.specials)do if s=='column'then column=true end end;assert(column,'Vertical four should make a column Spark that falls with gravity')
b=fixture();four(b);b.board[k(1,4)]=1;assert(b:swap(4,3,4,4));assert(b.specials[k(4,4)]=='star','Five should make a Star')
b=fixture();four(b);b.board[k(5,4)]=3;b.board[k(3,3)]=1;b.board[k(3,5)]=1
assert(b:swap(4,3,4,4));local bloom=false;for _,s in pairs(b.specials)do if s=='bloom'then bloom=true end end;assert(bloom,'Intersecting lines should make a Bloom')
-- Star + color is legal even without a normal match, and collection uses removed gems.
b=fixture({kind='collect',goal=3,color=2});b.specials[k(3,3)]='star';b.board[k(4,3)]=2
assert(b:swap(3,3,4,3)and b.collected>=3 and b.won)
-- Fixed seals break from adjacent matches, not from an unrelated match count.
b=fixture({kind='clay',goal=6});four(b);b.clay={[k(2,5)]=true,[k(7,1)]=true};b.goal=2
assert(b:swap(4,3,4,4));assert(not b.clay[k(2,5)]and b.broken>=1);assert(not b.won or b.broken>=2)
-- A combination starts both specials and chains into a third.
b=fixture();b.specials[k(3,3)]='row';b.specials[k(4,3)]='column';b.specials[k(6,3)]='bloom'
assert(b:swap(3,3,4,3));assert(tonumber(b.message:match('(%d+) fired'))>=3)
-- Rejected swaps restore both the gem and its special without touching clay.
b=fixture();b.specials[1]='row';local va,vb=b.board[1],b.board[2]
assert(not b:swap(1,1,2,1));assert(b.specials[1]=='row'and not b.specials[2]and b.board[1]==va and b.board[2]==vb)
b.clay[17]=true;b:reshuffle();assert(b.specials[1]=='row'and b.clay[17]and M.hasMove(b.board,b.specials))
assert(M.profile(1,2).kind==M.profile(2,1).kind)
local kinds={};for i=2,15 do kinds[M.profile(1,i).kind]=true end
assert(kinds.matches and kinds.collect and kinds.clay)
print('MATCH3: special creation, activation, chaining, collection, adjacent clay, rejected swaps and free reshuffles passed.')

-- The match counter alone cannot satisfy collection or seal objectives.
for _,kind in ipairs({'collect','clay'})do
 b=fixture({kind=kind,goal=kind=='clay'and 6 or 1000,color=2,moves=1});b.count=10000
 if kind=='clay'then b.clay={[1]=true};b.goal=2 end
 four(b);assert(b:swap(4,3,4,4));assert(not b.won and b.failed)
end
b=fixture();b.specials[1]='star';b.specials[2]='star';b.targetColor=1;local expected=0;for _,v in ipairs(b.board)do if v==1 then expected=expected+1 end end
assert(b:swap(1,1,2,1));assert(b.collected>=expected,'Two Stars should clear the entire board')
print('MATCH3: vertical Spark, objective-specific failure and double-Star board clear passed.')

-- Presentation snapshots record the original colors and origins before gravity.
b=fixture();four(b);assert(b:swap(4,3,4,4));assert(#b.events>=1)
local event=b.events[1];assert(#event.cleared>=3 and #event.born==1)
assert(event.born[1].kind=='row'and event.born[1].index==25)
for _,cell in ipairs(event.cleared)do assert(cell.index>=1 and cell.index<=49 and cell.color>=1 and cell.color<=6)end
local FX=require('puzzle_fx')
local effect=FX.new(b.events);assert(effect.duration>0 and #effect.bursts>0 and #effect.bursts<=360)
assert(not effect:update(.01));assert(effect:update(3))
-- Keep the presentation bounded even for pathological cascade streams.
local events={};for i=1,100 do events[i]=event end
local bounded=FX.new(events);assert(bounded.duration<2 and #bounded.bursts<=360)
print('MATCH3 FX: snapshot origins, timed completion and particle/cascade bounds passed.')
