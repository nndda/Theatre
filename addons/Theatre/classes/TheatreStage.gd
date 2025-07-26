@icon("res://addons/Theatre/assets/icons/classes/ticket.svg")
class_name TheatreStage
extends Node

## Run, control, and configure [Dialogue], and reference UIs and Nodes that will be used to display the [Dialogue].
##
## @tutorial(Theatre's tutorial page): https://nndda.github.io/Theatre/tutorials/
##
## [TheatreStage] connects your [Dialogue] and the [DialogueLabel]. This is where you configure and control
## your [Dialogue], manage variables, and set up function calls from your written [Dialogue].


#region NOTE: Configurations & stored variables ----------------------------------------------------

## Optional [Label] node that displays actors of the current line of [member current_dialogue].
@export var actor_label : Label = null:
    set = set_actor_label,
    get = get_actor_label

func set_actor_label(node : Label) -> void:
    actor_label = node
    if node != null:
        actor_label.tree_exiting.connect(set_actor_label.bind(null))

func get_actor_label() -> Label:
    return actor_label

## [DialogueLabel] node that displays the [Dialogue] line body. This is [b]required[/b] to be set before playing or running [Dialogue].
@export var dialogue_label : DialogueLabel = null:
    set = set_dialogue_label,
    get = get_dialogue_label

func set_dialogue_label(node : DialogueLabel) -> void:
    dialogue_label = node
    if node != null:
        dialogue_label.tree_exiting.connect(set_dialogue_label.bind(null))

func get_dialogue_label() -> DialogueLabel:
    return dialogue_label

@export_group("Configurations")

## Allow skipping [Dialogue] or the [member dialogue_label] text rendering. See [method progress].
@export var allow_skip := true

## Allow cancelling/stopping [Dialogue] with [method cancel] or [method reset].
@export var allow_cancel := true

## Allow calling functions defined in the written [Dialogue].
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

## [Dialogue] resource to be used by [TheatreStage]. Set it by assigning your [Dialogue],
## or by passing the [Dialogue] to [method start].
## [br][br]
## [b]Note:[/b] [member current_dialogue] will be set to [code]null[/code],
## when [method cancel] or [method reset] is called with [param keep_dialogue]
## set to [code]false[/code] (default), [i]and[/i] when [TheatreStage] is finished running.
@export_storage var current_dialogue : Dialogue:
    set(new_dlg):
        current_dialogue = new_dlg
        if !is_playing():
            if new_dlg != null:
                for n in current_dialogue._sets.size():
                    DialogueParser.update_tags_position(
                        current_dialogue, n, variables
                    )

@export_storage var _scope : Dictionary = {}

#endregion

#region NOTE: Variable related ---------------------------------------------------------------------
## [Dictionary] of user-defined variables used in the written [Dialogue].
## [br][br]
## [b]Note: Do not[/b] modify [member variables] directly, use methods such as [method add_variable],
## [method merge_variables], [method remove_variable], and [method clear_variables] instead.
@export var variables : Dictionary = {}:
    set = _set_variables,
    get = get_variables

func _set_variables(new_var : Dictionary) -> void:
    variables = new_var

    if is_playing():
        _update_display()

    _update_variables_dialogue()

func _update_variables_dialogue() -> void:
    _variables_all.clear()
    _variables_all.merge(variables, true)
    if current_dialogue != null:
        var stepn := clampi(_step, 0, current_dialogue._sets.size())
        # NOTE, BUG: NOT COMPATIBLE WHEN CHANGING VARIABLE REAL-TIME
        DialogueParser.update_tags_position(
            current_dialogue, stepn, variables
        )

        if is_playing():
            _dialogue_full_string = _current_dialogue_set[DialogueParser.__CONTENT]
            _update_display()

            if dialogue_label != null:
                dialogue_label.rerender()

var _variables_all : Dictionary = {}

## Set a variable used in the written [Dialogue].
## [br][br]
## See also [method merge_variables], and [method remove_variable], and [method clear_variables].
func set_variable(var_name : String, value : Variant) -> void:
    if var_name in DialogueParser.BUILT_IN_TAGS:
        push_error("Failed to set variable: built-in variable '%s' already exists" % var_name)
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
func merge_variables(vars : Dictionary) -> void:
    for n in vars.keys():
        if n in DialogueParser.BUILT_IN_TAGS:
            push_error(
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
## Node-based scopes that are in the scene tree.
@export var scope_nodes : Array[Node] = []

static var _scope_built_in : Dictionary = {}
var _scope_all : Dictionary = {}

func _update_scope() -> void:
    _scope_all = _scope.merged(_scope_built_in, true)

## Return user-defined scopes that will be used in the written [Dialogue].
func get_scopes() -> Dictionary:
    return _scope
## @deprecated: Use [method get_scopes] instead.
func get_callers() -> Dictionary:
    return get_scopes()

## Add function scope used in the written [Dialogue].
## If [param object] is a [Node], it will be removed automatically when its freed.
## [br][br]
## See also [method remove_scope], and [method clear_scope].
func add_scope(id : String, object : Object) -> void:
    _scope[id] = weakref(object)
    if object is Node:
        object.tree_exited.connect(remove_scope.bind(id))
    _update_scope()
## @deprecated: Use [method add_scope] instead.
func add_caller(id : String, object : Object) -> void:
    add_scope(id, object)


## Remove function scope used in the written [Dialogue].
## [br][br]
## See also [method add_scope], and [method clear_scope].
func remove_scope(id : String) -> void:
    if !_scope.has(id):
        push_error("Cannot remove scope: scope '%s' doesn't exists" % id)
    else:
        _scope.erase(id)
    _update_scope()
## @deprecated: Use [method remove_scope] instead.
func remove_caller(id: String) -> void:
    remove_scope(id)

## Remove all function scopes.
## [br][br]
## See also [method add_scope], and [method remove_scope].
func clear_scopes() -> void:
    _scope.clear()
    _update_scope()
## @deprecated: Use [method clear_scopes] instead.
func clear_callers() -> void:
    clear_scopes()

var _expression_args := Expression.new()
func _call_function(f : Dictionary) -> void:
    if !allow_func:
        return

    var func_scope : StringName = f[DialogueParser.__SCOPE]
    var func_name : StringName = f[DialogueParser.__NAME]
    var func_vars : Array = f[DialogueParser.__VARS]

    #region general error checks
    if !_scope_all.has(func_scope):
        push_error("Error @%s:%d - scope '%s' doesn't exists" % [
            current_dialogue._source_path, f[DialogueParser.__LN_NUM],
            func_scope,
        ])
        return

    var scope_obj : Object = _scope_all[func_scope].get_ref()

    if scope_obj == null:
        push_error("Error @%s:%d - object of the scope '%s' is null" % [
            current_dialogue._source_path, f[DialogueParser.__LN_NUM],
            func_scope,
        ])
        return

    if !scope_obj.has_method(func_name):
        push_error("Error @%s:%d - function '%s.%s()' doesn't exists" % [
            current_dialogue._source_path, f[DialogueParser.__LN_NUM],
            func_scope, func_name
        ])
        return
    #endregion

    if f[DialogueParser.__STANDALONE]:
        scope_obj.callv(func_name, f[DialogueParser.__ARGS])
        return

    if func_vars.any(_func_args_inp_check_scope.bind(_scope_all.keys())):
        push_error("Error @%s:%d - argument scope(s) used: %s doesn't exists" % [
            current_dialogue._source_path, f[DialogueParser.__LN_NUM],
            func_vars,
        ])
        return

    var expr_err := _expression_args.parse(f[DialogueParser.__ARGS], func_vars as PackedStringArray)
    var expr_args = _expression_args.execute(
        (func_vars as Array[String]).map(_func_args_inp_get),
    scope_obj)

    if _expression_args.has_execute_failed() or expr_err != OK:
        push_error("Error @%s:%d - %s" % [
            current_dialogue._source_path, f[DialogueParser.__LN_NUM],
            _expression_args.get_error_text(),
        ])
        return

    scope_obj.callv(func_name, expr_args)

func _func_args_inp_get(arg_str : String) -> Object:
    return _scope_all[arg_str].get_ref()

func _func_args_inp_check_scope(arg_str : String, arg_arr : Array) -> bool:
    return !arg_arr.has(arg_str)

func _execute_functions() -> void:
    if allow_func:
        for n in _current_dialogue_set[DialogueParser.__FUNC].size():
            # do not call positional functions
            if not n in _current_dialogue_set[DialogueParser.__FUNC_IDX]:
                _call_function(_current_dialogue_set[DialogueParser.__FUNC][n])

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

## Emitted when the [Dialogue] is switched using [method switch].
signal dialogue_switched(old_dialogue : Dialogue, new_dialogue : Dialogue)

#signal locale_changed(lang : String)

#endregion

#region NOTE: Utilities ----------------------------------------------------------------------------
## Return the current [Dialogue] line number.
func get_line() -> int:
    return _step

## Return the current [Dialogue] line data. Will return empty [Dictionary], if [member current_dialogue] is
## [code]null[/code], or if [TheatreStage] is not currently running/playing any [Dialogue].
func get_current_line() -> Dictionary:
    if current_dialogue != null and _step >= 0:
        return current_dialogue._sets[_step]
    return {}

## Returns [code]true[/code] if [TheatreStage] is currently playing/running a [Dialogue].
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
    var curr_scope := _scope.keys()

    for n in used_funcs:
        if not n in curr_scope:
            if !output.has("no_scope"):
                output["no_scope"] = []

            output["no_scope"].append(n)

        else:
            for m in used_funcs[n]:
                if _scope[n] != null and _scope[n] is WeakRef:
                    if _scope[n].get_ref() != null:
                        if !(_scope[n].get_ref() as Object).has_method(used_funcs[n][m][DialogueParser.__NAME]):
                            if !output.has("no_method"):
                                output["no_method"] = []

                            output["no_method"].append(
                                "%s.%s" % [n, used_funcs[n][m][DialogueParser.__NAME]]
                            )

    return output

#endregion

#region NOTE: Core & Dialogue controls -------------------------------------------------------------
var _current_dialogue_length : int
var _current_dialogue_set : Dictionary
var _dialogue_full_string : String = ""

# Current progress of the Dialogue.
var _step : int = -1

## Start the [Dialogue] with the specified [param dialogue]. If [param dialogue] is [code]null[/code], 
## [member current_dialogue] will be used instead.
## Optionally, set [param to_section] parameter to start the [param dialogue] at a specific line or section.
func start(dialogue : Dialogue = null, to_section : Variant = 0) -> void:
    if is_playing():
        push_warning("Theres already a running Dialogue!")
    else:
        if dialogue != null:
            current_dialogue = dialogue

        if current_dialogue == null:
            push_error("Cannot start the TheatreStage: `dialogue` is null")
        else:
            print("Starting Dialogue: %s..." % current_dialogue.get_source_path())
            _current_dialogue_length = current_dialogue._sets.size()

            if to_section is int:
                if to_section > _current_dialogue_length:
                    push_error("Failed to start Dialogue at line %d: Dialogue length is %d" % [
                        to_section, _current_dialogue_length
                    ])
                elif to_section <= -1:
                    _step = wrapi(to_section - 1, 0, _current_dialogue_length)
                else:
                    _step = to_section - 1

            elif to_section is String or to_section is StringName:
                if !dialogue._sections.has(to_section):
                    push_error("Failed to start Dialogue at section '%s': section not found." % to_section)
                else:
                    _step = dialogue._sections[to_section] - 1

            else:
                push_error("Failed to start Dialogue at section/line: invalid data type for '%s'." % str(to_section))

            _progress_forward()
            started.emit()

## Switch the [member current_dialogue] with [param dialogue].
## Both [Dialogue] has to be the same length.
func switch(dialogue : Dialogue) -> void:
    if current_dialogue == null:
        push_error("Failed switching dialogue: current_dialogue is null")
    elif dialogue == null:
        push_error("Failed switching dialogue: dialogue is null")
    elif current_dialogue.get_length() != dialogue.get_length():
        push_error("Failed switching dialogue: different dialogue length with current_dialogue")
    else:
        dialogue_switched.emit(current_dialogue, dialogue)
        current_dialogue = dialogue

        if is_playing():
            _current_dialogue_set = current_dialogue._sets[_step]
            _dialogue_full_string = _current_dialogue_set[DialogueParser.__CONTENT]
            _update_display()
            dialogue_label.rerender()

## Reset, and start over the [Dialogue] progres. Functions will be re-called. And [signal started] will also be emitted.
func restart() -> void:
    if current_dialogue == null:
        push_error("Cannot restart TheatreStage: no current Dialogue")
    else:
        _reset_progress(true)
        start()

var _at_end := false

func _preprogress_check() -> bool:
    if current_dialogue == null:
        push_error("Failed to progress TheatreStage: no Dialogue present")
    elif dialogue_label == null:
        push_error("Failed to progress TheatreStage: no DialogueLabel")
    elif dialogue_label.rendering_paused:
        push_warning("Attempt to progress Dialogue while rendering_paused is true on DialogueLabel")
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
    _dialogue_full_string = _current_dialogue_set[DialogueParser.__CONTENT]

    _execute_functions()
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
            push_error("Failed to jump to Dialogue section '%s': section not found." % section)
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
        push_error("Failed to jump to Dialogue section/line: invalid data type for '%s'." % str(id))

func _goto_line(line : int) -> void:
    if line > _current_dialogue_length:
        push_error("Failed to jump to Dialogue line %d: Dialogue length is %d" % [
            line, _current_dialogue_length
        ])
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
            push_error("Cannot cancel TheatreStage: no Dialogue present")

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
            _current_dialogue_set[DialogueParser.__ACTOR].format(_variables_all)
        )
    if dialogue_label != null:
        dialogue_label.text = DialogueParser.escape_brackets(
            _dialogue_full_string.format(_variables_all)
        )
    # TODO
    #if _current_dialogue_set[DialogueParser.__HAS_VARS]:
        #if actor_label != null:
            #actor_label.text = DialogueParser.escape_brackets(
                #_current_dialogue_set[DialogueParser.__ACTOR].format(_variables_all)
            #)
        #if dialogue_label != null:
            #dialogue_label.text = DialogueParser.escape_brackets(
                #_dialogue_full_string.format(_variables_all)
            #)
    #else:
        #if actor_label != null:
            #actor_label.text = DialogueParser.escape_brackets(
                #_current_dialogue_set[DialogueParser.__ACTOR]
            #)
        #if dialogue_label != null:
            #dialogue_label.text = DialogueParser.escape_brackets(
                #_dialogue_full_string
            #)

# TODO:
#func switch_dialogue(dialogue : Dialogue, current_line : bool = true) -> void:
    #pass

#endregion

func _enter_tree() -> void:
    _update_scope()
    add_scope("TheatreStage", self)

    if dialogue_label != null:
        print("assigning stage to dlg label")
        dialogue_label._current_stage = self

    _update_variables_dialogue()

    if !scope_nodes.is_empty():
        await get_tree().current_scene.ready
        for node in scope_nodes:
            if node != null:
                add_scope(node.name, node)

func _exit_tree() -> void:
    if dialogue_label != null:
        if dialogue_label._current_stage == self:
            dialogue_label._current_stage = null

    actor_label = null
    dialogue_label = null
    current_dialogue = null

    scope_nodes.clear()
    clear_variables()
    clear_scopes()
