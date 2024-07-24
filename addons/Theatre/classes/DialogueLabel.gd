@icon("res://addons/Theatre/assets/icons/classes/message.svg")
@tool
class_name DialogueLabel
extends RichTextLabel

## Control node built for displaying [Dialogue].
##
## A [RichTextLabel] inherited node that are built for displaying and rendering [Dialogue] lines.
## [DialogueLabel] has a partial support for BBCode tags, as for now, the [code][img][/code] tag are not supported.
## [member RichTextLabel.bbcode_enabled] will always be [code]true[/code].

## Each string character will be drawn every [param characters_draw_tick] seconds
@export var characters_draw_tick : float = .015
var _characters_draw_tick_scaled : float

#region NOTE: Setup --------------------------------------------------------------------------------
var _current_stage : Stage:
    set = set_stage,
    get = get_stage

## Returns the [Stage] that is currently controling the [DialogueLabel].
func get_stage() -> Stage:
    return _current_stage

## Set the [Stage] that will be used to control the [DialogueLabel]. If there's already a [Stage]
## set, this will remove the previous [member Stage.dialogue_label].
## [br][br]
## [b]Note:[/b] [member Stage.dialogue_label] will be set automatically when you assign
## a [DialogueLabel] to the [Stage] on the inspector.
func set_stage(stage : Stage) -> void:
    if _current_stage != null:
        _current_stage.dialogue_label = null
    if stage != null:
        _current_stage = stage
        if !_current_stage.skipped.is_connected(_on_stage_skipped):
            _current_stage.skipped.connect(_on_stage_skipped)
    else:
        if _current_stage.skipped.is_connected(_on_stage_skipped):
            _current_stage.skipped.disconnect(_on_stage_skipped)
        _current_stage = null

func _validate_property(property: Dictionary) -> void:
    if property["name"] == "bbcode_enabled":
        bbcode_enabled = true
        property["usage"] = PROPERTY_USAGE_NO_EDITOR

func _enter_tree() -> void:
    if !Engine.is_editor_hint():
        _delay_timer = Timer.new()
        _characters_ticker = Timer.new()

        text = ""
        bbcode_enabled = true

        _delay_timer.autostart = false
        _delay_timer.one_shot = true
        _delay_timer.timeout.connect(_delay_timer_timeout)
        #call_deferred(&"add_child", _delay_timer)
        add_child(_delay_timer)

        _characters_ticker.autostart = false
        _characters_ticker.one_shot = false
        _characters_ticker.timeout.connect(_characters_ticker_timeout)
        #call_deferred(&"add_child", _characters_ticker)
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
var _speed_queue : PackedInt64Array = []
var _func_queue : PackedInt64Array = []

var _delay_timer : Timer
var _characters_ticker : Timer

## Start the rendering of the current [Dialogue] line text.
func start_render() -> void:
    _delay_timer.one_shot = true

    _characters_draw_tick_scaled = characters_draw_tick /\
        _current_stage.speed_scale_global / _current_stage.speed_scale
    _characters_ticker.start(_characters_draw_tick_scaled)

    _delay_queue = _current_stage._current_dialogue_set["tags"]["delays"].keys()
    _speed_queue = _current_stage._current_dialogue_set["tags"]["speeds"].keys()
    _func_queue = _current_stage._current_dialogue_set["func_pos"].keys()
    _is_rendering = true

## Stop the process of rendering text, and clear the [DialogueLabel] text.
func clear_render() -> void:
    _delay_timer.stop()
    _characters_ticker.stop()

    visible_ratio = 0

    _delay_queue.clear()
    _speed_queue.clear()
    _func_queue.clear()

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

func _characters_ticker_timeout() -> void:
    if !_func_queue.is_empty():
        if _func_queue[0] == visible_characters:
            if _current_stage.allow_func:
                _current_stage._call_functions(
                    _current_stage._current_dialogue_set["func"][
                        _current_stage._current_dialogue_set["func_pos"][_func_queue[0]]
                    ]
                )
            _func_queue.remove_at(0)

    if !_delay_queue.is_empty():
        if _delay_queue[0] == visible_characters:
            _characters_ticker.stop()
            _delay_timer.start(
                _current_stage._current_dialogue_set["tags"]["delays"][_delay_queue[0]]
            )
            return

    if !_speed_queue.is_empty():
        if _speed_queue[0] == visible_characters:
            _characters_ticker.wait_time = _characters_draw_tick_scaled /\
                _current_stage.speed_scale_global /\
                _current_stage._current_dialogue_set["tags"]["speeds"][_speed_queue[0]]
            _characters_ticker.start()
            _speed_queue.remove_at(0)

    visible_characters += 1

    if visible_ratio >= 1.0:
        _characters_ticker.stop()
        _is_rendering = false
        text_rendered.emit(text)
        _characters_ticker.wait_time = _characters_draw_tick_scaled

    if _current_stage._step == -1:
        clear_render()

    character_drawn.emit()

func _delay_timer_timeout() -> void:
    _delay_queue.remove_at(0)
    _characters_ticker.start()

func _on_stage_skipped() -> void:
    for f in _func_queue:
        _current_stage._call_functions(
            _current_stage._current_dialogue_set["func"][
                _current_stage._current_dialogue_set["func_pos"][f]
            ]
        )
    text_rendered.emit(text)
#endregion

func _exit_tree() -> void:
    if !Engine.is_editor_hint():
        _delay_queue.clear()
        _speed_queue.clear()
        _func_queue.clear()
