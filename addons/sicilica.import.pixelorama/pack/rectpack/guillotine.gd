# Adapted from the rectpack Python library by secnot
# GitHub: https://github.com/secnot/rectpack
# License: Apache License 2.0
#
# The Guillotine packing algorithm comes from:
# Jukka Jylanki - A Thousand Ways to Pack the Bin (February 27, 2010)

extends "types/pack_algo.gd"


enum Selection {
  BestSideShortFit,
}

enum Splitting {
  ShortAxisSplit,
}


var _selection: Selection
var _splitting: Splitting

var _sections: Array[Section] = []


func _init(size: Vector2i, selection: Selection, splitting: Splitting, allow_rotation: bool) -> void:
  super (size, allow_rotation)
  _selection = selection
  _splitting = splitting
  _sections.append(Section.new(0, 0, size.x, size.y))


func add_rect(rect: Rect) -> Rect:
  var section := _select_fittest_section(rect.size)
  if section == null:
    return null
  
  var rotated := _fittest_section_rotated
  if rect.rotated:
    var tmp := rect.size.x
    rect.size.x = rect.size.y
    rect.size.y = tmp

  _split(section, rect.size)

  rect.pos = section.pos
  return rect


## In guillotine algorithm case, returns the min of the fitness of all 
## free sections, for the given dimension, both normal and rotated
## (if rotation enabled.)
func fitness(size: Vector2i) -> int:
  assert(size.x > 0 && size.y > 0)

  # Get best fitness section.
  var section := _select_fittest_section(size)
  if section == null:
    return -1

  return _fittest_section_fitness


class Section:
  var _bounds: Rect2i

  var pos: Vector2i:
    get: return _bounds.position

  var size: Vector2i:
    get: return _bounds.size

  func _init(x0: int, y0: int, w: int, h: int) -> void:
    _bounds = Rect2i(x0, y0, w, h)

  ## Attempts to join two sections together, returning the merged result.
  func join(other: Section) -> Section:
    if size.x == other.size.x && pos.x == other.pos.x:
      if pos.y + size.y == other.pos.y:
        return Section.new(pos.x, pos.y, size.x, size.y + other.size.y)
      if pos.y == other.pos.y + other.size.y:
        return Section.new(pos.x, other.pos.y, size.x, size.y + other.size.y)

    if size.y == other.size.y && pos.y == other.pos.y:
      if pos.x + size.x == other.pos.x:
        return Section.new(pos.x, pos.y, size.x + other.size.x, size.y)
      if pos.x == other.pos.x + other.size.x:
        return Section.new(other.pos.x, pos.y, size.x + other.size.x, size.y)

    return null


## Adds a new section to the free section list, but before that and if 
## section merge is enabled, tries to join the rectangle with all existing 
## sections, if successful the resulting section is again merged with the 
## remaining sections until the operation fails. The result is then 
## appended to the list.
func _add_section(section: Section) -> void:
  # Attempt to merge with an existing section. If successful, attempts to merge again.
  while true:
    var found_merge := false
    for i in _sections.size():
      var merged := section.join(_sections[i])
      if merged != null:
        _sections.remove_at(i)
        section = merged
        found_merge = true
        break
    if not found_merge:
      break

  _sections.append(section)


func _section_fitness(section: Section, size: Vector2i) -> int:
  match _selection:
    Selection.BestSideShortFit:
      return _section_fitness_bssf(section, size)
    _:
      return -1


## Calls _section_fitness for each of the sections in free section 
## list. Returns the section with the minimal fitness value, all the rest 
## is boilerplate to make the fitness comparison, to rotatate the rectangles,
## and to take into account when _section_fitness returns None because 
## the rectangle couldn't be placed.
func _select_fittest_section(rect_size: Vector2i) -> Section:
  var fittest_section: Section = null
  _fittest_section_fitness = -1

  for section in _sections:
    var fitness := _section_fitness(section, rect_size)
    if fitness >= 0:
      if fitness < _fittest_section_fitness || fittest_section == null:
        fittest_section = section
        _fittest_section_fitness = fitness
        _fittest_section_rotated = false
    
    if _allow_rotation:
      fitness = _section_fitness(section, Vector2i(rect_size.y, rect_size.x))
      if fitness >= 0:
        if fitness < _fittest_section_fitness || fittest_section == null:
          fittest_section = section
          _fittest_section_fitness = fitness
          _fittest_section_rotated = true
  
  return fittest_section

## The fitness value returned by the last call to _select_fittest_section.
var _fittest_section_fitness: int

## Whether the last call to _select_fittest_section rotated the input.
var _fittest_section_rotated: bool


## Selects the best split for a section, given a rectangle of dimmensions
## width and height, then calls _split_vertical or _split_horizontal, 
## to do the dirty work.
func _split(section: Section, size: Vector2i) -> void:
  _sections.erase(section)
  match _splitting:
    Splitting.ShortAxisSplit:
      return _split_sas(section, size)
    _:
      return _split_horizontal(section, size)

## For an horizontal split the rectangle is placed in the lower
## left corner of the section (section's xy coordinates), the top
## most side of the rectangle and its horizontal continuation,
## marks the line of division for the split.
## +-----------------+
## |                 |
## |                 |
## |                 |
## |                 |
## +-------+---------+
## |#######|         |
## |#######|         |
## |#######|         |
## +-------+---------+
## If the rectangle width is equal to the the section width, only one
## section is created over the rectangle. If the rectangle height is
## equal to the section height, only one section to the right of the
## rectangle is created. If both width and height are equal, no sections
## are created.
func _split_horizontal(section: Section, size: Vector2i) -> void:
  if size.y < section.size.y:
    _add_section(Section.new(section.pos.x, section.pos.y + size.y, section.size.x, section.size.y - size.y))
  if size.x < section.size.x:
    _add_section(Section.new(section.pos.x + size.x, section.pos.y, section.size.x - size.x, size.y))

## For a vertical split the rectangle is placed in the lower
## left corner of the section (section's xy coordinates), the
## right most side of the rectangle and its vertical continuation,
## marks the line of division for the split.
## +-------+---------+
## |       |         |
## |       |         |
## |       |         |
## |       |         |
## +-------+         |
## |#######|         |
## |#######|         |
## |#######|         |
## +-------+---------+
## If the rectangle width is equal to the the section width, only one
## section is created over the rectangle. If the rectangle height is
## equal to the section height, only one section to the right of the
## rectangle is created. If both width and height are equal, no sections
## are created.
func _split_vertical(section: Section, size: Vector2i) -> void:
  if size.y < section.size.y:
    _add_section(Section.new(section.pos.x, section.pos.y + size.y, size.x, section.size.y - size.y))
  if size.x < section.size.x:
    _add_section(Section.new(section.pos.x + size.x, section.pos.y, section.size.x - size.x, section.size.y))


## Implements Best Short Side Fit (BSSF) section selection criteria for 
## Guillotine algorithm.
func _section_fitness_bssf(section: Section, size: Vector2i) -> int:
  if size.x > section.size.x || size.y > section.size.y:
    return -1
  return min(section.size.x - size.x, section.size.y - size.y)


## Implements Short Axis Split (SAS) selection rule for Guillotine 
## algorithm.
func _split_sas(section: Section, size: Vector2i) -> void:
  if section.size.x < section.size.y:
    return _split_horizontal(section, size)
  return _split_vertical(section, size)
