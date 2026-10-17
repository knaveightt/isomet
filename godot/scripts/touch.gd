extends Control
var move := Vector2.ZERO
var look := Vector2.ZERO
var left_id := -1
var right_id := -1
var origin := Vector2.ZERO
var thumb := Vector2.ZERO
var invert := false
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
func _input(event: InputEvent) -> void:
 if not visible: return
 if event is InputEventScreenTouch:
  if event.pressed:
   if event.position.x < size.x*.42 and left_id == -1:
    left_id=event.index; origin=event.position; thumb=origin
   elif event.position.x > size.x*.55 and right_id == -1 and event.position.y < size.y-120:
    right_id=event.index
  else:
   if event.index==left_id: left_id=-1; move=Vector2.ZERO
   if event.index==right_id: right_id=-1
 elif event is InputEventScreenDrag:
  if event.index==left_id:
   var offset: Vector2 = (event.position-origin).limit_length(65)
   thumb=origin+offset; move=offset/65.0
  elif event.index==right_id:
   look += event.relative * Vector2(1,-1 if invert else 1)
 queue_redraw()
func reset() -> void:
 left_id=-1; right_id=-1; move=Vector2.ZERO; look=Vector2.ZERO; queue_redraw()
func _draw() -> void:
 var center = origin if left_id!=-1 else Vector2(130,size.y-140)
 draw_circle(center,70,Color(.08,.16,.20,.65))
 draw_arc(center,70,0,TAU,48,Color(.65,.77,.72,.6),2)
 draw_circle(thumb if left_id!=-1 else center,26,Color(.73,.62,.36,.7))
