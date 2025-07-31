@tool
extends EditorSyntaxHighlighter

var text_edit : CodeEdit
var text_edit_initialized := false

const COL := "color"
const TRANSPARENT := Color(0, 0, 0, 0)

const COLON := DialogueParser.COLON
const HASH := DialogueParser.HASH
const EQUALS := "="

const __NAME := "name"
const __TAG := "tag"
const __ARG := "arg"
const __SCOPE := "scope"
const __VAL := "val"
const __SYM := "sym"

var string : String
var dict : Dictionary = {}

static var actor_name_line : Color
static var actor_name_line_bg : Color
static var actor_name_line_bg_2 : Color
static var base_content : Color
static var symbol : Color
static var comment : Color
static var tag_content : Color
static var tag_braces : Color
static var scope : Color
static var func_name : Color
static var func_args : Color
static var section : Color
static var section_bg : Color
static var invalid : Color

static var COL_actor_name_line : Dictionary[String, Color]
static var COL_base_content : Dictionary[String, Color]
static var COL_symbol : Dictionary[String, Color]
static var COL_comment : Dictionary[String, Color]
static var COL_tag_content : Dictionary[String, Color]
static var COL_tag_braces : Dictionary[String, Color]
static var COL_scope : Dictionary[String, Color]
static var COL_func_name : Dictionary[String, Color]
static var COL_func_args : Dictionary[String, Color]
static var COL_section : Dictionary[String, Color]
static var COL_invalid : Dictionary[String, Color]

static var color_initialized := false

static func initialize_colors() -> void:
    var editor_settings : EditorSettings = TheatrePlugin.editor_settings

    actor_name_line = editor_settings.get_setting("text_editor/theme/highlighting/base_type_color")
    base_content = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
    symbol = editor_settings.get_setting("text_editor/theme/highlighting/symbol_color")
    comment = editor_settings.get_setting("text_editor/theme/highlighting/comment_color")
    tag_content = editor_settings.get_setting("text_editor/theme/highlighting/user_type_color")
    tag_braces = Color(editor_settings.get_setting("text_editor/theme/highlighting/user_type_color"), 0.65)
    scope = editor_settings.get_setting("text_editor/theme/highlighting/engine_type_color")
    func_name = editor_settings.get_setting("text_editor/theme/highlighting/function_color")
    func_args = editor_settings.get_setting("text_editor/theme/highlighting/string_color")
    section = editor_settings.get_setting("text_editor/theme/highlighting/keyword_color")
    invalid = editor_settings.get_setting("text_editor/theme/highlighting/comment_markers/critical_color")

    COL_actor_name_line = {COL: actor_name_line}
    COL_base_content = {COL: base_content}
    COL_symbol = {COL: symbol}
    COL_comment = {COL: comment}
    COL_tag_content = {COL: tag_content}
    COL_tag_braces = {COL: tag_braces}
    COL_scope = {COL: scope}
    COL_func_name = {COL: func_name}
    COL_func_args = {COL: func_args}
    COL_section = {COL: section}
    COL_invalid = {COL: invalid}

    actor_name_line_bg = Color(actor_name_line, 0.0825)
    actor_name_line_bg_2 = Color(actor_name_line, 0.04)
    section_bg = Color(section, 0.12)

func initialize_text_edit() -> void:
    if get_text_edit() != null:
        text_edit = get_text_edit()
        text_edit.clear_string_delimiters()

func _init() -> void:
    if !color_initialized:
        initialize_colors()
        color_initialized = true

func _get_name() -> String:
    return "Theatre Dialogue"

func _get_supported_languages() -> PackedStringArray:
    return ["dlg"]

func is_indented(string : String) -> bool:
    return string != string.lstrip(" \t")

func _get_line_syntax_highlighting(line : int) -> Dictionary:
    #initialize_colors() # NOTE: uncomment on development
    if !text_edit_initialized:
        initialize_text_edit()
        text_edit_initialized = true

    text_edit.set_line_background_color(line, TRANSPARENT)

    string = text_edit.get_line(line)

    dict.clear()
    dict[0] = COL_base_content

    if is_indented(string):
        if DialogueParser._regex_func_call == null:
            DialogueParser._regex_func_call = RegEx.create_from_string(
                DialogueParser.REGEX_FUNC_CALL
            )

        var match_func := DialogueParser._regex_func_call.search(string)
        var match_vars : RegExMatch = null
        var match_newline_tag : RegExMatch = null

        if match_func != null:
            dict[match_func.get_start(__SCOPE)] = COL_scope
            dict[match_func.get_start(__NAME)] = COL_func_name
            dict[match_func.get_start(__NAME) - 1] = COL_symbol
            dict[match_func.get_end(__NAME)] = COL_symbol
            dict[match_func.get_end(__NAME) + 1] = COL_func_args
            dict[match_func.get_end() - 1] = COL_symbol
            dict[match_func.get_end()] = COL_base_content
        else:
            if DialogueParser._regex_vars_set == null:
                DialogueParser._regex_vars_set = RegEx.create_from_string(
                    DialogueParser.REGEX_VARS_SET
                )
            match_vars = DialogueParser._regex_vars_set.search(string)

        if match_vars != null:
            dict[match_vars.get_start(__SCOPE)] = COL_scope
            dict[match_vars.get_start(__NAME)] = COL_func_name
            dict[match_vars.get_start(__NAME) - 1] = COL_symbol
            dict[match_vars.get_end(__NAME)] = COL_symbol
            dict[match_vars.get_start(__VAL)] = COL_func_args
            dict[match_vars.get_end()] = COL_base_content
        else:
            if DialogueParser._regex_dlg_tags_newline == null:
                DialogueParser._regex_dlg_tags_newline = RegEx.create_from_string(
                    DialogueParser.REGEX_DLG_TAGS_NEWLINE
                )
            match_newline_tag = DialogueParser._regex_dlg_tags_newline.search(string)

        if match_newline_tag != null:
            dict[match_newline_tag.get_start(__TAG)] = COL_tag_content
            dict[match_newline_tag.get_start(__ARG) - 1] = COL_symbol
            dict[match_newline_tag.get_start(__ARG)] = COL_tag_content

        else:
            if DialogueParser._regex_dlg_tags == null:
                DialogueParser._regex_dlg_tags = RegEx.create_from_string(
                    DialogueParser.REGEX_DLG_TAGS
                )
            for tag in DialogueParser._regex_dlg_tags.search_all(string):
                var START : int = tag.get_start()
                var END : int = tag.get_end()

                dict[START] = COL_tag_braces

                dict[tag.get_start(__TAG)] = COL_tag_content

                if !tag.get_string(__SYM).is_empty():
                    dict[tag.get_start(__SYM)] = COL_symbol
                    dict[tag.get_end(__SYM)] = COL_tag_content
    
                dict[END - 1] = COL_tag_braces

                if !dict.has(END):
                    dict[END] = COL_base_content

            if DialogueParser._regex_bbcode_tags == null:
                DialogueParser._regex_bbcode_tags = RegEx.create_from_string(
                    DialogueParser.REGEX_BBCODE_TAGS
                )
            for bb in DialogueParser._regex_bbcode_tags.search_all(string):
                var START : int = bb.get_start()
                var END : int = bb.get_end()

                dict[START] = COL_tag_braces

                dict[bb.get_start(__TAG)] = COL_tag_content
                dict[END - 1] = COL_tag_braces

                if !dict.has(END):
                    dict[END] = COL_base_content

    else:
        dict[0] = COL_invalid

        if string.begins_with(HASH):
            dict[0] = COL_comment

        else:
            if string.ends_with(COLON):
                dict[0] = COL_actor_name_line
                dict[string.rfind(COLON)] = COL_symbol

                text_edit.set_line_background_color(line, actor_name_line_bg)
                if string.strip_edges() == COLON:
                    text_edit.set_line_background_color(line, actor_name_line_bg_2)

            elif string.begins_with(COLON):
                dict[0] = COL_section
                text_edit.set_line_background_color(line, section_bg)

    # why does it need to be ordered????
    var dict_ordered : Dictionary = {}

    var dict_keys : PackedInt64Array = dict.keys()
    dict_keys.sort()

    for n in dict_keys:
        dict_ordered[n] = dict[n]

    return dict_ordered
