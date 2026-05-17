#!/usr/bin/env bash
# ChromaShell — lädt alle Apps nach einem Theming-Wechsel neu
# Wird von WallpaperPicker.qml und ThemingPopup.qml aufgerufen
# nach: matugen image <wallpaper>  ODER  wal -i <wallpaper>

# ── Kitty ──────────────────────────────────────────────────────────────────
killall -USR1 .kitty-wrapped 2>/dev/null || true

# ── SwayOSD ────────────────────────────────────────────────────────────────
if systemctl --user is-active --quiet swayosd.service; then
    systemctl --user restart swayosd.service &
fi

# ── GTK live-reload ────────────────────────────────────────────────────────
# Theme kurz umschalten → GTK3/4-Apps flushen ihren CSS-Cache
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    sleep 0.05
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    gsettings set org.gnome.desktop.interface color-scheme 'default'
    sleep 0.05
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi

wait
