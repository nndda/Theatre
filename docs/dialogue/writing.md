# Writing your dialogue

This page cover the syntax of Dialogue, and its features.

`Dialogue` text/string needs to have atleast one actor's name with `:` at the end, and the dialogue body indented:
```
Actor name:
    Dialogue body
```

```
Ritsu:
    "You can
    break new line
    many times,
    as long
    as the dialogue body
    is indented"
```
And save your dialogue with the file extension `*.dlg.txt`

## Comments

You can write comments with `#`.
```
Ritsu:
    "Hello, world!"

# this is a comment
```

!!! warning
    Comments can only be placed on a new line. With the `#` character placed at the beginning of the line. You can't put comments after actor's name or dialogue body.
    ```
    Ritsu:
        "Hello, world!" # this is not allowed
        # and this will not count as comment
    ```

## Variables

Use `{var}` to insert variables into the dialogue body or actor's name.

```
{player_name}:
    "Hi there"

Ritsu:
    "Hello {player_name}!"
```

You can define the variable with [`Stage.add_variables`]("/").

```gdscript
your_stage.add_variables(
    "player_name", "John"
)
```

### Built-in variables

There are some built-in variables

* `{n}` - Newline
* `{rb}` - Right bracket character `}`
* `{lb}` - Left bracket character `{`

## Tags

There are several built-in tags to customize how the Dialogue flows.

### :material-code-braces: delay/wait

:   Pause the text progress at its position for `t` seconds.
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
        "That place is quite {speed = 0.4}spooky"
    ```
:   You can also revert the speed back with `{s}`
    ```
    Ritsu:
        "And {s = 0.4}err... {s}I've been wondering"
    ```

## Function calls

Before calling the functions within the dialogue, you need to set the [`caller`]("/"): the Object from which the function will be called.

```gdscript
stage.set_caller("player", $Player)
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

A `caller` will be deleted when its object is freed. You can also delete them manually with `Stage.remove_caller`.

```gdscript
stage.remove_caller("player")
```

<!-- Currently, function calls in Dialogue only accept the following parameter type:
<ul>
  <li><code>int</code></li>
  <li><code>float</code></li>
  <li><code>String</code></li>
</ul> -->