// Reads caelestia's color.ini at startup and applies --spice-* CSS variables dynamically.
(async () => {
    await new Promise(res => Spicetify.Events.webpackLoaded.on(res));

    const fs   = require('fs');
    const path = require('path');

    const configHome   = process.env.XDG_CONFIG_HOME || path.join(process.env.HOME, '.config');
    const colorIniPath = path.join(configHome, 'spicetify/Themes/caelestia/color.ini');

    function parseSection(content, section) {
        const colors = {};
        let inSection = false;
        for (const line of content.split('\n')) {
            const trimmed = line.trim();
            if (trimmed === `[${section}]`) { inSection = true; continue; }
            if (trimmed.startsWith('['))    { inSection = false; continue; }
            if (!inSection || !trimmed || trimmed.startsWith(';')) continue;
            const eq  = trimmed.indexOf('=');
            if (eq === -1) continue;
            const key = trimmed.slice(0, eq).trim();
            const val = trimmed.slice(eq + 1).split(';')[0].trim();
            if (/^[0-9a-fA-F]{6}$/.test(val)) colors[key] = val;
        }
        return colors;
    }

    try {
        const content = fs.readFileSync(colorIniPath, 'utf8');
        const colors  = parseSection(content, 'caelestia');
        const root    = document.documentElement;
        for (const [key, val] of Object.entries(colors)) {
            root.style.setProperty(`--spice-${key}`, `#${val}`);
            const r = parseInt(val.slice(0, 2), 16);
            const g = parseInt(val.slice(2, 4), 16);
            const b = parseInt(val.slice(4, 6), 16);
            root.style.setProperty(`--spice-rgb-${key}`, `${r},${g},${b}`);
        }
    } catch (e) {
        console.warn('[caelestia] could not load spicetify colors:', e);
    }
})();
