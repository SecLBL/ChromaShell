// Popup logic: settings management, current-site controls, list rendering.
// Applies current scheme colors to the popup via CSS custom properties.

let _domain    = "";
let _blacklist = [];
let _whitelist = [];

// ── Color theming for the popup itself ────────────────────────────────────
async function applySchemeColors() {
    try {
        const resp = await browser.runtime.sendMessage({ type: "chromafox-get-colors" });
        if (!resp || !resp.colours) return;
        const c = resp.colours;
        const root = document.documentElement;
        root.style.setProperty("--bg",       `#${c.surface}`);
        root.style.setProperty("--bg-card",  `#${c.surfaceContainer}`);
        root.style.setProperty("--text",     `#${c.onSurface}`);
        root.style.setProperty("--text-dim", `#${c.onSurfaceVariant}`);
        root.style.setProperty("--accent",   `#${c.primary}`);
        root.style.setProperty("--danger",   `#${c.error}`);
        root.style.setProperty("--border",   `#${c.outlineVariant}`);
    } catch (_) {}
}

// ── Storage helpers ───────────────────────────────────────────────────────
async function loadSettings() {
    const { enabled = true, blacklist = [], whitelist = [] } =
        await browser.storage.local.get(["enabled", "blacklist", "whitelist"]);
    _blacklist = blacklist;
    _whitelist = whitelist;
    return { enabled, blacklist, whitelist };
}

async function saveList(key, list) {
    await browser.storage.local.set({ [key]: list });
}

// ── Render ────────────────────────────────────────────────────────────────
function renderList(ulId, countId, list, removeKey) {
    const ul    = document.getElementById(ulId);
    const badge = document.getElementById(countId);
    badge.textContent = list.length;
    ul.innerHTML = "";
    for (const d of list) {
        const li  = document.createElement("li");
        li.textContent = d;
        const btn = document.createElement("button");
        btn.className   = "remove";
        btn.textContent = "✕";
        btn.title       = `Remove ${d}`;
        btn.onclick = async () => {
            const updated = list.filter(x => x !== d);
            if (removeKey === "blacklist") _blacklist = updated;
            else                           _whitelist = updated;
            await saveList(removeKey, updated);
            renderUI();
        };
        li.appendChild(btn);
        ul.appendChild(li);
    }
}

function renderUI() {
    const inBlack = _blacklist.includes(_domain);
    const inWhite = _whitelist.includes(_domain);

    const btnBlock = document.getElementById("btnBlock");
    const btnAllow = document.getElementById("btnAllow");

    if (inBlack) {
        btnBlock.textContent = "Unblock";
        btnBlock.className   = "btn active-block";
    } else {
        btnBlock.textContent = "Block";
        btnBlock.className   = "btn";
    }

    if (inWhite) {
        btnAllow.textContent = "Remove from allowed";
        btnAllow.className   = "btn active-allow";
    } else {
        btnAllow.textContent = "Allow only";
        btnAllow.className   = "btn";
    }

    renderList("blacklistEl", "blacklistCount", _blacklist, "blacklist");
    renderList("whitelistEl", "whitelistCount", _whitelist, "whitelist");
}

// ── Init ──────────────────────────────────────────────────────────────────
async function init() {
    await applySchemeColors();

    const { enabled } = await loadSettings();

    // Current tab domain
    try {
        const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
        if (tab && tab.url && !tab.url.startsWith("moz-extension://")) {
            _domain = new URL(tab.url).hostname.replace(/^www\./, "");
        }
    } catch (_) {}
    document.getElementById("currentDomain").textContent = _domain || "—";

    // Global toggle
    const toggle = document.getElementById("globalToggle");
    toggle.checked = enabled;
    toggle.onchange = async () => {
        await browser.storage.local.set({ enabled: toggle.checked });
    };

    // Block button
    document.getElementById("btnBlock").onclick = async () => {
        if (!_domain) return;
        if (_blacklist.includes(_domain)) {
            _blacklist = _blacklist.filter(d => d !== _domain);
        } else {
            _blacklist = [..._blacklist, _domain];
            _whitelist = _whitelist.filter(d => d !== _domain);
        }
        await Promise.all([
            saveList("blacklist", _blacklist),
            saveList("whitelist", _whitelist),
        ]);
        renderUI();
    };

    // Allow-only button
    document.getElementById("btnAllow").onclick = async () => {
        if (!_domain) return;
        if (_whitelist.includes(_domain)) {
            _whitelist = _whitelist.filter(d => d !== _domain);
        } else {
            _whitelist = [..._whitelist, _domain];
            _blacklist = _blacklist.filter(d => d !== _domain);
        }
        await Promise.all([
            saveList("blacklist", _blacklist),
            saveList("whitelist", _whitelist),
        ]);
        renderUI();
    };

    renderUI();
}

init();
