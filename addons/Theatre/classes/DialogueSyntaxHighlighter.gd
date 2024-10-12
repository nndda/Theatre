@tool
class_name DialogueSyntaxHighlighter
extends EditorSyntaxHighlighter

var text_edit : CodeEdit
var text_edit_initialized := false

const COL : String = "color"
const TRANSPARENT : Color = Color(0, 0, 0, 0)

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
static var caller : Color
static var func_name : Color
static var func_args : Color
static var section : Color
static var section_bg : Color
static var invalid : Color

static var COL_actor_name_line : Dictionary
static var COL_base_content : Dictionary
static var COL_symbol : Dictionary
static var COL_comment : Dictionary
static var COL_tag_content : Dictionary
static var COL_tag_braces : Dictionary
static var COL_caller : Dictionary
static var COL_func_name : Dictionary
static var COL_func_args : Dictionary
static var COL_section : Dictionary
static var COL_invalid : Dictionary

static var color_initialized := false

static func initialize_colors() -> void:
    var editor_settings : EditorSettings = TheatrePlugin.editor_settings

    actor_name_line = editor_settings.get_setting("text_editor/theme/highlighting/base_type_color")
    base_content = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
    symbol = editor_settings.get_setting("text_editor/theme/highlighting/symbol_color")
    comment = editor_settings.get_setting("text_editor/theme/highlighting/comment_color")
    tag_content = editor_settings.get_setting("text_editor/theme/highlighting/user_type_color")
    tag_braces = Color(editor_settings.get_setting("text_editor/theme/highlighting/user_type_color"), 0.65)
    caller = editor_settings.get_setting("text_editor/theme/highlighting/engine_type_color")
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
    COL_caller = {COL: caller}
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

func _get_line_syntax_highlighting(line: int) -> Dictionary:
    #initialize_colors() # NOTE: uncomment on development
    if !text_edit_initialized:
        initialize_text_edit()
        text_edit_initialized = true

    text_edit.set_line_background_color(line, TRANSPARENT)

    string = text_edit.get_line(line)

    dict.clear()
    dict[0] = COL_base_content

    if is_indented(string):
        var match_func := DialogueParser._regex_func_call.search(string)
        var match_newline_tag := null \
            if match_func != null else DialogueParser._regex_dlg_tags_newline.search(string)

        if match_func != null:
            dict[match_func.get_start("caller")] = COL_caller
            dict[match_func.get_start("name")] = COL_func_name
            dict[match_func.get_start("name") - 1] = COL_symbol
            dict[match_func.get_end("name")] = COL_symbol
            dict[match_func.get_end("name") + 1] = COL_func_args
            dict[match_func.get_end() - 1] = COL_symbol
            dict[match_func.get_end()] = COL_base_content

        elif match_newline_tag != null:
            dict[match_newline_tag.get_start("tag")] = COL_tag_content
            dict[match_newline_tag.get_start("arg") - 1] = COL_symbol
            dict[match_newline_tag.get_start("arg")] = COL_tag_content

        else:
            for tag in DialogueParser._regex_dlg_tags.search_all(string):
                var START : int = tag.get_start()
                var END : int = tag.get_end()

                if !dict.has(START):
                    dict[START] = COL_tag_braces

                dict[tag.get_start("tag")] = COL_tag_content
    
                if string.contains("="):
                    dict[tag.get_start("tag") + 1] = COL_symbol
                    dict[tag.get_start("arg")] = COL_tag_content
    
                dict[END - 1] = COL_tag_braces

                if !dict.has(END):
                    dict[END] = COL_base_content

            for bb in DialogueParser._regex_bbcode_tags.search_all(string):
                var START : int = bb.get_start()
                var END : int = bb.get_end()

                if !dict.has(START):
                    dict[START] = COL_tag_braces

                dict[bb.get_start("tag")] = COL_tag_content
                dict[END - 1] = COL_tag_braces

                if !dict.has(END):
                    dict[END] = COL_base_content

    else:
        dict[0] = COL_invalid

        if string.begins_with(DialogueParser.HASH):
            dict[0] = COL_comment

        else:
            if string.ends_with(DialogueParser.COLON):
                dict[0] = COL_actor_name_line
                dict[string.rfind(DialogueParser.COLON)] = COL_symbol
                text_edit.toggle_foldable_line

                text_edit.set_line_background_color(line, actor_name_line_bg)
                if string.strip_edges() == DialogueParser.COLON:
                    text_edit.set_line_background_color(line, actor_name_line_bg_2)

            elif string.begins_with(DialogueParser.COLON):
                dict[0] = COL_section
                text_edit.set_line_background_color(line, section_bg)

    # why does it need to be ordered????
    # TODO: performance
    var dict_ordered : Dictionary = {}

    var dict_keys : PackedInt64Array = dict.keys()
    dict_keys.sort()

    for n in dict_keys:
        dict_ordered[n] = dict[n]

    return dict_ordered
