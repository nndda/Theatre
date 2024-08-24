@icon("res://addons/Theatre/assets/icons/Theatre.svg")
extends Node

class Debug extends RefCounted:
    static func format_stack(stack_arr : Array[Dictionary], indent : String = "  ") -> String:
        var output : String = ""
        for n in stack_arr.size():
            output += "%s %d: {source}:{line} @ {function}()\n".format(stack_arr[n]) % [indent, n]
        return output

func _enter_tree() -> void:
    DialogueParser._initialize_regex()

    var tree := get_tree()

    for singleton in Engine.get_singleton_list():
        Stage._caller_built_in[singleton] = Engine.get_singleton(singleton)

    for autoload in tree.root.get_children():
        if autoload != tree.current_scene:
            Stage._caller_built_in["%s" % autoload.name] = autoload

func print_silly() -> void:
    print("silly :p")
