class_name Dialogue extends Resource

## A Dialogue resource, saved as sets of instruction on how the dialogue flow.

@export var step : int = -1
static var step_global : int = 0

static var default_lang : String = "en"

@export var characters : Dictionary = {}
static var characters_global : Dictionary = {}

@export var raw : String = ""
@export var sets : Array[Dictionary] = []
@export var set_current : Dictionary = {}

## Maximum characters of strings to fit in the dialogue box. Parsing Dialogue with characters more than the specified max_chr will fail and throw out an error.
const max_chr : int = 305

@export var tr_sets : Array[Dictionary] = []
#   { "EN" : sets,
#     "ID" : sets }

const data_template : Dictionary = {
    "name"   : "",
    "dlg"    : "",
    "func"   : [] } #           <- Array[Dictionary]

const HANDLER : PackedStringArray = [
    "SPR","BG","TRANS","AUD","VFX","FREE","END", "PLOT"]

## Parsed and compiled Dialogue files.
##
## Once a raw Dialogue file is parsed either with [method crawl] or when it was initialized:
## [br]
## [code] var dlg = Dialogue.new("res://chapter_one.en.dlg.txt") [/code]
## [br]
## It can be accessed through the [Dialogue] singleton with the file path used when parsing said raw Dialogue text file.
## [br]
## [code] Dialogue.compiled["res://chapter_one.en.dlg.txt"] [/code]
static var compiled : Dictionary = {}

## Emitted when the Dialogue started ( [member step] == 0 )
signal started
signal finished
signal set_updated(
    step_n : int, set_n : Dictionary )

func _init( dlg_file : String ):

    step = -1
    characters = {}

    sets = []
    set_current = {}

    characters.merge( characters_global, true )
    parse( dlg_file )
    step_global += sets.size()

    raw = ""

func parse( dialogue_file : String ) -> void:

    sets = []

    var output : Array[Dictionary] = []
    var dlg_raw : PackedStringArray = []

    raw =  FileAccess.get_file_as_string( dialogue_file )

    print( "Parsing dialogue: ", dialogue_file )

    #   Filter out comments
    for n in raw.split( "\n", false ):
        if !n.begins_with("#") and !n.is_empty():
            dlg_raw.append(n)

    output = parse_set(dlg_raw)
    sets = output
    
    Dialogue.compiled[dialogue_file] = self


#       function(arg1,arg2)
#       function
#           arg1 arg2
#       callv(name,arg_arr)


func parse_set(
    input : PackedStringArray
    ) -> Array[Dictionary]:
    var output : Array[Dictionary] = []

    for i in input.size():
        var n : String = input[i]

        if n.begins_with("-") or !n.begins_with("    "):
            var setsl : Dictionary = data_template.duplicate()

            if n.begins_with("-"):
#                print( "  ", output.size(), "  standalone functions..." )
                if !(
                    i != 0 and
                    output[ clampi( i - 1, 0, output.size() - 1 ) ]["dlg"].is_empty() and
                    output[ clampi( i - 1, 0, output.size() - 1 ) ]["name"].is_empty()
                    ):
                    setsl["func"]    = parse_set_func( i, input )

                    output.append( setsl )

            elif !n.begins_with("    "):
#                print( "  ", output.size(), "  line..." )

                setsl["dlg"]     = input[ i + 1 ].dedent()
                setsl["name"]    = n.split( " ", false )[0]

                setsl["func"]    = parse_set_func( i + 2, input )

                if setsl["name"] == "_":
                    setsl["name"] = ""

                output.append( setsl )

#            setsl.clear()

#    for n in output:
#        print("\n\n--------------------------------")
#        for t in n:
#            print(n[t])

    return output



func parse_set_func( start : int, target_sets : PackedStringArray ) -> Dictionary:
    var i : int = start
    var input : PackedStringArray = target_sets

    var funs : Dictionary = {}
    var break_flag : bool = false

    for f in range( i, input.size() ):
        if !break_flag:

            if !input[f].dedent().begins_with("-"):
                break_flag = true

            else:
                var fun_out     : Array = []
                var input_f     : String = input[f].dedent()
                var type        : String = input_f.left( input_f.find(" ") ).trim_prefix("-")

                for fun in ( input_f.right( ( type.length() + 1 ) * -1 ) ).split( ")", false ):
                    var fun_arg     : Array = []
                    var fun_raw     : PackedStringArray = ( fun.replace( " ", "" ) ).split( "(", true )
                    var fun_name    : String = fun_raw[0].replace( " ", "" )

                    if fun_raw.size() > 1:
                        for arg in fun_raw[1].split( ",", false ):
                            fun_arg.append( varified(arg) )

                    fun_out.append( [ fun_name, fun_arg ] )
                    funs[type] = fun_out

    return funs

func progress( step_n  : int = 1 ) -> void:

    if step + step_n > sets.size() - 1 :
        emit_signal("finished")
    else:
        step += step_n
        set_current = sets[step]

        if step == 0: emit_signal( "started" )
        emit_signal( "set_updated", step, set_current )

static func print_set( input : Dictionary ) -> void:
        print(
            "\n  name: ", input["name"],
            "\n  dlg: ", input["dlg"],
        )
        for f in input["func"].keys() as Array:
            print( "    ", input["func"][f][0] )
            for a in input["func"][f]:
                print("      ",a)

const COMMENTS  : String = "(#.*?(?=\\n|$))"
const BODY      : String = "(\\n    .*(?=\\n|$))"

static func get_components(
    expressions : String,
    target      : String ) -> String:

    var output  : String    = ""
    var regex   : RegEx     = RegEx.new()

    regex.compile(expressions)
    for result in regex.search_all(target):
        print( result.get_string() )
        output += result.get_string()

    regex.free()
    return output


func varified( input : String ):
    if    input.is_valid_int(): return input.to_int()
    elif  input.is_valid_float(): return input.to_float()
    elif  input.is_valid_html_color(): return Color(input)
    else: return input


# Preparsing dialogue
static var files : PackedStringArray = []

static func filename_switch_lang(
    file : String,
    lang : String = Dialogue.default_lang
    ) -> String:
    return file.left(-10) + lang + ".dlg." + file.get_extension()


static func verify_filename(
    file : String
    ) -> bool:
    return file.ends_with(".dlg.txt")


static func crawl( path : String = "res://", after : bool = false ):
#    print("Crawling " + path + " for dialogue resources...")
    var dir : DirAccess = DirAccess.open(path)
    DirAccess.make_dir_absolute("user://compiled")
    if dir:
        dir.list_dir_begin()
        var file_name : String = dir.get_next()
        while file_name != "":
            if dir.current_is_dir(): crawl( path + file_name, true )
            else: if verify_filename( file_name ):
                    var file  : String = ( path + ( "/" if after else "" ) +
                        Dialogue.filename_switch_lang(file_name) )
                    var dlg   : Dialogue = Dialogue.new( file )
                    Dialogue.compiled[ file ] = dlg
                    print( "  total lines: ", dlg.sets.size() )

            file_name = dir.get_next()

static func fetch_humanified() -> void:

    for dlg in Dialogue.compiled.keys():
        var dir : String = "user" + (dlg as String).right(-3)
        if FileAccess.file_exists(dir): DirAccess.remove_absolute(dir)

        var file : FileAccess = FileAccess.open( dir, FileAccess.WRITE_READ )
        file.store_string( Dialogue.humanified( Dialogue.compiled[dlg] ) )
        file.close()
        file = null

static func humanified( input : Dialogue ) -> String:
    var header : String = "#  Max chr.:" + str(max_chr)
    var output : PackedStringArray = ["",header,"",""]

    for dlg in input.sets:
        if dlg["name"].is_empty():
            output.append_array(["-TRANSITION","","",""])
        else:
            output.append_array([
                dlg["name"],"",
                dlg["dlg"],"","",""])

    return "\n".join(output)

static func save_to_json( path : String ) -> void:
    pass



