// ChromaShell — loaded via --require before element-desktop's main module.
// Injects ~/.config/chromashell/element.css into every renderer window so
// Compound Design System variables follow the caelestia color scheme.
const { app } = require("electron");
const fs = require("fs");
const path = require("path");
const os = require("os");

const cssPath = path.join(
    process.env["XDG_CONFIG_HOME"] || path.join(os.homedir(), ".config"),
    "chromashell", "element.css"
);

app.on("browser-window-created", (_, win) => {
    win.webContents.on("did-finish-load", () => {
        try {
            if (fs.existsSync(cssPath)) {
                win.webContents.insertCSS(fs.readFileSync(cssPath, "utf8")).catch(() => {});
            }
        } catch (_) {}
    });
});
