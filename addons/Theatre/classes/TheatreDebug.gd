class_name  TheatreDebug
extends RefCounted

static func log_err(
    msg : String,
    stack : Array[Dictionary] = [],
    #is_warning : bool = false,
    ) -> void:
    #if is_warning:
        #push_warning(msg)
    #else:
        #push_error(msg)

    printerr(
        "Theatre: " + msg + "\n" + format_stack(
            stack if not stack.is_empty() else get_stack()
        )
    )

static func format_stack(stack_arr : Array[Dictionary]) -> String:
    var output : String = "Stack trace:\n"

    var stack_size : int = stack_arr.size()
    for n in stack_size:
        output += "%s%d: {source}:{line} @ {function}()".format(stack_arr[n]) % [DialogueParser.INDENT_2, n] + (
            DialogueParser.NEWLINE if n != stack_size - 1 else DialogueParser.EMPTY
        )
    return output
