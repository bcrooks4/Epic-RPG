extends Control

onready var fps_label := $"Debug Stats/FPS"

func _process(delta):
	fps_label.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS)).pad_zeros(3)
