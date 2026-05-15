import "modules/bar"
import "modules/wallpaper"
import "modules/drawers"
import Quickshell

ShellRoot {
    settings.watchFiles: true
    WallpaperWindow { id: wallpaperWin }
    BarRoot {}
    Drawers {}
}
