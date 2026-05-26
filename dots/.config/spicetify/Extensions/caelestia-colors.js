// Reads caelestia's color.ini at startup and applies --spice-* CSS variables dynamically.
(async () => {
    while (typeof Spicetify === 'undefined' || !Spicetify.showNotification) {
        await new Promise(r => setTimeout(r, 300));
    }

    const notify = (msg, err) => {
        try { Spicetify.showNotification('[caelestia] ' + msg, !!err, 6000); } catch (_) {}
    };

    try {
        // Get env vars via /proc/self/environ (works with fetch file:// in Electron)
        async function readEnv() {
            const res = await fetch('file:///proc/self/environ');
            if (!res.ok) return null;
            const env = {};
            for (const entry of (await res.text()).split('\0')) {
                const eq = entry.indexOf('=');
                if (eq > 0) env[entry.slice(0, eq)] = entry.slice(eq + 1);
            }
            return env;
        }

        let colorIniPath;

        // Try process.env first (works if nodeIntegration is enabled)
        if (typeof process !== 'undefined' && process.env?.HOME) {
            const base = process.env.XDG_CONFIG_HOME || (process.env.HOME + '/.config');
            colorIniPath = base + '/spicetify/Themes/caelestia/color.ini';
        } else {
            // Fall back to /proc/self/environ
            const env = await readEnv().catch(() => null);
            if (!env?.HOME) { notify('HOME nicht ermittelbar (process + /proc fehlgeschlagen)', true); return; }
            const base = env.XDG_CONFIG_HOME || (env.HOME + '/.config');
            colorIniPath = base + '/spicetify/Themes/caelestia/color.ini';
        }

        const fileUrl = 'file://' + colorIniPath;
        notify('Pfad: ' + colorIniPath); // temporary: confirm path is correct

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

        function applyColors(content, method) {
            const colors = parseSection(content, 'caelestia');
            const n      = Object.keys(colors).length;
            if (n === 0) { notify('0 Farben geparst (' + method + ')', true); return; }
            const root = document.documentElement;
            for (const [key, val] of Object.entries(colors)) {
                root.style.setProperty(`--spice-${key}`, `#${val}`);
                const r = parseInt(val.slice(0, 2), 16);
                const g = parseInt(val.slice(2, 4), 16);
                const b = parseInt(val.slice(4, 6), 16);
                root.style.setProperty(`--spice-rgb-${key}`, `${r},${g},${b}`);
            }
            notify(n + ' Farben via ' + method);
        }

        const errors = [];

        // Method 1: window.require (Node.js require, unaffected by webpack's local const require)
        try {
            const req = window.require;
            if (typeof req === 'function') {
                applyColors(req('fs').readFileSync(colorIniPath, 'utf8'), 'window.require');
                return;
            }
            errors.push('window.require=' + typeof req);
        } catch (e) { errors.push('window.require: ' + e.message); }

        // Method 2: fetch with file://
        try {
            const res = await fetch(fileUrl);
            if (res.ok) { applyColors(await res.text(), 'fetch'); return; }
            errors.push('fetch: status=' + res.status);
        } catch (e) { errors.push('fetch: ' + e.message); }

        // Method 3: XMLHttpRequest with file://
        try {
            const content = await new Promise((resolve, reject) => {
                const xhr = new XMLHttpRequest();
                xhr.open('GET', fileUrl, true);
                xhr.onload  = () => (xhr.status === 0 || xhr.status === 200)
                    ? resolve(xhr.responseText)
                    : reject(new Error('status=' + xhr.status));
                xhr.onerror = () => reject(new Error('network error'));
                xhr.send();
            });
            applyColors(content, 'XHR');
            return;
        } catch (e) { errors.push('XHR: ' + e.message); }

        notify('alle Methoden gescheitert: ' + errors.join(' | '), true);

    } catch (e) {
        notify('crash: ' + e.message, true);
    }
})();
