#!/usr/bin/env bash
# Wrapper that injects the ChromaShell theme config into Element Desktop.
# ELEMENT_DESKTOP_CONFIG_JSON is merged on top of the bundled webapp/config.json.
exec env ELEMENT_DESKTOP_CONFIG_JSON="${XDG_CONFIG_HOME:-$HOME/.config}/chromashell/element-config.json" \
    element-desktop --password-store=gnome-libsecret "$@"
