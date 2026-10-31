-- Run with Lua 5.4. Mock only the engine services used to build sprite images.
-- Sprite assets are validated by assets_test.py; this test isolates input behavior.
love={graphics={getDimensions=function()return 800,600 end},keyboard={
 setTextInput=function(v)love.textEnabled=v end,setKeyRepeat=function(v)love.repeatEnabled=v end}}
package.loaded['cartoon']={load=function()return {}end}
local C=require('characters');C.load()
assert(#C.images==8 and love.textEnabled and love.repeatEnabled)
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
print('Character checks passed: 8 stable traveler choices, selection, UTF-8 editing, name limit, blank rejection, mouse confirmation.')
