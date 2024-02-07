class_name Dialogue extends Resource

## A Dialogue resource, saved as sets of instruction on how the Dialogue flow.

static var default_lang : String = "en"
@export var characters : Dictionary = {}

@export var raw : String = ""
@export var sets : Array[Dictionary] = []

@export var tr_sets : Array[Dictionary] = []
#   { "EN" : sets,
#     "ID" : sets }

const DATA_TEMPLATE : Dictionary = {
    "name"   : "",
    "body"    : "",
    "func"   : [], # Array[Dictionary]
}

const FUNC_IDENTIFIER := "=>"
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
        parse(FileAccess.get_file_as_string(dlg_src))
    elif dlg_src.get_slice_count("\n") >= 1:
        print("Parsing Dialogue from raw string: ", get_stack())
        parse(dlg_src)
    else:
        push_error("Unable to create Dialogue resource: unkbown source")

    raw = ""

func parse(dialogue_raw : String) -> void:
    #print("parse.dialogue_raw:\n", dialogue_raw)

    sets = []

    var output : Array[Dictionary] = []
    var dialogue_raw_arr : PackedStringArray = []

    # Filter out comments
    for n in dialogue_raw.split("\n", false):
        if !n.begins_with("#") and !n.is_empty():
            dialogue_raw_arr.append(n)

    #print("parse.dialogue_raw_arr:\n", dialogue_raw_arr)
    output = parse_set(dialogue_raw_arr)
    sets = output

#       function(arg1,arg2)
#       function
#           arg1 arg2
#       callv(name,arg_arr)


func parse_set(input : PackedStringArray) -> Array[Dictionary]:
    var output : Array[Dictionary] = []
    #print("parse_set.input:\n", input)

    for i in input.size():
        # Current line
        var n := input[i]

        if n.begins_with(FUNC_IDENTIFIER) or !n.begins_with("    "):
            var setsl := DATA_TEMPLATE.duplicate()

            if n.begins_with(FUNC_IDENTIFIER):
#                print("  ", output.size(), "  standalone functions...")
                var prev := clampi(i - 1, 0, output.size() - 1)
                if !(
                    i != 0 and
                    output[prev]["body"].is_empty() and
                    output[prev]["name"].is_empty()
                   ):
                    setsl["func"] = parse_set_func(i, input)
                    output.append(setsl)

            elif !n.begins_with("    "):
#                print("  ", output.size(), "  line...")

                setsl["body"] = input[ i + 1 ].dedent()
                setsl["name"] = n.split(" ", false)[0]

                setsl["func"] = parse_set_func(i + 2, input)

                if setsl["name"] == "_":
                    setsl["name"] = ""

                output.append(setsl)

#            setsl.clear()

    for n in output:
        print("\n\n--------------------------------")
        for t in n:
            print(n[t])

    return output

func parse_set_func(start : int, target_sets : PackedStringArray) -> Dictionary:
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
                            fun_arg.append(varified(arg))

                    fun_out.append([fun_name, fun_arg])
                    funs[type] = fun_out

    return funs

static func print_set(input : Dictionary) -> void:
        print(
            "\n  name: ", input["name"],
            "\n  body: ", input["body"],
       )
        for f in input["func"].keys() as Array:
            print("    ", input["func"][f][0])
            for a in input["func"][f]:
                print("      ",a)

const COMMENTS  := "(#.*?(?=\\n|$))"
const BODY      := "(\\n    .*(?=\\n|$))"

static func get_components(
    expressions : String,
    target      : String) -> String:

    var output  : String    = ""
    var regex   : RegEx     = RegEx.new()

    regex.compile(expressions)
    for result in regex.search_all(target):
        print(result.get_string())
        output += result.get_string()

    regex.free()
    return output

func varified(input : String):
    if    input.is_valid_int(): return input.to_int()
    elif  input.is_valid_float(): return input.to_float()
    elif  input.is_valid_html_color(): return Color(input)
    else: return input

static func filename_switch_lang(
    file : String,
    lang : String = Dialogue.default_lang
   ) -> String:
    return file.left(-10) + lang + ".dlg." + file.get_extension()

static func verify_filename(
    file : String
   ) -> bool:
    return file.ends_with(".dlg.txt")

static func crawl(path := "res://", after := false):
    var dir := DirAccess.open(path)
    var ignored_directories := Theatre.Config.get_ignored_directories()

    if dir:
        dir.list_dir_begin()
        var file_name := dir.get_next()
        while file_name != "":
            if dir.current_is_dir():
                if !ignored_directories.has(dir.get_current_dir(false).trim_prefix("res://")):
                    print("Crawling " + path + " for dialogue resources...")
                    crawl(path + ("/" if after else "") + file_name, true)
            else:
                if verify_filename(file_name):
                    var file : String = (
                        path +
                        #path + ("/" if after else "") +
                        Dialogue.filename_switch_lang(file_name)
                    )
                    var dlg := Dialogue.new(file)

                    if ProjectSettings.get_setting(Theatre.Config.dialogue_save_to_memory, true):
                        Dialogue.compiled[file] = dlg

                    if ProjectSettings.get_setting(Theatre.Config.dialogue_save_to_userpath, true):
                        var err := ResourceSaver.save(dlg, file
                            .trim_suffix(".txt")
                            .replace("res://", "user://")
                            + ".res")
                        if err != OK:
                            push_error("Failed to save Dialogue resource: ", error_string(err))

                    #print("  total lines: ", dlg.sets.size())

            file_name = dir.get_next()

func to_json() -> void:
    pass



