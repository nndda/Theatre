## @deprecated: `Stage` class is deprecated, use `TheatreStage` instead.
class_name Stage
extends TheatreStage

## Backward compatibility for `Stage`-named nodes.

func _enter_tree() -> void:
    push_warning("`Stage` class is deprecated, use `TheatreStage` instead.")
    super()
