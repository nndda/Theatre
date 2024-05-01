# Methods

!!! note
    This page might not cover every single methods in the `Dialogue` class

### load() {.class-reference-heading}
:   Load Dialogue from a text file.
    ``` title="res://convo.dlg.txt"

    Ritsu:
        "..."

    ```
    ```gdscript
    var dlg = Dialogue.new('res://convo.dlg.txt')
    ```

<hr>

### new() {.class-reference-heading}
:   Create a new Dialogue by parsing `string` directly. Write the Dialogue with triple quotation marks (`"""`)
    ```gdscript
    var dlg = Dialogue.new("""

    Ritsu:
        "..."

    """)
    ```

<hr>

### get_word_count() {.class-reference-heading}

:    Returns word count from the Dialogue as `int`. Variable placeholder like `{username}` counts as 1 word. Any words separated by `.`, `,` or `;` are counted as separate words.

    ```gdscript
    var dlg = Dialogue.new("""

    Ritsu:
        "..."

    Dia:
        "..."

    """)

    print(dlg.get_word_count()) # 6
    ```

<hr>

### get_length() {.class-reference-heading}

:   Returns how many lines in the Dialogue as `int`.

<hr>

### to_json() {.class-reference-heading}

:   Save the Dialogue resource to JSON in the specified `path`.
    ```gdscript
    dlg.to_json('user://convo.dlg.txt')
    ```