var fps: float
var frames: Array[Frame]
var layers: Array[Layer]
var pxo_version: int
var size: Vector2
var tags: Array[Tag]


func load(bytes: PackedByteArray) -> Error:
  if bytes.is_empty():
    push_error("Failed to parse Pixelorama project data")
    return ERR_FILE_CORRUPT

  var json := JSON.new()
  var err := json.parse(bytes.get_string_from_utf8())
  if err != OK:
    return err
  
  if typeof(json.data) != TYPE_DICTIONARY:
    push_error("Failed to parse Pixelorama project data")
    return ERR_INVALID_DATA
  
  pxo_version = _parse_int(json.data.pxo_version, "pxo_version")
  if _parse_error != OK:
    return _parse_error

  match pxo_version:
    5:
      return _load_v5(json.data)
    _:
      push_error("Unsupported Pixelorama project version (%d)" % [pxo_version])
      return ERR_INVALID_DATA


class Frame:
  var duration: float


class Layer:
  var name: String


class Tag:
  var name: String
  var from: int
  var to: int


var _parse_error: Error


func _load_v5(data: Dictionary) -> Error:
  size.x = _parse_float(data.size_x, "size_x")
  if _parse_error != OK:
    return _parse_error
  size.y = _parse_float(data.size_y, "size_y")
  if _parse_error != OK:
    return _parse_error

  fps = _parse_float(data.fps, "fps")
  if _parse_error != OK:
    return _parse_error

  frames.assign(_parse_array(data.frames, "frames", _parse_frame_v5))
  if _parse_error != OK:
    return _parse_error

  layers.assign(_parse_array(data.layers, "layers", _parse_layer_v5))
  if _parse_error != OK:
    return _parse_error

  tags.assign(_parse_array(data.tags, "tags", _parse_tag_v5))
  if _parse_error != OK:
    return _parse_error

  return OK

func _parse_frame_v5(v: Variant) -> Frame:
  var frame := Frame.new()

  var data := _parse_dictionary(v, "frames[]")
  if _parse_error != OK:
    return frame

  frame.duration = _parse_float(data.duration, "frames[].duration")
  if _parse_error != OK:
    return frame
  
  return frame

func _parse_layer_v5(v: Variant) -> Layer:
  var layer := Layer.new()

  var data := _parse_dictionary(v, "layers[]")
  if _parse_error != OK:
    return layer

  layer.name = _parse_string(data.name, "layers[].name")
  if _parse_error != OK:
    return layer
  
  return layer

func _parse_tag_v5(v: Variant) -> Tag:
  var tag := Tag.new()

  var data := _parse_dictionary(v, "tags[]")
  if _parse_error != OK:
    return tag

  tag.name = _parse_string(data.name, "tags[].name")
  if _parse_error != OK:
    return tag

  tag.from = _parse_int(data.from, "tags[].from") - 1
  if _parse_error != OK:
    return tag

  tag.to = _parse_int(data.to, "tags[].to") - 1
  if _parse_error != OK:
    return tag
  
  if tag.from < 0 || tag.to < 0 || tag.from > tag.to:
    _error(ERR_INVALID_DATA, "Parse error: invalid tag frames")
    return tag

  return tag


func _parse_array(v: Variant, label: String, parse_func: Callable) -> Array:
  if typeof(v) != TYPE_ARRAY:
    _error(ERR_INVALID_DATA, "Parse error: %s is not an array" % [label])
    return []
  var array: Array = []
  for i in v.size():
    array.append(parse_func.call(v[i]))
    if _parse_error != OK:
      _error(ERR_INVALID_DATA, "Parse error: error while parsing %s[%d]" % [label, i])
      return []
  return array

func _parse_dictionary(v: Variant, label: String) -> Dictionary:
  if typeof(v) != TYPE_DICTIONARY:
    _error(ERR_INVALID_DATA, "Parse error: %s is not a dictionary" % [label])
    return {}
  return v

func _parse_float(v: Variant, label: String) -> float:
  if typeof(v) != TYPE_FLOAT:
    _error(ERR_INVALID_DATA, "Parse error: %s is not a float" % [label])
    return 0.0
  return v

func _parse_int(v: Variant, label: String) -> int:
  var float_val := _parse_float(v, label)
  if _parse_error == OK && float_val != floor(float_val):
    _error(ERR_INVALID_DATA, "Parse error: %s is not an integer" % [label])
  return int(float_val)

func _parse_string(v: Variant, label: String) -> String:
  if typeof(v) != TYPE_STRING:
    _error(ERR_INVALID_DATA, "Parse error: %s is not a string" % [label])
    return ""
  return v


func _error(err: Error, msg: String) -> void:
  push_error(msg)
  _parse_error = err
