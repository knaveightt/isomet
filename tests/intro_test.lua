-- State and input checks run without opening a window.
love={math={random=math.random},graphics={
 newCanvas=function() return {setFilter=function() end} end,
 newFont=function() return {} end,
 getDimensions=function() return 800,600 end
}}
local I=require('intro')
for selected=1,8 do
 I.begin({selected=selected})
 assert(I.active and I.phase=='location' and I.time==0)
 assert(selected<=4 and I.companion>=5 and I.companion<=8 or selected>4 and I.companion>=1 and I.companion<=4)
 assert(not I.update(20) and I.time==0,'Location selection must wait for confirmation')
 I.keypressed('left'); assert(I.selected==3)
 I.keypressed('right'); assert(I.selected==1)
 I.keypressed('down'); assert(I.selected==2)
 I.keypressed('return'); assert(I.phase=='cutscene')
 local choice=I.selected; I.keypressed('right'); assert(I.selected==choice)
 for tick=1,124 do assert(not I.update(.1)) end
 assert(I.active and I.update(.2) and not I.active and I.phase=='done')
 assert(not I.update(1),'Completion must only be reported once')
end
I.begin({selected=1})
I.mousepressed(650,300,2); assert(I.selected==1)
I.mousepressed(650,300,1); assert(I.selected==3)
I.mousepressed(400,480,1); assert(I.phase=='cutscene' and I.time==0)
print('Intro checks passed: opposite-gender companions, location navigation, mouse controls, timeline and one-time completion.')
