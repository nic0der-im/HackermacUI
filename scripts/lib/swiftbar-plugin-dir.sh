#!/usr/bin/env bash
# Shared helper: resolve SwiftBar's configured plugin directory.
#
# SwiftBar's own preference is the source of truth; scripts/apply.sh is what
# sets it, but a user may point it elsewhere, so every script that touches
# the plugin directory falls back the same way instead of hardcoding
# ~/SwiftBarPlugins.
#
# Usage: source this file, then call `swiftbar_plugin_dir`.

swiftbar_plugin_dir() {
  defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || printf '%s' "$HOME/SwiftBarPlugins"
}
