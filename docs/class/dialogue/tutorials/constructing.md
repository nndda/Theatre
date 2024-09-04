# Loading the Dialogue

Load your written Dialogue with `Dialogue.load()` or `load()`, and pass the absolute path of the text file as the parameter.

```gdscript
var dlg = Dialogue.load("res://intro.dlg")
# or
var dlg = load("res://intro.dlg")
```

Both `load()` and `Dialogue.load()` are pretty much the same. But `Dialogue.load()` provides type safety, without having to cast or explicitly set the `Dialogue` type.

You can also write Dialogue in the script directly with `Dialogue.new()` using triple quotation marks `"""`.

```gdscript
var dlg = Dialogue.new("""

Dia:
    "For performance reason, don't do this."

:
    "The note below should explains further."

""")
```

!!! note
    Parsing the written Dialogue text is a heavy process. Write the Dialogue in a text file, and load it using `load()`, instead of creating it directly in the script using `new()`.
