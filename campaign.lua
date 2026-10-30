-- Authored content from the Miswander master plan; IDs are stable save keys.
local C={}
C.worlds={
 {name='The Crooked Kiln',code='K',entrance='Chimney Court',anchors={'Chimney Court','Mould Lane','Flue Walk','Glaze Court','Stitch Landing','Furnace Approach','Cooling Landing'},color={.29,.19,.20},guardian='The Cinder Smith',warning='The vents flash before they fire. Wait for the blue safe interval.',record='The chair was dusty before you arrived. Someone was taking pieces of home long before tonight.',warden='Those things followed you. Familiar surroundings can be a comfort.',pip='Then why was that chair dusty before we arrived?'},
 {name='Upside-Down Harbor',code='H',entrance='Dry Quay',anchors={'Dry Quay','Mooring Bend','Archive Walk','Glass Court','Watcher Landing','Tower Approach','Cold Landing'},color={.13,.26,.32},guardian='The Undertow',warning='Water surges after the warning. Shelter during the red interval.',record='The passenger list calls the captives replacements. Rooms are being collected, and so are people.',warden='Rooms are easier to save than people. I am doing what I can.',pip='That passenger list calls everyone a replacement. Including you.'},
 {name='The Midnight Snowfair',code='F',entrance='Ticket Square',anchors={'Ticket Square','Sled Bend','Mirror Walk','Prize Alley','Listening Landing','Owl Approach','Hatch Landing'},color={.25,.25,.38},guardian='The Glass Owl',warning='Only the real owl casts a shadow. Wait in shelter until the blue interval.',record='The dates repeat the same evening for years. The unfinished family scene was made before your arrival.',warden='I built a place where nothing precious had to disappear. Why does everyone insist on leaving?',pip='Look at the dates. He has been rebuilding the same evening for years.'},
 {name='The Buried Orchard',code='O',entrance='Root Porch',anchors={'Root Porch','Rooftop Bend','Hanging Walk','Bell Court','Portrait Landing','Foundation Approach','Homeward Landing'},color={.22,.28,.20},guardian='The Rootkeeper',warning='Dust falls before the stones. Strike only in the blue recovery interval.',record='The Warden built this refuge after losing his family. He stole rooms, belongings, people and animals to reconstruct a home. Grief does not excuse captivity.',warden='I kept every room. Every chair. I thought if I put it all back, someone would stay.',pip='A home needs a way out. Let them choose.'}
}
-- marking, interior name, task type, reward, requirements, description
C.doors={
 {
 {'The Missing-Finger Hand',"Potter's Cupboard",'inspect',"Potter's Mitts",{},'A four-fingered statue points to patched mitts. Protects against hot handles.'},
 {'The Clay-Toothed Gear','Crooked Pump Shop','match','Little Tooth Key',{"Potter's Mitts"},'Fit the mitts to the hot lever. Restore the ember mechanism.'},
 {'The Glowing Clawmarks','Breathing Flue','hazard','Emberglass Lens',{'Little Tooth Key'},'Cross three vent lanes, then open the keyed cache.'},
 {'The Downward Chimney','Borrowed Sitting Room','optional','Brass Button',{},'Smoke falls downward. The reflected side exit is whole; the obvious doorway has floor cracks.'},
 {'The Stitched Eye',"Blind Glazer's Room",'match','Crooked-Tooth Cog',{'Emberglass Lens'},'The lens reveals a hidden latch. Loosen the soot seals around a mechanical eye.'},
 {'The Red Thread','Room Behind the Stitch','story','Smith rhythm',{'Crooked-Tooth Cog'},'A thread taps three slow beats, then one quick beat.'},
 {'The Stapled Circle',"The Cinder Smith's Foundry",'guardian','Kiln Key',{'Crooked-Tooth Cog','Smith rhythm'},'Cool three seals during recovery. Bait the hammer away from the safe plate.'},
 {'The Steaming Wave','The Long Cooling Passage','exit',nil,{'Kiln Key'},'The key fits. A corridor of cooling stone bends toward impossible water.'}
 },{
 {'The Weeping Bowl','Dry-Dock Pantry','inspect',"Ship's Smile Wheel",{},'A moving drop circles a cracked bowl. A smiling wheel waits on the shelf.'},
 {'The Backward Spiral','Inside-Out Sluice','match','Archive Drained',{"Ship's Smile Wheel"},'Fit the wheel and restore the sluice. The lower archive drains.'},
 {'The Fish-Pressed Book','Lower Archive','hazard','Brass Gillfish',{'Archive Drained'},'Read the tide record. Recover the breathing aid between predictable surges.'},
 {'The Climbing Footprints','The Floating Supper','optional','Bent Teaspoon',{},'Hold the visible return rope. A side alcove is safe; releasing the rope at the warning swirl is fatal.'},
 {'The Caged Bubble','Air-Pocket Cabinet','match','Pearlglass Eye',{'Brass Gillfish'},'The breathing aid opens the water seal. Work safely inside the air pocket.'},
 {'The Wrong-Tide Window',"The Watcher's Booth",'story','Low-Tide Sequence',{'Pearlglass Eye'},'Read the altered passenger list. Three symbols give the floodgate order.'},
 {'The Bitten Ring','Undertow Tower','guardian','Harbor Key',{'Low-Tide Sequence'},'Open three floodgates in the Undertow recovery pauses. Shelter from its rush.'},
 {'The Dripping Feather','The Cold Stair','exit',nil,{'Harbor Key'},'Droplets stop in midair above a stair descending into snow.'}
 },{
 {'The Borrowed Bootprint','Lost-Coat Booth','inspect','Fairground Grippers',{},'A tiny footprint sits inside a giant one. Patched shoes grip the rough ice.'},
 {'The Returning Arrow','The Sled Gallery','hazard','Laughing Mirror Sliver',{'Fairground Grippers'},'Stop on the marked rough ice. The cracked edge is unsafe; the side exit is always free.'},
 {'The Curtained Sun','The Lantern Carousel','match','Sleeping Sun',{'Laughing Mirror Sliver'},'Fit the sliver to the light receiver. Clear the frost from a stationary platform.'},
 {'The Shared Shadow','The Laughing Reflection Hall','optional','Clockwork Ticket',{},'The reflection missing its scarf marks a hidden side door. The obvious reflection loops over cracked ice.'},
 {'The Burned Snowflake',"The Prizekeeper's Nursery",'picture','Prizekeeper Key',{'Sleeping Sun'},'Melt the seal and restore the family picture. Wrong placements are safe.'},
 {'The Crooked Star','The Listening Booth','story','Owl Shadow Clue',{'Prizekeeper Key'},'The reversed tune becomes a written clue: only the real owl casts a shadow.'},
 {'The Scratched Perch',"The Glass Owl's Observatory",'guardian','Snowfair Key',{'Prizekeeper Key','Owl Shadow Clue'},'Use the shadow clue. Redirect three beams while the owl rests.'},
 {'The Leafless Crack','The Buried Service Tunnel','exit',nil,{'Snowfair Key'},'A frozen hatch opens. Roots push through the ice below.'}
 },{
 {'The Fraying Weight','The Drowsy Weighhouse','match','Dozing Stone',{},'Restore the scale to release a sleeping, face-carved counterweight.'},
 {'The Root-Split Bridge','The Upside-Up Crossing','hazard','Knotwake Rope',{'Dozing Stone'},'Install the stone on the bridge plate. Cross during stable intervals; avoid shaking planks.'},
 {'The Knotted Face','The Hanging Rootshaft','hazard','Bellhead Hammer',{'Knotwake Rope'},'Anchor the living rope. Watch falling dust and cross between boulders.'},
 {'The Empty Nest Hand','The Offering Room','optional','Wooden Nest',{},'A hand requests your keepsake. You may refuse; it is never consumed. The safe root lift leads onward.'},
 {'The Bell in Stone','The Singing Wall','match','Orchard Seal',{'Bellhead Hammer'},'Strike the hollow latch and restore the sound patterns.'},
 {'The Turned Portrait','The Original Room','story','Homeward Sequence',{'Orchard Seal'},'The original family records reveal the guide is the builder himself.'},
 {'The Strangled Circle',"The Rootkeeper's Foundation",'guardian','Orchard Key',{'Orchard Seal'},'Lure three stomps onto marked plates and strike resonant stones during recovery.'},
 {'The Scratched Handle',"The Companion's Chamber",'finale',nil,{'Orchard Key','Homeward Sequence'},'Your companion works the inner latch while you set the outer sequence.'}
 }
}
C.origins={
 City={companion='your child',anchors={'Apartment chair','Buzzer intercom','TV remote'},traces={'A child drew your chair: "It remembered the room wrong."','A drawing on dry glass: "He asked which window was ours."','A drawing gives the chair a door: "I left you an exit."','A drawing shows two latch halves on opposite sides of the door.'},reunion='Back in your apartment, your child raises a hand. You return your TV-night high-five. The chair has one blue leg now.'},
 Suburb={companion='your partner',anchors={'Dining chair','Place card','Garage remote'},traces={'A place card: "Our table is here. We are not home."','Your partner writes: "He knew where we sat. He did not know our names."','A place card: "Do not tell him what you remember."','Your shared dinner rhythm taps against the inner frame.'},reunion='Your partner resets the dinner places. You finish the old dinner joke together. One place card is written in blue.'},
 Midwest={companion='your dog',anchors={'Barn boards','Feed scoop','Porch blanket'},traces={"Pawprints lead from your dog's blanket toward a passage.",'The collar tag chimes above a scratched gap beneath the wall.','Pawprints cross the family scene. A curtain has been tugged aside to reveal a latch.','Your dog has dug beneath the inner latch. A familiar toy sound brings an answering bark.'},reunion='On the farmhouse porch, your dog drops the familiar toy at your feet. You throw it once more. The toy now shines faintly blue.'}
}
function C.id(level,slot) return (level-1)*15+slot end
function C.info(id)
 local level=math.floor((id-1)/15)+1; local slot=(id-1)%15+1
 return level,slot,slot>7 and C.doors[level][slot-7] or nil
end
-- View-facing ports are separate from saved topology, so older journeys migrate intact.
local visualPorts={}
local opposite={NE='SW',SW='NE',SE='NW',NW='SE'}
for _,e in ipairs({{1,2,'SE'},{2,3,'SE'},{3,4,'SW'},{4,5,'NW'},{5,1,'NE'},{4,6,'SW'},{5,6,'NW'},
 {1,8,'NW'},{2,9,'NE'},{3,10,'SE'},{1,11,'NE'},{4,12,'SE'},{5,13,'SW'},{6,14,'SW'},{14,7,'SE'},{7,15,'SE'}})do
 visualPorts[e[1]..':'..e[2]]=e[3];visualPorts[e[2]..':'..e[1]]=opposite[e[3]]
end
function C.attach(rooms)
 for _,r in ipairs(rooms)do
  local l,s,d=C.info(r.id);r.level=l;r.slot=s;r.door=d;r.name=d and d[2]or C.worlds[l].anchors[s]
  r.visualExits={}
  for side,target in pairs(r.exits)do local _,slot=C.info(target);local port=visualPorts[s..':'..slot]or side
   assert(not r.visualExits[port],'Tabletop door ports overlap; check campaign topology')
   r.visualExits[port]=target
  end
 end
 return rooms
end
function C.generate(random)
 local rooms={}; local sides={'NE','SE','SW','NW'}; local opposite={NE='SW',SW='NE',SE='NW',NW='SE'}
 for l=1,4 do for s=1,15 do local id=C.id(l,s)
  rooms[id]={id=id,name='',width=random(8,10),height=random(8,10),exits={},pillars={}}
 end end
 local function link(a,b,side)
  assert(not rooms[a].exits[side] and not rooms[b].exits[opposite[side]])
  rooms[a].exits[side]=b; rooms[b].exits[opposite[side]]=a
 end
 for l=1,4 do
  local function id(s)return C.id(l,s)end
  for _,edge in ipairs({{1,2,'SE'},{2,3,'SE'},{3,4,'SE'},{4,5,'SE'},{5,1,'SE'},
    {4,6,'NE'},{5,6,'SW'},{1,8,'NE'},{2,9,'NE'},{3,10,'NE'},{1,11,'SW'},
    {4,12,'SW'},{5,13,'NE'},{6,14,'SE'},{14,7,'SE'},{7,15,'SE'}}) do
   link(id(edge[1]),id(edge[2]),edge[3])
  end
 end
 rooms[C.id(4,15)].portal=true
 for _,r in ipairs(rooms) do
  for x=2,r.width-3 do for y=2,r.height-3 do
   if random(1,18)==1 and math.abs(x+.5-r.width/2)>=1.6 and math.abs(y+.5-r.height/2)>=1.6 then r.pillars[#r.pillars+1]={x=x+.5,y=y+.5} end
  end end
 end
 return C.attach(rooms)
end
function C.validate(rooms)
 assert(#rooms==60,'Campaign needs 60 rooms')
 local opposite={NE='SW',SW='NE',SE='NW',NW='SE'}
 local portals=0
 for _,r in ipairs(rooms) do
  if r.portal then portals=portals+1; assert(r.id==60,'Final portal belongs in the companion chamber') end
  for side,target in pairs(r.exits) do assert(rooms[target] and rooms[target].exits[opposite[side]]==r.id,'Non-reciprocal campaign exit') end
 end
 assert(portals==1,'Campaign needs one finale portal')
 for l=1,4 do local queue={C.id(l,1)};local seen={[queue[1]]=true};local i=1
  while queue[i] do for _,target in pairs(rooms[queue[i]].exits) do
   assert(math.floor((target-1)/15)+1==l,'Use the story passage to travel between environments')
   if not seen[target] then seen[target]=true;queue[#queue+1]=target end
  end;i=i+1 end
  assert(#queue==15,'All local rooms must be connected')
 end
 return true
end
return C
