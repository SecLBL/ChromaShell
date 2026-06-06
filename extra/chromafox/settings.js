// Settings page: configure which Material You role feeds each CSS override target.

const ROLES = [
    "surface", "surfaceDim", "surfaceBright",
    "surfaceContainer", "surfaceContainerLow", "surfaceContainerHigh", "surfaceContainerHighest",
    "surfaceVariant", "onSurface", "onSurfaceVariant",
    "inverseSurface", "inverseOnSurface",
    "primary", "onPrimary", "primaryContainer", "onPrimaryContainer", "inversePrimary",
    "secondary", "onSecondary", "secondaryContainer", "onSecondaryContainer",
    "tertiary", "onTertiary", "tertiaryContainer", "onTertiaryContainer",
    "error", "onError", "errorContainer", "onErrorContainer",
    "outline", "outlineVariant", "scrim", "shadow",
];

const DEFAULTS = {
    bodyBg:       "surface",
    bodyText:     "onSurface",
    linkColor:    "primary",
    visitedColor: "secondary",
};

const FIELDS = ["bodyBg", "bodyText", "linkColor", "visitedColor"];

let _savedTimer = null;

// ── Scheme colors ─────────────────────────────────────────────────────────
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

// ── Populate selects ──────────────────────────────────────────────────────
function buildOptions(selectEl, currentValue) {
    selectEl.innerHTML = "";
    for (const role of ROLES) {
        const opt = document.createElement("option");
        opt.value       = role;
        opt.textContent = role;
        if (role === currentValue) opt.selected = true;
        selectEl.appendChild(opt);
    }
}

// ── Save feedback ─────────────────────────────────────────────────────────
function flashSaved() {
    const el = document.getElementById("savedMsg");
    el.textContent = "Saved";
    el.classList.add("visible");
    clearTimeout(_savedTimer);
    _savedTimer = setTimeout(() => el.classList.remove("visible"), 1500);
}

// ── Persist ───────────────────────────────────────────────────────────────
async function saveColorMap(colorMap) {
    await browser.storage.local.set({ colorMap });
    flashSaved();
}

function readColorMap() {
    return Object.fromEntries(
        FIELDS.map(key => [key, document.getElementById(key).value])
    );
}

// ── Init ──────────────────────────────────────────────────────────────────
async function init() {
    await applySchemeColors();

    const { colorMap = {} } = await browser.storage.local.get("colorMap");
    const merged = { ...DEFAULTS, ...colorMap };

    for (const key of FIELDS) {
        const sel = document.getElementById(key);
        buildOptions(sel, merged[key]);
        sel.onchange = () => saveColorMap(readColorMap());
    }

    document.getElementById("btnReset").onclick = async () => {
        for (const key of FIELDS) {
            document.getElementById(key).value = DEFAULTS[key];
        }
        await saveColorMap({ ...DEFAULTS });
    };
}

init();
