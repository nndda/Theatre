extends RefCounted

const GENERAL_PRINT_HEADER := "theatre/general/print_header"
const GENERAL_AUTO_UPDATE := "theatre/general/updates/check_updates_automatically"
const GENERAL_EXT_CONFIG_PATH := "theatre/general/extended_config_path"
const PARSER_MULTI_THREADS := "theatre/parser/use_multiple_threads"

const PARSER_TAGSBB_ALIASES := "theatre/parser/bbcode/aliases"
const PARSER_TAGSBB_ALIASES_DEFAULT : Dictionary[String, PackedStringArray] = {
    #"bi": ["b", "i"], # BUG: typing issue with Array <-> PackedStringArray
}

const PARSER_TAGS_DEFAULT_DELAY := "theatre/parser/dialogue_tags/delay_default"
const PARSER_TAGS_DEFAULT_SPEED := "theatre/parser/dialogue_tags/speed_default"

static var config_initialized : bool = false

var update_cb : Array[Callable] = []

func _init(update_cb_arg : Array[Callable]) -> void:
    for config_item : Array in [
        [ GENERAL_PRINT_HEADER, TYPE_BOOL, true, PROPERTY_HINT_NONE, "", ],
        [ GENERAL_AUTO_UPDATE, TYPE_BOOL, true, PROPERTY_HINT_NONE, "", ],
        [ GENERAL_EXT_CONFIG_PATH, TYPE_STRING, "res://theatre.gd", PROPERTY_HINT_FILE_PATH, "", ],

        [ PARSER_MULTI_THREADS, TYPE_BOOL, false, PROPERTY_HINT_NONE, "", ],

        [ PARSER_TAGSBB_ALIASES, TYPE_DICTIONARY, PARSER_TAGSBB_ALIASES_DEFAULT, PROPERTY_HINT_DICTIONARY_TYPE, "%d:;%d:" % [TYPE_STRING, TYPE_PACKED_STRING_ARRAY], ],

        [ PARSER_TAGS_DEFAULT_DELAY, TYPE_FLOAT, .35, PROPERTY_HINT_NONE, "", ],
        [ PARSER_TAGS_DEFAULT_SPEED, TYPE_FLOAT, 1., PROPERTY_HINT_NONE, "", ],
    ]:
        if !ProjectSettings.has_setting(config_item[0]):
            ProjectSettings.set_setting(config_item[0], config_item[2])
            ProjectSettings.add_property_info({
                "name": config_item[0],
                "type": config_item[1],
                "hint": config_item[3],
                "hint_string": config_item[4],
            })
            ProjectSettings.set_initial_value(config_item[0], config_item[2])
            ProjectSettings.set_as_basic(config_item[0], true)

    ProjectSettings.settings_changed.connect(_project_settings_changed)

    update_cb = update_cb_arg
    update()

func remove_configs() -> void:
    for config_item : String in [
        GENERAL_PRINT_HEADER,
        GENERAL_AUTO_UPDATE,
        GENERAL_EXT_CONFIG_PATH,
        PARSER_MULTI_THREADS,
        PARSER_TAGSBB_ALIASES,
        PARSER_TAGS_DEFAULT_DELAY,
        PARSER_TAGS_DEFAULT_SPEED,
    ]:
        ProjectSettings.set_setting(config_item, null)

    update()

func update() -> void:
    var err := ProjectSettings.save()
    if err != OK:
        push_error("Theatre: error saving Theatre config: ", err)

static func get_setting(
    key: String,
    default: Variant = null,
) -> Variant:
    return ProjectSettings.get_setting(key, default) \
        if not (key in ext_cfg_data) \
        else \
            ext_cfg_data[key]

static var ext_cfg_data : Dictionary = {}

static func update_ext_cfg(data: Dictionary) -> void:
    ext_cfg_data = data

func _project_settings_changed() -> void:
    for cb : Callable in update_cb:
        cb.call()

    _update_parser_config()

    config_initialized = true

static func _update_parser_config() -> void:
    update_ext_cfg(load_ext_cfg())

    DialogueParser._is_multi_threaded = get_setting(PARSER_MULTI_THREADS, true)

    #print(get_setting(PARSER_TAGSBB_ALIASES))
    DialogueParser._tagbb_aliases_compile(
        PARSER_TAGSBB_ALIASES_DEFAULT.merged(
            get_setting(
                PARSER_TAGSBB_ALIASES, { } as Dictionary[String, PackedStringArray]
            ) as Dictionary[String, PackedStringArray],
            true,
        )
    )

    DialogueParser._tag_default_delay = get_setting(PARSER_TAGS_DEFAULT_DELAY, .35)
    DialogueParser._tag_default_speed = get_setting(PARSER_TAGS_DEFAULT_SPEED, 1.)

static func load_ext_cfg() -> Dictionary:
    var cfg_path: String = ProjectSettings.get_setting(
        GENERAL_EXT_CONFIG_PATH,
        "res://theatre.gd",
    )
    var res: Variant = load(cfg_path)

    if res != null:
        if res is GDScript:
            if res.get_base_script().get_global_name() == &"TheatreConfig":
                var res_inst: TheatreConfig = res.new()

                if res_inst is TheatreConfig:
                    if not res_inst.has_method(&"config"):
                        TheatreDebug.log_err(
                            "'config()' method not defined in the external config file '%s'"
                        )
                    else:
                        return res_inst._get_config()

    if FileAccess.file_exists(cfg_path):
        TheatreDebug.log_err(
            "Failed to load external config file '%s'"
        )
    return {}
