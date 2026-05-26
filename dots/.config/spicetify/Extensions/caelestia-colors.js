// Connects to the ChromaShell SSE server (127.0.0.1:29847/events) and applies
// --spice-* CSS variables from caelestia's Material You color roles.
// The server sends current colors on connect and pushes live updates on theme change.
// EventSource auto-reconnects if the connection drops.
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

    function applyScheme(data) {
        const colours = JSON.parse(data).colours;
        const root    = document.documentElement;
        for (const [spice, role] of Object.entries(SPICE_MAP)) {
            const val = colours[role];
            if (!val) continue;
            root.style.setProperty(`--spice-${spice}`, `#${val}`);
            root.style.setProperty(`--spice-rgb-${spice}`,
                `${parseInt(val.slice(0,2),16)},${parseInt(val.slice(2,4),16)},${parseInt(val.slice(4,6),16)}`);
        }
    }

    const es = new EventSource('http://127.0.0.1:29847/events');
    es.onmessage = (e) => { try { applyScheme(e.data); } catch (_) {} };
})();
