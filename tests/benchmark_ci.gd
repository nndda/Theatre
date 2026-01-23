extends SceneTree

func _init() -> void:
    preload("res://tests/class/BenchmarkParser.gd").new(DialogueTest.DLG_FILES, 1000)

    quit(0)
