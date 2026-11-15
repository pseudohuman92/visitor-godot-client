extends Node
## Run: godot --headless --path . res://tests/sound_effects.tscn

var heard := []
var checks := 0
var failures := 0

func expect(condition: bool, description: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func expect_sound(effect: StringName, description: String):
	expect(heard == [effect], description + ": " + str(heard))
	heard.clear()

func card(id: String):
	var result = GS.Types.CardP.new()
	result.set_id(id)
	return result

func _ready():
	call_deferred("run")

func run():
	SFX.effect_played.connect(func(effect): heard.append(effect))
	SFX.reset_match()
	var state = GS.Types.GameStateP.new()
	state.set_id("sound-test")
	state.set_turnPlayer("player")
	var player = state.new_player()
	player.set_health(30)
	player.set_deckSize(40)
	var opponent = state.new_opponent()
	opponent.set_health(30)
	player.get_hand().append(card("first"))
	SFX.observe(state)
	expect_sound(&"card_draw", "Initial deal plays once")
	SFX.observe(state)
	expect(heard.is_empty(), "Repeated snapshot is silent")
	player.get_hand().append(card("drawn"))
	player.set_deckSize(39)
	SFX.observe(state)
	expect_sound(&"card_draw", "Drawing a card is audible")
	player.set_maxEnergy(1)
	SFX.observe(state)
	expect_sound(&"study", "Studying is audible")
	state.get_stack().append(player.get_hand().pop_front())
	SFX.observe(state)
	expect_sound(&"card_play", "Playing to stack is audible")
	player.get_play().append(state.get_stack().pop_front())
	SFX.observe(state)
	expect(heard.is_empty(), "Resolving the same card does not replay its cue")
	state.add_attackers("first")
	SFX.observe(state)
	expect_sound(&"attack", "Declaring attackers is audible")
	SFX.observe(state)
	expect(heard.is_empty(), "Unchanged attackers do not retrigger")
	opponent.set_health(28)
	SFX.observe(state)
	expect_sound(&"damage", "Opponent damage is audible")
	player.set_health(29)
	SFX.observe(state)
	expect_sound(&"damage", "Player damage is audible")
	player.set_health(30)
	SFX.observe(state)
	expect(heard.is_empty(), "Healing does not sound like damage")
	state.set_turnPlayer("opponent")
	SFX.observe(state)
	expect_sound(&"turn_end", "Turn changes are audible")
	SFX.finish_match("sound-test", false)
	expect(heard.is_empty(), "A loss does not play victory")
	SFX.reset_match()
	SFX.finish_match("sound-test", true)
	expect_sound(&"victory", "Winning plays victory")
	SFX.finish_match("sound-test", true)
	expect(heard.is_empty(), "Duplicate game-end messages are silent")
	SFX.reset_match()
	state.set_id("second-match")
	SFX.observe(state)
	expect_sound(&"card_draw", "A new match gets a fresh initial deal")
	SFX.reset_match()
	var capture := AudioEffectCapture.new()
	AudioServer.add_bus_effect(0, capture)
	for effect in SFX.SOUNDS:
		SFX.reset_match()
		await get_tree().create_timer(0.25).timeout
		capture.clear_buffer()
		SFX.play(effect)
		expect_sound(effect, "Sound can be played: " + str(effect))
		var audible := false
		# Dummy/headless devices can take several buffers to start mixing.
		for attempt in range(10):
			await get_tree().create_timer(0.1).timeout
			var frames := capture.get_buffer(capture.get_frames_available())
			for frame in frames:
				if frame.length() > 0.001:
					audible = true
					break
			if audible:
				break
		expect(audible, "Mixer produces nonzero samples: " + str(effect))
		SFX.reset_match()
		capture.clear_buffer()
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	capture = null
	await get_tree().create_timer(0.15).timeout
	print("Sound checks: ", checks, "; failures: ", failures)
	get_tree().quit(0 if failures == 0 else 1)
