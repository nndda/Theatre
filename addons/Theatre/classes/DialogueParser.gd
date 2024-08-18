extends RefCounted
class_name DialogueParser

var output : Array[Dictionary]
var sections : Dictionary = {}

const REGEX_DLG_TAGS :=\
    r"\{\s*(?<tag>\w+)\s*(\=\s*(?<arg>.+?)\s*)*\}";\
    static var _regex_dlg_tags := RegEx.create_from_string(REGEX_DLG_TAGS)

const REGEX_DLG_TAGS_NEWLINE :=\
    r"^\s*(?<tag>\w+)\=((?<arg>.+))*$";\
    static var _regex_dlg_tags_newline : RegEx

const REGEX_BBCODE_TAGS :=\
    r"[\[\/]+?(?<tag>\w+)[^\[\]]*?\]";\
    static var _regex_bbcode_tags := RegEx.create_from_string(REGEX_BBCODE_TAGS)

const REGEX_FUNC_CALL :=\
    r"(?<caller>\w+)\.(?<name>\w+)\((?<args>.*)\)$";\
    static var _regex_func_call : RegEx

const REGEX_INDENT :=\
    r"(?<=\n{1})\s+";\
    static var _regex_indent : RegEx

const REGEX_VALID_DLG :=\
    r"\n+\w+\:\n+\s+\w+";\
    static var _regex_valid_dlg := RegEx.create_from_string(REGEX_VALID_DLG)

const REGEX_SECTION :=\
    r"^\:(.+)";\
    static var _regex_section : RegEx

const SETS_TEMPLATE := {
    "actor": "",
    "line": "",
    "line_raw": "",
    "line_num": -1,
    "tags": {
        "delays": {
            #   pos,    delay(s)
            #   15,     5
        },
        "speeds": {
            #   pos,    scale(f)
            #   15:     1.2
        },
    },
    "func": [],
    "func_pos": {},
    "func_idx": [],
    "offsets": {
        #   start, end
        #   15: 20
    },
    "has_vars": false,
    "vars": [],
}
const FUNC_TEMPLATE := {
    "caller": "",
    "name": "",
    "args": [],
    "ln_num": 0,
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

    output = []
    sections = {}
    var dlg_raw : PackedStringArray = src.split("\n")

    var body_pos : int = 0
    var dlg_raw_size : int = dlg_raw.size()
    var newline_stack : int = 0
    var dlg_line_stack : int = 0

    var regex_func_match : RegExMatch

    # Per raw string line
    for i in dlg_raw_size:
        var ln_num : int = i + 1
        var n := dlg_raw[i]
        var is_valid_line := !n.begins_with("#") and !n.is_empty()

        var current_processed_string : String = ""

        if is_valid_line and !is_indented(n) and n.strip_edges().ends_with(":"):
            #region NOTE: Create new Dialogue line -------------------------------------------------
            var setsl := SETS_TEMPLATE.duplicate(true)
            newline_stack = 0
            dlg_line_stack += 1

            if dlg_raw_size < i + 1:
                printerr("Error: actor's name exists without a dialogue body")

            setsl["actor"] = n.strip_edges().trim_suffix(":")
            setsl["line_num"] = ln_num

            if setsl["actor"] == "_":
                setsl["actor"] = ""
            elif setsl["actor"].is_empty():
                if output.size() - 1 < 0:
                    printerr("Warning: missing initial actor's name on line %d" % ln_num)
                else:
                    setsl["actor"] = output[output.size() - 1]["actor"]

            output.append(setsl)
            body_pos = output.size() - 1
            #endregion

        elif _regex_section.search(n) != null:
            sections[
                n.split(" ", false, 1)[0].strip_edges().trim_prefix(":")
            ] = dlg_line_stack

        elif n.strip_edges().is_empty():
            newline_stack += 1

        elif is_valid_line and !output.is_empty():
            current_processed_string = dlg_raw[i].strip_edges()
            regex_func_match = _regex_func_call.search(current_processed_string)

            #region NOTE: Function calls -----------------------------------------------------------
            if regex_func_match != null:
                var func_dict := FUNC_TEMPLATE.duplicate(true)
                for func_n : String in [
                    "caller", "name",
                ]:
                    func_dict[func_n] = regex_func_match.get_string(
                        regex_func_match.names[func_n]
                    )

                # Function arguments
                var args_raw := regex_func_match.get_string(
                    regex_func_match.names["args"]
                ).strip_edges()

                func_dict["ln_num"] = ln_num

                # Parse parameter arguments
                var args := Expression.new()
                var args_err := args.parse("[%s]" % args_raw)
                if args_err != OK:
                    printerr("Error: '%s' when parsing arguments on function %s.%s(%s) on line %d" % [
                        error_string(args_err),
                        func_dict["caller"], func_dict["name"], args_raw, ln_num
                    ])

                func_dict["args"] = args.execute() as Array
                output[body_pos]["func"].append(func_dict)
            #endregion

            #region NOTE: Newline Dialogue tags ----------------------------------------------------
            elif is_regex_full_string(_regex_dlg_tags_newline.search(current_processed_string)):
                output[body_pos]["line_raw"] += "{%s}" % current_processed_string
                output[body_pos]["line"] += output[body_pos]["line_raw"]
            #endregion

            #region NOTE: Newline BBCode tags ------------------------------------------------------
            elif is_regex_full_string(_regex_bbcode_tags.search(current_processed_string)):
                output[body_pos]["line_raw"] += current_processed_string
                output[body_pos]["line"] += current_processed_string
            #endregion

            # Dialogue text body
            else:
                if newline_stack > 0:
                    newline_stack += 1
                var dlg_body := "\n".repeat(newline_stack)\
                    + current_processed_string\
                    + " "
                newline_stack = 0

                # Append Dialogue body
                output[body_pos]["line_raw"] += dlg_body
                output[body_pos]["line"] += dlg_body

    # Per dialogue line
    for n in output.size():
        var body : String = ""

        if output[n]["line_raw"].is_empty():
            printerr("Warning: empty dialogue body for '%s' on line %d" % [
                output[n]["actor"], output[n]["line_num"]
            ])

        else:
            var parsed_tags := parse_tags(output[n]["line_raw"])

            for tag : String in SETS_TEMPLATE["tags"].keys():
                output[n]["tags"][tag].merge(parsed_tags["tags"][tag])

            var regex_tags_match := _regex_dlg_tags.search_all(output[n]["line_raw"])

            body = output[n]["line_raw"]
            for tag in regex_tags_match:
                body = body.replace(tag.strings[0], "")

            output[n]["vars"] = parsed_tags["vars"]
            output[n]["has_vars"] = parsed_tags["has_vars"]
            output[n]["func_pos"] = parsed_tags["func_pos"]
            output[n]["func_idx"] = parsed_tags["func_idx"]

        output[n]["line"] = body

    dlg_raw.clear()

## Check if [param string] is indented with tabs or spaces.
func is_indented(string : String) -> bool:
    return string != string.lstrip(" \t")

## Check if [param string] is written in a valid Dialogue string format/syntax or not.
static func is_valid_source(string : String) -> bool:
    return _regex_valid_dlg.search(string) == null

# BUG
## Normalize indentation of the Dialogue raw string.
static func normalize_indentation(string : String) -> String:
    var indents : Array[int] = []

    for n in _regex_indent.search_all(string):
        var len := n.get_string(1).length()
        if !indents.has(len):
            indents.append(len)

    if indents.max() > 0:
        var spc := ""
        for n in indents.min():
            spc += " "
        string = string.replacen("\n" + spc, "\n")

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
    var tags : Dictionary = SETS_TEMPLATE["tags"].duplicate(true)
    var func_pos : Dictionary = {}
    var func_idx : PackedInt64Array = []

    # BBCode ===============================================================
    var bb_data : Dictionary = {}
    string = string\
        .replace(r"\[", r"[lb]")\
        .replace(r"\]", r"[rb]")

    var stripped_tags := _regex_dlg_tags.sub(string, "", true)

    var bbcode_pos_offset : int = 0

    # Strip and log BBCode tags
    for bb in _regex_bbcode_tags.search_all(stripped_tags):
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
            string = string.replace(bb.strings[0], "")

    # Escaped Curly Brackets ===============================================
    # 💀💀💀💀💀💀💀💀💀💀💀
    var regex_curly_brackets := RegEx.new()
    regex_curly_brackets.compile(r"\\\{|\\\}")

    var esc_curly_brackets : Array[Dictionary] = []

    for cb in regex_curly_brackets.search_all(string):
        esc_curly_brackets.append({
            "pos": cb.get_start(),
            "chr": cb.strings[0],
        })

    if !esc_curly_brackets.is_empty():
        esc_curly_brackets.reverse()
        string = regex_curly_brackets.sub(string, "-", true)

    # Dialogue tags ========================================================
    var tag_pos_offset : int = 0

    for b in _regex_dlg_tags.search_all(string):
        var string_match := b.strings[0]

        var tag_pos : int = b.get_start() - tag_pos_offset
        var tag_key := b.get_string("tag").to_upper()
        var tag_key_l := b.get_string("tag")
        var tag_value := b.get_string("arg")

        if TAG_DELAY_ALIASES.has(tag_key):
            tags["delays"][tag_pos] = float(tag_value)
        elif TAG_SPEED_ALIASES.has(tag_key):
            tags["speeds"][tag_pos] = float(
                1.0 if tag_value.is_empty() else tag_value
            )

        if !(tag_key_l in VARS_BUILT_IN_KEYS):
            string = string.replace(string_match, "")

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

    # Insert back escaped curly brackets ===================================
    for cb in esc_curly_brackets:
        string = string\
            .erase(cb["pos"])\
            .insert(cb["pos"], cb["chr"])

    # Insert back BBCodes ==================================================
    string = string\
        .replace("[", "")\
        .replace("]", "")

    for bb in bb_data:
        string = string.insert(bb, bb_data[bb]["content"])

    output["tags"] = tags
    output["string"] = string
    output["func_pos"] = func_pos
    output["func_idx"] = func_idx
    output["vars"] = vars
    output["has_vars"] = !vars.is_empty()

    return output

# Temporary solution when using variables and tags at the same time
# Might not be performant when dealing with real-time variables
## Format Dialogue body at [param pos] position with [member Stage.variables], and update the positions of the built-in tags.
## Return the formatted string.
static func update_tags_position(dlg : Dialogue, pos : int, vars : Dictionary) -> void:
    var dlg_str : String = dlg._sets[pos]["line_raw"].format(vars)
    for n in ["delays", "speeds"]:
        dlg._sets[pos]["tags"][n].clear()

    var parsed_tags := parse_tags(dlg_str)

    dlg._sets[pos]["tags"] = parsed_tags["tags"]
    dlg._sets[pos]["line"] = parsed_tags["string"]
    dlg._sets[pos]["vars"] = parsed_tags["vars"]
    dlg._sets[pos]["has_vars"] = parsed_tags["has_vars"]
    dlg._sets[pos]["func_pos"] = parsed_tags["func_pos"]
    dlg._sets[pos]["func_idx"] = parsed_tags["func_idx"]

static func is_regex_full_string(regex_match : RegExMatch) -> bool:
    if regex_match == null:
        return false
    return regex_match.get_start() == 0 and\
        regex_match.get_end() == regex_match.subject.length()
