# Adapted from the rectpack Python library by secnot
# GitHub: https://github.com/secnot/rectpack
# License: Apache License 2.0

var data: Variant
var pos: Vector2i
var rotated: bool
var size: Vector2i


func _init(data: Variant, size: Vector2i) -> void:
  self.data = data
  self.size = size
