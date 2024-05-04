# Properties

!!! note
    This page might not cover every single properties in the `Stage` class

## Configurations

### dialogue_label { .var .return .DialogueLabel }

:   `DialogueLabel` node that will be used to render the `Dialogue`. This needs to be set when creating `Stage` object.

### actor_label { .var .return .Label }

:   `Label` node that will be used to display actor's name. Unlike `dialogue_label`, this property is optional.

### speed_scale { .var .return .float }

:   The speed scale in `float`, of how fast the dialogue is rendered. Default to `1.0`.

### allow_skip { .var .return .bool }

:   Allow skipping Dialogue render if `progress()` is called while the Dialogue is being rendered. Default to `true`.

### allow_cancel { .var .return .bool }

:   Allow canceling or exiting Dialogue using `reset()` while the Dialogue is still running. Default to `true`.

### allow_func { .var .return .bool }

:   Allow calling functions written in the Dialogue. Default to `true`.

### caller { .var .return .Dictionary }

:   `Dictionary` of callers. With the identifier string as the key, and its assigned Node as the value.

    !!! danger
        **Do not** modify this property directly. Instead, use `add_caller()`, `merge_caller()`, or `remove_caller()`.