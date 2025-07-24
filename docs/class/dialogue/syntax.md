# Dialogue Syntax

This page covers the syntax of the written `Dialogue` and its features.

Dialogue text file needs to be saved as `*.dlg`. Dialogue text/string needs to have at least one actor's name with `:` at the end, and the dialogue body indented:

```
Actor's name:
    Dialogue body
```

```
Ritsu:
    "You can
    break newline
    many times,
    as long
    as the dialogue body
    is indented!"
```

!!! note "Newlines"
    Even though the dialogue above has multiple newline breaks, it will be rendered without the newline:
    ```
    "You can break newline many times, as long as the dialogue body is indented!"
    ```
    You can insert newlines by using [`{n}` dialogue variable.](#built-in-variables).

## Actor's Name

For dialogue lines that use the same actor, You can leave the following actor's name blank, leaving `:` alone. It will use the last declared actor's name.

<div class="grid" markdown>

```
Dia:
    "I'm honestly running out of
    ideas for the dialogue
    text example"

Dia:
    "And I don't want to use
    'lorem ipsum' over and
    over again"

Dia:
    "Or anything along the
    lines of 'Hello, world!'"
```

```
Dia:
    "I'm honestly running out of
    ideas for the dialogue
    text example"

:
    "And I don't want to use
    'lorem ipsum' over and
    over again"

:
    "Or anything along the
    lines of 'Hello, world!'"
```

</div>

Leave the actor's name blank, by using a single underscore `_`.

```
{player}:
    "I'm {player}"

_:
    And I am a nameless narrator

```

## Variables

Insert variables by wrapping the variables name inside curly brackets: `{_}`.

```
{player}:
    "Please call my name, I need to demonstrate
    the variable use in the written Dialogue."

Ritsu:
    "O-okay?... hello {player}!"
```

Define the variable using `TheatreStage.set_variable()`.

```gdscript
your_stage.set_variable(
    "player", "John"
)
```

You can also define multiple variables using `TheatreStage.merge_variables` with a `Dictionary`.

```gdscript
your_stage.merge_variables({
    "player": "John",
    "item_left": 3
})
```

```
Dia:
    "Great job {player}! just {item_left} more to go."
```

### Built-in Variables

| Tags    | Description         |
| ------- | ------------------- |
| `{n}`   | Newline |
| `{spc}`   | Space |
| `{eq}`   | Equal sign `=` |

!!! warning
    You can't use names for variables that are used by Theatre. This includes:
    `{n}`, `{d}`, `{w}`, `{s}`, `{spc}`, `{delay}`, `{wait}`, `{speed}`, and [function calls indexes](#positional-function-calls).
    Variables using any of these names will be ignored or treated as the built-in tags/variables.

## Tags

There are several built-in tags to fine-tune your Dialogue flows. Tags can have several aliases: `{delay = 1.0}` can also be written as `{d = 1.0}`.

!!! note "Tag syntax"
    Tag can be written inbetween dialogue string:
    ```
    Wait,{delay = 0.5} alright go on
    ```
    Or in a newline
    ```
    Wait,
        delay=0.5
    alright go on
    ```
    Newline tag does not use curly brackets and spaces.

### :material-code-braces: delay/wait

:   Pause the text render at its position for `t` seconds.
    ```
    { delay|wait|d|w = t }
    ```
    ```
    Dia:
        "Hello!{delay = 0.6} nice to meet you"
    ```

### :material-code-braces: speed

:   Change the text progress' speed at its position by `s` times. Revert back to normal speed (`s = 1`) when the Dialogue line is finished.
    ```
    { speed|s = s }
    ```
    ```
    Ritsu:
        "That is quite {speed = 0.4}spooky"
    ```
:   You can also revert the speed back with `{s}`, which is equivalent to `{s = 1.0}`.
    ```
    Ritsu:
        "So {s = 0.4}uh...{s} {d=0.9}what are we gonna do?"
    ```

## Calling Functions & Changing Properties

### Scopes

Before calling functions or changing any properties in the written Dialogue, you need to set the `scope`: the `Object` from which the functions will be called, or its properties to be changed from within the written Dialogue.

Use `TheatreStage.add_scope()` to add a scope to a `TheatreStage`.The first argument is the id that will be used in the written Dialogue. The second argument must be an `Object` class or anything that inherits that. Name the scope's id, the way you would name a variable or a class in GDScript.

```gdscript
@onready var player = $Player

func _ready():
    your_stage.add_scope("Player", player)
```

Add multiple scopes at once, using `TheatreStage.merge_scoped()`, that takes a Dictionary format instead:

```gdscript
func _ready():
    your_stage.merge_scopes({
        "Player": $Player,
        "UI": $UI,
        "Global": Global
    })
```

!!! note
    You should set the scopes before starting any Dialogues.

If the scope is a `Node` or inherits `Node`, it will be removed automatically from the `TheatreStage` if its freed. You can also remove scope manually using `TheatreStage.remove_scope()`.

```gdscript
your_stage.remove_scope("Player")
```

Removes all scopes of a `TheatreStage` using `TheatreStage.clear_scopes()`:

```gdscript
your_stage.clear_scopes()
```

### Syntax

After setting up the scopes, you can call any functions, or manipulate properties that are available in the scope.

```
{player_name}:
    Player.heals(25)
    "Thanks, that feels so much better."
```
```
Ritsu:
    UI.portrait = "ritsu_smile.png"
    "Cheers!"
```
```
Ritsu:
    Global.friendship_lv = Global.friendship_lv + 1
    "Yay!"
```

All functions on a Dialogue line are called with the order they are written. The following Dialogue will call `one()`, `two()`, and `three()` subsequently.

```
Dia:
    Scope.one()
    Scope.two()
    Scope.three()
    "You can call as many functions as you want."
```

### Arguments & Expressions

You can generally pass any data type as the function calls arguments, or as the property's value.
```
Ritsu:
    Inventory.add([ 'apple_pie', 'cupcake', 'muffin' ])
    "Don't eat all of them at once~!"
```
```
Thief:
    Inventory.items = []
    "I'll be taking that >:)"
```

You can also write expressions.
```
    Sprite.jump(pow(15, 2) * Vector2(0, -1))
```

Although, built-in constants are not supported for now.
```
# ❌ Not supported:
    Button.set_color(Color.BLUE)
    Player.rotate(Vector.RIGHT)

# ✅ Use these instead:
    Button.set_color(Color("#0000FF"))
    Player.rotate(Vector2(0, 1))
```

!!! warning "Function syntax"
    Write function calls (including all of its arguments) in a single line only!

    ```
    # ❌ Not supported:
        Portrait.set(
            "res://ritsu_angy.png"
        )

    # ✅ Write function in a single line:
        Portrait.set("res://ritsu_smile.png")
    ```

### Positions

Functions will be called, and properties will be set, when the `Dialogue` has rendered/reached the exact positions they were written on:

```
Actor:
    Scope.foo()
    "..."
    Scope.bar()
```

In the `Dialogue` line above, the `foo()` function will be called immediately after the `Dialogue` progressed to this line. And the `bar()` function will be called after the whole `Dialogue` line has fully been rendered. The same also applies to setting properties.

You can also place them in the middle of the `Dialogue` content.

```
Dia:
    "Let me brighten up the room a little...{d = 1.1}
        Background.set_brightness(1.0)
    there we go."
```
```
Ritsu:
    Portrait.set("ritsu_smile.png")

    "Such a lovely weather today!{d = 1.5}
        Environment.set_weather("storm")
        delay=1.5
        Portrait.set("ritsu_pissed.png")
    nevermind..."
```

## BBCodes

!!! warning
    Dialogue has partial supports for BBCodes: the `[img]` tag are not supported for now.

You can use BBCodes alongside variables and dialogue tags. `DialogueLabel` will _always_ have the `bbcode_enabled` property set to `true`.

There's also several shorthand aliases for BBCode tags:

| Shorthand    | BBCode tag         |
| ------------ | ------------------ |
| `[c]`, `[col]` | `[color]` |
| `[bg]` | `[bgcolor]` |
| `[fg]` | `[fgcolor]` |
| `\[` | `[lb]` |
| `\]` | `[rb]` |

The escaped square brackets: `\[` and `\]`, are actually shorthands for `[rb]` and `[lb]`. So, rather than writing:

```
Dia:
    "There are three main classes of the Theatre plugin:
    [color=blue]Dialogue[/color],
    [color=green]DialogueLabel[/color], &
    [color=red]TheatreStage[/color],
    "
```

You can write:

```
Dia:
    "There are three main classes of the Theatre plugin:
    [c=blue]Dialogue[/c],
    [c=green]DialogueLabel[/c], &
    [c=red]TheatreStage[/c],
    "
```


## Sections

Define a section in dialogue with `:section_name`.

``` title="res://convo.dlg"
Dia:
    "This Dialogue line can be skipped!"

:some_section
Dia:
    "You can jump to any defined section
    in the written Dialogue"
```

You can start a `Dialogue` at a specific section.
```gdscript
your_stage.start(
    Dialogue.load("res://convo.dlg"),
    "some_section"
)
```

Or go to a section in the middle of a `Dialogue` using `jump_to_section()` or `jump_to()`.
```gdscript
your_stage.jump_to_section("some_section")
your_stage.jump_to("some_section")
```

## Comments

Write comments by placing `#` at the start of a new line.
```
Ritsu:
    "This is a dialogue!"

# and this is a comment
```

!!! warning
    Comments can only be placed on a new line. With the `#` character placed at the beginning of the line. You can't put comments after the actor's name or dialogue body.
    ```
    Ritsu:
        "This right here 👉" # this is not a comment
        # and this will not count as a comment too
    ```
