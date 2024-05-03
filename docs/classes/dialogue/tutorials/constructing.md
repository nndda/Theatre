# Loading the Dialogue

You can create Dialogue in the script by using `Dialogue.load()` and pass the absolute path of the text file as the parameter.

```gdscript
var dlg = Dialogue.load("res://intro.dlg.txt")
```

You can also create it in the script with `Dialogue.new()`. And then write the dialogue directly using triple quotation marks `"""` as the parameter.

```gdscript
var dlg = Dialogue.new("""

Dia:
    "This, however,
    is not a recommended
    way to do it"

""")
```

!!! note
    Parsing the Dialogue text is quite a heavy process. Its recommended to write a Dialogue in a text file, and load it using `load()`, instead of creating it directly in the script using `new()`.

## Compiled resources
You might notice an additional resources right besides the written Dialogue files, after running/testing the project. These are the compiled Dialogue resources.
```
res:\\
    | res://intro.dlg.txt
    \ res://intro.dlg.res  <- compiled Dialogue
```
If you're using version control like git, make sure that `*.dlg.res` files are ignored.
```
!!! Note
    Theatre already ignore these resources in `.gitignore`.
```