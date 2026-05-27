#!/usr/bin/env python3
# ChromaShell SSE server — serves caelestia's scheme.json over HTTP and pushes
# live updates via Server-Sent Events whenever the file changes.
#
#   GET /                   → current scheme.json (application/json)
#   GET /events             → SSE stream; sends current colors on connect, then on every change
#   GET /element-theme.json → Element custom theme JSON (add URL once in Element settings)
import http.server
import json
import os
import pathlib
import queue
import subprocess
import threading

PORT  = 29847
STATE = (
    pathlib.Path(os.environ.get("XDG_STATE_HOME") or (os.path.expanduser("~") + "/.local/state"))
    / "caelestia/scheme.json"
)

_clients: list[queue.Queue] = []
_lock = threading.Lock()


def _watcher() -> None:
    while True:
        subprocess.run(
            ["inotifywait", "-e", "close_write", "-q", str(STATE)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        try:
            data = STATE.read_text()
        except OSError:
            continue
        with _lock:
            for q in _clients[:]:
                try:
                    q.put_nowait(data)
                except queue.Full:
                    pass


threading.Thread(target=_watcher, daemon=True).start()


def _build_element_theme(scheme: dict) -> dict:
    c = scheme.get("colours", {})
    is_dark = scheme.get("mode", "dark") == "dark"

    def hex_(key: str, fallback: str = "000000") -> str:
        return "#" + c.get(key, fallback)

    primary          = hex_("primary")
    surface          = hex_("surface")
    on_surface       = hex_("onSurface", "f0f0f0")
    on_surface_var   = hex_("onSurfaceVariant", "b0b0b0")
    surf_cont        = hex_("surfaceContainer")
    surf_cont_low    = hex_("surfaceContainerLow")
    surf_cont_high   = hex_("surfaceContainerHigh")
    outline_var      = hex_("outlineVariant")
    error            = hex_("error", "ff0000")
    primary_cont     = hex_("primaryContainer")
    success          = hex_("success", "4CAF50")

    return {
        "name": "ChromaShell",
        "is_dark": is_dark,
        "colors": {
            "accent-color":                          primary,
            "primary-color":                         primary,
            "warning-color":                         error,
            "sidebar-color":                         surface,
            "roomlist-background-color":             surf_cont_low,
            "roomlist-text-color":                   on_surface,
            "roomlist-text-secondary-color":         on_surface_var,
            "roomlist-highlights-color":             surf_cont,
            "roomlist-separator-color":              outline_var,
            "timeline-background-color":             surf_cont,
            "timeline-text-color":                   on_surface,
            "timeline-text-secondary-color":         on_surface_var,
            "timeline-highlights-color":             surf_cont_high,
            "reaction-row-button-selected-bg-color": primary_cont,
            "secondary-content":                     on_surface,
            "tertiary-content":                      on_surface_var,
        },
        "compound": {
            "--cpd-color-theme-bg":                   surface,
            "--cpd-color-bg-canvas-default":          surf_cont,
            "--cpd-color-bg-subtle-secondary":        surface,
            "--cpd-color-bg-subtle-primary":          surf_cont_low,
            "--cpd-color-bg-action-primary-rest":     primary,
            "--cpd-color-bg-accent-rest":             primary,
            "--cpd-color-bg-critical-primary":        error,
            "--cpd-color-text-primary":               on_surface,
            "--cpd-color-text-secondary":             on_surface_var,
            "--cpd-color-text-action-accent":         primary,
            "--cpd-color-text-critical-primary":      error,
            "--cpd-color-text-success-primary":       success,
            "--cpd-color-icon-accent-tertiary":       primary,
            "--cpd-color-icon-primary":               on_surface,
            "--cpd-color-icon-secondary":             on_surface_var,
            "--cpd-color-icon-tertiary":              on_surface_var,
            "--cpd-color-border-interactive-primary": outline_var,
            "--cpd-color-border-critical-primary":    error,
            "--cpd-color-border-success-subtle":      success,
        },
    }


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/events":
            self._sse()
        elif self.path == "/element-theme.json":
            self._element_theme()
        else:
            self._json()

    def _json(self) -> None:
        try:
            data = STATE.read_bytes()
        except OSError:
            self.send_response(404)
            self.end_headers()
            return
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(data)

    def _element_theme(self) -> None:
        try:
            scheme = json.loads(STATE.read_text())
        except (OSError, json.JSONDecodeError):
            self.send_response(404)
            self.end_headers()
            return
        data = json.dumps(_build_element_theme(scheme), indent=2).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(data)

    def _sse(self) -> None:
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

        q: queue.Queue = queue.Queue(maxsize=4)
        with _lock:
            _clients.append(q)
        try:
            # Send current colors immediately on connect
            self.wfile.write(f"data: {STATE.read_text()}\n\n".encode())
            self.wfile.flush()
            while True:
                self.wfile.write(f"data: {q.get()}\n\n".encode())
                self.wfile.flush()
        except Exception:
            pass
        finally:
            with _lock:
                try:
                    _clients.remove(q)
                except ValueError:
                    pass

    def log_message(self, *args) -> None:
        pass


if __name__ == "__main__":
    with http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler) as httpd:
        httpd.serve_forever()
