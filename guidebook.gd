extends CanvasLayer
class_name Guidebook

var open := false
var panel: Panel
var text_label: RichTextLabel

const GUIDE_TEXT := """[b]MASK — Field Guide[/b]

[b]Goal[/b]
Explore the Overworld, gather resources, defeat gate bosses, follow compasses to portals, and face the raid bosses in Hell and Heaven.

[b]Controls (Android Landscape)[/b]
• Left side: Virtual Joystick — move
• Aim with the center crosshair ✚
• Short TAP = Mine / Attack under crosshair
• Right side drag = look
• On-screen buttons still work

[b]Controller (Minecraft-style layout)[/b]
• Left stick — Move
• Right stick — Look
• RT / R2 — Mine or Attack (hold)
• LT / L2 — Place block (hold)
• A / X — Jump
• Y / Triangle — Sprint
• LB / L1 — Hotbar previous
• RB / R1 — Hotbar next
• D-Pad — Hotbar slots
• Options / Start — Settings
• Share / Back — Guidebook

[b]Armor tiers (Head / Chest / Legs / Feet)[/b]
Wood → Copper → Iron → Gold → Diamond → Crystal → Core
Core is the hardest, most resilient set (best damage reduction).
Mix pieces; HUD shows total Armor DR %.

[b]Mining & Ores[/b]
Break stone layers to find:
• Coal — common, dark
• Copper — orange-brown
• Iron — gray
• Gold — yellow
• Diamond — bright cyan crystal
Ores appear underground. Use BREAK on stone blocks.

[b]Trees & Flowers[/b]
Timber grows in forests. Flowers decorate plains and forests. Collect them for inventory.

[b]Chests[/b]
Look for wooden chests in the world. Open them (walk close + interact / BREAK near them in this build) for completely random loot.

[b]Bosses & Portals[/b]
1. Change altitude until you hear a Call Sign
2. Defeat the gate boss → receive Compass / Key
3. Follow the Compass HUD to the glowing Portal
4. Enter with the matching key
• Hell → Lucifer (raid boss)
• Heaven → God (raid boss)
• Purgatory → dark quiet realm

[b]Creative Mode[/b]
Unlimited blocks, no damage, flight, all keys unlocked. Create from the World Select screen.

[b]Survival Tips[/b]
• Craft Rough Blade (Stonehard + Timber) for more damage
• Crystalite ×3 → Crystal Shard
• Watch your HP against raid bosses
• Use settings to lower Render Scale on weaker devices
"""

func _ready() -> void:
	layer = 25
	visible = false
	_build()

func _build() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.gui_input.connect(func(e):
		if e is InputEventScreenTouch and e.pressed:
			toggle()
	)
	add_child(bg)

	panel = Panel.new()
	panel.anchor_left = 0.12
	panel.anchor_right = 0.88
	panel.anchor_top = 0.08
	panel.anchor_bottom = 0.92
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 16
	vbox.offset_right = -16
	vbox.offset_top = 12
	vbox.offset_bottom = -12
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "GUIDEBOOK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.custom_minimum_size = Vector2(400, 600)
	text_label.text = GUIDE_TEXT
	scroll.add_child(text_label)

	var close_btn = Button.new()
	close_btn.text = "CLOSE GUIDE"
	close_btn.pressed.connect(toggle)
	vbox.add_child(close_btn)

func toggle() -> void:
	open = not open
	visible = open
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
