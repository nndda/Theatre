extends RefCounted
class_name DialogueParser

var output : Array[Dictionary] = []
var sections : Dictionary = EMPTY_DICT

const REGEX_DLG_TAGS :=\
    r"\{\s*(?<tag>\w+)\s*(\=\s*(?<arg>.+?)\s*)*\}";\
    static var _regex_dlg_tags := RegEx.create_from_string(REGEX_DLG_TAGS)

const REGEX_DLG_TAGS_NEWLINE :=\
    r"^\s*(?<tag>\w+)\=((?<arg>.+))*$";\
    static var _regex_dlg_tags_newline := RegEx.create_from_string(REGEX_DLG_TAGS_NEWLINE)

const REGEX_BBCODE_TAGS :=\
    r"[\[\/]+?(?<tag>\w+)[^\[\]]*?\]";\
    static var _regex_bbcode_tags := RegEx.create_from_string(REGEX_BBCODE_TAGS)

const REGEX_FUNC_CALL :=\
    r"(?<caller>\w+)\.(?<name>\w+)\((?<args>.*)\)$";\
    static var _regex_func_call := RegEx.create_from_string(REGEX_FUNC_CALL)

const REGEX_INDENT :=\
    r"(?<=\n{1})\s+";\
    static var _regex_indent := RegEx.create_from_string(REGEX_INDENT)

const REGEX_VALID_DLG :=\
    r"\n+\w+\:\n+\s+\w+";\
    static var _regex_valid_dlg := RegEx.create_from_string(REGEX_VALID_DLG)

const REGEX_SECTION :=\
    r"^\:(.+)";\
    static var _regex_section := RegEx.create_from_string(REGEX_SECTION)

#region Dictionary keys constants
const __ACTOR := "actor"
const __LINE := "line"
const __LINE_RAW := "line_raw"
const __LINE_NUM := "line_num"
const __TAGS := "tags"
const __TAGS_DELAYS := "delays"
const __TAGS_SPEEDS := "speeds"
const __FUNC := "func"
const __FUNC_POS := "func_pos"
const __FUNC_IDX := "func_idx"
const __OFFSETS := "offsets"
const __HAS_VARS := "has_vars"
const __VARS := "vars"

const __CALLER := "caller"
const __NAME := "name"
const __ARGS := "args"
const __LN_NUM := "ln_num"
#endregion

const EMPTY_ARR := []
const EMPTY_DICT := {}

const SETS_TEMPLATE := {
    __ACTOR: EMPTY,
    __LINE: EMPTY,
    __LINE_RAW: EMPTY,
    __LINE_NUM: -1,
    __TAGS: {
        __TAGS_DELAYS: EMPTY_DICT,
            #   pos,    delay(s)
            #   15,     5
        __TAGS_SPEEDS: EMPTY_DICT,
            #   pos,    scale(f)
            #   15:     1.2
    },
    __FUNC: EMPTY_ARR,
    __FUNC_POS: EMPTY_DICT,
    __FUNC_IDX: EMPTY_ARR,
    __OFFSETS: EMPTY_DICT,
        #   start, end
        #   15: 20
    __HAS_VARS: false,
    __VARS: EMPTY_ARR,
}
const FUNC_TEMPLATE := {
    __CALLER: EMPTY,
    __NAME: EMPTY,
    __ARGS: EMPTY_ARR,
    __LN_NUM: 0,
}

const TAG_DELAY_ALIASES : PackedStringArray = [
    "DELAY", "WAIT", "D", "W"
]
const TAG_SPEED_ALIASES : PackedStringArray = [
    "SPEED", "SPD", "S"
]

const VARS_BUILT_IN_KEYS : PackedStringArray = ["n", "spc"]

const BUILT_IN_TAGS : PackedStringArray = (
    TAG_DELAY_ALIASES +
    TAG_SPEED_ALIASES +
    VARS_BUILT_IN_KEYS
)

const NEWLINE := "\n"
const SPACE := " "
const EMPTY := ""
const UNDERSCORE := "_"
const COLON := ":"
const HASH := "#"

const INDENT_2 := "  "
const INDENT_4 := "    "

static var _regex_initialized := false
static func _initialize_regex() -> void:
    _regex_dlg_tags = RegEx.create_from_string(REGEX_DLG_TAGS)
    _regex_dlg_tags_newline = RegEx.create_from_string(REGEX_DLG_TAGS_NEWLINE)
    _regex_bbcode_tags = RegEx.create_from_string(REGEX_BBCODE_TAGS)
    _regex_func_call = RegEx.create_from_string(REGEX_FUNC_CALL)
    _regex_indent = RegEx.create_from_string(REGEX_INDENT)
    _regex_valid_dlg = RegEx.create_from_string(REGEX_VALID_DLG)
    _regex_section = RegEx.create_from_string(REGEX_SECTION)

func _init(src : String = ""):
    # WHY???
    if !_regex_initialized:
        _initialize_regex()
        _regex_initialized = true

    var dlg_raw : PackedStringArray = src.split(NEWLINE)

    var body_pos : int = -1
    var dlg_raw_size : int = dlg_raw.size()
    var newline_stack : int = 0
    var dlg_line_stack : int = 0

    var regex_func_match : RegExMatch

    # Per raw string line
    for i in dlg_raw_size:
        var ln_num : int = i + 1
        var n := dlg_raw[i]
        var n_stripped := n.strip_edges()
        var is_valid_line := !n.begins_with(HASH) and !n.is_empty()

        var current_processed_string : String

        if is_valid_line and !is_indented(n) and n_stripped.ends_with(COLON):
            #region NOTE: Create new Dialogue line -------------------------------------------------
            var setsl := SETS_TEMPLATE.duplicate(true)
            newline_stack = 0
            dlg_line_stack += 1

            if dlg_raw_size < i + 1:
                printerr("Error: actor's name exists without a dialogue body")

            setsl[__ACTOR] = n_stripped.trim_suffix(COLON)
            setsl[__LINE_NUM] = ln_num

            if setsl[__ACTOR] == UNDERSCORE:
                setsl[__ACTOR] = EMPTY
            elif setsl[__ACTOR].is_empty():
                if body_pos < 0:
                    printerr("Warning: missing initial actor's name on line %d" % ln_num)
                else:
                    setsl[__ACTOR] = output[body_pos][__ACTOR]

            output.append(setsl)
            body_pos += 1
            #endregion

        elif _regex_section.search(n) != null:
            sections[
                n.split(SPACE, false, 1)[0].strip_edges().trim_prefix(COLON)
            ] = dlg_line_stack

        elif n_stripped.is_empty():
            newline_stack += 1

        elif is_valid_line and !output.is_empty():
            current_processed_string = dlg_raw[i].strip_edges()
            regex_func_match = _regex_func_call.search(current_processed_string)

            #region NOTE: Function calls -----------------------------------------------------------
            if regex_func_match != null:
                var func_dict := FUNC_TEMPLATE.duplicate(true)

                func_dict[__CALLER] = regex_func_match.get_string(
                    regex_func_match.names[__CALLER]
                )
                func_dict[__NAME] = regex_func_match.get_string(
                    regex_func_match.names[__NAME]
                )

                # Function arguments
                var args_raw := regex_func_match.get_string(
                    regex_func_match.names[__ARGS]
                ).strip_edges()

                func_dict[__LN_NUM] = ln_num

                # Parse parameter arguments
                var args := Expression.new()
                var args_err := args.parse("[%s]" % args_raw)
                if args_err != OK:
                    printerr("Error: '%s' when parsing arguments on function %s.%s(%s) on line %d" % [
                        error_string(args_err),
                        func_dict[__CALLER], func_dict[__NAME], args_raw, ln_num
                    ])

                func_dict[__ARGS] = args.execute() as Array
                output[body_pos][__FUNC].append(func_dict)
            #endregion

            #region NOTE: Newline Dialogue tags ----------------------------------------------------
            elif is_regex_full_string(_regex_dlg_tags_newline.search(current_processed_string)):
                output[body_pos][__LINE_RAW] += "{%s}" % current_processed_string
                output[body_pos][__LINE] += output[body_pos][__LINE_RAW]
            #endregion

            #region NOTE: Newline BBCode tags ------------------------------------------------------
            elif is_regex_full_string(_regex_bbcode_tags.search(current_processed_string)):
                output[body_pos][__LINE_RAW] += current_processed_string
                output[body_pos][__LINE] += current_processed_string
            #endregion

            # Dialogue text body
            else:
                if newline_stack > 0:
                    newline_stack += 1
                var dlg_body := NEWLINE.repeat(newline_stack)\
                    + current_processed_string\
                    + SPACE
                newline_stack = 0

                # Append Dialogue body
                output[body_pos][__LINE_RAW] += dlg_body
                output[body_pos][__LINE] += dlg_body

    # Per dialogue line
    for n in output.size():
        var body : String

        if output[n][__LINE_RAW].is_empty():
            printerr("Warning: empty dialogue body for '%s' on line %d" % [
                output[n][__ACTOR], output[n][__LINE_NUM]
            ])

        else:
            var parsed_tags := parse_tags(output[n][__LINE_RAW])

            for tag : String in SETS_TEMPLATE[__TAGS].keys():
                output[n][__TAGS][tag].merge(parsed_tags[__TAGS][tag])

            body = output[n][__LINE_RAW]
            for tag in _regex_dlg_tags.search_all(output[n][__LINE_RAW]):
                body = body.replace(tag.strings[0], EMPTY)

            output[n][__VARS] = parsed_tags[__VARS]
            output[n][__HAS_VARS] = parsed_tags[__HAS_VARS]
            output[n][__FUNC_POS] = parsed_tags[__FUNC_POS]
            output[n][__FUNC_IDX] = parsed_tags[__FUNC_IDX]

        output[n][__LINE] = body

    dlg_raw.clear()

## Check if [param string] is indented with tabs or spaces.
func is_indented(string : String) -> bool:
    return string != string.lstrip(" \t")

## Check if [param string] is written in a valid Dialogue string format/syntax or not.
static func is_valid_source(string : String) -> bool:
    if _regex_valid_dlg == null:
        _regex_valid_dlg = RegEx.create_from_string(REGEX_VALID_DLG)
    return _regex_valid_dlg.search(string) == null

# BUG
## Normalize indentation of the Dialogue raw string.
static func normalize_indentation(string : String) -> String:
    var indents : Array[int] = []

    if _regex_indent == null:
        _regex_indent = RegEx.create_from_string(REGEX_INDENT)

    for n in _regex_indent.search_all(string):
        var len := n.get_string(1).length()
        if !indents.has(len):
            indents.append(len)

    if indents.max() > 0:
        var spc : String
        for n in indents.min():
            spc += SPACE
        string = string.replacen(NEWLINE + spc, NEWLINE)

    indents.clear()
    return string

static func escape_brackets(string : String) -> String:
    return string\
        .replace(r"\{", "{")\
        .replace(r"\}", "}")

# 😭😭😭
static func parse_tags(string : String) -> Dictionary:
    var output : Dictionary = {}
    var vars : PackedStringArray = []
    var tags : Dictionary = SETS_TEMPLATE[__TAGS].duplicate(true)
    var func_pos : Dictionary = {}
    var func_idx : PackedInt64Array = []

    # BBCode ===============================================================
    var bb_data : Dictionary = {}
    string = string\
        .replace(r"\[", r"[lb]")\
        .replace(r"\]", r"[rb]")

    var bbcode_pos_offset : int = 0

    # Strip and log BBCode tags
    for bb in _regex_bbcode_tags.search_all(_regex_dlg_tags.sub(string, EMPTY, true)):
        var bb_start : int = bb.get_start() - bbcode_pos_offset
        var bb_end : int = bb.get_end() - bbcode_pos_offset
        var bb_tag := bb.get_string("tag")

        bb_data[bb_start] = {
            "content" : bb.strings[0],
            "img" : false,
        }

        if bb_tag == r"lb":
            string = string.replace(bb.strings[0], "[")
        elif bb_tag == r"rb":
            string = string.replace(bb.strings[0], "]")
        else:
            string = string.replace(bb.strings[0], EMPTY)

    # TODO
    # Escaped Curly Brackets ===============================================
    # 💀💀💀💀💀💀💀💀💀💀💀
    #var regex_curly_brackets := RegEx.new()
    #regex_curly_brackets.compile(r"\\\{|\\\}")
#
    #var esc_curly_brackets : Array[Dictionary] = []
#
    #for cb in regex_curly_brackets.search_all(string):
        #esc_curly_brackets.append({
            #"pos": cb.get_start(),
            #"chr": cb.strings[0],
        #})
#
    #if !esc_curly_brackets.is_empty():
        #esc_curly_brackets.reverse()
        #string = regex_curly_brackets.sub(string, "-", true)

    # Dialogue tags ========================================================
    var tag_pos_offset : int = 0

    for b in _regex_dlg_tags.search_all(string):
        var string_match := b.strings[0]

        var tag_pos : int = b.get_start() - tag_pos_offset
        var tag_key := b.get_string("tag").to_upper()
        var tag_key_l := b.get_string("tag")
        var tag_value := b.get_string("arg")

        if TAG_DELAY_ALIASES.has(tag_key):
            tags[__TAGS_DELAYS][tag_pos] = float(tag_value)
        elif TAG_SPEED_ALIASES.has(tag_key):
            tags[__TAGS_SPEEDS][tag_pos] = float(
                1.0 if tag_value.is_empty() else tag_value
            )

        if !(tag_key_l in VARS_BUILT_IN_KEYS):
            string = string.replace(string_match, EMPTY)

        if tag_key_l.is_valid_int():
            var idx = tag_key_l.to_int()
            func_pos[tag_pos] = idx

            if !func_idx.has(idx):
                func_idx.append(idx)

        if !BUILT_IN_TAGS.has(tag_key) and\
            !(tag_key_l in vars) and\
            !tag_key_l.is_valid_int():
            vars.append(tag_key_l)

        tag_pos_offset += string_match.length()

    # TODO
    # Insert back escaped curly brackets ===================================
    #for cb in esc_curly_brackets:
        #string = string\
            #.erase(cb["pos"])\
            #.insert(cb["pos"], cb["chr"])

    # Insert back BBCodes ==================================================
    string = string\
        .replace("[", EMPTY)\
        .replace("]", EMPTY)

    for bb in bb_data:
        string = string.insert(bb, bb_data[bb]["content"])

    output[__TAGS] = tags
    output["string"] = string
    output[__FUNC_POS] = func_pos
    output[__FUNC_IDX] = func_idx
    output[__VARS] = vars
    output[__HAS_VARS] = !vars.is_empty()

    return output

# Temporary solution when using variables and tags at the same time
# Might not be performant when dealing with real-time variables
## Format Dialogue body at [param pos] position with [member Stage.variables], and update the positions of the built-in tags.
## Return the formatted string.
static func update_tags_position(dlg : Dialogue, pos : int, vars : Dictionary) -> void:
    var dlg_str : String = dlg._sets[pos][__LINE_RAW].format(vars)
    for n in [__TAGS_DELAYS, __TAGS_SPEEDS]:
        dlg._sets[pos][__TAGS][n].clear()

    var parsed_tags := parse_tags(dlg_str)

    dlg._sets[pos][__TAGS] = parsed_tags[__TAGS]
    dlg._sets[pos][__LINE] = parsed_tags["string"]
    dlg._sets[pos][__VARS] = parsed_tags[__VARS]
    dlg._sets[pos][__HAS_VARS] = parsed_tags[__HAS_VARS]
    dlg._sets[pos][__FUNC_POS] = parsed_tags[__FUNC_POS]
    dlg._sets[pos][__FUNC_IDX] = parsed_tags[__FUNC_IDX]

static func is_regex_full_string(regex_match : RegExMatch) -> bool:
    if regex_match == null:
        return false
    return regex_match.get_start() == 0 and\
        regex_match.get_end() == regex_match.subject.length()
