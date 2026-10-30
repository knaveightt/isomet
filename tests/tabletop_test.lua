local C=require('campaign');local P=require('progress');local T=require('tabletop')
local opposite={NE='SW',SW='NE',SE='NW',NW='SE'}
for seed=1,50 do
 math.randomseed(seed);local rooms=C.generate(math.random)
 for _,r in ipairs(rooms)do
  local count,original=0,0;for _ in pairs(r.exits)do original=original+1 end
  for side,target in pairs(r.visualExits)do count=count+1;assert(rooms[target].visualExits[opposite[side]]==r.id)end
  assert(count==original,'Presentation ports changed graph destinations')
 end
 for a=1,15 do local ax,ay=T.origin(a)
  for b=a+1,15 do local bx,by=T.origin(b)
   assert(ax+rooms[a].width<=bx or bx+rooms[b].width<=ax or ay+rooms[a].height<=by or by+rooms[b].height<=ay,'Room footprints overlap')
  end
 end
 local p=P.new();p.inspected[8]=true
 local known,fog=T.visibility(rooms,1,p);assert(#known==1 and fog[8],'Inspecting a door must not reveal its room')
 p.seen[8]=true;local decoded=P.decode(p:encode());known,fog=T.visibility(rooms,8,decoded)
 assert(#known==2 and not fog[8]and not fog[1],'Saved discovery should lift fog in both views')
 p.seen[16]=true;known=T.visibility(rooms,1,p);assert(#known==2,'Other environments must not leak into this maze')
 local player={x=4,y=4};T.snap(1,player);local oldX,oldY=T.cx,T.cy
 local side;for s,target in pairs(rooms[1].visualExits)do if target==8 then side=s end end
 T.cross(1,player,8,player,side,opposite[side],rooms);assert(T.walk)
 T.update(.55,rooms,8,player);assert(T.walk and(T.cx~=oldX or T.cy~=oldY),'Camera did not scroll')
 for i=1,100 do T.update(.05,rooms,8,player)end
 local x,y=T.position(8,4,4);assert(not T.walk and math.abs(T.cx-x)<.01 and math.abs(T.cy-y)<.01)
 T.zoomBy(-100);assert(T.zoom==.38);T.zoomBy(100);assert(T.zoom==1.25)
 T.drag(30,-20);assert(T.panX==30 and T.panY==-20);T.recenter();assert(T.panX==0 and T.panY==0)
end
print('TABLETOP: 50 layouts passed non-overlap, reciprocal view ports, persistent fog, hidden-room isolation, camera traversal, zoom and pan checks.')
-- New solid corner scenery preserves a broad center cross and all spawn points.
local S=require('scenery')
for width=8,10 do for height=8,10 do local r={width=width,height=height}
 assert(S.blocked(r,1.5,1.5))
 for n=1,40 do local x=.35+(width-.7)*n/40;local y=.35+(height-.7)*n/40
  assert(not S.blocked(r,x,height/2)and not S.blocked(r,width/2,y),'Decor blocked the central navigation cross')
 end
end end
print('Solid scenery preserves room centers and all four central exit approaches.')
local rooms=C.generate(math.random);local p=P.new();local player={x=4,y=4}
T.update(.01,rooms,1,player,p);assert(not T.reveals[8])
p.seen[8]=true;T.update(.01,rooms,1,player,p);assert(T.reveals[8]and T.reveals[8]<.1)
for i=1,25 do T.update(.05,rooms,8,player,p)end;assert(not T.reveals[8])
local resumed=P.decode(p:encode());T.update(.01,rooms,8,player,resumed);assert(not next(T.reveals),'Loaded discoveries should remain clear')
print('Fog reveal animates once and stays clear after a saved journey resumes.')
