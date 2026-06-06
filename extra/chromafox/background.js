// Connects to the ChromaShell SSE server (127.0.0.1:29847/events) and applies
// live Material You colors to the browser theme via the WebExtension theme API.
// Sends current colors on connect, then pushes updates on every caelestia theme change.

const COLOR_MAP = {
    bookmark_text:                  "onSurface",
    button_background_hover:        "surfaceContainerHigh",
    button_background_active:       "surfaceContainerHighest",
    icons:                          "secondary",
    icons_attention:                "primary",
    frame:                          "surfaceDim",
    frame_inactive:                 "surfaceDim",
    tab_text:                       "onSurface",
    tab_loading:                    "primary",
    tab_background_text:            "outline",
    tab_selected:                   "surfaceContainer",
    tab_line:                       "surfaceContainer",
    toolbar:                        "surfaceContainer",
    toolbar_text:                   "onSurface",
    toolbar_field:                  "surfaceBright",
    toolbar_field_focus:            "surfaceBright",
    toolbar_field_border:           "surfaceBright",
    toolbar_field_border_focus:     "primary",
    toolbar_field_text:             "onSurfaceVariant",
    toolbar_field_text_focus:       "onSurface",
    toolbar_field_highlight:        "primary",
    toolbar_field_highlight_text:   "onPrimary",
    toolbar_field_separator:        "surface",
    toolbar_top_separator:          "surfaceContainer",
    toolbar_bottom_separator:       "surface",
    toolbar_vertical_separator:     "secondaryContainer",
    ntp_background:                 "surface",
    ntp_card_background:            "surfaceContainer",
    ntp_text:                       "onSurface",
    popup:                          "surfaceContainer",
    popup_border:                   "outlineVariant",
    popup_text:                     "onSurface",
    popup_highlight:                "primary",
    popup_highlight_text:           "onPrimary",
    sidebar:                        "surfaceContainerHigh",
    sidebar_border:                 "surfaceContainerHigh",
    sidebar_text:                   "onSurface",
    sidebar_highlight:              "secondaryContainer",
    sidebar_highlight_text:         "onSecondaryContainer",
};

// Dark Reader connector — graceful no-op if Dark Reader is not installed.
const DR_EXT_ID = "addon@darkreader.org";
let _drPort = null;

function _drConnect() {
    try {
        _drPort = browser.runtime.connect(DR_EXT_ID, { name: "chromafox" });
        _drPort.onDisconnect.addListener(() => {
            _drPort = null;
            setTimeout(_drConnect, 5000);
        });
    } catch (_) {
        _drPort = null;
    }
}
_drConnect();

function applyDarkReader(scheme) {
    if (!_drPort) return;
    const c = scheme.colours;
    try {
        _drPort.postMessage({
            type: "setTheme",
            data: {
                mode:                       scheme.mode === "dark" ? 1 : 2,
                brightness:                 100,
                contrast:                   100,
                sepia:                      0,
                darkSchemeBackgroundColor:  `#${c.surface}`,
                darkSchemeTextColor:        `#${c.onSurface}`,
                lightSchemeBackgroundColor: `#${c.surface}`,
                lightSchemeTextColor:       `#${c.onSurface}`,
                scrollbarColor:             "auto",
                selectionColor:             "auto",
            },
        });
    } catch (_) {}
}

function applyTheme(data) {
    const scheme  = JSON.parse(data);
    const colours = scheme.colours;
    const colors  = {};
    for (const [key, role] of Object.entries(COLOR_MAP)) {
        const val = colours[role];
        if (val) colors[key] = `#${val}`;
    }
    browser.theme.update({
        colors,
        properties: {
            color_scheme:         scheme.mode,
            content_color_scheme: scheme.mode,
        },
    });
    applyDarkReader(scheme);
}

const es = new EventSource("http://127.0.0.1:29847/events");
es.onmessage = (e) => { try { applyTheme(e.data); } catch (_) {} };
