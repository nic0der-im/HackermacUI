#!/usr/bin/env bash
# Focus the AeroSpace workspace on the monitor under the mouse, then run the
# given command (e.g. `on-mouse-monitor.sh open -na Ghostty`).
#
# Why: clicking an empty area of another monitor does not change AeroSpace's
# focused workspace (macOS has no focus for a window-less screen), so new apps
# would open on the previously focused workspace.
set -u

# NSScreen.screens order matches AeroSpace's %{monitor-appkit-nsscreen-screens-id}.
screen_id="$(/usr/bin/osascript -l JavaScript -e '
  ObjC.import("AppKit");
  var m = $.NSEvent.mouseLocation, s = $.NSScreen.screens, id = "";
  for (var i = 0; i < s.count; i++) {
    var f = s.objectAtIndex(i).frame;
    if (m.x >= f.origin.x && m.x < f.origin.x + f.size.width &&
        m.y >= f.origin.y && m.y < f.origin.y + f.size.height) { id = String(i + 1); break; }
  }
  id;' 2>/dev/null || true)"

if [[ -n "$screen_id" ]]; then
  ws="$(aerospace list-workspaces --monitor all --visible \
    --format '%{workspace}|%{monitor-appkit-nsscreen-screens-id}' 2>/dev/null \
    | awk -F'|' -v id="$screen_id" '$2 == id { print $1; exit }')"
  [[ -n "$ws" ]] && aerospace workspace "$ws" >/dev/null 2>&1
fi

exec "$@"
