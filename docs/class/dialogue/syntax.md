# :fontawesome-solid-feather-alt:{.theatre-icon} Dialogue Syntax

This page covers the syntax of the written dialogue and all of its features.

### Syntax Overview

Dialogue text file are saved as `*.dlg`. The dialogue text require at least one actor name, followed by `:` at the end, and the dialogue body indented:

```yaml
# This is a comment

# This is a dialogue line. It is started with an actor name, followed by ':'
Ritsu:
    "Helloooo!!!"
# This is the next dialogue line.
# Because the actor name is empty,
# it'll use the previous actor name instead: Ritsu
:
    "Welcome welcome!!"

# This is another dialogue line, now with different actor.
Dia:
    "Welcome."
:
    "We hope this article helps with your project."
```

---

## :material-keyboard-space: Whitespace

```yaml
Ritsu:
    "You can
    break newline
    many times,
    as long
    as the dialogue body
    is indented!"
```

!!! note "Newlines"
    Even though the dialogue above have multiple newline breaks, it will be rendered without the newlines:
    ```
    "You can break newline many times, as long as the dialogue body is indented!"
    ```
    Insert newlines by using [`{n}` dialogue variable.](#built-in-variables).

Any extra whitespaces **after** the end of a dialogue line will be trimmed to one space.

```yaml
Ritsu:
    "There's bunch of spaces here 👉      
    but... its invisible, and it will be trimmed to one anyway."
```

If you want to avoid trimming, insert the spaces in the middle:

```yaml
Ritsu:
    "This is a long        space."
```

Or using the built-in `{spc}` variable:

```yaml
Ritsu:
    "This is a long {spc}{spc}{spc}{spc} space."
```

---

## :fontawesome-solid-user-tag: Actor's Name

For dialogue lines that use the same actor, you can leave the following actor's name blank, leaving only the `:` character alone. It will use the last declared actor's name.

<div class="grid" markdown>

```yaml
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

```yaml
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

```yaml
Ritsu:
    "Ritsu deeesu!!"

_:
    I am a nameless narrator

{player}:
    "And I'm {player}"
```

---

## :material-code-json: Variables

Insert variables by wrapping the variables name inside curly brackets: `{_}`.

```yaml
{player}:
    "Please call my name, I need to demonstrate
    the use of variable in the written Dialogue."

Ritsu:
    "O-okay?... hello {player}!"
```

Define the variable using [`TheatreStage.set_variable()`](class/theatrestage/references/#set_variable).

```gdscript
my_stage.set_variable(
    "player", "John"
)
```

Define multiple variables using [`TheatreStage.merge_variables()`](class/theatrestage/references/#merge_variables) with a [Dictionary].

```gdscript
my_stage.merge_variables({
    "player": "John",
    "item_left": 3
})
```

```yaml
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
    `{n}`, `{d}`, `{w}`, `{s}`, `{spc}`, `{delay}`, `{wait}`, `{speed}`, and numbers (`{0}`, `{3}`, `{15}`, etc.).
    Variables using any of these names will be ignored or treated as the built-in tags/variables.

For more dynamic variables, see [Scope Variables](#scope-variables) and [Expression Tag](#expression-tag).

---

## :fontawesome-solid-tag: Tags

There are several built-in tags to fine-tune your dialogue flows. Tags can have several aliases: `{delay = 1.0}` can also be written as `{d = 1.0}`.

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
    ```yaml
    Dia:
        "Hello!{delay = 0.6} nice to meet you"
    ```

### :material-code-braces: speed

:   Change the text progress' speed at its position by `s` times. Revert back to normal speed (`s = 1`) when the Dialogue line is finished.
    ```
    { speed|s = s }
    ```
    ```yaml
    Ritsu:
        "That is quite {speed = 0.4}spooky"
    ```
:   You can also revert the speed back with `{s}`, which is equivalent to `{s = 1.0}`.
    ```yaml
    Ritsu:
        "So {s = 0.4}uh...{s} {d=0.9}what are we gonna do?"
    ```

---

## :fontawesome-solid-bullhorn: Calling Functions & Manipulating Properties

### Scopes

Before calling functions or changing any properties in the written dialogue, you need to set the `scope`: the [Object] from which the functions will be called, or its properties to be modified from within the written dialogue.

Use [`TheatreStage.add_scope()`](class/theatrestage/references/#add_scope) to add a scope to a [TheatreStage] instance. The first argument is the ID that will be used in the written Dialogue. The second argument must be of an [Object] class, or anything that inherits that. Name the scope's ID, the way you would name a variable or a class in GDScript.

```gdscript
@onready var player = $Player

func _ready():
    my_stage.add_scope("Player", player)
```
<!-- 
Add multiple scopes at once, using `TheatreStage.merge_scoped()`, that takes a Dictionary format instead:

```gdscript
func _ready():
    my_stage.merge_scopes({
        "Player": $Player,
        "UI": $UI,
        "Global": Global
    })
```
 -->
!!! note
    Set up the scopes before starting the dialogue.

Remove a scope manually from a [TheatreStage] instance using [`TheatreStage.remove_scope()`]((class/theatrestage/references/#remove_scopes)).
If the scope is a [Node] or inherits it, it will be removed automatically when its freed.

```gdscript
my_stage.remove_scope("Player")
```

Remove all scopes of a [TheatreStage] instance using [`TheatreStage.clear_scopes()`](class/theatrestage/references/#clear_scopes):

```gdscript
my_stage.clear_scopes()
```

#### Built-in Scopes

All singletons by user, or built-in from the Godot Engine itself (i.e. [Engine], [OS], [Time], etc.) are available as built-in scopes by default.
Built-in scopes like that can't be overriden. You can't add a scope with the same ID/name as a built-in scope:

```gdscript
my_stage.add_scope("Time", $Foo) # ❌
```

The code above won't register `$Foo` as `Time`, because `Time` already exists as a built-in scope.

### Syntax

After setting up the scopes, you can call any functions, manipulate properties, and insert variables that are available in the scope.
Below are some examples to get started:

#### Function Calls

Syntax: `scope.function(arg)`

```yaml
Ritsu:
    UI.set_portrait("res://portraits/ritsu/smile.png")
    "Cheers!"
```

```yaml
Ritsu:
    Player.heal(25)
    "There! better??"

{Player.name}:
    "Thanks, that feels so much better."
```

##### Arguments & Expressions

You can generally pass any valid GDScript expressions as the function calls arguments, or as the property's value:
```yaml
    Sprite.jump( pow(15, 2) * Vector2(0, -1) )
```

And even references to other scopes:
```yaml
    GameData.set_data( "username", Player.name )
    Log.add( "dialogue_finished", Time.get_time_string_from_system() )
```

Although, built-in constants from the engine itself are not supported for now.
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


#### Property Manipulations

Syntax: `scope.variable  = | += | -= | *= | /=  value`

```yaml
Ritsu:
    Global.friendship_lv += 1
    "Yay!!"
```

```yaml
Ritsu:
    Inventory.items = ["cupcake", "muffin", "scone"]
    "Have some snacks ;)"

{Player.name}:
    "Thanks :D"

Thief:
    Inventory.items = []
    "I will be taking these >:)"
```

#### Scope Variables

Syntax: `{ scope.variable }`

Insert any variables or constant of a scope in the dialogue text.

```yaml
Ritsu:
    "Good {Game.day_state}, {Game.player_name}!"
```

Given a setup like the following:
```gdscript
var day_state = "evening"
var player_name = "Sylvia"

func _ready():
    my_stage.add_scope("Game", self)
```

The output will be:
```yaml
Ritsu:
    "Good evening, Sylvia!"
```

More examples:

```yaml
Dia:
    "Let's meet {Player.name}. Don't keep {Player.pronoun} waiting."
```

#### Expression Tag

Syntax: `{( expressions )}`

Write any valid GDScript expressions, pull scope variables, or call scope functions, modify its return value further, and have them outputted in the written dialogue.

```yaml
Ritsu:
    "HEEEEY!! {( Player.name.to_upper() )}!!"
:
    "{( (Player.name.to_upper() + ' ').repeat(3).strip_edges() )}!!!!"

{Player.name}:
    "WHAAAAT??"
```

Given a `Player.name` of `Nina`, it'll output:
```yaml
Ritsu:
    "HEEEEY!! NINA!!"
:
    "NINA NINA NINA!!!!"

Nina:
    "WHAAAAT??"
```

More examples:

```yaml
Dia:
    "You're running {( OS.get_name() )}."
:
    "It is currently {( Time.get_time_string_from_system(false) )}."
```

```yaml
Ritsu:
    "Diaaaaaa, help me with my assignment TwT"

Dia:
    "Hmmm..."
:
    "Given a cone with a radius of {Cone.radius} meters,"
:
    "...and a height of {Cone.height} meters,"
:
    "Its volume would be
    {( snappedf( PI * Cone.radius ** 2 * (Cone.height / 3), 0.01 ) )}
    cubic meters."
```

##### Variable vs. Scope Variable vs. Expression Tag

Variable tag, added manually via [`TheatreStage.set_variable()`](class/theatrestage/references/#set_variable) or [`TheatreStage.merge_variables()`](class/theatrestage/references/#merge_variables) are *static variables*. To update its value, you'd need to re-call those methods that were used set them again.

Scoped variable are pulled from the scope (its variables or constants) when the dialogue progressed to that line.

If you're only pulling in the value from the game, opt with using the regular variable tag, or Scope Variable if you need more flexibility, instead of Expression Tag, unless you also want to transform the variable (i.e. convert it to uppercase).

!!! note
    Scope Variable and Expression Tag also can be used in actor's name string.
    ```yaml
    Lord {( Player.name[0].to_upper() )}.:
        "Mmm, yes, I am the one who goes by '{Player.name}'"
    ```
    Given `Player.name` of `William`, it'll output:
    ```yaml
    Lord W.:
        "Mmm, yes, I am the one who goes by 'William'"
    ```

### Orders

Functions calls and variables manipulations on a dialogue line are called with the order they are written. The first line on the following dialogue will call `one()`, `two()`, and `three()` subsequently.

```yaml
Dia:
    Scope.one()
    Scope.two()
    Scope.three()
    "Call as many functions as you want."
:
    "By the start or the end of a dialogue line."
    Scope.owo()
:
    "Or, in the middle
    Scope.uwu()
    of the dialogue."
```

In the last line, the function `Scope.uwu()` will be called, right after the word `'middle'` has rendered in.

The same also applies to variable manipulation.

```yaml
Dia:
    Scope.value = 0
    Scope.value += 3
    Scope.value *= 6
    Scope.value /= 2
    "'Scope.value' is now 9"
```

!!! example

    ```yaml
    Dia:
        "Let me brighten up the room a little...{d = 1.1}
            Background.set_brightness(1.0)
        there we go."
    ```

    ```yaml
    Ritsu:
        Portrait.set("ritsu_smile.png")

        "Such a lovely weather today!{d = 1.5}
            Environment.set_weather("storm")
            delay=1.5
            Portrait.set("ritsu_pissed.png")
        nevermind..."
    ```

!!! note

    If a line contains Scope Variables or Expression Tag, like the following:

    ```yaml
    Dia:
        Portrait.change("dia_smiles.png")

        "My, you like {Player.fav_item} too?"
    ```

    The scope variable `Player.fav_item` will be pulled ***before*** calling any function, even the first one like the above's `Portrait.change()`.

    Meaning if the variable has a getter function, that getter function will be called, before any of the functions in the dialogue. 

<!-- ### Positions

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
 -->

---

## :material-code-block-brackets: BBCodes

BBCodes tags are allowed, and can be used alongside variables and dialogue tags. [DialogueLabel] will _always_ have the `bbcode_enabled` property set to `true`.

There's also several shorthand aliases for BBCode tags:

| Shorthand    | BBCode tag         |
| ------------ | ------------------ |
| `[c]`, `[col]` | `[color]` |
| `[bg]` | `[bgcolor]` |
| `[fg]` | `[fgcolor]` |
| `\[` | `[lb]` |
| `\]` | `[rb]` |

So, the following:

```yaml
Dia:
    "There are three main classes of the Theatre plugin:
        delay=.5
    [color=blue]Dialogue[/color],
    [color=green]DialogueLabel[/color], &
    [color=red]TheatreStage[/color].
    "
```

Will transpile to:

```yaml
Dia:
    "There are three main classes of the Theatre plugin:
        delay=.5
    [c=blue]Dialogue[/c],
    [c=green]DialogueLabel[/c], &
    [c=red]TheatreStage[/c].
    "
```

### `[img]` Tag

Display an image using the `[img]` tag. Each image count as one character when rendering the dialogue.
```yaml
Ritsu:
    "Nooooo!!! [img height=20]res://emoji/crying_loudly.png[/img]
    "
```

Alternatively, use the following syntax, for shorter and simpler markup.
```yaml
Ritsu:
    "Nooooo!!!
    [img h=20 res://emoji/crying_loudly.png]
    "
```

!!! note
    The syntax above can **only be used in a newline**.
    ```yaml
    # ❌
    Ritsu:
        "Nooooo!!! [img h=20 res://emoji/crying_loudly.png]"
    ```
    ```yaml
    # ✅
    Ritsu:
        "Nooooo!!!
        [img h=20 res://emoji/crying_loudly.png]
        "
    ```

## Sections

Define a section in dialogue with `:section_name`.

```yaml title="res://convo.dlg"
Dia:
    "This Dialogue line can be skipped."

:some_section
Dia:
    "You can jump to any defined section
    in the written Dialogue."
```

You can start a dialogue at a specific section.
```gdscript
my_stage.start(
    Dialogue.load("res://convo.dlg"),
    "some_section"
)
```

Or go to a section in the middle of a dialogue using [`TheatreStage.jump_to_section()`](class/theatrestage/references/#jump_to_section) or [`TheatreStage.jump_to()`](class/theatrestage/references/#jump_to).
```gdscript
my_stage.jump_to_section("some_section")
my_stage.jump_to("some_section")
```

## Comments

Write comments by placing `#` at the start of a new line.
```yaml
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
