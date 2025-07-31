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
    r"(?<!\\)(?:\\\\)*\{\s*(?<tag>\w+)\s*(?<sym>\=|\.)?\s*(?<val>(?:[^\\\{\}]|\\[\{\}])*?)\s*(?<!\\)\}";\
    static var _regex_dlg_tags := RegEx.create_from_string(REGEX_DLG_TAGS)

# Match Dialogue tags newline syntax:
#       d=1.0
#       delay=1.0
const REGEX_DLG_TAGS_NEWLINE :=\
    r"^\s*(?<tag>\w+)\=((?<arg>.+))*$";\
    static var _regex_dlg_tags_newline := RegEx.create_from_string(REGEX_DLG_TAGS_NEWLINE)

const REGEX_BBCODE_TAGS :=\
    r"(?<!\\)\[\/?(?<tag>\w+)[^\[\]]*?(?<!\\)\]";\
    static var _regex_bbcode_tags := RegEx.create_from_string(REGEX_BBCODE_TAGS)

# Match variables assignments:
#       Scope.name = value
#       Scope.name += value
const REGEX_VARS_SET :=\
    r"(?<scope>\w+)\.(?<name>\w+)\s*(?<op>[\+\-\*\/])?\=\s*(?<val>.+)$";\
    static var _regex_vars_set := RegEx.create_from_string(REGEX_VARS_SET)

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
    r"(?m)\w+:\n\s+(.[^\s])+?";\
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

    SCOPE,
    NAME,
    ARGS,
    LN_NUM,
    STANDALONE,
}
#endregion

## Dictionary template for each Dialogue line.
const SETS_TEMPLATE := {
    # Actor's name.
    Key.ACTOR: EMPTY,

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
    Key.LN_NUM: 0,

    Key.STANDALONE: true,
    Key.VARS: [],
}

#region Built in tags and variables
const TAG_DELAY_ALIASES : PackedStringArray = [
    "DELAY", "WAIT", "D", "W"
]
const TAG_SPEED_ALIASES : PackedStringArray = [
    "SPEED", "SPD", "S"
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
}

const BB_ALIASES_TAGS : PackedStringArray = [
    "bg", "fg", "col", "c"
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
static var _regex_initialized := false
static func _initialize_regex() -> void:
    _regex_dlg_tags = RegEx.create_from_string(REGEX_DLG_TAGS)
    _regex_dlg_tags_newline = RegEx.create_from_string(REGEX_DLG_TAGS_NEWLINE)
    _regex_bbcode_tags = RegEx.create_from_string(REGEX_BBCODE_TAGS)
    _regex_vars_set = RegEx.create_from_string(REGEX_VARS_SET)
    _regex_func_call = RegEx.create_from_string(REGEX_FUNC_CALL)
    _regex_func_vars = RegEx.create_from_string(REGEX_FUNC_VARS)
    _regex_indent = RegEx.create_from_string(REGEX_INDENT)
    _regex_valid_dlg = RegEx.create_from_string(REGEX_VALID_DLG)
    _regex_section = RegEx.create_from_string(REGEX_SECTION)
#endregion

func _init(src : String = "", src_path : String = ""):
    # WHY???
    if !_regex_initialized:
        _initialize_regex()
        _regex_initialized = true

    if !src_path.is_empty():
        _source_path = src_path

    var dlg_raw : PackedStringArray = src.split(NEWLINE)

    var body_pos : int = -1
    var dlg_raw_size : int = dlg_raw.size()
    var newline_stack : int = 0
    var dlg_line_stack : int = 0

    var regex_func_match : RegExMatch
    var regex_vars_match : RegExMatch

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
                push_error("Error @%s:%d - actor's name exists without a dialogue body" % [_source_path, ln_num])

            setsl[Key.ACTOR] = StringName(n_stripped.trim_suffix(COLON))

            if setsl[Key.ACTOR] == UNDERSCORE:
                setsl[Key.ACTOR] = EMPTY
            elif setsl[Key.ACTOR].is_empty():
                if body_pos < 0:
                    push_error("Error @%s - missing initial actor's name" % _source_path)
                else:
                    setsl[Key.ACTOR] = output[body_pos][Key.ACTOR]

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

            if regex_func_match == null:
                regex_vars_match = _regex_vars_set.search(current_processed_string)

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

                func_dict[Key.LN_NUM] = ln_num

                # Parse parameter arguments
                var args := Expression.new()
                var args_err := args.parse("[" + args_raw + "]")
                var var_matches := _regex_func_vars.search_all(args_raw)

                if var_matches.is_empty():
                    func_dict[Key.ARGS] = args.execute()

                    if args.has_execute_failed():
                        push_error("Error @%s:%d - %s" % [_source_path, ln_num, args.get_error_text()])

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
                func_dict[Key.LN_NUM] = ln_num

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
                        push_error("Error @%s:%d - %s" % [_source_path, ln_num, val.get_error_text()])

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

            #region NOTE: Newline Dialogue tags ----------------------------------------------------
            elif is_regex_full_string(_regex_dlg_tags_newline.search(current_processed_string)):
                output[body_pos][Key.CONTENT_RAW] += "{%s}" % current_processed_string
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
            push_error("Error @%s:%d - empty dialogue body for actor '%s'" % [
                _source_path, output[n][Key.LINE_NUM], output[n][Key.ACTOR]
            ])

        else:
            #region NOTE: Resolve BBCode aliases
            var match_bb := _regex_bbcode_tags.search_all(content_str)

            if !match_bb.is_empty():
                match_bb.reverse()
                var tag : String
                var start : int

                for bb in match_bb:
                    tag = bb.get_string("tag")

                    if BB_ALIASES_TAGS.has(tag):
                        start = bb.get_start("tag")
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

            var parsed_tags := parse_tags(content_str)

            for tag : int in SETS_TEMPLATE[Key.TAGS].keys():
                output[n][Key.TAGS][tag].merge(parsed_tags[Key.TAGS][tag])

            body = content_str
            for tag in _regex_dlg_tags.search_all(content_str):
                body = body.replace(tag.strings[0], EMPTY)

            output[n][Key.VARS] = parsed_tags[Key.VARS]
            output[n][Key.VARS_SCOPE] = parsed_tags[Key.VARS_SCOPE]
            output[n][Key.HAS_VARS] = parsed_tags[Key.HAS_VARS]
            output[n][Key.FUNC_POS] = parsed_tags[Key.FUNC_POS]
            output[n][Key.FUNC_IDX] = parsed_tags[Key.FUNC_IDX]

        output[n][Key.FUNC].make_read_only()
        output[n][Key.CONTENT] = body

## Check if [param string] is indented with tabs or spaces.
func is_indented(string : String) -> bool:
    return string != string.lstrip(" \t")

## Check if [param string] is written in a valid Dialogue string format/syntax or not.
static func is_valid_source(string : String) -> bool:
    if _regex_valid_dlg == null:
        _regex_valid_dlg = RegEx.create_from_string(REGEX_VALID_DLG)
    return _regex_valid_dlg.search(string) != null

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
        string = string.replacen(NEWLINE + SPACE.repeat(indents.min()), NEWLINE)

    return string

static func escape_brackets(string : String) -> String:
    return string\
        .replace(r"\{", "{")\
        .replace(r"\}", "}")

# 😭😭😭
static func parse_tags(string : String) -> Dictionary:
    var output : Dictionary = {}
    var vars : PackedStringArray = []
    var vars_scope : PackedStringArray = []
    var tags : Dictionary = SETS_TEMPLATE[Key.TAGS].duplicate(true)
    var func_pos : Dictionary = {}
    var func_idx : PackedInt64Array = []

    # BBCode ===============================================================
    var bb_data : Array[Dictionary] = []
    var bbcode_pos_offset : int = 0

    # Escaped Equal Sign ===================================================
    string = string.replace("\\=", "=")

    # Strip and log BBCode tags
    for bb in _regex_bbcode_tags.search_all(_regex_dlg_tags.sub(string, EMPTY, true)):
        var bb_start : int = bb.get_start() - bbcode_pos_offset
        var bb_end : int = bb.get_end() - bbcode_pos_offset
        var bb_tag := bb.get_string("tag")

        bb_data.append({
            "pos" : bb_start,
            "content" : bb.strings[0],
            #"img" : false,
        })

        if bb_tag == r"lb":
            string = string.replace(bb.strings[0], "[")
        elif bb_tag == r"rb":
            string = string.replace(bb.strings[0], "]")
        else:
            string = string.replace(bb.strings[0], EMPTY)

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

    for b in _regex_dlg_tags.search_all(string):
        var string_match := b.strings[0]

        var tag_pos : int = b.get_start() - tag_pos_offset
        var tag_key_l := b.get_string("tag")
        var tag_key := tag_key_l.to_upper()
        var tag_value := b.get_string(__VAL)
        var tag_sym := b.get_string(__SYM)

        # Position-based function calls.
        if tag_key_l.is_valid_int():
            var idx : int = tag_key_l.to_int()

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

        elif tag_sym == DOT:
            vars_scope.append(tag_key_l + DOT + tag_value)

        #elif tag_sym == "=": # NOTE: conflicting with the {s} shorthand alias to reset the rendering speed.
        #region NOTE: built in tags.
        elif TAG_DELAY_ALIASES.has(tag_key):
            tags[Key.TAGS_DELAYS][tag_pos] = float(tag_value)

        elif TAG_SPEED_ALIASES.has(tag_key):
            tags[Key.TAGS_SPEEDS][tag_pos] = 1.0 if tag_value.is_empty() else tag_value.to_float()
        #endregion

        # User defined variables.
        elif tag_key_l not in vars:
            vars.append(tag_key_l)

        string = string.replace(string_match, EMPTY)

        tag_pos_offset += string_match.length()

    # Insert back escaped curly brackets ===================================
    for cb in esc_curly_brackets.keys():
        string = string\
            .erase(cb)\
            .insert(cb, esc_curly_brackets[cb])

    # Insert back BBCodes ==================================================
    string = string\
        .replace("[", EMPTY)\
        .replace("]", EMPTY)

    for bb : Dictionary in bb_data:
        string = string.insert(bb["pos"], bb["content"])

    output[Key.TAGS] = tags
    output["string"] = string
    output[Key.FUNC_POS] = func_pos
    output[Key.FUNC_IDX] = func_idx
    output[Key.VARS] = vars
    output[Key.VARS_SCOPE] = vars_scope
    output[Key.HAS_VARS] = not vars.is_empty() or not vars_scope.is_empty()

    return output

# Temporary solution when using variables and tags at the same time
# Might not be performant when dealing with real-time variables
## Format Dialogue body at [param pos] position with [member TheatreStage.variables], and update the positions of the built-in tags.
## Return the formatted string.
static func update_tags_position(dlg : Dialogue, pos : int, vars : Dictionary) -> void:
    var dlg_str : String = dlg._sets[pos][Key.CONTENT_RAW].format(vars)

    dlg._sets[pos][Key.TAGS][Key.TAGS_DELAYS].clear()
    dlg._sets[pos][Key.TAGS][Key.TAGS_SPEEDS].clear()

    var parsed_tags := parse_tags(dlg_str)

    dlg._sets[pos][Key.TAGS] = parsed_tags[Key.TAGS]
    dlg._sets[pos][Key.CONTENT] = parsed_tags["string"]
    dlg._sets[pos][Key.VARS] = parsed_tags[Key.VARS]
    dlg._sets[pos][Key.VARS_SCOPE] = parsed_tags[Key.VARS_SCOPE]
    dlg._sets[pos][Key.HAS_VARS] = parsed_tags[Key.HAS_VARS]
    dlg._sets[pos][Key.FUNC_POS] = parsed_tags[Key.FUNC_POS]
    dlg._sets[pos][Key.FUNC_IDX] = parsed_tags[Key.FUNC_IDX]

static func is_regex_full_string(regex_match : RegExMatch) -> bool:
    if regex_match == null:
        return false
    return regex_match.get_start() == 0 and\
        regex_match.get_end() == regex_match.subject.length()
