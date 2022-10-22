tool
extends EditorPlugin

const Dock = preload("res://addons/get_animplayer_frame_millis/Dock.tscn")
var dock = null

func _enter_tree():
	# Add the main panel
	dock = Dock.instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)

func handles(object: Object) -> bool:
	return object is AnimationPlayer

## nodo seleccionado
func edit(object: Object) -> void:
	dock.Anim = object
	dock.update_anim_list()

func _exit_tree():
	if dock != null:
		remove_control_from_docks(dock)
		dock.free()
		dock = null
