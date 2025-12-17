# Adapted from the rectpack Python library by secnot
# GitHub: https://github.com/secnot/rectpack
# License: Apache License 2.0

const Rect = preload("rect.gd")


var _allow_rotation: bool
var _size: Vector2i

func _init(size: Vector2i, allow_rotation: bool) -> void:
  _size = size
  _allow_rotation = allow_rotation


func add_rect(rect: Rect) -> Rect:
  push_error("not implemented")
  assert(false)
  return null


func fitness(size: Vector2i) -> int:
  push_error("not implemented")
  assert(false)
  return 0
