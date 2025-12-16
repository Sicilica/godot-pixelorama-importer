const rectpack = preload("rectpack/packer.gd")


# Enable this to view the packed texture atlases
const DEBUG = false


## Given an array of images, packs them all into a single texture
## and returns AtlasTextures corresponding to each image.
##
## It is legal to pass null images, in which case they will be mapped to
## null textures.
static func pack_images(images: Array[Image]) -> Array[Texture2D]:
  # Trim and deduplicate images, and prepare metadata
  var packed_images_by_hash: Dictionary = {}
  var packed_images: Array[PackedImage] = []
  packed_images.resize(images.size())
  for i in images.size():
    if images[i] == null:
      continue
    var packed := PackedImage.new(images[i], i)
    if packed_images_by_hash.has(packed._hash):
      packed = packed_images_by_hash[packed._hash]
      packed.indices.append(i)
    else:
      packed_images_by_hash[packed._hash] = packed
      packed_images[i] = packed

  # Calculate initial size
  var total_area := 0
  var total_width := 0
  var total_height := 0
  for image in packed_images:
    if image == null:
      continue
    total_area += image.size.x * image.size.y
    total_width += image.size.x
    total_height += image.size.y
  # Pick the smallest power of 2 that gives us a big enough square
  var size := pow(2, ceil(log(sqrt(total_area)) / log(2)))
  # If our initial size is more than twice the size we need, we can try halving it
  var half_size := (size * size) > total_area * 2
  # When we halve the canvas, we should look to our images to tell us which way to cut it
  var prefer_wide := total_width >= total_height

  # Pack images
  var packer := rectpack.Packer.new(
    rectpack.BinningAlgorithm.BinBestFit,
    rectpack.PackingAlgorithm.GuillotineBssfSas,
    rectpack.SortingAlgorithm.Area,
    false
  )
  while true:
    # TODO: remove this assert, and start splitting bins once the texture gets too big
    assert(size <= 16384)
    packer.reset()

    var bin_size := Vector2i(size, size)
    if half_size:
      if prefer_wide:
        bin_size.y /= 2
      else:
        bin_size.x /= 2
    packer.add_bin(bin_size)

    for entry in packed_images:
      if entry == null:
        continue
      packer.add_rect(entry.size, entry)
    
    if packer.pack():
      break

    if half_size:
      half_size = false
    else:
      size *= 2
      half_size = true
  
  # Make atlas textures and generate output mappings
  var out: Array[Texture2D] = []
  out.resize(images.size())
  for bin_idx in packer.bin_count:
    var bin := packer.get_bin(bin_idx)

    var image := Image.create(bin.size.x, bin.size.y, false, Image.FORMAT_RGBA8)
    for rect in bin.rectangles:
      assert(not rect.rotated)
      var rect_data: PackedImage = rect.data
      image.blit_rect(rect_data.image, Rect2i(0, 0, rect.size.x, rect.size.y), rect.pos)

    # Draw debug data for unpacked sections
    if DEBUG:
      for section in bin._pack_algo._sections:
        if section.size.x >= 2 && section.size.y >= 2:
          image.fill_rect(Rect2i(section.pos.x + 1, section.pos.y + 1, section.size.x - 2, section.size.y - 2), Color.HOT_PINK)

    var texture := ImageTexture.create_from_image(image)

    for rect in bin.rectangles:
      var rect_data: PackedImage = rect.data

      var frame_texture: Texture2D
      if DEBUG:
        frame_texture = texture
      else:
        frame_texture = AtlasTexture.new()
        frame_texture.atlas = texture
        frame_texture.filter_clip = true
        frame_texture.region = Rect2i(rect.pos.x, rect.pos.y, rect.size.x, rect.size.y)
        frame_texture.margin = rect_data.margin

      for i in rect.data.indices:
        out[i] = frame_texture

  return out


class PackedImage:
  var _hash: int
  var image: Image
  var indices: Array[int]
  var margin: Rect2i
  var size: Vector2i

  func _init(image: Image, index: int) -> void:
    indices = [index]

    var original_size := image.get_size()
    var used_rect := image.get_used_rect()
    self.image = image.get_region(used_rect)
    size = used_rect.size
    margin = Rect2i(used_rect.position, original_size - size)
    _hash = hash(image.get_data())
