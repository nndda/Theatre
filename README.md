<h1>Theatre</h1>

<img src="/addons/Theatre/assets/icons/Theatre.svg" alt="Theatre logo" height="160" align="right">

<a href="https://godotengine.org/">
<img src="https://img.shields.io/badge/4.4-white?style=flat-square&logo=godotengine&logoColor=white&label=Godot&labelColor=%232f5069&color=%233e4c57" alt="Godot 4.3" height="20"></a>
<a href="https://github.com/nndda/Theatre/actions/workflows/dialogue-test.yml">
<img src="https://img.shields.io/github/actions/workflow/status/nndda/Theatre/dialogue-test.yml?branch=main&event=push&style=flat-square&logo=github&label=CI&labelColor=%23252b30&color=%23306b3d" alt="Build status" height="20"></a>
<a href="https://nndda.github.io/Theatre/">
<img src="https://img.shields.io/website?style=flat-square&logo=github&label=Docs&labelColor=%23252b30&color=%23306b3d&up_message=online&url=http%3A//nndda.github.io/Theatre" alt="Documentation build" height="20"></a>

Yet another <sub>(linear)</sub> dialogue system<b>/</b>addon<b>/</b>plugin for Godot. With features such as:

- ✍️ Human-readable syntax.
- ⚡ Simple setup. Get started in just 7 lines of codes!
- 😐 ....
- 📝 And 100% written in GDScript!

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

<img src="https://github.com/user-attachments/assets/5bbefeed-61bb-4b9d-89a0-69d8300a3c08" alt="Theatre in action" width="368">

</td>
<td>

```yaml
Dia:
    "Welcome! {d=0.8}to the
    [fx1]Theatre[/fx1]!
        d=0.9
    yet another text-based
    dialogue addon
        d=0.3
    developed for Godot {gd_ver}."


    ＼(^ ▽ ^)
```

</td>
</tr>

<tr>
<td colspan="2">
    <b>GDScript</b>
</td>
</tr>

<tr>
<td colspan="2">

```gdscript
var epic_dialogue := Dialogue.load('res://epic_dialogue.dlg')

@export var my_stage: TheatreStage

func _ready():
    my_stage.start(epic_dialogue)

func _input(event):
    if event.is_action_pressed('ui_accept'):
        my_stage.progress()
```

</td>
</tr>

</table>


<br>

> [!IMPORTANT]
> This project is still in development and is subject to frequent breaking changes, and bugs. Check out the [Issues](https://github.com/nndda/Theatre/issues) page for known bugs &amp; issues, and [Common Troubleshooting](https://nndda.github.io/Theatre/tutorials/troubleshooting/) documentation page if you encounter any issues.

<br>

# Features

## Dialogue Tags

Fine-tune your dialogue flow with `{delay}` and `{speed}`.
```yaml
Godette:
    "Hello!{delay = 0.7} Nice to meet you."
```

## Variables

Insert static or dynamic variables.
```yaml
Dia:
    "Great job, {player}. Just {item_left} to go."
```
```yaml
Dia:
    "Your operating system is {User.os}.
    It is currently {User.datetime}.
    Your IP address is {User.ip_adress}"
```

## Set Properties

Manipulate properties &amp; variables.
```yaml
Ritsu:
    UI.portrait = "ritsu_smile.png"
    "Cheers!"
```
```yaml
Ritsu:
    Global.friendship_lv += 1
    "Yay!"
```

## Call Functions

Connect your story to the game with function calls.
```yaml
{player}:
    Player.heal(20)
    "Thanks! That feels so much better."
```

<br>

Call functions or set properties/variables at specific points in the Dialogue.
```yaml
Dia:
    "Let's brighten up the room a little...{d = 1.1}
        Background.set_brightness(1.0)
# or
        Background.brightness = 1.0
    there we go."
```

<p align="center">
<a href="https://nndda.github.io/Theatre/class/dialogue/syntax/">📚 More comprehensive Dialogue features documented here.</a>
</p>

# (Very) Quick Start

Write your epic Dialogue!
```gdscript
# Write it in a *.dlg file, and load it.
var epic_dialogue := Dialogue.load("res://epic_dialogue.dlg")

# Write it directly with triple quotation marks.
var epic_dialogue := Dialogue.new("""

Dia:
    "Loading the Dialogue written in a *.dlg file
    is much better for performance."
:
    "It'll keep things clean and efficient."
:
    "Plus, you’ll have syntax highlighting
    for better readability."

""")
```

Set the Stage! Add `TheatreStage` and `DialogueLabel` node to your scene. Structure your scene like the following:

<div align="center">
<img width="261" height="197" alt="A scene tree, with Stage and PanelContainer" src="https://github.com/user-attachments/assets/2fe8cc77-d35a-4eae-911d-8f3e0b6410dc" />
</div>

<br>

Adjust the position and size of the `PanelContainer` to your liking.

Select the `TheatreStage` node, and reference the `Label` & `DialogueLabel` node to display your Dialogue. Adjust and configure your `TheatreStage` via the inspector. Alternatively, you can also set them in script:

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

<img width="260" height="244" alt="Inspector dock's representation of Stage's properties." src="https://github.com/user-attachments/assets/6a60fa6c-3b6c-49e4-b182-f1fef3eec733" />

</td>
<td>

```gdscript
@onready var my_stage: TheatreStage = $TheatreStage

func _ready():
    my_stage.actor_label =\
        $PanelContainer/VBoxContainer/Label
    my_stage.dialogue_label =\
        $PanelContainer/VBoxContainer/DialogueLabel

```

</td>
</tr>

</table>

Reference the `TheatreStage` node in the script, and set up a way to progress your Dialogue with `TheatreStage.progress()`.

```gdscript
func _input(event):
    if event.is_action_pressed('ui_accept'):
        my_stage.progress()
```

And finally, start the `TheatreStage` with your `epic_dialogue`.

```gdscript
func _ready():
    my_stage.start(epic_dialogue)
```

<p align="center">
<a href="https://nndda.github.io/Theatre/quickstart/">📚 More detailed quick start tutorial here.</a>
</p>

## License

- Theatre is licensed under [MIT](LICENSE).
- [Theatre logo](/addons/Theatre/assets/icons/Theatre.svg), created by [nnda](https://github.com/nndda), is licensed under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- [Class icons](addons/Theatre/assets/icons/classes) from [@fontawesome](https://fontawesome.com) (recolored), are licensed under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/).
