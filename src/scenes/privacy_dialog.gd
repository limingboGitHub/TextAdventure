@tool
extends Control

const json_file = "res://addons/GodotPrivacyPlugin/config.json"

@onready var panel = $ColorRect/Panel
@onready var label = $ColorRect/Panel/ScrollContainer/Label
@onready var agree_btn = $ColorRect/Panel/AgreeButton
@onready var cancel_btn = $ColorRect/Panel/RefuseButton

signal privacy_policy_agreed()

signal privacy_policy_refused()


func loadJson():
	var file = FileAccess.open(json_file, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	return JSON.parse_string(content)


func loadText(entity):
	var file = FileAccess.open(entity.textPath, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		label.text = content
		file.close()


func loadPanel():
	var entity = loadJson()
	loadText(entity)
	label.label_settings.set_font_color(Color(entity.textColor))
	panel.get("theme_override_styles/panel").set("bg_color",Color(entity.contentColor))
	agree_btn.get("theme_override_styles/normal").set("bg_color",Color(entity.agreeBtn.color))
	agree_btn.set("theme_override_colors/font_color",Color(entity.agreeBtn.textColor))
	cancel_btn.get("theme_override_styles/normal").set("bg_color",Color(entity.cancelBtn.color))
	cancel_btn.set("theme_override_colors/font_color",Color(entity.cancelBtn.textColor))


func _on_close_requested() -> void:
	hide()


func _on_about_to_popup() -> void:
	loadPanel()


func _ready() -> void:
	loadPanel()


func _on_agree_button_pressed() -> void:
	privacy_policy_agreed.emit()
	hide()


func _on_refuse_button_pressed() -> void:
	privacy_policy_refused.emit()


func _on_go_back_requested() -> void:
	privacy_policy_refused.emit()
