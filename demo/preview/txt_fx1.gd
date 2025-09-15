@tool
extends RichTextEffect
class_name TextEffect1

var bbcode = "wavy"

const COL := Color("#8ae5ff")
var col_fx := COL.darkened(0.2)
var f : float

func _process_custom_fx(char_fx : CharFXTransform) -> bool:
    f = sin(char_fx.relative_index / 2.8 - char_fx.elapsed_time * 7.25)
    char_fx.color = COL.lerp(col_fx, f)
    char_fx.offset.y = f * 1.25
    return true
