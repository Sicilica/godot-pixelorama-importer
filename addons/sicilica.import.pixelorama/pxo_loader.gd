const PXOData = preload("pxo/pxo_data.gd")
const TexturePacker = preload("pack/texture_packer.gd")


var data: SpriteFrames:
  get: return _imported


var _data: PXOData
var _imported: SpriteFrames
var _options: Options
var _textures: Variant


func _init(options: Dictionary) -> void:
  _options = Options.new(options)


class Options:
  var include_default_animation := true
  var separate_layers := false

  func _init(dict: Dictionary) -> void:
    if dict.has("include_default_animation"):
      var val = dict["include_default_animation"]
      if typeof(val) == TYPE_BOOL:
        include_default_animation = val

    if dict.has("separate_layers"):
      var val = dict["separate_layers"]
      if typeof(val) == TYPE_BOOL:
        separate_layers = val


func load(path: String) -> Error:
  var reader := ZIPReader.new()
  var err := reader.open(path)
  if err != OK:
    push_error("Could not open Pixelorama project")
    return err

  err = _load(reader)
  reader.close()
  if err != OK:
    _imported = null
    return err

  return OK


func _load(reader: ZIPReader) -> Error:
  var err := _load_data(reader)
  if err != OK:
    return err

  err = _post_process_data()
  if err != OK:
    return err

  err = _load_textures(reader)
  if err != OK:
    return err

  _imported = SpriteFrames.new()
  _imported.remove_animation("default")

  if _options.separate_layers:
    for layer_idx in _data.layers.size():
      var layer_name := _data.layers[layer_idx].name
      for tag in _data.tags:
        var anim_name := "%s:%s" % [layer_name, tag.name]
        _imported.add_animation(anim_name)
        _imported.set_animation_speed(anim_name, _data.fps)
        _imported.set_animation_loop(anim_name, true)
        for i in range(tag.from, tag.to + 1):
          _imported.add_frame(anim_name, _textures[layer_idx][i], _data.frames[i].duration)
  else:
    for tag in _data.tags:
      var anim_name := tag.name
      _imported.add_animation(anim_name)
      _imported.set_animation_speed(anim_name, _data.fps)
      _imported.set_animation_loop(anim_name, true)
      for i in range(tag.from, tag.to + 1):
        _imported.add_frame(anim_name, _textures[i], _data.frames[i].duration)

  return OK


func _load_data(reader: ZIPReader) -> Error:
  var raw := reader.read_file("data.json")
  if raw.is_empty():
    push_error("File is not a Pixelorama project")
    return ERR_FILE_UNRECOGNIZED


  _data = PXOData.new()
  var err := _data.load(raw)
  if err != OK:
    push_error("Failed to parse Pixelorama project data")
    return ERR_FILE_CORRUPT

  return OK

func _post_process_data() -> Error:
  if _data.frames.size() <= 0:
    push_error("Pixelorama project contains no frames")
    return ERR_INVALID_DATA

  if _options.include_default_animation:
    var has_default_tag := false
    for tag in _data.tags:
      if tag.name == "default":
        has_default_tag = true
        break
    if !has_default_tag:
      var tag := PXOData.Tag.new()
      tag.name = "default"
      tag.from = 0
      tag.to = _data.frames.size() - 1
      _data.tags.append(tag)

  return OK


func _load_textures(reader: ZIPReader) -> Error:
  var used_frames := BitMap.new()
  used_frames.create(Vector2i(_data.frames.size(), 1))
  for tag in _data.tags:
    for i in range(tag.from, tag.to + 1):
      used_frames.set_bit(i, 0, true)

  if _options.separate_layers:
    _textures = []
    _textures.resize(_data.layers.size())
    for layer_idx in _data.layers.size():
      var layer_images: Array[Image] = []
      layer_images.resize(_data.frames.size())
      for frame_idx in _data.frames.size():
        if used_frames.get_bit(frame_idx, 0):
          layer_images[frame_idx] = _load_cel(reader, frame_idx, layer_idx)

      _textures[layer_idx] = TexturePacker.pack_images(layer_images)
  else:
    var images: Array[Image] = []
    images.resize(_data.frames.size())
    for frame_idx in _data.frames.size():
      if used_frames.get_bit(frame_idx, 0):
        images[frame_idx] = _load_or_render_frame(reader, frame_idx)
    _textures = TexturePacker.pack_images(images)
  
  return OK

func _load_cel(reader: ZIPReader, frame_idx: int, layer_idx: int) -> Image:
  var image_data := reader.read_file("image_data/frames/%d/layer_%d" % [frame_idx + 1, layer_idx + 1])
  if image_data.is_empty():
    push_warning("Missing cel image data for frame %d layer %s" % [frame_idx, _data.layers[layer_idx].name])
    return null
  return Image.create_from_data(_data.size.x, _data.size.y, false, Image.FORMAT_RGBA8, image_data)

func _load_or_render_frame(reader: ZIPReader, frame_idx: int) -> Image:
  var image_data := reader.read_file("image_data/final_images/%d" % [frame_idx + 1])
  if image_data.is_empty():
    push_warning("Missing blended image data for frame %d" % [frame_idx])
    return _render_blended_frame(reader, frame_idx)
  return Image.create_from_data(_data.size.x, _data.size.y, false, Image.FORMAT_RGBA8, image_data)

func _render_blended_frame(reader: ZIPReader, frame_idx: int) -> Image:
  var img := Image.create(_data.size.x, _data.size.y, false, Image.FORMAT_RGBA8)
  var all_missing := true

  for layer_idx in _data.layers.size():
    var cel := _load_cel(reader, frame_idx, layer_idx)
    if cel != null:
      all_missing = false
      img.blend_rect(cel, Rect2i(0, 0, _data.size.x, _data.size.y), Vector2i(0, 0))

  if all_missing:
    return null
  return img
