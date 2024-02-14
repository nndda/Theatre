class_name DialogueLabel
extends RichTextLabel

var current_stage : Stage
var delay_timer := Timer.new()

var is_delayed := false

func _ready() -> void:
    delay_timer.autostart = false
    delay_timer.one_shot = true
    add_child(delay_timer)
    delay_timer.timeout.connect(delay_timer_timeout)

func _process(_delta : float) -> void:
    if current_stage != null and current_stage.is_playing():
        for delay_pos : int in current_stage.current_dialogue_set["delays"].keys():
            if visible_characters < delay_pos:
                visible_characters += 1
                delay_timer.start(
                    current_stage.current_dialogue_set["delays"][delay_pos]
                )
                current_stage.progress_tween.pause()
                current_stage.progress_tween.kill()
                is_delayed = true

func delay_timer_timeout() -> void:
    if visible_ratio < 1.0:
        current_stage.progress_tween = create_tween()
        current_stage.progress_tween.tween_property(
                current_stage.body_label,
                ^"visible_characters",
                current_stage.body_text_length,
                0.03 * current_stage.body_text_length )\
            .set_trans(Tween.TRANS_LINEAR)\
            .set_ease(Tween.EASE_IN_OUT)\
            .from(visible_characters)
        current_stage.progress_tween.play()
        is_delayed = false
