extends Control

const BASE_CARD_WIDTH := 200.0
const MIN_FONT_SCALE := 0.55
const MAX_FONT_SCALE := 1.5
const MIN_FONT_SIZE := 9
const LABEL_BASE_SIZE_META := "card_base_label_font_size"
const LAST_SCALE_META := "card_last_font_scale"

func _ready():
	resized.connect(_apply_card_font_scale)
	call_deferred("_apply_card_font_scale")

func _apply_card_font_scale():
	if size.x <= 0.0:
		return
	var scale_factor = clampf(size.x / BASE_CARD_WIDTH, MIN_FONT_SCALE, MAX_FONT_SCALE)
	if has_meta(LAST_SCALE_META) and is_equal_approx(get_meta(LAST_SCALE_META), scale_factor):
		return
	set_meta(LAST_SCALE_META, scale_factor)
	_scale_descendant_text(self, scale_factor)

func _scale_descendant_text(node: Node, scale_factor: float):
	for child in node.get_children():
		if child is Label:
			_scale_label(child, scale_factor)
		elif child is RichTextLabel:
			_scale_rich_text(child, scale_factor)
		_scale_descendant_text(child, scale_factor)

func _scale_label(label: Label, scale_factor: float):
	if label.label_settings:
		if not label.has_meta(LABEL_BASE_SIZE_META):
			var settings = label.label_settings.duplicate() as LabelSettings
			label.label_settings = settings
			label.set_meta(LABEL_BASE_SIZE_META, settings.font_size)
		var base_size: int = label.get_meta(LABEL_BASE_SIZE_META)
		label.label_settings.font_size = maxi(MIN_FONT_SIZE, roundi(base_size * scale_factor))
		return
	_scale_theme_font_size(label, "font_size", LABEL_BASE_SIZE_META, scale_factor)

func _scale_rich_text(label: RichTextLabel, scale_factor: float):
	for size_name in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
		_scale_theme_font_size(label, size_name, "card_base_" + size_name, scale_factor)
	if label.has_method("set_icon_size"):
		label.set_icon_size(label.get_theme_font_size("normal_font_size"))

func _scale_theme_font_size(control: Control, size_name: StringName, meta_name: String, scale_factor: float):
	if not control.has_meta(meta_name):
		var base_size = control.get_theme_font_size(size_name)
		if base_size <= 0:
			base_size = 16
		control.set_meta(meta_name, base_size)
	var base_size: int = control.get_meta(meta_name)
	control.add_theme_font_size_override(size_name, maxi(MIN_FONT_SIZE, roundi(base_size * scale_factor)))
