class_name Dialogue
extends Resource

# TODO: handle errors and non-Dialogue text files
# TODO: localization support

## A Dialogue resource, saved as sets of instruction on how the Dialogue flow.

#static var default_lang := "en"

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

    # Loading Dialogue with load() also trigger this
    #else:
        #push_error("Unable to create Dialogue resource: unkbown source:", dlg_src)

static func load(dlg_src : String) -> Dialogue:
    if (dlg_src.begins_with("res://") or
        dlg_src.begins_with("user://")) and\
        dlg_src.get_file().is_valid_filename():

        print("Getting Dialogue from file: ", dlg_src)
        if FileAccess.file_exists(dlg_src):
            var dlg := load(
                dlg_src.trim_suffix(".txt") + ".dlg.res"
            )
            return dlg as Dialogue
        else:
            push_warning("Compiled Dialogue %s does'nt exists. Creating new dialogue" % dlg_src)
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
                    20 : .5,
                    35 : 2,
                },
                "func": [],
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

            else:
                output[body_pos]["body_raw"] += dlg_raw[i].dedent() + " "

    #for n in output:
        #print("\n\n--------------------------------")
        #for t in n:
            #print(n[t])

    sets = output

# TODO: set function calls
    #Safe arguments: int, float, bool

    # => HANDLER : add(12)
    # => PLAYER : rotate(20.5)
    # => PLAYER : heal(25)
    # => bool : toggle(true)
    # => PORTRAIT : change("res://smiling.png")

#static func print_set(input : Dictionary) -> void:
        #print(
            #"\n  name: ", input["name"],
            #"\n  body: ", input["body_raw"],
       #)
        #for f in input["func"].keys() as Array:
            #print("    ", input["func"][f][0])
            #for a in input["func"][f]:
                #print("      ",a)

# TODO: this
func to_json(path : String) -> int:
    JSON
    return 0

# TODO: Consider comma and semicolon
func get_word_count() -> int:
    var output : int = 0
    for n in sets:
        output += n["body_raw"].split(" ", false).size()
    return output

