local Campaign=require('campaign');local Nav=require('navigation');local Shape=require('terrain_shape');local T=require('tabletop')
math.randomseed(423)
local rooms=Campaign.generate(math.random);local outlines={}
for _,r in ipairs(rooms)do
 local outline=Shape.outline(r);local signature={}
 for _,p in ipairs(outline)do signature[#signature+1]=string.format('%.5f,%.5f',p[1],p[2])end
 signature=table.concat(signature,';');assert(not outlines[signature],'A landscape outline repeats');outlines[signature]=true
 local x,y=r.width/2,r.height/2
 local targets={{x+1,y+.6},{x,-.35},{r.width+.3,y},{x,r.height+.35},{-.3,y}}
 for _,target in ipairs(targets)do
  local path=Nav.path(r,x,y,target[1],target[2]);assert(path,'No route to a clear land border')
  local px,py=x,y
  for _,point in ipairs(path)do assert(Nav.segment(r,px,py,point.x,point.y),'Path crosses a solid prop or cliff');px,py=point.x,point.y end
 end
 assert(not Nav.path(r,x,y,-20,-20))
end
for level=1,4 do for a=1,15 do local ia=Campaign.id(level,a);local ax,ay=T.origin(ia)
 for b=a+1,15 do local ib=Campaign.id(level,b);local bx,by=T.origin(ib)
  assert(ax+rooms[ia].width<=bx or bx+rooms[ib].width<=ax or ay+rooms[ia].height<=by or by+rooms[ib].height<=ay)
 end
end end
local curve=Shape.route(0,0,12,7,'SE','NW');assert(curve[1][1]==0 and curve[#curve][1]==12)
assert(math.abs(curve[8][2]-7*7/20)>.1,'Connection was flattened into a straight line')
print('LANDSCAPE: 60 unique outlines, clear click routes, walkable organic margins, four non-overlapping layouts and curved connections passed.')

local detour={id=61,slot=1,width=8,height=8,pillars={{x=4,y=4}}}
local path=Nav.path(detour,2,4,6,4);assert(path and #path>1)
local x,y=2,4;for _,point in ipairs(path)do assert(Nav.segment(detour,x,y,point.x,point.y));x,y=point.x,point.y end
print('Click navigation finds a safe detour around solid obstacles.')

local Progress=require('progress');local p=Progress.new();p.profile.name='Border walker';p.x=-.45;p.y=4.5
local restored=Progress.decode(p:encode());assert(restored.x==p.x and restored.y==p.y)
p.x=-100;assert(not pcall(Progress.decode,p:encode()),'Unbounded saved positions must still be rejected')
print('Saved organic-border positions round-trip without relaxing finite coordinate limits.')
