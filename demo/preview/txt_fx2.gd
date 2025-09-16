@tool
extends RichTextEffect
class_name TextEffect2

var bbcode = "fx2"

var f : float

func _process_custom_fx(char_fx : CharFXTransform) -> bool:
    f = sin(char_fx.relative_index / 5.5 - char_fx.elapsed_time * 5.65)
    char_fx.transform = char_fx.transform.scaled_local(Vector2.ONE * remap(f, -1.0, 1.0, 0.9, 1.2))
    return true
