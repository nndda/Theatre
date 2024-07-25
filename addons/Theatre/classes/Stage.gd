@icon("res://addons/Theatre/assets/icons/classes/ticket.svg")
class_name Stage
extends Node

## Run, control, and configure [Dialogue], and reference UIs and Nodes that will be used to display the [Dialogue].
##
## [Stage] connects your [Dialogue] and the [DialogueLabel]. This is where you configure and control
## your [Dialogue], manage variables, and set up function calls from your written [Dialogue].

#region NOTE: Configurations & stored variables ----------------------------------------------------

## Optional [Label] node that displays actors of the current line of [member current_dialogue].
@export var actor_label : Label = null

## [DialogueLabel] node that displays the [Dialogue] line body. This is [b]required[/b] to be set before playing or running [Dialogue].
@export var dialogue_label : DialogueLabel = null

@export_group("Configurations")

## Allow skipping [Dialogue] or the [member dialogue_label] text rendering. See [method progress].
@export var allow_skip := true

## Allow cancelling/stopping [Dialogue] with [method cancel] or [method reset].
@export var allow_cancel := true

## Allow calling functions in the written [Dialogue].
@export var allow_func := true

#@export var auto := false

#@export var auto_delay : float = 1.5

#@export var insert_actor := false

static var speed_scale_global : float = 1.0

## The speed scale of the [member dialogue_label] text rendering.
@export_range(0.01, 3.0, 0.01) var speed_scale : float = 1.0:
    set(s):
        speed_scale = s
        if dialogue_label != null:
            dialogue_label._characters_draw_tick_scaled =\
                dialogue_label.characters_draw_tick / s
            dialogue_label._characters_ticker.wait_time =\
                dialogue_label._characters_draw_tick_scaled

@export_group("Dialogues")

## [Dialogue] resource to be used by [Stage]. Set it by assigning your [Dialogue],
## or by passing the [Dialogue] to [method start].
## [br][br]
## [b]Note:[/b] [member current_dialogue] will be set to [code]null[/code],
## when [method cancel] or [method reset] is called with [param keep_dialogue]
## set to [code]false[/code] (default), [i]and[/i] when [Stage] is finished.
@export_storage var current_dialogue : Dialogue:
    set(new_dlg):
        if !is_playing():
            current_dialogue = new_dlg
            if !variables.is_empty() and new_dlg != null:
                for n in current_dialogue._sets.size():
                    DialogueParser.update_tags_position(
                        current_dialogue, n, variables
                    )
        else:
            push_error("Cannot set Dialogue: there's a Dialogue running")

@export_storage var _caller : Dictionary = {}

#endregion

#region NOTE: Variable related ---------------------------------------------------------------------
## [Dictionary] of user-defined variables that will be used by [Stage].
##
## [b]Note:[/b] Avoid modifying [member variables] directly, use methods such as [method add_variable],
## [method merge_variables], [method remove_variable], and [method clear_variables] instead.
@export var variables : Dictionary = {}:
    set(new_var):
        variables = new_var

        if is_playing():
            _update_display()

        _update_variables_dialogue()
    get:
        return variables

func _update_variables_dialogue() -> void:
    _variables_all.clear()
    _variables_all.merge(variables, true)
    _variables_all.merge(_VARIABLES_BUILT_IN, true)
    if current_dialogue != null:
        var stepn := clampi(_step, 0, current_dialogue._sets.size())
        # NOTE, BUG: NOT COMPATIBLE WHEN CHANGING VARIABLE REAL-TIME
        DialogueParser.update_tags_position(
            current_dialogue, stepn, variables
        )

        if is_playing():
            _dialogue_full_string = _current_dialogue_set["line"]
            _update_display()

            if dialogue_label != null:
                dialogue_label.rerender()

const _VARIABLES_BUILT_IN : Dictionary = {
    "n" : "\n",
}
var _variables_all : Dictionary = {}

## Set a variable used in the written [Dialogue].
## [br][br]
## See also [method merge_variables], and [method remove_variable], and [method clear_variables].
func set_variable(var_name : String, value) -> void:
    variables[var_name] = value
    _update_variables_dialogue()

## Set multiple variables in a [Dictionary] used in the written [Dialogue]. Will overwrite
## same variable name with the new one.
##
## [br][br]
## See also [method set_variable], [method remove_variable], and [method clear_variables].
func merge_variables(vars : Dictionary) -> void:
    variables.merge(vars, true)
    _update_variables_dialogue()

## Remove a variable used in the written [Dialogue].
## [br][br]
## See also [method set_variable], [method merge_variables], and [method clear_variables].
func remove_variable(var_name : String) -> void:
    variables.erase(var_name)
    _update_variables_dialogue()

## Remove all variable in [member variables].
## [br][br]
## See also [method set_variable], [method merge_variables], and [method remove_variable].
func clear_variables() -> void:
    variables.clear()
    _update_variables_dialogue()

#endregion

#region NOTE: Function calls related ---------------------------------------------------------------
@export var caller_nodes : Array[Node] = []

static var _caller_built_in : Dictionary = {}
var _caller_all : Dictionary = {}

func _update_caller() -> void:
    _caller_all = _caller.merged(_caller_built_in, true)

## Return user-defined callers that will be used in the written [Dialogue].
func get_callers() -> Dictionary:
    return _caller

## Add function caller used in the written [Dialogue].
## If [param object] is a [Node], it will be removed automatically when its freed.
## [br][br]
## See also [method remove_caller], and [method clear_caller].
func add_caller(id : String, object : Object) -> void:
    _caller[id] = object
    if object is Node:
        object.tree_exited.connect(remove_caller.bind(id))
    _update_caller()

## Remove function caller used in the written [Dialogue].
## [br][br]
## See also [method add_caller], and [method clear_caller].
func remove_caller(id : String) -> void:
    if !_caller.has(id):
        push_error("Cannot remove caller: caller '%s' doesn't exists" % id)
    else:
        if _caller[id] is Node:
            if (_caller[id] as Node).tree_exited\
                .is_connected(remove_caller.bind(id)):
                (_caller[id] as Node).tree_exited.disconnect(
                    remove_caller.bind(id)
                )
        _caller.erase(id)
    _update_caller()

## Remove all function callers.
## [br][br]
## See also [method add_caller], and [method remove_caller].
func clear_callers() -> void:
    for id : String in _caller:
        if _caller[id] is Node:
            if (_caller[id] as Node).tree_exited\
                .is_connected(remove_caller.bind(id)):
                (_caller[id] as Node).tree_exited.disconnect(
                    remove_caller.bind(id)
                )
    _caller.clear()
    _update_caller()

func _call_functions(f : Dictionary) -> void:
    if allow_func:
        if !_caller_all.has(f["caller"]):
            printerr("Error @%s:%d - caller '%s' doesn't exists" % [
                current_dialogue._source_path, f["ln_num"],
                f["caller"],
            ])
        else:
            if !_caller_all[f["caller"]].has_method(f["name"]):
                printerr("Error @%s:%d - function '%s.%s()' doesn't exists" % [
                    current_dialogue._source_path, f["ln_num"],
                    f["name"], f["caller"]
                ])
            else:
                _caller_all[f["caller"]].callv(f["name"], f["args"])

func _execute_functions() -> void:
    if allow_func:
        for n in _current_dialogue_set["func"].size():
            # do not call positional functions
            if not n in _current_dialogue_set["func_idx"]:
                _call_functions(_current_dialogue_set["func"][n])

#endregion

#region NOTE: Signals ------------------------------------------------------------------------------
## Emitted when the [Dialogue] started.
signal started
## Emitted when the [Dialogue] reached the end.
signal finished

## Emitted when the [Dialogue] progressed using [method progress]. This signal is
## also emitted when the [Dialogue] is started using [member start].
signal progressed
## Same as [signal progressed], but with the line number and line data of the [Dialogue] passed.
signal progressed_at(line : int, line_data : Dictionary)

## Emitted when the [Dialogue] progress is skipped. See [method progress].
signal skipped
## Same as [signal skipped], but with the line number and line data of the [Dialogue] passed.
signal skipped_at(line : int, line_data : Dictionary)

## Emitted when the [Dialogue] progress is cancelled using [method cancel] or [method reset].
signal cancelled
## Same as [signal cancelled], but with the line number and line data of the [Dialogue] passed.
signal cancelled_at(line : int, line_data : Dictionary)

signal dialogue_switched(old_dialogue, new_dialogue)

#signal locale_changed(lang : String)

#endregion

#region NOTE: Utilities ----------------------------------------------------------------------------
func get_line() -> int:
    return _step

## Return the current [Dialogue] line data. Will return empty [Dictionary], if [member current_dialogue] is
## [code]null[/code], or if [Stage] is not currently running/playing any [Dialogue].
func get_current_line() -> Dictionary:
    if current_dialogue != null and _step >= 0:
        return current_dialogue._sets[_step]
    return {}

## Returns [code]true[/code] if [Stage] is currently playing/running a [Dialogue].
func is_playing() -> bool:
    return _step >= 0

## Returns [PackedStringArray] of unused variables in [member current_dialogue]. It
## compares [method Dialogue.get_variables] and [member variables] to find unused variables.
func get_unused_variables() -> PackedStringArray:
    if current_dialogue == null:
        return []

    var output : PackedStringArray = []
    var used_vars := variables.keys()

    for n in current_dialogue.get_variables():
        if not n in used_vars:
            output.append(n)

    return output

func get_invalid_functions() -> Dictionary:
    if current_dialogue == null:
        return {}

    var output : Dictionary = {}
    var used_funcs := current_dialogue.get_function_calls()
    var curr_caller := _caller.keys()

    for n in used_funcs:
        if not n in curr_caller:
            if !output.has("no_caller"):
                output["no_caller"] = []

            output["no_caller"].append(n)

        else:
            for m in used_funcs[n]:
                if !(_caller[n] as Object).has_method(used_funcs[n][m]["name"]):
                    if !output.has("no_method"):
                        output["no_method"] = []

                    output["no_method"].append(
                        "%s.%s" % [n, used_funcs[n][m]["name"]]
                    )

    return output

#endregion

#region NOTE: Core & Dialogue controls -------------------------------------------------------------
var _current_dialogue_length : int
var _current_dialogue_set : Dictionary
var _dialogue_full_string : String = ""

# Current progress of the Dialogue.
var _step : int = -1

## Start the [Dialogue] specified in [param dialogue], if [param dialogue] is [code]null[/code], 
## [member current_dialogue] will be used instead.
## Optionally set [param to_line] parameter to jump to a specific line when the [Dialogue] start.
func start(dialogue : Dialogue = null, to_line : int = 0) -> void:
    if is_playing():
        push_warning("Theres already a running Dialogue!")
    else:
        if dialogue != null:
            current_dialogue = dialogue

        if current_dialogue == null:
            push_error("Cannot start the Stage: `dialogue` is null")
        else:
            print("Starting Dialogue: %s..." % current_dialogue.get_source_path())
            _current_dialogue_length = current_dialogue._sets.size()

            _step = to_line - 1
            _progress_forward()
            started.emit()

# TODO
#func switch_lang(lang : String = "") -> void:
    #if current_dialogue == null:
        #push_error("Failed switching lang: current_dialogue is null")
    #else:
        #if current_dialogue.source_path == "":
            #push_error("Failed switching lang: no Dialogue source_path")
        #else:
            #var regex_lang := RegEx.new()
            #regex_lang.compile(r"\.\w{2,4}\.txt$")
            #var src := current_dialogue.source_path
            #var ext := "" if lang == "" or lang == Theatre.default_lang\
                #else ("." + lang)
#
            ## TODO: mybe `default_lang` is not necessary.
            ## Make `default_lang` as an alias
#
            #if regex_lang.search(src) == null: # is using default lang
                #src = src.insert(src.rfind(".txt"), ext)
            #else:
                #src = src.replace(
                    #regex_lang.search(src).strings[0], ext + ".txt"
                #)
#
            #if !FileAccess.file_exists(src):
                #push_error("Failed switching lang: %s does not exists" % src)
            #else:
                #var dlg_tr := Dialogue.load(src)
                #if dlg_tr._sets.size() != current_dialogue._sets.size():
                    #push_error("Failed switching lang: Dialogue length does not match")
                #else:
                    #current_dialogue = dlg_tr
                    #locale_changed.emit(lang)
                    #if is_playing():
                        #_current_dialogue_set = current_dialogue._sets[_step]
                        #_update_display()
                        #dialogue_label.rerender()

## Reset, and start over the [Dialogue] progres. Functions will be re-called. And [signal started] will also be emitted.
func restart() -> void:
    if current_dialogue == null:
        push_error("Cannot restart Stage: no current Dialogue")
    else:
        _reset_progress(true)
        start()

var _at_end := false

## Progress the [Dialogue].
## Calling [method progress] with [param skip_render] set to [code]false[/code] while the
## [member dialogue_label] is still rendering the text, will force it to finish the rendering instead of progressing. [signal skipped] will also be emitted.
## [br][br]
## If the parameter [param skip_render] is set to [code]true[/code], text rendering by the [DialogueLabel] will be
## skipped, and immediately progress to the next Dialogue line. [signal skipped] will also be emitted.
## [br][br]
## If [member allow_skip] is set to [code]false[/code]. Regardless of whether [param skip_render]
## is [code]true[/code] or [code]false[/code], the [Dialogue] won't progress until [member dialogue_label] has finished rendering.
func progress(skip_render : bool = false) -> void:
    if current_dialogue == null:
        push_error("Failed to progress Stage: no Dialogue present")
    elif dialogue_label == null:
        push_error("Failed to progress Stage: no DialogueLabel")
    elif dialogue_label.rendering_paused:
        push_warning("Attempt to progress Dialogue while rendering_paused is true on DialogueLabel")
    else:
        _at_end = _step + 1 >= _current_dialogue_length

        # TODO: optimize this conditional trees
        #if dialogue_label.visible_ratio < 1.0:
        if dialogue_label._is_rendering:
            if !skip_render:
                if allow_skip:
                    _progress_skip()
            else:
                if allow_skip:
                    if _at_end:
                        _reset_progress()
                    else:
                        _progress_forward()
        else:
            if _at_end:
                _reset_progress()
            else:
                _progress_forward()

func _progress_skip() -> void:
    dialogue_label.clear_render()
    dialogue_label.visible_ratio = 1.0
    skipped.emit()
    skipped_at.emit(_step, _current_dialogue_set)

func _progress_forward() -> void:
    dialogue_label.clear_render()

    _step += 1
    _current_dialogue_set = current_dialogue._sets[_step]
    _dialogue_full_string = _current_dialogue_set["line"]

    _execute_functions()
    _update_display()

    dialogue_label.start_render()
    progressed.emit()
    progressed_at.emit(_step, _current_dialogue_set)

## Stop the [Dialogue], clear [member dialogue_label] text render, and reset everything.
## Require [member allow_cancel] to be [code]true[/code]. Optionally, pass [code]true[/code] to keep the [member current_dialogue].
func cancel(keep_dialogue : bool = false) -> void:
    if !allow_cancel:
        print("Resetting Dialogue is not allowed")
    else:
        if current_dialogue != null:
            _reset_progress(keep_dialogue)
        else:
            push_error("Cannot cancel Stage: no Dialogue present")

## Alias for method [method cancel].
func reset(keep_dialogue : bool = false) -> void:
    cancel(keep_dialogue)

func _reset_progress(keep_dialogue : bool = false) -> void:
    print("Resetting Dialogue: %s..." % current_dialogue.get_source_path())

    if _step >= _current_dialogue_length - 1:
        finished.emit()
    else:
        cancelled.emit()
        cancelled_at.emit(_step,
            current_dialogue._sets[_step] if _step != -1 else\
            DialogueParser.SETS_TEMPLATE
        )

    _step = -1

    if actor_label != null:
        actor_label.text = ""

    dialogue_label.clear_render()
    dialogue_label.text = ""

    if !keep_dialogue:
        current_dialogue = null

func _update_display() -> void:
    if actor_label != null:
        actor_label.text = _current_dialogue_set["actor"].format(_variables_all)
    if dialogue_label != null:
        dialogue_label.text = _dialogue_full_string.format(_variables_all)

# TODO:
#func switch_dialogue(dialogue : Dialogue, current_line : bool = true) -> void:
    #pass

#endregion

func _enter_tree() -> void:
    _update_caller()

    if dialogue_label != null:
        dialogue_label._current_stage = self

    if !variables.is_empty():
        _update_variables_dialogue()

    await get_tree().current_scene.ready
    for node in caller_nodes:
        if node != null:
            add_caller("%s" % node.name, node)

func _exit_tree() -> void:
    if dialogue_label._current_stage == self:
        dialogue_label._current_stage = null

    actor_label = null
    dialogue_label = null
    current_dialogue = null

    caller_nodes.clear()
    clear_variables()
    clear_callers()
