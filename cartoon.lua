-- Runtime atlas quads: no destructive resizing/cropping of source illustrations.
local metadata=require('cartoon_atlas')
local A={cache={}}
function A.load(sheet)
 if A.cache[sheet]then return A.cache[sheet]end
 local spec=assert(metadata[sheet]);local image=love.graphics.newImage(spec.file,{mipmaps=true});image:setFilter('linear','linear',4)
 local result={image=image,rects=spec.rects,quads={}}
 for i,r in ipairs(spec.rects)do result.quads[i]=love.graphics.newQuad(r[1],r[2],r[3],r[4],spec.width,spec.height)end
 A.cache[sheet]=result;return result
end
function A.draw(sheet,index,x,y,width,height,anchorX,anchorY,alpha,rotation,flip)
 local atlas=A.load(sheet);local r=atlas.rects[index];local size=math.min(width/r[3],height/r[4])
 love.graphics.setColor(1,1,1,alpha or 1)
 love.graphics.draw(atlas.image,atlas.quads[index],x,y,rotation or 0,flip and -size or size,size,r[3]*(anchorX or .5),r[4]*(anchorY or 1))
end
function A.drawRect(sheet,index,x,y,width,height,alpha)
 local atlas=A.load(sheet);local r=atlas.rects[index]
 love.graphics.setColor(1,1,1,alpha or 1);love.graphics.draw(atlas.image,atlas.quads[index],x,y,0,width/r[3],height/r[4])
end
function A.traveler(sprite,x,y,width,height,alpha,rotation,flip)
 A.draw('travelers',sprite.index,x,y,width,height,.5,1,alpha,rotation,flip)
end
return A
