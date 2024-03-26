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
        r"\{\s*(\w+)\s*=\s*(.+?)\s*\}"
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
    }
    const FUNC_TEMPLATE := {
        "caller": "",
        "name": "",
        "args": [],
    }

    func _init(src : String = ""):
        output = []
        const FUNC_IDENTIFIER := "_FUNC:"

        var dlg_raw : PackedStringArray = []

        # Filter out comments, and create PackedStringArray
        # of every non-empty line in the source
        for n in src.split("\n", false):
            if !n.begins_with("#"):
                dlg_raw.append(n)

        var body_pos : int = 0
        for i in dlg_raw.size():
            var n := dlg_raw[i]

            if n.begins_with(FUNC_IDENTIFIER) or !is_indented(n):
                var setsl := SETS_TEMPLATE.duplicate(true)

                if !is_indented(n):
                    if dlg_raw.size() < i + 1:
                        assert(false, "Error: Dialogue name exists without a body")

                    setsl["actor"] = n.trim_suffix(":")

                    if setsl["actor"] == "_":
                        setsl["actor"] = ""

                    output.append(setsl)
                    body_pos = output.size() - 1

            elif is_indented(n):
                # Function calls
                var regex_func := RegEx.new()
                regex_func.compile(REGEX_FUNC_CALL)
                var regex_func_match := regex_func.search(dlg_raw[i].dedent())

                if regex_func_match != null:
                    var func_dict := FUNC_TEMPLATE.duplicate(true)
                    for func_n : String in [
                        "caller", "name",
                    ]:
                        func_dict[func_n] = regex_func_match.get_string(
                            regex_func_match.names[func_n]
                        )

                    # Function parameters/arguments
                    var args_raw := regex_func_match.get_string(
                        regex_func_match.names["args"]
                    ).strip_edges()
                    var args = str_to_var("[%s]" % args_raw)

                    if args == null:
                        push_error("Error, null arguments: ", args_raw)

                    func_dict["args"] = args
                    output[body_pos]["func"].append(func_dict)

                # Dialogue text body
                else:
                    var dlg_body := dlg_raw[i].dedent() + " "

                    output[body_pos]["line_raw"] += dlg_body
                    output[body_pos]["line"] += dlg_body

        for n in output.size():
            # Implement built-in tags
            var parsed_tags := parse_tags(output[n]["line_raw"])

            for tag : String in SETS_TEMPLATE["tags"].keys():
                output[n]["tags"][tag].merge(parsed_tags["tags"][tag])

            output[n]["line"] = parsed_tags["string"]

    ## Check if [param string] is indented with tabs or spaces.
    func is_indented(string : String) -> bool:
        return string.begins_with(" ") or string.begins_with("\t")

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

    static func parse_tags(string : String) -> Dictionary:
        var output : Dictionary = {}
        var tags : Dictionary = SETS_TEMPLATE["tags"].duplicate(true)

        var regex_tags := RegEx.new()
        regex_tags.compile(REGEX_DLG_TAGS)
        var regex_tags_match := regex_tags.search_all(string)

        var tag_pos_offset : int = 0

        for b in regex_tags_match:
            string = string.replace(b.strings[0], "")

            var tag_pos : int = b.get_start() - tag_pos_offset
            var tag_key := b.strings[1].to_upper()
            var tag_value := b.strings[2]

            tag_pos_offset += b.strings[0].length()

            if ["DELAY", "WAIT", "D", "W"].has(tag_key):
                tags["delays"][tag_pos] = float(tag_value)
            elif ["SPEED", "SPD", "S"].has(tag_key):
                tags["speeds"][tag_pos] = float(tag_value)
            else:
                push_warning("Unknown tags: ", b.strings[0])

        output["tags"] = tags
        output["string"] = string

        return output

    # Temporary solution when using variables and tags at the same time
    # Might not be performant when dealing with real-time variables
    ## Format Dialogue body at [param pos] position with [member Stage.variables], and update the positions of the built-in tags.
    ## Return the formatted string.
    static func update_tags_position(dlg : Dialogue, pos : int, vars : Dictionary) -> void:
        var dlg_str : String = dlg.sets[pos]["line_raw"].format(vars)
        for n in ["delays", "speeds"]:
            dlg.sets[pos]["tags"][n].clear()

        dlg.sets[pos]["tags"] = parse_tags(dlg_str)["tags"]
        dlg.sets[pos]["line"] = parse_tags(dlg_str)["string"]

#static var default_lang := "en"

@export var sets : Array[Dictionary] = []

@export var source_path : String = ""

func _init(dlg_src : String = ""):
    sets = []
    var parser : Parser

    if is_valid_filename(dlg_src):
        print("Parsing Dialogue from file: ", dlg_src)
        if FileAccess.file_exists(dlg_src):
            source_path = dlg_src
            parser = Parser.new(FileAccess.get_file_as_string(dlg_src))
            sets = parser.output
        else:
            push_error("Unable to create Dialogue resource: %s does not exists" % dlg_src)

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
    )

static func load(dlg_src : String) -> Dialogue:
    if is_valid_filename(dlg_src):
        # Find filename alias
        var dlg_compiled := dlg_src.trim_suffix(".txt")

        if FileAccess.file_exists(dlg_compiled + ".dlg.res"):
            dlg_compiled += ".dlg.res"
        elif FileAccess.file_exists(dlg_compiled + ".dlg.tres"):
            dlg_compiled += ".dlg.tres"

        print("Getting Dialogue from file: ", dlg_compiled)

        if FileAccess.file_exists(dlg_compiled):
            var dlg := load(dlg_compiled)
            return dlg as Dialogue
        else:
            push_warning("Compiled Dialogue %s does'nt exists. Creating new dialogue" % dlg_compiled)
            return Dialogue.new(dlg_src)

    else:
        print("Parsing Dialogue from raw string: ", get_stack())
        return Dialogue.new(dlg_src)

#static func print_set(input : Dictionary) -> void:
    #print(
        #"\n", input["actor"],
        #"\n", input["line_raw"],
    #)
    #if !input["delays"].is_empty():
        #"    delays at:"
        #for d : int in input["delays"].keys():
            #print("position %i, for %f seconds" % d, input["delays"][d])
#
    #for f in input["func"].keys():
        #pass

func to_json(path : String) -> Error:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(
        JSON.stringify(sets, "  ")
    )
    file.close()
    return file.get_error()

func get_word_count() -> int:
    var output : int = 0
    var text : String
    for n in sets:
        for chr in ":;.,{}":
            text = n["line_raw"].replace(chr, " ")
        output += text.split(" ", false).size()
    return output

