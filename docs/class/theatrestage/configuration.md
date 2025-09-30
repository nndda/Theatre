# Configuring Stage
<!-- 
<style>
    table code {
        white-space: nowrap;
    }
</style>
 -->
This page cover configurations & properties for [TheatreStage]. You can configure them through the inspector dock, or in script.

[DialogueLabel] node is required to run a [Dialogue].

<!-- Unlike [`actor_label`](class/theatrestage/references/#actor_label), which is optional. -->

<!-- 
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
| `scope_nodes`    | `Array[Node]`   | `[]`    | Node-based scopes that are in the scene tree.|
 -->

### `scope_nodes`

While you can add scopes with [`add_scope()`](/class/theatrestage/references/#add_scope), if the scope is a [Node], and is accessible in the scene tree, you can reference it directly in the inspector in [`scope_nodes`](/class/theatrestage/references/#scope_nodes). The key is the ID of the scope that would be used in the written dialogue.

This approach is preferrable in such case. Not only that its more simpler compared to adding the scope through script(1), the scope [Node] will always be synced if it moved in the scene tree.
{ .annotate }

1.  !!! example "Like this"
    ```gdscript
    your_stage.add_scope("Portrait", $UI/DialogueContainer/Portrait)
    ```