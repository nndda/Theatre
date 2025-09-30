# Dialogue Beep SFX

```
Dia:
    "Dialogue voice beep are substitute
    for voice acting in video games."
:
    "Especially in the older titles
    and smaller budget productions."
:
    "Although not really used in modern, big budget titles anymore,
    there's many indie games that still use this today."

```

!!! info "TL;DR"
    Play the dialogue beep audio with the [DialogueLabel]'s [`character_drawn`](/class/dialoguelabel/references/#character_drawn) signal.

0. Add the dialogue voice beep audio file to your project. In this article, we'll use one of the sound effect from [Text/Dialogue Bleeps Pack by dmochas :fontawesome-brands-creative-commons: :fontawesome-brands-creative-commons-by:](https://dmochas-assets.itch.io/dmochas-bleeps-pack).

    <br>

0. Add [AudioStreamPlayer] node, attach the beep audio file to it. Reference it as `beep_player` variable in the script.

    ```gdscript
    @export var beep_player: AudioStreamPlayer
    ```

    <div class="grid cards" markdown>

    - ![AudioStreamPlayer node in the scene tree](audiostreamplayer.png){ .center }

    - ![AudioStreamPlayer referenced to beep_player variable](audiostreamplayer_2.png){ .center }

    </div>

    <br>

0. Connect the signal [`character_drawn`](/class/dialoguelabel/references/#character_drawn) from [DialogueLabel] to method `_on_dialogue_label_character_drawn()`.

    ```gdscript
    func _on_dialogue_label_character_drawn():
        pass # Replace with function body.
    ```

    <div class="grid cards" markdown>

    - ![character_drawn signal being highlighted in the Node dock](character_drawn.png){ .center }

    </div>

    <br>

0. On the signal method, play the audio from the `beep_player` using [`play()`](https://docs.godotengine.org/en/4.4/classes/class_audiostreamplayer.html#class-audiostreamplayer-method-play). Only if its not already playing.

    ```gdscript hl_lines="2 3"
    func _on_dialogue_label_character_drawn():
        if not beep_player.playing:
            beep_player.play()
    ```

    <br>

## Code summary

``` hl_lines="7"
MyScene
  ├─ TheatreStage
  ├─ PanelContainer
  │     └─ VBoxContainer
  │         ├─ Label
  │         └─ DialogueLabel
  └─ AudioStreamPlayer
```

```gdscript hl_lines="6 15 16 17"
extends Control

var dlg: Dialogue # Load/create Dialogue here

@export var my_stage: TheatreStage
@export var beep_player: AudioStreamPlayer

func _input(event):
    if event.is_action_pressed("ui_accept"):
        stage.progress()

func _ready():
    stage.start(dlg)

func _on_dialogue_label_character_drawn():
    if not beep_player.playing:
        beep_player.play()
```

<br>

Got any questions? feel free to ask them in the [GitHub Discussions!](https://github.com/nndda/Theatre/discussions/new?category=help){ target="_blank" }