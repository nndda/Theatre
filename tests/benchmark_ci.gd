extends SceneTree

func _init() -> void:
    preload("res://tests/class/BenchmarkParser.gd").new(DialogueTest.DLG_FILES, 10_000)

    quit(0)
