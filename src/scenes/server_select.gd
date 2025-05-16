extends Control

var server_name := -1
var server_line := -1

signal server_selected(server_name: int, server_line: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 默认选中
	_select_server(11)
	_select_line(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_server_name_back_11_pressed() -> void:
	_select_server(11)
	$ServerLine.visible = true

func _select_server(index: int):
	get_node("ServersNameHBox/ServerNameBack" + str(index)).scale = Vector2(1.1,1.1)
	server_name = index
	
func _select_line(index: int):
	get_node("ServerLine/ServerLineHBox/ServerLine" + str(index)).scale = Vector2(1.1,1.1)
	server_line = index

func _on_ok_button_pressed() -> void:
	if server_name == -1:
		return
	if server_line == -1:
		return

	emit_signal("server_selected", server_name, server_line)
	visible = false


func _on_server_line_1_pressed() -> void:
	_select_line(1)
