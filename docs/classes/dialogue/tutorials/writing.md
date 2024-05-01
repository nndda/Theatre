# Writing your dialogue

This page cover the syntax of Dialogue, and its features.

Dialogue text file needs to be saved as `*.dlg.txt`. Dialogue text/string needs to have atleast one actor's name with `:` at the end, and the dialogue body indented:
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

!!! note
    Even though the dialogue above has multiple newline breaks, it will be rendered without the newline:
    ```
    "You can break newline many times, as long as the dialogue body is indented!"
    ```
    You can insert newline by using [`{n}` dialogue variable.](#built-in-variables)

## Actor's name

When writing lots of dialogue lines of the same actor, typing the same actor name for each line can be quite tedious.

You can leave the following actor's name blank, leaving `:` alone. It will use the last declared actor's name.

<div class="grid" markdown>

```
Dia:
    "Im honestly running out of
    ideas for the dialogue
    text example"

Dia:
    "And I don't want to use
    'lorem ipsum' over and
    over again"

Dia:
    "Or using 'Hello, world!'"
```

```
Dia:
    "Im honestly running out of
    ideas for the dialogue
    text example"

:
    "And I don't want to use
    'lorem ipsum' over and
    over again"

:
    "Or using 'Hello, world!'"
```

</div>

If you want to leave the actor's name blank, you can use single underscore (`_`).

```
_:
    I am a nameless actor
```

## Comments

Write comments by placing `#` at the beginning of a new line.
```
Ritsu:
    "Hi everyone!"

# this is a comment
```

!!! warning
    Comments can only be placed on a new line. With the `#` character placed at the beginning of the line. You can't put comments after actor's name or dialogue body.
    ```
    Ritsu:
        "Hello, world!" # this is not allowed
        # and this will not count as a comment
    ```

## Variables

Use `{var}` to insert variables into the dialogue body or actor's name.

```
{player_name}:
    "Hi there"

Ritsu:
    "Hello {player_name}!"
```

You can define the variable using [`Stage.set_variable`]("/").

```gdscript
your_stage.add_variable(
    "player_name", "John"
)
```

You can also define multiple variables using [`Stage.merge_variables`]("/") with a `Dictionary`.

```gdscript
your_stage.merge_variables({
    'player_name': 'John',
    'day_state': 'evening',
    'day_left': 9,
})
```
```
Dia:
    "Good {day_state}, {player_name}.
    The event will starts in {day_left} days"
```

### Built-in variables

| Tags    | Description         |
| ------- | ------------------- |
| `{n}` | Newline|
| `{rb}` | Right bracket character `}`|
| `{lb}` | Left bracket character `{`|

!!! note
    Since the character `{` and `}` can be misinterpreted as a Dialogue variables or tags, Its best to use `{lb}` and `{rb}` to insert brackets.

## Tags

There are several built-in tags to fine-tune the Dialogue flows. Tags can have several aliases: `{delay = 1.0}` can also be written as `{d = 1.0}`.

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

:   Change the text progress' speed at its position by `s` times. Revert back to normal speed (`s = 1`) when the Dialogue finished.
    ```
    { speed/s = s }
    ```
    ```
    Ritsu:
        "That is quite {speed = 0.4}spooky"
    ```
:   You can also revert the speed back with `{s}`
    ```
    Ritsu:
        "So {s = 0.4}uh... {s}how's it going?"
    ```

## Function calls

Before calling the functions within the dialogue, you need to set the `caller`: a Node from which the function will be called.

You can do that using `Stage.add_caller`. The second parameter must be a `Node` or inherits `Node`.

```gdscript
your_stage.add_caller('player', $Player)
```

After that you can call the functions with the following syntax:
```
caller.function_name()
```


```
{player_name}:
    "Thanks, that feels so much better"
    player.heals(25)
```

A `caller` will be removed when its node is freed. You can also delete them manually with `Stage.remove_caller`.

```gdscript
your_stage.remove_caller('player')
```

!!! warning
    Currently