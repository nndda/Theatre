# Constructing the Dialogue

You can create a Dialogue variable by using `Dialogue.load()` and pass the absolute path of the text file as the parameter.

```gdscript
var dlg = Dialogue.load("res://intro.dlg.txt")
```

You can also create it in the script with `Dialogue.new()`. And then write the dialogue directly using triple quotation marks `"""` as the parameter.

```gdscript
var dlg = Dialogue.new("""

Dia:
    "Hello, world!"

""")
```

!!! note
    Its recommended to create Dialogue variable via `load()` instead of creating it directly with `new()`. Because parsing the text strings is quite a heavy process, and may lead to performance issue.