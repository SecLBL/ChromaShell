#!/usr/bin/env python3
"""
navigate_windows.py
Navega entre ventanas del workspace activo usando Super+flechas.

- Flotante: mueve todas las ventanas para centrar la objetivo (infinite canvas)
- Tileado master: movefocus l/r/u/d
- Tileado dwindle: movefocus left/right/up/down

Uso: python3 navigate_windows.py <left|right|up|down>
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hypr_ipc import (hyprctl_json, move_focus, move_window_exact_lua, focus_window,
                       batch_async, desktop_lock, _load_peek_state, _save_peek_state, _run)

# ChromaShell: Iridium never focused browsers here (only centred them); empty = focus everything
PROTECTED_APPS = []

DIR_SHORT = {"left": "l", "right": "r", "up": "u", "down": "d"}

# workspace being navigated, set in main() (the wallpaper parallax is per workspace)
WORKSPACE_ID = None


def notify_parallax(dx, dy):
    """Wallpaper parallax in the shell, through the canvas plugin's IPC event (if loaded)."""
    if WORKSPACE_ID is None or (dx == 0 and dy == 0):
        return
    _run(["eval", f"if hl.plugin.canvas then hl.plugin.canvas.pan({WORKSPACE_ID}, {dx}, {dy}) end"])


def movefocus(direction):
    # La wiki documenta el selector de direccion de hl.dsp.focus como l/r/u/d
    # sin importar el layout.
    move_focus(DIR_SHORT[direction])


def get_monitor_center():
    monitors = hyprctl_json(["monitors"]) or []
    for m in monitors:
        if m.get("focused"):
            # ChromaShell: width/height are the unrotated mode, logical size needs transform + scale
            w, h = m["width"], m["height"]
            if m.get("transform", 0) % 2:
                w, h = h, w
            s = m.get("scale") or 1.0
            return m["x"] + round(w / s) // 2, m["y"] + round(h / s) // 2
    return 960, 540


def get_window_center(w):
    return w["at"][0] + w["size"][0] // 2, w["at"][1] + w["size"][1] // 2


def get_window_bounds(w):
    x, y = w["at"][0], w["at"][1]
    ww, wh = w["size"][0], w["size"][1]
    return {"left": x, "right": x+ww, "top": y, "bottom": y+wh,
            "center_x": x+ww//2, "center_y": y+wh//2}


def is_protected(w):
    return any(app in w.get("class", "").lower() for app in PROTECTED_APPS)


def resolve_positions(windows):
    """Ver la misma funcion en focus_window_from_taskbar.py: devuelve
    la posicion REAL de cada ventana (no la "peekeada" en la esquina
    si tenia un peek pendiente), y cancela ese registro de una vez."""
    state = _load_peek_state()
    changed = False
    positions = {}
    for w in windows:
        addr = w["address"]
        orig = state.pop(addr, None)
        if orig is not None:
            changed = True
            positions[addr] = (orig["x"], orig["y"])
        else:
            positions[addr] = (w["at"][0], w["at"][1])
    if changed:
        _save_peek_state(state)
    return positions


def overlap_h(b1, b2):
    return not (b1["right"] <= b2["left"] or b1["left"] >= b2["right"])


def overlap_v(b1, b2):
    return not (b1["bottom"] <= b2["top"] or b1["top"] >= b2["bottom"])


def find_target(floating, current_bounds, center, direction):
    cx, cy = center

    aligned = []
    for w in floating:
        b = get_window_bounds(w)
        wx, wy = b["center_x"], b["center_y"]
        if direction == "left"  and overlap_v(current_bounds, b) and wx < cx:
            aligned.append((w, cx - wx))
        elif direction == "right" and overlap_v(current_bounds, b) and wx > cx:
            aligned.append((w, wx - cx))
        elif direction == "up"   and overlap_h(current_bounds, b) and wy < cy:
            aligned.append((w, cy - wy))
        elif direction == "down" and overlap_h(current_bounds, b) and wy > cy:
            aligned.append((w, wy - cy))

    if aligned:
        return sorted(aligned, key=lambda x: x[1])[0][0]

    same_dir = []
    for w in floating:
        b = get_window_bounds(w)
        wx, wy = b["center_x"], b["center_y"]
        if direction == "left"  and wx < cx: same_dir.append((w, cx - wx))
        elif direction == "right" and wx > cx: same_dir.append((w, wx - cx))
        elif direction == "up"   and wy < cy: same_dir.append((w, cy - wy))
        elif direction == "down" and wy > cy: same_dir.append((w, wy - cy))

    if same_dir:
        return sorted(same_dir, key=lambda x: x[1])[0][0]

    opp = {"left":"right","right":"left","up":"down","down":"up"}[direction]
    wrap = []
    for w in floating:
        b = get_window_bounds(w)
        wx, wy = b["center_x"], b["center_y"]
        if opp == "left"  and wx < cx: wrap.append((w, cx - wx))
        elif opp == "right" and wx > cx: wrap.append((w, wx - cx))
        elif opp == "up"   and wy < cy: wrap.append((w, cy - wy))
        elif opp == "down" and wy > cy: wrap.append((w, wy - cy))

    if wrap:
        return sorted(wrap, key=lambda x: x[1])[0][0]

    return None


def pan_to_window(floating, target_addr, center_x, center_y):
    target = next((w for w in floating if w["address"] == target_addr), None)
    if not target:
        return

    # Misma correccion que en focus_window_from_taskbar.py: si alguna de
    # estas ventanas estaba "peekeada" (en la esquina, por el hover del
    # taskbar) cuando se disparo esta navegacion, hay que calcular el
    # paneo desde su posicion REAL, no desde la de la esquina -- y
    # cancelar ese registro para que un restore() posterior no deshaga
    # este paneo.
    positions = resolve_positions(floating)

    tx0, ty0 = positions[target["address"]]
    tx = tx0 + target["size"][0] // 2
    ty = ty0 + target["size"][1] // 2
    dx = center_x - tx
    dy = center_y - ty

    exprs = []
    for w in floating:
        wx, wy = positions[w["address"]]
        exprs.append(move_window_exact_lua(int(wx + dx), int(wy + dy), w["address"]))

    batch_async(exprs)
    notify_parallax(dx, dy)

    if not is_protected(target):
        focus_window(target_addr)


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("left", "right", "up", "down"):
        print("Uso: navigate_windows.py <left|right|up|down>")
        sys.exit(1)

    direction = sys.argv[1]

    # Todo el ciclo "leer posiciones -> calcular -> mover" va dentro del
    # lock compartido con peek_window.py y focus_window_from_taskbar.py
    # -- ver la nota extensa en hypr_ipc.py sobre la condicion de
    # carrera que esto evita.
    with desktop_lock():
        ws = hyprctl_json(["activeworkspace"])
        if not ws:
            sys.exit(1)
        workspace_id = ws["id"]
        global WORKSPACE_ID
        WORKSPACE_ID = workspace_id

        clients = hyprctl_json(["clients"]) or []
        ws_clients = [w for w in clients if w.get("workspace", {}).get("id") == workspace_id]
        floating = [w for w in ws_clients if w.get("floating")]

        # ── modo mosaico ──────────────────────────────────────────────
        if not floating:
            movefocus(direction)
            return

        # ── modo flotante ──────────────────────────────────────
        if len(floating) <= 1:
            return

        center_x, center_y = get_monitor_center()
        focused = hyprctl_json(["activewindow"])

        window_near_center = any(
            abs(get_window_center(w)[0] - center_x) < 100 and
            abs(get_window_center(w)[1] - center_y) < 100
            for w in floating
        )

        if not focused or not focused.get("address") or not window_near_center:
            closest = min(
                floating,
                key=lambda w: (
                    ((get_window_center(w)[0] - center_x)**2 +
                     (get_window_center(w)[1] - center_y)**2) ** 0.5
                    + (1000 if is_protected(w) else 0)
                )
            )
            pan_to_window(floating, closest["address"], center_x, center_y)
            return

        current_bounds = get_window_bounds(focused)
        target = find_target(floating, current_bounds, (center_x, center_y), direction)
        if target:
            pan_to_window(floating, target["address"], center_x, center_y)


if __name__ == "__main__":
    main()