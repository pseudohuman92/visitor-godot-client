# OMEN UI asset library

These assets came from the user-provided `OMEN_UI_Asset_Library.zip`.
Only its transparent-background variants are included and referenced by the
client. The opaque atlas crops remain in the source ZIP.

Transparent outer padding was cropped to the visible alpha bounds (alpha over
1%) with up to two pixels of safety margin. This reduced 56 of the 63 images;
the remaining seven were already tight. The artwork inside each crop was not
rescaled or redrawn.

Godot nine-slice styles using these images live in `assets/ui/styles/`.
Decorative uses in menu, board, popup, and tutorial scenes retain their own
placement and margins. The assets have no built-in text or gameplay state.
