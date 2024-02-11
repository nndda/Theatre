@tool
class_name Theatre extends EditorPlugin

class Config:
    static var dialogue_save_to_memory = "theatre/files_and_resources/dialogue/compile_to_memory"
    static var dialogue_save_to_userpath = "theatre/files_and_resources/dialogue/compile_to_user_directory"

    static var dialogue_ignored_dir = "theatre/files_and_resources/dialogue/ignored_directories"
    static func get_ignored_directories() -> PackedStringArray:
        return PackedStringArray([".git", ".godot"]) + (
            ProjectSettings.get_setting(dialogue_ignored_dir, "addons").split(",", false)
        )

var configs : Array[Array] = [
    [
        Config.dialogue_save_to_memory, TYPE_BOOL, true, PROPERTY_HINT_NONE, "",
    ],
    [
        Config.dialogue_save_to_userpath, TYPE_BOOL, true, PROPERTY_HINT_NONE, "",
    ],
    [
        Config.dialogue_ignored_dir, TYPE_STRING, "addons", PROPERTY_HINT_NONE, "",
    ],
]

func _enter_tree():
    # Initialization of the plugin goes here.
    print("Theatre v%s by nnda" % get_plugin_version())

    for config_item in configs:
        add_config(config_item[0], config_item[1], config_item[2], config_item[3], config_item[4])

    var err := ProjectSettings.save()
    if err != OK:
        push_error("Error in saving Theatre config: ", err)

func _exit_tree():
    # Clean-up of the plugin goes here.
    pass

func add_config(
        config_name : String,
        type : int,
        default,
        hint : int,
        hint_string : String
    ) -> void:
    if ProjectSettings.has_setting(config_name):
        print(config_name, " already exist on ProjectSettings")
    else:
        ProjectSettings.set_setting(config_name, default)
        ProjectSettings.add_property_info({
            "name": config_name,
            "type": type,
            "hint": hint,
            "hint_string": hint_string,
        })
        ProjectSettings.set_initial_value(config_name, default)

