extends Node
class_name DialogueTest

const DLG_FILES: PackedStringArray = [
    "res://dialogues/vanilla.dlg",
    "res://dialogues/demo_dialogue.dlg",
    "res://dialogues/plugin_addon.dlg",
    "res://dialogues/preview-advanced.dlg",
]

var failures : int = 0

func dlg(path : String) -> Dialogue:
    if path.ends_with(".res") or path.ends_with(".tres"):
        return ResourceLoader.load(path)
    return Dialogue.new(
        FileAccess.get_file_as_string(path)
    )

static func generate_references() -> void:
    for dlg_file: String in DLG_FILES:
        DialogueTestUnit.create_reference(dlg_file)

func _init() -> void:
    for dlg_file: String in DLG_FILES:
        var unit := DialogueTestUnit.new(dlg(dlg_file), true)
        unit.test(dlg(DialogueTestUnit.get_ref_path(dlg_file)))
        failures += unit._failed_tests
