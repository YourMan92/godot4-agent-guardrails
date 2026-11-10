extends SceneTree
## Godot 4 API lint: flags Godot 3-era APIs and syntax that AI agents commonly hallucinate.
## Usage (from your project root):
##   godot --headless --path . --script res://tools/godot4_lint.gd
##   godot --headless --path . --script res://tools/godot4_lint.gd -- --include-addons
## Exit code: 0 = no errors, 1 = errors found. Warnings never fail the run.
## From godot4-agent-guardrails (MIT). Full pack: https://pimpwen.gumroad.com/l/godot4-agent-pack

const SELF_PATH := "res://tools/godot4_lint.gd"

# [regex, severity, message]
const GD_RULES: Array = [
	["\\bKinematicBody2D\\b", "error", "KinematicBody2D was renamed to CharacterBody2D in Godot 4"],
	["\\bKinematicBody\\b", "error", "KinematicBody was renamed to CharacterBody3D in Godot 4"],
	["\\bmove_and_slide\\(\\s*[^)\\s]", "error", "move_and_slide() takes no arguments in Godot 4; set `velocity` / `up_direction` properties instead"],
	["\\byield\\s*\\(", "error", "yield() was removed; use `await signal` or `await some_func()`"],
	["^\\s*onready\\s+var\\b", "error", "use the @onready annotation: `@onready var ...`"],
	["^\\s*export(\\s*\\(.*\\))?\\s+var\\b", "error", "use the @export annotation family: `@export var ...`, `@export_range(...)`"],
	["^\\s*tool\\s*$", "error", "use the @tool annotation"],
	["\\bsetget\\b", "error", "setget was removed; use `var x: int: set = _set_x, get = _get_x` or inline set/get blocks"],
	["^\\s*(remote|master|puppet|remotesync|mastersync|puppetsync)\\s+func\\b", "error", "RPC keywords were replaced by the @rpc annotation"],
	["\\.connect\\(\\s*\"[^\"]+\"\\s*,\\s*[\\w.]+\\s*,\\s*\"", "error", "Godot 3 connect(signal, target, \"method\"); use `my_signal.connect(_on_method)`"],
	["\\.instance\\(\\)", "error", "PackedScene.instance() was renamed to instantiate()"],
	["\\bextends\\s+Reference\\b", "error", "Reference was renamed to RefCounted"],
	["\\bSpatial\\b", "error", "Spatial was renamed to Node3D"],
	["\\bPosition2D\\b", "error", "Position2D was renamed to Marker2D"],
	["\\bPosition3D\\b", "error", "Position3D was renamed to Marker3D"],
	["\\bAnimatedSprite\\b(?!2D|3D)", "error", "AnimatedSprite was renamed to AnimatedSprite2D"],
	["\\bSprite\\b(?!2D|3D|Frames|Base3D)", "warning", "Sprite was renamed to Sprite2D (ignore if this is your own identifier)"],
	["\\bVisibilityNotifier2D\\b", "error", "VisibilityNotifier2D was renamed to VisibleOnScreenNotifier2D"],
	["\\bVisibilityEnabler2D\\b", "error", "VisibilityEnabler2D was renamed to VisibleOnScreenEnabler2D"],
	["\\bYSort\\b", "error", "YSort was removed; enable `y_sort_enabled` on a Node2D"],
	["\\bNavigation2D\\b", "error", "Navigation2D was removed; use NavigationRegion2D + NavigationAgent2D"],
	["\\bVisualServer\\b", "error", "VisualServer was renamed to RenderingServer"],
	["\\bPhysics2DServer\\b", "error", "Physics2DServer was renamed to PhysicsServer2D"],
	["\\bPool(String|Int|Real|Byte|Vector2|Vector3|Color)Array\\b", "error", "Pool*Array types were renamed to Packed*Array (PoolRealArray -> PackedFloat32Array)"],
	["\\bFile\\.new\\(\\)", "error", "File was replaced by FileAccess.open(path, FileAccess.READ)"],
	["\\bDirectory\\.new\\(\\)", "error", "Directory was replaced by DirAccess.open(path)"],
	["\\bTween\\.new\\(\\)", "error", "Tween is no longer a node; use `create_tween()`"],
	["\\bchange_scene\\(", "error", "use get_tree().change_scene_to_file(path) or change_scene_to_packed(scene)"],
	["\\bfuncref\\(", "error", "funcref() was removed; use a Callable (e.g. `obj.method` or a lambda)"],
	["\\brand_range\\(", "error", "rand_range() was renamed to randf_range()"],
	["\\b(deg2rad|rad2deg)\\(", "error", "use deg_to_rad() / rad_to_deg()"],
	["\\bstepify\\(", "error", "stepify() was renamed to snapped()"],
	["\\brange_lerp\\(", "error", "range_lerp() was renamed to remap()"],
	["\\b(str2var|var2str|bytes2var|var2bytes)\\(", "error", "use str_to_var / var_to_str / bytes_to_var / var_to_bytes"],
	["\\b(to_json|parse_json)\\(", "error", "use JSON.stringify() / JSON.parse_string()"],
	["\\bOS\\.get_ticks_(msec|usec)\\b", "error", "use Time.get_ticks_msec() / Time.get_ticks_usec()"],
	["\\bOS\\.window_(size|fullscreen|position)\\b", "error", "window properties moved to DisplayServer / get_window()"],
	["\\bEngine\\.editor_hint\\b", "error", "use Engine.is_editor_hint()"],
	["\\.empty\\(\\)", "error", "empty() was renamed to is_empty()"],
	["\\bget_world\\(\\)", "error", "use get_world_2d() or get_world_3d()"],
	["\\.rect_(position|size|min_size|global_position|rotation|scale)\\b", "error", "Control rect_* properties lost the prefix (rect_min_size -> custom_minimum_size)"],
	["\\bBUTTON_(LEFT|RIGHT|MIDDLE|WHEEL_UP|WHEEL_DOWN)\\b", "error", "use MOUSE_BUTTON_* constants"],
	["\\bemit_signal\\(\\s*\"", "warning", "prefer the typed form `my_signal.emit(args)` over emit_signal(\"name\")"],
	["\\bTileMap\\b(?!Layer|Pattern)", "warning", "TileMap is deprecated since Godot 4.3; prefer TileMapLayer nodes"],
	["\\bParallaxBackground\\b", "warning", "since Godot 4.3, prefer the Parallax2D node"],
	["\\bget_node\\(\\s*\"(\\.\\./){3,}", "warning", "fragile deep relative get_node path; use %UniqueName, @export var node: NodeType, or signals"],
]

const SCENE_RULES: Array = [
	["^\\[gd_(scene|resource)[^\\]]*format=2", "error", "format=2 is a Godot 3 scene/resource file; re-save it with Godot 4"],
	["type=\"(KinematicBody2D|KinematicBody|Spatial|Position2D|Position3D|AnimatedSprite|Sprite|YSort|Navigation2D|VisibilityNotifier2D)\"", "error", "Godot 3 node type in scene file"],
]

var _compiled: Dictionary = {}
var _errors: int = 0
var _warnings: int = 0


func _initialize() -> void:
	var include_addons: bool = "--include-addons" in OS.get_cmdline_user_args()
	var files: PackedStringArray = []
	_collect("res://", include_addons, files)
	for path in files:
		_lint_file(path)
	print("\nGodot 4 lint: %d file(s), %d error(s), %d warning(s)" % [files.size(), _errors, _warnings])
	quit(1 if _errors > 0 else 0)


func _collect(dir_path: String, include_addons: bool, out: PackedStringArray) -> void:
	for sub in DirAccess.get_directories_at(dir_path):
		if sub.begins_with("."):
			continue
		if sub == "addons" and dir_path == "res://" and not include_addons:
			continue
		var full: String = dir_path.path_join(sub)
		if FileAccess.file_exists(full.path_join(".gdignore")):
			continue
		_collect(full, include_addons, out)
	for file_name in DirAccess.get_files_at(dir_path):
		var full: String = dir_path.path_join(file_name)
		if full == SELF_PATH:
			continue
		if file_name.ends_with(".gd") or file_name.ends_with(".tscn") or file_name.ends_with(".tres"):
			out.append(full)


func _regex(pattern: String) -> RegEx:
	if not _compiled.has(pattern):
		var re := RegEx.new()
		var err: Error = re.compile(pattern)
		assert(err == OK, "bad lint pattern: %s" % pattern)
		_compiled[pattern] = re
	return _compiled[pattern]


func _lint_file(path: String) -> void:
	var text: String = FileAccess.get_file_as_string(path)
	var rules: Array = GD_RULES if path.ends_with(".gd") else SCENE_RULES
	var line_no: int = 0
	for line in text.split("\n"):
		line_no += 1
		var stripped: String = line.strip_edges()
		if stripped.begins_with("#") or stripped.begins_with(";"):
			continue
		if "lint-ignore" in line:
			continue
		for rule in rules:
			if _regex(rule[0]).search(line) != null:
				_report(path, line_no, rule[1], rule[2], stripped)


func _report(path: String, line_no: int, severity: String, message: String, source: String) -> void:
	if severity == "error":
		_errors += 1
		printerr("%s:%d: error: %s\n    %s" % [path, line_no, message, source])
	else:
		_warnings += 1
		print("%s:%d: warning: %s\n    %s" % [path, line_no, message, source])
