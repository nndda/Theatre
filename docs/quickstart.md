# Quick Start

You've installed the plugin [(or have you?)](installation.md "Installing the plugin."). You had the characters, plot, and the worldbuilding of your story ready, or maybe not, thats ok too.
Lets start by writing a `Dialogue`.

## Writing the Dialogue

Create a new text file in your project. And write your dialogue with the following syntax:

```
Actor's name:
    "The Dialogue syntax are designed to be human readable,
    similar other data formats like YAML."

Actor's name:
    "You just need the character or actor's name,
    with `:` at the end."

Actor's name:
    "And the dialogue body indented."

Actor's name:
    The quotation marks are also entirely optional,
    everything you wrote is displayed as is.

```

You can save it as `*.dlg` or `*.dlg.txt`. In this example, we'll save the file as `res://intro.dlg`. Now that the `Dialogue` is ready, lets set up the `Stage`.

[**More on writing Dialogue here.**](class/dialogue/syntax.md){ .md-button }

## Setting up the Stage

Create a new 2D scene. And add `Stage`, `Label`, and `DialogueLabel` node. To tidy things up a little, we'll put those two `Control` node inside a `PanelContainer`. Resize the `PanelContainer` to your liking.

Here's what the current scene should looks like:

```
YourScene
  ├─ Stage
  └─ PanelContainer
      ├─ Label
      └─ DialogueLabel
```

Attach a script to your scene's root. And create a variable with `@onready` keyword to reference your `Stage` node made previously. In this example, we'll name the variable `'your_stage'`.

```gdscript
@onready var your_stage : Stage = $Stage
```

Click your `Stage` node, and head over to the inspector dock. Reference the `Label` and `DialogueLabel` node that were made before.

[**More on configuring Stage here.**](class/stage/configuration.md){ .md-button }

### Starting

Now, we'll create another variable to store the Dialogue. Use `Dialogue.load()` and pass the path of the written dialogue file:
```gdscript
var epic_dialogue = Dialogue.load('res://intro.dlg')
```

Call `start()` method on your Stage to start the Dialogue:
```gdscript
func _ready():
    your_stage.start(epic_dialogue)
```

Now the Dialogue will start when you play the scene. But we're not done here yet!

### Progressing

Progress the `Dialogue` with `progress()`. In this example, we'll use `_input(event)` with Godot's default action key `'ui_accept'` (space/enter key).

```gdscript
func _input(event):
    if event.is_action_pressed('ui_accept'):
        your_stage.progress()
```

Now, everytime `'ui_accept'` key is pressed, the Dialogue should progress.

## Additional stuff

### Toggling the UI

You might want to only show the UI when theres a Dialogue running, and hide it when the Dialogue ends.

`Stage` class is also equipped with signals such as `started`, `finished`, and `cancelled`. We'll connect these signals in `_ready()` before starting the Dialogue. And just call the method `show` and `hide` on the parents UI node `$PanelContainer`:

```gdscript
func _ready():

    stage.started.connect(
        $PanelContainer.show
    )

    stage.finished.connect(
        $PanelContainer.hide
    )

    stage.cancelled.connect(
        $PanelContainer.hide
    )

    stage.start(epic_dialogue)
```

Alternatively, you can connect these signals via the `Node` dock window. In this example, we only used `show` and `hide` method for simplicity. You can use `AnimationPlayer` or `Tween` for more fancy transitions.

## Summary

And, thats it!

Here is the finalized script of the scene:
```gdscript
extends Node2D

var epic_dialogue = Dialogue.load('res://intro.dlg')

func _input(event):
    if event.is_action_pressed('ui_accept'):
        your_stage.progress()

func _ready():
    stage.started.connect(
        $PanelContainer.show
    )

    stage.finished.connect(
        $PanelContainer.hide
    )

    stage.cancelled.connect(
        $PanelContainer.hide
    )

    your_stage.start(epic_dialogue)

```

## Next step

* More about writing your `Dialogue` on [Dialogue Syntax](class/dialogue/syntax.md).
* Configure your `Stage` on [Configuring Stage](class/stage/configuration.md).