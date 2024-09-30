extends SceneTree

var failures : int = 0

func dlg(path : String) -> Dialogue:
    if path.ends_with(".res") or path.ends_with(".tres"):
        return ResourceLoader.load(path)

    return Dialogue.new(
        FileAccess.get_file_as_string(path)
    )

func _init() -> void:
    for test_dlg in [
        "res://dialogue/preview-advanced.dlg",
        "res://dialogue/demo_dialogue.dlg",
    ]:
        var unit := DialogueTestUnit.new(dlg(test_dlg + ".REF.tres"))
        unit.test(dlg(test_dlg))
        failures += unit._failed_tests

    quit(0 if failures == 0 else 1)
