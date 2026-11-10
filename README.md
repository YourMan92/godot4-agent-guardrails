# godot4-agent-guardrails

Free, MIT-licensed guardrails that stop AI coding agents (Cursor, Claude Code, Codex, and others) from writing **Godot 3 code in your Godot 4 project**.

If your agent keeps writing `KinematicBody2D`, `yield()`, `onready var`, or `move_and_slide(velocity, Vector2.UP)`, this repo is for you.

## What's in here

| File | What it does |
|---|---|
| `.cursor/rules/godot4-api-accuracy.mdc` | Always-on Cursor rule: a 31-row "Godot 3 → Godot 4" table, common hallucinated APIs, and a "look it up, don't guess" instruction |
| `AGENTS.md` + `CLAUDE.md` | The same rule for Claude Code (`CLAUDE.md` imports `AGENTS.md`), Codex, and other tools that read `AGENTS.md` |
| `tools/godot4_lint.gd` | A lint that runs inside Godot (no Python or Node). It flags 46 Godot 3-era APIs and patterns in `.gd` files plus Godot 3 `.tscn`/`.tres` formats, and exits 1 on errors, so you can use it in CI or as the agent's "done" check |
| `.claude/skills/godot-player-controller-2d/SKILL.md` | Claude Code skill: a typed Godot 4 `CharacterBody2D` platformer controller (acceleration, coyote time, jump buffer, variable jump height) plus a top-down variant and common gotchas |

Requires **Godot 4.3+**. Tested on Godot 4.7.2-stable.

## Install (2 minutes)

From your Godot project root (the folder with `project.godot`):

```bash
git clone https://github.com/YourMan92/godot4-agent-guardrails /tmp/g4ag
mkdir -p .cursor/rules .claude/skills tools
cp /tmp/g4ag/.cursor/rules/godot4-api-accuracy.mdc .cursor/rules/
cp -r /tmp/g4ag/.claude/skills/godot-player-controller-2d .claude/skills/
cp /tmp/g4ag/tools/godot4_lint.gd tools/
cp -n /tmp/g4ag/AGENTS.md /tmp/g4ag/CLAUDE.md .   # -n: won't overwrite yours
```

If you already have an `AGENTS.md` or `CLAUDE.md`, paste the contents of this repo's `AGENTS.md` into yours instead.

- **Cursor:** the rule shows up under Customize → Rules as *Always*.
- **Claude Code:** start `claude` in the project; `CLAUDE.md` loads the rule, and `/godot-player-controller-2d` appears in the `/` menu.

## Run the lint

```bash
godot --headless --path . --script res://tools/godot4_lint.gd
godot --headless --path . --script res://tools/godot4_lint.gd -- --include-addons   # also scan addons/
```

Real output on a Godot 3-style script (Godot 4.7.2):

```
res://player.gd:1: error: KinematicBody2D was renamed to CharacterBody2D in Godot 4
    extends KinematicBody2D
res://player.gd:3: error: use the @onready annotation: `@onready var ...`
    onready var sprite = $Sprite
res://player.gd:3: warning: Sprite was renamed to Sprite2D (ignore if this is your own identifier)
    onready var sprite = $Sprite
res://player.gd:4: error: use the @export annotation family: `@export var ...`, `@export_range(...)`
    export var speed = 200
res://player.gd:7: error: move_and_slide() takes no arguments in Godot 4; set `velocity` / `up_direction` properties instead
    velocity = move_and_slide(velocity, Vector2.UP)
res://player.gd:8: error: yield() was removed; use `await signal` or `await some_func()`
    yield(get_tree().create_timer(1.0), "timeout")
Godot 4 lint: 1 file(s), 5 error(s), 1 warning(s)
```

- Exit code 0 = no errors, 1 = errors. Warnings never fail the run.
- Add `lint-ignore` in a comment to silence one line.
- It's a line-based regex check, not a parser. It catches the common Godot 3 leftovers, not every possible mistake. Use it alongside Godot's own `--check-only` parse and your tests.
- `godot` = your Godot 4 binary (on Windows, use the `_console.exe`).

Tip: add this to your agent instructions: *"Before saying you're done, run the Godot 4 lint and fix everything it reports."*

## Want the rest?

This repo is a free, standalone subset of the paid **[Godot 4 Indie Game Dev Agent Pack](https://pimpwen.gumroad.com/l/godot4-agent-pack)** (made by the same people). The paid pack adds:

- 6 more scoped Cursor rules (GDScript typing/style, scenes & .tscn format, signals, project structure, performance, testing)
- 4 more Claude Code skills (scene creation, signal wiring, export builds, headless tests)
- `api_check.gd`, which asks your installed Godot whether a class/method/property/signal exists
- a zero-dependency headless test runner
- tested MCP configs for [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp), so the agent can run your game and read real errors
- a sample platformer with 6 passing tests, and installers for macOS/Linux/Windows

Everything in *this* repo works on its own. You don't need the paid pack.

## How this was made

Written with the help of an AI assistant, then run and checked against Godot 4.7.2: the lint was run on the engine, and the API names in the rule and skill were checked against it.

## Contributing

Found a Godot 3 pattern the lint misses, or a false positive? Open an issue with the line of code and your Godot version.

## License

MIT. See [LICENSE](LICENSE). Godot is a trademark of the Godot Foundation. This project is not affiliated with the Godot Foundation, Cursor, or Anthropic.
