extends Control

var data_player : DataPlayer

signal pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_role_show_pressed() -> void:
	pressed.emit()

func update_info(data: DataPlayer):
	$NameRoot/NameLabel.text = data.player_name
