class_name Dialogue
extends Resource

# TODO: handle errors and non-Dialogue text files
# TODO: localization support

## A Dialogue resource, saved as sets of instruction on how the Dialogue flow.

## Parser class for processing the raw string used for the dialogue.
class Parser extends RefCounted:
    var output : Array[Dictionary]

    const REGEX_DLG_TAGS :=\
        r"\{\s*(\w+)\s*=\s*(.+?)\s*\}"
    const REGEX_FUNC_CALL :=\
        r"(?<=\n+)\s+(?<handler>\w+)\s+(?:\=\>)\s+(?<func_name>\w+)\((?<func_args>[^)]*)\)$"
    const REGEX_PLACEHOLDER :=\
        r"\{(\w+?)\}"
    const REGEX_INDENT :=\
        r"(?<=\n{1})\s+"
    const REGEX_VALID_DLG :=\
        r"\n+\w+\:\n+\s+\w+"

    func _init(src : String = ""):
        output = []
        const FUNC_IDENTIFIER := "=>"

        var dlg_raw : PackedStringArray = []

        # Filter out comments, and create PackedStringArray
        # of every non-empty line in the source
        for n in src.split("\n", false):
            if !n.begins_with("#") and !n.is_empty():
                dlg_raw.append(n)

        var body_pos : int = 0
        for i in dlg_raw.size():
            var n := dlg_raw[i]

            if n.begins_with(FUNC_IDENTIFIER) or !is_indented(n):
                var setsl := {
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
                if false:
                    pass
                #if n.dedent().begins_with(FUNC_IDENTIFIER):
                    #var fun_str := n.split("(", false, 2)
#
                    #var identifier := fun_str[0]\
                        #.strip_edges()\
                        #.trim_suffix(":")\
                        #.trim_prefix(FUNC_IDENTIFIER)\
                        #.split(" ", false, 3)
#
                    #var param_str := fun_str[-1]\
                        #.strip_edges().\
                        #trim_suffix(")")\
                        #.split(",", false, 2)
#
                    #var param : Array = []
#
                    #for p in param_str:
                        #if identifier.size() >= 3:
                            #match identifier[1].to_upper():
                                #"COLOR":
                                    #param.append(Color(p))
                                #"STRING":
                                    #param.append(p)
                                #_:
                                    #param.append(str_to_var(p))
#
                    #var fun := {
                        #"handler": identifier[0],
                        #"func_name": StringName(identifier[-1]),
                        #"param": param,
                    #}
#
                    #output[body_pos]["func"].append(fun)

                # Dialogue text body
                else:
                    # TODO: perhaps can be merged with update_tags_position()?
                    var dlg_body := dlg_raw[i].dedent() + " "

                    # Dialogue built-in tags
                    var regex_tags := RegEx.new()
                    regex_tags.compile(REGEX_DLG_TAGS)
                    var regex_tags_match := regex_tags.search_all(dlg_body)

                    var tag_pos_offset : int = 0

                    for b in regex_tags_match:
                        var tag_pos : int = b.get_start()\
                            - tag_pos_offset\
                            + output[body_pos]["line_raw"].length()
                        var tag_key := b.strings[1]
                        var tag_value := b.strings[2]

                        tag_pos_offset = b.strings[0].length()

                        dlg_body = dlg_body.replace(b.strings[0], "")
                        match tag_key.to_upper():
                            "DELAY":
                                output[body_pos]["tags"]["delays"][tag_pos] = float(tag_value)
                            "WAIT":
                                output[body_pos]["tags"]["delays"][tag_pos] = float(tag_value)
                            _:
                                push_warning("Unknown tags: ", b.strings[0])

                    output[body_pos]["line"] += dlg_body
                    output[body_pos]["line_raw"] += dlg_raw[i].dedent() + " "

                    # Placeholder position for offset
                    #var regex_placeholders := RegEx.new()
                    #regex_placeholders.compile(REGEX_PLACEHOLDER)
                    #var regex_placeholder_match := regex_placeholders.search_all(output[body_pos]["line_raw"])
#
                    #for b in regex_placeholder_match:
                        #if !output[body_pos]["offsets"].keys().has(b.get_start()):
                            #output[body_pos]["offsets"][b.get_start()] = b.get_end()

        #for n in output:
            #print("\n\n--------------------------------")
            #for t in n:
                #print(n[t])

    ## Check if [param string] is indented with tabs or spaces.
    func is_indented(string : String) -> bool:
        return string.begins_with(" ") or string.begins_with("\t")

    ## Check if the [param string] is written in a valid Dialogue string format/syntax or not.
    static func is_valid_source(string : String) -> bool:
        var regex := RegEx.new()
        regex.compile(REGEX_VALID_DLG)
        return regex.search(string) == null

    ## Normalize indentation of the Dialogue string.
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

    # Temporary solution when using variables and tags at the same time
    # Might not be performant when dealing with real-time variables
    ## Format Dialogue body at [param pos] position with [member Stage.variables], and update the positions of the built-in tags.
    ## Return the formatted string.
    static func update_tags_position(dlg : Dialogue, pos : int, vars : Dictionary) -> String:
        var dlg_str : String = dlg.sets[pos]["line_raw"].format(vars)
        for n in ["delays", "speeds"]:
            dlg.sets[pos]["tags"][n].clear()

        var regex_tags := RegEx.new()
        regex_tags.compile(REGEX_DLG_TAGS)
        var regex_tags_match := regex_tags.search_all(dlg_str)

        var tag_pos_offset : int = 0

        for b in regex_tags_match:
            var tag_pos : int = b.get_start()\
                - tag_pos_offset
            var tag_key := b.strings[1]
            var tag_value := b.strings[2]

            tag_pos_offset = b.strings[0].length()

            dlg_str = dlg_str.replace(b.strings[0], "")
            match tag_key.to_upper():
                "DELAY":
                    dlg.sets[pos]["tags"]["delays"][tag_pos] = float(tag_value)
                "WAIT":
                    dlg.sets[pos]["tags"]["delays"][tag_pos] = float(tag_value)
                "SPEED":
                    dlg.sets[pos]["tags"]["speeds"][tag_pos] = float(tag_value)
                _:
                    push_warning("Unknown tags: ", b.strings[0])

        return dlg_str

#static var default_lang := "en"

@export var sets : Array[Dictionary] = []

func _init(dlg_src : String = ""):
    sets = []
    var parser : Parser

    if is_valid_filename(dlg_src):
        print("Parsing Dialogue from file: ", dlg_src)
        if FileAccess.file_exists(dlg_src):
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

# TODO: set function calls
    #Safe arguments: int, float, bool

    # => HANDLER : add(12)
    # => PLAYER : rotate(20.5)
    # => PLAYER : heal(25)
    # => bool : toggle(true)
    # => PORTRAIT : change("res://smiling.png")

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

# TODO: this
#func to_json(path : String) -> Error:
    #JSON
    #return 0

func get_word_count() -> int:
    var output : int = 0
    var text : String
    for n in sets:
        for chr in ";,{}":
            text = n["line_raw"].replace(chr, " ")
        output += text.split(" ", false).size()
    return output

