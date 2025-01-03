@tool
extends EditorImportPlugin
class_name DialogueImporter

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
    return []

func _get_import_order() -> int:
    return 0

func _get_importer_name() -> String:
    return "theatre.dialogue.importer"

func _get_preset_count() -> int:
    return 1

func _get_preset_name(preset_index : int) -> String:
    return "Default"

func _get_priority() -> float:
    return 1.0

func _get_recognized_extensions() -> PackedStringArray:
    return ["dlg"]

func _get_resource_type() -> String:
    return "Resource"

func _get_save_extension() -> String:
    return "res"

func _get_visible_name() -> String:
    return "Dialogue"

func _import(
    source_file : String,
    save_path : String,
    options : Dictionary,
    platform_variants : Array[String],
    gen_files : Array[String],
    ) -> Error:
    var dlg_file := FileAccess.open(source_file, FileAccess.READ)
    if dlg_file == null:
        return FileAccess.get_open_error()

    var dlg := Dialogue.new()
    dlg._source_path = source_file
    dlg._from_string(dlg_file.get_as_text())

    return ResourceSaver.save( dlg,
        save_path + "." + _get_save_extension()
    )
