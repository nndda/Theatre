# DialogueLabel

**Inherits:** [RichTextLabel] < [Control] < [CanvasItem] < [Node] < [Object]


## Description
A custom [RichTextLabel] made for displaying and rendering [Dialogue]. For most part, dialogue rendering are already handled by [TheatreStage].


## Properties

| Returns | Property | Default |
| ---: | :--- | :--- |
p   [float]     characters_draw_tick   `0.015`
The time in second for each character in the dialogue to be rendered.


p   [bool]     rendering_paused   `false`
If `true`, text rendering will be paused. Progressing dialogue won't work until [rendering_paused] is set to false, or [resume_render()] is called. 

See also [pause_render()] and [resume_render()].



## Methods

| Returns | Function |
| ---: | :--- |
m `void`    clear_render()
Stop rendering dialogue, and clear the displayed text.


m [TheatreStage] get_stage()
Returns the [TheatreStage] that is currently controling the `DialogueLabel`.


m [bool] is_rendering()
Returns `true` if the `DialogueLabel` is in the process of rendering dialogue.


m `void` pause_render()
Pause text rendering. The same as setting [rendering_paused] to `true`.


m `void` rerender()
Restart the rendering. Written dialogue functions will also be re-called.


m `void` resume_render()
Continue paused text rendering. The same as setting [rendering_paused] to `false`.


m `void` set_stage( stage: [TheatreStage] )
Set the [TheatreStage] that will be used to control the DialogueLabel. If there's already a [TheatreStage] set, this will remove the previous [TheatreStage.dialogue_label](/class/theatrestage/references/#dialogue_label).


m `void` start_render()
Start the rendering of the current dialogue line.



## Property Descriptions

<!-- property descriptions -->

## Method Descriptions

<!-- method descriptions -->
