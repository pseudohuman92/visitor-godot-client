extends Control

const BASE_CARD_WIDTH := 200.0
const MIN_FONT_SCALE := 0.55
const MAX_FONT_SCALE := 1.5
const MIN_FONT_SIZE := 9
const INLINE_ICON_SCALE := 1.5
const LABEL_BASE_SIZE_META := "card_base_label_font_size"
const LAST_SCALE_META := "card_last_font_scale"
const ABILITY_AREA_RATIO := 0.30
const MIN_ABILITY_FONT_SIZE := 5
const SHORT_PANEL_VERTICAL_MARGIN_RATIO := 0.28
const LONG_PANEL_VERTICAL_MARGIN_RATIO := 0.10
const PANEL_HORIZONTAL_MARGIN_RATIO := 0.06
const LONG_ABILITY_STYLE = preload("res://src/Themes/AbilityBox.tres")
const SHORT_ABILITY_STYLE = preload("res://src/Themes/AbilityBoxShort.tres")
enum AbilityFitStage { IDLE, PREPARE, SELECT_PANEL, FIT_TEXT }
var _title_label: Label
var _ability_panel: PanelContainer
var _ability_label: RichTextLabel
var _ability_fit_stage := AbilityFitStage.IDLE
var _ability_fit_font_size := 0
var _ability_fit_revision := 0
var _long_ability_style: StyleBoxTexture
var _short_ability_style: StyleBoxTexture

func _ready():
	set_process(false)
	resized.connect(_apply_card_font_scale)
	_title_label = find_child("Name", true, false) as Label
	if _title_label:
		_title_label.resized.connect(_queue_title_fit)
	_ability_panel = find_child("AbilityPanel", true, false) as PanelContainer
	_ability_label = _ability_panel.find_child("Ability", true, false) as RichTextLabel if _ability_panel else null
	if _ability_panel and _ability_label:
		_long_ability_style = LONG_ABILITY_STYLE.duplicate()
		_short_ability_style = SHORT_ABILITY_STYLE.duplicate()
		_ability_panel.size_flags_vertical = Control.SIZE_FILL
		_ability_panel.resized.connect(_queue_ability_fit)
		_ability_label.fit_content = false
		_ability_label.threaded = false
		_ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ability_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_ability_label.clip_contents = true
		_ability_label.add_theme_color_override("default_color", Color.BLACK)
		_ability_label.resized.connect(_queue_ability_fit)
		if _ability_label.has_signal("content_changed"):
			_ability_label.connect("content_changed", _queue_ability_fit)
	call_deferred("_apply_card_font_scale")

func _apply_card_font_scale():
	if size.x <= 0.0:
		return
	if _ability_panel:
		_ability_panel.custom_minimum_size.y = roundf(size.y * ABILITY_AREA_RATIO)
		_queue_ability_fit()
	var scale_factor = clampf(size.x / BASE_CARD_WIDTH, MIN_FONT_SCALE, MAX_FONT_SCALE)
	if has_meta(LAST_SCALE_META) and is_equal_approx(get_meta(LAST_SCALE_META), scale_factor):
		_fit_title_to_line(scale_factor)
		return
	set_meta(LAST_SCALE_META, scale_factor)
	_scale_descendant_text(self, scale_factor)
	_fit_title_to_line(scale_factor)

func _queue_ability_fit() -> void:
	if not is_inside_tree():
		return
	_ability_fit_revision += 1
	_ability_fit_stage = AbilityFitStage.PREPARE
	set_process(true)

func _process(_delta: float) -> void:
	if not is_instance_valid(_ability_panel) or not is_instance_valid(_ability_label):
		_stop_ability_fit()
		return
	match _ability_fit_stage:
		AbilityFitStage.PREPARE:
			if _ability_panel.size.x <= 0.0 or _ability_panel.size.y <= 0.0:
				return
			var revision = _ability_fit_revision
			_update_ability_style_margins(_short_ability_style, SHORT_PANEL_VERTICAL_MARGIN_RATIO)
			_update_ability_style_margins(_long_ability_style, LONG_PANEL_VERTICAL_MARGIN_RATIO)
			var scale_factor = clampf(size.x / BASE_CARD_WIDTH, MIN_FONT_SCALE, MAX_FONT_SCALE)
			var base_size: int = _ability_label.get_meta("card_base_normal_font_size", 16)
			_ability_fit_font_size = maxi(MIN_ABILITY_FONT_SIZE, roundi(base_size * scale_factor))
			_set_ability_font_size(_ability_fit_font_size)
			if revision == _ability_fit_revision:
				_ability_fit_stage = AbilityFitStage.SELECT_PANEL
		AbilityFitStage.SELECT_PANEL:
			if _ability_label.size.x <= 0.0 or _ability_label.size.y <= 0.0:
				return
			var use_short_panel = _ability_label.get_content_height() <= _ability_panel.size.y * (1.0 - 2.0 * SHORT_PANEL_VERTICAL_MARGIN_RATIO) - 2.0
			var style = _short_ability_style if use_short_panel else _long_ability_style
			if _ability_panel.get_theme_stylebox("panel") != style:
				_ability_panel.add_theme_stylebox_override("panel", style)
				_ability_fit_stage = AbilityFitStage.PREPARE
			else:
				_ability_fit_stage = AbilityFitStage.FIT_TEXT
		AbilityFitStage.FIT_TEXT:
			if _ability_label.size.y <= 0.0:
				_ability_fit_stage = AbilityFitStage.PREPARE
			elif _ability_label.get_content_height() <= _ability_label.size.y - 2.0 or _ability_fit_font_size <= MIN_ABILITY_FONT_SIZE:
				_stop_ability_fit()
			else:
				_ability_fit_font_size -= 1
				_set_ability_font_size(_ability_fit_font_size)

func _stop_ability_fit() -> void:
	_ability_fit_stage = AbilityFitStage.IDLE
	set_process(false)

func _update_ability_style_margins(style: StyleBoxTexture, vertical_ratio: float) -> void:
	var horizontal_margin = roundf(_ability_panel.size.x * PANEL_HORIZONTAL_MARGIN_RATIO)
	var vertical_margin = roundf(_ability_panel.size.y * vertical_ratio)
	for side in [SIDE_LEFT, SIDE_RIGHT]:
		if not is_equal_approx(style.get_content_margin(side), horizontal_margin):
			style.set_content_margin(side, horizontal_margin)
	for side in [SIDE_TOP, SIDE_BOTTOM]:
		if not is_equal_approx(style.get_content_margin(side), vertical_margin):
			style.set_content_margin(side, vertical_margin)

func _set_ability_font_size(font_size: int) -> void:
	for size_name in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
		_ability_label.add_theme_font_size_override(size_name, font_size)
	if _ability_label.has_method("set_icon_size"):
		_ability_label.set_icon_size(roundi(font_size * INLINE_ICON_SCALE))

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
