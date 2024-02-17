class_name Dialogue
extends Resource

# TODO: handle errors and non-Dialogue text files
# TODO: localization support
# TODO: regex stuff

## A Dialogue resource, saved as sets of instruction on how the Dialogue flow.

#static var default_lang := "en"

const REGEX_DLG_TAGS := r"\{\s*(\w+)\s*=\s*(.+?)\s*\}"
const REGEX_FUNC_CALL := r"(?<=\n*)(\w+)\(([^)]*)\)$"
const REGEX_PLACEHOLDER = r"\{(\w+?)\}"

@export var sets : Array[Dictionary] = []

func _init(dlg_src : String = ""):
    sets = []

    if (dlg_src.begins_with("res://") or
        dlg_src.begins_with("user://")) and\
        dlg_src.get_file().is_valid_filename():
        print("Parsing Dialogue from file: ", dlg_src)
        if FileAccess.file_exists(dlg_src):
            parse(FileAccess.get_file_as_string(dlg_src))
        else:
            push_error("Unable to create Dialogue resource: %s does not exists" % dlg_src)

    elif dlg_src.get_slice_count("\n") >= 1:
        print("Parsing Dialogue from raw string: ", get_stack())
        parse(dlg_src)

    # BUG? Loading Dialogue with @GDScript load() also trigger this
    #else:
        #push_error("Unable to create Dialogue resource: unkbown source:", dlg_src)

static func load(dlg_src : String) -> Dialogue:
    if (dlg_src.begins_with("res://") or
        dlg_src.begins_with("user://")) and\
        dlg_src.get_file().is_valid_filename():

        var dlg_compiled := dlg_src.trim_suffix(".txt") + ".dlg.res"

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

## Parse the raw string used for the dialogue.
func parse(src : String) -> void:
    sets = []
    const FUNC_IDENTIFIER := "=>"

    var output : Array[Dictionary] = []
    var dlg_raw : PackedStringArray = []

    var is_indented := Callable( func(string : String) -> bool:
        return string.begins_with(" ") or string.begins_with("\t")
    )

    # Filter out comments, and create PackedStringArray
    # of every non-empty line in the source
    for n in src.split("\n", false):
        if !n.begins_with("#") and !n.is_empty():
            dlg_raw.append(n)

    var body_pos : int = 0
    for i in dlg_raw.size():
        var n := dlg_raw[i]

        if n.begins_with(FUNC_IDENTIFIER) or !is_indented.call(n):
            var setsl := {
                "name": "",
                "body_raw": "",
                "delays": {
                    #   pos,    delay(s)
                    #   15,     5
                },
                "speeds": {
                    #   pos,    scale(f)
                    #   15:     1.2
                },
                "func": [],
                "offsets": {
                    #   start, end
                    #   15: 20
                },
            }

            if !is_indented.call(n):
                if dlg_raw.size() < i + 1:
                    assert(false, "Error: Dialogue name exists without a body")

                setsl["name"] = n.trim_suffix(":")

                if setsl["name"] == "_":
                    setsl["name"] = ""

                output.append(setsl)
                body_pos = output.size() - 1

        elif is_indented.call(n):
            # Function calls
            if n.dedent().begins_with(FUNC_IDENTIFIER):
                var fun_str := n.split("(", false, 2)

                var identifier := fun_str[0]\
                    .strip_edges()\
                    .trim_suffix(":")\
                    .trim_prefix(FUNC_IDENTIFIER)\
                    .split(" ", false, 3)

                var param_str := fun_str[-1]\
                    .strip_edges().\
                    trim_suffix(")")\
                    .split(",", false, 2)

                var param = []

                for p in param_str:
                    if identifier.size() >= 3:
                        match identifier[1].to_upper():
                            "COLOR":
                                param.append(Color(p))
                            "STRING":
                                param.append(p)
                            _:
                                param.append(str_to_var(p))

                var fun := {
                    "handler": identifier[0],
                    "func_name": StringName(identifier[-1]),
                    "param": param,
                }

                output[body_pos]["func"].append(fun)

            # Dialogue text body
            else:
                var dlg_body := dlg_raw[i].dedent() + " "

                # Dialogue tags
                var regex_tags := RegEx.new()
                regex_tags.compile(REGEX_DLG_TAGS)
                var regex_tags_match := regex_tags.search_all(dlg_body)

                var tag_pos_offset : int = 0

                for b in regex_tags_match:
                    var tag_pos : int = b.get_start()\
                        - tag_pos_offset\
                        + output[body_pos]["body_raw"].length()
                    var tag_key := b.strings[1]
                    var tag_value := b.strings[2]

                    tag_pos_offset = b.strings[0].length()

                    dlg_body = dlg_body.replace(b.strings[0], "")
                    match tag_key.to_upper():
                        "DELAY":
                            output[body_pos]["delays"][tag_pos] = float(tag_value)
                        "WAIT":
                            output[body_pos]["delays"][tag_pos] = float(tag_value)
                        _:
                            push_warning("Unknown tags: ", b.strings[0])

                output[body_pos]["body_raw"] += dlg_body

                # Placeholder position for offset
                var regex_placeholders := RegEx.new()
                regex_placeholders.compile(REGEX_PLACEHOLDER)
                var regex_placeholder_match := regex_placeholders.search_all(output[body_pos]["body_raw"])

                for b in regex_placeholder_match:
                    if !output[body_pos]["offsets"].keys().has(b.get_start()):
                        output[body_pos]["offsets"][b.get_start()] = b.get_end()

    for n in output:
        print("\n\n--------------------------------")
        for t in n:
            print(n[t])

    sets = output

# TODO: set function calls
    #Safe arguments: int, float, bool

    # => HANDLER : add(12)
    # => PLAYER : rotate(20.5)
    # => PLAYER : heal(25)
    # => bool : toggle(true)
    # => PORTRAIT : change("res://smiling.png")

static func print_set(input : Dictionary) -> void:
    print(
        "\n", input["name"],
        "\n", input["body_raw"],
    )
    if !input["delays"].is_empty():
        "    delays at:"
        for d : int in input["delays"].keys():
            print("position %i, for %f seconds" % d, input["delays"][d])

    for f in input["func"].keys():
        pass

# TODO: this
func to_json(path : String) -> int:
    JSON
    return 0

func get_word_count() -> int:
    var output : int = 0
    var text : String
    for n in sets:
        for chr in ";,{}":
            text = n["body_raw"].replace(chr, " ")
        output += text.split(" ", false).size()
    return output

