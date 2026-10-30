-- Original shaded 32 x 32 RPG sprites, built from two readable silhouettes.
local V=require("visual")
local utf8=require('utf8')
local C={selected=1,name='',active=true,images={}}
local male={
 '      HHHH      ','     HHHHHH     ','    HHHHHHHH    ','    HHHSSSHH    ',
 '    HHSESSH    ','     SSSSS      ','      SSS       ','    CCCCCCC     ',
 '   CCCGCGCCC    ','   SCCGGGCCS    ','   SSCCGCCSS    ','     CCCCC      ',
 '     BBBBB      ','     BB BB      ','    DDD DDD     ','    DDD DDD     '}
local female={
 '     HHHHHH     ','    HHHHHHHH    ','    HHHHHHHH    ','    HHHSSSHH    ',
 '    HHSESSHH    ','    HSSSSSHH    ','    HHSSSHHH    ','    CCCCCCC     ',
 '   CCCGCGCCC    ','   SCCGGGCCS    ','   SSCCGCCSS    ','     CCCCC      ',
 '    CCCCCCC     ','    CCCBCCC     ','     DD DD      ','    DDD DDD     '}
local variants={
 {label='Tide',skin={.94,.72,.52,1},cloth={.19,.67,.78,1},hair={.23,.16,.29,1},trim={.97,.79,.40,1}},
 {label='Ember',skin={.76,.49,.32,1},cloth={.92,.36,.26,1},hair={.16,.11,.14,1},trim={1,.77,.42,1}},
 {label='Grove',skin={.46,.28,.20,1},cloth={.30,.70,.42,1},hair={.12,.09,.14,1},trim={.79,.88,.61,1}},
 {label='Aster',skin={.29,.17,.14,1},cloth={.67,.43,.86,1},hair={.78,.73,.65,1},trim={.85,.88,1,1}}
}
function C.load()
 for i=1,8 do
  local v=variants[(i-1)%4+1]
  local colors={H=v.hair,S=v.skin,E={.10,.12,.19,1},C=v.cloth,G=v.trim,B={.27,.30,.47,1},D={.17,.15,.25,1}}
  local data=love.image.newImageData(32,32)
  local shape=i<=4 and male or female
  local occupied={}
  for y,row in ipairs(shape)do for x=1,16 do if colors[row:sub(x,x)]then
   for yy=0,1 do for xx=0,1 do occupied[(y*2-2+yy)*32+x*2-2+xx]=true end end
  end end end
  -- One-pixel colored outline gives every silhouette a clear edge.
  for index in pairs(occupied)do local x,y=index%32,math.floor(index/32)
   for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}})do local xx,yy=x+d[1],y+d[2]
    if xx>=0 and xx<32 and yy>=0 and yy<32 and not occupied[yy*32+xx]then data:setPixel(xx,yy,.19,.23,.30,1)end
   end
  end
  for y,row in ipairs(shape)do for x=1,16 do local symbol=row:sub(x,x);local c=colors[symbol]
   if c then for yy=0,1 do for xx=0,1 do local light=xx==0 and yy==0 and 1.18 or (xx==1 and yy==1 and .86 or 1)
    data:setPixel(x*2-2+xx,y*2-2+yy,math.min(1,c[1]*light),math.min(1,c[2]*light),math.min(1,c[3]*light),1)
   end end end
  end end
  -- Fine hair, face, embroidered belt and boot highlights.
  for x=12,18 do data:setPixel(x,3,math.min(1,v.hair[1]+.18),math.min(1,v.hair[2]+.14),math.min(1,v.hair[3]+.12),1)end
  data:setPixel(14,9,1,.94,.82,1);data:setPixel(14,10,.17,.22,.29,1)
  for x=11,20 do data:setPixel(x,23,v.trim[1],v.trim[2],v.trim[3],1)end
  data:setPixel(15,23,1,1,.82,1);data:setPixel(9,28,.58,.47,.37,1);data:setPixel(21,28,.58,.47,.37,1)
  C.images[i]=love.graphics.newImage(data); C.images[i]:setFilter('nearest','nearest')
 end
 love.keyboard.setTextInput(true); love.keyboard.setKeyRepeat(true)
end
function C.displayName() return C.name:match('^%s*(.-)%s*$') end
function C.confirm()
 if C.displayName()=='' then C.message='Please enter your character’s name.'; return false end
 C.name=C.displayName(); C.active=false
 love.keyboard.setTextInput(false); love.keyboard.setKeyRepeat(false)
 return true
end
function C.textinput(text)
 -- Keep printable UTF-8 characters, with a bounded name and on-screen width.
 text=text:gsub('[%z\1-\31\127]','')
 local candidate=C.name..text
 if utf8.len(candidate) and utf8.len(candidate)<=20 then C.name=candidate; C.message=nil end
end
function C.keypressed(key)
 if key=='left' then C.selected=(C.selected-2)%8+1
 elseif key=='right' then C.selected=C.selected%8+1
 elseif key=='up' or key=='down' then C.selected=(C.selected+3)%8+1
 elseif key=='backspace' then local offset=utf8.offset(C.name,-1); if offset then C.name=C.name:sub(1,offset-1) end; C.message=nil
 elseif key=='return' or key=='kpenter' then return C.confirm() end
 return false
end
local function layout()
 local w,h=love.graphics.getDimensions()
 return w,h,(w-664)/2,math.max(130,h/2-190)
end
function C.mousepressed(x,y,button)
 if button~=1 then return false end
 local w,h,left,top=layout()
 for i=1,8 do local cx=left+((i-1)%4)*170; local cy=top+math.floor((i-1)/4)*142
  if x>=cx and x<=cx+154 and y>=cy and y<=cy+128 then C.selected=i; return false end
 end
 if x>=w/2-130 and x<=w/2+130 and y>=top+366 and y<=top+410 then return C.confirm() end
 return false
end
function C.draw(fonts,time)
 local g=love.graphics;local w,h,left,top=layout()
 g.setFont(fonts.title);V.color(V.ink);g.printf('Choose your traveler',0,top-89,w,'center')
 g.setFont(fonts.body);V.color(V.muted);g.printf('A little courage. A familiar face. An extraordinary journey.',0,top-49,w,'center')
 for i=1,8 do
  local x=left+((i-1)%4)*170;local y=top+math.floor((i-1)/4)*142
  V.card(x,y,154,128,i==C.selected)
  V.color({.77,.89,.72});g.ellipse('fill',x+77,y+77,28,7)
  g.setColor(1,1,1);g.draw(C.images[i],x+45,y+12,0,2,2)
  g.setFont(fonts.body);V.color(V.ink);g.printf((i<=4 and 'Male' or 'Female')..' · '..variants[(i-1)%4+1].label,x,y+91,154,'center')
 end
 g.setFont(fonts.body);V.color(V.ink);g.printf('Character name',0,top+290,w,'center')
 V.card(w/2-220,top+313,440,39,false)
 V.color(V.ink);g.printf(C.name..(math.floor(time*2)%2==0 and '|'or''),w/2-208,top+324,416,'center')
 V.button(w/2-130,top+366,260,44,true);g.setColor(1,1,.94);g.printf('Continue',w/2-130,top+380,260,'center')
 g.setFont(fonts.small);V.color(C.message and {.68,.25,.19}or V.muted);g.printf(C.message or 'Click a traveler or use arrow keys · Type your name (20 characters) · Enter to begin',0,top+427,w,'center')
end
return C
