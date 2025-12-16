@tool
extends EditorImportPlugin


func _get_importer_name() -> String:
  return "sicilica.import.pixelorama"

func _get_visible_name() -> String:
  return "Pixelorama"

func _get_recognized_extensions() -> PackedStringArray:
  return ["pxo"]

func _get_save_extension() -> String:
  return "res"

func _get_resource_type() -> String:
  return "SpriteFrames"


enum Presets {DEFAULT}

func _get_preset_count() -> int:
  return Presets.size()

func _get_preset_name(preset_index: int) -> String:
  match preset_index:
    Presets.DEFAULT:
      return "Default"
    _:
      return "Unknown"

func _get_import_options(_path: String, preset_index: int) -> Array[Dictionary]:
  match preset_index:
    Presets.DEFAULT:
      return [
        {
          "name": "include_default_animation",
          "default_value": true
        },
        {
          "name": "separate_layers",
          "default_value": false
        }
      ]
    _:
      return []

func _get_option_visibility(_path: String, _option_name: StringName, _options: Dictionary) -> bool:
  return true


func _import(source_file: String, save_path: String, options: Dictionary, _platform_variants: Array[String], _gen_files: Array[String]) -> Error:
  var loader := preload("pxo_loader.gd").new(options)

  var err := loader.load(source_file)
  if err != OK:
    return err

  return ResourceSaver.save(loader.data, "%s.%s" % [save_path, _get_save_extension()])
