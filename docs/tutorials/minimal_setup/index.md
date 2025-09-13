# Minimal Theatre Setup

This article cover the basic minimal setup for Theatre, like the one created in the [Quick Start](../../quickstart.md) article, but a lot more shorter and straightforward.

<hr>

1. Create a new `2D` or `User Interface` scene, and structure it like the following:

    <div class="grid cards" markdown>

    - ![Scene tree](scenetree.png){ .center }

    </div>

    The two highlighted nodes are the Theatre-specific nodes.

    Adjust the size and position of the [PanelContainer] to your liking.

    <br>

2. Tick the `fit_content` property on the [DialogueLabel].

    <div class="grid cards" markdown>

    - ![fit_content property](fit_content.png){ .center }

    </div>

    <br>

3. Attach a script to the scene and create a new [TheatreStage] object variable with `@export` annotation.

    ```gdscript hl_lines="3"
    extends Control

    @export var my_stage: TheatreStage

    ```

    <br>

4. Go to the inspector, and assign the [TheatreStage] node to the variable named `stage` in the script.

    <div class="grid cards" markdown>

    - ![](stage_node_1.png){ .center }

    - ![](stage_node_2.png){ .center }

    </div>

    <br>

5. Click the [TheatreStage] node, go to the inspector, and assign the [Label] to [`actor_label`](/class/theatrestage/references/#actor_label), and [DialogueLabel] to [`dialogue_label`](/class/theatrestage/references/#dialogue_label).

    <div class="grid cards" markdown>

    - ![Label and DialogueLabel node assigned on the TheatreStage inspector](stage_required_nodes.png){ .center }

    </div>

    <br>

6. Use input event to progress the [TheatreStage].

    ```gdscript hl_lines="5 6 7"
    extends Control

    @export var my_stage: TheatreStage

    func _input(event):
        if event.is_action_pressed("ui_accept"):
            my_stage.progress()
    ```

    <br>

7. You can then write/load your [Dialogue], and start it.

    ```gdscript hl_lines="3 11 12"
    extends Control

    var dlg: Dialogue # Load/create Dialogue here

    @export var my_stage: TheatreStage

    func _input(event):
        if event.is_action_pressed("ui_accept"):
            my_stage.progress()

    func _ready():
        my_stage.start(dlg)
    ```

   <br>

## Code summary

```
MyScene
  ├─ TheatreStage
  └─ PanelContainer
        └─ VBoxContainer
            ├─ Label
            └─ DialogueLabel
```

```gdscript
extends Control

var dlg: Dialogue # Load/create Dialogue here

@export var my_stage: TheatreStage

func _input(event):
    if event.is_action_pressed("ui_accept"):
        my_stage.progress()

func _ready():
    my_stage.start(dlg)
```

<br>

Got any questions? feel free to ask them in the [GitHub Discussions!](https://github.com/nndda/Theatre/discussions/new?category=help){ target="_blank" }