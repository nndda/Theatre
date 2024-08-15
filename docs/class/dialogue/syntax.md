# Dialogue Syntax

This page covers the syntax of the written `Dialogue` and its features.

Dialogue text file needs to be saved as `*.dlg` or `*.dlg.txt`(1). Dialogue text/string needs to have at least one actor's name with `:` at the end, and the dialogue body indented:
{ .annotate }

1.  !!! tip
    Prefer saving written Dialogues as `*.dlg`, to keep the filename short and concise.

```
Actor's name:
    Dialogue body
```

!!! note "Dialogue filename"
    If there's two written `Dialogue` files with the same name, but are saved as `*.dlg` and `*.dlg.txt` (for example: `dialogue.dlg` and `dialogue.dlg.txt`), the one saved as `*.dlg.txt` will be ignored, and only `*.dlg` file will get gets compiled.

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

## Actor's name

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

Define the variable using `Stage.set_variable()`.

```gdscript
your_stage.set_variable(
    'player', 'John'
)
```

You can also define multiple variables using `Stage.merge_variables` with a `Dictionary`.

```gdscript
your_stage.merge_variables({
    'player': 'John',
    'item_left': 3
})
```

```
Dia:
    "Great job {player}! just {item_left} more to go."
```

### Built-in variables

| Tags    | Description         |
| ------- | ------------------- |
| `{n}`   | Newline |
| `{spc}`   | Space |

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
    { delay/wait/d/w = t }
    ```
    ```
    Dia:
        "Hello!{delay = 0.6} nice to meet you"
    ```

### :material-code-braces: speed

:   Change the text progress' speed at its position by `s` times. Revert back to normal speed (`s = 1`) when the Dialogue line is finished.
    ```
    { speed/s = s }
    ```
    ```
    Ritsu:
        "That is quite {speed = 0.4}spooky"
    ```
:   You can also revert the speed back with `{s}`.
    ```
    Ritsu:
        "So {s = 0.4}uh...{s} {d=0.9}what are we gonna do?"
    ```

## Function calls

Before calling the functions in the written Dialogue, you need to set the `caller`: the `Object` from which the function will be called.

You can do that using `Stage.add_caller()`.The first argument is the id that will be used in the written Dialogue. The second argument must be an `Object` class or anything that inherits that.

```gdscript
your_stage.add_caller('Player', $Player)
```

After that, you can call any script functions or built-in functions that are available in the caller.
```
{player_name}:
    "Thanks, that feels so much better"
    Player.heals(25)
```

If the caller is a `Node` or inherits `Node`, it will be removed automatically from the Stage if its freed. You can also remove caller manually with `Stage.remove_caller()`.

```gdscript
your_stage.remove_caller('Player')
```

All functions on a Dialogue line are called with the order they written. The following Dialogue will call `one()`, `two()`, and `three()` subsequently.
```
Dia:
    "You can call as many function as you want"

    Caller.one()
    Caller.two()
    Caller.three()
```

### Passing arguments

You can generally pass any data type in the function.
```
Ritsu:
    "Cheers!"

    Portrait.set("ritsu_smile.png")
```

You can also write expressions.
```
    Sprite.jump(pow(15, 2) * Vector2(0, -1))
```

Although, datatype constants are not supported for now.
```
# Not supported:
    Button.set_color(Color.BLUE)
    Player.rotate(Vector.RIGHT)

# Use these instead:
    Button.set_color(Color("#0000FF"))
    Player.rotate(Vector2(0, 1))
```

### Positional function calls

Just like Dialogue tags, functions can also be called at specific point in the written Dialogue.
```
Dia:
    "
    Let me brighten up the room a little...{d = 1.1}
    {0}
    there we go.
    "

    Background.set_brightness(1.0)
```

The `{0}` tag indicates that it will call the first function: `Background.set_brightness(1.2)`. Use zero based index to call functions, based on their order.

```
# {0}
    Caller.func_a()
# {1}
    Caller.func_b()
# {2}
    Caller.func_c()
```

The rest of the functions that are not called at a specific position will be called immediately.

```
Ritsu:
    "
    Such a lovely weather today!{d=0.9}
    {1}
        delay=1.5
    {2}
    I spoke too soon....
    "

    Portrait.set("ritsu_smile.png")

    Environment.set_weather("storm")

    Portrait.set("ritsu_pissed.png")
```

## BBCodes

Dialogue has partial supports for BBCodes: the `[img]` tag are not supported for now. `DialogueLabel` will _always_ have the `bbcode_enabled` property set to `true`. You can use BBCodes alongside variables and dialogue tags too.

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

You can start a `Dialogue` with at a specific section.
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
