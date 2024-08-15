# Configuring Stage

<style>
    table code {
        white-space: nowrap;
    }
</style>

This page cover various configurations & properties for `Stage`. You can configure `Stage` through inspector, or in script.

`DialogueLabel` node is required to run a `Dialogue`. Unlike `actor_label`, which is optional.

| Property          | Type            | Default | Description                      |
| ----------------- | --------------- | ------  | -------------------------------- |
| `dialogue_label`  | `DialogueLabel` | `null`  | A `DialogueLabel` node used to display the dialogue body. This is the only required parameter.|
| `actor_label`     | `Label`         | `null`  | Optional `Label` node that displays actors of the current line of `current_dialogue`.|

## Configurations

| Property          | Type            | Default | Description                      |
| ----------------- | --------------- | ------  | -------------------------------- |
| `speed_scale`     | `float`         | `1.0`   | The speed scale of the dialogue_label text rendering.|
| `allow_skip`      | `bool`          | `true`  | Allow skipping `Dialogue` or the `dialogue_label` text rendering.|
| `allow_cancel`    | `bool`          | `true`  | Allow cancelling/stopping `Dialogue` with `cancel()` or `reset()`.|
| `allow_func`      | `bool`          | `true`  | Allow calling functions defined in the written `Dialogue`.|

## Dialogues

| Property          | Type            | Default | Description                      |
| ----------------- | --------------- | ------  | -------------------------------- |
| `variables`       | `Dictionary`    | `{}`    | `Dictionary` of user-defined variables used in the written `Dialogue`.|
| `caller_nodes`    | `Array[Node]`   | `[]`    | Node-based callers that are in the scene tree.|

### `caller_nodes`

While you can add callers with `add_caller()`, if the function caller is a `Node`, and is accessible in the scene tree where the `Stage` at, You can reference it directly in the inspector in `caller_nodes`. And the caller name/ID will use the node's name.

This approach is preferrable in such case. Not only that its more simpler compared to adding the caller through script(1), the caller `Node` will always be synced if it moved in the tree.
{ .annotate }

1.  !!! example "Like this"
    ```gdscript
    your_stage.add_caller("Portrait", $UI/DialogueContainer/Portrait)
    ```