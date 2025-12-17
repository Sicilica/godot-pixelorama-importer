# Adapted from the rectpack Python library by secnot
# GitHub: https://github.com/secnot/rectpack
# License: Apache License 2.0

const PackingAlgorithm = preload("pack_algo.gd")
const Rect = preload("rect.gd")


var rectangles: Array[Rect] = []


var _pack_algo: PackingAlgorithm
var _size: Vector2i


var size: Vector2i:
  get: return _size


func _init(size: Vector2i, pack_algo: PackingAlgorithm) -> void:
  _size = size
  _pack_algo = pack_algo


func _add_rect(rect: Rect) -> void:
  rectangles.append(rect)
