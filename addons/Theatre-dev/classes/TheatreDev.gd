@tool
extends EditorPlugin

func mkdir(path: String) -> void:
    if not DirAccess.dir_exists_absolute(path):
        DirAccess.make_dir_recursive_absolute(path)

func _enter_tree() -> void:
    # Copy assets to a more shorter path, so that dialogue sample will be simpler :p
    mkdir("res://fonts/")
    mkdir("res://icons/")

    for src_target: PackedStringArray in [
        [
            "res://demo/assets/fonts/gabriela.tres",
            "res://fonts/gabriela.tres",
        ],
        [
            "res://addons/Theatre/assets/icons/classes/feather-pointed.svg",
            "res://icons/dialogue.svg",
        ],
        [
            "res://demo/assets/godot.png",
            "res://icons/godot.png",
        ],
        [
            "res://demo/assets/Theatre-icon.png",
            "res://icons/theatre.png",
        ],
    ] as Array[PackedStringArray]:
        DirAccess.copy_absolute(src_target[0], src_target[1])
