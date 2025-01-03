@icon("res://addons/Theatre/assets/icons/classes/feather-pointed.svg")
class_name Dialogue
extends Resource

## Compiled [Dialogue] resource.
##
## This is the resource that have been parsed and processed from the written [Dialogue].
## Load it from the text file with [method Dialogue.load], or write it directly in script using [method Dialogue.new]
## [codeblock]
## var dlg = Dialogue.load("res://your_dialogue.dlg")
## # or
## var dlg = Dialogue.new("""
##
## Godette:
##      "Hello world!"
##
## """)
## [/codeblock]
##
## @tutorial(Dialogue Syntax): https://nndda.github.io/Theatre/class/dialogue/syntax/
## @tutorial(Theatre's tutorial page): https://nndda.github.io/Theatre/tutorials/

#region NOTE: Stored variables ---------------------------------------------------------------------
@export_storage var _sets : Array[Dictionary] = []
@export_storage var _source_path : String

@export_storage var _used_variables : PackedStringArray = []
@export_storage var _used_function_calls : Dictionary = {}

@export_storage var _sections : Dictionary = {}
#endregion

#region NOTE: Loader/constructor -------------------------------------------------------------------
func _init(dlg_src : String = ""):
    if !dlg_src.is_empty():
        _from_string(dlg_src)

func _from_string(dlg_src : String = "") -> void:
    var parser : DialogueParser

    if dlg_src.is_empty():
        pass

    elif DialogueParser.is_valid_source(dlg_src) and\
        dlg_src.split(DialogueParser.NEWLINE, false, 3).size() >= 2:
        var stack : Array[Dictionary] = get_stack()
        if stack.size() >= 1:
            var stack_ln : Dictionary = stack[-1]
            print("Parsing Dialogue from raw string: %s:%d" % [
                stack_ln["source"], stack_ln["line"]
            ])
            _source_path = "%s:%d" % [stack_ln["source"], stack_ln["line"]]

        parser = DialogueParser.new(
            # BUG
            DialogueParser.normalize_indentation(dlg_src),
            _source_path
        )
        _sections = parser.sections
        _sets = parser.output
        _update_used_variables()
        _update_used_function_calls()

        _sections.make_read_only()
        _sets.make_read_only()
        _used_function_calls.make_read_only()

## Load written [Dialogue] file from [param path]. Use [method Dialogue.new] instead to create a written [Dialogue] directly in the script.
static func load(path : String) -> Dialogue:
    return load(path) as Dialogue
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
    return RegEx \
    .create_from_string(r"\w+") \
    .search_all(_strip(
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
        for m : Dictionary in n[DialogueParser.__FUNC]:
            if !_used_function_calls.has(m[DialogueParser.__SCOPE]):
                _used_function_calls[m[DialogueParser.__SCOPE]] = {}

            _used_function_calls[m[DialogueParser.__SCOPE]][m[DialogueParser.__LN_NUM]] = {
                DialogueParser.__NAME: m[DialogueParser.__NAME],
                DialogueParser.__ARGS: m[DialogueParser.__ARGS],
            }

## Gets all variables used in the written [Dialogue].
func get_variables() -> PackedStringArray:
    return _used_variables

func _update_used_variables() -> void:
    for n : Dictionary in _sets:
        for m : String in n[DialogueParser.__VARS]:
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
    var output := DialogueParser.EMPTY
    var newline : String = DialogueParser.EMPTY if exclude_newline else DialogueParser.NEWLINE

    for n in _sets:
        if !exclude_actors:
            output += n.actor + DialogueParser.COLON + newline

        output += (
            DialogueParser.EMPTY if exclude_actors else DialogueParser.INDENT_4
        ) + n.line + newline + newline

    # Strip BBCode tags
    output = DialogueParser._regex_bbcode_tags.sub(output, DialogueParser.EMPTY, true)

    return output.format(variables)

## Save the compiled [Dialogue] data as a JSON file to the specified [param path]. Returns [member OK] if successful.
func to_json(path : String) -> Error:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if FileAccess.get_open_error() == OK:
        file.store_string(
            JSON.stringify(_sets, DialogueParser.INDENT_2, true, true)
        )
    else:
        return FileAccess.get_open_error()
    file.close()
    return file.get_error()
#endregion
