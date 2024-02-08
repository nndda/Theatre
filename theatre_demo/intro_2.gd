extends Node2D

var stage = Stage.new({
    container_name = $DialogueContainer/MarginContainer/VBoxContainer/Name,
    container_body = $DialogueContainer/MarginContainer/VBoxContainer/Body
})
var epic_dialogue : Dialogue

# Loading Dialogue resources via `Dialogue.new()` can take some time depending on how long the text file is.
# You can use `Dialogue.crawl()' to preload all the Dialogue files in your project.
# Which then you can access through `Dialogue.load()` a lot faster.
func _init():
    Dialogue.crawl()

# NOTE: `Dialogue.crawl()` have to run BEFORE loading the dialogue

func _ready():
    epic_dialogue = Dialogue.load("res://theatre_demo/demo_dialogue.en.txt")

func _input(event):
    if event.is_action_pressed("space"):
        stage.progress()
