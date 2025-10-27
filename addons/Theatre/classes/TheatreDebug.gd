class_name  TheatreDebug
extends RefCounted

static func log_err(
    msg : String,
    stack_offset : int = 0,
    stack : Array[Dictionary] = [],
    #is_warning : bool = false,
    ) -> void:
    #if is_warning:
        #push_warning(msg)
    #else:
        #push_error(msg)

    if stack_offset == -1:
        printerr(msg)
        return

    if stack.is_empty():
        stack = get_stack()
        stack_offset += 1

    printerr(
        msg + "\n" + format_stack(stack, stack_offset)
    )

static func format_stack(stack_arr : Array[Dictionary], offset : int = 0 ) -> String:
    var output : String = "Stack trace:\n"
    stack_arr = stack_arr.slice(offset)

    var stack_size : int = stack_arr.size()
    for n in stack_size:
        output += "%s%d: {source}:{line} @ {function}()".format(stack_arr[n]) % [DialogueParser.INDENT_2, n] + (
            DialogueParser.NEWLINE if n != stack_size - 1 else DialogueParser.EMPTY
        )
    return output
