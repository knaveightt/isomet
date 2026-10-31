-- Reference-inspired courtyard dioramas over the existing room geometry.
local Art=require('cartoon')
local V=require('visual')
local E={meshes={}}
E.themes={
 {base={.25,.20,.23},mist={.45,.32,.32},water={.92,.28,.035},shine={1,.78,.16}},
 {base={.13,.46,.48},mist={.67,.85,.79},water={.08,.58,.65},shine={.68,.98,.91}},
 {base={.29,.37,.59},mist={.75,.80,.94},water={.23,.57,.82},shine={.76,.94,1}},
 {base={.25,.39,.29},mist={.64,.75,.52},water={.18,.48,.39},shine={.67,.86,.66}},
}
function E.background(level,w,h,time,panX)
 local g=love.graphics;local theme=E.themes[level]
 V.color(theme.base);g.rectangle('fill',0,0,w,h)
 -- A distant vista is scenic only: every playable room is drawn separately.
 local vistaH=math.max(225,math.min(h*.43,w*.25));local shift=math.max(-24,math.min(24,(panX or 0)*.025))
 Art.drawRect('backdrops',level,-28+shift,0,w+56,vistaH)
 for i=0,28 do local q=i/28;V.color(theme.base,q*.95);g.rectangle('fill',0,vistaH*.50+q*vistaH*.50,w,vistaH/28+1)end
 for i=1,11 do local x=(i*193+time*(1+i%3))%(w+200)-100;local y=h*.40+(i*83)%(math.max(1,h*.55))
  V.color(theme.mist,.035);g.ellipse('fill',x,y,140,18+i%4*5)
 end
 if level==3 then
  for i=1,65 do local x=(i*167+time*(4+i%4))%w;local y=(i*71+time*(9+i%6))%h
   g.setColor(.91,.96,1,.35);g.circle('fill',x,y,1+i%2*.5)
  end
 elseif level==1 then
  for i=1,26 do local x=(i*173+math.sin(time+i)*7)%w;local y=h-(i*79+time*13)%h
   g.setColor(1,.57,.16,.16+i%3*.07);g.circle('fill',x,y,1.1+i%2*.5)
  end
 end
end
local Shape=require('terrain_shape')
local function groundTexture(level)
 E.textures=E.textures or {};if E.textures[level]then return E.textures[level]end
 -- Ordinary Images survive window-mode changes; cached Canvases lose contents.
 local atlas=Art.load('ground');local rect=atlas.rects[level]
 E.groundPixels=E.groundPixels or love.image.newImageData('assets/cartoon/ground-materials.png')
 local pixels=love.image.newImageData(rect[3],rect[4]);pixels:paste(E.groundPixels,0,0,rect[1],rect[2],rect[3],rect[4])
 local texture=love.graphics.newImage(pixels,{mipmaps=true});texture:setWrap('repeat','repeat');texture:setFilter('linear','linear',4)
 E.textures[level]=texture;return texture
end
local function patch(key,points,project,level,triangles)
 local signature={};for _,point in ipairs(points)do signature[#signature+1]=point[1]..','..point[2]end;signature=table.concat(signature,';')
 local entry=E.meshes[key]
 if not entry or entry.signature~=signature then
  local flat={};for _,p in ipairs(points)do flat[#flat+1]=p[1];flat[#flat+1]=p[2]end
  entry={triangles=triangles or love.math.triangulate(flat),signature=signature};E.meshes[key]=entry
 end
 local vertices={}
 for _,triangle in ipairs(entry.triangles)do for n=1,6,2 do local wx,wy=triangle[n],triangle[n+1];local x,y=project(wx,wy)
  vertices[#vertices+1]={x,y,wx/7,wy/7,1,1,1,1}
 end end
 if not entry.mesh then entry.mesh=love.graphics.newMesh(vertices,'triangles','dynamic');entry.mesh:setTexture(groundTexture(level))else entry.mesh:setVertices(vertices)end
 love.graphics.setColor(.90,.91,.87);love.graphics.draw(entry.mesh)
end
local function cliff(key,points,project,level,scale)
 local g=love.graphics;local colors={{.43,.36,.31},{.75,.77,.69},{.75,.86,.98},{.54,.61,.42}};local c=colors[level];local vertices={}
 local function vertex(x,y,u,v,shade)return {x,y,u,v,c[1]*shade,c[2]*shade,c[3]*shade,1}end
 for i,a in ipairs(points)do local b=points[i%#points+1];local x,y=project(a[1],a[2]);local xx,yy=project(b[1],b[2]);local depth=(35+i%3*5)*scale
  local u=(a[1]+a[2])*.22;local v=(b[1]+b[2])*.22;local shade=.57+i%3*.035
  local first=vertex(x,y,u,0,shade*1.2);local second=vertex(xx,yy,v,0,shade*1.2)
  local third=vertex(xx,yy+depth,v,.7,shade*.65);local fourth=vertex(x,y+depth,u,.7,shade*.65)
  for _,point in ipairs({first,second,third,first,third,fourth})do vertices[#vertices+1]=point end
 end
 E.cliffMeshes=E.cliffMeshes or {};local entry=E.cliffMeshes[key]
 if not entry or entry:getVertexCount()~=#vertices then entry=g.newMesh(vertices,'triangles','dynamic');entry:setTexture(groundTexture(level));E.cliffMeshes[key]=entry else entry:setVertices(vertices)end
 g.setColor(1,1,1);g.draw(entry)
 if level==1 then for i,a in ipairs(points)do if i%5==0 then local x,y=project(a[1],a[2]);local pulse=.6+.15*math.sin(i+level*.3)
  g.setColor(1,.38,.035,pulse);g.setLineWidth(1.5*scale);g.line(x,y+12*scale,x+2*scale,y+32*scale)
 end end end
 g.setLineWidth(1)
end
local function ribbon(link)
 local left,right={},{};local route=link.route
 for i,p in ipairs(route)do local before=route[math.max(1,i-1)];local after=route[math.min(#route,i+1)]
  local dx,dy=after[1]-before[1],after[2]-before[2];local len=math.sqrt(dx*dx+dy*dy);local nx,ny=-dy/math.max(.1,len),dx/math.max(.1,len)
  local q=(i-1)/(#route-1);local half=2.2+math.abs(q-.5)*1.6+.12*math.sin(q*math.pi*3)
  left[#left+1]={p[1]+nx*half,p[2]+ny*half};right[#right+1]={p[1]-nx*half,p[2]-ny*half}
 end
 local triangles={}
 for i=1,#left-1 do local a,b,c,d=left[i],left[i+1],right[i],right[i+1]
  triangles[#triangles+1]={a[1],a[2],b[1],b[2],c[1],c[2]};triangles[#triangles+1]={b[1],b[2],d[1],d[2],c[1],c[2]}
 end
 for i=#right,1,-1 do left[#left+1]=right[i]end;return left,triangles
end
function E.land(rooms,visible,links,origin,project,scale)
 local patches={}
 for _,id in ipairs(visible)do local r=rooms[id];local rx,ry=origin(id);local points={}
  for _,p in ipairs(Shape.outline(r))do points[#points+1]={rx+p[1],ry+p[2]}end
  patches[#patches+1]={key='room'..id,points=points,level=r.level}
 end
 for _,link in ipairs(links)do if not link.bridge then local points,triangles=ribbon(link);patches[#patches+1]={key=link.key,points=points,triangles=triangles,level=link.level}end end
 -- All cliffs first, then every surface: shared land has no dark platform seams.
 for _,p in ipairs(patches)do cliff(p.key,p.points,project,p.level,scale)end
 for _,p in ipairs(patches)do patch(p.key,p.points,project,p.level,p.triangles)end
 -- Native low vegetation is generated from area identity, not repeated prefabs.
 for _,id in ipairs(visible)do local r=rooms[id];local rx,ry=origin(id);local outline=Shape.outline(r)
  for i,p in ipairs(outline)do if(i+id)%3==0 then
   local x,y=project(rx+p[1],ry+p[2]);local shade=r.level==3 and {.83,.89,.95}or{.34+(id%4)*.02,.43+(i%5)*.015,.24}
   V.color(V.shade(shade,.8));love.graphics.ellipse('fill',x,y+2*scale,(9+id%6)*scale,(4+i%4)*scale)
   V.color(shade);love.graphics.ellipse('fill',x-2*scale,y-3*scale,(7+id%5)*scale,(5+i%3)*scale)
   if r.level~=3 then for flower=1,3 do V.color({.73+(id%3)*.08,.61+(i%3)*.06,.38+(flower%3)*.13});love.graphics.circle('fill',x+(flower*7%15-7)*scale,y-(flower*5%9)*scale,(1.1+id%3*.25)*scale)end end
  end end
 end
end
function E.isBridge(a,b,level)
 local n=(math.min(a,b)*3+math.max(a,b))
 return n%(level==4 and 5 or 4)==0
end
function E.channel(a,b,c,d,scale,level,time)
 local g=love.graphics;local theme=E.themes[level];local dx,dy=c-a,d-b;local length=math.sqrt(dx*dx+dy*dy)
 if length<1 then return end
 g.setLineWidth(69*scale);V.color(theme.base,.8);g.line(a,b+28*scale,c,d+28*scale)
 g.setLineWidth(47*scale);V.color(theme.water,.85);g.line(a,b+31*scale,c,d+31*scale)
 for i=1,9 do local q=(i/10+time*.012)%1;local x,y=a+dx*q,b+dy*q+31*scale
  V.color(theme.shine,.15+math.sin(time+i)*.05);g.setLineWidth(1.5*scale);g.line(x-8*scale,y,x+8*scale,y)
 end
 g.setLineWidth(1)
end
return E
