class_name Dialogue extends Resource

## A Dialogue resource, saved as sets of instruction on how the Dialogue flow.

static var default_lang : String = "en"
@export var characters : Dictionary = {}

@export var sets : Array[Dictionary] = []

const DATA_TEMPLATE : Dictionary = {
    "name"   : "",
    "body"    : "",
    "func"   : [], # Array[Dictionary]
}

const FUNC_IDENTIFIER := "FUNC"
const DLGSET_IDENTIFIER := "-"

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
func parse(dlg_src : String) -> void:
    #print("parse.dialogue_raw:\n", dialogue_raw)

    sets = []

    var output : Array[Dictionary] = []
    var dlg_raw : PackedStringArray = []

    var is_indented = Callable( func(string : String) -> bool:
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

    for i in dlg_raw.size():
        # Current line
        var n := dlg_raw[i]

        if n.begins_with(FUNC_IDENTIFIER) or !is_indented.call(n):
            var setsl := DATA_TEMPLATE.duplicate()

            if n.begins_with(FUNC_IDENTIFIER):
#                print("  ", output.size(), "  standalone functions...")
                var prev := clampi(i - 1, 0, output.size() - 1)
                if !(
                    i != 0 and
                    output[prev]["body"].is_empty() and
                    output[prev]["name"].is_empty()
                   ):
                    setsl["func"] = parse_set_func(i, dlg_raw)
                    output.append(setsl)

            elif !is_indented.call(n):
#                print("  ", output.size(), "  line...")

                if dlg_raw.size() < i + 1:
                    assert(false, "Error: Dialogue name exists without a body")
                else:
                    setsl["body"] = dlg_raw[i + 1].dedent()

                setsl["name"] = n.trim_suffix(":")

                #setsl["func"] = parse_set_func(i + 2, dlg_raw)

                if setsl["name"] == "_":
                    setsl["name"] = ""

                output.append(setsl)

    is_indented = null
#            setsl.clear()

    #for n in output:
        #print("\n\n--------------------------------")
        #for t in n:
            #print(n[t])

    sets = output

# TODO: set function calls
func parse_set_func(start : int, target_sets : PackedStringArray) -> Dictionary:
    # => int: add(12)
    # => float: rotate(20.5)
    # => bool: toggle(true)
    # => string: portrait("res://smiling.png")
    # => color: portrait("#abcdef")

    var i := start
    var input := target_sets

    var funs := {}
    var break_flag := false

    for f in range(i, input.size()):
        if !break_flag:

            if !input[f].dedent().begins_with(FUNC_IDENTIFIER):
                break_flag = true

            else:
                var fun_out : Array = []
                var input_f := input[f].dedent()
                var type := input_f.left(input_f.find(" ")).trim_prefix("-")

                for fun in (input_f.right((type.length() + 1) * -1)).split(")", false):
                    var fun_arg : Array = []
                    var fun_raw := (fun.replace(" ", "")).split("(", true)
                    var fun_name := fun_raw[0].replace(" ", "")

                    if fun_raw.size() > 1:
                        for arg in fun_raw[1].split(",", false):
                            #fun_arg.append(varified(arg))
                            pass

                    fun_out.append([fun_name, fun_arg])
                    funs[type] = fun_out

    return funs

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

# TODO: file verification/validation
#static func verify_filename(
    #file : String
   #) -> bool:
    #return file.ends_with(".dlg.txt")

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

