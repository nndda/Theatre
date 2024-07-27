@tool
extends RichTextEffect
class_name TextEffect1

var bbcode = "fx1"

const COL := Color("#bff1ff")
var col_fx := COL.darkened(0.2)
var f : float

func _process_custom_fx(char_fx : CharFXTransform) -> bool:
    f = sin(char_fx.relative_index / 3.15 - char_fx.elapsed_time * 9.25)
    char_fx.color = COL.lerp(col_fx, f)
    char_fx.offset.y = f * 1.25
    return true
