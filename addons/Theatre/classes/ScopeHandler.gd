extends RefCounted

# NOTE#1: standalone DialogueLabel doesn't have the actual Dialogue resource
# attached/embedded. Instead, it only have the parsed, raw dialogue data
# from the written dialogue provided (DialogueLabel.dialogue_text)
#
# And so, current_dialogue will be null, for ScopeHandler of DialogueLabel
var current_dialogue : Dialogue:
    set(dlg):
        current_dialogue = dlg
        if dlg != null:
            _dialogue_source_path = dlg._source_path
var _current_dialogue_set : Dictionary
# Source path is handled separately because of NOTE#1
var _dialogue_source_path : String = ""

var allow_func : bool = true

var _handler : Node # TheatreStage or DialogueLabel

# TODO: maybe use StringName as the scope id instead?
@export_storage var _scope : Dictionary[String, WeakRef] = {}
var _scope_all : Dictionary[String, WeakRef] = {}

signal function_called(func_data : Dictionary, executed : bool)

func _init(_handler_node : Node) -> void:
    if not Engine.is_editor_hint():
        if _handler_node is TheatreStage or _handler_node is DialogueLabel:

            if _handler_node is TheatreStage:
                allow_func = _handler_node.allow_func
            elif _handler_node is DialogueLabel:
                _dialogue_source_path = str(_handler_node.get_path())

            function_called.connect(_handler_node.function_called.emit)

            _handler = _handler_node

            if not _scope_built_in_initialized:
                _handler.tree_entered.connect(_initialize_builtin_scopes)

static var _scope_built_in : Dictionary[String, WeakRef] = {}
static var _scope_built_in_initialized := false
func _initialize_builtin_scopes() -> void:
    if not _scope_built_in_initialized:
        var tree := _handler.get_tree()

        for singleton in Engine.get_singleton_list():
            _scope_built_in[singleton] = weakref(Engine.get_singleton(singleton))

        for autoload: Node in tree.root.get_children():
            if autoload != tree.current_scene:
                _scope_built_in[String(autoload.name)] = weakref(autoload)

        _scope_built_in_initialized = true
        _update_scope()

func _update_scope() -> void:
    _scope_all = _scope.merged(_scope_built_in, true)
    # TODO, NOTE: this seems... not very performant... how about maybe something like:
    _scope_all.clear()
    _scope_all.merge(_scope, true)
    _scope_all.merge(_scope_built_in, true)

func get_scopes() -> Dictionary:
    return _scope

func add_scope(id : String, object : Object) -> void:
    _scope[id] = weakref(object)
    _update_scope()

func merge_scopes(scopes : Dictionary[String, Object]) -> void:
    for id: String in scopes:
        _scope[id] = weakref(scopes[id])
    _update_scope()

func remove_scope(id : String) -> void:
    if not _scope.has(id):
        TheatreDebug.log_err(
            "Cannot remove scope: scope '%s' doesn't exists" % id
        )
    else:
        _scope.erase(id)
    _update_scope()

## Remove all function scopes.
## [br][br]
## See also [method add_scope], and [method remove_scope].
func clear_scopes() -> void:
    _scope.clear()
    _update_scope()

var func_call_filter : Callable:
    set(cb):
        var args_count : int = cb.get_argument_count()
        if args_count != 1:
            TheatreDebug.log_err(
                "'func_call_filter' callable argument != 1 (%d)" % args_count
            )
        else:
            func_call_filter = cb

var _expression_args := Expression.new()
func _call_function(f : Dictionary) -> void:
    if not allow_func:
        return

    #region NOTE: User-defined function call filter
    if func_call_filter.is_valid():
        var func_call_allowed : Variant = func_call_filter.call(f)
        var func_call_filter_return : int = typeof(func_call_allowed)

        if func_call_filter_return != TYPE_BOOL:
            TheatreDebug.log_err(
                "'func_call_filter' callable returns '%s', instead of 'bool" % type_string(func_call_filter_return)
            )
        else:
            if not func_call_allowed:
                function_called.emit(f, false)
                return
    #endregion

    var func_scope : StringName = f[DialogueParser.Key.SCOPE]
    var func_path : NodePath = f[DialogueParser.Key.PROPERTY_PATH]
    var func_vars : Array = f[DialogueParser.Key.VARS]

    #region general error checks
    if !_scope_all.has(func_scope):
        printerr(
            "Cannot call dialogue function: scope '%s' doesn't exists.\n  dialogue: %s:%d" % [
                func_scope, _dialogue_source_path, f[DialogueParser.Key.LINE_NUM],
            ],
        )
        return

    var scope_obj : Object = _scope_all[func_scope].get_ref()

    if scope_obj == null:
        printerr(
            "Cannot call dialogue function: object of the scope '%s' is null.\n  dialogue: %s:%d" % [
                func_scope, _dialogue_source_path, f[DialogueParser.Key.LINE_NUM],
            ],
        )
        return

    var scope_obj_path := scope_obj.get_indexed(func_path)

    if scope_obj_path == null:
        printerr(
            "Cannot call dialogue function: function '%s.%s()' doesn't exists.\n  dialogue: %s:%d" % [
                func_scope, str(func_path).replace(DialogueParser.COLON, DialogueParser.DOT), _dialogue_source_path, f[DialogueParser.Key.LINE_NUM],
            ],
        )
        return
    #endregion

    if f[DialogueParser.Key.STANDALONE]:
        scope_obj_path.callv(f[DialogueParser.Key.ARGS])
        function_called.emit(f, true)
        return

    if func_vars.any(_func_args_inp_check_scope.bind(_scope_all.keys())):
        printerr(
            "Cannot call dialogue function: argument scope(s) used: %s doesn't exists.\n  dialogue: %s:%d" % [
                func_vars, _dialogue_source_path, f[DialogueParser.Key.LINE_NUM],
            ],
        )
        return

    var expr_err := _expression_args.parse(f[DialogueParser.Key.ARGS], func_vars as PackedStringArray)
    var expr_args = _expression_args.execute(
        (func_vars as Array[String]).map(_func_args_inp_get),
    scope_obj)

    if _expression_args.has_execute_failed() or expr_err != OK:
        printerr(
            "Cannot call dialogue function: Failed parsing function call arguments: %s.\n  dialogue: %s:%d" % [
                _expression_args.get_error_text(), _dialogue_source_path, f[DialogueParser.Key.LINE_NUM],
            ],
        )
        return

    scope_obj_path.callv(expr_args)
    function_called.emit(f, true)

func _func_args_inp_get(arg_str : String) -> Object:
    if not _scope_all.has(arg_str):
        TheatreDebug.log_err(
            "Error @%s:%d - scope '%s' doesn't exists" % [
                _dialogue_source_path, _current_dialogue_set[DialogueParser.Key.LINE_NUM],
                arg_str,
            ]
        )
        return null
    return _scope_all[arg_str].get_ref()

func _func_args_inp_check_scope(arg_str : String, arg_arr : Array) -> bool:
    return !arg_arr.has(arg_str)

func _execute_functions() -> void:
    if allow_func:
        for n in _current_dialogue_set[DialogueParser.Key.FUNC].size():
            # do not call positional functions
            if not n in _current_dialogue_set[DialogueParser.Key.FUNC_IDX]:
                _call_function(_current_dialogue_set[DialogueParser.Key.FUNC][n])

func _dyn_var_get(
    vars_scoped: Array,
    vars_expr: Array,
) -> Dictionary[String, String]:
    var dyn_vars_defs : Dictionary[String, String] = {}

    for scoped_vars : Array in vars_scoped:
        if _scope_all.has(scoped_vars[1]):
            var scope_obj : Object = _scope_all[scoped_vars[1]].get_ref()

            if scope_obj.get_indexed(scoped_vars[2]) != null:
                dyn_vars_defs[scoped_vars[0]] = scope_obj.get_indexed(scoped_vars[2])

    for expr_vars : Dictionary in vars_expr:
        var expr_err := _expression_args.parse(expr_vars[DialogueParser.Key.CONTENT], expr_vars[DialogueParser.Key.ARGS])
        var expr_res = _expression_args.execute(
            (expr_vars[DialogueParser.Key.ARGS] as Array[String]).map(_func_args_inp_get),
            null,
            false,
        )

        if _expression_args.has_execute_failed() or expr_err != OK:
            TheatreDebug.log_err(
                "Failed executing dynamic value @%s:%d - %s" % [
                    _dialogue_source_path, _current_dialogue_set[DialogueParser.Key.LINE_NUM],
                    _expression_args.get_error_text(),
                ]
            )

        dyn_vars_defs[expr_vars[DialogueParser.Key.NAME]] = "" if expr_res == null else str(expr_res)

    return dyn_vars_defs
