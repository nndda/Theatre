# Setting up your Stage

For the `Dialogue` to run you'll need to create `Stage` and add a `DialogueLabel` node to your scene.

## Creating and configuring Stage

Create a stage object in your script's global scope with `@onready` keyword.

```gdscript
@onready stage = Stage.new({
    'dialogue_label': $DialogueLabel
}) 
```

Stage takes `Dictionary` as the constuctor parameter. Here's the overview of what options you can set:

| Property          | Description                      |
| ----------------- | -------------------------------- |
| `dialogue_label`{ title="DialogueLabel. Default: null" } | A `DialogueLabel` node used to display the dialogue body. This is the only required parameter.|
| `actor_label`{ title="Label. Default: null" } | An optional `Label` node to display the name of actor/speaker/narrator.|
| `speed_scale`{ title="float. Default: 1.0" } | The speed scale in `float`, of how fast the dialogue is rendered.|
| `allow_skip`{ title="bool. Default: true" } | Allow skipping `DialogueLabel` render.|
| `allow_cancel`{ title="bool. Default: true" } | Allow cancelling the current running `Dialogue` with `Stage.reset()`.|
| `allow_func`{ title="bool. Default: true" } | Allow function calls from `Dialogue`.|

!!! note
    These options are also properties that you can set and modify after creating the Stage.
    ```gdscript
    stage.speed -= .5
    stage.allow_cancel = true
    stage.allow_func = false
    ```

## Controlling the Stage

### Progressing

Before starting your dialogue you need to set how to progress your dialogue with `Stage.progress()`.

One common way is to progress with input event: eg. a press of a button, or a mouse click.

```gdscript
func _input(event):
    if event.is_action_pressed('ui_accept'):
        stage.progress()
```

### Starting

You can then use `Stage.start()` and pass the Dialogue as the parameter.

```gdscript
var dlg = Dialogue.load('res://convo.dlg.txt')

func _ready():
    stage.start(dlg)
```

## Cancelling

Sometimes, you might want to end the Dialogue even before its over. You can use `Stage.reset()`. You'll have to set `allow_cancel` to `true` for it to works.

Just like progressing, 
```
func _input(event):
    if event.is_action_pressed('ui_accept'):
        stage.progress()

    elif event.is_action_pressed('ui_cancel'):
        stage.reset()
```