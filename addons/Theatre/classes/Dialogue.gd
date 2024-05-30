class_name Dialogue
extends Resource

# TODO: handle errors and non-Dialogue text files
# TODO: localization support

# low priority
# TODO: something to flag that the dialogue have been played or not. Maybe something that utilize `user://` savedata

## A Dialogue resource, saved as sets of instruction on how the Dialogue flow.

## Parser class for processing the raw string used for the dialogue.
class Parser extends RefCounted:
    var output : Array[Dictionary]

    const REGEX_DLG_TAGS :=\
        r"\{\s*(?<tag>\w+)\s*(\=\s*(?<arg>.+?)\s*)*\}"
    const REGEX_BBCODE_TAGS :=\
        r"(?<tag>[\[\/]+?\w+)[^\[\]]*?\]"
    const REGEX_FUNC_CALL :=\
        r"(?<caller>\w+)\.(?<name>\w+)\((?<args>.*)\)$"
    const REGEX_PLACEHOLDER :=\
        r"\{(\w+?)\}"
    const REGEX_INDENT :=\
        r"(?<=\n{1})\s+"
    const REGEX_VALID_DLG :=\
        r"\n+\w+\:\n+\s+\w+"

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
        "offsets": {
            #   start, end
            #   15: 20
        },
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

    const VARS_BUILT_IN_KEYS : PackedStringArray = ["n"]

    const BUILT_IN_TAGS : PackedStringArray = (
        TAG_DELAY_ALIASES +
        TAG_SPEED_ALIASES +
        VARS_BUILT_IN_KEYS
    )

    func _init(src : String = ""):
        output = []
        var dlg_raw : PackedStringArray = src.split("\n")

        var body_pos : int = 0
        var dlg_raw_size = dlg_raw.size()

        for i in dlg_raw_size:
            var ln_num : int = i + 1
            var n := dlg_raw[i]
            var is_valid_line := !n.begins_with("#") and !n.is_empty()

            if is_valid_line and !is_indented(n) and n.strip_edges().ends_with(":"):
                var setsl := SETS_TEMPLATE.duplicate(true)

                if dlg_raw_size < i + 1:
                    printerr("Error: actor's name exists without a dialogue body")

                setsl["actor"] = n.strip_edges().trim_suffix(":")
                setsl["line_num"] = ln_num

                if setsl["actor"] == "_":
                    setsl["actor"] = ""
                elif setsl["actor"] == "":
                    if output.size() - 1 < 0:
                        printerr("Warning: missing initial actor's name on line %d" % ln_num)
                    else:
                        setsl["actor"] = output[output.size() - 1]["actor"]

                output.append(setsl)
                body_pos = output.size() - 1

            elif is_valid_line:
                # Function calls
                var regex_func := RegEx.new()
                regex_func.compile(REGEX_FUNC_CALL)
                var regex_func_match := regex_func.search(dlg_raw[i].strip_edges())

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
                    var args = str_to_var("[%s]" % args_raw)

                    func_dict["ln_num"] = ln_num

                    if args == null:
                        printerr("Error: null arguments on function %s.%s(%s) on line %d" % [
                            func_dict["caller"], func_dict["name"], args_raw, ln_num
                        ])

                    func_dict["args"] = args
                    output[body_pos]["func"].append(func_dict)

                # Dialogue text body
                else:
                    var dlg_body := dlg_raw[i].strip_edges() + " "

                    # Append Dialogue body
                    output[body_pos]["line_raw"] += dlg_body
                    output[body_pos]["line"] += dlg_body

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

                var regex_tags := RegEx.new()
                regex_tags.compile(REGEX_DLG_TAGS)
                var regex_tags_match := regex_tags.search_all(output[n]["line_raw"])

                body = output[n]["line_raw"]
                for tag in regex_tags_match:
                    body = body.replace(tag.strings[0], "")

                output[n]["vars"] = parsed_tags["variables"]

            output[n]["line"] = body

    ## Check if [param string] is indented with tabs or spaces.
    func is_indented(string : String) -> bool:
        return string != string.lstrip(" \t")

    ## Check if [param string] is written in a valid Dialogue string format/syntax or not.
    static func is_valid_source(string : String) -> bool:
        var regex := RegEx.new()
        regex.compile(REGEX_VALID_DLG)
        return regex.search(string) == null

    ## Normalize indentation of the Dialogue raw string.
    func normalize_indentation(string : String) -> String:
        var regex := RegEx.new()
        var indents : Array[int] = []

        regex.compile(REGEX_INDENT)
        for n in regex.search_all(string):
            var len := n.get_string(1).length()
            if !indents.has(len):
                indents.append(n.get_string(1).length())

        if indents.max() > 0:
            var spc := ""
            for n in indents.min():
                spc += " "
            string = string.replacen("\n" + spc, "\n")

        return string

    # 😭😭😭
    static func parse_tags(string : String) -> Dictionary:
        var output : Dictionary = {}
        var vars : PackedStringArray = []
        var tags : Dictionary = SETS_TEMPLATE["tags"].duplicate(true)

        var regex_tags := RegEx.new()
        regex_tags.compile(REGEX_DLG_TAGS)

        # BBCode ===============================================================
        var bb_data : Dictionary = {}
        # Strip all Dialogue tags to process BBCode tags
        var stripped_tags := regex_tags.sub(string, "", true)

        var regex_bbcode := RegEx.new()
        regex_bbcode.compile(REGEX_BBCODE_TAGS)
        var regex_bbcode_match := regex_bbcode.search_all(stripped_tags)

        var bbcode_pos_offset : int = 0

        # Strip and log BBCode tags
        for bb in regex_bbcode_match:
            var bb_start : int = bb.get_start() - bbcode_pos_offset
            var bb_end : int = bb.get_end() - bbcode_pos_offset

            bb_data[bb_start] = {
                "content" : bb.strings[0],
                "img" : false,
            }

            string = string.replace(bb.strings[0], "")

            if bb.get_string("tag") == "[img":
                bb_data[bb_start]["img"] = true
                bb_data[bb_start]["img-pos"] = bb_end
                bb_data[bb_start]["img-res"] = string.substr(
                    bb_start, string.find("[/img]", bb_start) - bb_start
                )

                string = string\
                    .erase(bb_start, bb_data[bb_start]["img-res"].length())\
                    .insert(bb_start, "i")

                #bbcode_pos_offset += bb_data[bb_start]["img-res"].length()

        # Dialogue tags ========================================================
        var regex_tags_match := regex_tags.search_all(string)

        var tag_pos_offset : int = 0

        for b in regex_tags_match:
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

            if !BUILT_IN_TAGS.has(tag_key) and !(tag_key_l in vars):
                vars.append(tag_key_l)

            if !(tag_key_l in VARS_BUILT_IN_KEYS):
                string = string.replace(string_match, "")

            tag_pos_offset += string_match.length()

        for bb in bb_data:
            string = string.insert(bb, bb_data[bb]["content"])

            if bb_data[bb]["img"]:
                string = string.erase(bb_data[bb]["img-pos"], 1)
                string = string.insert(
                    bb_data[bb]["img-pos"],
                    bb_data[bb]["img-res"],
                )

        output["tags"] = tags
        output["string"] = string
        output["variables"] = vars

        return output

    # Temporary solution when using variables and tags at the same time
    # Might not be performant when dealing with real-time variables
    ## Format Dialogue body at [param pos] position with [member Stage.variables], and update the positions of the built-in tags.
    ## Return the formatted string.
    static func update_tags_position(dlg : Dialogue, pos : int, vars : Dictionary) -> void:
        var dlg_str : String = dlg.sets[pos]["line_raw"].format(vars)
        for n in ["delays", "speeds"]:
            dlg.sets[pos]["tags"][n].clear()

        var parsed_tags := parse_tags(dlg_str)

        dlg.sets[pos]["tags"] = parsed_tags["tags"]
        dlg.sets[pos]["line"] = parsed_tags["string"]
        dlg.sets[pos]["vars"] = parsed_tags["variables"]

#static var default_lang := "en"

@export var sets : Array[Dictionary] = []

@export var source_path : String = ""

func _init(dlg_src : String = ""):
    sets = []
    var parser : Parser

    if is_valid_filename(dlg_src):
        print("Parsing Dialogue from file: %s..." % dlg_src)
        if FileAccess.file_exists(dlg_src):
            source_path = dlg_src
            parser = Parser.new(FileAccess.get_file_as_string(dlg_src))
            sets = parser.output
        else:
            push_error("Unable to create Dialogue resource: '%s' does not exists" % dlg_src)

    elif (
        # TODO: maybe this one check not needed
        dlg_src.get_slice_count("\n") >= 2 and
        Parser.is_valid_source(dlg_src)
        ):
        print("Parsing Dialogue from raw string: ", get_stack())
        parser = Parser.new(dlg_src)
        sets = parser.output

    # BUG? Loading Dialogue with @GDScript load() also trigger this
    #else:
        #push_error("Unable to create Dialogue resource: unkbown source:", dlg_src)

static func is_valid_filename(filename : String) -> bool:
    return (
        (filename.begins_with("res://") or filename.begins_with("user://"))
        and filename.get_file().is_valid_filename()
        and filename.ends_with(".dlg.txt")
    )

static func load(dlg_src : String) -> Dialogue:
    if is_valid_filename(dlg_src):
        # Find filename alias
        var dlg_compiled := dlg_src.trim_suffix(".txt")

        if FileAccess.file_exists(dlg_compiled + ".res"):
            dlg_compiled += ".res"
        elif FileAccess.file_exists(dlg_compiled + ".tres"):
            dlg_compiled += ".tres"

        print("Getting Dialogue from file: %s..." % dlg_compiled)

        if FileAccess.file_exists(dlg_compiled):
            var dlg := load(dlg_compiled)
            return dlg as Dialogue
        else:
            push_warning("Compiled Dialogue %s does'nt exists. Creating new dialogue" % dlg_compiled)
            return Dialogue.new(dlg_src)

    else:
        print("Parsing Dialogue from raw string: ", get_stack())
        return Dialogue.new(dlg_src)

func get_actors() -> PackedStringArray:
    var output : PackedStringArray = []
    for n in sets:
        if !output.has(n.actor):
            output.append(n.actor)
    return output

func get_length() -> int:
    return sets.size()

func get_word_count(variables : Dictionary = {}) -> int:
    var output : int = 0
    var text : String
    for n in sets:
        for chr in ":;.,{}-":
            text = n["line_raw"]\
                .format(variables)\
                .replace(chr, " ")
        output += text.split(" ", false).size()
    return output

func humanize(variables : Dictionary = {}) -> String:
    var output := ""
    for n in sets:
        output += n.actor +\
            ":\n  " + n.line + "\n\n"
    return output.format(variables)

func to_json(path : String) -> Error:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(
        JSON.stringify(sets, "  ", true, true)
    )
    file.close()
    return file.get_error()
