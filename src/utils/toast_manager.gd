extends Node2D

## 全局的提示框管理类

signal toast_added(msg: String)


func add_toast(msg: String) -> void:
	toast_added.emit(msg)
