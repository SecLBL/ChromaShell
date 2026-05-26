// Fetches caelestia's scheme.json (single source of truth for Material You color roles)
// from the local socket service and applies --spice-* CSS variables dynamically.
(async () => {
    while (typeof Spicetify === 'undefined' || !Spicetify.showNotification) {
        await new Promise(r => setTimeout(r, 300));
    }

    // Mapping from spicetify variable names to Material You color roles.
    // Derived from caelestia-cli's spicetify-dark.ini template.
    const SPICE_MAP = {
        'text':               'onSurface',
        'subtext':            'onSurfaceVariant',
        'main':               'surfaceContainer',
        'highlight':          'primary',
        'misc':               'primary',
        'notification':       'outline',
        'notification-error': 'error',
        'shadow':             'shadow',
        'card':               'surfaceContainerHigh',
        'player':             'secondaryContainer',
        'sidebar':            'surface',
        'main-elevated':      'surfaceContainerHigh',
        'highlight-elevated': 'surfaceContainerHighest',
        'selected-row':       'onSurface',
        'button':             'primary',
        'button-active':      'primary',
        'button-disabled':    'outline',
        'tab-active':         'surfaceContainerHigh',
    };

    try {
        const res = await fetch('http://127.0.0.1:29847/');
        if (!res.ok) {
            Spicetify.showNotification('[caelestia] colors socket: HTTP ' + res.status, true, 4000);
            return;
        }
        const scheme = await res.json();
        const colours = scheme.colours;
        const root    = document.documentElement;

        for (const [spice, role] of Object.entries(SPICE_MAP)) {
            const val = colours[role];
            if (!val) continue;
            root.style.setProperty(`--spice-${spice}`, `#${val}`);
            root.style.setProperty(`--spice-rgb-${spice}`,
                `${parseInt(val.slice(0,2),16)},${parseInt(val.slice(2,4),16)},${parseInt(val.slice(4,6),16)}`);
        }
    } catch (e) {
        Spicetify.showNotification('[caelestia] colors socket nicht erreichbar: ' + e.message, true, 4000);
    }
})();
