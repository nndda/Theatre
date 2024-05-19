class_name Stage
extends Object

var allow_skip := true

var allow_cancel := true

var allow_func := true

var auto := false

var auto_delay : float = 1.5

var speed_scale : float = 1.0:
    set(s):
        speed_scale = s
        if dialogue_label != null:
            dialogue_label.characters_draw_tick_scaled =\
                dialogue_label.characters_draw_tick / s
            dialogue_label.characters_ticker.wait_time =\
                dialogue_label.characters_draw_tick_scaled

## Run/play [Dialogue], define and reference UIs and Nodes that will be used to display the [Dialogue]. It takes a dictionary of elements of nodes as the constructor parameter.

## Characters count of the dialogue body. The same as [member current_dialogue.sets.size()]
var body_text_length : int

## Maximum characters count to fit in the dialogue body. Running Dialogue with characters more than the specified number will throws out an error.
var body_text_limit : int = 500

## The current [Dialogue] resource that is being used
var current_dialogue : Dialogue:
    set(new_var):
        current_dialogue = new_var
        if !variables.is_empty() and new_var != null:
            for n in current_dialogue.sets.size():
                Dialogue.Parser.update_tags_position(
                    current_dialogue, n, variables
                )

var current_dialogue_length : int
var current_dialogue_set : Dictionary

## Optional [Label] node that displays [member Dialogue.set_current.actor]. Usually used as the name of the character, narrator, or speaker of the current dialogue.
var actor_label : Label

var caller : Dictionary = {}

## [DialogueLabel] node that displays the dialogue body [member Dialogue.set_current.dlg]. This is [b]required[/b] for the dialogue to run
var dialogue_label : DialogueLabel

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
            Dialogue.Parser.update_tags_position(
                current_dialogue, stepn, new_var
            )
    get:
        return variables

## [Stage] needs to be initialized in _ready() or with @onready when passing the parameters required.
## [codeblock]
##@onready var stage = Stage.new({
##    actor_label = $Label,
##    dialogue_label = $DialogueLabel
##})
## [/codeblock]
func _init(parameters : Dictionary):
    if !parameters.is_empty():
        if parameters.has("actor_label"):
            assert(
                parameters["actor_label"] is Label,
                "Object of type '%s' is used. Only use `Label` as 'actor_label'"
                % type_string(typeof(parameters["actor_label"]))
            )
            if parameters["actor_label"] is Label:
                actor_label = parameters["actor_label"]

        if parameters.has("dialogue_label"):
            assert(
                parameters["dialogue_label"] is DialogueLabel,
                "Object of type '%s' is used. Only use `DialogueLabel` as 'dialogue_label'"
                % type_string(typeof(parameters["dialogue_label"]))
            )
            if parameters["dialogue_label"] is DialogueLabel:
                dialogue_label = parameters["dialogue_label"]
                dialogue_label.current_stage = self

        var constructor_property : PackedStringArray = [
            "allow_skip",
            "allow_cancel",
            "allow_func",
            "auto",
            "auto_delay",
            "speed_scale",
            "body_text_limit",
        ]
        for property in parameters.keys():
            if !["actor_label", "dialogue_label"].has(property):
                if property in self and constructor_property.has(property):
                    set(StringName(property), parameters[property])
                else:
                    push_error("Error constructing Stage, `%s` does not exists" % property)

## Emitted when [Dialogue] started ([member step] == 0)
signal started
## Emitted when [Dialogue] finished ([member step] == [member step.size()])
signal finished
## Emitted when [Dialogue] progressed
signal progressed(step_n : int, set_n : Dictionary)
signal resetted(step_n : int, set_n : Dictionary)
signal locale_changed(lang : String)

func get_current_set() -> Dictionary:
    if current_dialogue != null and step >= 0:
        return current_dialogue.sets[step]
    return {}

func is_playing() -> bool:
    return step >= 0

## Progress the [Dialogue] by 1 step.
func progress(skip_render : bool = false) -> void:
    if current_dialogue == null:
        push_warning("Failed to progress Stage: no Dialogue present")
    else:
        # Skip dialogue
        if dialogue_label.visible_ratio < 1.0 and !skip_render:
            if allow_skip:
                dialogue_label.clear_render()
                dialogue_label.visible_ratio = 1.0

        # Progress dialogue
        else:
            if step + 1 < current_dialogue_length:
                dialogue_label.clear_render()

                step += 1
                current_dialogue_set = current_dialogue.sets[step]
                body_text_length = current_dialogue_set["line"].length()

                if body_text_length > body_text_limit:
                    push_warning(
                        "Dialogue text length exceeded limit: %i/%i"
                        % [body_text_length, body_text_limit]
                    )

                if OS.is_debug_build():
                    var unused_vars := ""
                    var def_vars = variables.keys()

                    for i in current_dialogue_set["vars"]:
                        if !(i in def_vars):
                            unused_vars += i + ", "

                    if !unused_vars.is_empty():
                        push_warning("Warning: @%s:%d - unused variables: %s" % [
                            current_dialogue.source_path, current_dialogue_set["line_num"],
                            unused_vars
                        ])

                update_display()

                # Calling functions
                if allow_func:
                    for f : Dictionary in current_dialogue_set["func"]:
                        print("Calling function: %s.%s()" % [
                            f["name"], f["caller"]
                        ])
                        if !caller.has(f["caller"]):
                            printerr("Error @%s:%d - caller '%s' doesn't exists" % [
                                current_dialogue.source_path, f["ln_num"],
                                f["caller"],
                            ])
                        else:
                            if !caller[f["caller"]].has_method(f["name"]):
                                printerr("Error @%s:%d - function '%s.%s()' doesn't exists" % [
                                    current_dialogue.source_path, f["ln_num"],
                                    f["name"], f["caller"]
                                ])
                            else:
                                caller[f["caller"]].callv(f["name"], f["args"])

                dialogue_label.start_render()
                progressed.emit(step, current_dialogue_set)

            elif step + 1 >= current_dialogue_length:
                reset()
                finished.emit()

## Stop Dialogue and resets everything
func reset() -> void:
    if !allow_cancel:
        print("Resetting Dialogue is not allowed")
    else:
        if current_dialogue != null:
            print("Resetting Dialogue: %s..." % current_dialogue.source_path)
            resetted.emit(step,
                current_dialogue.sets[step] if step != -1 else\
                Dialogue.Parser.SETS_TEMPLATE
            )

            step = -1

            if actor_label != null:
                actor_label.text = ""

            dialogue_label.clear_render()
            dialogue_label.text = ""

            current_dialogue = null

## Start the [Dialogue] at step 0 or at defined preprogress parameter.
## If no parameter (or null) is passed, it will run the [member current_dialogue] if present
func start(dialogue : Dialogue = null) -> void:
    if is_playing():
        push_warning("Theres already a running Dialogue!")
    else:
        if dialogue != null:
            current_dialogue = dialogue

        if current_dialogue == null:
            push_error("Cannot start the Stage: `current_dialogue` is null")
        else:
            print("Starting Dialogue: %s..." % current_dialogue.source_path)
            current_dialogue_length = current_dialogue.sets.size()

            progress()
            started.emit()

# TODO
func switch_lang(lang : String = "") -> void:
    if current_dialogue == null:
        push_error("Failed switching lang: current_dialogue is null")
    else:
        if current_dialogue.source_path == "":
            push_error("Failed switching lang: no Dialogue source_path")
        else:
            var regex_lang := RegEx.new()
            regex_lang.compile(r"\.\w{2,4}\.txt$")
            var src := current_dialogue.source_path
            var ext := "" if lang == "" or lang == Theatre.default_lang\
                else ("." + lang)

            # TODO: mybe `default_lang` is not necessary.
            # Make `default_lang` as an alias

            if regex_lang.search(src) == null: # is using default lang
                src = src.insert(src.rfind(".txt"), ext)
            else:
                src = src.replace(
                    regex_lang.search(src).strings[0], ext + ".txt"
                )

            if !FileAccess.file_exists(src):
                push_error("Failed switching lang: %s does not exists" % src)
            else:
                var dlg_tr := Dialogue.load(src)
                if dlg_tr.sets.size() != current_dialogue.sets.size():
                    push_error("Failed switching lang: Dialogue length does not match")
                else:
                    current_dialogue = dlg_tr
                    locale_changed.emit(lang)
                    if is_playing():
                        current_dialogue_set = current_dialogue.sets[step]
                        update_display()
                        dialogue_label.rerender()

func add_caller(id : String, node : Node) -> void:
    caller[id] = node
    node.tree_exited.connect(remove_caller.bind(id))

func remove_caller(id : String) -> void:
    caller.erase(id)

func set_variable(name : String, value) -> void:
    variables[name] = value

func merge_variables(values : Dictionary) -> void:
    variables.merge(values, true)

func update_display() -> void:
    if actor_label != null:
        actor_label.text = current_dialogue_set["actor"].format(variables)
    dialogue_label.text = current_dialogue_set["line"].format(variables)
