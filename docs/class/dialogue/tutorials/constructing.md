# Loading the Dialogue

Load your written Dialogue with `Dialogue.load()` and pass the absolute path of the text file as the parameter.

```gdscript
var dlg = Dialogue.load("res://intro.dlg")
```

You can also create it in the script with `Dialogue.new()`. And then write the dialogue directly using triple quotation marks `"""`.

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

## Compiled resources
You might notice an additional resources right besides the written Dialogue files after running/testing the project. Those are the compiled Dialogue resources.

```
res:\\
  ├─ intro.dlg
  └─ intro.dlg.res  <- compiled Dialogue
```

If you're using version control like git, make sure that `*.dlg.res` and `*.dlg.tres` files are ignored.

!!! Note
    Theatre already ignore these resources in `.gitignore` automatically, but still make sure to check your `.gitignore` file.
