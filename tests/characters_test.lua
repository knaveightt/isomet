-- Run with Lua 5.4. Mock only the engine services used to build sprite images.
local images={}
love={
 image={newImageData=function(w,h)
  assert(w==16 and h==16)
  return {pixels={},setPixel=function(self,x,y,...)
   assert(x>=0 and x<16 and y>=0 and y<16)
   self.pixels[y*16+x]=table.concat({...},',')
  end}
 end},
 graphics={newImage=function(data) data.setFilter=function() end; images[#images+1]=data; return data end,
 getDimensions=function() return 800,600 end},
 keyboard={setTextInput=function(value) love.textEnabled=value end,setKeyRepeat=function(value) love.repeatEnabled=value end}
}
unpack=table.unpack
local C=require('characters'); C.load()
assert(#images==8 and love.textEnabled and love.repeatEnabled)
for i=1,8 do for j=i+1,8 do
 local different=false
 for pixel,value in pairs(images[i].pixels) do if images[j].pixels[pixel]~=value then different=true; break end end
 assert(different,'Every portrait should be distinct')
end end
assert(not C.confirm() and C.active)
C.textinput('   '); assert(not C.confirm())
C.name=''; C.textinput('Éowyn'); C.keypressed('backspace'); assert(C.name=='Éowy')
C.textinput('\n\t'); assert(C.name=='Éowy')
C.name=string.rep('a',20); C.textinput('b'); assert(#C.name==20)
C.name='  Mira  '; C.keypressed('left'); assert(C.selected==8)
C.keypressed('right'); assert(C.selected==1)
C.keypressed('down'); assert(C.selected==5)
C.keypressed('up'); assert(C.selected==1)
-- At 800x600 the last card begins at (578,272).
C.mousepressed(600,300,1); assert(C.selected==8)
assert(C.mousepressed(400,510,1))
assert(C.name=='Mira' and not C.active and not love.textEnabled and not love.repeatEnabled)
print('Character checks passed: 8 unique sprites, selection, UTF-8 editing, name limit, blank rejection, mouse confirmation.')
