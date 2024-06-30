@icon("res://addons/Theatre/assets/icons/Theatre.svg")
extends Node

class Debug extends RefCounted:
    static func format_stack(stack_arr : Array[Dictionary], indent : String = "  ") -> String:
        var output : String = ""
        for n in stack_arr.size():
            output += "%s %d: {source}:{line} @ {function}()\n".format(stack_arr[n]) % [indent, n]
        return output

func print_silly() -> void:
    print("silly :p")
