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

#region NOTE: Stored variables ---------------------------------------------------------------------
@export_storage var _sets : Array[Dictionary] = []
@export_storage var _source_path : String

@export_storage var _used_variables : PackedStringArray = []
@export_storage var _used_function_calls : Dictionary = {}

@export_storage var _sections : Dictionary = {}
#endregion

#region NOTE: Loader/constructor -------------------------------------------------------------------
## Returns [code]true[/code] if [param filename] use a valid written [Dialogue] file name ([code]*.dlg.txt[/code] or [code]*.dlg[/code]).
static func is_valid_filename(filename : String) -> bool:
    return (
        (filename.ends_with(".dlg.txt") or filename.ends_with(".dlg"))
        and filename.get_file().is_valid_filename()
    )

func _init(dlg_src : String = ""):
    var parser : DialogueParser

    if is_valid_filename(dlg_src):
        print("Parsing Dialogue from file: %s..." % dlg_src)

        if !FileAccess.file_exists(dlg_src):
            push_error("Unable to create Dialogue resource: '%s' does not exists" % dlg_src)

        else:
            _source_path = dlg_src
            parser = DialogueParser.new(FileAccess.get_file_as_string(dlg_src))
            _sections = parser.sections
            _sets = parser.output
            _update_used_variables()
            _update_used_function_calls()

    elif DialogueParser.is_valid_source(dlg_src) and dlg_src.split("\n", false).size() >= 2:
        var stack : Dictionary = get_stack()[-1]
        print("Parsing Dialogue from raw string: %s:%d" % [
            stack["source"], stack["line"]
        ])
        parser = DialogueParser.new(
            # BUG
            DialogueParser.normalize_indentation(dlg_src)
        )
        _sections = parser.sections
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

        #print("Getting Dialogue from file: %s..." % dlg_compiled)

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
    var regex := RegEx.new()
    regex.compile(r"\w+")

    # is it really any better?
    return regex.search_all(_strip(
        variables.merged(Stage._VARIABLES_BUILT_IN),
        true, true
    )).size()

func get_character_count(variables : Dictionary = {}) -> int:
    return humanize(false, variables).length()

func get_function_calls() -> Dictionary:
    return _used_function_calls

## Returns the defined sections in the written [Dialogue], as a key-value pair,
## with the key being the section ID, the value being the [Dialogue] line it represent.
func get_sections() -> Dictionary:
    return _sections

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
func humanize(with_actor : bool = true, variables : Dictionary = {}) -> String:
    return _strip(variables, !with_actor)

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

        output += (
            "" if exclude_actors else "    "
        ) + n.line + newline + newline

    # Strip BBCode tags
    for bb in DialogueParser._regex_bbcode_tags.search_all(output):
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
