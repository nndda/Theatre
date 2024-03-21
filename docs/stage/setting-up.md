# Setting up your Stage

For the `Dialogue` to run you'll need to create `Stage` and add a `DialogueLabel` node to your scene.

## Creating and configuring Stage

Create a stage object in your script's global scope with `@onready` keyword.

```gdscript
@onready stage = Stage.new({
    "dialogue_label": $DialogueLabel
}) 
```

Stage takes Dictionary as the constuctor parameter. Here's the overview of what options you can set:

- `actor_label`: An optional `Label` node to display the name of actor/speaker/narrator
- `dialogue_label`: A `DialogueLabel` node used to display the dialogue body. This is the only required parameter.
- `variables`: 
- `speed`: Set how fast the dialogue is rendered.

### Progressing

Before starting your dialogue you need to set how to progress your dialogue with `Stage.progress()`.

A common way is to progress with input event.

```
func _input(event):
    if event.is_action_pressed("ui_accept"):
        stage.progress()
```

