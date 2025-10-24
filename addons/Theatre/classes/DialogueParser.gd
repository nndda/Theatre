@tool
extends RefCounted
class_name DialogueParser

var output : Array[Dictionary] = []
var sections : Dictionary[String, int] = {}

# Source path from Dialouge._source_path for debugging purposes.
var _source_path : String

#region RegExes
# Match Dialogue tags: {delay=1.0} {d = 1.0} {foo} {bar} {foo.bar}
# But not: \{foo\} \{foo} {foo\}
const REGEX_DLG_TAGS :=\
    r"(?<!\\)(?:\\\\)*\{\s*(?<tag>\w+)\s*(?<sym>\=)?\s*(?<val>(?:[^\\\{\}]|\\[\{\}])*?)\s*(?<!\\)\}";\
    static var _regex_dlg_tags := RegEx.create_from_string(REGEX_DLG_TAGS)

const REGEX_SCOPE_VAR_TAGS :=\
    r"(?<!\\)(?:\\\\)*\{(?<name>\s*(?<scope>\w+)\s*\.\s*(?<val>(?:[^\\\{\}]|\\[\{\}])*?)\s*(?<!\\))\}";\
    static var _regex_scope_var_tags := RegEx.create_from_string(REGEX_SCOPE_VAR_TAGS)

# Match Dialogue tags [img] syntax:
#   [img h=20 res://icon.png]
#   [img 20x20 res://icon.png]
const REGEX_DLG_TAGS_IMG :=\
    r"(?<!\\)\[\s*img\s*((?<width>\d*?%?)x(?<height>\d*?%?))?(?<attr>\s+.+?)?\s+(?<path>(?<pathid>(?:res|user|uid)\:\/\/).+?)(?<!\\)\]";\
    static var _regex_dlg_tags_img := RegEx.create_from_string(REGEX_DLG_TAGS_IMG)

# Match Dialogue tags newline syntax:
#       d=1.0
#       delay=1.0
const REGEX_DLG_TAGS_NEWLINE :=\
    r"^\s*(?<tag>\w+)\=((?<arg>.+))*$";\
    static var _regex_dlg_tags_newline := RegEx.create_from_string(REGEX_DLG_TAGS_NEWLINE)

const REGEX_BBCODE_TAGS :=\
    r"(?<!\\)\[(?<tag>\/?(?<tag_name>\w+))\s*(?<attr>[^\[\]]+?)?(?<!\\)\]";\
    static var _regex_bbcode_tags := RegEx.create_from_string(REGEX_BBCODE_TAGS)

const REGEX_BBCODE_ATTR :=\
    r"\s*(?<key>.*?)(?<eq>=)(?<val>\"(?:[^\"]*)\"|'(?:[^']*)'|[^\s\"']+)";\
    static var _regex_bbcode_attr := RegEx.create_from_string(REGEX_BBCODE_ATTR)

# Match variables assignments:
#       Scope.name = value
#       Scope.name += value
const REGEX_VARS_SET :=\
    r"(?<scope>\w+)\.(?<name>\w+)\s*(?<op>[\+\-\*\/])?\=\s*(?<val>.+)$";\
    static var _regex_vars_set := RegEx.create_from_string(REGEX_VARS_SET)

# Match expressions-as-variable tag
#       {(Scope.owo()[-1] + "owo")}
const REGEX_VARS_EXPR :=\
    r"(?<!\\)\{\((?<expr>.+)(?<!\\)\)(?<!\\)\}";\
    static var _regex_vars_expr := RegEx.create_from_string(REGEX_VARS_EXPR)

# Match function calls:
#       Scope.name(args)
const REGEX_FUNC_CALL :=\
    r"(?<scope>\w+)\.(?<name>\w+)\((?<args>.*)\)$";\
    static var _regex_func_call := RegEx.create_from_string(REGEX_FUNC_CALL)

# Match object/property access in function arguments or variables expressions:
#       Scope.name = Object.value
#       Scope.name(Object.value)
#           -> Object.value
const REGEX_FUNC_VARS :=\
    r"(?<![\"\'\d])\b([a-zA-Z_]\w*)\s*\.\s*([a-zA-Z_]\w*)\b(?![\"\'\d])";\
    static var _regex_func_vars := RegEx.create_from_string(REGEX_FUNC_VARS)

const REGEX_INDENT :=\
    r"(?<=\n{1})\s+";\
    static var _regex_indent := RegEx.create_from_string(REGEX_INDENT)

const REGEX_VALID_DLG :=\
    r"(?m).+:\n\s+(.[^\s])+?";\
    static var _regex_valid_dlg := RegEx.create_from_string(REGEX_VALID_DLG)

const REGEX_SECTION :=\
    r"^\:(.+)";\
    static var _regex_section := RegEx.create_from_string(REGEX_SECTION)

# Named groups
const __VAL := "val"
const __SYM := "sym"

const __SCOPE := "scope"
const __NAME := "name"
const __ARGS := "args"
const __OP := "op"
#endregion

#region Dictionary keys constants
enum Key {
    ACTOR,
    ACTOR_DYN_VAR,
    ACTOR_DYN_EXPR,
    ACTOR_DYN_HAS,

    CONTENT,
    CONTENT_RAW,
    LINE_NUM,
    TAGS,
    TAGS_DELAYS,
    TAGS_SPEEDS,
    FUNC,
    FUNC_POS,
    FUNC_IDX,
    OFFSETS,
    HAS_VARS,
    VARS,
    VARS_SCOPE,
    VARS_EXPR,

    SCOPE,
    NAME,
    ARGS,
    STANDALONE,
    
    POS,
    PLACEHOLDER,
}
#endregion

## Dictionary template for each Dialogue line.
const SETS_TEMPLATE := {
    # Actor's name.
    Key.ACTOR: EMPTY,
    Key.ACTOR_DYN_VAR: [],
    Key.ACTOR_DYN_EXPR: [],
    Key.ACTOR_DYN_HAS: false,

    # Dialogue content, stripped from the Dialogue tags.
    Key.CONTENT: EMPTY,

    # Written Dialogue content.
    Key.CONTENT_RAW: EMPTY,

    # Line number of where the Dialogue line is written.
    Key.LINE_NUM: -1,

    # Built-in tags data.
    Key.TAGS: {
        Key.TAGS_DELAYS: {},
            #   Position:   Delay in second.
        Key.TAGS_SPEEDS: {},
            #   Position:   Speed scale (0, 1).
    },

    # Function calls in order. Refer to FUNC_TEMPLATE.
    Key.FUNC: [],
        # Array of Dictionary (FUNC_TEMPLATE).

    # Positional function calls.
    Key.FUNC_POS: {},
        # Position:     [Function index...].

    # Function index tags.
    Key.FUNC_IDX: [],

    Key.OFFSETS: {},
        #   start, end
        #   15: 20

    Key.HAS_VARS: false,

    # User-defined variables used.
    Key.VARS: [],
    Key.VARS_SCOPE: [],
    Key.VARS_EXPR: [],
}

## Function call Dictionary template.
const FUNC_TEMPLATE := {
    # Function's scope name/id.
    Key.SCOPE: EMPTY,

    # Function name.
    Key.NAME: EMPTY,

    # Arguments used.
    Key.ARGS: null,

    # Line number of where the function is written.
    Key.LINE_NUM: 0,

    Key.STANDALONE: true,
    Key.VARS: [],
}

#region Built in tags and variables
const TAG_DELAY_ALIASES : PackedStringArray = [
    "delay", "wait", "d", "w"
]
const TAG_SPEED_ALIASES : PackedStringArray = [
    "speed", "spd", "s"
]
const VARS_BUILT_IN_KEYS : PackedStringArray = ["n", "spc", "eq"]

const BUILT_IN_TAGS : PackedStringArray = (
    TAG_DELAY_ALIASES +
    TAG_SPEED_ALIASES +
    VARS_BUILT_IN_KEYS
)

const VARS_BUILT_IN : Dictionary[String, String] = {
    "n" : "\n",
    "spc" : " ",
    "eq" : "=",
}

const BB_ALIASES := {
    "bg": "bgcolor",
    "fg": "fgcolor",
    "col": "color",
    "c": "color",
    "f": "font",
}

const BB_ALIASES_TAGS : PackedStringArray = [
    "bg", "fg", "col", "c", "f",
]
#endregion

const NEWLINE := "\n"
const SPACE := " "
const EMPTY := ""
const UNDERSCORE := "_"
const COLON := ":"
const HASH := "#"
const DOT := "."

const INDENT_2 := "  "
const INDENT_4 := "    "

#region RegEx init NOTE: sometimes the RegExes returns null
static var _is_multi_threaded := false
static var _regex_initialized := false
static var _regex_mutex := Mutex.new()

static func _initialize_regex_multi_threaded() -> void:
    if _regex_initialized:
        return

    if _is_multi_threaded:
        _regex_mutex.lock()
        if not _regex_initialized:
            _initialize_regex()
        _regex_mutex.unlock()
    else:
        _initialize_regex()

static func _initialize_regex() -> void:
    _regex_dlg_tags = RegEx.create_from_string(REGEX_DLG_TAGS)
    _regex_scope_var_tags = RegEx.create_from_string(REGEX_SCOPE_VAR_TAGS)
    _regex_dlg_tags_newline = RegEx.create_from_string(REGEX_DLG_TAGS_NEWLINE)
    _regex_bbcode_tags = RegEx.create_from_string(REGEX_BBCODE_TAGS)
    _regex_vars_set = RegEx.create_from_string(REGEX_VARS_SET)
    _regex_vars_expr = RegEx.create_from_string(REGEX_VARS_EXPR)
    _regex_func_call = RegEx.create_from_string(REGEX_FUNC_CALL)
    _regex_func_vars = RegEx.create_from_string(REGEX_FUNC_VARS)
    _regex_indent = RegEx.create_from_string(REGEX_INDENT)
    _regex_valid_dlg = RegEx.create_from_string(REGEX_VALID_DLG)
    _regex_section = RegEx.create_from_string(REGEX_SECTION)

    _regex_initialized = (
        _regex_dlg_tags and
        _regex_scope_var_tags and
        _regex_dlg_tags_newline and
        _regex_bbcode_tags and
        _regex_vars_set and
        _regex_vars_expr and
        _regex_func_call and
        _regex_func_vars and
        _regex_indent and
        _regex_valid_dlg and
        _regex_section
    )
#endregion

func _init(src : String = "", src_path : String = ""):
    # WHY???
    _initialize_regex_multi_threaded()
    #if !_regex_initialized:
        #_initialize_regex()
        #_regex_initialized = true

    if !src_path.is_empty():
        _source_path = src_path

    var dlg_raw : PackedStringArray = src.split(NEWLINE)

    var body_pos : int = -1
    var dlg_raw_size : int = dlg_raw.size()
    var newline_stack : int = 0
    var dlg_line_stack : int = 0

    var regex_func_match : RegExMatch
    var regex_vars_match : RegExMatch
    var regex_img_match : RegExMatch

    # Per raw string line
    for i in dlg_raw_size:
        var ln_num : int = i + 1
        var n := dlg_raw[i]
        var n_stripped := n.strip_edges()
        var is_valid_line := !n.begins_with(HASH) and !n.is_empty()

        var current_processed_string : String

        if is_valid_line \
            and !is_indented(n) \
            and n_stripped.ends_with(COLON):

            #region NOTE: Create new Dialogue line -------------------------------------------------
            var setsl := SETS_TEMPLATE.duplicate(true)
            newline_stack = 0
            dlg_line_stack += 1

            setsl[Key.LINE_NUM] = ln_num

            if dlg_raw_size < i + 1:
                Theatre.TheatreDebug.log_err(
                    "@%s:%d - actor's name exists without a dialogue body" % [
                        _source_path, ln_num,
                    ],
                    -1
                )

            var actor_str := n_stripped.trim_suffix(COLON)

            if actor_str == UNDERSCORE:
                actor_str = EMPTY
            elif actor_str.is_empty():
                if body_pos < 0:
                    Theatre.TheatreDebug.log_err(
                        "@%s:%d - missing initial actor's name" % [
                            _source_path, ln_num,
                        ],
                        -1
                    )
                else:
                    actor_str = output[body_pos][Key.ACTOR]
                    setsl[Key.ACTOR_DYN_HAS] = output[body_pos][Key.ACTOR_DYN_HAS]
                    setsl[Key.ACTOR_DYN_VAR] = output[body_pos][Key.ACTOR_DYN_VAR]
                    setsl[Key.ACTOR_DYN_EXPR] = output[body_pos][Key.ACTOR_DYN_EXPR]
            else:
                # Actor name with dynamic variable
                # Expression tag
                var parsed_expr_tags := parse_expr_tags(actor_str, ln_num)
                if not parsed_expr_tags.is_empty():
                    setsl[Key.ACTOR_DYN_EXPR].append(
                        parsed_expr_tags[Key.VARS_EXPR]
                    )
                    actor_str = parsed_expr_tags[Key.NAME]
                setsl[Key.ACTOR_DYN_EXPR].make_read_only()

                # Scoped var tag
                setsl[Key.ACTOR_DYN_VAR].append_array(
                    parse_var_scope_tags(actor_str, ln_num)
                )
                setsl[Key.ACTOR_DYN_VAR].make_read_only()

                setsl[Key.ACTOR_DYN_HAS] = \
                    not setsl[Key.ACTOR_DYN_VAR].is_empty() or \
                    not setsl[Key.ACTOR_DYN_EXPR].is_empty()

            setsl[Key.ACTOR] = StringName(actor_str)
            output.append(setsl)
            body_pos += 1
            #endregion

        elif _regex_section.search(n) != null:
            sections[
                n
                .split(SPACE, false, 1)[0]
                .strip_edges()
                .trim_prefix(COLON)
            ] = dlg_line_stack

        elif n_stripped.is_empty():
            newline_stack += 1

        elif is_valid_line and !output.is_empty():
            current_processed_string = dlg_raw[i].strip_edges()
            regex_func_match = _regex_func_call.search(current_processed_string)
            regex_vars_match = null
            regex_img_match = null

            if regex_func_match == null:
                regex_vars_match = _regex_vars_set.search(current_processed_string)
            if regex_vars_match == null:
                regex_img_match = _regex_dlg_tags_img.search(current_processed_string)

            #region NOTE: Function calls -----------------------------------------------------------
            if regex_func_match != null:
                var func_dict := FUNC_TEMPLATE.duplicate(true)

                func_dict[Key.SCOPE] = StringName(regex_func_match.get_string(
                    regex_func_match.names[__SCOPE]
                ))
                func_dict[Key.NAME] = StringName(regex_func_match.get_string(
                    regex_func_match.names[__NAME]
                ))

                # Function arguments
                var args_raw := regex_func_match.get_string(
                    regex_func_match.names[__ARGS]
                ).strip_edges()

                func_dict[Key.LINE_NUM] = ln_num

                # Parse parameter arguments
                var args := Expression.new()
                var args_err := args.parse("[" + args_raw + "]")
                var var_matches := _regex_func_vars.search_all(args_raw)

                if var_matches.is_empty():
                    func_dict[Key.ARGS] = args.execute()

                    if args.has_execute_failed():
                        Theatre.TheatreDebug.log_err(
                            "Failed parsing function call arguments @%s:%d - %s" % [
                                _source_path, ln_num, args.get_error_text()
                            ],
                            -1
                        )

                else:
                    func_dict[Key.STANDALONE] = false
                    func_dict[Key.ARGS] = "[" + args_raw + "]"

                    for var_match in var_matches:
                        func_dict[Key.VARS].append(var_match.get_string(1))

                func_dict.make_read_only()
                output[body_pos][Key.FUNC].append(func_dict)

                output[body_pos][Key.CONTENT_RAW] += "{%d}" % (output[body_pos][Key.FUNC].size() - 1)
                output[body_pos][Key.CONTENT] += output[body_pos][Key.CONTENT_RAW]
            #endregion

            #region NOTE: Variables setter
            elif regex_vars_match != null:
                var func_dict := FUNC_TEMPLATE.duplicate(true)
                var var_scope := regex_vars_match.get_string(
                    regex_vars_match.names[__SCOPE]
                )
                var var_name := regex_vars_match.get_string(
                    regex_vars_match.names[__NAME]
                )

                func_dict[Key.SCOPE] = StringName(var_scope)
                func_dict[Key.NAME] = &"set"
                func_dict[Key.LINE_NUM] = ln_num

                var prop_name := "StringName(\"" + var_name + "\")"

                # Operator assignment type if used
                #       += -= *= /=
                #       +  -  *  /
                var operator := regex_vars_match.get_string(
                    regex_vars_match.names[__OP]
                )
                var operator_used := not operator.is_empty()

                # Value
                var val_raw := regex_vars_match.get_string(
                    regex_vars_match.names[__VAL]
                )
                
                # Parse value
                var val := Expression.new()
                var val_err := val.parse("[" + prop_name + ", (" + val_raw + ")]")
                var val_obj_matches := _regex_func_vars.search_all(val_raw)

                if val_obj_matches.is_empty() and\
                    not operator_used:

                    func_dict[Key.ARGS] = val.execute()

                    if val.has_execute_failed():
                        Theatre.TheatreDebug.log_err(
                            "Failed parsing property setter value @%s:%d - %s" % [
                                _source_path, ln_num, val.get_error_text()
                            ],
                            -1
                        )

                else:
                    func_dict[Key.STANDALONE] = not operator_used
                    func_dict[Key.ARGS] = "[" + prop_name + ", (" + (
                        # 'Scope.name'   ' + - * / ' 
                        var_scope + DOT + var_name + operator if operator_used
                        else EMPTY
                    ) + val_raw + ")]"

                    if operator_used:
                        func_dict[Key.VARS].append(var_scope)
                    
                    for var_match in val_obj_matches:
                        func_dict[Key.VARS].append(var_match.get_string(1))

                func_dict.make_read_only()
                output[body_pos][Key.FUNC].append(func_dict)

                output[body_pos][Key.CONTENT_RAW] += "{%d}" % (output[body_pos][Key.FUNC].size() - 1)
                output[body_pos][Key.CONTENT] += output[body_pos][Key.CONTENT_RAW]
            #endregion

            #region NOTE: [img] tag sugar ----------------------------------------------------------
            elif regex_img_match != null:
                var parsed_img := parse_img_tag(regex_img_match) + SPACE

                output[body_pos][Key.CONTENT_RAW] += parsed_img
                output[body_pos][Key.CONTENT] += parsed_img
            #endregion

            #region NOTE: Newline Dialogue tags ----------------------------------------------------
            elif is_regex_full_string(_regex_dlg_tags_newline.search(current_processed_string)):
                output[body_pos][Key.CONTENT_RAW] += "{" + current_processed_string + "}"
                output[body_pos][Key.CONTENT] += output[body_pos][Key.CONTENT_RAW]
            #endregion

            #region NOTE: Newline BBCode tags ------------------------------------------------------
            elif is_regex_full_string(_regex_bbcode_tags.search(current_processed_string)):
                output[body_pos][Key.CONTENT_RAW] += current_processed_string
                output[body_pos][Key.CONTENT] += current_processed_string
            #endregion

            # Dialogue text body
            else:
                # Bake built-in variables
                current_processed_string = current_processed_string.format(VARS_BUILT_IN)

                var parsed_expr_tags := parse_expr_tags(current_processed_string, ln_num)
                if not parsed_expr_tags.is_empty():
                    output[body_pos][Key.VARS_EXPR].append(
                        parsed_expr_tags[Key.VARS_EXPR]
                    )
                    current_processed_string = parsed_expr_tags[Key.NAME]

                output[body_pos][Key.VARS_SCOPE].append_array(
                    parse_var_scope_tags(current_processed_string, ln_num)
                )

                if newline_stack > 0:
                    newline_stack += 1
                var dlg_body := NEWLINE.repeat(newline_stack)\
                    + current_processed_string\
                    + (
                        EMPTY if current_processed_string.ends_with(NEWLINE)
                        else SPACE
                    )
                newline_stack = 0

                # Append Dialogue body
                output[body_pos][Key.CONTENT_RAW] += dlg_body
                output[body_pos][Key.CONTENT] += dlg_body

    # Per dialogue line
    for n in output.size():
        var body : String
        var content_str : String = output[n][Key.CONTENT_RAW]

        if content_str.is_empty():
            Theatre.TheatreDebug.log_err(
                "@%s:%d - empty dialogue body for actor '%s'" % [
                    _source_path, output[n][Key.LINE_NUM], output[n][Key.ACTOR]
                ],
                -1
            )

        else:
            #region NOTE: Resolve BBCode aliases
            var match_bb := _regex_bbcode_tags.search_all(content_str)

            if !match_bb.is_empty():
                match_bb.reverse()
                var tag : String
                var start : int

                for bb in match_bb:
                    tag = bb.get_string("tag_name")

                    if BB_ALIASES_TAGS.has(tag):
                        start = bb.get_start("tag_name")
                        content_str = content_str \
                            .erase(start, tag.length()) \
                            .insert(start, BB_ALIASES[tag])
            #endregion

            #region NOTE: Escaped square brackets
            match_bb = RegEx.create_from_string(r"(\\\[|\\\])").search_all(content_str)
            if !match_bb.is_empty():
                match_bb.reverse()
                var bracket : String
                var start : int

                for br in match_bb:
                    bracket = "[lb]" if br.strings[0] == r"\[" else "[rb]"
                    start = br.get_start()

                    content_str = content_str \
                        .erase(start, 2) \
                        .insert(start, bracket)
            #endregion

            output[n][Key.CONTENT_RAW] = content_str

            body = content_str
            for tag in _regex_dlg_tags.search_all(content_str):
                body = body.replace(tag.strings[0], EMPTY)

            output[n].merge(parse_tags(content_str), true)

        output[n][Key.FUNC].make_read_only()
        output[n][Key.CONTENT] = body

## Check if [param string] is indented with tabs or spaces.
func is_indented(string : String) -> bool:
    return string != string.lstrip(" \t")

## Check if [param string] is written in a valid Dialogue string format/syntax or not.
static func is_valid_source(string : String) -> bool:
    #if _regex_valid_dlg == null:
        #_regex_valid_dlg = RegEx.create_from_string(REGEX_VALID_DLG)
    return _regex_valid_dlg.search(string) != null

# BUG
## Normalize indentation of the Dialogue raw string.
static func normalize_indentation(string : String) -> String:
    var indents : Array[int] = []

    #if _regex_indent == null:
        #_regex_indent = RegEx.create_from_string(REGEX_INDENT)

    for n in _regex_indent.search_all(string):
        var len := n.get_string(1).length()
        if !indents.has(len):
            indents.append(len)

    if indents.max() > 0:
        string = string.replacen(NEWLINE + SPACE.repeat(indents.min()), NEWLINE)

    return string

static func escape_brackets(string : String) -> String:
    return string\
        .replace(r"\{", "{")\
        .replace(r"\}", "}")

func parse_img_tag(img_tag_match : RegExMatch) -> String:
#static func parse_img_tag(string : String) -> String:
    #if _regex_dlg_tags_img == null:
        #_regex_dlg_tags_img = RegEx.create_from_string(REGEX_DLG_TAGS_IMG)

    #var img_tag_match := _regex_dlg_tags_img.search(string)
    var attrs : String = ""

    var n := img_tag_match.get_string("width")
    if not n.is_empty():
        attrs += " width=" + n

    n = img_tag_match.get_string("height")
    if not n.is_empty():
        attrs += " height=" + n
        
    n = img_tag_match.get_string("attr")
    if not n.is_empty():
        for attr in _regex_bbcode_attr.search_all(n):
            var key := attr.get_string("key")

            if key == "w": key = "width"
            elif key == "h": key = "height"

            attrs += \
                " " + key + "=" +\
                attr.get_string("val")

    return "[img" + attrs + "]" + img_tag_match.get_string("path") + "[/img]"

func parse_var_scope_tags(string : String, line_num : int = 0) -> Array[Array]:
    var output : Array[Array] = []

    for tag: RegExMatch in _regex_scope_var_tags.search_all(string):
        output.append(
            [
                tag.get_string(__NAME),
                tag.get_string(__SCOPE),
                StringName(tag.get_string(__VAL)),
                line_num,
            ]
        )

    return output
    
# Expression-as-variable tag
# "{(1 + 2)}"
# "{(Scope.uwu()[-1] + "owo")}"
func parse_expr_tags(string : String, line_num : int = 0) -> Dictionary:
    var output : Dictionary = {}

    for regex_vars_expr_match: RegExMatch in _regex_vars_expr.search_all(string):
        var tag_expr_start := regex_vars_expr_match.get_start()
        var tag_expr_full := regex_vars_expr_match.get_string()
        var tag_expr_args_str := regex_vars_expr_match.get_string(1)

        var inputs : PackedStringArray = []
        for input_re: RegExMatch in _regex_func_vars.search_all(tag_expr_args_str):
            inputs.append(input_re.get_string(1))

        output[Key.VARS_EXPR] = {
            Key.NAME: "#%d%d" % [line_num, tag_expr_full.hash()],
            Key.ARGS: inputs,
            Key.CONTENT: tag_expr_args_str,
        }

        output[Key.NAME] = string \
            .erase(
                tag_expr_start,
                tag_expr_full.length(),
            )\
            .insert(
                tag_expr_start,
                "{" + output[Key.VARS_EXPR][Key.NAME] + "}",
            )

    return output

# 😭😭😭
#const BB_TAG_TEMPLATE := {
    #Key.POS: 0,
    #Key.CONTENT: "",
    #Key.PLACEHOLDER: false,
#}
static func parse_tags(string : String) -> Dictionary:
    var vars : PackedStringArray = []
    var tags : Dictionary = SETS_TEMPLATE[Key.TAGS].duplicate(true)
    var func_pos : Dictionary = {}
    var func_idx : PackedInt64Array = []

    # BBCode ===============================================================
    var bb_data : Array[Dictionary] = []

    # Escaped Equal Sign ===================================================
    string = string.replace("\\=", "=")

    # Strip and log BBCode tags
    var bb_tag : String
    var bb_full_str : String
    var bb_full_str_len : int
    var bb_pos : int
    var bb_pos_inv : int

    var is_sqr_bracket : bool
    var is_img : bool
    var is_placeholder : bool

    var tagless_string : String = _regex_dlg_tags.sub(string, EMPTY, true)

    var bb_tag_img_end : int = 0
    var bb_tags_matches := _regex_bbcode_tags.search_all(tagless_string)
    bb_tags_matches.reverse()

    for bb in bb_tags_matches:
        bb_tag = bb.get_string("tag")

        if not bb_tag == "/img":
            bb_full_str = bb.strings[0]
            bb_full_str_len = bb_full_str.length()

            bb_pos = bb.get_start()            

            is_sqr_bracket = bb_tag == "lb" or bb_tag == "rb"
            is_img = bb_tag == "img"
            is_placeholder = is_sqr_bracket or is_img

            if is_img:
                bb_full_str = tagless_string.substr(
                    bb_pos,
                    bb_tag_img_end - bb_pos,
                )
                bb_full_str_len = bb_full_str.length()

            # so scawy
            tagless_string = tagless_string\
                .erase(bb_pos, bb_full_str_len)

            if is_placeholder:
                tagless_string = tagless_string\
                    .insert(bb_pos, HASH)

            string = string.replace(
                bb_full_str,
                HASH if is_placeholder else
                EMPTY
            )

            # BBCodes data to be re-inserted later after parsing the dialogue tags
            bb_pos_inv = tagless_string.length() - bb_pos
            
            bb_data.append({
                Key.POS: bb_pos_inv,
                Key.CONTENT: (
                    "[" + bb_tag + "]" if is_sqr_bracket
                    else bb_full_str + "[/img]" if is_img
                    else bb_full_str
                ),
                Key.PLACEHOLDER: is_placeholder,
            })

        else:
            bb_tag_img_end = bb.get_start()
            string = string.replace(
                bb.strings[0],
                EMPTY
            )
            tagless_string = tagless_string.erase(bb_tag_img_end, bb.strings[0].length())

    # Escaped Curly Brackets ===============================================
    # 💀💀💀💀💀💀💀💀💀💀💀
    var regex_curly_brackets := RegEx.create_from_string(r"\\(\{|\})")

    var esc_curly_brackets : Dictionary = {}

    for cb in regex_curly_brackets.search_all(
        _regex_dlg_tags.sub(string, EMPTY, true)
        ):
        esc_curly_brackets[cb.get_start()] = cb.strings[0]

    if !esc_curly_brackets.is_empty():
        string = regex_curly_brackets.sub(string, HASH, true)

    # Dialogue tags ========================================================
    var tag_pos_offset : int = 0

    var string_match : String
    var tag_pos : int
    var tag_key : String
    var tag_value : String
    var tag_sym : String
    for b in _regex_dlg_tags.search_all(string):
        string_match = b.strings[0]

        tag_pos = b.get_start() - tag_pos_offset
        tag_key = b.get_string("tag")
        tag_value = b.get_string(__VAL)
        tag_sym = b.get_string(__SYM)

        # Position-based function calls.
        if tag_key.is_valid_int():
            var idx : int = tag_key.to_int()

            if tag_pos == 0:
                tag_pos = 1

            # If its in the same position after {delay}, offset by +1.
            # So that it will be called after the rendering continued.
            if tags[Key.TAGS_DELAYS].has(tag_pos):
                tag_pos += 1

            if func_pos.has(tag_pos):
                func_pos[tag_pos].append(idx)
            else:
                func_pos[tag_pos] = [idx]

            if !func_idx.has(idx):
                func_idx.append(idx)

        #elif tag_sym == "=": # NOTE: conflicting with the {s} shorthand alias to reset the rendering speed.
        #region NOTE: built in tags.
        elif TAG_DELAY_ALIASES.has(tag_key):
            tags[Key.TAGS_DELAYS][tag_pos] = float(tag_value)

        elif TAG_SPEED_ALIASES.has(tag_key):
            tags[Key.TAGS_SPEEDS][tag_pos] = 1.0 if tag_value.is_empty() else tag_value.to_float()
        #endregion

        # User defined variables.
        elif tag_key not in vars:
            vars.append(tag_key)

        string = string.replace(string_match, EMPTY)

        tag_pos_offset += string_match.length()

    # Insert back escaped curly brackets ===================================
    for cb in esc_curly_brackets.keys():
        string = string\
            .erase(cb)\
            .insert(cb, esc_curly_brackets[cb])

    # Insert back BBCodes ==================================================
    var str_len := string.length()
    if not bb_data.is_empty():
        for data: Dictionary in bb_data:
            bb_pos_inv = str_len - data[Key.POS]
            string = string\
                .erase(bb_pos_inv, 1 if data[Key.PLACEHOLDER] else 0)\
                .insert(bb_pos_inv, data[Key.CONTENT])

    return {
        Key.TAGS: tags,
        Key.CONTENT: string,
        Key.FUNC_POS: func_pos,
        Key.FUNC_IDX: func_idx,
        Key.VARS: vars,
    }

# Temporary solution when using variables and tags at the same time
# Might not be performant when dealing with real-time variables
## Format Dialogue body at [param pos] position with [member TheatreStage.variables], and update the positions of the built-in tags.
## Return the formatted string.
static func update_tags_position(dlg : Dialogue, pos : int, vars : Dictionary) -> void:
    dlg._sets[pos].merge(
        parse_tags(
            dlg._sets[pos][Key.CONTENT_RAW].format(vars)
        ),
        true
    )

static func is_regex_full_string(regex_match : RegExMatch) -> bool:
    if regex_match == null:
        return false
    return regex_match.get_start() == 0 and\
        regex_match.get_end() == regex_match.subject.length()
