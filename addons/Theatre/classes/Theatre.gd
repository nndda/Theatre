@tool
class_name Theatre extends EditorPlugin

class Config:
    const DEBUG_SHOW_CRAWL_FOLDER := "theatre/debug/log/show_current_crawling_directory"

    const DIALOGUE_IGNORED_DIR := "theatre/resources/dialogue/ignored_directories"

    static func init_configs() -> void:
        for config_item : Array in [
            [ DEBUG_SHOW_CRAWL_FOLDER, TYPE_BOOL, false, PROPERTY_HINT_NONE, "", ],
            [ DIALOGUE_IGNORED_DIR, TYPE_STRING, "addons", PROPERTY_HINT_NONE, "", ],
        ]:
            if ProjectSettings.has_setting(config_item[0]):
                print(config_item[0], " already exist on ProjectSettings")
            else:
                ProjectSettings.set_setting(config_item[0], config_item[2])
                ProjectSettings.add_property_info({
                    "name": config_item[0],
                    "type": config_item[1],
                    "hint": config_item[3],
                    "hint_string": config_item[4],
                })
                ProjectSettings.set_initial_value(config_item[0], config_item[2])

        update()

    static func remove_configs() -> void:
        for config_item : String in [
            DEBUG_SHOW_CRAWL_FOLDER,

            DIALOGUE_IGNORED_DIR,
        ]:
            ProjectSettings.set_setting(config_item, null)

        update()

    static func update() -> void:
        var err := ProjectSettings.save()
        if err != OK:
            push_error("Error in saving Theatre config: ", err)

func _enter_tree() -> void:
    # Initialize Theatre config
    print("Theatre v%s by nnda" % get_plugin_version())
    Config.init_configs()

    var ignore_dlg := "\n\n# Parsed Dialogue resources\n*.dlg.tres\n*.dlg.res"
    var gitignore_prev := FileAccess.get_file_as_string("res://.gitignore")

    if FileAccess.file_exists("res://.gitignore"):
        if !FileAccess\
            .get_file_as_string("res://.gitignore")\
            .contains(ignore_dlg):
            var gitignore := FileAccess.open("res://.gitignore", FileAccess.WRITE)
            gitignore.store_line(
                gitignore_prev +
                ignore_dlg
            )
            gitignore.close()

func _exit_tree() -> void:
    # Clean-up of the plugin goes here.
    pass

func _build() -> bool:
    print("Compiling Dialogue resources...")
    crawl()
    print("")
    return true

func _enable_plugin() -> void:
    Config.init_configs()

func _disable_plugin() -> void:
    Config.remove_configs()

func crawl(path : String = "res://") -> void:
    var dir := DirAccess.open(path)
    var ignored_directories : PackedStringArray = (ProjectSettings.get_setting(
        Config.DIALOGUE_IGNORED_DIR, ["addons"]
    ) as String ).split(",", false)

    if dir:
        dir.list_dir_begin()
        var file_name := dir.get_next()
        while file_name != "":
            if dir.current_is_dir():
                # Ignore directories beginning with "."
                if !file_name.begins_with("."):
                    if !ignored_directories.has(file_name):
                        var new_dir := path + (
                            "" if path == "res://" else "/"
                        ) + file_name
                        if ProjectSettings.get_setting(
                            Config.DEBUG_SHOW_CRAWL_FOLDER, false
                            ):
                            print("Crawling " + new_dir + " for dialogue resources...")
                        crawl(new_dir)
            else:
                if file_name.ends_with(".txt"):
                    var file : String = path + "/" + file_name
                    var file_com : String = file.trim_suffix(".txt") + ".dlg.res"

                    # Is this necessary?
                    if FileAccess.file_exists(file_com):
                        DirAccess.remove_absolute(file_com)

                    ResourceSaver.save(Dialogue.new(file), file_com,
                        ResourceSaver.FLAG_CHANGE_PATH
                    )
            file_name = dir.get_next()
