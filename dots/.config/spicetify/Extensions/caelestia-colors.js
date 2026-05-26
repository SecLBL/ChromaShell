// Reads caelestia's color.ini at startup and applies --spice-* CSS variables dynamically.
// Uses window.require (Node.js require, unaffected by webpack's local const require),
// with fetch(file://) and XMLHttpRequest as fallbacks.
(async () => {
    await new Promise(res => Spicetify.Events.webpackLoaded.on(res));

    const configHome   = process.env.XDG_CONFIG_HOME || (process.env.HOME + '/.config');
    const colorIniPath = configHome + '/spicetify/Themes/caelestia/color.ini';
    const fileUrl      = 'file://' + colorIniPath;

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

    const logPath = (process.env.XDG_STATE_HOME || (process.env.HOME + '/.local/state'))
                    + '/caelestia/spicetify-colors.log';

    function writeLog(msg) {
        try {
            const req = window.require;
            if (typeof req === 'function') req('fs').appendFileSync(logPath, msg + '\n');
        } catch (_) {}
    }

    function applyColors(content, method) {
        const colors = parseSection(content, 'caelestia');
        const root   = document.documentElement;
        for (const [key, val] of Object.entries(colors)) {
            root.style.setProperty(`--spice-${key}`, `#${val}`);
            const r = parseInt(val.slice(0, 2), 16);
            const g = parseInt(val.slice(2, 4), 16);
            const b = parseInt(val.slice(4, 6), 16);
            root.style.setProperty(`--spice-rgb-${key}`, `${r},${g},${b}`);
        }
        writeLog('[ok] applied via ' + method + ', keys: ' + Object.keys(colors).join(','));
    }

    // Method 1: window.require — Node.js require is on window, webpack only overrides
    // the local 'require' const inside spicetifyWrapper.js, not window.require.
    try {
        const req = window.require;
        if (typeof req === 'function') {
            const fs      = req('fs');
            const content = fs.readFileSync(colorIniPath, 'utf8');
            applyColors(content, 'window.require');
            return;
        }
        writeLog('[skip] window.require is not a function: ' + typeof req);
    } catch (e) {
        writeLog('[fail] window.require: ' + e.message);
    }

    // Method 2: fetch with file:// (works when Electron allows file protocol in renderer)
    try {
        const res = await fetch(fileUrl);
        if (res.ok) {
            applyColors(await res.text(), 'fetch');
            return;
        }
        writeLog('[fail] fetch: status ' + res.status);
    } catch (e) {
        writeLog('[fail] fetch: ' + e.message);
    }

    // Method 3: XMLHttpRequest with file:// (status 0 = success for local files)
    try {
        const content = await new Promise((resolve, reject) => {
            const xhr = new XMLHttpRequest();
            xhr.open('GET', fileUrl, true);
            xhr.onload  = () => (xhr.status === 0 || xhr.status === 200)
                ? resolve(xhr.responseText)
                : reject(new Error('XHR status ' + xhr.status));
            xhr.onerror = () => reject(new Error('XHR network error'));
            xhr.send();
        });
        applyColors(content, 'XMLHttpRequest');
        return;
    } catch (e) {
        writeLog('[fail] XMLHttpRequest: ' + e.message);
    }

    writeLog('[fail] all methods failed');
})();
