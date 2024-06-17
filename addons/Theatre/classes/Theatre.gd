@icon("res://addons/Theatre/assets/icons/Theatre.svg")
extends Object
class_name Theatre

class Debug extends RefCounted:
    static func format_stack(stack_arr : Array[Dictionary], indent : String = "  ") -> String:
        var output : String = ""
        for n in stack_arr.size():
            output += "%s %d: {source}:{line} @ {function}()\n".format(stack_arr[n]) % [indent, n]
        return output

static var speed_scale : float = 1.0

static var lamg : String = ""
static var default_lang : String = "en"

static func print_silly() -> void:
    print("silly :p")
