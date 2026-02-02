@icon("res://addons/Theatre/assets/icons/classes/message.svg")
@tool
class_name DialogueLabel
extends RichTextLabel

## Control node built for displaying [Dialogue].
##
## @tutorial(Theatre's tutorial page): https://nndda.github.io/Theatre/tutorials/
##
## A [RichTextLabel] inherited node that are built for displaying and rendering [Dialogue] lines.
## [DialogueLabel] has a partial support for BBCode tags, as for now, the [code][img][/code] tag are not supported.
## [member RichTextLabel.bbcode_enabled] will always be [code]true[/code].

var _is_editor : bool = Engine.is_editor_hint()

## Each string character will be drawn every [param _characters_draw_tick] seconds
var _characters_draw_tick : float = .015
var _characters_draw_tick_scaled : float

@export_range(1., 120., 1., "suffix:chars/s") var chars_per_second: float = 1/.015:
    set(val):
        chars_per_second = val
        _characters_draw_tick = 1. / val

#region NOTE: Standalone configuration & core ------------------------------------------------------
@export_category("Standalone Config")
@export var is_standalone: bool = false:
    set(v):
        is_standalone = v
        if _is_editor:
            notify_property_list_changed()

var _dialogue_text_parse_timer : SceneTreeTimer
@export_multiline var dialogue_text: String = "":
    set(v):
        dialogue_text = v
        #region NOTE: debounce real-time editor parsing
        if is_inside_tree():
            if _dialogue_text_parse_timer:
                if _dialogue_text_parse_timer.time_left > 0:
                    _dialogue_text_parse_timer.timeout.disconnect(_parse_dialogue)
                    _dialogue_text_parse_timer = null

            _dialogue_text_parse_timer = get_tree().create_timer(.35)
            _dialogue_text_parse_timer.timeout.connect(_parse_dialogue)
        #endregion

@export var variables : Dictionary[String, String] = {}
@export var scope_nodes : Dictionary[String, Node] = {}

@export_storage var _dialogue_content : Dictionary

const ScopeHandler := preload("res://addons/Theatre/classes/ScopeHandler.gd")
var _scope_handler : ScopeHandler

func _parse_dialogue() -> void:
    _dialogue_content = DialogueParser\
        .new(
            # Simulate 'full' dialogue syntax with empty actor
            "_:\n" + dialogue_text.indent(DialogueParser.INDENT_4)
        )\
        # Only grabs the raw data
        .output[0]

## Emitted when a function is called.
signal function_called(func_data : Dictionary, executed : bool)

func _update_variables_dialogue() -> void:
    # Update the dialogue data.
    _dialogue_content.merge(
        DialogueParser.parse_tags(
            (
                _dialogue_content[DialogueParser.Key.CONTENT_RAW] as String
            ).format(
                # Insert the static variables,...
                variables.merged(
                    # ...and the dynamic/scope-based variables...
                    _scope_handler._dyn_var_get(
                        _dialogue_content[DialogueParser.Key.VARS_SCOPE],
                        _dialogue_content[DialogueParser.Key.VARS_EXPR],
                    )
                ) if (
                    # ...but only if it has any.
                    _dialogue_content[DialogueParser.Key.VARS_SCOPE] as Array
                ).is_empty() else variables # Otherwise, only insert the static variables.
            )
        ),
        true,
    )

    # Update the visible text with the updated dialogue content.
    text = _dialogue_content[DialogueParser.Key.CONTENT]
#endregion

#region NOTE: Setup --------------------------------------------------------------------------------
# NOTE: These are cyclic references right?
var _current_stage : TheatreStage:
    set = set_stage,
    get = get_stage

## Returns the [TheatreStage] that is currently controling the [DialogueLabel].
func get_stage() -> TheatreStage:
    return _current_stage

## Set the [TheatreStage] that will be used to control the [DialogueLabel]. If there's already a [TheatreStage]
## set, this will remove the previous [member TheatreStage.dialogue_label].
## [br][br]
## [b]Note:[/b] [member TheatreStage.dialogue_label] will be set automatically when you assign
## a [DialogueLabel] to the [TheatreStage] on the inspector.
func set_stage(stage : TheatreStage) -> void:
    if stage != null:
        if is_standalone:
            TheatreDebug.log_err(
                "Binding standalone DialogueLabel to a TheatreStage instance is not allowed"
            )
        else:
            _current_stage = stage
            _scope_handler = stage.scope_handler
            if !_current_stage.skipped.is_connected(_on_stage_skipped):
                _current_stage.skipped.connect(_on_stage_skipped)
    else:
        if _current_stage.skipped.is_connected(_on_stage_skipped):
            _current_stage.skipped.disconnect(_on_stage_skipped)
        _current_stage = null

func _validate_property(property: Dictionary) -> void:
    var property_name : String = property["name"]

    # Hide and set bbcode_enabled to true.
    if property_name == "bbcode_enabled":
        bbcode_enabled = true
        property["usage"] = PROPERTY_USAGE_NO_EDITOR
        return

    #region
    # NOTE: Only shows standalone-related properties,
    # when is_standalone is true.

    var is_standalone_properties : bool =\
        property_name == "dialogue_text" or \
        property_name == "scope_nodes" or \
        property_name == "variables" or \
        property_name == "scope_nodes"

    if is_standalone:
        if is_standalone_properties:
            property["usage"] = PROPERTY_USAGE_DEFAULT

        elif property_name == "text":
            property["usage"] = PROPERTY_USAGE_NO_EDITOR
    else:
        if is_standalone_properties:
            property["usage"] = PROPERTY_USAGE_NO_EDITOR
    #endregion

func _enter_tree() -> void:
    if _is_editor:
        # One-time initialization
        const _IS_INITIALIZED_KEY : StringName = &"_is_initialized"

        if !get_meta(_IS_INITIALIZED_KEY, false):
            visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
            set_meta(_IS_INITIALIZED_KEY, true)
    else:
        _characters_draw_tick = 1. / chars_per_second

        _delay_timer = Timer.new()
        _characters_ticker = Timer.new()

        text = ""
        bbcode_enabled = true

        _delay_timer.autostart = false
        _delay_timer.one_shot = true
        _delay_timer.timeout.connect(_delay_timer_timeout)
        add_child(_delay_timer)

        _characters_ticker.autostart = false
        _characters_ticker.one_shot = false
        _characters_ticker.timeout.connect(_characters_ticker_timeout)
        add_child(_characters_ticker)

        if is_standalone:
            _scope_handler = ScopeHandler.new(self)

            # Merge scope_nodes to the handler's scope list
            if not scope_nodes.is_empty():
                for id: String in scope_nodes:
                    _scope_handler._scope[id] = weakref(scope_nodes[id])
                _scope_handler._update_scope()

func _ready() -> void:
    if not _is_editor:
        visible_ratio = 0.
#endregion

#region NOTE: Signals ------------------------------------------------------------------------------
## Emitted when the text or the [Dialogue] line has finished rendering.
signal text_rendered

## Emitted everytime a character drawn.
signal character_drawn
#endregion

#region NOTE: Core & rendering ---------------------------------------------------------------------
var _is_rendering := false

## If [code]true[/code], text rendering will be paused.
## Progressing [Dialogue] won't work until [member rendering_paused]
## is set to [code]false[/code],
## or [method resume_render] is called.
## [br][br]
## See also [method pause_render] and [method resume_render].
var rendering_paused := false:
    set(v):
        rendering_paused = v
        _characters_ticker.paused = v

var _delay_queue : PackedInt64Array = []
var _delay_count : int = 0
var _speed_queue : PackedInt64Array = []
var _speed_count : int = 0
var _jump_queue : PackedInt64Array = []
var _jump_count : int = 0
var _func_queue : PackedInt64Array = []
var _func_count : int = 0

var _delay_timer : Timer
var _characters_ticker : Timer

var _current_dialogue_set : Dictionary = {}

## Start the rendering of the current [Dialogue] line text.
func start_render() -> void:
    if is_standalone:
        _update_variables_dialogue()

    visible_ratio = 0.

    _current_dialogue_set = _dialogue_content if is_standalone else _current_stage._current_dialogue_set
    text = _current_dialogue_set[DialogueParser.Key.CONTENT]
    _delay_timer.one_shot = true

    _characters_draw_tick_scaled = _characters_draw_tick /\
        (1.0 if is_standalone else (_current_stage.speed_scale_global / _current_stage.speed_scale))
    _characters_ticker.start(_characters_draw_tick_scaled)

    # Set up & count dialogue tags queues.
    #
    # In the character rendering step @_characters_ticker_timeout() (hot path):
    #   - Check if _<tag>_count < 0,
    #   - and if current visible character matches _<tag>_queue[_<tag>_count],
    #   - increment the count by 1, and modify the rendering behaviour according to the tag.
    #
    # _<tag>_count is negative-counted because the alternatives (positive count)
    # will requires _<tag>_queue.reverse(),
    # which is another overhead in the setup (this section of the codes you're currently reading).
    #
    # TODO?: perhaps the tags queue should be reversed on the parse-time?
    # then the negating of the queue count won't be needed.
    # But I'm not very sure about the ordering system and behaviour for dictionary :/
    _delay_queue = _current_dialogue_set\
        [DialogueParser.Key.TAGS]\
        [DialogueParser.Key.TAGS_DELAYS].keys()
    _delay_count = -_delay_queue.size()

    _speed_queue = _current_dialogue_set\
        [DialogueParser.Key.TAGS]\
        [DialogueParser.Key.TAGS_SPEEDS].keys()
    _speed_count = -_speed_queue.size()

    _jump_queue = _current_dialogue_set\
        [DialogueParser.Key.TAGS]\
        [DialogueParser.Key.TAGS_JUMP].keys()
    _jump_count = -_jump_queue.size()

    _func_queue = _current_dialogue_set[DialogueParser.Key.FUNC_POS].keys()
    _func_count = -_func_queue.size()

    _is_rendering = true

## Stop the process of rendering text, and clear the [DialogueLabel] text.
func clear_render() -> void:
    # Stop the timers and tickers
    _delay_timer.stop()
    _characters_ticker.stop()

    # Reset/hide the displayed content.
    visible_ratio = 0.

    # Clears out previous dialogue line's tags data.
    # TODO: rather than .clear()ing everything, maybe we could use a single, global, read-only,
    # empty array, and point it to that value instead.
    # Since _<tag>_queue are all read-only, grabbed/copied from the dialogue data.
    # And will be *replaced* by the tags data (dict.keys()) in the setup @start_render anyway.
    _delay_queue.clear()
    _delay_count = 0
    _speed_queue.clear()
    _speed_count = 0
    _jump_queue.clear()
    _jump_count = 0
    _func_queue.clear()
    _func_count = 0

    # Same with above's TODO, but for dictionary.
    _current_dialogue_set = {}

    _is_rendering = false


## Returns [code]true[/code] if the [DialogueLabel] is in the process of rendering text.
func is_rendering() -> bool:
    return _is_rendering

## Restart text rendering. Written [Dialogue] functions will also be re-called.
func rerender() -> void:
    clear_render()
    start_render()

## Pause text rendering. The same as setting [member rendering_paused] to [code]true[/code].
## Progressing [Dialogue] won't work until [method resume_render]
## is called, or [member rendering_paused] is set to [code]false[/code].
func pause_render() -> void:
    rendering_paused = true
    _characters_ticker.paused = rendering_paused

## Continue paused text rendering. The same as setting [member rendering_paused] to [code]false[/code].
func resume_render() -> void:
    rendering_paused = false
    _characters_ticker.paused = rendering_paused

func _characters_ticker_timeout() -> void: #NOTE: HOT PATH
    #region Handle Dialogue tags
    # {delay} tag
    if _delay_count < 0:
        if _delay_queue[_delay_count] == visible_characters:
            # Stop the rendering
            # Rendering will be continued on _delay_timer_timeout()
            _characters_ticker.stop()
            _delay_timer.start(
                _current_dialogue_set\
                    [DialogueParser.Key.TAGS]\
                    [DialogueParser.Key.TAGS_DELAYS]\
                    [visible_characters]
            )
            return

    # {speed} tag
    if _speed_count < 0:
        if _speed_queue[_speed_count] == visible_characters:
            _characters_ticker.wait_time = _characters_draw_tick_scaled /\
                (1. if is_standalone else _current_stage.speed_scale_global) /\
                _current_dialogue_set\
                    [DialogueParser.Key.TAGS]\
                    [DialogueParser.Key.TAGS_SPEEDS]\
                    [visible_characters]
            _characters_ticker.start()
            _speed_count += 1

    # {jump} tag
    if _jump_count < 0:
        if _jump_queue[_jump_count] == visible_characters:
            visible_characters = _current_dialogue_set\
                [DialogueParser.Key.TAGS]\
                [DialogueParser.Key.TAGS_JUMP]\
                [visible_characters]
            _jump_count += 1
    #endregion

    visible_characters += 1

    # Positional function tag
    if _func_count < 0:
        if _func_queue[_func_count] == visible_characters:
            if _scope_handler.allow_func:
                for i : int in _current_dialogue_set\
                    [DialogueParser.Key.FUNC_POS]\
                    [visible_characters]:
                    _scope_handler._call_function(
                        _current_dialogue_set[DialogueParser.Key.FUNC][i]
                    )
            _func_count += 1

    if visible_ratio >= 1.:
        _characters_ticker.stop()
        _is_rendering = false
        text_rendered.emit()
        _characters_ticker.wait_time = _characters_draw_tick_scaled

    if not is_standalone:
        if _current_stage._step == -1:
            clear_render()

    character_drawn.emit()


func _delay_timer_timeout() -> void:
    _delay_count += 1
    _characters_ticker.start()

func _on_stage_skipped() -> void:
    var arr_size : int = _func_queue.size()
    for f in _func_queue.slice(arr_size - absi(_func_count), arr_size):
        for i : int in _current_dialogue_set[DialogueParser.Key.FUNC_POS][f]:
            _current_stage.scope_handler._call_function(
                _current_dialogue_set[DialogueParser.Key.FUNC][i]
            )
    text_rendered.emit()
#endregion
