<h1>
    <img src="https://github.com/user-attachments/assets/93316149-f3c1-4b06-aefe-6aa6a8397868" alt="Theatre logo" height="38">&nbsp;
    Theatre
</h1>

<img src="/addons/Theatre/assets/icons/Theatre.svg" alt="Theatre logo" height="160" align="right">

<a href="https://godotengine.org/"><img src="https://img.shields.io/badge/%E2%89%A54.4-white?style=flat-square&logo=godotengine&logoColor=white&label=Godot&labelColor=%232f5069&color=%233e4c57" alt="Godot 4.4 or above" height="20"></a>
<a href="https://github.com/nndda/Theatre/actions/workflows/dialogue-test.yml"><img src="https://img.shields.io/github/actions/workflow/status/nndda/Theatre/dialogue-test.yml?branch=main&event=push&style=flat-square&label=CI&labelColor=%23252b30&color=%23306b3d" alt="Build status" height="20"></a>
<a href="https://nndda.github.io/Theatre/"><img src="https://img.shields.io/website?style=flat-square&label=Docs&labelColor=%23252b30&color=%23306b3d&up_message=online&url=http%3A//nndda.github.io/Theatre" alt="Documentation build" height="20"></a>

Yet another <sub>(linear)</sub> dialogue system<b>/</b>addon<b>/</b>plugin for Godot. With features such as:

- ✍️ Text-based, human-readable syntax.
- ⚡ Simple setup. Get started in just <b>7 lines</b> of codes!
- 😐 ....
- 📝 And <b>100%</b> written in <b>GDScript!</b>

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

<img src="https://github.com/user-attachments/assets/30b57946-b39c-4e7e-a8c3-487f9a50a100" alt="Theatre in action" width="385">

</td>
<td>

<img alt="Theatre Dialogue script" src="https://github.com/user-attachments/assets/a655c48e-b09f-46b3-a375-cde3bd654d60" width="385">

</td>
</tr>
</table>

```gdscript
# Load your epic dialogue!
var dialogue: Dialogue = load('res://dialogue.dlg')
# Set up the stage
@export var stage: TheatreStage

func _ready():
    # Start your dialogue
    stage.start(dialogue)

func _input(event):
    # When the space/enter key is pressed,
    if event.is_action_pressed('ui_accept'):
        # Progress your dialogue
        stage.progress()
```

<br>

> [!IMPORTANT]
> This project is still in development and is subject to frequent breaking changes, and bugs. Check out the [Issues](https://github.com/nndda/Theatre/issues) page for known bugs &amp; issues, and [Common Troubleshooting](https://nndda.github.io/Theatre/tutorials/troubleshooting/) documentation page if you encounter any issues.

<br>

# Installation
Run the command below in your Godot project directory. Or [download and install](https://theatre.nnda.dev/installation/) it manually.
```sh
curl -L 'https://nnda.dev/theatre/latest' | tar zxv --strip-components=1
```
The URL above is just a redirect to the `main` branch tarball :p

<br>

# Features

## Variables & Expressions

Insert static...
```yaml
Dia:
    "Let's meet {player}. Don't keep {player_pronoun} waiting."
```
...or dynamic variables.
```yaml
Dia:
    "Good {Game.day_state}, {Game.player.name}."
```

Execute, evaluate, and insert any valid GDScript expressions to the dialogue.
```yaml
Ritsu:
    "HEY {( Player.name.to_upper() )}!!"
```
```yaml
Dia:
    "Your operating system is {( OS.get_name() )}.
    It is currently {( Time.get_time_string_from_system(false) )}."
```

## Dialogue Tags

Fine-tune your dialogue flow with `{delay}` and `{speed}`.
```yaml
Godette:
    "Hello!{delay = 0.7} Nice to meet you."
```
```yaml
Ritsu:
    "{speed = 1.5}AAAAAAAAAAAAAAAAA!!!!"
```

## Manipulate Properties

Manipulate in-game object properties &amp; variables.
```yaml
Ritsu:
    UI.portrait.current = "ritsu_smile.png"
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

## Extensible API
Here's some signals, here's some dialogue data, do whatever you want.

```gdscript
func _progressed_on(dialogue_data):
    var speaker = dialogue_data[Dialogue.ACTOR]
    var text = dialogue_data[Dialogue.CONTENT]

    if speaker == "Dia":
        portrait.change("dia.png")
        dialogue_label.text_color = Color.LIGHT_BLUE
    elif speaker == "Ritsu":
        portrait.change("ritsu.png")
        dialogue_label.text_color = Color.PINK
    else:
        portrait.change("blank.png")
        dialogue_label.text_color = Color.WHITE

    history_log.push({
        "speaker": speaker,
        "text": text
    })
```

<p align="center">
<a href="https://nndda.github.io/Theatre/class/dialogue/syntax/">📚 More comprehensive Dialogue features documented here.</a>
</p>

# _(Very)_ Quick Start

Write your epic Dialogue!
```gdscript
# Write it in a *.dlg file, and load it.
var dialogue: Dialogue = load('res://dialogue.dlg')
# or
var dialogue := Dialogue.load('res://dialogue.dlg')

# Write it directly with triple quotation marks.
var dialogue := Dialogue.new("""

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

<img align="right" width="261" height="197" alt="A scene tree, with Stage and PanelContainer" src="https://github.com/user-attachments/assets/2fe8cc77-d35a-4eae-911d-8f3e0b6410dc" />

Set the Stage! Add
<code><img src="addons/Theatre/assets/icons/classes/ticket.svg" height="13"> TheatreStage</code>
and
<code><img src="addons/Theatre/assets/icons/classes/message.svg" height="13"> DialogueLabel</code>
node to your scene. Structure your scene like the following image:

And adjust the position and size of the
<code><img src="https://raw.githubusercontent.com/godotengine/godot/refs/heads/master/editor/icons/PanelContainer.svg" height="13"> PanelContainer</code>
to your liking.

Select the
<code><img src="addons/Theatre/assets/icons/classes/ticket.svg" height="13"> TheatreStage</code>
node, and reference the
<code><img src="https://raw.githubusercontent.com/godotengine/godot/refs/heads/master/editor/icons/Label.svg" height="13"> Label</code>
&
<code><img src="addons/Theatre/assets/icons/classes/message.svg" height="13"> DialogueLabel</code>
node to display your Dialogue. Adjust and configure your
<code><img src="addons/Theatre/assets/icons/classes/ticket.svg" height="13"> TheatreStage</code>
via the inspector. Alternatively, you can also set them in script:

<br>

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
@onready var stage: TheatreStage = $TheatreStage

func _ready():
    stage.actor_label =\
        $PanelContainer/VBoxContainer/Label
    stage.dialogue_label =\
        $PanelContainer/VBoxContainer/DialogueLabel

```

</td>
</tr>

</table>

Reference the
<code><img src="addons/Theatre/assets/icons/classes/ticket.svg" height="13"> TheatreStage</code>
node in the script, and set up a way to progress your Dialogue with `TheatreStage.progress()`.

```gdscript
func _input(event):
    if event.is_action_pressed('ui_accept'):
        stage.progress()
```

And finally, start the
<code><img src="addons/Theatre/assets/icons/classes/ticket.svg" height="13"> TheatreStage</code>
with your `dialogue`.

```gdscript
func _ready():
    stage.start(dialogue)
```

<p align="center">
<a href="https://nndda.github.io/Theatre/quickstart/">📚 More detailed quick start tutorial here.</a>
</p>

## License

- Theatre is licensed under [MIT](LICENSE).
- [Theatre logo](/addons/Theatre/assets/icons/Theatre.svg), created by [nnda](https://github.com/nndda), is licensed under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- [Class icons](addons/Theatre/assets/icons/classes) from [@fontawesome](https://fontawesome.com) (recolored), are licensed under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/).
