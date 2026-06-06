// Receives Material You color updates from background.js and applies them to
// the page as CSS custom properties + color-scheme declaration.
// Works on any site that uses CSS variables for theming (MD3, Bootstrap 5, etc.).

const STYLE_ID = "chromafox-theme";

function buildCSS(colours, mode) {
    const c = (role) => `#${colours[role] || "808080"}`;
    return `
:root {
    color-scheme: ${mode};

    /* Material Design 3 system tokens */
    --md-sys-color-background:              ${c("surface")};
    --md-sys-color-on-background:           ${c("onSurface")};
    --md-sys-color-surface:                 ${c("surface")};
    --md-sys-color-surface-dim:             ${c("surfaceDim")};
    --md-sys-color-surface-bright:          ${c("surfaceBright")};
    --md-sys-color-surface-container:       ${c("surfaceContainer")};
    --md-sys-color-surface-container-low:   ${c("surfaceContainerLow")};
    --md-sys-color-surface-container-high:  ${c("surfaceContainerHigh")};
    --md-sys-color-surface-container-highest: ${c("surfaceContainerHighest")};
    --md-sys-color-on-surface:              ${c("onSurface")};
    --md-sys-color-on-surface-variant:      ${c("onSurfaceVariant")};
    --md-sys-color-surface-variant:         ${c("surfaceVariant")};
    --md-sys-color-inverse-surface:         ${c("inverseSurface")};
    --md-sys-color-inverse-on-surface:      ${c("inverseOnSurface")};
    --md-sys-color-primary:                 ${c("primary")};
    --md-sys-color-on-primary:              ${c("onPrimary")};
    --md-sys-color-primary-container:       ${c("primaryContainer")};
    --md-sys-color-on-primary-container:    ${c("onPrimaryContainer")};
    --md-sys-color-primary-fixed:           ${c("primaryContainer")};
    --md-sys-color-primary-fixed-dim:       ${c("primary")};
    --md-sys-color-inverse-primary:         ${c("inversePrimary")};
    --md-sys-color-secondary:               ${c("secondary")};
    --md-sys-color-on-secondary:            ${c("onSecondary")};
    --md-sys-color-secondary-container:     ${c("secondaryContainer")};
    --md-sys-color-on-secondary-container:  ${c("onSecondaryContainer")};
    --md-sys-color-tertiary:                ${c("tertiary")};
    --md-sys-color-on-tertiary:             ${c("onTertiary")};
    --md-sys-color-tertiary-container:      ${c("tertiaryContainer")};
    --md-sys-color-on-tertiary-container:   ${c("onTertiaryContainer")};
    --md-sys-color-error:                   ${c("error")};
    --md-sys-color-on-error:                ${c("onError")};
    --md-sys-color-error-container:         ${c("errorContainer")};
    --md-sys-color-on-error-container:      ${c("onErrorContainer")};
    --md-sys-color-outline:                 ${c("outline")};
    --md-sys-color-outline-variant:         ${c("outlineVariant")};
    --md-sys-color-scrim:                   ${c("scrim")};
    --md-sys-color-shadow:                  ${c("shadow")};

    /* Bootstrap 5 */
    --bs-body-bg:               ${c("surface")};
    --bs-body-color:            ${c("onSurface")};
    --bs-emphasis-color:        ${c("onSurface")};
    --bs-secondary-bg:          ${c("surfaceContainerHigh")};
    --bs-link-color:            ${c("primary")};
    --bs-link-hover-color:      ${c("primaryContainer")};
    --bs-border-color:          ${c("outline")};

    /* Common generic variables */
    --background:       ${c("surface")};
    --foreground:       ${c("onSurface")};
    --card:             ${c("surfaceContainer")};
    --card-foreground:  ${c("onSurface")};
    --primary-color:    ${c("primary")};
    --text-color:       ${c("onSurface")};
    --link-color:       ${c("primary")};
    --border-color:     ${c("outlineVariant")};
    --accent-color:     ${c("tertiary")};
    --muted:            ${c("surfaceContainerHigh")};
    --muted-foreground: ${c("onSurfaceVariant")};
}`;
}

let _styleEl = null;

function applyColors(colours, mode) {
    if (!_styleEl) {
        _styleEl = document.createElement("style");
        _styleEl.id = STYLE_ID;
        (document.head || document.documentElement).appendChild(_styleEl);
    }
    _styleEl.textContent = buildCSS(colours, mode);
}

browser.runtime.onMessage.addListener((msg) => {
    if (msg.type === "chromafox-colors") {
        applyColors(msg.colours, msg.mode);
    }
});

// Request current colors when the page loads
browser.runtime.sendMessage({ type: "chromafox-get-colors" }).then((resp) => {
    if (resp && resp.colours) applyColors(resp.colours, resp.mode);
}).catch(() => {});
