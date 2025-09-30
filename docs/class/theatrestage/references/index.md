# TheatreStage

**Inherits:** [Node] < [Object]

## Description

Display, run, control, and configure [Dialogue], reference UIs, nodes, and scopes that will be used to display the dialogue.

[TheatreStage] connects your [Dialogue] with the [DialogueLabel], and the rest of your project. This is where you configure & control your dialogue, and manage variables & scopes in your written dialogue.

## Properties

| Returns | Property | Default |
| ---: | :--- | :--- |
p   [int]     actor_label   null
Optional [Label] node that displays the actors of the current line of [current_dialogue].


p   [bool]    allow_cancel   true
Allow cancelling/stopping [Dialogue] using [cancel()] or [reset()].


p   [bool]    allow_func     true
Allow calling functions written in the [Dialogue].


p   [bool]    allow_skip    true
Allow skipping [Dialogue] or the [dialogue_label] text rendering. See [progress()].


p   [Dialogue]    current_dialogue  null
[Dialogue] resource to be used by the `TheatreStage` instance. Will be set when passing a [Dialogue] to [start()].
<br>
!!! note
    [current_dialogue] will be set to `null`, when [cancel()] or [reset()] is called with [keep_dialogue] set to `false` (default), and when `TheatreStage` is finished running.


p [DialogueLabel] dialogue_label null
The [DialogueLabel] node that will be used to displays the [current_dialogue]. This is **required** to be set before running a dialogue.


p   [Dictionary][[String], [Node]]   scope_nodes   []
[Node] scopes that are in the scene tree. The key is the scope ID that would be used in the written dialogue. The nodes will be registered as scopes when the scene is ready.


p [float] speed_scale 1.0
The speed scale of the [dialogue_label] text rendering.


p [Dictionary][[String], [Variant]] variables {}
[Dictionary] of user-defined variables used in the written [Dialogue].
<br>
!!! warning
    **DO NOT** modify variables directly, use methods such as [add_variable()], [merge_variables()], [remove_variable()], and [clear_variables()] instead.



## Methods

| Returns | Function |
| ---: | :--- |
m `void`    add_scope( id: [String], object: [Object] )
Add a scope used in the written dialogue. If `object` is a [Node], it will be removed automatically when its freed.
<br><br>
See also [remove_scope()], and [clear_scope()].


m `void`   cancel( keep_dialogue: [bool] = false)
Stop the dialogue, clear [dialogue_label] text render, and reset everything. Require [allow_cancel] to be `true`. Optionally, pass `true` to keep the [current_dialogue].


m `void` clear_scopes()
Remove all scopes of the `TheatreStage` instance.
<br><br>
See also [add_scope()], and [remove_scope()].


m `void` clear_variables()
Remove all variable defined in [variables].
<br><br>
See also [set_variable()], [merge_variables()], and [remove_variable()].


m [Dictionary] get_current_line()
Return the current dialogue line data. Will return empty [Dictionary], if [current_dialogue] is null, or if the `TheatreStage` instance is not currently running any [Dialogue].


m [int] get_line()
Return the current dialogue line number.


m [Dictionary] get_scopes()
Return assigned scopes that can be used in the written dialogue. Where the key is the ID of the scope, and the value is the [WeakRef] of the [Object] assigned.


m [bool] is_playing()
Returns true if the `TheatreStage` instance is currently running a [Dialogue].


m `void` jump_to( id: [Variant] )
Combined method of [jump_to_line()] and [jump_to_section()]. Can accept dialogue line number as [int], and dialogue section as [String].


m `void` jump_to_line( line: [int] )
Jump and progress to a specific [Dialogue] line. Return error if line is greater than [Dialogue] length. Will wrap if line is negative.


m `void` jump_to_section( section: [String] )
Jump to section defined in the written dialogue. 
<br><br>
See also Dialogue.get_sections().


m `void` merge_variables( vars: [Dictionary][[String], [Variant]] )
Set multiple variables as a [Dictionary][[String], [Variant]]. Will overwrite same variable name.  
<br><br>
See also [set_variable()], [remove_variable()], and [clear_variables()].


m `void` progress( skip_render: [bool] = false )
Progress the dialogue. Calling [progress()] with `skip_render` set to `false` while the [dialogue_label] is still rendering the text, will force it to finish the rendering instead of progressing. [skipped] will also be emitted. 
<br><br>
If the parameter `skip_render` is set to true, text rendering by the [DialogueLabel] will be skipped, and immediately progress to the next dialogue line. [skipped] will also be emitted. 
<br><br>
If [allow_skip] is set to `false`. Regardless of whether `skip_render` is `true` or `false`, the dialogue won't progress until [dialogue_label] has finished rendering.


m `void` remove_scope( id: [String] )
Remove a scope of the specified `id`.
<br><br>
See also [add_scope()], and [clear_scope()].


m `void` remove_variable( var_name: [String] )
Remove a variable of the name `var_name``.
<br><br>
See also [set_variable()], [merge_variables()], and [clear_variables()].


m `void` reset( keep_dialogue: [bool] = false )
Alias for the method `cancel()`.


m `void` restart()
Reset, and start over the dialogue. [started] will be emitted.


m `void` set_variable( var_name: [String], value: [Variant] )
Set a static variable.
<br><br>
See also [merge_variables()], and [remove_variable()], and [clear_variables()].


m `void` start( dialogue: [Dialogue] = null, to_section: [Variant] = 0 )

Start a dialogue. If `dialogue` is `null`, [current_dialogue] will be used instead. Optionally, set `to_section` parameter to start the dialogue at the specific line or section.



## Signals

- ### <code>cancelled()</code>

    Emitted when the dialogue progress is cancelled using [cancel()] or [reset()].

- ### <code>cancelled_at( line: [int], line_data: [Dictionary] )</code>

    Same as [cancelled], but with the line number and line data of the dialogue passed.

- ### <code>finished()</code>

    Emitted when the dialogue reached the end.

- ### <code>progressed()</code>

    Emitted when the dialogue progressed using [progress()]. This signal is also emitted when the dialogue is started using [start()].

- ### <code>progressed_at( line: [int], line_data: [Dictionary] )</code>

    Same as [progressed], but with the line number and line data of the dialogue passed.

- ### <code>skipped()</code>

    Emitted when the dialogue progress is skipped. See [progress()].

- ### <code>skipped_at( line: [int], line_data: [Dictionary] )</code>

    Same as [skipped], but with the line number and line data of the dialogue passed.

- ### <code>started()</code>

    Emitted when the dialogue started.

## Property Descriptions

<!-- property descriptions -->

## Method Descriptions

<!-- method descriptions -->
