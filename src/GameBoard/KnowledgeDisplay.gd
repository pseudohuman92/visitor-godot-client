extends HBoxContainer

var _pool = {}
var _selection = []
var _initialized = false
var _selecting = false

func update_pool(knowledge):
	var desired = {}
	for group in knowledge:
		desired[CS.to_knowledge_string(group.get_knowledge())] = group.get_count()
	for code in ["B", "G", "P", "R", "Y"]:
		if not _initialized or _pool.get(code) != desired.get(code):
			var container = find_child(code + "Container")
			container.visible = desired.has(code)
			if desired.has(code):
				find_child(code + "Label").text = str(desired[code])
				var border = container.get_theme_stylebox("panel").duplicate()
				border.border_color = Color.TRANSPARENT
				container.add_theme_stylebox_override("panel", border)
	_pool = desired
	_initialized = true

func _process(_delta):
	# Study choices change locally between snapshots; normal pools are push-updated.
	if not name.contains("KnowledgeSelection"):
		return
	var selecting = SS.selecting_for == SS.selection_type.KNOWLEDGE
	var desired = SS.selection_targets.duplicate() if selecting else []
	if _initialized and selecting == _selecting and desired == _selection:
		return
	visible = selecting
	if selecting:
		SS.selection_message = "Select a knowledge to gain."
	for code in ["B", "G", "P", "R", "Y"]:
		var container = find_child(code + "Container")
		container.visible = selecting and desired.has(CS.to_knowledge_type(code))
		if container.visible:
			find_child(code + "Label").text = ""
			var border = container.get_theme_stylebox("panel").duplicate()
			border.border_color = Color.GREEN_YELLOW
			container.add_theme_stylebox_override("panel", border)
	_selection = desired
	_selecting = selecting
	_initialized = true
