written by ChromaShell

ChromaFox — live browser theming for Firefox-based browsers via the ChromaShell SSE color server.

Replaces CaelestiaFox's native messaging approach with a direct SSE connection
to the ChromaShell color server (127.0.0.1:29847/events).

- no native messaging host required
- no path substitution in Nix
- works identically for all Firefox-based browsers
- color mapping derived from caelestia-firefox-integration/src/extension.ts
- DarkReader integration: connects to addon@darkreader.org via runtime.connect; themes websites with Material You surface/onSurface colors
