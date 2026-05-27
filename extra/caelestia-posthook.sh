#!/usr/bin/env bash
# Called by caelestia-cli after each theme change.
# $SCHEME_COLOURS is injected as a JSON object by caelestia-cli.
#
# Usage: caelestia-posthook.sh [--browser BROWSER] [--comms APP]

browser=""
comms=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser) browser="$2"; shift 2 ;;
        --comms)   comms="$2";   shift 2 ;;
        *) shift ;;
    esac
done

primary=$(jq -r '.primary' <<< "$SCHEME_COLOURS")
surface=$(jq -r '.surface'  <<< "$SCHEME_COLOURS")

# Hyprland border colors
printf 'return {\n  active_border   = "rgba(%sFF)",\n  inactive_border = "rgba(%s00)",\n}\n' \
    "$primary" "$surface" > "$HOME/.config/hypr/colors.lua"
hyprctl reload

# --- Zen browser ---
if [[ "$browser" == "zen" ]]; then
    mkdir -p "$HOME/.config/chromashell"
    surface_container=$(jq -r '.surfaceContainer' <<< "$SCHEME_COLOURS")
    outline_variant=$(jq -r '.outlineVariant'    <<< "$SCHEME_COLOURS")
    surface_dim=$(jq -r '.surfaceDim'            <<< "$SCHEME_COLOURS")
    printf ':root {\n    --zen-primary-color: #%s !important;\n    --zen-colors-primary: #%s !important;\n    --zen-colors-secondary: #%s !important;\n    --zen-colors-tertiary: #%s !important;\n    --zen-colors-border: #%s !important;\n    --zen-themed-toolbar-bg: #%s !important;\n    --zen-main-browser-background: #%s !important;\n}\n' \
        "$surface_container" "$primary" "$surface_container" "$surface" \
        "$outline_variant" "$surface_dim" "$surface_dim" \
        > "$HOME/.config/chromashell/zen-colors.css"
fi

# --- Element ---
if [[ "$comms" == "element" ]]; then
    scheme_json="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"
    on_surface=$(jq -r '.onSurface'          <<< "$SCHEME_COLOURS")
    on_surface_var=$(jq -r '.onSurfaceVariant' <<< "$SCHEME_COLOURS")
    surface_cont=$(jq -r '.surfaceContainer'   <<< "$SCHEME_COLOURS")
    surface_cont_low=$(jq -r '.surfaceContainerLow'  <<< "$SCHEME_COLOURS")
    surface_cont_high=$(jq -r '.surfaceContainerHigh' <<< "$SCHEME_COLOURS")
    outline_var=$(jq -r '.outlineVariant'    <<< "$SCHEME_COLOURS")
    error_col=$(jq -r '.error'               <<< "$SCHEME_COLOURS")
    primary_cont=$(jq -r '.primaryContainer' <<< "$SCHEME_COLOURS")
    success_col="4CAF50"
    is_dark=$(jq -r 'if .mode == "dark" then "true" else "false" end' "$scheme_json" 2>/dev/null || echo "true")

    element_theme=$(jq -n \
        --arg name         "ChromaShell" \
        --arg is_dark      "$is_dark" \
        --arg primary      "#$primary" \
        --arg error        "#$error_col" \
        --arg surface      "#$surface" \
        --arg surf_cont    "#$surface_cont" \
        --arg surf_cont_low  "#$surface_cont_low" \
        --arg surf_cont_high "#$surface_cont_high" \
        --arg outline_var  "#$outline_var" \
        --arg on_surface   "#$on_surface" \
        --arg on_surf_var  "#$on_surface_var" \
        --arg prim_cont    "#$primary_cont" \
        --arg success      "#$success_col" \
        '{
          name:    $name,
          is_dark: ($is_dark == "true"),
          colors: {
            "accent-color":                          $primary,
            "primary-color":                         $primary,
            "warning-color":                         $error,
            "sidebar-color":                         $surface,
            "roomlist-background-color":             $surf_cont_low,
            "roomlist-text-color":                   $on_surface,
            "roomlist-text-secondary-color":         $on_surf_var,
            "roomlist-highlights-color":             $surf_cont,
            "roomlist-separator-color":              $outline_var,
            "timeline-background-color":             $surf_cont,
            "timeline-text-color":                   $on_surface,
            "timeline-text-secondary-color":         $on_surf_var,
            "timeline-highlights-color":             $surf_cont_high,
            "reaction-row-button-selected-bg-color": $prim_cont,
            "secondary-content":                     $on_surface,
            "tertiary-content":                      $on_surf_var
          },
          compound: {
            "--cpd-color-theme-bg":                   $surface,
            "--cpd-color-bg-canvas-default":          $surf_cont,
            "--cpd-color-bg-subtle-secondary":        $surface,
            "--cpd-color-bg-subtle-primary":          $surf_cont_low,
            "--cpd-color-bg-action-primary-rest":     $primary,
            "--cpd-color-bg-accent-rest":             $primary,
            "--cpd-color-bg-critical-primary":        $error,
            "--cpd-color-text-primary":               $on_surface,
            "--cpd-color-text-secondary":             $on_surf_var,
            "--cpd-color-text-action-accent":         $primary,
            "--cpd-color-text-critical-primary":      $error,
            "--cpd-color-text-success-primary":       $success,
            "--cpd-color-icon-accent-tertiary":       $primary,
            "--cpd-color-icon-primary":               $on_surface,
            "--cpd-color-icon-secondary":             $on_surf_var,
            "--cpd-color-icon-tertiary":              $on_surf_var,
            "--cpd-color-border-interactive-primary": $outline_var,
            "--cpd-color-border-critical-primary":    $error,
            "--cpd-color-border-success-subtle":      $success
          }
        }')

    element_cfg="$HOME/.config/Element/config.json"
    mkdir -p "$HOME/.config/Element"
    if [ -f "$element_cfg" ]; then
        tmp=$(mktemp)
        jq --argjson theme "$element_theme" \
            '.custom_themes = ((.custom_themes // []) | map(select(.name != "ChromaShell"))) + [$theme]
             | .default_theme = "ChromaShell"' \
            "$element_cfg" > "$tmp" && mv "$tmp" "$element_cfg"
    else
        jq -n --argjson theme "$element_theme" \
            '{ custom_themes: [$theme], default_theme: "ChromaShell" }' \
            > "$element_cfg"
    fi
fi
