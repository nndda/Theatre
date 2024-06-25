# Theatre

<img src="/addons/Theatre/assets/icons/Theatre.svg" height="160" align="right">

Text-based linear dialogue system for Godot 4.3.
- ✍️ Literally just a text file! Written in human-readable syntax & VCS-friendly.
- ✨ Focused on presentation and delivery of your story.
- 📝 100% written in GDScript.

> [!IMPORTANT]
> This project is currently in its alpha stage and is subject to frequent and breaking changes, and bugs.

<table align="center">
<tr align="center">
<td>
    <b> Rendered </b>
</td>
<td>
    <b> Written </b>
</td>
</tr>
<tr>
<td>

<img src="https://github.com/nndda/Theatre/assets/96333146/58d7c400-9aac-4ba3-971c-57d7b28cb7e3" width="364">

</td>
<td>
    
```
Dia:
    "Welcome! {d=0.8}to the
    [fx1]Theatre[/fx1]!
        d=0.9
    a text-based dialogue system
        d=0.3
    developed for Godot {gd_ver}
        d=0.8
    [fx3]
        (well,{d = 0.8} 4.3 specifically)
    [/fx3]."


    ＼(^ ▽ ^)
```

</td>
</tr>
</table>

# Features

## Dialogue tags

Fine-tune your dialogue flow with `{delay}` and `{speed}`.
```
Godette:
    "Hello!{delay = 0.7} nice to meet you"
```
```
Godette:
    "Hello!
        delay=0.7
    nice to meet you"
```

## Function calls

Connect your story to the game with function calls.
```
{player_name}:
    "Thanks! that feels so much better"

    Player.heal(20)
```
```
Ritsu:
    "Smile for the camera!"

    Portrait.change('res://ritsu_smile.png')
```

Call functions only at specific points in the Dialogue.
```
Dia:
    "Let me just...{d = 0.7}
    set the mood a little...{1.2}
    {0}there we go"

# Call this function using its index: {0}
    Environment.brightness(0.8)
```

# Quick Start

Write your epic Dialogue!
```gdscript
# write it directly with triple quotation marks
var epic_dialogue = Dialogue.new("""

Dia:
    "For performance reason, I'd recommend
    using the method below instead."

""")

# alternatively, write it in a *.dlg.txt or *.dlg  file, and load it
var epic_dialogue = Dialogue.load("res://epic_dialogue.dlg")
```

Set the Stage! Create a `Stage` node, and reference the `Label` & `DialogueLabel` node to display your Dialogue. Adjust and configure your `Stage` via the inspector. Alternatively, you can also set them in script:

<table align="center">
<tr align="center">
<td>
    <b> Inspector </b>
</td>
<td>
    <b> GDScript </b>
</td>
</tr>

<tr>
<td>

<img src="https://github.com/nndda/Theatre/assets/96333146/69d7b946-2444-4247-8cdf-394332466c99" width="260">

</td>
<td>

```gdscript
@onready var your_stage : Stage = $Stage

func _ready():
    your_stage.allow_skip = true
    your_stage.allow_cancel = true
    your_stage.allow_func = true
    your_stage.speed_scale = 1.0
```

</td>
</tr>

</table>

Reference the `Stage` node in the script, and set up a way to progress your Dialogue with `Stage.progress()`.

```gdscript
func _input(event):
    if event.is_action_pressed("ui_accept"):
        your_stage.progress()
```

And finally, start the Stage

```gdscript
func _ready():
    your_stage.start(epic_dialogue)
```

## License

- Theatre is licensed under [MIT](LICENSE).
- [Theatre logo](/addons/Theatre/assets/icons/Theatre.svg), created by [nnda](https://github.com/nndda), is licensed under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- [Class icons](addons/Theatre/assets/icons/classes), from [@fontawesome](https://fontawesome.com), are licensed under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/).
