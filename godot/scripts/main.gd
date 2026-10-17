extends Node3D
const Art = preload("res://scripts/art.gd")
const Store = preload("res://scripts/store.gd")
const Touch = preload("res://scripts/touch.gd")
var mobile := OS.get_name() in ["Android","iOS"]
var settings := {"master":0.7,"music":0.45,"ambience":0.6,"quality":1,"sensitivity":1.0,"invert":false,"reduced_motion":false,"large_text":false,"touch":false}
var profile := {"name":"Traveler","variant":0,"location":"City"}
var mode := "title"
var world: Node3D
var home: Node3D
var actor: CharacterBody3D
var model: Node3D
var reaction: Label3D
var companion: Node3D
var dog: Node3D
var camera: Camera3D
var ui: Control
var content: VBoxContainer
var safe: MarginContainer
var hud: Label
var prompt: Button
var touch: Control
var fade: ColorRect
var ambience: AudioStreamPlayer
var music: AudioStreamPlayer
var portal: Node3D
var portal_mesh: MeshInstance3D
var yaw := 0.0
var pitch := -0.24
var powered := false
var escaped := false
var elapsed := 0.0
var intro_time := 0.0
var auto_time := 0.0
var fps_sum := 0.0
var fps_count := 0
var body_bob := 0.0
var status := ""
var start_intro := false
var companion_variant := 4
var panel: PanelContainer
var save_timer := 0.0
var benchmark_samples: Array[float] = []
var quitting := false
var benchmark_finished := false
var benchmark_last_usec := 0
var benchmark_step := 0
var benchmark_path := [Vector3(0,0,4),Vector3(-3,0,-3),Vector3(0,0,-4),Vector3(0,0,-9),Vector3(0,0,-17),Vector3(0,0,-9),Vector3(0,0,-4)]
func _ready() -> void:
 get_tree().auto_accept_quit=false
 var saved = Store.read_json(Store.SETTINGS)
 for key in settings:
  if saved.has(key):
   if typeof(saved[key]) == typeof(settings[key]) or (settings[key] is int and saved[key] is float): settings[key]=saved[key]
 settings.quality=clampi(int(settings.quality),0,2)
 settings.sensitivity=clampf(float(settings.sensitivity),.3,2.5)
 for key in ["master","music","ambience"]: settings[key]=clampf(float(settings[key]),0,1)
 _inputs(); _build_world(); _build_ui(); _audio(); _apply_settings(); _title()
 get_tree().root.size_changed.connect(_safe_area)
 if "--smoke" in OS.get_cmdline_user_args(): _smoke()
 elif "--gallery" in OS.get_cmdline_user_args(): _gallery()
 elif "--benchmark" in OS.get_cmdline_user_args():
  profile={"name":"Benchmark","variant":0,"location":"City"}; _begin_play(); powered=true
func _inputs() -> void:
 for action in ["forward","back","left","right","interact","run"]:
  if not InputMap.has_action(action): InputMap.add_action(action)
 var mapping={"forward":[KEY_W,KEY_UP],"back":[KEY_S,KEY_DOWN],"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"interact":[KEY_E],"run":[KEY_SHIFT]}
 for action in mapping:
  for key in mapping[action]:
   var e=InputEventKey.new(); e.physical_keycode=key; InputMap.action_add_event(action,e)
func _build_world() -> void:
 var env=WorldEnvironment.new(); var resource=Environment.new()
 resource.background_mode=Environment.BG_COLOR; resource.background_color=Color("07121f")
 resource.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; resource.ambient_light_color=Color("718eaa"); resource.ambient_light_energy=.8
 resource.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 env.environment=resource; add_child(env)
 var sun=DirectionalLight3D.new(); sun.light_color=Color("a1c9dc"); sun.light_energy=1.0; sun.rotation_degrees=Vector3(-48,-32,0); add_child(sun)
 world=Node3D.new(); add_child(world)
 # Two chambers connected by a walk-through arch; only this slice is converted.
 Art.box(world,Vector3(0,-.3,-6),Vector3(12,.6,28),Art.DARK,true)
 for z in range(-19,8,2):
  for x in range(-5,6,2):
   Art.box(world,Vector3(x,.006,z),Vector3(1.94,.025,1.94),Color("21434a") if (x+z)%4==0 else Color("284c51"))
 for x in [-5.8,5.8]:
  Art.box(world,Vector3(x,1.8,-6),Vector3(.35,3.6,28),Art.TEAL,true)
  for y in [.2,2.8,3.4]: Art.box(world,Vector3(x-.18*sign(x),y,-6),Vector3(.06,.07,28),Art.BRASS)
  for z in range(-18,8,4):
   for offset in [-.18,0,.18]: Art.box(world,Vector3(x-.25*sign(x),1.6,z+offset),Vector3(.25,3.2,.07),Art.BRASS)
   Art.box(world,Vector3(x-.45*sign(x),2.4,z),Vector3(.18,.7,.26),Art.CYAN,false,1.5)
 for z in [7.8,-19.8]: Art.box(world,Vector3(0,1.8,z),Vector3(12,3.6,.35),Art.TEAL,true)
 # Divider with an actual central opening.
 for x in [-3.9,3.9]: Art.box(world,Vector3(x,1.6,-6),Vector3(4.2,3.2,.4),Art.DARK,true)
 Art.arch(world,-6)
 Art.batch_static(world)
 for x in [-3.8,3.8]:
  for z in [-2,-14]:
   Art.cylinder(world,Vector3(x,1.5,z),.32,3,Art.STONE)
   Art.cylinder(world,Vector3(x,.12,z),.52,.24,Art.BRASS)
   Art.cylinder(world,Vector3(x,3,z),.5,.2,Art.BRASS)
   var body=StaticBody3D.new(); world.add_child(body); body.position=Vector3(x,1.5,z)
   var collision=CollisionShape3D.new(); var bounds=CylinderShape3D.new(); bounds.radius=.48; bounds.height=3
   collision.shape=bounds; body.add_child(collision)
 for z in [3,-10]:
  for n in range(5): Art.box(world,Vector3(0,.025,z+n*.30),Vector3(.8-n*.10,.02,.06),Art.BRASS)
 # Deco dais and a machinery terminal, with an in-world story fragment.
 Art.box(world,Vector3(-3,.6,-3),Vector3(1.1,1.2,.8),Art.DARK,true)
 var screen=Art.box(world,Vector3(-3,1.35,-3),Vector3(.9,.65,.18),Art.CYAN,false,1)
 screen.rotation_degrees.x=-15
 Art.label(world,"RESONANCE / 01",Vector3(-3,1.95,-2.9),26)
 Art.label(world,"THE FIRST SILENCE",Vector3(0,3.0,7.5),42).rotation.y=PI
 Art.label(world,"THE LAST INTERVAL",Vector3(0,3.05,-19.5),40)
 Art.label(world,"WE HEARD THEM IN THE STATIC.\nWE OPENED THE WRONG DOOR.",Vector3(3,1.8,-19.5),24,Art.STONE)
 portal=Node3D.new(); world.add_child(portal); portal.position=Vector3(0,0,-18)
 for n in range(3): Art.box(portal,Vector3(0,.08+n*.09,0),Vector3(3.4-n*.35,.18,1.6-n*.2),Art.BRASS)
 Art.arch(portal,0)
 portal_mesh=Art.box(portal,Vector3(0,1.6,0),Vector3(2.5,2.9,.045),Art.VIOLET,false,2)
 var veil=ShaderMaterial.new(); veil.shader=load("res://assets/threshold.gdshader"); portal_mesh.material_override=veil
 # A stepped fan relief above the central passage and at the portal.
 for center_z in [-6.0,-18.0]:
  for n in range(-4,5):
   var ray=Art.box(world,Vector3(n*.22,3.8-abs(n)*.09,center_z-.35),Vector3(.055,.6-abs(n)*.055,.055),Art.BRASS)
   ray.rotation.z=-n*.15
 for x in [-3.8,3.8]:
  for z in [-2,-14]:
   Art.cylinder(world,Vector3(x,.025,z),.8,.018,Color("102b34"))
 # A distant suspended silhouette rather than expensive volumetric effects.
 for i in range(28):
  var rng=RandomNumberGenerator.new(); rng.seed=i*137+41
  var star=Art.box(world,Vector3(rng.randf_range(-40,40),rng.randf_range(5,22),rng.randf_range(-60,20)),Vector3(.06,.06,.06),Art.CYAN,false,1)
  star.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 # Warm/cool lighting contrast, with no shadow maps or volumetric passes.
 for p in [Vector3(-3,2.8,1),Vector3(3,2.8,-10),Vector3(0,2.7,-17)]:
  var light=OmniLight3D.new(); light.position=p; light.light_color=Color("e7bd7b") if p.z> -5 else Color("6c9fe3")
  light.light_energy=1.5; light.omni_range=7; light.omni_attenuation=1.3; light.shadow_enabled=false; world.add_child(light)
 Art.batch_static(world)
 actor=CharacterBody3D.new(); actor.name="Traveler"; add_child(actor)
 var collision=CollisionShape3D.new(); var capsule=CapsuleShape3D.new(); capsule.radius=.3; capsule.height=1.7
 collision.shape=capsule; collision.position.y=.85; actor.add_child(collision)
 model=Art.person(actor,0); actor.position=Vector3(0,.05,4)
 reaction=Art.label(actor,"!!!",Vector3(0,2.25,0),70,Color("fff1c9")); reaction.billboard=BaseMaterial3D.BILLBOARD_ENABLED; reaction.hide()
 camera=Camera3D.new(); add_child(camera); camera.current=true; camera.fov=58; camera.far=110; camera.position=Vector3(2.6,2.8,5); camera.look_at(Vector3(0,1.4,-12))
 home=Node3D.new(); add_child(home); home.visible=false
func _make_home() -> void:
 for child in home.get_children(): child.free()
 Art.box(home,Vector3(0,-.25,0),Vector3(12,.5,10),Color("58454b"))
 Art.box(home,Vector3(0,2,-4.8),Vector3(12,4,.2),Color("253c4d"))
 var location=profile.location
 if location=="City":
  Art.box(home,Vector3(-1,.45,0),Vector3(3,.8,2.4),Color("544869"))
  Art.box(home,Vector3(-1,.9,.2),Vector3(3,.16,1.7),Color("8987a1"))
  Art.box(home,Vector3(-1,1.05,.8),Vector3(2.8,.16,.45),Art.STONE)
  Art.box(home,Vector3(2,.5,-2),Vector3(2.4,1,.8),Color("4d3a36"))
  Art.box(home,Vector3(-3,.6,0),Vector3(.7,1.2,.7),Color("4d3a36"))
  Art.cylinder(home,Vector3(-3,1.7,0),.3,.4,Color("c9ad7d"))
  Art.box(home,Vector3(2,1.2,-2),Vector3(2.1,1.3,.4),Art.DARK)
  Art.box(home,Vector3(2,1.3,-1.77),Vector3(1.8,1,.03),Art.CYAN,false,1)
  for x in [-4,-2,0]: Art.box(home,Vector3(x,2.3,-4.6),Vector3(1.3,2,.04),Color("102a44"))
 elif location=="Suburb":
  Art.box(home,Vector3(-1,.8,0),Vector3(2.8,.14,1.8),Color("895e42"))
  for x in [-2.1,.1]:
   for z in [-.6,.6]: Art.box(home,Vector3(x,.4,z),Vector3(.12,.8,.12),Color("473539"))
   Art.box(home,Vector3(x,.4,1.4),Vector3(.55,.8,.55),Color("473539"))
   Art.box(home,Vector3(x,.95,1.62),Vector3(.55,.9,.1),Color("473539"))
  Art.box(home,Vector3(-1,.015,.2),Vector3(4,.02,3.5),Color("563d50"))
  for x in [-2,0]:
   Art.cylinder(home,Vector3(x,.9,0),.32,.04,Art.STONE)
   Art.sphere(home,Vector3(x,.99,0),.14,Color("b28b46"))
  Art.box(home,Vector3(2,1.6,-2),Vector3(1.7,2.8,.3),Art.BRASS)
  Art.box(home,Vector3(2,1.6,-1.8),Vector3(1.4,2.5,.03),Art.CYAN,false,.5)
 else:
  Art.box(home,Vector3(0,-.01,0),Vector3(12,.05,10),Color("76754c"))
  for z in [-3.5,3.5]:
   Art.box(home,Vector3(0,.65,z),Vector3(11,.1,.1),Color("a68d63"))
   Art.box(home,Vector3(0,1.1,z),Vector3(11,.1,.1),Color("a68d63"))
  for x in range(-5,6):
   for z in [-3,3]:
    Art.box(home,Vector3(x,.7,z),Vector3(.06,1.4,.06),Color("827a40"))
    Art.box(home,Vector3(x,1,z),Vector3(.25,.3,.2),Color("c8a85c"))
  Art.box(home,Vector3(-3,1.4,-4),Vector3(3,2.8,1),Color("855348"))
  Art.box(home,Vector3(2,.03,-2),Vector3(2,.05,1.6),Art.CYAN,false,.6)
 companion_variant=randi_range(4,7) if int(profile.variant)<4 else randi_range(0,3)
 companion=Art.person(home,companion_variant); companion.position=Vector3(-.5,0,-.6)
 dog=Art.dog(home); dog.position=Vector3(.7,0,.8)
func _build_ui() -> void:
 var layer=CanvasLayer.new(); add_child(layer)
 ui=Control.new(); ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layer.add_child(ui)
 var theme=Theme.new(); theme.default_font_size=24 if mobile else 20
 var normal=StyleBoxFlat.new(); normal.bg_color=Color(.025,.07,.09,.94); normal.border_color=Art.BRASS
 normal.set_border_width_all(1); normal.content_margin_left=22; normal.content_margin_right=22; normal.content_margin_top=12; normal.content_margin_bottom=12
 theme.set_stylebox("normal","Button",normal)
 var hover=normal.duplicate(); hover.bg_color=Color("214b50"); hover.set_border_width_all(2)
 theme.set_stylebox("hover","Button",hover); theme.set_stylebox("focus","Button",hover); theme.set_stylebox("pressed","Button",hover)
 theme.set_color("font_color","Button",Color("f4ead2")); theme.set_color("font_disabled_color","Button",Color("687574"))
 ui.theme=theme
 safe=MarginContainer.new(); safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.add_child(safe)
 var stack=HBoxContainer.new(); safe.add_child(stack)
 panel=PanelContainer.new(); panel.custom_minimum_size=Vector2(440,0); stack.add_child(panel)
 var bg=StyleBoxFlat.new(); bg.bg_color=Color(.012,.032,.047,.93); bg.content_margin_left=30; bg.content_margin_right=30; bg.content_margin_top=24; bg.content_margin_bottom=24
 panel.add_theme_stylebox_override("panel",bg)
 var scroll=ScrollContainer.new(); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; panel.add_child(scroll)
 content=VBoxContainer.new(); content.size_flags_horizontal=Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation",12); scroll.add_child(content)
 var spacer=Control.new(); spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL; spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE; stack.add_child(spacer)
 hud=Label.new(); hud.position=Vector2(30,24); hud.add_theme_color_override("font_color",Color("f5ead0")); ui.add_child(hud)
 touch=Touch.new(); touch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.add_child(touch)
 prompt=Button.new(); prompt.text="Interact"; prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT); prompt.position=Vector2(-250,-105); prompt.size=Vector2(210,64); prompt.pressed.connect(_interact); ui.add_child(prompt)
 var pause=Button.new(); pause.text="II"; pause.position=Vector2(-85,20); pause.set_anchors_preset(Control.PRESET_TOP_RIGHT); pause.custom_minimum_size=Vector2(64,56); pause.pressed.connect(_pause); ui.add_child(pause); pause.name="Pause"
 fade=ColorRect.new(); fade.color=Color(0,0,0,0); fade.mouse_filter=Control.MOUSE_FILTER_IGNORE; fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.add_child(fade)
 _safe_area()
func _safe_area() -> void:
 var padding=Vector4(24,20,24,20)
 if mobile:
  var area=DisplayServer.get_display_safe_area(); var screen=DisplayServer.screen_get_size(); var view=get_viewport().get_visible_rect().size
  if screen.x>0 and screen.y>0:
   padding.x=maxf(24,area.position.x*view.x/screen.x)
   padding.y=maxf(20,area.position.y*view.y/screen.y)
   padding.z=maxf(24,(screen.x-area.end.x)*view.x/screen.x)
   padding.w=maxf(20,(screen.y-area.end.y)*view.y/screen.y)
 for i in range(4): safe.add_theme_constant_override(["margin_left","margin_top","margin_right","margin_bottom"][i],int(padding[i]))
 panel.custom_minimum_size.x=clampf(get_viewport().get_visible_rect().size.x*(.5 if mobile else .36),460 if mobile else 370,600 if mobile else 490)
 hud.position=Vector2(padding.x+8,padding.y+8)
 prompt.offset_right=-padding.z-12; prompt.offset_left=-padding.z-222; prompt.offset_bottom=-padding.w-12; prompt.offset_top=-padding.w-76
 ui.get_node("Pause").position=Vector2(get_viewport().get_visible_rect().size.x-padding.z-76,padding.y)
func _clear(title: String, subtitle: String="") -> void:
 for child in content.get_children(): child.free()
 _label("T H E   Q U I E T   B E T W E E N",14,Art.BRASS)
 var heading=_label(title,68 if title=="ISOMET" else 36,Color("f3e9d0"))
 if title=="ISOMET":
  heading.hide()
  var wordmark=TextureRect.new(); wordmark.texture=load("res://assets/wordmark.svg"); wordmark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; wordmark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; wordmark.custom_minimum_size.y=90; content.add_child(wordmark)
 if title=="ISOMET":
  heading.add_theme_constant_override("outline_size",1)
  var ornament=HSeparator.new(); ornament.modulate=Art.BRASS; content.add_child(ornament)
 if subtitle!="": _label(subtitle,18,Color("a4b9ba"))
 panel.show(); hud.hide(); prompt.hide(); touch.hide(); touch.reset(); ui.get_node("Pause").hide()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func _label(text: String, size: int=20, color: Color=Color.WHITE) -> Label:
 var l=Label.new(); l.text=text; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size.x=280
 l.set_meta("base_size",size); l.add_theme_font_size_override("font_size",size+(3 if settings.large_text else 0)); l.modulate=color; content.add_child(l); return l
func _button(text: String, callback: Callable, disabled: bool=false) -> Button:
 var b=Button.new(); b.text=text; b.custom_minimum_size.y=76 if mobile else 54; b.disabled=disabled; content.add_child(b); b.pressed.connect(callback); return b
func _title() -> void:
 mode="title"; world.show(); home.hide(); actor.hide(); _clear("ISOMET", "A threshold observatory, suspended outside time.\nFind the ones the silence took.")
 _button("Continue",_continue,not Store.valid_save(Store.read_json(Store.SAVE)))
 _button("New Game",_new_game)
 _button("Settings",func(): _settings(false))
 _button("Credits",_credits)
 if OS.get_name()=="Windows": _button("Quit to Desktop",func(): _quit_cleanly())
 _label("3D VERTICAL SLICE  /  THE FIRST SILENCE",13,Art.BRASS)
 if status!="": _label(status,16)
 _focus()
func _focus() -> void:
 for c in content.get_children():
  if c is Button and not c.disabled: c.grab_focus(); break
func _new_game() -> void:
 if Store.valid_save(Store.read_json(Store.SAVE)):
  _clear("Begin again?","Your existing checkpoint will be replaced when you enter the void. Your settings will remain.")
  _button("Begin new journey",_creation); _button("Keep existing journey",_title); _focus()
 else: _creation()
func _creation() -> void:
 mode="create"; actor.show(); actor.position=Vector3(0,0,3); _replace_model()
 _clear("Your traveler","Eight travelers. One impossible way home.")
 var name_input=LineEdit.new(); name_input.placeholder_text="Character name"; name_input.max_length=20; name_input.text=profile.name if profile.name!="Traveler" else ""; name_input.custom_minimum_size.y=76 if mobile else 54; content.add_child(name_input)
 var choice=OptionButton.new(); choice.custom_minimum_size.y=76 if mobile else 54
 for gender in ["Male","Female"]:
  for variant in ["Tide","Ember","Grove","Aster"]: choice.add_item(gender+" / "+variant)
 choice.select(int(profile.variant)); content.add_child(choice)
 choice.item_selected.connect(func(index): profile.variant=index; _replace_model())
 var location=OptionButton.new(); location.custom_minimum_size.y=76 if mobile else 54
 for place in ["City","Suburb","Midwest"]: location.add_item(place)
 content.add_child(location)
 _label("City: a television at night.\nSuburb: a dining-room mirror.\nMidwest: a puddle among the corn.",16)
 var error=_label("",16,Color("f2ad8d"))
 _button("Begin your story",func():
  if name_input.text.strip_edges().is_empty(): error.text="Please enter your character's name."; return
  profile.name=name_input.text.strip_edges(); profile.location=location.get_item_text(location.selected)
  _loading(func(): _intro())
 )
 _button("Back",_title); name_input.grab_focus()
func _replace_model() -> void:
 if is_instance_valid(model): model.free()
 model=Art.person(actor,int(profile.variant))
func _loading(next: Callable) -> void:
 _clear("Crossing the threshold…","Loading the observatory")
 await get_tree().process_frame
 await get_tree().process_frame
 next.call()
func _intro() -> void:
 _make_home(); mode="intro"; intro_time=0; home.show(); world.hide(); actor.show(); actor.position=Vector3(-2,0,1)
 panel.hide(); hud.show(); prompt.hide(); ui.get_node("Pause").hide(); fade.color.a=1
func _begin_play() -> void:
 home.hide(); world.show(); actor.show(); actor.position=Vector3(0,.05,2); actor.velocity=Vector3.ZERO
 powered=false; escaped=false; yaw=0; pitch=-.24; mode="play"; _position_camera(0,true); _play_ui(); _save(); fade.color.a=1
func _play_ui() -> void:
 reaction.hide(); panel.hide(); hud.show(); ui.get_node("Pause").show(); touch.visible=mobile or settings.touch
 if not mobile and not "--gallery" in OS.get_cmdline_user_args(): Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func _continue() -> void:
 var saved=Store.read_json(Store.SAVE)
 if not Store.valid_save(saved): status="Checkpoint is missing or invalid."; _title(); return
 _loading(func():
  profile={"name":saved.name,"variant":int(saved.variant),"location":saved.location}; companion_variant=int(saved.get("companion",4 if int(saved.variant)<4 else 0)); _replace_model()
  var p=saved.position; actor.position=Vector3(p[0],p[1],p[2]); actor.velocity=Vector3.ZERO
  powered=saved.powered; escaped=saved.escaped; world.show(); home.hide(); actor.show(); mode="play"; _position_camera(0,true); _play_ui(); fade.color.a=1
  if escaped: _victory()
 )
func _save() -> bool:
 if "--benchmark" in OS.get_cmdline_user_args() or "--gallery" in OS.get_cmdline_user_args(): return true
 var p=actor.position
 var data={"version":1,"name":profile.name,"variant":int(profile.variant),"location":profile.location,"companion":companion_variant,"position":[p.x,p.y,p.z],"powered":powered,"escaped":escaped}
 var ok=Store.write_json(Store.SAVE,data)
 status="Checkpoint saved" if ok else "Could not save checkpoint. Check device storage."
 return ok
func _pause() -> void:
 if mode!="play": return
 mode="pause"; actor.velocity=Vector3.ZERO; _clear("Between moments", "Your journey waits here.")
 _button("Resume",func(): mode="play"; _play_ui())
 _button("Save checkpoint",func(): _save(); _pause_status())
 _button("Settings",func(): _settings(true))
 _button("Save & return to title",func():
  if _save(): _title()
  else: _pause_status()
 )
 _focus()
func _pause_status() -> void:
 mode="play"; _pause(); _label(status,16)
func _settings(from_pause: bool) -> void:
 mode="settings"; _clear("Settings","Changes are saved immediately on this device.")
 for key in ["master","music","ambience","sensitivity"]:
  _label(key.capitalize(),16,Art.BRASS)
  var slider=HSlider.new(); slider.min_value=.3 if key=="sensitivity" else 0.0; slider.max_value=2.5 if key=="sensitivity" else 1.0; slider.step=.05; slider.value=settings[key]; slider.custom_minimum_size.y=72 if mobile else 42; content.add_child(slider)
  slider.value_changed.connect(func(value): settings[key]=value; _apply_settings(); _save_settings())
 var quality=OptionButton.new(); quality.custom_minimum_size.y=76 if mobile else 54
 for item in ["Low / 30 FPS / 65% resolution","Balanced / mobile 30, PC 60 / 85%","High / PC 60 / full resolution"]: quality.add_item(item)
 quality.select(int(settings.quality)); content.add_child(quality)
 quality.item_selected.connect(func(value): settings.quality=value; _apply_settings(); _save_settings())
 for key in ["invert","reduced_motion","large_text","touch"]:
  var check=CheckButton.new(); check.text={"invert":"Invert vertical camera","reduced_motion":"Reduce camera motion","large_text":"Larger interface text","touch":"Show touch controls on PC"}[key]; check.button_pressed=settings[key]; check.custom_minimum_size.y=76 if mobile else 50; content.add_child(check)
  check.toggled.connect(func(value): settings[key]=value; _apply_settings(); _save_settings())
 _label("PC: WASD / arrows move · Mouse looks\nE interacts · Shift runs · Esc pauses\nTouch: left stick moves · right swipe looks\nTap the contextual button to interact.",16)
 _button("Back",func():
  if from_pause: mode="play"; _pause()
  else: _title()
 ); _focus()
func _save_settings() -> void:
 if not Store.write_json(Store.SETTINGS,settings): status="Settings could not be written to storage."
func _apply_settings() -> void:
 Engine.max_fps=30 if mobile or int(settings.quality)==0 else 60
 get_viewport().scaling_3d_scale=[.65,.85,1.0][int(settings.quality)]
 get_viewport().msaa_3d=Viewport.MSAA_DISABLED if int(settings.quality)==0 else Viewport.MSAA_2X
 touch.invert=settings.invert
 ui.theme.default_font_size=(24 if mobile else 20)+(4 if settings.large_text else 0)
 for label in content.get_children():
  if label is Label and label.has_meta("base_size"): label.add_theme_font_size_override("font_size",int(label.get_meta("base_size"))+(3 if settings.large_text else 0))
 if is_instance_valid(music): music.volume_db=linear_to_db(maxf(.0001,settings.master*settings.music))
 if is_instance_valid(ambience): ambience.volume_db=linear_to_db(maxf(.0001,settings.master*settings.ambience))
func _credits() -> void:
 _clear("Credits","ISOMET — The Quiet Between\nOriginal story and game concept: project creator\nPrototype code, procedural models and sound: developed with Codex\nEngine: Godot 4.5.2 (MIT)\nNo BioShock assets, characters, or music are used.")
 _button("Engine license",func(): OS.shell_open("https://godotengine.org/license/"))
 _button("Back",_title); _focus()
func _audio() -> void:
 # Original small looping PCM soundscapes; no third-party recordings.
 for kind in [0,1]:
  var stream=AudioStreamWAV.new(); stream.format=AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate=22050
  stream.loop_mode=AudioStreamWAV.LOOP_FORWARD; stream.loop_begin=0; stream.loop_end=22050*8
  var bytes=PackedByteArray(); bytes.resize(22050*8*2)
  for i in range(22050*8):
   var t=float(i)/22050; var sample=0.0
   if kind==0: sample=(sin(TAU*55*t)*.10+sin(TAU*82.5*t)*.035)*(0.7+0.3*sin(TAU*t/8))
   else: sample=(sin(TAU*110*t)+sin(TAU*165*t)*.6+sin(TAU*220*t)*.3)*.035*(.65+.35*cos(TAU*t/8))
   bytes.encode_s16(i*2,int(clampf(sample,-1,1)*32767))
  stream.data=bytes
  var audio=AudioStreamPlayer.new(); audio.stream=stream; add_child(audio); audio.play()
  if kind==0: ambience=audio
  else: music=audio
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  if mode=="play": _pause()
  elif mode=="pause": mode="play"; _play_ui()
 if mode=="play":
  if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
   yaw-=event.relative.x*.003*settings.sensitivity
   pitch=clampf(pitch-event.relative.y*.002*settings.sensitivity*(-1 if settings.invert else 1),-.65,.35)
  if event.is_action_pressed("interact"): _interact()
func _process(dt: float) -> void:
 elapsed+=dt
 if mode=="play":
  yaw-=touch.look.x*.003*settings.sensitivity; pitch=clampf(pitch-touch.look.y*.002*settings.sensitivity,-.65,.35); touch.look=Vector2.ZERO
  _position_camera(dt)
  var chamber="The First Silence" if actor.position.z> -6 else "The Last Interval"
  hud.text=profile.name+" / "+chamber+"\n"+("Find the violet escape portal." if powered else "Explore the observatory. Find the resonance console.")+"\n"+status
  prompt.text=_interaction_text(); prompt.visible=prompt.text!=""
  save_timer+=dt
  if save_timer>20: _save(); save_timer=0
 elif mode=="intro": _process_intro(dt)
 elif mode in ["title","create"]:
  if mode=="create": camera.position=Vector3(3.4,2.1,7); camera.look_at(actor.position+Vector3(0,1,0)); model.rotation.y=PI+PI/5
  else:
   camera.position=Vector3(2.6+sin(elapsed*.13)*(.0 if settings.reduced_motion else .22),2.8,5.0)
   camera.look_at(Vector3(0,1.4,-12))
 if is_instance_valid(portal_mesh):
  portal_mesh.material_override.set_shader_parameter("awake",powered)
  portal_mesh.material_override.set_shader_parameter("animate",not settings.reduced_motion)
  portal_mesh.scale.x=1.0 if settings.reduced_motion else 1.0+sin(elapsed*1.4)*.025
 if mode!="intro": fade.color.a=move_toward(fade.color.a,0,dt*1.8)
 if "--benchmark" in OS.get_cmdline_user_args() and not benchmark_finished:
  var now=Time.get_ticks_usec()
  if elapsed>2 and benchmark_last_usec>0: benchmark_samples.append((now-benchmark_last_usec)/1000.0)
  benchmark_last_usec=now
  if elapsed>32:
   benchmark_samples.sort()
   var mean=0.0
   for ms in benchmark_samples: mean+=ms
   mean/=maxi(1,benchmark_samples.size())
   var report={"platform":OS.get_name(),"gpu":RenderingServer.get_video_adapter_name(),"renderer":"Compatibility","logical_viewport":str(get_viewport().get_visible_rect().size),"output_pixels":str(get_viewport().get_texture().get_size()),"quality":int(settings.quality),"frames":benchmark_samples.size(),"mean_ms":mean,"p95_ms":benchmark_samples[int(benchmark_samples.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"triangles":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"mobile_certified":false}
   Store.write_json("user://benchmark.json",report); print("BENCHMARK ",JSON.stringify(report)); benchmark_finished=true; _quit_cleanly()
func _position_camera(dt: float, snap: bool=false) -> void:
 var target=actor.position+Vector3(0,1.3,0)
 var offset=Vector3(sin(yaw)*4.4,2.6-pitch*3,cos(yaw)*4.4)
 var desired=target+offset
 desired.x=clampf(desired.x,-5.3,5.3); desired.z=clampf(desired.z,-19.1,7.1)
 if not snap and not settings.reduced_motion: desired=camera.position.lerp(desired,1-exp(-dt*9))
 var query=PhysicsRayQueryParameters3D.create(target,desired,1,[actor.get_rid()])
 var hit=get_world_3d().direct_space_state.intersect_ray(query)
 camera.position=hit.position+(target-hit.position).normalized()*.3 if not hit.is_empty() else desired
 camera.look_at(target)
func _physics_process(dt: float) -> void:
 if mode!="play": return
 var input=Input.get_vector("left","right","forward","back")+touch.move
 input=input.limit_length(1)
 var direction=Vector3(input.x,0,input.y).rotated(Vector3.UP,yaw)
 if "--benchmark" in OS.get_cmdline_user_args():
  var target: Vector3=benchmark_path[benchmark_step]
  var delta=target-actor.position; delta.y=0
  if delta.length()<.35: benchmark_step=(benchmark_step+1)%benchmark_path.size()
  direction=delta.normalized()
 actor.velocity.x=direction.x*(4.5 if Input.is_action_pressed("run") else 3)
 actor.velocity.z=direction.z*(4.5 if Input.is_action_pressed("run") else 3)
 actor.velocity.y-=12*dt; actor.move_and_slide()
 if direction.length()>.1:
  model.rotation.y=lerp_angle(model.rotation.y,atan2(-direction.x,-direction.z),.2)
  body_bob+=dt*10; model.position.y=0 if settings.reduced_motion else sin(body_bob)*.025
 if actor.position.y < -3: actor.position=Vector3(0,.1,2); actor.velocity=Vector3.ZERO
func _interaction_text() -> String:
 var prefix="" if mobile or settings.touch else "[E] "
 if actor.position.distance_to(Vector3(-3,0,-3))<2.0: return prefix+("Read resonance console" if powered else "Attune resonance")
 if actor.position.distance_to(Vector3(0,0,-18))<2.4: return prefix+"Enter the escape" if powered else "The threshold is silent"
 return ""
func _interact() -> void:
 if mode!="play": return
 if actor.position.distance_to(Vector3(-3,0,-3))<2:
  powered=true; _save(); mode="note"; _clear("A voice in the static","A familiar voice. A dog's bark.\n\n“We are still here. Follow the violet light.”\n\nThe resonance wakes the final threshold. Somewhere beyond it, your loved ones are waiting.")
  _button("Follow the signal",func(): mode="play"; _play_ui()); _focus()
 elif powered and actor.position.distance_to(Vector3(0,0,-18))<2.4:
  escaped=true; _save(); _victory()
 elif actor.position.distance_to(Vector3(0,0,-18))<2.4:
  status="A resonance console can wake this threshold."
func _victory() -> void:
 mode="victory"; _clear("The void releases you","You found the escape.\n\nThis is the end of the 3D vertical slice. The full maze and the search for your loved ones continue in the original prototype's story.")
 _button("Return to title",_title); _focus()
func _process_intro(dt: float) -> void:
 intro_time+=dt
 reaction.visible=intro_time>5 and intro_time<7
 var destination=Vector3(2,1.3,-1.6) if profile.location!="Midwest" else Vector3(2,0,-2)
 var n=smoothstep(3,5,intro_time); var d=smoothstep(4,6,intro_time); var chase=smoothstep(7,9,intro_time)
 companion.position=Vector3(-.5,0,-.6).lerp(destination,n); companion.scale=Vector3.ONE*maxf(.001,1-n)
 dog.position=Vector3(.7,0,.8).lerp(destination,d); dog.scale=Vector3.ONE*maxf(.001,1-d)
 actor.position=Vector3(-2,0,1).lerp(destination,chase)
 if intro_time>5 and intro_time<7: actor.position.y+=abs(sin(intro_time*10))*.25
 actor.scale=Vector3.ONE*maxf(.001,1-chase)
 camera.position=Vector3(6,4.5,8); camera.look_at(Vector3(0,1,0))
 var text="An ordinary evening. Someone you love. Your dog, close by."
 if intro_time>3: text="The "+{"City":"television","Suburb":"mirror","Midwest":"puddle"}[profile.location]+" opens into the void."
 if intro_time>5: text="!!!  No! Wait!"
 if intro_time>7: text="You follow them into the quiet between."
 hud.text=profile.location.to_upper()+" / BEFORE THE SILENCE\n\n"+text
 fade.color.a=maxf(1-clampf(intro_time,0,1),smoothstep(9,10.3,intro_time))
 if intro_time>10.3: actor.scale=Vector3.ONE; _begin_play()
func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_PAUSED:
  if mode=="play": _save(); _pause()
  if is_instance_valid(music): music.stream_paused=true
  if is_instance_valid(ambience): ambience.stream_paused=true
 if what==NOTIFICATION_APPLICATION_RESUMED:
  if is_instance_valid(music): music.stream_paused=false
  if is_instance_valid(ambience): ambience.stream_paused=false
 if what==NOTIFICATION_WM_CLOSE_REQUEST:
  if mode=="play": _save()
  _quit_cleanly()
func _smoke() -> void:
 await get_tree().process_frame
 assert(not Store.valid_save({}))
 profile={"name":"Mira","variant":5,"location":"Suburb"}; _replace_model(); _intro()
 intro_time=10.4; _process_intro(.01)
 assert(mode=="play" and actor.scale==Vector3.ONE)
 powered=true; actor.position=Vector3(-2,.05,-3); assert(_save())
 var record=Store.read_json(Store.SAVE); assert(Store.valid_save(record)); assert(record.name=="Mira" and record.powered)
 _title(); assert(mode=="title")
 _continue()
 await get_tree().process_frame; await get_tree().process_frame; await get_tree().process_frame
 assert(mode=="play" and powered)
 _pause(); assert(mode=="pause")
 _settings(true); assert(mode=="settings")
 mode="play"; actor.position=Vector3(0,.05,-18); _interact(); assert(escaped and mode=="victory")
 for location in ["City","Suburb","Midwest"]:
  profile.location=location; _intro(); assert(companion_variant<4 and int(profile.variant)>=4)
  intro_time=6; _process_intro(.01); assert(hud.text.contains("!!!"))
 actor.scale=Vector3.ONE; home.hide(); world.show()
 _title(); fade.color.a=0
 await get_tree().process_frame; await get_tree().process_frame
 if DisplayServer.get_name()!="headless": get_viewport().get_texture().get_image().save_png("user://title.png")
 print("SMOKE PASS: creation, intro, checkpoint round trip, continue, pause and settings")
 _quit_cleanly()

func _capture(filename: String) -> void:
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("user://"+filename+".png")
func _gallery() -> void:
 _title(); fade.color.a=0; await _capture("preview_title")
 _creation(); await _capture("preview_creation")
 profile={"name":"Mira","variant":5,"location":"City"}; _replace_model()
 for place in ["City","Suburb","Midwest"]:
  profile.location=place; _intro(); intro_time=6; _process_intro(.01); fade.color.a=0
  await _capture("preview_intro_"+place)
 actor.scale=Vector3.ONE; _begin_play(); powered=true; fade.color.a=0
 _position_camera(0,true)
 await _capture("preview_gameplay")
 _pause(); _settings(true); await _capture("preview_settings")
 get_window().content_scale_size=Vector2i(800,600); _safe_area(); _title(); fade.color.a=0
 await _capture("preview_small_title")
 mobile=true; get_window().content_scale_size=Vector2i(1280,600); _safe_area(); _title(); fade.color.a=0
 await _capture("preview_mobile_ui")
 print("GALLERY PASS"); _quit_cleanly()

func _exit_tree() -> void:
 if is_instance_valid(music): music.stop(); music.stream=null
 if is_instance_valid(ambience): ambience.stop(); ambience.stream=null
 Art.materials.clear()

func _quit_cleanly() -> void:
 if quitting: return
 quitting=true; mode="shutdown"
 if is_instance_valid(music): music.stop()
 if is_instance_valid(ambience): ambience.stop()
 await get_tree().create_timer(.12).timeout
 get_tree().quit()
