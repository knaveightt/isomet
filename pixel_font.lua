-- Original 5x7 bitmap lettering. Each digit encodes a five-pixel row.
-- An image font avoids antialiased outlines at the cutscene's tiny resolution.
local rows={
 A={14,17,17,31,17,17,17},B={30,17,17,30,17,17,30},C={14,17,16,16,16,17,14},
 D={30,17,17,17,17,17,30},E={31,16,16,30,16,16,31},F={31,16,16,30,16,16,16},
 G={14,17,16,23,17,17,15},H={17,17,17,31,17,17,17},I={14,4,4,4,4,4,14},
 J={7,2,2,2,18,18,12},K={17,18,20,24,20,18,17},L={16,16,16,16,16,16,31},
 M={17,27,21,21,17,17,17},N={17,25,21,19,17,17,17},O={14,17,17,17,17,17,14},
 P={30,17,17,30,16,16,16},Q={14,17,17,17,21,18,13},R={30,17,17,30,20,18,17},
 S={15,16,16,14,1,1,30},T={31,4,4,4,4,4,4},U={17,17,17,17,17,17,14},
 V={17,17,17,17,17,10,4},W={17,17,17,21,21,21,10},X={17,17,10,4,10,17,17},
 Y={17,17,10,4,4,4,4},Z={31,1,2,4,8,16,31},
 [' ']={0,0,0,0,0,0,0},['.']={0,0,0,0,0,0,4},[',']={0,0,0,0,0,4,8},
 ['!']={4,4,4,4,4,0,4},['/']={1,2,2,4,8,8,16}
}
return function()
 local glyphs='ABCDEFGHIJKLMNOPQRSTUVWXYZ .,!/'
 local data=love.image.newImageData(1+#glyphs*6,9)
 for column=0,#glyphs do for y=0,8 do data:setPixel(column*6,y,1,0,1,1) end end
 for i=1,#glyphs do
  local pattern=rows[glyphs:sub(i,i)]
  for y,bits in ipairs(pattern) do for x=0,4 do
   if math.floor(bits/2^(4-x))%2==1 then data:setPixel(1+(i-1)*6+x,y,1,1,1,1) end
  end end
 end
 local font=love.graphics.newImageFont(data,glyphs)
 font:setFilter('nearest','nearest')
 return font
end
