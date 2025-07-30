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

## Each string character will be drawn every [param characters_draw_tick] seconds
@export var characters_draw_tick : float = .015
var _characters_draw_tick_scaled : float

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
    # NOTE: ????????
    #if _current_stage != null:
        #_current_stage.dialogue_label = null
    if stage != null:
        _current_stage = stage
        if !_current_stage.skipped.is_connected(_on_stage_skipped):
            _current_stage.skipped.connect(_on_stage_skipped)
    else:
        if _current_stage.skipped.is_connected(_on_stage_skipped):
            _current_stage.skipped.disconnect(_on_stage_skipped)
        _current_stage = null

func _validate_property(property: Dictionary) -> void:
    # Hide and set bbcode_enabled to true.
    if property["name"] == "bbcode_enabled":
        bbcode_enabled = true
        property["usage"] = PROPERTY_USAGE_NO_EDITOR

func _enter_tree() -> void:
    visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING

    if !Engine.is_editor_hint():
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
#endregion

#region NOTE: Signals ------------------------------------------------------------------------------
## Emitted when the text or the [Dialogue] line has finished rendering.
signal text_rendered(rendered_text : String)

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
        if _current_stage != null:
            _current_stage

var _delay_queue : PackedInt64Array = []
var _delay_count : int = 0
var _speed_queue : PackedInt64Array = []
var _speed_count : int = 0
var _func_queue : PackedInt64Array = []
var _func_count : int = 0

var _delay_timer : Timer
var _characters_ticker : Timer

var _current_dialogue_set : Dictionary = {}

## Start the rendering of the current [Dialogue] line text.
func start_render() -> void:
    _current_dialogue_set = _current_stage._current_dialogue_set

    _delay_timer.one_shot = true

    _characters_draw_tick_scaled = characters_draw_tick /\
        _current_stage.speed_scale_global / _current_stage.speed_scale
    _characters_ticker.start(_characters_draw_tick_scaled)

    # Set & count Dialogue tags queues
    _delay_queue = _current_dialogue_set[DialogueParser.Key.TAGS][DialogueParser.Key.TAGS_DELAYS].keys()
    _delay_count = -_delay_queue.size()
    _speed_queue = _current_dialogue_set[DialogueParser.Key.TAGS][DialogueParser.Key.TAGS_SPEEDS].keys()
    _speed_count = -_speed_queue.size()
    _func_queue = _current_dialogue_set[DialogueParser.Key.FUNC_POS].keys()
    _func_count = -_func_queue.size()

    _is_rendering = true

## Stop the process of rendering text, and clear the [DialogueLabel] text.
func clear_render() -> void:
    _delay_timer.stop()
    _characters_ticker.stop()

    visible_ratio = 0

    _delay_queue.clear()
    _delay_count = 0
    _speed_queue.clear()
    _speed_count = 0
    _func_queue.clear()
    _func_count = 0

    _is_rendering = false

    _current_dialogue_set = {}

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

func _characters_ticker_timeout() -> void:
    #region Handle Dialogue tags
    # {delay} tag
    if _delay_count < 0:
        if _delay_queue[_delay_count] == visible_characters:
            # Stop the rendering
            # Rendering will be continued on _delay_timer_timeout()
            _characters_ticker.stop()
            _delay_timer.start(
                _current_dialogue_set[DialogueParser.Key.TAGS][DialogueParser.Key.TAGS_DELAYS][visible_characters]
            )
            return

    # {speed} tag
    if _speed_count < 0:
        if _speed_queue[_speed_count] == visible_characters:
            _characters_ticker.wait_time = _characters_draw_tick_scaled /\
                _current_stage.speed_scale_global /\
                _current_dialogue_set[DialogueParser.Key.TAGS][DialogueParser.Key.TAGS_SPEEDS][visible_characters]
            _characters_ticker.start()
            _speed_count += 1
    #endregion

    visible_characters += 1

    # Positional function tag
    if _func_count < 0:
        if _func_queue[_func_count] == visible_characters:
            if _current_stage.allow_func:
                for i : int in _current_dialogue_set[DialogueParser.Key.FUNC_POS][visible_characters]:
                    _current_stage._call_function(
                        _current_dialogue_set[DialogueParser.Key.FUNC][i]
                    )
            _func_count += 1

    if visible_ratio >= 1.0:
        _characters_ticker.stop()
        _is_rendering = false
        text_rendered.emit(text)
        _characters_ticker.wait_time = _characters_draw_tick_scaled

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
            _current_stage._call_function(
                _current_dialogue_set[DialogueParser.Key.FUNC][i]
            )
    text_rendered.emit(text)
#endregion
