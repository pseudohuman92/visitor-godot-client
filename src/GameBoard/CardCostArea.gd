extends VBoxContainer

const KNOWLEDGE_ICON_SIZE := 36.0
const KNOWLEDGE_STEP := KNOWLEDGE_ICON_SIZE * 0.5
var children = []
var _knowledge_stack: Control

func update(cost, knowledge):
	for child in children:
		if is_instance_valid(child):
			child.get_parent().remove_child(child)
			child.queue_free()
	children.clear()
	alignment = BoxContainer.ALIGNMENT_BEGIN
	CS.set_cost_texture(find_child("CostBG"), cost)
	if not is_instance_valid(_knowledge_stack):
		_knowledge_stack = Control.new()
		_knowledge_stack.name = "KnowledgeStack"
		_knowledge_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_knowledge_stack)
	var index = 0
	for group in knowledge:
		var code = CS.to_knowledge_string(group.get_knowledge())
		var template = find_child(code + "BG", false)
		if template == null:
			continue
		for i in group.get_count():
			var symbol = template.duplicate()
			symbol.name = "KnowledgeIcon%d" % index
			symbol.set_anchors_preset(Control.PRESET_TOP_LEFT)
			symbol.custom_minimum_size = Vector2.ONE * KNOWLEDGE_ICON_SIZE
			symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			symbol.position = Vector2(0, index * KNOWLEDGE_STEP)
			symbol.size = Vector2.ONE * KNOWLEDGE_ICON_SIZE
			symbol.z_index = index + 1
			_ignore_input(symbol)
			_knowledge_stack.add_child(symbol)
			symbol.show()
			children.append(symbol)
			index += 1
	_knowledge_stack.custom_minimum_size = Vector2(KNOWLEDGE_ICON_SIZE, KNOWLEDGE_ICON_SIZE + (index - 1) * KNOWLEDGE_STEP) if index > 0 else Vector2.ZERO
	_knowledge_stack.visible = index > 0
	show()

func _ignore_input(node):
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_input(child)
