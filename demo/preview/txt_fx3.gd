@tool
extends RichTextEffect
class_name TextEffect3

var bbcode = "fx3"

var f : float
const SKEW := Transform2D(0.0, Vector2.ONE, .35, Vector2.ZERO)

func _process_custom_fx(char_fx : CharFXTransform) -> bool:
    char_fx.transform *= SKEW
    char_fx.color.a = 0.85
    return true
