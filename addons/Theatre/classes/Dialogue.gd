@icon("res://addons/Theatre/assets/icons/classes/feather-pointed.svg")
class_name Dialogue
extends Resource

## Compiled [Dialogue] resource.
##
## This is the resource that have been parsed and processed from the written [Dialogue].
## Load it from the text file with [method Dialogue.load], or write it directly in script using [method Dialogue.new]
## [codeblock]
## var dlg = Dialogue.load("res://your_dialogue.dlg")
##
## var dlg = Dialogue.new("""
##
## Godette:
##      "Hello world!"
##
## """)
## [/codeblock]

#region NOTE: Parser -------------------------------------------------------------------------------
# Parser class for processing the raw string used for the dialogue.
class _Parser extends RefCounted:
    var output : Array[Dictionary]

    #region NOTE: RegExes, templates, and built-ins ------------------------------------------------
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
        "func_pos": {},
        "func_idx": [],
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
    #endregion

    func _init(src : String = ""):
        output = []
        var dlg_raw : PackedStringArray = src.split("\n")

        var body_pos : int = 0
        var dlg_raw_size : int = dlg_raw.size()

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
                elif setsl["actor"].is_empty():
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
                output[n]["func_pos"] = parsed_tags["func_pos"]
                output[n]["func_idx"] = parsed_tags["func_idx"]

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
        var func_pos : Dictionary = {}
        var func_idx : PackedInt64Array = []

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

            # TODO:
            #if bb.get_string("tag") == "[img":
                #bb_data[bb_start]["img"] = true
                #bb_data[bb_start]["img-pos"] = bb_end
                #bb_data[bb_start]["img-res"] = string.substr(
                    #bb_start, string.find("[/img]", bb_start) - bb_start
                #)
#
                #string = string\
                    #.erase(bb_start, bb_data[bb_start]["img-res"].length())\
                    #.insert(bb_start, "i")

                #bbcode_pos_offset += bb_data[bb_start]["img-res"].length()

        # Dialogue tags ========================================================
        var regex_tags_match := regex_tags.search_all(string)
        var tag_pos_offset : int = 0

        var regex_int_func := RegEx.new()
        regex_int_func.compile(r"\d+")

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

            if !(tag_key_l in VARS_BUILT_IN_KEYS):
                string = string.replace(string_match, "")

            var regex_int_func_match := regex_int_func.search(tag_key_l)
            if regex_int_func_match != null:
                var idx = regex_int_func_match.strings[0].to_int()
                func_pos[tag_pos] = idx

                if !func_idx.has(idx):
                    func_idx.append(idx)

            if !BUILT_IN_TAGS.has(tag_key) and\
                !(tag_key_l in vars) and\
                (regex_int_func_match == null):
                vars.append(tag_key_l)

            tag_pos_offset += string_match.length()

        # Insert back BBCodes ==================================================
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
        output["func_pos"] = func_pos
        output["func_idx"] = func_idx
        output["variables"] = vars

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
        dlg._sets[pos]["vars"] = parsed_tags["variables"]
        dlg._sets[pos]["func_pos"] = parsed_tags["func_pos"]
        dlg._sets[pos]["func_idx"] = parsed_tags["func_idx"]
#endregion

#region NOTE: Stored variables ---------------------------------------------------------------------
#static var default_lang := "en"

@export_storage var _sets : Array[Dictionary] = []
@export_storage var _source_path : String

@export_storage var _used_variables : PackedStringArray = []
@export_storage var _used_function_calls : Dictionary = {}
#endregion

#region NOTE: Loader/constructor -------------------------------------------------------------------
## Returns [code]true[/code] if [param filename] use a valid written [Dialogue] file name ([code]*.dlg.txt[/code] or [code]*.dlg[/code]).
static func is_valid_filename(filename : String) -> bool:
    return (
        (filename.ends_with(".dlg.txt") or filename.ends_with(".dlg"))
        and filename.get_file().is_valid_filename()
    )

func _init(dlg_src : String = ""):
    _sets = []
    _used_variables = []
    var parser : _Parser

    if is_valid_filename(dlg_src):
        print("Parsing Dialogue from file: %s..." % dlg_src)

        if !FileAccess.file_exists(dlg_src):
            push_error("Unable to create Dialogue resource: '%s' does not exists" % dlg_src)

        else:
            _source_path = dlg_src
            parser = _Parser.new(FileAccess.get_file_as_string(dlg_src))
            _sets = parser.output
            _update_used_variables()
            _update_used_function_calls()

    elif _Parser.is_valid_source(dlg_src) and dlg_src.split("\n", false).size() >= 2:
        var stack : Dictionary = get_stack()[-1]
        print("Parsing Dialogue from raw string: %s:%d" % [
            stack["source"], stack["line"]
        ])
        parser = _Parser.new(dlg_src)
        _sets = parser.output
        _update_used_variables()
        _update_used_function_calls()

        _source_path = "%s:%d" % [stack["source"], stack["line"]]

## Load written [Dialogue] file from [param path]. Use [method Dialogue.new] instead to create a written [Dialogue] directly in the script.
static func load(path : String) -> Dialogue:
    if !is_valid_filename(path):
        printerr("Error loading Dialogue: '%s' is not a valid path/filename\n" % path,
            Theatre.Debug.format_stack(get_stack())
        )
        return null
    else:
        # Find filename alias
        var dlg_compiled := path

        if path.ends_with(".txt"):
            dlg_compiled = path.trim_suffix(".txt")

        if FileAccess.file_exists(dlg_compiled + ".res"):
            dlg_compiled += ".res"
        elif FileAccess.file_exists(dlg_compiled + ".tres"):
            dlg_compiled += ".tres"

        print("Getting Dialogue from file: %s..." % dlg_compiled)

        if FileAccess.file_exists(dlg_compiled):
            var dlg := load(dlg_compiled)
            return dlg as Dialogue
        else:
            push_warning("Compiled Dialogue '%s' doesn't exists. Creating new dialogue\n" % path)
            return Dialogue.new(path)
#endregion

#region NOTE: Utilities ----------------------------------------------------------------------------
## Return all actors present in the compiled [Dialogue]. Optionally pass [param variables] to
## insert variables used in the actor's name, otherwise it will return it as is (e.g. [code]{player_name}[/code])
func get_actors(variables : Dictionary = {}) -> PackedStringArray:
    var output : PackedStringArray = []
    for n in _sets:
        var actor : String = n.actor.format(variables)
        if !output.has(actor):
            output.append(actor)
    return output

## Return line count in the compiled [Dialogue].
func get_length() -> int:
    return _sets.size()

## Returns the path of written [Dialogue] source. If the [Dialogue] is created in a script using
## [method Dialogue.new], it will returns the script's path and the line number from where the [Dialogue] is created
## (e.g. [code]res://your_script.gd:26[/code]).
func get_source_path() -> String:
    return _source_path

## Returns word count in the compiled [Dialogue]. Optionally pass [param variables] to insert
## variables used by the [Dialogue], otherwise it will count any variable placeholder as 1 word.
func get_word_count(variables : Dictionary = {}) -> int:
    var output : int = 0
    var text : String
    for n in _sets:
        for chr in ":;.,{}-":
            text = n["line_raw"]\
                .format(variables)\
                .format(Stage._VARIABLES_BUILT_IN)\
                .replace(chr, " ")
        output += text.split(" ", false).size()
    return output

func get_character_count(variables : Dictionary = {}) -> int:
    #var output : int = 0
    #var text : String
    #for n in _sets:
        #for chr in ":;.,{}-":
            #text = n["line_raw"]\
                #.format(variables)\
                #.format(Stage._VARIABLES_BUILT_IN)\
                #.replace(chr, " ")
        #output += text.length()
    return humanize(variables).length()
    

func get_function_calls() -> Dictionary:
    return _used_function_calls

func _update_used_function_calls() -> void:
    for n : Dictionary in _sets:
        for m : Dictionary in n["func"]:
            if !_used_function_calls.has(m["caller"]):
                _used_function_calls[m["caller"]] = {}

            _used_function_calls[m["caller"]][m["ln_num"]] = {
                "name": m["name"],
                "args": m["args"],
            }

## Gets all variables used in the written [Dialogue].
func get_variables() -> PackedStringArray:
    return _used_variables

func _update_used_variables() -> void:
    for n : Dictionary in _sets:
        for m : String in n["vars"]:
            if not m in _used_variables:
                _used_variables.append(m)

## Returns the human-readable string of the compiled [Dialogue]. This will return the [Dialogue]
## without the Dialogue tags and/or BBCode tags. Optionally, insert the variables used by passing it to [param variables].
func humanize(variables : Dictionary = {}) -> String:
    return _strip(variables)

func _strip(
    variables : Dictionary = {},
    exclude_actors : bool = false,
    exclude_newline : bool = false
    ) -> String:
    var output := ""
    var newline : String = "" if exclude_newline else "\n"

    for n in _sets:
        if !exclude_actors:
            output += n.actor + ":" + newline

        output += "    " + n.line + newline + newline

    # Strip BBCode tags
    var regex_bbcode := RegEx.new()
    regex_bbcode.compile(_Parser.REGEX_BBCODE_TAGS)
    var regex_bbcode_match := regex_bbcode.search_all(output)
    for bb in regex_bbcode_match:
        output = output.replace(bb.strings[0], "")

    return output.format(variables)

## Save the compiled [Dialogue] data as a JSON file to the specified [param path]. Returns [member OK] if successful.
func to_json(path : String) -> Error:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if FileAccess.get_open_error() == OK:
        file.store_string(
            JSON.stringify(_sets, "  ", true, true)
        )
    else:
        return FileAccess.get_open_error()
    file.close()
    return file.get_error()
#endregion
