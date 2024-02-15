class_name DialogueLabel
extends RichTextLabel

var current_stage : Stage
var delay_queue : Array = []
var delay_timer := Timer.new()
var characters_ticker := Timer.new()

var is_delayed := false

func _ready() -> void:
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
    if current_stage != null and current_stage.is_playing():
        if visible_characters == 0:
            visible_characters += 1
            characters_ticker.start(.009)
            delay_queue = current_stage.current_dialogue_set["delays"].keys()

func characters_ticker_timeout() -> void:
    visible_characters += 1

    if !delay_queue.is_empty():
        if delay_queue[0] == visible_characters:
            characters_ticker.stop()
            await get_tree().create_timer(
                current_stage.current_dialogue_set["delays"][delay_queue[0]]
            ).timeout
            characters_ticker.start()
            delay_queue.remove_at(0)

    if visible_ratio >= 1.0:
        characters_ticker.stop()

func delay_timer_timeout() -> void:
    pass
