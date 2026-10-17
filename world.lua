-- Plain-text rooms are deliberately data, never executable Lua.
local W = {}
local opposite = {NE='SW', SW='NE', NW='SE', SE='NW'}
W.opposite = opposite
function W.generate(random)
  local rooms, cells = {}, {}
  local dirs = {{'NE',0,-1},{'SE',1,0},{'SW',0,1},{'NW',-1,0}}
  local names = {'The First Silence','Violet Reliquary','Chamber of Echoes','The Unlit Court','Threshold of Glass','A Forgotten Orbit','The Hollow Archive','Stillwater Without Water','The Pale Observatory','The Listening Stones','An Impossible Garden','The Last Interval'}
  local function add(x,y)
    local id=#rooms+1
    rooms[id]={id=id,name=names[id],width=random(7,10),height=random(7,10),exits={},pillars={},gx=x,gy=y}
    cells[x..','..y]=id
    return rooms[id]
  end
  add(0,0)
  while #rooms<12 do
    local a=rooms[random(1,#rooms)]; local d=dirs[random(1,4)]
    local x,y=a.gx+d[2],a.gy+d[3]
    if not cells[x..','..y] then
      local b=add(x,y); a.exits[d[1]]=b.id; b.exits[opposite[d[1]]]=a.id
    end
  end
  -- Occasional cycles make navigation more interesting than a single corridor.
  for _,a in ipairs(rooms) do
    for _,d in ipairs(dirs) do
      local id=cells[(a.gx+d[2])..','..(a.gy+d[3])]
      if id and not a.exits[d[1]] and random(1,3)==1 then
        a.exits[d[1]]=id; rooms[id].exits[opposite[d[1]]]=a.id
      end
    end
    for x=2,a.width-3 do for y=2,a.height-3 do
      if random(1,13)==1 and not (math.abs(x+.5-a.width/2)<1.6 or math.abs(y+.5-a.height/2)<1.6) then
        a.pillars[#a.pillars+1]={x=x+.5,y=y+.5}
      end
    end end
  end
  local queue,dist={1},{[1]=0}; local far=1
  for i=1,12 do
    local id=queue[i]; if not id then break end
    for _,nextId in pairs(rooms[id].exits) do if not dist[nextId] then
      dist[nextId]=dist[id]+1; queue[#queue+1]=nextId
      if dist[nextId]>dist[far] then far=nextId end
    end end
  end
  rooms[far].portal=true
  return rooms
end
function W.encode(r)
  local lines={'# ISOMET room v1 — coordinates are floor tiles','name = '..r.name,'size = '..r.width..' '..r.height,'portal = '..tostring(r.portal or false)}
  for _,side in ipairs({'NE','SE','SW','NW'}) do if r.exits[side] then lines[#lines+1]='exit = '..side..' '..r.exits[side] end end
  for _,p in ipairs(r.pillars) do lines[#lines+1]='pillar = '..p.x..' '..p.y end
  return table.concat(lines,'\n')..'\n'
end
function W.decode(text,id)
  local r={id=id,name='Unnamed chamber',exits={},pillars={}}
  for line in text:gmatch('[^\r\n]+') do
    local k,v=line:match('^%s*(%w+)%s*=%s*(.-)%s*$')
    if k=='name' then r.name=v
    elseif k=='size' then local w,h=v:match('^(%d+)%s+(%d+)$'); r.width=tonumber(w); r.height=tonumber(h)
    elseif k=='portal' then r.portal=v=='true'
    elseif k=='exit' then local s,n=v:match('^(%u%u)%s+(%d+)$'); assert(opposite[s], 'Invalid exit'); assert(not r.exits[s], 'Duplicate exit'); r.exits[s]=tonumber(n)
    elseif k=='pillar' then local x,y=v:match('^([%d.]+)%s+([%d.]+)$'); assert(tonumber(x) and tonumber(y),'Invalid pillar'); r.pillars[#r.pillars+1]={x=tonumber(x),y=tonumber(y)} end
  end
  assert(r.width and r.height and r.width>=5 and r.height>=5 and r.width<=16 and r.height<=16,'Room size must be 5–16 tiles')
  for _,p in ipairs(r.pillars) do assert(p.x>=1 and p.x<r.width-1 and p.y>=1 and p.y<r.height-1,'Pillar outside room interior') end
  return r
end
function W.validate(rooms)
  local portals=0
  for _,r in ipairs(rooms) do
    if r.portal then portals=portals+1 end
    for side,id in pairs(r.exits) do assert(rooms[id] and rooms[id].exits[opposite[side]]==r.id,'Exits must link back on the opposite side') end
  end
  assert(portals==1,'World needs exactly one escape portal')
  local seen,queue={[1]=true},{1}
  local i=1; while queue[i] do for _,id in pairs(rooms[queue[i]].exits) do if not seen[id] then seen[id]=true; queue[#queue+1]=id end end; i=i+1 end
  assert(#queue==#rooms,'All rooms must connect to room 1')
  return true
end
return W
