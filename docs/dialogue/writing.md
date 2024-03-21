# Writing your dialogue

This page cover the syntax of the Dialogue, and its features.

`Dialogue` text/string needs to have atleast one actor's name with `:` at the end, and the dialogue body indented:
```
Actor name:
    Dialogue body
```

```
Ritsu:
    "You
    can
    break
    new line
    many times,
    as long
    as the dialogue body
    is indented"
```

## Comments

You can write comments with `#`.
```
Ritsu:
    "Hello, world!"

# this is a comment
```

!!! note
    Comments can only be placed on a new line. You can't put comments after actor's name or dialogue body.
    ```
    Ritsu:
        "Hello, world!" # this is not allowed
    ```

## Variables

Godot's built-in method `String.format()` are used to insert variables into dialogue body and the actor's name. You can define the variable with [`Stage.variables`]("/").

```
{player_name}:
    "Hi there"

Ritsu:
    "Hello {player_name}!"
```

## Built-in tags

There are several built-in tags to customize how the Dialogue flows.

:material-code-braces: delay/wait

:   Pause the text progress at its position for `t` seconds.
    ```
    { delay = t }
    { wait = t }
    ```
    ```
    Dia:
        "I was um...{delay = 0.6} thinking about something"
    ```

:material-code-braces: speed

:   Change the text progress' speed at its position by `s` times. Revert back to normal speed (`s = 1`) when finished.
    ```
    { speed = s }
    ```
    ```
    Ritsu:
        "That place is quite {speed = 0.4}spooky"
    ```

## Function calls

Before calling the functions within the dialogue, you need to set the [`caller`]("/"): the Object from which the function will be called.

```gdscript
stage.set_caller("Player", $Player)
```

After that you can call the functions with the following syntax:
```
caller.function_name()
```


```
{player_name}:
    "Thanks, that feels so much better"
    Player.heals(25)
```

A `caller` will be deleted when its object is freed. You can also delete them manually with `Stage.remove_caller`.

```gdscript
stage.remove_caller("Player")
```

Currently, function calls in Dialogue only accept the following parameter type:
<ul>
  <li><code>int</code></li>
  <li><code>float</code></li>
  <li><code>String</code></li>
</ul>