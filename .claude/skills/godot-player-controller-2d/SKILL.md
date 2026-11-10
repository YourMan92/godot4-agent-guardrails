---
name: godot-player-controller-2d
description: Builds or fixes a Godot 4 CharacterBody2D player controller (platformer or top-down) with Input Map actions, acceleration, coyote time, jump buffering, variable jump height, and a headless test. Use when the user asks for player movement, jumping, a platformer character, top-down movement, or says the player "feels floaty", "falls through the floor", or "can't jump".
when_to_use: Trigger phrases include make the player move; add jumping; platformer controller; top-down movement; player falls through floor; fix jump.
argument-hint: "[platformer|topdown] [scene path]"
---

# Godot 4 player controller (2D)

Godot 4.3+ only. Body = `CharacterBody2D`, movement = edit `velocity` then call `move_and_slide()` with no arguments.

## Steps

1. **Inspect** `project.godot`: engine version (`config/features`), `[input]` actions, `[physics]` gravity. Find any existing player scene/script.
2. **Input Map.** Make sure `move_left`, `move_right`, `jump` (platformer) or `move_left/right/up/down` (top-down) exist. If missing, add them in `project.godot` `[input]` using the format already in the file, or tell the user to add them in Project Settings → Input Map. Never read raw keycodes in gameplay code.
3. **Scene** `scenes/player.tscn`: root `CharacterBody2D` → `CollisionShape2D` (RectangleShape2D or CapsuleShape2D, offset so feet are at y=0) → visual (`Sprite2D`/`AnimatedSprite2D`/`Polygon2D`) → optional `Camera2D`.
4. **Script** `scripts/player.gd`: use the template below. Tune exports, don't hard-code.
5. **Test.** If the project has a test setup (GUT, gdUnit4, or a custom runner), add tests: lands on floor, moves right on input, jump rises and lands, `jumped` signal fires. Drive input with `Input.action_press(&"jump")` and step physics frames.
6. **Verify**: `godot --headless --path . --import`, then `godot --headless --path . --script res://tools/godot4_lint.gd`, then any tests, then `godot --headless --path . --quit-after 300`. Report what you ran and the results.

## Platformer template (verified on Godot 4.7.2)

```gdscript
class_name Player
extends CharacterBody2D

signal jumped
signal landed

@export_group("Movement")
@export var max_speed: float = 260.0
@export var acceleration: float = 2200.0
@export var friction: float = 2600.0
@export var air_control: float = 0.6

@export_group("Jump")
@export var jump_velocity: float = -420.0
@export_range(0.0, 1.0) var jump_cut: float = 0.45
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12
@export var fall_gravity_scale: float = 1.6

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false


func _physics_process(delta: float) -> void:
	var on_floor: bool = is_on_floor()
	_coyote_timer = coyote_time if on_floor else maxf(_coyote_timer - delta, 0.0)
	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	if not on_floor:
		var gravity_mult: float = fall_gravity_scale if velocity.y > 0.0 else 1.0
		velocity += get_gravity() * gravity_mult * delta
		if velocity.y < 0.0 and Input.is_action_just_released(&"jump"):
			velocity.y *= jump_cut

	var direction: float = Input.get_axis(&"move_left", &"move_right")
	var control: float = 1.0 if on_floor else air_control
	var target: float = direction * max_speed
	var rate: float = (acceleration if not is_zero_approx(direction) else friction) * control
	velocity.x = move_toward(velocity.x, target, rate * delta)

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		jumped.emit()

	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		landed.emit()
	_was_on_floor = is_on_floor()
```

## Top-down variant

```gdscript
extends CharacterBody2D

@export var max_speed: float = 200.0
@export var acceleration: float = 1500.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = velocity.move_toward(input * max_speed, acceleration * delta)
	move_and_slide()
```

## Gotchas

- `get_gravity()` needs Godot 4.3+. On 4.0–4.2 use `ProjectSettings.get_setting("physics/2d/default_gravity")` × `Vector2.DOWN`.
- Falling through floors: floor needs `StaticBody2D` + shape on a layer in the player's `collision_mask`; very fast bodies may need a thicker floor or higher physics ticks.
- Don't scale the CharacterBody2D or its collision shape non-uniformly; resize the shape.
- One-way platforms: `CollisionShape2D.one_way_collision = true` on the platform's shape.
- Animation: drive it from state (`velocity`, `is_on_floor()`), and flip with `sprite.flip_h = velocity.x < 0.0` only when `absf(velocity.x) > 1.0`.
- Don't invent helpers like `is_grounded()` or `jump()` on the engine class. If unsure, check https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html.
