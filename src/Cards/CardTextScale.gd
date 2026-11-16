extends Control

const BASE_CARD_WIDTH := 200.0
const MIN_FONT_SCALE := 0.55
const MAX_FONT_SCALE := 1.5
const MIN_FONT_SIZE := 9
const INLINE_ICON_SCALE := 1.5
const LABEL_BASE_SIZE_META := "card_base_label_font_size"
const LAST_SCALE_META := "card_last_font_scale"
var _title_label: Label

func _ready():
	resized.connect(_apply_card_font_scale)
	_title_label = find_child("Name", true, false) as Label
	if _title_label:
		_title_label.resized.connect(_queue_title_fit)
	call_deferred("_apply_card_font_scale")

func _apply_card_font_scale():
	if size.x <= 0.0:
		return
	var scale_factor = clampf(size.x / BASE_CARD_WIDTH, MIN_FONT_SCALE, MAX_FONT_SCALE)
	if has_meta(LAST_SCALE_META) and is_equal_approx(get_meta(LAST_SCALE_META), scale_factor):
		_fit_title_to_line(scale_factor)
		return
	set_meta(LAST_SCALE_META, scale_factor)
	_scale_descendant_text(self, scale_factor)
	_fit_title_to_line(scale_factor)

func _queue_title_fit():
	call_deferred("_fit_title_to_line", clampf(size.x / BASE_CARD_WIDTH, MIN_FONT_SCALE, MAX_FONT_SCALE))

func _fit_title_to_line(scale_factor: float):
	if not is_instance_valid(_title_label) or _title_label.size.x <= 0.0 or _title_label.text.is_empty():
		return
	var base_size: int
	if _title_label.has_meta(LABEL_BASE_SIZE_META):
		base_size = _title_label.get_meta(LABEL_BASE_SIZE_META)
	elif _title_label.label_settings:
		var settings = _title_label.label_settings.duplicate() as LabelSettings
		_title_label.label_settings = settings
		base_size = settings.font_size
		_title_label.set_meta(LABEL_BASE_SIZE_META, base_size)
	else:
		base_size = _title_label.get_theme_font_size("font_size")
		if base_size <= 0:
			base_size = 16
		_title_label.set_meta(LABEL_BASE_SIZE_META, base_size)
	var font_size = maxi(MIN_FONT_SIZE, roundi(base_size * scale_factor))
	var font: Font
	if _title_label.label_settings:
		font = _title_label.label_settings.font
	if font == null:
		font = _title_label.get_theme_font("font")
	if font == null:
		return
	var available_width = _title_label.size.x
	var style = _title_label.get_theme_stylebox("normal")
	if style:
		available_width -= maxf(0.0, style.get_content_margin(SIDE_LEFT))
		available_width -= maxf(0.0, style.get_content_margin(SIDE_RIGHT))
	while font_size > MIN_FONT_SIZE and font.get_string_size(_title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available_width:
		font_size -= 1
	if _title_label.label_settings:
		_title_label.label_settings.font_size = font_size
	else:
		_title_label.add_theme_font_size_override("font_size", font_size)

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
		label.set_icon_size(roundi(label.get_theme_font_size("normal_font_size") * INLINE_ICON_SCALE))

func _scale_theme_font_size(control: Control, size_name: StringName, meta_name: String, scale_factor: float):
	if not control.has_meta(meta_name):
		var base_size = control.get_theme_font_size(size_name)
		if base_size <= 0:
			base_size = 16
		control.set_meta(meta_name, base_size)
	var base_size: int = control.get_meta(meta_name)
	control.add_theme_font_size_override(size_name, maxi(MIN_FONT_SIZE, roundi(base_size * scale_factor)))
