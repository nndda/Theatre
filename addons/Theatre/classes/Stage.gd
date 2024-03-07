class_name Stage
extends Object

# TODO: hamdle errors for required parameters

var allow_skip := true

var auto := false

var auto_delay : float = 1.5

var speed_scale

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
var body_label : DialogueLabel

var handler := {
    "STAGE" : self,
}

## Current progress of the Dialogue.
var step : int = -1

var variables : Dictionary = {}:
    set(new_var):
        variables = new_var
        if is_playing():
            update_display()

        if current_dialogue != null:
            var stepn := clampi(step, 0, current_dialogue.sets.size())
            # NOTE, BUG: NOT COMPATIBLE WHEN CHANGING VARIABLE REAL-TIME
            current_dialogue.sets[stepn]["line"] =\
            Dialogue.Parser.update_tags_position(
                current_dialogue, stepn, new_var
            )
    get:
        return variables

## [Stage] needs to be initialized in _ready() or with @onready when passing the parameters required.
## [codeblock]
##@onready var stage = Stage.new({
##    name_label = $Label,
##    body_label = $DialogueLabel
##})
## [/codeblock]
func _init(parameters : Dictionary):
    if !parameters.is_empty():
        if parameters.has("name_label"):
            assert(
                parameters["name_label"] is Label,
                "Object of type %s is used. Only use `Label` as \"name_label\""\
                % type_string(typeof(parameters["name_label"]))
            )
            if parameters["name_label"] is Label:
                name_label = parameters["name_label"]

        if parameters.has("body_label"):
            assert(
                parameters["body_label"] is DialogueLabel,
                "Object of type %s is used. Only use `DialogueLabel` as \"body_label\""
                % type_string(typeof(parameters["body_label"]))
            )
            if parameters["body_label"] is DialogueLabel:
                body_label = parameters["body_label"]
                body_label.current_stage = self

        if parameters.has("progress_speed"):
            speed_scale = parameters["progress_speed"]

        if parameters.has("allow_skip"):
            allow_skip = parameters["allow_skip"]

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
        if body_label.visible_ratio < 1.0:
            if allow_skip:
                body_label.visible_characters = current_dialogue_set["line"].length()

        # Progress dialogue
        else:
            if step + 1 < current_dialogue_length:
                step += 1
                body_label.visible_characters = 0
                current_dialogue_set = current_dialogue.sets[step]
                body_text_length = current_dialogue_set["line"].length()

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

                progressed.emit(step, current_dialogue_set)

            elif step + 1 >= current_dialogue_length:
                reset()
                finished.emit()

## Stop Dialogue and resets everything
func reset(keep_dialogue : bool = false) -> void:
    print_debug("Resetting Dialouge...")
    resetted.emit(step,
        current_dialogue.sets[step] if step != -1 else\
        {
            "actor" : "",
            "line" : "",
            "line_raw" : "",
            "func" : [],
            "delays" : {},
            "speeds" : {},
            "offets" : {},
        }
    )

    if !keep_dialogue:
        current_dialogue = null
    step = -1

    if name_label != null:
        name_label.text = ""
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

        progress()
        started.emit()

func update_display() -> void:
    if name_label != null:
        name_label.text = current_dialogue_set["actor"].format(variables)
    body_label.text = current_dialogue_set["line"].format(variables)
