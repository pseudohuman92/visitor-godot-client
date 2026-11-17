#!/usr/bin/env python3
"""Build a drop-in Godot Theme from the client's existing Barlow theme."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT.parents[2]
BASE = CLIENT / "src/Themes/MainTheme.tres"
OUTPUT = ROOT / "OMENKitTheme.tres"
FOCUS = ROOT / "theme/button_focus.tres"

REPLACEMENTS = {
    "assets/ui/styles/button_primary_default.tres": "assets/ui/kit/surfaces/buttons/ui_button_primary_default.tres",
    "assets/ui/styles/button_primary_hover.tres": "assets/ui/kit/surfaces/buttons/ui_button_primary_hover.tres",
    "assets/ui/styles/button_primary_pressed.tres": "assets/ui/kit/surfaces/buttons/ui_button_primary_pressed.tres",
    "assets/ui/styles/button_primary_disabled.tres": "assets/ui/kit/surfaces/buttons/ui_button_primary_disabled.tres",
    "assets/ui/styles/button_focus.tres": "assets/ui/kit/theme/button_focus.tres",
    "assets/ui/styles/field_default.tres": "assets/ui/kit/surfaces/fields/ui_field_default.tres",
    "assets/ui/styles/field_focus.tres": "assets/ui/kit/surfaces/fields/ui_field_focused.tres",
    "assets/ui/styles/panel_standard.tres": "assets/ui/kit/surfaces/panels/ui_panel_standard.tres",
    "assets/ui/styles/panel_tooltip.tres": "assets/ui/kit/surfaces/panels/ui_panel_tooltip.tres",
}

EXTRA_RESOURCES = '''[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_checkbox_checked.png" id="20_checked"]
[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_checkbox_unchecked.png" id="21_unchecked"]
[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_checkbox_disabled.png" id="22_check_disabled"]
[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_toggle_on.png" id="23_toggle_on"]
[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_toggle_off.png" id="24_toggle_off"]
[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_toggle_disabled.png" id="25_toggle_disabled"]
[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_slider_track_default.png" id="26_slider_track"]
[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_slider_fill_ash.png" id="27_slider_fill"]
[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_slider_thumb_default.png" id="28_slider_thumb"]
[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_slider_thumb_hover.png" id="29_slider_thumb_hover"]
[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_progress_track_default.png" id="30_progress_track"]
[ext_resource type="Texture2D" path="res://assets/ui/kit/controls/ui_progress_fill_success.png" id="31_progress_fill"]
[ext_resource type="StyleBox" path="res://assets/ui/kit/surfaces/tabs/ui_tab_default.tres" id="32_tab_default"]
[ext_resource type="StyleBox" path="res://assets/ui/kit/surfaces/tabs/ui_tab_hover.tres" id="33_tab_hover"]
[ext_resource type="StyleBox" path="res://assets/ui/kit/surfaces/tabs/ui_tab_selected.tres" id="34_tab_selected"]
[ext_resource type="StyleBox" path="res://assets/ui/kit/surfaces/tabs/ui_tab_disabled.tres" id="35_tab_disabled"]
[ext_resource type="StyleBox" path="res://assets/ui/kit/surfaces/buttons/ui_button_secondary_default.tres" id="36_secondary"]
[ext_resource type="StyleBox" path="res://assets/ui/kit/surfaces/buttons/ui_button_secondary_hover.tres" id="37_secondary_hover"]
[ext_resource type="StyleBox" path="res://assets/ui/kit/surfaces/buttons/ui_button_secondary_pressed.tres" id="38_secondary_pressed"]
[ext_resource type="StyleBox" path="res://assets/ui/kit/surfaces/buttons/ui_button_secondary_disabled.tres" id="39_secondary_disabled"]

'''

EXTRA_SUBRESOURCES = '''[sub_resource type="StyleBoxTexture" id="SliderTrack"]
texture = ExtResource("26_slider_track")
texture_margin_left = 8.0
texture_margin_top = 8.0
texture_margin_right = 8.0
texture_margin_bottom = 8.0

[sub_resource type="StyleBoxTexture" id="SliderFill"]
texture = ExtResource("27_slider_fill")
texture_margin_left = 8.0
texture_margin_top = 8.0
texture_margin_right = 8.0
texture_margin_bottom = 8.0

[sub_resource type="StyleBoxTexture" id="ProgressTrack"]
texture = ExtResource("30_progress_track")
texture_margin_left = 12.0
texture_margin_top = 12.0
texture_margin_right = 12.0
texture_margin_bottom = 12.0

[sub_resource type="StyleBoxTexture" id="ProgressFill"]
texture = ExtResource("31_progress_fill")
texture_margin_left = 12.0
texture_margin_top = 12.0
texture_margin_right = 12.0
texture_margin_bottom = 12.0

'''

EXTRA_PROPERTIES = '''
CheckBox/colors/font_color = Color(0.909804, 0.901961, 0.878431, 1)
CheckBox/fonts/font = ExtResource("12_condensed_semibold")
CheckBox/font_sizes/font_size = 18
CheckBox/icons/checked = ExtResource("20_checked")
CheckBox/icons/unchecked = ExtResource("21_unchecked")
CheckBox/icons/checked_disabled = ExtResource("22_check_disabled")
CheckBox/icons/unchecked_disabled = ExtResource("22_check_disabled")
CheckButton/icons/on = ExtResource("23_toggle_on")
CheckButton/icons/off = ExtResource("24_toggle_off")
CheckButton/icons/on_disabled = ExtResource("25_toggle_disabled")
CheckButton/icons/off_disabled = ExtResource("25_toggle_disabled")
HSlider/icons/grabber = ExtResource("28_slider_thumb")
HSlider/icons/grabber_highlight = ExtResource("29_slider_thumb_hover")
HSlider/styles/slider = SubResource("SliderTrack")
HSlider/styles/grabber_area = SubResource("SliderFill")
ProgressBar/styles/background = SubResource("ProgressTrack")
ProgressBar/styles/fill = SubResource("ProgressFill")
TabBar/styles/tab_unselected = ExtResource("32_tab_default")
TabBar/styles/tab_hovered = ExtResource("33_tab_hover")
TabBar/styles/tab_selected = ExtResource("34_tab_selected")
TabBar/styles/tab_disabled = ExtResource("35_tab_disabled")
OptionButton/colors/font_color = Color(0.909804, 0.901961, 0.878431, 1)
OptionButton/fonts/font = ExtResource("12_condensed_semibold")
OptionButton/font_sizes/font_size = 18
OptionButton/styles/normal = ExtResource("36_secondary")
OptionButton/styles/hover = ExtResource("37_secondary_hover")
OptionButton/styles/pressed = ExtResource("38_secondary_pressed")
OptionButton/styles/disabled = ExtResource("39_secondary_disabled")
OptionButton/styles/focus = ExtResource("5_focus")
'''


def main() -> None:
    theme = BASE.read_text()
    theme = theme.replace(' uid="uid://y7aot7vogdr6"', '', 1)
    for old, new in REPLACEMENTS.items():
        if old not in theme:
            raise SystemExit(f"Missing source reference: {old}")
        theme = theme.replace(old, new)
    theme = theme.replace("[sub_resource type=", EXTRA_RESOURCES + "[sub_resource type=", 1)
    theme = theme.replace("[resource]\n", EXTRA_SUBRESOURCES + "[resource]\n", 1)
    OUTPUT.write_text(theme.rstrip() + "\n" + EXTRA_PROPERTIES)
    FOCUS.parent.mkdir(parents=True, exist_ok=True)
    FOCUS.write_text((CLIENT / "assets/ui/styles/button_focus.tres").read_text())
    print(f"Wrote {OUTPUT.relative_to(CLIENT)}")


if __name__ == "__main__":
    main()
