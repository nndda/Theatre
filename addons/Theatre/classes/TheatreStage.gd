@icon("res://addons/Theatre/assets/icons/classes/ticket.svg")
@tool
class_name TheatreStage
extends Node


## Run, control, and configure [Dialogue]. Set up and reference UIs and Nodes that will be used to display the [Dialogue].
##
## [TheatreStage] connects your [Dialogue] and the [DialogueLabel]. This is where you configure and control
## your [Dialogue], manage variables, and set up function calls from your written [Dialogue].
##
## @tutorial(Configuring TheatreStage): https://theatre.nnda.dev/class/theatrestage/configuration/

var is_editor : bool = Engine.is_editor_hint()

#region NOTE: Configurations & stored variables ----------------------------------------------------

## Optional [Label] node that displays the actor/speaker's name of the current line of [member current_dialogue].
@export var actor_label : Label = null:
    set = set_actor_label,
    get = get_actor_label

func set_actor_label(node : Label) -> void:
    actor_label = node
    if node != null:
        var cb : Callable = set_actor_label.bind(null)
        if not actor_label.tree_exiting.is_connected(cb):
            actor_label.tree_exiting.connect(cb)

func get_actor_label() -> Label:
    return actor_label

## The [DialogueLabel] node that will be used to displays the [member current_dialogue]. This is [b]required[/b] to be set before running a dialogue.
@export var dialogue_label : DialogueLabel = null:
    set = set_dialogue_label,
    get = get_dialogue_label

func set_dialogue_label(node : DialogueLabel) -> void:
    dialogue_label = node
    if is_editor:
        update_configuration_warnings()
    elif node != null:
        var cb : Callable = set_dialogue_label.bind(null)
        if not dialogue_label.tree_exiting.is_connected(cb):
            dialogue_label.tree_exiting.connect(cb)

func get_dialogue_label() -> DialogueLabel:
    return dialogue_label

@export_group("Configurations")

## Allow skipping [Dialogue] or the [member dialogue_label] text rendering. See [method progress].
@export var allow_skip := true

## Allow cancelling/stopping [Dialogue] using [method cancel] or [method reset].
@export var allow_cancel := true

## Allow calling functions defined in the written [Dialogue].
@export var allow_func := true:
    set(v):
        allow_func = v

        if scope_handler != null:
            scope_handler.allow_func = v

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
                dialogue_label._characters_draw_tick / s
            dialogue_label._characters_ticker.wait_time =\
                dialogue_label._characters_draw_tick_scaled

@export_group("Dialogues")

## [Dialogue] resource to be used by [TheatreStage]. Set it by assigning your [Dialogue],
## or by passing the [Dialogue] to [method start].
## [br][br]
## [b]Note:[/b] [member current_dialogue] will be set to [code]null[/code],
## when [method cancel] or [method reset] is called with [param keep_dialogue]
## set to [code]false[/code] (default), [i]and[/i] when [TheatreStage] is finished running.
@export_storage var current_dialogue : Dialogue:
    set(new_dlg):
        current_dialogue = new_dlg
        scope_handler.current_dialogue = new_dlg

        if !is_playing() and !is_editor:
            if new_dlg != null:
                for n in current_dialogue._sets.size():
                    DialogueParser.update_tags_position(
                        current_dialogue, n, variables
                    )

#endregion

#region NOTE: Variable related ---------------------------------------------------------------------
## [Dictionary] of user-defined variables used in the written [Dialogue].
## [br][br]
## [b]Note: Do not[/b] modify [member variables] directly, use methods such as [method add_variable],
## [method merge_variables], [method remove_variable], and [method clear_variables] instead.
@export var variables : Dictionary[String, Variant] = {}:
    set = _set_variables,
    get = get_variables

func _set_variables(new_var : Dictionary[String, Variant]) -> void:
    variables = new_var

    if !is_editor:
        if is_playing():
            _update_display()

        _update_variables_dialogue()

func _update_variables_dialogue() -> void:
    if current_dialogue != null:
        DialogueParser.update_tags_position(
            current_dialogue,
            clampi(_step, 0, current_dialogue._sets.size()),
            variables,
        )

        if is_playing():
            _dialogue_full_string = _current_dialogue_set[DialogueParser.Key.CONTENT]
            _update_display()

            if dialogue_label != null:
                dialogue_label.rerender()

## Set a variable used in the written [Dialogue].
## [br][br]
## See also [method merge_variables], and [method remove_variable], and [method clear_variables].
func set_variable(var_name : String, value : Variant) -> void:
    if var_name in DialogueParser.BUILT_IN_TAGS:
        TheatreDebug.log_err(
            "Failed to set variable: built-in variable '%s' already exists" % var_name
        )
        return

    variables[var_name] = value
    _update_variables_dialogue()

## Return user-defined [member variables] used.
func get_variables() -> Dictionary:
    return variables

## Set multiple variables in a [Dictionary] used in the written [Dialogue]. Will overwrite
## same variable name with the new one.
##
## [br][br]
## See also [method set_variable], [method remove_variable], and [method clear_variables].
func merge_variables(vars : Dictionary[String, Variant]) -> void:
    for n in vars.keys():
        if n in DialogueParser.BUILT_IN_TAGS:
            TheatreDebug.log_err(
                "Failed to set multiple variables: user-defined variables can't be any of %s"
                % DialogueParser.BUILT_IN_TAGS
            )
            return

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
const ScopeHandler := preload("res://addons/Theatre/classes/ScopeHandler.gd")
var scope_handler : ScopeHandler

## Node-based scopes that are in the scene tree.
@export var scope_nodes : Dictionary[String, Node] = {}

## Return user-defined scopes that will be used in the written [Dialogue].
func get_scopes() -> Dictionary:
    return scope_handler.get_scopes()

## Add a scope used in the written dialogue.
## If [param object] is a [Node], it will be removed automatically when its freed.
## [br][br]
## See also [method remove_scope], and [method clear_scope].
func add_scope(id : String, object : Object) -> void:
    scope_handler.add_scope(id, object)

## Remove function scope used in the written [Dialogue].
## [br][br]
## See also [method add_scope], and [method clear_scope].
func remove_scope(id : String) -> void:
    scope_handler.remove_scope(id)

## Remove all function scopes.
## [br][br]
## See also [method add_scope], and [method remove_scope].
func clear_scopes() -> void:
    scope_handler.clear_scopes()

## Custom [Callable] that have the called function data as the parameter. Return[code]true[/code] to execute the function, and [code]false[/code] to skip the function call..
var func_call_filter : Callable:
    set(c):
        scope_handler.func_call_filter = c

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

## Emitted when the [Dialogue] is switched using [method switch].
signal dialogue_switched(old_dialogue : Dialogue, new_dialogue : Dialogue)

## Emitted when a function is called.
signal function_called(func_data : Dictionary, executed : bool)

#signal locale_changed(lang : String)

#endregion

#region NOTE: Utilities ----------------------------------------------------------------------------
## Return the current [Dialogue] line number.
func get_line() -> int:
    return _step

## Return the current [Dialogue] line data. Returns empty [Dictionary], if [member current_dialogue] is
## [code]null[/code], or if [TheatreStage] is not currently running any [Dialogue].
func get_current_line() -> Dictionary:
    if current_dialogue != null and _step >= 0:
        return current_dialogue._sets[_step]
    return {}

## Returns [code]true[/code] if [TheatreStage] is currently running a [Dialogue].
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

    var output : Dictionary[String, Variant] = {}
    var used_funcs := current_dialogue.get_function_calls()
    var curr_scope := scope_handler._scope.keys()

    for n in used_funcs:
        if not n in curr_scope:
            if !output.has("no_scope"):
                output["no_scope"] = []

            output["no_scope"].append(n)

        else:
            for m in used_funcs[n]:
                var _scope : Dictionary = scope_handler._scope

                if _scope[n] != null and _scope[n] is WeakRef:
                    if _scope[n].get_ref() != null:
                        if !(_scope[n].get_ref() as Object).has_method(used_funcs[n][m][DialogueParser.Key.NAME]):
                            if !output.has("no_method"):
                                output["no_method"] = []

                            output["no_method"].append(
                                "%s.%s" % [n, used_funcs[n][m][DialogueParser.Key.NAME]]
                            )

    return output

#endregion

#region NOTE: Core & Dialogue controls -------------------------------------------------------------
var _current_dialogue_length : int
var _current_dialogue_set : Dictionary:
    set(v):
        _current_dialogue_set = v
        scope_handler._current_dialogue_set = v
var _dialogue_full_string : String = ""

# Current progress of the Dialogue.
var _step : int = -1

## Start the [Dialogue] with the specified [param dialogue]. If [param dialogue] is [code]null[/code], 
## [member current_dialogue] will be used instead.
## Optionally, set [param to_section] parameter to start the [param dialogue] at a specific line or section.
func start(dialogue : Dialogue = null, to_section : Variant = 0) -> void:
    if is_playing():
        TheatreDebug.log_err(
            "Cannot start TheatreStage: Theres already a running Dialogue.",
        )
        return

    if dialogue != null:
        current_dialogue = dialogue

    if current_dialogue == null:
        TheatreDebug.log_err("Cannot start TheatreStage: `dialogue` is null.")
        return

    #if current_dialogue._sets.size() == 0:
        #printerr("%s - Possible syntax error, please review the written dialogue." % current_dialogue._source_path)
        #return

    # TODO: maybe have a 'verbose' flag in the project setting,
    # and then print this conditionally based on that flag?
    # So that these won't flood the user's console.
    print("Starting Dialogue: %s..." % current_dialogue.get_source_path())
    _current_dialogue_length = current_dialogue._sets.size()

    if to_section is int:
        if to_section > _current_dialogue_length:
            TheatreDebug.log_err(
                "Failed to start Dialogue at line %d: Dialogue length is %d" % [to_section, _current_dialogue_length],
            )
        elif to_section <= -1:
            _step = wrapi(to_section - 1, 0, _current_dialogue_length)
        else:
            _step = to_section - 1

    elif to_section is String or to_section is StringName:
        if !dialogue._sections.has(to_section):
            TheatreDebug.log_err(
                "Failed to start Dialogue at section '%s': section not found." % to_section,
            )
        else:
            _step = dialogue._sections[to_section] - 1

    else:
        TheatreDebug.log_err(
            "Failed to start Dialogue at section/line: invalid data type for '%s'." % str(to_section),
        )

    _progress_forward()
    started.emit()

## Switch the [member current_dialogue] with [param dialogue].
## Both [Dialogue] has to be the same length.
func switch(dialogue : Dialogue) -> void:
    if current_dialogue == null:
        TheatreDebug.log_err(
            "Failed switching dialogue: current_dialogue is null"
        )
    elif dialogue == null:
        TheatreDebug.log_err(
            "Failed switching dialogue: dialogue is null"
        )
    elif current_dialogue.get_length() != dialogue.get_length():
        TheatreDebug.log_err(
            "Failed switching dialogue: different dialogue length with current_dialogue"
        )
    else:
        dialogue_switched.emit(current_dialogue, dialogue)
        current_dialogue = dialogue

        if is_playing():
            _current_dialogue_set = current_dialogue._sets[_step]
            _dialogue_full_string = _current_dialogue_set[DialogueParser.Key.CONTENT]
            _update_display()
            dialogue_label.rerender()

## Reset, and start over the [Dialogue] progres. Functions will be re-called. And [signal started] will also be emitted.
func restart() -> void:
    if current_dialogue == null:
        TheatreDebug.log_err(
            "Cannot restart TheatreStage: no current Dialogue",
        )
    else:
        _reset_progress(true)
        start()

var _at_end := false

func _preprogress_check() -> bool:
    if current_dialogue == null:
        TheatreDebug.log_err(
            "Failed to progress TheatreStage: no Dialogue present"
        )
    elif dialogue_label == null:
        TheatreDebug.log_err(
            "Failed to progress TheatreStage: no DialogueLabel"
        )
    elif dialogue_label.rendering_paused:
        TheatreDebug.log_err(
            "Attempt to progress Dialogue while rendering_paused is true on DialogueLabel"
        )
    else:
        return true
    return false

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
    if _preprogress_check():
        _at_end = _step + 1 >= _current_dialogue_length

        # TODO: optimize this conditional trees
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
    skipped.emit()
    skipped_at.emit(_step, _current_dialogue_set)
    dialogue_label.clear_render()
    dialogue_label.visible_ratio = 1.0

func _progress_forward() -> void:
    dialogue_label.clear_render()

    _step += 1
    _current_dialogue_set = current_dialogue._sets[_step]

    var dyn_vars_defs : Dictionary[String, String] = scope_handler._dyn_var_get(
        _current_dialogue_set[DialogueParser.Key.VARS_SCOPE],
        _current_dialogue_set[DialogueParser.Key.VARS_EXPR],
    )

    if not dyn_vars_defs.is_empty():
        DialogueParser.update_tags_position(
            current_dialogue,
            clampi(_step, 0, _current_dialogue_set.size()),
            variables.merged(dyn_vars_defs)
        )

    _dialogue_full_string = _current_dialogue_set[DialogueParser.Key.CONTENT]

    scope_handler._execute_functions()
    _update_display()

    dialogue_label.start_render()
    progressed.emit()
    progressed_at.emit(_step, _current_dialogue_set)
 
## Jump and progress to a specific [Dialogue] line.
## Return error if [param line] is greater than [Dialogue] length.
## Will wrap if [param line] is negative.
func jump_to_line(line : int) -> void:
    if _preprogress_check():
        _goto_line(line)

## Jump to section defined in the written [Dialogue].
## [br][br]
## See also [method Dialogue.get_sections].
func jump_to_section(section : String) -> void:
    if _preprogress_check():
        if !current_dialogue._sections.has(section):
            TheatreDebug.log_err(
                "Failed to jump to Dialogue section '%s': section not found." % section
            )
        else:
            _goto_line(
                current_dialogue._sections[section]
            )

## Combined method of [method jump_to_line] and [method jump_to_section].
## Can accept [Dialogue] line number as [int], and [Dialogue] section as [String].
func jump_to(id : Variant) -> void:
    if id is int:
        jump_to_line(id)
    elif id is String or id is StringName:
        jump_to_section(id)
    else:
        TheatreDebug.log_err(
            "Failed to jump to Dialogue section/line: invalid data type for '%s'." % str(id)
        )

func _goto_line(line : int) -> void:
    if line > _current_dialogue_length:
        TheatreDebug.log_err(
            "Failed to jump to Dialogue line %d: Dialogue length is %d" % [
                line, _current_dialogue_length
            ]
        )
    elif line <= -1:
        _step = wrapi(line - 1, 0, _current_dialogue_length)
        progress(true)
    else:
        _step = line - 1
        progress(true)

## Stop the [Dialogue], clear [member dialogue_label] text render, and reset everything.
## Require [member allow_cancel] to be [code]true[/code]. Optionally, pass [code]true[/code] to keep the [member current_dialogue].
func cancel(keep_dialogue : bool = false) -> void:
    if !allow_cancel:
        print("Resetting Dialogue is not allowed")
    else:
        if current_dialogue != null:
            _reset_progress(keep_dialogue)
        else:
            TheatreDebug.log_err(
                "Cannot cancel TheatreStage: no Dialogue present"
            )

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
        actor_label.text = DialogueParser.escape_brackets(
            _current_dialogue_set[DialogueParser.Key.ACTOR].format(
                variables.merged(
                    scope_handler._dyn_var_get(
                        _current_dialogue_set[DialogueParser.Key.ACTOR_DYN_VAR],
                        _current_dialogue_set[DialogueParser.Key.ACTOR_DYN_EXPR],
                    )
                ) if _current_dialogue_set[DialogueParser.Key.ACTOR_DYN_HAS] else variables
            )
        )
    if dialogue_label != null:
        dialogue_label.text = _dialogue_full_string

# TODO:
#func switch_dialogue(dialogue : Dialogue, current_line : bool = true) -> void:
    #pass

#endregion

func _enter_tree() -> void:
    if !is_editor:
        scope_handler = ScopeHandler.new(self)

        if dialogue_label != null:
            dialogue_label._current_stage = self

        _update_variables_dialogue()

func _exit_tree() -> void:
    if !is_editor:
        if dialogue_label != null:
            if dialogue_label._current_stage == self:
                dialogue_label._current_stage = null

        actor_label = null
        dialogue_label = null
        current_dialogue = null

        scope_nodes.clear()
        clear_variables()
        scope_handler.clear_scopes()

func _get_configuration_warnings() -> PackedStringArray:
    var warnings : PackedStringArray = []
    if dialogue_label == null:
        warnings.append(
            "No DialogueLabel assigned. Create a DialogueLabel node, and assign it to the dialogue_label variable."
        )
    return warnings
