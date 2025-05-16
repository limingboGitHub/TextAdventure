class_name LogTool

"""
日志打印工具
"""

var tag := ""
var tag2 := ""

var last_time = 0.0

func init(input_tag: String, input_tag2: String = ""):
	self.tag = input_tag
	self.tag2 = input_tag2


func print_time(content: String):
	# var time = Time.get_unix_time_from_system()
	# if show_time_diff:
	#     if last_time != 0.0:
	#         var sub_time = time - last_time
	#     last_time = time
	print(tag, " ", tag2, " ", content, ":", Time.get_unix_time_from_system())


func print_finish(content: String):
	print(tag, " ", tag2, " ", content, " finished:", Time.get_unix_time_from_system())

func print_time_cost(content):
	var time = Time.get_unix_time_from_system()
	print(tag," ", tag2," ",content,":", time)
	if last_time!= 0.0:
		var sub_time = time - last_time
		print(tag," ", tag2," ",content,"耗时:", sub_time)
	last_time = time
