written by ChromaShell

Replaces CaelestiaFox's native messaging approach with a direct SSE connection
to the ChromaShell color server (127.0.0.1:29847/events).

- no native messaging host required
- no path substitution in Nix
- works identically for all Firefox-based browsers
- color mapping derived from caelestia-firefox-integration/src/extension.ts
- DarkReader integration intentionally omitted
