extends RefCounted
const BRASS = Color("b5985b")
const STONE = Color("a0acaa")
const TEAL = Color("163e46")
const DARK = Color("0b202d")
const CYAN = Color("65ddd0")
const VIOLET = Color("9474ed")
static var materials: Dictionary = {}
static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
 var key = str(color) + str(glow)
 if materials.has(key): return materials[key]
 var m = StandardMaterial3D.new()
 m.albedo_color = color
 m.roughness = 0.68
 if color == BRASS: m.metallic = 0.65; m.roughness = 0.32
 if glow > 0:
  m.emission_enabled = true; m.emission = color; m.emission_energy_multiplier = glow
 materials[key] = m
 return m
static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false, glow: float = 0.0) -> MeshInstance3D:
 var mesh = MeshInstance3D.new()
 var shape = BoxMesh.new(); shape.size = size
 mesh.mesh = shape; mesh.material_override = material(color, glow)
 parent.add_child(mesh); mesh.position = pos
 if solid:
  var body = StaticBody3D.new(); var collider = CollisionShape3D.new(); var bounds = BoxShape3D.new()
  bounds.size = size; collider.shape = bounds; body.add_child(collider); mesh.add_child(body)
 return mesh
static func sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
 var m = MeshInstance3D.new(); var s = SphereMesh.new()
 s.radius = radius; s.height = radius * 2; s.radial_segments = 12; s.rings = 6
 m.mesh = s; m.material_override = material(color); parent.add_child(m); m.position = pos
 return m
static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
 var m = MeshInstance3D.new(); var c = CylinderMesh.new()
 c.top_radius = radius; c.bottom_radius = radius; c.height = height; c.radial_segments = 12
 m.mesh = c; m.material_override = material(color); parent.add_child(m); m.position = pos
 return m
static func label(parent: Node3D, text: String, pos: Vector3, size: int = 34, color: Color = BRASS) -> Label3D:
 var l = Label3D.new(); l.text = text; l.font_size = size; l.pixel_size = 0.007
 l.modulate = color; l.outline_size = 3; parent.add_child(l); l.position = pos
 return l
static func person(parent: Node3D, variant: int) -> Node3D:
 var root = Node3D.new(); parent.add_child(root)
 var skins = [Color("efb985"),Color("c27e52"),Color("754732"),Color("4a2c24")]
 var clothes = [Color("478b9c"),Color("b34e48"),Color("427f60"),Color("8564ad")]
 var index = variant % 4; var skin: Color = skins[index]; var cloth: Color = clothes[index]
 var hair = Color("34283a") if index != 3 else Color("c9bda6")
 cylinder(root, Vector3(0,0.91,0),0.24,0.66,cloth)
 if variant >= 4:
  var skirt = cylinder(root,Vector3(0,0.66,0),.29,.28,cloth)
  skirt.scale.z = .8
 for x in [-.12,.12]:
  box(root,Vector3(x,.28,0),Vector3(.15,.5,.18),DARK)
  box(root,Vector3(x,.08,-.06),Vector3(.19,.16,.31),Color("302c39"))
 for x in [-.31,.31]:
  box(root,Vector3(x,.98,0),Vector3(.15,.43,.18),cloth)
  sphere(root,Vector3(x,.73,0),.09,skin)
 sphere(root,Vector3(0,1.48,0),.235,skin)
 sphere(root,Vector3(0,1.61,.035),.235,hair).scale.y = .55
 if variant >= 4: box(root,Vector3(0,1.43,.16),Vector3(.41,.35,.14),hair)
 for x in [-.08,.08]: sphere(root,Vector3(x,1.50,-.214),.023,DARK)
 box(root,Vector3(0,1.16,-.23),Vector3(.09,.16,.025),BRASS)
 box(root,Vector3(0,.76,-.02),Vector3(.47,.055,.43),BRASS)
 return root
static func dog(parent: Node3D) -> Node3D:
 var root = Node3D.new(); parent.add_child(root)
 box(root,Vector3(0,.35,0),Vector3(.32,.28,.6),Color("ad784b"))
 sphere(root,Vector3(0,.57,-.3),.19,Color("cf9c68"))
 for x in [-.12,.12]:
  box(root,Vector3(x,.1,-.2),Vector3(.08,.25,.09),DARK)
  box(root,Vector3(x,.1,.2),Vector3(.08,.25,.09),DARK)
  box(root,Vector3(x,.58,-.26),Vector3(.09,.27,.1),Color("6b4939"))
 sphere(root,Vector3(0,.55,-.48),.065,DARK)
 var tail = box(root,Vector3(0,.5,.39),Vector3(.07,.33,.07),Color("ad784b")); tail.rotation.x = .7
 return root
static func arch(parent: Node3D, z: float) -> void:
 for x in [-1.5,1.5]:
  box(parent,Vector3(x,1.7,z),Vector3(.38,3.4,.6),TEAL,true)
  box(parent,Vector3(x,1.7,z-.32),Vector3(.08,3.15,.035),BRASS)
 for n in range(3):
  box(parent,Vector3(0,3.2+n*.18,z),Vector3(3.4-n*.36,.18,.6),BRASS)
 box(parent,Vector3(0,3.05,z-.32),Vector3(2.8,.045,.04),CYAN,false,1.5)

# Merge static render geometry by material once. Keep physics bodies independent.
# This lowers the compatibility renderer's draw count without changing gameplay.
static func batch_static(parent: Node3D) -> void:
 var groups: Dictionary = {}
 var sources: Array[MeshInstance3D] = []
 for child in parent.get_children():
  if child is MeshInstance3D and child.mesh is PrimitiveMesh:
   var mat=child.material_override
   if not groups.has(mat):
    var surface=SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES); groups[mat]=surface
   groups[mat].append_from(child.mesh,0,child.transform)
   sources.append(child)
 for mesh in sources:
  for body in mesh.get_children():
   if body is StaticBody3D: body.reparent(parent,true)
  mesh.free()
 for mat in groups:
  var merged=MeshInstance3D.new(); merged.mesh=groups[mat].commit(); merged.material_override=mat; parent.add_child(merged)
