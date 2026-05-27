#!/usr/bin/env fish

if test "$argv[1]" = '-g'
    set group
    set argv $argv[2..]
end

if test (count $argv) -ne 2
    echo 'Wrong number of arguments. Usage: ./wsaction.fish [-g] <dispatcher> <workspace>'
    exit 1
end

set -l active_ws (hyprctl activeworkspace -j | jq -r '.id')

set -l target_ws 0
if set -q group
    set target_ws (math "($argv[2] - 1) * 10 + $active_ws % 10")
else
    set target_ws (math "floor(($active_ws - 1) / 10) * 10 + $argv[2]")
end

switch $argv[1]
    case workspace
        hyprctl dispatch "hl.dsp.focus({workspace=$target_ws})"
    case movetoworkspace
        hyprctl dispatch "hl.dsp.window.move({workspace=$target_ws})"
    case '*'
        echo "Unknown dispatcher: $argv[1]"
        exit 1
end
