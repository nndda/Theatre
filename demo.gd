extends Node


var preferences : Dictionary = {
    "text_speed"  : 1.0,
}

var allow_progress : bool = true

var dialogue_current : Dialogue
var text_length : int
var typing_tween : Tween
var typing_duraton : float

@export_node_path("Label", "RichTextLabel") var character_name_
@onready var character_name : Control = get_node( character_name_ )

@export_node_path("Label", "RichTextLabel") var dialogue_box_
@onready var dialogue_box : Control = get_node( dialogue_box_ )

func _input( event : InputEvent ):
    if event.is_action_pressed("ui_accept"):
        emit_signal("trigger_progress")

func _ready():
    connect( "trigger_progress", Callable( self, "trig_progress" ) )
    typing_tween = create_tween()
    Dialogue.crawl()
    start( Dialogue.compiled["res://demo_dialogue.en.dlg.txt"] )

func start( dialogue_file : Dialogue, preprogress : int = 0 ) -> void:
    dialogue_file.step = 0
    dialogue_current = dialogue_file
    dialogue_current.connect( "set_updated", Callable( self, "step_progress" ) )
    dialogue_current.connect( "finished", Callable( self, "step_end" ) )
    dialogue_current.progress( preprogress )

func stop() -> void:
    pass

signal trigger_progress
func trig_progress() -> void:
    if dialogue_current != null and allow_progress:

        if typing_tween.is_running():
            typing_tween.stop()
            dialogue_box.visible_ratio = 1.0

        else:
            dialogue_current.progress()
            typing_tween = create_tween()
            typing_tween.tween_property(
                dialogue_box, "visible_characters",
                text_length, typing_duraton
            ).set_trans(  Tween.TRANS_LINEAR
            ).set_ease(   Tween.EASE_IN_OUT
            ).from( 0 as int )

func step_progress(
    step_count  : int,
    step_set    : Dictionary ) -> void:
    var step_func : Dictionary = step_set["func"]

    print("\n  ",step_count,"  ",step_set)

    text_length         = step_set["dlg"].length() as int
    typing_duraton      = ( 0.025 * text_length ) * preferences["text_speed"]
    dialogue_box.text   = step_set["dlg"]
    character_name.text = step_set["name"]

    if step_func.size() > 0:
        for hndler in step_func.keys():
            for fn in step_func[hndler].size():

                print(
                    step_func[hndler][fn][0], " ",
                    step_func[hndler][fn][1] )

#                get_handler( hndler ).callv(
#                    step_func[hndler][fn][0],
#                    step_func[hndler][fn][1] )
