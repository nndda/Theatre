extends Node

func dlg(path : String) -> Dialogue:
    if path.ends_with(".res") or path.ends_with(".tres"):
        return ResourceLoader.load(path)
    return Dialogue.new(
        FileAccess.get_file_as_string(path)
    )

func _ready() -> void:
    if DisplayServer.get_name() != "headless":
        DialogueTestUnit.new(
            dlg("res://dialogue/preview-advanced.dlg.REF.tres"), true
        ).test(
            dlg("res://dialogue/preview-advanced.dlg")
        )

        DialogueTestUnit.new(
            dlg("res://dialogue/demo_dialogue.dlg.REF.tres"), true
        ).test(
            dlg("res://dialogue/demo_dialogue.dlg")
        )
