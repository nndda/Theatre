@icon("res://addons/Theatre/assets/icons/Theatre.svg")
extends Node

var speed_scale : float = 1.0

var lamg : String = ""
var default_lang : String = "en"

signal locale_changed(lang : String)

# TODO: would be nice if this can be triggered when `TranslationServer.set_locale()` is called
func set_locale(lang : String = "") -> void:
    locale_changed.emit(lang)

func print_silly() -> void:
    print("silly :p")
