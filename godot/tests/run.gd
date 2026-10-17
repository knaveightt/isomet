extends SceneTree
const Store=preload("res://scripts/store.gd")
var failures:=0
func check(value: bool, message: String) -> void:
 if not value: failures+=1; push_error(message)
func _initialize() -> void:
 call_deferred("run")
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func run() -> void:
 var scene=load("res://main.tscn").instantiate(); root.add_child(scene)
 await process_frame; await frames(2)
 check(not Store.valid_save({}),"Empty saves must be rejected")
 var data={"version":1,"name":"Mira","variant":5,"location":"City","position":[0,0,4],"powered":false,"escaped":false}
 check(Store.valid_save(data),"Valid checkpoint rejected")
 var bad=data.duplicate(true); bad.position=[0,"wrong",0]
 check(not Store.valid_save(bad),"Invalid coordinates accepted")
 bad=data.duplicate(true); bad.variant=15
 check(not Store.valid_save(bad),"Invalid character accepted")
 for index in range(8):
  scene.profile={"name":"Mira","variant":index,"location":"City"}; scene._replace_model(); scene._intro()
  check((index<4 and scene.companion_variant>=4) or (index>=4 and scene.companion_variant<4),"Wrong companion gender")
 for place in ["City","Suburb","Midwest"]:
  scene.profile.location=place; scene._intro(); scene.intro_time=6; scene._process_intro(.01)
  check(scene.hud.text.contains("!!!"),"Missing reaction")
 scene.actor.scale=Vector3.ONE; scene._begin_play(); await frames(3)
 Input.action_press("forward"); await frames(250); Input.action_release("forward")
 check(scene.actor.position.z< -7,"Player cannot pass through connecting arch")
 check(scene.actor.position.y> -.15,"Player fell through floor")
 scene.actor.position=Vector3(0,.1,-2)
 Input.action_press("left"); await frames(110); Input.action_release("left")
 check(scene.actor.position.x> -3.2 and scene.actor.position.x< -2.5,"Pillar collision failed")
 scene.actor.position=Vector3(-3,.1,-3); scene._interact()
 check(scene.powered and scene.mode=="note","Console interaction failed")
 scene.mode="play"; scene.actor.position=Vector3(0,.1,-18); scene._interact()
 check(scene.escaped and scene.mode=="victory","Escape interaction failed")
 check(Store.valid_save(Store.read_json(Store.SAVE)),"Checkpoint serialization failed")
 scene.settings.master=.35; scene.settings.invert=true; scene._save_settings()
 check(Store.read_json(Store.SETTINGS).invert==true,"Settings persistence failed")
 scene._title(); scene._new_game()
 check(scene.content.get_child(1).text=="Begin again?","Overwrite confirmation missing")
 scene.touch.show(); scene.touch.size=Vector2(1280,720)
 var press=InputEventScreenTouch.new(); press.index=0; press.pressed=true; press.position=Vector2(150,500); scene.touch._input(press)
 var drag=InputEventScreenDrag.new(); drag.index=0; drag.position=Vector2(200,460); scene.touch._input(drag)
 check(scene.touch.move.length()>.5,"Touch stick did not track movement")
 press.index=1; press.position=Vector2(900,300); scene.touch._input(press)
 drag.index=1; drag.position=Vector2(920,320); drag.relative=Vector2(20,20); scene.touch._input(drag)
 check(scene.touch.look.length()>1,"Right touch did not track camera independently")
 scene.touch.reset(); check(scene.touch.move==Vector2.ZERO,"Touch input stuck after pause")
 scene._settings(false); scene._credits(); scene._title()
 print("3D TESTS: ","PASS" if failures==0 else "FAIL", " / collision, movement, intro, interaction, saves, settings, overwrite")
 scene.music.stop(); scene.ambience.stop()
 # Fixed-FPS headless tests can finish before the audio mixer releases its last block.
 OS.delay_msec(100)
 root.remove_child(scene); scene.free(); quit(0 if failures==0 else 1)
