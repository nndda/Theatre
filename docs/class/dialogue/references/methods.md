# Methods

!!! note
    This page might not cover every single methods in the `Dialogue` class.

## Loader/Parser

### load { .func .return .Dialogue params="path-string" }
:   Load Dialogue written in text file from `path`.

    ``` title="res://convo.dlg.txt"

    Ritsu:
        "Remember to save the file as *.dlg.txt"

    ```

    ```gdscript
    var dlg = Dialogue.new('res://convo.dlg.txt')
    ```

<hr>

### new { .func .return .Dialogue params="source-string" }
:   Create a new Dialogue by parsing `string` directly. Write the Dialogue with triple quotation marks (`"""`).
    ```gdscript
    var dlg = Dialogue.new("""

    Dia:
        "This is still not a recommended
        way to do it"

    """)
    ```

<hr>

## Utilities

### get_length { .func .return .int }

:   Returns how many lines in the Dialogue.
    ??? example
        ``` title="res://convo.dlg.txt"
        Ritsu:
            ""
        ```

<hr>

### get_word_count { .func .return .int }

:    Returns word count from the Dialogue. Variable placeholder like `{username}` counts as 1 word. Any words separated by `.`, `,` or `;` are counted as separate words.
    ??? example
        ``` title="res://convo.dlg.txt"

        Ritsu:
            "..."

        Dia:
            "..."

        ```

        ```gdscript
        print(
            Dialogue.load('res://convo.dlg.txt').get_word_count()
        )
        # Will output: 6
        ```

<hr>

## Converter

### get_humanized { .func .return .string }

:   Returns the entire Dialogue in a human-readable `string`. Optionally, you can pass a [variables](../../stage/references/properties.md#variables) dictionary as an argument if variables are used. If none is passed, but the Dialogue used variables, it will left the placeholder as is.

    ??? example
        ```gdscript
        var dlg = Dialogue.new("""

        Dia:
            "The addon include classes such as:{d = 0.7}
            Dialogue,{d = 0.6}
            Stage,{d = 0.6}
            Theatre,{d = 0.6}
            and TheatrePlugin.
            "

        """)

        print(dlg.get_humanized())
        #   Dia:
        #       "The addon include classes such as: Dialogue, Stage, Theatre, and TheatrePlugin."
        ```

<hr>

### to_json { .func .return .int params="path-string" }

:   Save the Dialogue resource to JSON in the specified `path`.
    ```gdscript
    dlg.to_json('user://convo.dlg.txt')
    ```