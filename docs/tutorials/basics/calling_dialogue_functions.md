# Calling Dialogue Functions

```
Dia:
    "You can call functions from written Dialogues.
    Provided that there's the Object
    to call said functions: the caller."
:
    "Let's use a simple ColorRect node as a caller."
:
    "And we'll modify its properties
    using its various setter functions."
```

0. Add `ColorRect` node to the scene. Adjust its position and size to your liking.

    ``` hl_lines="7"
    MyScene
      ├─ Stage
      ├─ PanelContainer
      │     └─ VBoxContainer
      │         ├─ Label
      │         └─ DialogueLabel
      └─ ColorRect
    ```

    And reference it in the script.

    ```gdscript
    @onready var color_rect = $ColorRect
    ```

0. Register it as a caller in the `Stage`, using `add_caller()`.

    ```gdscript hl_lines="13"
    extends Control

    var dlg : Dialogue # Load/create Dialogue here

    @export var stage : Stage
    @onready var color_rect = $ColorRect

    func _input(event):
        if event.is_action_pressed("ui_accept"):
            stage.progress()

    func _ready():
        stage.add_caller("ColorRect", color_rect)
        stage.start(dlg)
    ```
    `add_caller()` requires 2 arguments:

    * The ID/name of the caller object to be used in the written Dialogue.
    * The object itself.

0. We are ready to call functions on our `ColorRect`. We'll append to the Dialogue above.

    ``` hl_lines="6"
    :
        "Now, I will turn this rectangle blue..."
    :
        "Ta-da~!"

        ColorRect.set_color("#0000FF")
    ```

## Code Summary

``` hl_lines="7"
MyScene
  ├─ Stage
  ├─ PanelContainer
  │     └─ VBoxContainer
  │         ├─ Label
  │         └─ DialogueLabel
  └─ ColorRect
```

```gdscript hl_lines="6 13"
extends Control

var dlg : Dialogue # Load/create Dialogue here

@export var stage : Stage
@onready var color_rect = $ColorRect

func _input(event):
    if event.is_action_pressed("ui_accept"):
        stage.progress()

func _ready():
    stage.add_caller("ColorRect", color_rect)
    stage.start(dlg)
```
