class_name DialogueLabel
extends RichTextLabel

var current_stage : Stage
var offset_queue : Array = []
var delay_queue : Array = []
var delay_timer := Timer.new()
var characters_ticker := Timer.new()

#var formatted_offset : int = 0

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
            #formatted_offset = current_stage.current_dialogue_set["line"].length() -  text.length()

            characters_ticker.start(.009)
            delay_queue = current_stage.current_dialogue_set["delays"].keys()
            offset_queue = current_stage.current_dialogue_set["offsets"].keys()

func characters_ticker_timeout() -> void:
    visible_characters += 1

    if !delay_queue.is_empty():
        var stop : int = 0
        var delay : float = 0
        # TODO: Issue #12 ======================================================
        stop = delay_queue[0]
        delay = current_stage.current_dialogue_set["delays"][delay_queue[0]]

        if !offset_queue.is_empty():
            if delay_queue[0] > offset_queue[0]:
                stop = delay_queue[0]# + formatted_offset

        if stop == visible_characters:
            #if stop == delay_queue[0] + formatted_offset:
                #offset_queue.remove_at(0)

        # ======================================================================

            characters_ticker.stop()
            print(stop, ", ", delay)
            await get_tree().create_timer(delay).timeout
            characters_ticker.start()
            delay_queue.remove_at(0)

    if visible_ratio >= 1.0:
        characters_ticker.stop()

func delay_timer_timeout() -> void:
    pass
