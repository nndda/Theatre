---
title: Dialogue Class Reference
---
# Dialogue

**Inherits:** [Resource] < [RefCounted] < [Object]

## Description

Dialogue as a resource that have been parsed from the written dialogue text file. Load it from a `*.dlg` file, or from a [String] directly with `.new()`. 

```gd
var dlg := Dialogue.load("res://my_dialogue.dlg")
# or
var dlg := Dialogue.new("""
  Godette:
    "Hello, world!"
""")
```


## Methods

| Returns | Function |
| ---: | :--- |
m [int] get_length()
Returns the dialogue line count.


m [String] get_source_path()
Returns the path of written dialogue text file source. If the dialogue is created in a script using `new()`, it will returns the script's path and the line number from where the dialogue is created (e.g. `res://script.gd:26`).


m [Dialogue] load( path: [String] ) <small>static</small>
Load written dialogue text file from `path`.



## Method Descriptions

<!-- method descriptions -->
