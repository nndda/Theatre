class_name DialogueLabel
extends RichTextLabel

var current_stage : Stage
var offset_queue : PackedInt32Array = []
var delay_queue : PackedInt32Array = []
var speed_queue : PackedInt32Array = []

var delay_timer := Timer.new()
var characters_ticker := Timer.new()

## Each string character will be drawn every `characters_draw_tick` seconds
@export var characters_draw_tick : float = .012

var characters_draw_tick_scaled : float

signal text_rendered(rendered_text : String)

func _enter_tree() -> void:
    for timer : Timer in [
        delay_timer,
        characters_ticker,
    ]:
        timer.autostart = false
        timer.one_shot = true
        add_child(timer)

    characters_ticker.one_shot = false
    characters_ticker.timeout.connect(characters_ticker_timeout)

func start_render() -> void:
    characters_draw_tick_scaled = characters_draw_tick /\
        Theatre.speed_scale / current_stage.speed_scale
    characters_ticker.start(characters_draw_tick_scaled)

    speed_queue = current_stage.current_dialogue_set["tags"]["speeds"].keys()
    delay_queue = current_stage.current_dialogue_set["tags"]["delays"].keys()
    offset_queue = current_stage.current_dialogue_set["offsets"].keys()

func rerender() -> void:
    visible_characters = 0
    delay_timer.stop()
    characters_ticker.stop()
    start_render()

func characters_ticker_timeout() -> void:
    if !delay_queue.is_empty():
        # TODO: Issue #12 ======================================================
        if delay_queue[0] == visible_characters:
            characters_ticker.stop()
            delay_timer.start(
                current_stage.current_dialogue_set["tags"]["delays"][delay_queue[0]]
            )
            await delay_timer.timeout
            characters_ticker.start()
            delay_queue.remove_at(0)

    if !speed_queue.is_empty():

        if speed_queue[0] == visible_characters:
            characters_ticker.wait_time = characters_draw_tick_scaled /\
                Theatre.speed_scale /\
                current_stage.current_dialogue_set["tags"]["speeds"][speed_queue[0]]
            characters_ticker.start()
            speed_queue.remove_at(0)

    visible_characters += 1

    if visible_ratio >= 1.0:
        characters_ticker.stop()
        text_rendered.emit(text)
        characters_ticker.wait_time = characters_draw_tick_scaled
