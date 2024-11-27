# Tutorials

Here are the various tutorial pages for Theatre. For guides on writing Dialogues, go to the [Dialogue Syntax page](../class/dialogue/syntax.md).

Unless otherwise specified, all tutorials here assume [_minimal Theatre setup_](minimal_setup/index.md):

```
MyScene
  ├─ Stage
  └─ PanelContainer
        └─ VBoxContainer
            ├─ Label
            └─ DialogueLabel
```

```gdscript
extends Control

var dlg : Dialogue # Load/create Dialogue here

@export var stage : Stage

func _input(event):
    if event.is_action_pressed("ui_accept"):
        stage.progress()

func _ready():
    stage.start(dlg)
```