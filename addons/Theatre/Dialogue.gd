class_name Dialogue extends Resource

## A Dialogue resource, saved as sets of instruction on how the Dialogue flow.

static var default_lang : String = "en"
@export var characters : Dictionary = {}

@export var sets : Array[Dictionary] = []

var indent = "    "

## Parsed and compiled Dialogue files.
##
## Once a raw Dialogue file is parsed with [method crawl] It can be accessed through the [Dialogue] singleton with the file path used when parsing said raw Dialogue text file.
## [br]
## [code] Dialogue.compiled["res://chapter_one.en.dlg.txt"] [/code]
static var compiled : Dictionary = {}

func _init(dlg_src : String):
    characters = {}
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

    else:
        push_error("Unable to create Dialogue resource: unkbown source:", dlg_src)

static func load(dlg_src : String) -> Dialogue:
    if (dlg_src.begins_with("res://") or
        dlg_src.begins_with("user://")) and\
        dlg_src.get_file().is_valid_filename():

        print("Getting Dialogue from file: ", dlg_src)
        if Dialogue.compiled.has(dlg_src):
            return Dialogue.compiled[dlg_src]
        else:
            push_warning("Compiled Dialogue %s does'nt exists. Creating new dialogue" % dlg_src)
            return Dialogue.new(dlg_src)

    else:
        print("Parsing Dialogue from raw string: ", get_stack())
        return Dialogue.new(dlg_src)

# TODO: handle errors and non-Dialogue text files

## Parse the raw string used for the dialogue.
func parse(dlg_src : String) -> void:
    sets = []
    const FUNC_IDENTIFIER := "=>"

    var output : Array[Dictionary] = []
    var dlg_raw : PackedStringArray = []

    var is_indented := Callable( func(string : String) -> bool:
        return string.begins_with(" ") or string.begins_with("\t")
    )

    # Filter out comments, and create PackedStringArray
    # of every non-empty line in the source
    for n in dlg_src.split("\n", false):
        if !n.begins_with("#") and !n.is_empty():
            dlg_raw.append(n)

#       function(arg1,arg2)
#       function
#           arg1 arg2
#       callv(name,arg_arr)

    var parse_func := Callable( func(src : String) -> Dictionary:
        return {}
    )

    var body_pos : int = 0
    for i in dlg_raw.size():
        var n := dlg_raw[i]

        if n.begins_with(FUNC_IDENTIFIER) or !is_indented.call(n):
            var setsl := {
                "name": "",
                "body": "",
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

                var param_str := fun_str[-1].strip_edges().trim_suffix(")").split(",", false, 2)
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
                output[body_pos]["body"] += dlg_raw[i].dedent() + " "

    #for n in output:
        #print("\n\n--------------------------------")
        #for t in n:
            #print(n[t])

    sets = output

# TODO: set function calls
#func parse_set_func(start : int, target_sets : PackedStringArray) -> Dictionary:
    #HANDLER : [
        #[ FUNC1, [ARG1, ARG2] ]
    #]

    #Safe arguments: int, float, bool

    # => HANDLER : add(12)
    # => PLAYER : rotate(20.5)
    # => PLAYER : kill()
    # => bool: toggle(true)

    # => PORTRAIT string: change("res://smiling.png")
    # => BACKGROUND color: change("#abcdef")

    # => PORTRAIT string: change
    # "res://smiling.png")

    # split "(" false, 2

    # IDENTIFIER:
    # dedent().trim_prefix(FUNC_IDENTIFIER).trim_suffix(":")
    # split " "

    # PARAMETER
    # dedent()

static func print_set(input : Dictionary) -> void:
        print(
            "\n  name: ", input["name"],
            "\n  body: ", input["body"],
       )
        #for f in input["func"].keys() as Array:
            #print("    ", input["func"][f][0])
            #for a in input["func"][f]:
                #print("      ",a)

# TODO: alternative translation
#static func filename_switch_lang(
    #file : String,
    #lang : String = Dialogue.default_lang
   #) -> String:
    #return file.left(-10) + lang + ".dlg." + file.get_extension()

static func crawl(path := "res://"):
    var dir := DirAccess.open(path)
    var ignored_directories := Theatre.Config.get_ignored_directories()

    if dir:
        dir.list_dir_begin()
        var file_name := dir.get_next()
        while file_name != "":
            if dir.current_is_dir():
                if !file_name.begins_with("."):
                    if !ignored_directories.has(file_name):
                        var new_dir := path + ("" if path == "res://" else "/") + file_name
                        print("Crawling " + new_dir + " for dialogue resources...")
                        crawl(new_dir)
            else:
                if file_name.ends_with(".txt"):
                    var file : String = path + "/" + file_name
                    var dlg := Dialogue.new(file)

                    if ProjectSettings.get_setting(Theatre.Config.dialogue_save_to_memory, true):
                        Dialogue.compiled[file] = dlg

                    #if ProjectSettings.get_setting(Theatre.Config.dialogue_save_to_userpath, true):
                        #var err := ResourceSaver.save(dlg, file
                            #.trim_suffix(".txt")
                            #.replace("res://", "user://")
                            #+ ".res")
                        #if err != OK:
                            #push_error("Failed to save Dialogue resource: ", error_string(err))

            file_name = dir.get_next()

# TODO: these...
func to_json(path : String) -> int:
    return 0

func get_word_count() -> int:
    var output : int = 0
    for n in sets:
        output += n["body"].split(" ", false).size()
    return output

