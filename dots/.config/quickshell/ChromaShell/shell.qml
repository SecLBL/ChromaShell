import "modules/bar"
import "modules/wallpaper"
import Quickshell

ShellRoot {
    settings.watchFiles: true
    WallpaperWindow { id: wallpaperWin }
    BarRoot {}
}
