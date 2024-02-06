class_name Stage extends Object

## Define and reference UIs and Nodes that will be used by the [Dialogue]. It takes a dictionary of elements of nodes as the constructor parameter.
## [codeblock]@onready var stage = Stage.new({
##    container_name = $Label,
##    container_body = $RichTextLabel
##})
##
##var epic_dialogue = Dialogue.new("res://epic_dialogue.en.dlg.txt")
##
##func _ready():
##    stage.start(epic_dialogue) [/codeblock]
## The parameters in the dictionary are as follows: [br]
## - [param "container_name"]. see [member container_name] [br]
## - [param "container_body"]. see [member container_body]

## The current [Dialogue] resource that is being used
var current_dialogue : Dialogue

## Optional [Label] node that displays [member Dialogue.set_current.name]. Usually used as the name of the narrator or the speaker of the current dialogue.
var container_name : Label

## [RichTextLabel] node that displays the dialogue body [member Dialogue.set_current.dlg]. This element is [b]required[/b] for the dialogue to run.
var container_body : RichTextLabel

## Characters count of the dialogue body. The same as [member current_dialogue.sets.size()]
var body_text_length : int

## Maximum characters count to fit in the dialogue body. Running Dialogue with characters more than the specified number will throws out an error.
var body_text_limit : int = 500

## Progress of the Dialogue.
var step : int = -1

## [Tween] that will be played when progressing. see [member progress_tween_start], and [member progress_tween_stop].
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
var progress_tween_stop : Callable = func():
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
## Emitted when [Dialogue] stopped by [method stop]
signal stopped
## Emitted when [Dialogue] progressed
signal progressed(step_n : int, set_n : Dictionary)

## Start the [Dialogue] at step 0 or at defined preprogress parameter
func start(dialogue : Dialogue) -> void:
    current_dialogue = dialogue
    progress_tween = container_body.create_tween()
    progress()
    started.emit()

func stop() -> void:
    current_dialogue = null
    step = -1
    container_name.text = ""
    container_body.text = ""
    stopped.emit()

## Progress the [Dialogue] by 1 step. If [member progress_tween] is still running, [member progress_tween.stop()] and [member progress_tween_stop] will be called.
func progress() -> void:
    if progress_tween.is_running():
        progress_tween.stop()
        progress_tween_stop.call()
    else:
        var current_dialogue_size := current_dialogue.sets.size()

        if step + 1 >= current_dialogue_size:
            stop()
        elif step + 1 < current_dialogue_size:
            step += 1
            var sets := current_dialogue.sets[step]
            var body : String = sets["body"]
            body_text_length = body.length()

            if body_text_length > body_text_limit:
                push_error("Dialogue text length exceeded limit: %i/%i" % [body_text_length, body_text_limit])

            if container_name != null:
                container_name.text = sets["name"]

            container_body.text = sets["body"]
            progress_tween.play()
            progress_tween_start.call()
            progressed.emit(step, sets)
