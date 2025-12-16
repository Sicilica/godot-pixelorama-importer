# Adapted from the rectpack Python library by secnot
# GitHub: https://github.com/secnot/rectpack
# License: Apache License 2.0

# online/offline, bin algo, pack algo, sort algo, allow rotation
# reference uses GuillotineBssfSas without rotations, and otherwise default
# that means offline mode, bin algo is BBF, sort algo is area
# 
# we end up calling PackerBBF and passing it the pack/sort/rotation
# PackerBBF does nothing but mixes in packer and packerbbfmixin
# mixin adds an add_rect implementation
# 
# anyway, after creating it, we call add_bin to add just 1 bin (with sizes we figured out)
# then we add_rect for each sprite
# then we pack


const Bin = preload("types/bin.gd")
const PackingProvider = preload("types/pack_algo.gd")
const Rect = preload("types/rect.gd")

const Guillotine = preload("guillotine.gd")


enum BinningAlgorithm {
  BinBestFit,
}

enum PackingAlgorithm {
  GuillotineBssfSas,
}

enum SortingAlgorithm {
  Area,
}


class PackerOnline:
  var _allow_rotation: bool
  var _bin_algo: BinningAlgorithm
  var _pack_algo: PackingAlgorithm

  var _closed_bins: Array[Bin] = []
  var _empty_bins: Array[Bin] = []
  var _open_bins: Array[Bin] = []


  func _init(bin_algo: BinningAlgorithm, pack_algo: PackingAlgorithm, allow_rotation: bool) -> void:
    _bin_algo = bin_algo
    _pack_algo = pack_algo
    _allow_rotation = allow_rotation
    reset()


  var bin_count: int:
    get: return _closed_bins.size() + _open_bins.size()

  func get_bin(index: int) -> Bin:
    if index < 0:
      index += bin_count
    
    if index < 0 || index >= bin_count:
      push_error("Bin index out of range")
      return null
    
    if index < _closed_bins.size():
      return _closed_bins[index]
    else:
      return _open_bins[index - _closed_bins.size()]

  func add_bin(size: Vector2i) -> void:
    _empty_bins.append(Bin.new(size, _new_pack_algo(size)))

  func add_rect(size: Vector2i, data: Variant) -> bool:
    var bin := _choose_bin(size)
    if bin == null:
      return false

    var rect := bin._pack_algo.add_rect(Rect.new(data, size))
    if rect == null:
      return false

    bin._add_rect(rect)
    return true

  func reset() -> void:
    _closed_bins.clear()
    _empty_bins.clear()
    _open_bins.clear()


  func _choose_bin(rect_size: Vector2i) -> Bin:
    match _bin_algo:
      BinningAlgorithm.BinBestFit:
        return _choose_bin_bbf(rect_size)
      _:
        assert(false)
        return null

  ## BBF (Bin Best Fit): Pack rectangle in bin that gives best fitness
  func _choose_bin_bbf(rect_size: Vector2i) -> Bin:
    # Try packing into open bins
    var bestBin: Bin
    var bestFitness := -1
    for bin in _open_bins:
      var fit := bin._pack_algo.fitness(rect_size)
      if fit < 0:
        continue
      if fit < bestFitness || bestBin == null:
        bestFitness = fit
        bestBin = bin
    if bestBin != null:
      return bestBin

    # Try packing into one of the empty bins
    return _new_open_bin(rect_size)

  
  func _new_open_bin(size: Vector2i) -> Bin:
    for bin in _empty_bins:
      if bin._size.x >= size.x && bin._size.y >= size.y:
        _empty_bins.erase(bin)
        _open_bins.append(bin)
        return bin
    return null


  func _new_pack_algo(size: Vector2i) -> PackingProvider:
    match _pack_algo:
      PackingAlgorithm.GuillotineBssfSas:
        return Guillotine.new(size, Guillotine.Selection.BestSideShortFit, Guillotine.Splitting.ShortAxisSplit, _allow_rotation)
      _:
        assert(false)
        return null


class Packer extends PackerOnline:
  var _sort_algo: SortingAlgorithm

  var _avail_bins: Array[Vector2i] = []
  var _avail_rects: Array[Rect] = []


  func _init(bin_algo: BinningAlgorithm, pack_algo: PackingAlgorithm, sort_algo: SortingAlgorithm, allow_rotation: bool) -> void:
    super (bin_algo, pack_algo, allow_rotation)
    _sort_algo = sort_algo


  func add_bin(size: Vector2i) -> void:
    _avail_bins.append(size)


  func add_rect(size: Vector2i, data: Variant) -> bool:
    _avail_rects.append(Rect.new(data, size))
    return true


  func pack() -> bool:
    super.reset()

    for bin in _avail_bins:
      super.add_bin(bin)

    _avail_rects.sort_custom(_sort_fn())

    var all_added := true
    for rect in _avail_rects:
      if not super.add_rect(rect.size, rect.data):
        all_added = false
    return all_added
  

  func reset() -> void:
    super.reset()
    _avail_bins.clear()
    _avail_rects.clear()


  func _sort_fn() -> Callable:
    match _sort_algo:
      SortingAlgorithm.Area:
        return func(a: Rect, b: Rect) -> bool:
          return (a.size.x * a.size.y) > (b.size.x * b.size.y)
      _:
        assert(false)
        return func(a: Rect, b: Rect) -> bool:
          return false
