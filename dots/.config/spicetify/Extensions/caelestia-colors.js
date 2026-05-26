// Reads caelestia's color.ini via the local colors server (127.0.0.1:29847)
// and applies --spice-* CSS variables dynamically.
// The server (caelestia-colors-server systemd user service) serves the file
// because Spotify's sandboxed Electron renderer cannot access the filesystem directly.
(async () => {
    while (typeof Spicetify === 'undefined' || !Spicetify.showNotification) {
        await new Promise(r => setTimeout(r, 300));
    }

    const COLORS_URL = 'http://127.0.0.1:29847/';

    function parseSection(content, section) {
        const colors = {};
        let inSection = false;
        for (const line of content.split('\n')) {
            const trimmed = line.trim();
            if (trimmed === `[${section}]`) { inSection = true; continue; }
            if (trimmed.startsWith('['))    { inSection = false; continue; }
            if (!inSection || !trimmed || trimmed.startsWith(';')) continue;
            const eq = trimmed.indexOf('=');
            if (eq === -1) continue;
            const key = trimmed.slice(0, eq).trim();
            const val = trimmed.slice(eq + 1).split(';')[0].trim();
            if (/^[0-9a-fA-F]{6}$/.test(val)) colors[key] = val;
        }
        return colors;
    }

    try {
        const res = await fetch(COLORS_URL);
        if (!res.ok) {
            Spicetify.showNotification('[caelestia] colors server: HTTP ' + res.status, true, 4000);
            return;
        }
        const colors = parseSection(await res.text(), 'caelestia');
        const root   = document.documentElement;
        for (const [key, val] of Object.entries(colors)) {
            root.style.setProperty(`--spice-${key}`, `#${val}`);
            const r = parseInt(val.slice(0, 2), 16);
            const g = parseInt(val.slice(2, 4), 16);
            const b = parseInt(val.slice(4, 6), 16);
            root.style.setProperty(`--spice-rgb-${key}`, `${r},${g},${b}`);
        }
    } catch (e) {
        Spicetify.showNotification('[caelestia] colors server nicht erreichbar: ' + e.message, true, 4000);
    }
})();
