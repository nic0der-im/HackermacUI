#!/usr/bin/env python3
import re
import stat
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    # Python < 3.11: skip tomllib-based checks instead of failing validation.
    tomllib = None

ROOT = Path(__file__).resolve().parents[1]
PROFILES = ROOT / "configs" / "templates" / "profiles"
CURRENT_PROFILE_FILE = ROOT / "configs" / "templates" / "current-profile"
ACTIVE_AEROSPACE_TOML = ROOT / "configs" / "aerospace" / "aerospace.toml"
THEME_PALETTE = ROOT / "configs" / "theme" / "palette.env"
GHOSTTY_CONFIG = ROOT / "configs" / "ghostty" / "config"

errors: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


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


def validate_profile(profile_dir: Path) -> None:
    label = profile_dir.relative_to(ROOT)
    aerospace = profile_dir / "aerospace.toml"
    env = profile_dir / "profile.env"
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

    check_toml_parses(aerospace)
    if aero_workspaces:
        check_workspace_binding_coverage(aerospace, aero_workspaces)


def check_toml_parses(path: Path) -> None:
    if tomllib is None:
        return
    try:
        tomllib.loads(path.read_text())
    except tomllib.TOMLDecodeError as exc:
        fail(f"{path.relative_to(ROOT)}: invalid TOML ({exc})")


def check_workspace_binding_coverage(path: Path, workspaces: list[str]) -> None:
    if tomllib is None:
        return
    try:
        data = tomllib.loads(path.read_text())
    except tomllib.TOMLDecodeError:
        return  # already reported by check_toml_parses
    binding = data.get("mode", {}).get("main", {}).get("binding", {})
    for ws in workspaces:
        switch_key = f"alt-{ws}"
        if switch_key not in binding:
            fail(f"{path.relative_to(ROOT)}: missing '{switch_key}' workspace-switch binding")
        move_key = f"alt-ctrl-{ws}"
        if move_key not in binding:
            fail(f"{path.relative_to(ROOT)}: missing '{move_key}' workspace-move binding")


def check_current_profile_matches_active() -> None:
    if not CURRENT_PROFILE_FILE.exists():
        fail(f"{CURRENT_PROFILE_FILE.relative_to(ROOT)}: missing file")
        return
    current = CURRENT_PROFILE_FILE.read_text().strip()
    if not current:
        fail(f"{CURRENT_PROFILE_FILE.relative_to(ROOT)}: empty")
        return
    profile_toml = PROFILES / current / "aerospace.toml"
    if not profile_toml.exists():
        fail(f"{CURRENT_PROFILE_FILE.relative_to(ROOT)}: unknown profile '{current}'")
        return
    if not ACTIVE_AEROSPACE_TOML.exists():
        fail(f"{ACTIVE_AEROSPACE_TOML.relative_to(ROOT)}: missing file")
        return
    if ACTIVE_AEROSPACE_TOML.read_text() != profile_toml.read_text():
        fail(
            f"{ACTIVE_AEROSPACE_TOML.relative_to(ROOT)} does not match the rendered "
            f"'{current}' profile ({profile_toml.relative_to(ROOT)}); "
            "run scripts/template.sh render <profile>"
        )


def parse_shell_env_value(path: Path, key: str) -> str | None:
    value = None
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith(f"{key}="):
            value = stripped.split("=", 1)[1].strip().strip('"').strip("'")
    return value


def parse_ghostty_value(path: Path, key: str) -> str | None:
    value = None
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        match = re.match(rf"^{re.escape(key)}\s*=\s*(.+)$", stripped)
        if match:
            value = match.group(1).strip()
    return value


def check_ghostty_focus_color() -> None:
    if not THEME_PALETTE.exists():
        fail(f"{THEME_PALETTE.relative_to(ROOT)}: missing file")
        return
    if not GHOSTTY_CONFIG.exists():
        fail(f"{GHOSTTY_CONFIG.relative_to(ROOT)}: missing file")
        return

    focus = parse_shell_env_value(THEME_PALETTE, "HACKERMACUI_COLOR_FOCUS")
    if not focus:
        fail(f"{THEME_PALETTE.relative_to(ROOT)}: missing HACKERMACUI_COLOR_FOCUS")
        return

    for key in ("cursor-color", "selection-background"):
        value = parse_ghostty_value(GHOSTTY_CONFIG, key)
        if not value:
            fail(f"{GHOSTTY_CONFIG.relative_to(ROOT)}: missing '{key}'")
            continue
        if value.lower() != focus.lower():
            fail(
                f"{GHOSTTY_CONFIG.relative_to(ROOT)}: '{key}' ({value}) does not match "
                f"HACKERMACUI_COLOR_FOCUS ({focus}) in {THEME_PALETTE.relative_to(ROOT)}"
            )


def check_executable(path: Path) -> None:
    if not path.exists():
        fail(f"{path.relative_to(ROOT)}: missing file")
        return
    if not (path.stat().st_mode & stat.S_IXUSR):
        fail(f"{path.relative_to(ROOT)}: not executable")


def collect_executable_paths() -> list[Path]:
    paths: list[Path] = []

    scripts_dir = ROOT / "scripts"
    if scripts_dir.exists():
        paths += sorted(scripts_dir.glob("*.sh"))

    aerospace_scripts_dir = ROOT / "configs" / "aerospace" / "scripts"
    if aerospace_scripts_dir.exists():
        paths += sorted(
            path
            for path in aerospace_scripts_dir.iterdir()
            if path.is_file() and path.name != "profile.env"
        )

    plugins_dir = ROOT / "configs" / "swiftbar" / "plugins"
    if plugins_dir.exists():
        paths += sorted(plugins_dir.glob("*.sh"))
        helpers_dir = plugins_dir / ".helpers"
        if helpers_dir.exists():
            paths += sorted(helpers_dir.glob("*.sh"))
            paths += sorted(helpers_dir.glob("*.jxa"))

    bordersrc = ROOT / "configs" / "borders" / "bordersrc"
    if bordersrc.exists():
        paths.append(bordersrc)

    return paths


def main() -> int:
    if not PROFILES.exists():
        fail("configs/templates/profiles: missing profiles directory")
    else:
        profiles = sorted(path for path in PROFILES.iterdir() if path.is_dir())
        if not profiles:
            fail("configs/templates/profiles: no profiles found")
        for profile in profiles:
            validate_profile(profile)

    check_ghostty_focus_color()

    if errors:
        print("Config validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Config validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
