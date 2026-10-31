-- Eight illustrated traveler variants. Profile indices and input behavior are stable.
local V=require("visual")
local utf8=require('utf8')
local C={selected=1,name='',active=true,images={}}
local Art=require('cartoon')
local variants={{label='Tide'},{label='Ember'},{label='Grove'},{label='Aster'}}
function C.load()
 Art.load('travelers')
 for i=1,8 do C.images[i]={index=i}end
 love.keyboard.setTextInput(true);love.keyboard.setKeyRepeat(true)
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
 V.heading('Choose your traveler',0,top-89,w,fonts.title)
 g.setFont(fonts.body);V.color(V.muted);g.printf('A little courage. A familiar face. An extraordinary journey.',0,top-36,w,'center')
 for i=1,8 do
  local x=left+((i-1)%4)*170;local y=top+math.floor((i-1)/4)*142
  V.card(x,y,154,128,i==C.selected)
  V.color({.77,.89,.72});g.ellipse('fill',x+77,y+77,28,7)
  Art.traveler(C.images[i],x+77,y+84,77,82)
  if i==C.selected then V.badge(x+134,y+18)end
  g.setFont(fonts.body);V.color(V.ink);g.printf((i<=4 and 'Male' or 'Female')..' · '..variants[(i-1)%4+1].label,x,y+91,154,'center')
 end
 g.setFont(fonts.body);V.color(V.ink);g.printf('Character name',0,top+290,w,'center')
 V.card(w/2-220,top+313,440,39,false)
 V.color({.91,.87,.72});g.rectangle('fill',w/2-212,top+319,424,27,8,8)
 V.color(V.ink);g.printf(C.name..(math.floor(time*2)%2==0 and '|'or''),w/2-208,top+324,416,'center')
 V.button(w/2-130,top+366,260,44,true);V.buttonText('Continue',w/2-130,top+366,260,44,fonts.body)
 g.setFont(fonts.small);V.color(C.message and {.68,.25,.19}or V.muted);g.printf(C.message or 'Click a traveler or use arrow keys · Type your name (20 characters) · Enter to begin',0,top+427,w,'center')
end
return C
