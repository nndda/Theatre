class_name Stage extends Object

## Run/play [Dialogue], and define and reference UIs and Nodes that will be used by the [Dialogue]. It takes a dictionary of elements of nodes as the constructor parameter.
## [codeblock]@onready var stage = Stage.new({
##    container_name = $Label,
##    container_body = $RichTextLabel
##})
##
##var epic_dialogue = Dialogue.new("res://epic_dialogue.txt")
##
##func _ready():
##    stage.start(epic_dialogue) [/codeblock]
## The parameters in the dictionary are as follows: [br]
## - [param "container_name"]. see [member container_name] [br]
## - [param "container_body"]. see [member container_body]

## Characters count of the dialogue body. The same as [member current_dialogue.sets.size()]
var body_text_length : int

## Maximum characters count to fit in the dialogue body. Running Dialogue with characters more than the specified number will throws out an error.
var body_text_limit : int = 500

var characters : Dictionary = {}

## The current [Dialogue] resource that is being used
var current_dialogue : Dialogue
var current_dialogue_length : int
var current_dialogue_set : Dictionary

## Optional [Label] node that displays [member Dialogue.set_current.name]. Usually used as the name of the narrator or the speaker of the current dialogue.
var container_name : Label

## [RichTextLabel] node that displays the dialogue body [member Dialogue.set_current.dlg]. This element is [b]required[/b] for the dialogue to run.
var container_body : RichTextLabel

## Progress of the Dialogue.
var step : int = -1

## [Tween] that will be played when progressing. see [member progress_tween_start], and [member progress_tween_reset].
var progress_tween : Tween

## [Callable] to be called to start the [member progress_tween] when the Dialogue progressed.
var progress_tween_start : Callable = func():
    progress_tween.tween_property(
            container_body,
            ^"visible_characters",
            body_text_length,
            0.025 * body_text_length )\
        .set_trans(Tween.TRANS_LINEAR)\
        .set_ease(Tween.EASE_IN_OUT)\
        .from(0 as int)

## [Callable] to be called to stop/reset the [member progress_tween] when the Dialogue progressed when the [member progress_tween] is still running.
var progress_tween_reset : Callable = func():
    container_body.visible_ratio = 1.0

## [Stage] needs to be initialized in _ready() or with @onready when passing the parameters required.
## [codeblock]
##@onready var stage = Stage.new({
##    container_name = $Label,
##    container_body = $RichTextLabel
##})
## [/codeblock]
func _init(parameters : Dictionary):
    if parameters.has("container_name"):
        container_name = parameters["container_name"]
    container_body = parameters["container_body"]

## Emitted when [Dialogue] started ([member step] == 0)
signal started
## Emitted when [Dialogue] finished ([member step] == [member step.size()])
signal finished
## Emitted when [Dialogue] progressed
signal progressed(step_n : int, set_n : Dictionary)
signal resetted(step_n : int, set_n : Dictionary)

## Start the [Dialogue] at step 0 or at defined preprogress parameter.
## If no parameter (or null) is passed, it will run the [member current_dialogue] if present
func start(dialogue : Dialogue = null) -> void:
    if dialogue != null:
        current_dialogue = dialogue
    current_dialogue_length = current_dialogue.sets.size()
    progress_tween = container_body.create_tween()
    progress()
    started.emit()
    resetted.emit(step, current_dialogue.sets[step])

## Stop Dialogue and resets everything
func reset(keep_dialogue : bool = false) -> void:
    if !keep_dialogue:
        current_dialogue = null
    step = -1

    if container_name != null:
        container_name.text = ""

    container_body.text = ""

## Progress the [Dialogue] by 1 step. If [member progress_tween] is still running, [member progress_tween.stop()] and [member progress_tween_reset] will be called, and the [Dialogue] will not progressed.
func progress() -> void:
    if current_dialogue != null:
        if progress_tween.is_running():
            progress_tween.stop()
            progress_tween_reset.call()
        else:
            if step + 1 >= current_dialogue_length:
                reset()
                finished.emit()
            elif step + 1 < current_dialogue_length:
                step += 1
                current_dialogue_set = current_dialogue.sets[step]
                body_text_length = current_dialogue_set["body"].length()

                if body_text_length > body_text_limit:
                    push_error("Dialogue text length exceeded limit: %i/%i" % [body_text_length, body_text_limit])

                if container_name != null:
                    container_name.text = current_dialogue_set["name"]

                container_body.text = current_dialogue_set["body"]
                progress_tween.play()
                progress_tween_start.call()
                progressed.emit(step, current_dialogue_set)

func is_playing() -> bool:
    return step >= 0
