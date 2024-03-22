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

signal text_rendered

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
    delay_timer.timeout.connect(delay_timer_timeout)

func _process(_delta : float) -> void:
    # TODO: trigger on Stage signals instead
    if current_stage != null and current_stage.is_playing():
        if visible_characters == 0:
            visible_characters += 1

            characters_ticker.start(characters_draw_tick)
            speed_queue = current_stage.current_dialogue_set["tags"]["speeds"].keys()
            delay_queue = current_stage.current_dialogue_set["tags"]["delays"].keys()
            offset_queue = current_stage.current_dialogue_set["offsets"].keys()

func characters_ticker_timeout() -> void:
    visible_characters += 1

    if !delay_queue.is_empty():
        # TODO: Issue #12 ======================================================
        var stop : int = delay_queue[0]
        var delay : float = current_stage.current_dialogue_set["tags"]["delays"][delay_queue[0]]

        if stop == visible_characters:
            characters_ticker.stop()
            #print(stop, ", ", delay)
            await get_tree().create_timer(delay).timeout
            characters_ticker.start()
            delay_queue.remove_at(0)

    if !speed_queue.is_empty():
        var stop : int = speed_queue[0]
        var speed : float = current_stage.current_dialogue_set["tags"]["speeds"][stop]

        if stop == visible_characters:
            #print(stop, ", ", speed)
            characters_ticker.wait_time = characters_draw_tick / speed
            characters_ticker.start()
            speed_queue.remove_at(0)

    if visible_ratio >= 1.0:
        characters_ticker.stop()
        text_rendered.emit()
        characters_ticker.wait_time = characters_draw_tick

func delay_timer_timeout() -> void:
    pass
