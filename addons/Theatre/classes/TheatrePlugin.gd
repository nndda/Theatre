@icon("res://addons/Theatre/assets/icons/Theatre.svg")
@tool
extends EditorPlugin
class_name TheatrePlugin

var http_update_req : HTTPRequest

const TheatreConfig = preload("res://addons/Theatre/classes/TheatreConfig.gd")
var theatre_config : TheatreConfig

const DialogueImporter = preload("res://addons/Theatre/classes/DialogueImporter.gd")
var dialogue_importer : DialogueImporter

const DialogueSyntaxHighlighter = preload("res://addons/Theatre/classes/DialogueSyntaxHighlighter.gd")
var dialogue_syntax_highlighter : DialogueSyntaxHighlighter

static var editor_settings := EditorInterface.get_editor_settings()
var editor_resource_filesystem := EditorInterface.get_resource_filesystem()

var plugin_submenu : PopupMenu = preload(
    "res://addons/Theatre/components/tool_submenu.tscn"
).instantiate()

func _enter_tree() -> void:
    if ProjectSettings.get_setting(TheatreConfig.GENERAL_PRINT_HEADER, true):
        print("🎭 Theatre v%s by nnda\nTheatre: initializing plugin..." % get_plugin_version())

    plugin_submenu.visible = false

    dialogue_importer = DialogueImporter.new()
    dialogue_syntax_highlighter = DialogueSyntaxHighlighter.new()

    # Initialize Theatre config
    theatre_config = TheatreConfig.new([
        DialogueSyntaxHighlighter.initialize_colors
    ])

    # Initialize project settings
    theatre_config._project_settings_changed()

    # Compile DialogueParser RegExes
    DialogueParser._initialize_regex_multi_threaded()

    # Initialize syntax highlighter
    DialogueSyntaxHighlighter.initialize_colors()

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

    # Initialize Dialogue importer
    add_import_plugin(dialogue_importer)

    # Register Dialogue syntax highlighter
    EditorInterface.get_script_editor().register_syntax_highlighter(dialogue_syntax_highlighter)

func _ready() -> void:
    if DisplayServer.get_name() != "headless":
        if ProjectSettings.get_setting(TheatreConfig.GENERAL_AUTO_UPDATE, true):
            update_check()

    const THEATRE_VER_LOG : String = "theatre/version"
    var ver : String = get_plugin_version()
    var update_needed: bool = true

    if ProjectSettings.has_setting(THEATRE_VER_LOG):
        var ver_prev : String = ProjectSettings.get_setting(THEATRE_VER_LOG)
        update_needed = ver_prev != ver

        if update_needed:
            print("Theatre: version change detected: %s -> %s, reimporting dialogues" % [ver_prev, ver])            
            reimport_dialogues()

    if update_needed:
        ProjectSettings.set_setting(THEATRE_VER_LOG, ver)

        theatre_config.update()

    ProjectSettings.set_as_internal(THEATRE_VER_LOG, true)

    if ProjectSettings.get_setting(TheatreConfig.GENERAL_PRINT_HEADER, true):
        print("Theatre: plugin ready")

func _exit_tree() -> void:
    var allow_header : bool = ProjectSettings.get_setting(TheatreConfig.GENERAL_PRINT_HEADER, true)
    if allow_header:
        print("🎭 Theatre: disabling plugin...")

    # Clear update check
    if http_update_req != null:
        http_update_req.queue_free()

    # Clear plugin submenu
    plugin_submenu.id_pressed.disconnect(tool_submenu_id_pressed)
    remove_tool_menu_item("🎭 Theatre")

    # Clear Dialogue importer
    remove_import_plugin(dialogue_importer)
    dialogue_importer = null

    # Unegister Dialogue syntax highlighter
    EditorInterface.get_script_editor().unregister_syntax_highlighter(dialogue_syntax_highlighter)
    dialogue_syntax_highlighter = null

    editor_resource_filesystem = null

    if allow_header:
        print("🎭 Theatre: plugin disabled")

func _disable_plugin() -> void:
    # Clear project settings
    theatre_config.remove_configs()

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
        1:
            reimport_dialogues()
        5:
            update_check()

func reimport_dialogues() -> void:
    const IMPORTED_PATH := "res://.godot/imported/"
    var import_file_regex : RegEx = RegEx.create_from_string(r"^.+\.dlg-[A-Fa-f0-9]+\.")
    if DirAccess.dir_exists_absolute(IMPORTED_PATH):
        for file in DirAccess.get_files_at(IMPORTED_PATH):
            if import_file_regex.search(file) != null:
                DirAccess.remove_absolute(IMPORTED_PATH + file)

        if !editor_resource_filesystem.is_scanning():
            editor_resource_filesystem.scan()

func update_check() -> void:
    print("Theatre: checking for updates...")
    
    const API_URL := "https://api.github.com/repos/nndda/Theatre/releases/latest"

    if http_update_req != null:
        http_update_req.request(API_URL)
    else:
        http_update_req = HTTPRequest.new()
        http_update_req.request_completed.connect(_update_response)
        http_update_req.ready.connect(
            http_update_req.set.bind(&"timeout", 3.),
            Object.CONNECT_ONE_SHOT,
        )

        http_update_req.ready.connect(
            http_update_req.request.bind(API_URL),
            Object.CONNECT_ONE_SHOT | Object.CONNECT_DEFERRED,
        )

        add_child.call_deferred(http_update_req)

func _update_response(
    result : int,
    response_code : int,
    headers : PackedStringArray,
    body : PackedByteArray,
    ) -> void:
    if response_code != 200:
        print_rich("Theatre: [color=red]Error getting updates: %d[/color]" % response_code)
    else:
        var json := JSON.new()
        var err := json.parse(body.get_string_from_utf8())

        if err != OK:
            print_rich("Theatre: [color=red]Error getting updates data: %s[/color]" % error_string(err))
        else:
            var data : Dictionary = json.get_data() as Dictionary
            var current_ver := get_plugin_version()
            if data["tag_name"] == current_ver:
                print("Theatre: using the latest version: %s" % current_ver)
            else:
                print_rich("Theatre: [color=cyan]New updates available: %s -> %s[/color]" % [current_ver,
                    "[url=%s]%s[/url]" % [
                        data["html_url"],
                        data["tag_name"],
                    ]
                ])
