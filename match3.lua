-- Pure Lua match-three rules, separated from presentation for seeded tests.
local M={}; M.__index=M
local function key(x,y)return (y-1)*7+x end
function M.matches(board)
 local cells,groups={},0
 for y=1,7 do local x=1;while x<=7 do local e=x+1;while e<=7 and board[key(e,y)]==board[key(x,y)] do e=e+1 end
  if board[key(x,y)] and e-x>=3 then groups=groups+1;for i=x,e-1 do cells[key(i,y)]=true end end;x=e
 end end
 for x=1,7 do local y=1;while y<=7 do local e=y+1;while e<=7 and board[key(x,e)]==board[key(x,y)] do e=e+1 end
  if board[key(x,y)] and e-y>=3 then groups=groups+1;for i=y,e-1 do cells[key(x,i)]=true end end;y=e
 end end
 return cells,groups
end
function M.hasMove(board)
 for y=1,7 do for x=1,7 do for _,d in ipairs({{1,0},{0,1}}) do
  local xx,yy=x+d[1],y+d[2]
  if xx<=7 and yy<=7 then local a,b=key(x,y),key(xx,yy);board[a],board[b]=board[b],board[a]
   local _,groups=M.matches(board);board[a],board[b]=board[b],board[a];if groups>0 then return true end
  end
 end end end
 return false
end
function M:reshuffle()
 repeat
  self.board={}
  for y=1,7 do for x=1,7 do
   local choices={};for v=1,6 do
    if not (x>2 and self.board[key(x-1,y)]==v and self.board[key(x-2,y)]==v) and not (y>2 and self.board[key(x,y-1)]==v and self.board[key(x,y-2)]==v) then choices[#choices+1]=v end
   end
   self.board[key(x,y)]=choices[self.random(1,#choices)]
  end end
 until M.hasMove(self.board)
 self.selected=nil
end
function M.new(random,goal,moves)
 local self=setmetatable({random=random,goal=goal or 5,moves=moves or 18,count=0,board={},message='Swap neighbors to line up 3 or more. Each line is one match.'},M)
 self:reshuffle();return self
end
function M:swap(x,y,xx,yy)
 if self.won or self.failed or x<1 or x>7 or y<1 or y>7 or xx<1 or xx>7 or yy<1 or yy>7 or math.abs(x-xx)+math.abs(y-yy)~=1 then return false end
 local a,b=key(x,y),key(xx,yy);self.board[a],self.board[b]=self.board[b],self.board[a]
 local cells,groups=M.matches(self.board)
 self.moves=self.moves-1
 if groups==0 then
  self.board[a],self.board[b]=self.board[b],self.board[a];self.failed=self.moves<=0
  self.message='No match. One swap used; look for a line of three.';return false
 end
 local gained=0
 -- Resolve cascades; a bound guards pathological custom RNGs.
 for cascade=1,100 do
  gained=gained+groups
  for x1=1,7 do local values={}
   for y1=7,1,-1 do local v=self.board[key(x1,y1)];if not cells[key(x1,y1)] then values[#values+1]=v end end
   for y1=7,1,-1 do self.board[key(x1,y1)]=values[8-y1] or self.random(1,6) end
  end
  cells,groups=M.matches(self.board);if groups==0 then break end
  if cascade==100 then self:reshuffle() end
 end
 self.count=self.count+gained;self.won=self.count>=self.goal;self.failed=not self.won and self.moves<=0
 self.message=gained..' match'..(gained==1 and '' or 'es')..'!'
 if not self.won and not self.failed and not M.hasMove(self.board) then self:reshuffle();self.message='No moves available: free reshuffle.' end
 return true
end
return M
