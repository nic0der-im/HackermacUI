#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIGS = ROOT / "configs"
PROFILES = CONFIGS / "templates" / "profiles"

ACTION_TYPES = {
    "submenu",
    "openApp",
    "openPath",
    "openURL",
    "ghostty",
    "aerospace",
    "run",
    "appleScript",
    "sequence",
}

ACTION_REQUIRED = {
    "openApp": {"name"},
    "openPath": {"path"},
    "openURL": {"url"},
    "ghostty": {"command"},
    "aerospace": {"args"},
    "run": {"command"},
    "appleScript": {"script"},
    "sequence": {"actions"},
}

HOTKEY_KEYS = {"space", *list("abcdefghijklmnopqrstuvwxyz")}
HOTKEY_MODIFIERS = {"option", "alt", "control", "ctrl", "shift", "command", "cmd", "super"}

errors: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


def load_json(path: Path):
    try:
        with path.open() as handle:
            return json.load(handle)
    except Exception as error:
        fail(f"{path.relative_to(ROOT)}: invalid JSON: {error}")
        return None


def expect_string(value, label: str, *, allow_empty: bool = False) -> None:
    if not isinstance(value, str):
        fail(f"{label}: expected string")
    elif not allow_empty and not value.strip():
        fail(f"{label}: expected non-empty string")


def validate_action(action, label: str) -> None:
    if not isinstance(action, dict):
        fail(f"{label}: action must be an object")
        return

    action_type = action.get("type")
    if action_type not in ACTION_TYPES:
        fail(f"{label}: unsupported action type {action_type!r}")
        return

    for field in ACTION_REQUIRED.get(action_type, set()):
        if field not in action:
            fail(f"{label}: action type {action_type!r} requires {field!r}")

    if action_type == "aerospace" and not isinstance(action.get("args"), list):
        fail(f"{label}: aerospace args must be an array")
    if action_type == "sequence":
        actions = action.get("actions")
        if not isinstance(actions, list) or not actions:
            fail(f"{label}: sequence actions must be a non-empty array")
        else:
            for index, child in enumerate(actions):
                validate_action(child, f"{label}.actions[{index}]")


def validate_menu_item(item, label: str) -> None:
    if not isinstance(item, dict):
        fail(f"{label}: item must be an object")
        return

    expect_string(item.get("title"), f"{label}.title")

    if "subtitle" in item and item["subtitle"] is not None:
        expect_string(item["subtitle"], f"{label}.subtitle", allow_empty=True)
    if "icon" in item and item["icon"] is not None:
        expect_string(item["icon"], f"{label}.icon")
    if "confirm" in item and not isinstance(item["confirm"], bool):
        fail(f"{label}.confirm: expected boolean")

    children = item.get("items")
    action = item.get("action")
    if children is not None:
        if not isinstance(children, list):
            fail(f"{label}.items: expected array")
        else:
            for index, child in enumerate(children):
                validate_menu_item(child, f"{label}.items[{index}]")
    elif action is not None:
        validate_action(action, f"{label}.action")
    else:
        # Leaf help rows are allowed in Keybindings.
        pass


def validate_menu(path: Path) -> None:
    data = load_json(path)
    if data is None:
        return
    label = str(path.relative_to(ROOT))
    expect_string(data.get("title"), f"{label}.title")
    items = data.get("items")
    if not isinstance(items, list) or not items:
        fail(f"{label}.items: expected non-empty array")
        return
    for index, item in enumerate(items):
        validate_menu_item(item, f"{label}.items[{index}]")


def validate_theme(path: Path) -> None:
    data = load_json(path)
    if data is None:
        return
    label = str(path.relative_to(ROOT))
    for field in ("material", "accentColor"):
        expect_string(data.get(field), f"{label}.{field}")
    for field in ("cornerRadius", "width"):
        if not isinstance(data.get(field), (int, float)) or data[field] <= 0:
            fail(f"{label}.{field}: expected positive number")
    if not isinstance(data.get("maxRows"), int) or data["maxRows"] <= 0:
        fail(f"{label}.maxRows: expected positive integer")

    hotkey = data.get("hotKey")
    if not isinstance(hotkey, dict):
        fail(f"{label}.hotKey: expected object")
        return
    key = hotkey.get("key")
    if not isinstance(key, str) or key.lower() not in HOTKEY_KEYS:
        fail(f"{label}.hotKey.key: unsupported key {key!r}")
    modifiers = hotkey.get("modifiers")
    if not isinstance(modifiers, list) or not modifiers:
        fail(f"{label}.hotKey.modifiers: expected non-empty array")
    else:
        for modifier in modifiers:
            if not isinstance(modifier, str) or modifier.lower() not in HOTKEY_MODIFIERS:
                fail(f"{label}.hotKey.modifiers: unsupported modifier {modifier!r}")


def parse_env_workspaces(path: Path) -> list[str]:
    value = None
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("HACKERMACUI_WORKSPACES="):
            value = stripped.split("=", 1)[1].strip().strip('"').strip("'")
    if value is None:
        fail(f"{path.relative_to(ROOT)}: missing HACKERMACUI_WORKSPACES")
        return []
    workspaces = value.split()
    if not workspaces:
        fail(f"{path.relative_to(ROOT)}: HACKERMACUI_WORKSPACES must not be empty")
    return workspaces


def parse_aerospace_workspaces(path: Path) -> list[str]:
    content = path.read_text()
    match = re.search(r"persistent-workspaces\s*=\s*\[(.*?)\]", content, re.S)
    if not match:
        fail(f"{path.relative_to(ROOT)}: missing persistent-workspaces")
        return []
    return re.findall(r"['\"]([^'\"]+)['\"]", match.group(1))


def parse_launcher_workspaces(path: Path) -> list[str]:
    data = load_json(path)
    if data is None:
        return []
    for item in data.get("items", []):
        if item.get("title") == "Switch":
            workspaces = []
            for child in item.get("items", []):
                action = child.get("action") or {}
                args = action.get("args") or []
                if action.get("type") == "aerospace" and len(args) == 2 and args[0] == "workspace":
                    workspaces.append(str(args[1]))
            return workspaces
    fail(f"{path.relative_to(ROOT)}: missing Switch menu")
    return []


def validate_profile(profile_dir: Path) -> None:
    label = profile_dir.relative_to(ROOT)
    aerospace = profile_dir / "aerospace.toml"
    env = profile_dir / "profile.env"
    menu = profile_dir / "launcher.menu.json"
    for required in (aerospace, env):
        if not required.exists():
            fail(f"{label}: missing {required.name}")
            return

    env_workspaces = parse_env_workspaces(env)
    aero_workspaces = parse_aerospace_workspaces(aerospace)
    if env_workspaces and aero_workspaces and env_workspaces != aero_workspaces:
        fail(
            f"{label}: profile.env workspaces {env_workspaces} "
            f"do not match aerospace.toml {aero_workspaces}"
        )

    if menu.exists():
        validate_menu(menu)
        menu_workspaces = parse_launcher_workspaces(menu)
        if menu_workspaces and aero_workspaces and menu_workspaces != aero_workspaces:
            fail(
                f"{label}: launcher Switch workspaces {menu_workspaces} "
                f"do not match aerospace.toml {aero_workspaces}"
            )


def main() -> int:
    validate_menu(CONFIGS / "launcher" / "menu.json")
    validate_theme(CONFIGS / "launcher" / "theme.json")

    if not PROFILES.exists():
        fail("configs/templates/profiles: missing profiles directory")
    else:
        profiles = sorted(path for path in PROFILES.iterdir() if path.is_dir())
        if not profiles:
            fail("configs/templates/profiles: no profiles found")
        for profile in profiles:
            validate_profile(profile)

    if errors:
        print("Config validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Config validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
