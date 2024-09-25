@icon("res://addons/Theatre/assets/icons/Theatre.svg")
@tool
extends EditorPlugin
class_name TheatrePlugin

class Config extends RefCounted:
    const GENERAL_AUTO_UPDATE := "theatre/general/updates/check_updates_automatically"
    const DEBUG_SHOW_CRAWL_FOLDER := "theatre/debug/log/show_current_crawling_directory"
    const DIALOGUE_IGNORED_DIR := "theatre/resources/dialogue/ignored_directories"

    static var debug_show_crawl_dir := false
    static var ignored_directories : PackedStringArray

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

    static func _project_settings_changed() -> void:
        debug_show_crawl_dir = ProjectSettings.get_setting(
            DEBUG_SHOW_CRAWL_FOLDER, false
        )

        ignored_directories = (ProjectSettings.get_setting(
            DIALOGUE_IGNORED_DIR
        ) as String ).split(",", false)

var http_update_req : HTTPRequest

var dialogue_importer : DialogueImporter

var editor_settings := EditorInterface.get_editor_settings()
var editor_resource_filesystem := EditorInterface.get_resource_filesystem()

var plugin_submenu : PopupMenu = preload(
    "res://addons/Theatre/components/tool_submenu.tscn"
).instantiate()

func _enter_tree() -> void:
    plugin_submenu.hide()
    dialogue_importer = DialogueImporter.new()

    # Initialize Theatre config
    print("🎭 Theatre v%s by nnda" % get_plugin_version())

    # Compile DialogueParser RegExes
    DialogueParser._initialize_regex()

    # Initialize project settings
    Config.init_configs()
    ProjectSettings.settings_changed.connect(Config._project_settings_changed)
    Config._project_settings_changed()

    # Add `.dlg` text file extension
    var text_files_ext : String = editor_settings\
        .get_setting("docks/filesystem/textfile_extensions")
    if !text_files_ext.contains("dlg"):
        editor_settings.set_setting("docks/filesystem/textfile_extensions",
            text_files_ext + ",dlg"
        )

    var text_files_find_ext : PackedStringArray =\
        ProjectSettings.get_setting("editor/script/search_in_file_extensions")
    if !text_files_find_ext.has("dlg"):
        text_files_find_ext.append("dlg")
        ProjectSettings.set_setting("editor/script/search_in_file_extensions",
            text_files_find_ext
        )

    # Initialize plugin submenu
    plugin_submenu.id_pressed.connect(tool_submenu_id_pressed)
    add_tool_submenu_item("🎭 Theatre", plugin_submenu)

    # Initiate Theatre singleton
    if !Engine.get_singleton_list().has("Theatre"):
        add_autoload_singleton("Theatre", "res://addons/Theatre/classes/Theatre.gd")

    # Initialize Dialogue importer
    add_import_plugin(dialogue_importer)

func _ready() -> void:
    # Initialize update check
    http_update_req = HTTPRequest.new()
    http_update_req.timeout = 3.0
    http_update_req.request_completed.connect(_update_response)
    add_child(http_update_req)

    if ProjectSettings.get_setting(Config.GENERAL_AUTO_UPDATE, true):
        await get_tree().create_timer(2.5).timeout
        update_check()

func _exit_tree() -> void:
    print("🎭 Disabling Theatre...")

    # Clear project settings
    Config.remove_configs()
    ProjectSettings.settings_changed.disconnect(Config._project_settings_changed)

    # Clear update check
    http_update_req.queue_free()

    # Clear plugin submenu
    plugin_submenu.id_pressed.disconnect(tool_submenu_id_pressed)
    remove_tool_menu_item("🎭 Theatre")

    # Clear Dialogue importer
    remove_import_plugin(dialogue_importer)
    dialogue_importer = null

    editor_resource_filesystem = null

func _disable_plugin() -> void:
    # Clear Theatre singleton
    remove_autoload_singleton("Theatre")

    # Remove `dlg` from search in file extensions
    var text_files_find_ext : PackedStringArray =\
        ProjectSettings.get_setting("editor/script/search_in_file_extensions")
    if text_files_find_ext.has("dlg"):
        var text_files_find_ext_new : PackedStringArray = []
        for n in text_files_find_ext:
            if n != "dlg":
                text_files_find_ext_new.append(n)
        ProjectSettings.set_setting("editor/script/search_in_file_extensions",
            text_files_find_ext_new
        )

func _save_external_data() -> void:
    editor_resource_filesystem.scan()

func _handles(object: Object) -> bool:
    return object is Dialogue

func tool_submenu_id_pressed(id : int) -> void:
    match id:
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
        print_rich("  [color=red]Error getting updates: %d[/color]" % response_code)
    else:
        var json := JSON.new()
        var err := json.parse(body.get_string_from_utf8())

        if err != OK:
            print_rich("  [color=red]Error getting updates data: %s[/color]" % error_string(err))
        else:
            var data : Dictionary = json.get_data() as Dictionary
            var current_ver := get_plugin_version()
            if data["tag_name"] == current_ver:
                print("  Using the latest version: %s" % current_ver)
            else:
                print_rich("  [color=cyan]New updates available: %s -> %s[/color]" % [current_ver,
                    "[url=%s]%s[/url]" % [
                        data["html_url"],
                        data["tag_name"],
                    ]
                ])
