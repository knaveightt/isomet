-- Original 16 x 16 sprites: shared proportions, two silhouettes, four palettes.
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
 {label='Tide',skin={.94,.72,.52,1},cloth={.37,.65,.74,1},hair={.23,.16,.29,1},trim={.97,.79,.40,1}},
 {label='Ember',skin={.76,.49,.32,1},cloth={.78,.32,.29,1},hair={.16,.11,.14,1},trim={1,.77,.42,1}},
 {label='Grove',skin={.46,.28,.20,1},cloth={.30,.62,.43,1},hair={.12,.09,.14,1},trim={.79,.88,.61,1}},
 {label='Aster',skin={.29,.17,.14,1},cloth={.64,.46,.81,1},hair={.78,.73,.65,1},trim={.85,.88,1,1}}
}
function C.load()
 for i=1,8 do
  local v=variants[(i-1)%4+1]
  local colors={H=v.hair,S=v.skin,E={.10,.12,.19,1},C=v.cloth,G=v.trim,B={.27,.30,.47,1},D={.17,.15,.25,1}}
  local data=love.image.newImageData(16,16)
  for y,row in ipairs(i<=4 and male or female) do for x=1,16 do
   local c=colors[row:sub(x,x)]; if c then data:setPixel(x-1,y-1,unpack(c)) end
  end end
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
 local g=love.graphics; local w,h,left,top=layout()
 g.setColor(.8,.89,.94); g.setFont(fonts.title); g.printf('Choose your traveler',0,top-89,w,'center')
 g.setFont(fonts.body); g.setColor(.55,.7,.79); g.printf('Eight faces at the edge of the world. Who will you be?',0,top-49,w,'center')
 for i=1,8 do
  local x=left+((i-1)%4)*170; local y=top+math.floor((i-1)/4)*142
  g.setColor(i==C.selected and .15 or .07,.14,.22,.95); g.rectangle('fill',x,y,154,128,8,8)
  g.setColor(i==C.selected and .61 or .23,i==C.selected and .88 or .32,i==C.selected and .89 or .43)
  g.setLineWidth(i==C.selected and 2 or 1); g.rectangle('line',x,y,154,128,8,8); g.setLineWidth(1)
  g.setColor(1,1,1); g.draw(C.images[i],x+45,y+12,0,4,4)
  g.setFont(fonts.body); g.printf((i<=4 and 'Male' or 'Female')..' · '..variants[(i-1)%4+1].label,x,y+91,154,'center')
 end
 g.setFont(fonts.body); g.setColor(.72,.83,.9); g.printf('Character name',0,top+290,w,'center')
 g.setColor(.07,.11,.18); g.rectangle('fill',w/2-220,top+313,440,39,5,5)
 g.setColor(.4,.65,.72); g.rectangle('line',w/2-220,top+313,440,39,5,5)
 g.setColor(.9,.93,.97); g.printf(C.name..(math.floor(time*2)%2==0 and '|' or ''),w/2-208,top+324,416,'center')
 g.setColor(.22,.40,.47); g.rectangle('fill',w/2-130,top+366,260,44,6,6)
 g.setColor(.88,.95,.94); g.printf('Enter the void',w/2-130,top+380,260,'center')
 g.setFont(fonts.small); g.setColor(.62,.73,.81); g.printf(C.message or 'Click a traveler or use arrow keys · Type your name (20 characters) · Enter to begin',0,top+427,w,'center')
end
return C
