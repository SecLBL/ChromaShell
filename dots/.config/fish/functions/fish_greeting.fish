function fish_greeting
    echo -ne '\x1b[38;5;16m'  # Set colour to primary
    echo '   ________                               _____ __         ____'
    echo '  / ____/ /_  _________  ____ ___  ____ _/ ___// /_  ___  / / /'
    echo ' / /   / __ \/ ___/ __ \/ __ `__ \/ __ `/\__ \/ __ \/ _ \/ / / '
    echo '/ /___/ / / / /  / /_/ / / / / / / /_/ /___/ / / / /  __/ / /  '
    echo '\____/_/ /_/_/   \____/_/ /_/ /_/\__,_//____/_/ /_/\___/_/_/   '
    set_color normal
    fastfetch --key-padding-left 5
end
