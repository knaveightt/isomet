-- Pure Lua match-three rules. Colors, mobile specials and fixed clay overlays
-- are separate so gravity never carries a room's seal away from its tile.
local M={};M.__index=M
local function key(x,y)return (y-1)*7+x end
local function runs(board)
 local result={}
 for axis=1,2 do for line=1,7 do local pos=1
  while pos<=7 do local e=pos+1;local function at(p)return axis==1 and key(p,line)or key(line,p)end
   while e<=7 and board[at(e)]==board[at(pos)]do e=e+1 end
   if board[at(pos)]and e-pos>=3 then local r={axis=axis};for p=pos,e-1 do r[#r+1]=at(p)end;result[#result+1]=r end
   pos=e
  end
 end end
 return result
end
function M.matches(board)
 local cells={};local rr=runs(board)
 for _,r in ipairs(rr)do for _,i in ipairs(r)do cells[i]=true end end
 return cells,#rr
end
function M.hasMove(board,specials)
 for y=1,7 do for x=1,7 do for _,d in ipairs({{1,0},{0,1}})do
  local xx,yy=x+d[1],y+d[2]
  if xx<=7 and yy<=7 then local a,b=key(x,y),key(xx,yy)
   if specials and(specials[a]=='star'or specials[b]=='star'or(specials[a]and specials[b]))then return true end
   board[a],board[b]=board[b],board[a];local _,n=M.matches(board);board[a],board[b]=board[b],board[a]
   if n>0 then return true end
  end
 end end end
 return false
end
function M:reshuffle()
 -- Preserve earned special pieces (and every fixed seal) on a free reshuffle.
 repeat
  self.board={}
  for y=1,7 do for x=1,7 do local choices={}
   for v=1,6 do if not(x>2 and self.board[key(x-1,y)]==v and self.board[key(x-2,y)]==v)and not(y>2 and self.board[key(x,y-1)]==v and self.board[key(x,y-2)]==v)then choices[#choices+1]=v end end
   self.board[key(x,y)]=choices[self.random(1,#choices)]
  end end
 until M.hasMove(self.board,self.specials)
 self.selected=nil
end
function M.profile(room,target)
 local n=(math.min(room,target)*11+math.max(room,target)*7)%3
 if n==1 then return {kind='collect',goal=15,color=(room+target)%6+1,moves=22}
 elseif n==2 then return {kind='clay',goal=6,moves=24}end
 return {kind='matches',goal=7,moves=20}
end
function M.new(random,goal,moves,objective)
 local o=objective or {kind='matches',goal=goal or 5}
 local self=setmetatable({random=random,goal=o.goal or goal or 5,moves=o.moves or moves or 18,count=0,collected=0,broken=0,objective=o.kind or 'matches',targetColor=o.color or 1,board={},specials={},clay={}},M)
 self:reshuffle()
 if self.objective=='clay'then
  local positions={17,19,23,27,31,33}
  self.goal=math.min(self.goal,#positions)
  for i=1,self.goal do self.clay[positions[i]]=true end
 end
 self.message=self.objective=='clay'and 'Match on or beside clay tiles to break their seals.'or(self.objective=='collect'and 'Clear the requested color with matches or special pieces.'or 'Each line of three or more counts as a match.')
 return self
end
function M:progress()
 return self.objective=='collect'and self.collected or(self.objective=='clay'and self.broken or self.count)
end
local names={'red Embers','blue Tide gems','purple Asters','gold Lanterns','green Leaves','pink Hearts'}
function M:objectiveText()
 local n=math.min(self.goal,self:progress())
 if self.objective=='collect'then return 'Collect '..names[self.targetColor]..': '..n..' / '..self.goal
 elseif self.objective=='clay'then return 'Break clay seals: '..n..' / '..self.goal end
 return 'Make matches: '..n..' / '..self.goal
end
function M:swap(x,y,xx,yy)
 if self.won or self.failed or x<1 or x>7 or y<1 or y>7 or xx<1 or xx>7 or yy<1 or yy>7 or math.abs(x-xx)+math.abs(y-yy)~=1 then return false end
 self.events={}
 local a,b=key(x,y),key(xx,yy);local sp=self.specials
 self.board[a],self.board[b]=self.board[b],self.board[a];sp[a],sp[b]=sp[b],sp[a]
 local cells,groups=M.matches(self.board)
 local combo=sp[a]and sp[b];local star=sp[a]=='star'and a or(sp[b]=='star'and b)
 self.moves=self.moves-1
 if groups==0 and not combo and not star then
  self.board[a],self.board[b]=self.board[b],self.board[a];sp[a],sp[b]=sp[b],sp[a]
  self.failed=self.moves<=0;self.message='No match. One swap used; look for three in a line.';return false
 end
 -- A star can be swapped with any color. Two specials fire together.
 local forced={}
 local starColor=star and self.board[star==a and b or a]
 if star then
  local color=starColor
  for i=1,49 do if (sp[a]=='star'and sp[b]=='star')or self.board[i]==color or(combo and sp[i])then forced[i]=true end end
  forced[a]=true;forced[b]=true
 elseif combo then forced[a]=true;forced[b]=true end
 local gained,created,activated,broken=0,0,0,0
 for cascade=1,100 do
  local event={cleared={},born={},fired={},clay={}}
  local rr=runs(self.board);local births={};local visited={}
  -- Merge intersecting lines, creating exactly one special per connected match.
  for rindex,r in ipairs(rr)do if not visited[rindex]then
   local merged,indices={},{};local queue={rindex};visited[rindex]=true
   local qi=1
   while qi<=#queue do local ri=queue[qi];qi=qi+1
    for _,i in ipairs(rr[ri])do merged[i]=true end
    indices[#indices+1]=ri
    for j,other in ipairs(rr)do if not visited[j]then for _,i in ipairs(other)do if merged[i]then visited[j]=true;queue[#queue+1]=j;break end end end end
   end
   local kind
   for _,ri in ipairs(indices)do if #rr[ri]>=5 then kind='star' end end
   if not kind and #indices>1 then kind='bloom'end
   if not kind and #r>=4 then kind=r.axis==1 and 'row'or'column'end
   if kind then
    local anchor
    if cascade==1 then if merged[b]and not sp[b]then anchor=b elseif merged[a]and not sp[a]then anchor=a end end
    if not anchor then for i=1,49 do if merged[i]and not sp[i]then anchor=i;break end end end
    if anchor then births[anchor]=kind end
   end
  end end
  gained=gained+groups
  for i in pairs(forced)do cells[i]=true end;forced={}
  -- Chained effects expand the removal set before gravity is applied.
  local fired={};local changed=true
  while changed do changed=false
   for i=1,49 do if cells[i]and sp[i]and not fired[i]then
    fired[i]=true;activated=activated+1;changed=true
    event.fired[#event.fired+1]={index=i,kind=sp[i],color=self.board[i]}
    local sx,sy=(i-1)%7+1,math.floor((i-1)/7)+1;local kind=sp[i]
    for j=1,49 do local tx,ty=(j-1)%7+1,math.floor((j-1)/7)+1
     if(kind=='row'and ty==sy)or(kind=='column'and tx==sx)or(kind=='bloom'and math.abs(tx-sx)<=1 and math.abs(ty-sy)<=1)or(kind=='star'and self.board[j]==(i==star and starColor or self.board[i]))then cells[j]=true end
    end
   end end
  end
  -- A seal breaks once per resolution when its tile or a neighbor is hit.
  local cracked={}
  for i in pairs(cells)do
   local cx,cy=(i-1)%7+1,math.floor((i-1)/7)+1
   for _,d in ipairs({{0,0},{1,0},{-1,0},{0,1},{0,-1}})do local tx,ty=cx+d[1],cy+d[2]
    if tx>=1 and tx<=7 and ty>=1 and ty<=7 and self.clay[key(tx,ty)]then cracked[key(tx,ty)]=true end
   end
  end
  for i=1,49 do if cracked[i]then self.clay[i]=nil;broken=broken+1;event.clay[#event.clay+1]=i end end
  for i in pairs(cells)do if not births[i]and self.board[i]==self.targetColor then self.collected=self.collected+1 end end
  for i,kind in pairs(births)do
   -- Existing effects may hit the birth tile; the newly earned piece survives.
   cells[i]=nil;sp[i]=kind;created=created+1
   event.born[#event.born+1]={index=i,kind=kind,color=self.board[i]}
  end
  for i=1,49 do if cells[i]then event.cleared[#event.cleared+1]={index=i,color=self.board[i]}end end
  self.events[#self.events+1]=event
  for col=1,7 do local values,specials={},{}
   for row=7,1,-1 do local i=key(col,row)
    if not cells[i]then values[#values+1]=self.board[i];specials[#values]=sp[i]end
   end
   for row=7,1,-1 do local i=key(col,row);local offset=8-row;self.board[i]=values[offset]or self.random(1,6);sp[i]=specials[offset]end
  end
  star=nil;starColor=nil -- The swapped Star's chosen color applies only to this resolution.
  cells,groups=M.matches(self.board);if groups==0 then break end
  if cascade==100 then self:reshuffle()end
 end
 self.count=self.count+gained;self.broken=self.broken+broken
 self.won=self:progress()>=self.goal;self.failed=not self.won and self.moves<=0
 self.message=string.format('%d matches · %d specials made · %d fired · %d seals broken',gained,created,activated,broken)
 if not self.won and not self.failed and not M.hasMove(self.board,sp)then self:reshuffle();self.message=self.message..' · Free reshuffle!'end
 return true
end
return M
