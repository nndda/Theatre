extends RefCounted

const GENERAL_PRINT_HEADER := "theatre/general/print_header"
const GENERAL_AUTO_UPDATE := "theatre/general/updates/check_updates_automatically"
const PARSER_MULTI_THREADS := "theatre/parser/use_multiple_threads"
const PARSER_TAGS_DEFAULT_DELAY := "theatre/parser/dialogue_tags/delay_default"
const PARSER_TAGS_DEFAULT_SPEED := "theatre/parser/dialogue_tags/speed_default"

static var config_initialized : bool = false

var update_cb : Array[Callable] = []

func _init(update_cb_arg : Array[Callable]) -> void:
    for config_item : Array in [
        [ GENERAL_PRINT_HEADER, TYPE_BOOL, true, PROPERTY_HINT_NONE, "", ],
        [ GENERAL_AUTO_UPDATE, TYPE_BOOL, true, PROPERTY_HINT_NONE, "", ],

        [ PARSER_MULTI_THREADS, TYPE_BOOL, false, PROPERTY_HINT_NONE, "", ],

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
        PARSER_MULTI_THREADS,
        PARSER_TAGS_DEFAULT_DELAY,
        PARSER_TAGS_DEFAULT_SPEED,
    ]:
        ProjectSettings.set_setting(config_item, null)

    update()

func update() -> void:
    var err := ProjectSettings.save()
    if err != OK:
        push_error("Theatre: error saving Theatre config: ", err)

func _project_settings_changed() -> void:
    for cb : Callable in update_cb:
        cb.call()

    _update_parser_config()

    config_initialized = true

static func _update_parser_config() -> void:
    DialogueParser._is_multi_threaded =\
        ProjectSettings.get_setting(PARSER_MULTI_THREADS, false)

    DialogueParser._tag_default_delay =\
        ProjectSettings.get_setting(PARSER_TAGS_DEFAULT_DELAY, .35)
    DialogueParser._tag_default_speed =\
        ProjectSettings.get_setting(PARSER_TAGS_DEFAULT_SPEED, 1.)
