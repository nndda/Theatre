extends Node

var speed_scale : float = 1.0

var lamg : String = ""

func _enter_tree() -> void:
    # TODO: Detect locale changes
    # So that the dialogue changes are also updated accordingly
    TranslationServer.add_user_signal("locale_changed", [
        {"name" : "locale", "type" : TYPE_STRING}
    ])

# TODO: would be nice if this can be triggered when `TranslationServer.set_locale()` is called
static func set_locale(lang : String = "") -> void:
    if TranslationServer.has_user_signal(&"locale_changed"):
        TranslationServer.emit_signal(&"locale_changed", lang)
    else:
        push_error("Signal `%s` not defined" % "locale_changed")
