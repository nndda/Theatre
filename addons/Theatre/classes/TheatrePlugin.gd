@icon("res://addons/Theatre/assets/icons/Theatre.svg")
@tool
class_name TheatrePlugin extends EditorPlugin

class Config extends RefCounted:
    const GENERAL_AUTO_UPDATE := "theatre/general/updates/check_updates_automatically"
    const DEBUG_SHOW_CRAWL_FOLDER := "theatre/debug/log/show_current_crawling_directory"
    const DIALOGUE_IGNORED_DIR := "theatre/resources/dialogue/ignored_directories"

    static func init_configs() -> void:
        print("  Initializing configs...")
        for config_item : Array in [
            [ GENERAL_AUTO_UPDATE, TYPE_BOOL, true, PROPERTY_HINT_NONE, "", ],
            [ DEBUG_SHOW_CRAWL_FOLDER, TYPE_BOOL, false, PROPERTY_HINT_NONE, "", ],
            [ DIALOGUE_IGNORED_DIR, TYPE_STRING, "addons", PROPERTY_HINT_NONE, "", ],
        ]:
            if ProjectSettings.has_setting(config_item[0]):
                print("    %s already exist on ProjectSettings" % config_item[0])
            else:
                ProjectSettings.set_setting(config_item[0], config_item[2])
                ProjectSettings.add_property_info({
                    "name": config_item[0],
                    "type": config_item[1],
                    "hint": config_item[3],
                    "hint_string": config_item[4],
                })
                ProjectSettings.set_initial_value(config_item[0], config_item[2])
                ProjectSettings.set_as_basic(config_item[0], true)

        update()

    static func remove_configs() -> void:
        for config_item : String in [
            GENERAL_AUTO_UPDATE,
            DEBUG_SHOW_CRAWL_FOLDER,
            DIALOGUE_IGNORED_DIR,
        ]:
            ProjectSettings.set_setting(config_item, null)

        update()

    static func update() -> void:
        var err := ProjectSettings.save()
        if err != OK:
            push_error("Error saving Theatre config: ", err)

var http_update_req : HTTPRequest

var plugin_submenu : PopupMenu = preload(
    "res://addons/Theatre/components/tool_submenu.tscn"
).instantiate()

func _build() -> bool:
    print("💬 Compiling Dialogue resources...")
    crawl()
    return true

func _enter_tree() -> void:
    plugin_submenu.hide()

    # Initialize Theatre config
    print("🎭 Theatre v%s by nnda" % get_plugin_version())

    # Initialize project settings
    Config.init_configs()

    # Initialize update check
    http_update_req = HTTPRequest.new()
    http_update_req.timeout = 3.0
    http_update_req.request_completed.connect(_update_response)
    add_child(http_update_req)

    if ProjectSettings.get_setting(Config.GENERAL_AUTO_UPDATE, true):
        update_check()

    # Initialize plugin submenu
    plugin_submenu.id_pressed.connect(tool_submenu_id_pressed)
    add_tool_submenu_item("🎭 Theatre", plugin_submenu)

func _exit_tree() -> void:
    print("🎭 Disabling Theatre...")
    # Clear project settings
    Config.remove_configs()

    # Clear update check
    http_update_req.queue_free()

    # Clear plugin submenu
    plugin_submenu.id_pressed.disconnect(tool_submenu_id_pressed)
    remove_tool_menu_item("🎭 Theatre")

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
                if file_name.ends_with(".dlg.txt"):
                    var file := path + "/" + file_name
                    var file_com := file.trim_suffix(".txt") + ".res"

                    if FileAccess.file_exists(file_com):
                        var rem_err := DirAccess.remove_absolute(file_com)
                        if rem_err != OK:
                            push_error("Error removing Dialogue resource: ", rem_err)

                    var sav_err := ResourceSaver.save(
                        Dialogue.new(file), file_com,
                        ResourceSaver.FLAG_CHANGE_PATH
                    )
                    if sav_err != OK:
                        push_error("Error saving Dialogue resource: ", sav_err)
                    EditorInterface.get_resource_filesystem().scan()

            file_name = dir.get_next()

func init_gitignore() -> void:
    if FileAccess.file_exists("res://.gitignore"):
        print("Found `.gitignore`, initializing...")
        var gitignore_str := FileAccess.get_file_as_string("res://.gitignore")
        var gitignore := FileAccess.open("res://.gitignore", FileAccess.WRITE)
        for i : String in [
                "# Parsed Dialogue resources",
                "*.dlg.tres",
                "*.dlg.res",
            ]:
            gitignore_str = gitignore_str.replace("\n" + i, "")
            gitignore_str += "\n" + i

        gitignore.store_string(gitignore_str)
        gitignore.close()
    else:
        push_error("`.gitignore` not found")

func tool_submenu_id_pressed(id : int) -> void:
    match id:
        1:
            crawl()
        10:
            init_gitignore()
        5:
            update_check()

func update_check() -> void:
    print("  Checking for updates...")
    http_update_req.request(
        "https://api.github.com/repos/nndda/Theatre/releases/latest"
    )

func _update_response(
    result : int,
    response_code : int,
    headers : PackedStringArray,
    body : PackedByteArray,
    ) -> void:
    if response_code != 200:
        push_error("  Error getting updates: %d" % response_code)
    else:
        var json := JSON.new()
        var err := json.parse(body.get_string_from_utf8())

        if err != OK:
            push_error("  Error getting updates data: %s" % error_string(err))
        else:
            var data : Dictionary = json.get_data() as Dictionary
            var current_ver := get_plugin_version()
            if data["tag_name"] == current_ver:
                print("  Using the latest version: %s" % current_ver)
            else:
                print_rich("  New updates available: %s -> %s" % [current_ver,
                    "[url=%s]%s[/url]" % [
                        data["html_url"],
                        data["tag_name"]]
                    ])
