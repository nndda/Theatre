class_name Stage
extends Object

# TODO: hamdle errors for required parameters

var allow_skip := true

var auto := false

var auto_delay := 1.5

## Run/play [Dialogue], define and reference UIs and Nodes that will be used to display the [Dialogue]. It takes a dictionary of elements of nodes as the constructor parameter.
## [codeblock]@onready var stage = Stage.new({
##    name_label = $Label,
##    body_label = $RichTextLabel
##})
##
##var epic_dialogue = Dialogue.new("res://epic_dialogue.txt")
##
##func _ready():
##    stage.start(epic_dialogue) [/codeblock]
## The parameters in the dictionary are as follows: [br]
## - [param "name_label"]. see [member name_label] [br]
## - [param "body_label"]. see [member body_label]

## Characters count of the dialogue body. The same as [member current_dialogue.sets.size()]
var body_text_length : int

## Maximum characters count to fit in the dialogue body. Running Dialogue with characters more than the specified number will throws out an error.
var body_text_limit : int = 500

## The current [Dialogue] resource that is being used
var current_dialogue : Dialogue
var current_dialogue_length : int
var current_dialogue_set : Dictionary

#var delay_timer := Timer.new()

## Optional [Label] node that displays [member Dialogue.set_current.name]. Usually used as the name of the narrator or the speaker of the current dialogue.
var name_label : Label

## [RichTextLabel] node that displays the dialogue body [member Dialogue.set_current.dlg]. This element is [b]required[/b] for the dialogue to run.
var body_label : RichTextLabel

var handler := {
    "STAGE" : self,
}

## [Tween] that will be played when progressing. see [member progress_tween_start], and [member progress_tween_reset].
var progress_tween : Tween

var progress_tween_speed_scale : float = 1.0

## [Callable] to be called to start the [member progress_tween] when the Dialogue progressed.
#var progress_tween_start : Callable = func(from_zero : bool = false):
    #progress_tween.tween_property(
            #body_label,
            #^"visible_characters",
            #body_text_length,
            #0.03 * body_text_length )\
        #.set_trans(Tween.TRANS_LINEAR)\
        #.set_ease(Tween.EASE_IN_OUT)\
        #.from(0 as int)

## [Callable] to be called to stop/reset the [member progress_tween] when the Dialogue progressed when the [member progress_tween] is still running.
#var progress_tween_reset : Callable = func():
    #body_label.visible_ratio = 1.0

## Progress of the Dialogue.
var step : int = -1

var variables : Dictionary = {}:
    set(new_var):
        variables = new_var
        if is_playing():
            update_display()
    get:
        return variables

## [Stage] needs to be initialized in _ready() or with @onready when passing the parameters required.
## [codeblock]
##@onready var stage = Stage.new({
##    name_label = $Label,
##    body_label = $RichTextLabel
##})
## [/codeblock]
func _init(parameters : Dictionary):
    if parameters.has("name_label"):
        name_label = parameters["name_label"]
    if parameters.has("progress_speed"):
        progress_tween_speed_scale = parameters["progress_speed"]

    if parameters.has("body_label"):
        body_label = parameters["body_label"]
        if body_label is DialogueLabel:
            body_label.current_stage = self

## Emitted when [Dialogue] started ([member step] == 0)
signal started
## Emitted when [Dialogue] finished ([member step] == [member step.size()])
signal finished
## Emitted when [Dialogue] progressed
signal progressed(step_n : int, set_n : Dictionary)
signal resetted(step_n : int, set_n : Dictionary)

func get_current_set() -> Dictionary:
    if current_dialogue != null and step >= 0:
        return current_dialogue.sets[step]
    return {}

func is_playing() -> bool:
    return step >= 0

## Progress the [Dialogue] by 1 step. If [member progress_tween] is still running, [member progress_tween.stop()] and [member progress_tween_reset] will be called, and the [Dialogue] will not progressed.
func progress() -> void:
    if current_dialogue != null:
        # Skip dialogue
        # BUG: it wont skip, itll just repeat the current set
        if (progress_tween.is_running() or
            body_label.visible_ratio < 1.0) and\
            allow_skip:

            #if current_dialogue_set["delays"].is_empty() or\
                #current_dialogue_set["delays"].keys().max() <=\
                #current_dialogue_set["body_raw"].length():

                #body_label.visible_ratio = 1.0
                #progress_tween.stop()

            if body_label.visible_ratio < 1.0 and body_label is DialogueLabel:
                if body_label.is_delayed:

                    body_label.is_delayed = false
                    body_label.delay_timer.stop()
                    body_label.visible_characters += 1
                    progress_tween = body_label.create_tween()
                    progress_tween.tween_property(
                            body_label,
                            ^"visible_characters",
                            body_text_length,
                            0.03 * body_text_length )\
                        .set_trans(Tween.TRANS_LINEAR)\
                        .set_ease(Tween.EASE_IN_OUT)\
                        .from(body_label.visible_characters)
                    progress_tween.play()

            elif body_label.visible_ratio < 1.0:
                body_label.visible_ratio = 1.0
                progress_tween.stop()

        # Progress dialogue
        else:
            if step + 1 < current_dialogue_length:
                step += 1
                current_dialogue_set = current_dialogue.sets[step]
                body_text_length = current_dialogue_set["body_raw"].length()

                if body_text_length > body_text_limit:
                    push_warning(
                        "Dialogue text length exceeded limit: %i/%i"
                        % [body_text_length, body_text_limit]
                    )

                update_display()

                # Calling functions
                for f : Dictionary in current_dialogue_set["func"]:
                    #if handler.has(f["handler"]):
                        print("\n", f["handler"], ",", f["func_name"])
                        for p in f["param"]:
                            print("  ", type_string(typeof(p)), ": ", p)

                # Playing Tween
                progress_tween = body_label.create_tween()
                progress_tween.tween_property(
                        body_label,
                        ^"visible_characters",
                        body_text_length,
                        0.03 * body_text_length )\
                    .set_trans(Tween.TRANS_LINEAR)\
                    .set_ease(Tween.EASE_IN_OUT)\
                    .from(int(0))
                progress_tween = progress_tween.set_speed_scale(
                    progress_tween_speed_scale
                )
                progress_tween.play()

                progressed.emit(step, current_dialogue_set)

            elif step + 1 >= current_dialogue_length:
                reset()
                finished.emit()

## Stop Dialogue and resets everything
func reset(keep_dialogue : bool = false) -> void:
    print_debug("Resetting Dialouge...")
    resetted.emit(step, current_dialogue.sets[step])

    if !keep_dialogue:
        current_dialogue = null
    step = -1

    if name_label != null:
        name_label.text = ""

    progress_tween.kill()
    body_label.text = ""

## Start the [Dialogue] at step 0 or at defined preprogress parameter.
## If no parameter (or null) is passed, it will run the [member current_dialogue] if present
func start(dialogue : Dialogue = null) -> void:
    print_debug("Starting Dialouge...")
    if dialogue != null:
        current_dialogue = dialogue

    if current_dialogue == null:
        push_error("Cannot start the Stage: `current_dialogue` is null")
    else:
        current_dialogue_length = current_dialogue.sets.size()
        progress_tween = body_label.create_tween()

        progress_tween.stop()
        body_label.visible_ratio = 1.0

        progress()
        started.emit()

func update_display() -> void:
    if name_label != null:
        name_label.text = current_dialogue_set["name"].format(variables)
    body_label.text = current_dialogue_set["body_raw"].format(variables)
