#!/usr/bin/env python3
"""
auto_layout_mode.py

ChromaShell: a new window floats when its workspace is a canvas (stored mode,
config/canvas.lua), sized and placed at the cursor. The majority rule below is
Iridium's and no longer applies.

Decide automaticamente floating vs mosaico para cada ventana NUEVA,
segun cual sea el modo mayoritario entre las ventanas ya abiertas en
el mismo workspace.

POR QUE ESTO NO SE PUEDE HACER SOLO CON hyprland.lua
------------------------------------------------------
El window_rule actual:

    hl.window_rule({
        name  = "todas-flotantes",
        match = { class = ".*" },
        float = true,
    })

matchea por clase/titulo via regex. Es declarativo: se evalua contra
propiedades ESTATICAS de la ventana (su clase, su titulo), no contra
estado dinamico como "cuantas ventanas hay abiertas ahora mismo y en
que modo estan". No hay forma de expresar esa condicion dentro del
propio rule. Por eso hace falta un proceso separado que escuche
eventos de Hyprland y decida en tiempo real -- este script.

El window_rule NO se borra: se deja tal cual, funciona como el
comportamiento por defecto/fallback (ventana nueva sin vecinas ->
floating, igual que ahora). Este script solo actua DESPUES de que la
ventana ya abrio (y por lo tanto ya recibio el float=true del rule):
si la mayoria del workspace esta en mosaico, la destila con un
toggle. Si la mayoria esta floating, o hay empate, o es la primera
ventana del workspace, no toca nada.

COMO DETECTA VENTANAS NUEVAS
-------------------------------
Se conecta directo al socket2 de Hyprland (el socket de EVENTOS, no
el de comandos que usa hyprctl) y escucha lineas "openwindow>>...".
Formato del evento: openwindow>>ADDRESS,WORKSPACENAME,CLASS,TITLE
La ADDRESS que manda el evento viene SIN el prefijo "0x" (a
diferencia de "hyprctl clients -j", que si lo trae), por eso se
normaliza antes de comparar/usar.

INTEGRACION
-------------
Se lanza en background al iniciar sesion, igual que infinite-desktop.sh
(exec-once en hyprland.lua, o agregado a un script de arranque
existente). Es un proceso aparte e independiente de
infinite_desktop_core.py: no comparte hilos ni el lock de
desktop_lock, solo reusa hypr_ipc.py para el dispatch.
"""
import sys, os, socket, subprocess, json, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hypr_ipc import (desktop_lock, batch, hyprctl_json, bar_height, toggle_floating_lua,
                      resize_window_exact_lua, move_window_exact_lua)

# ChromaShell: size of a new canvas window, share of its monitor's free area: long side
# (width) and short side (height), so portrait monitors get wide windows too
NEW_SIZE = (0.5, 0.5)  # keep in line with canvas.float_size (config/canvas.lua)


def canvas_geometry(win):
    """New canvas windows: NEW_SIZE of the monitor, centred on the cursor, kept inside
    the monitor's free area. Without this they keep their brief tiled size and all
    land on top of each other in the middle."""
    mon = next((m for m in hyprctl_json(['monitors']) or [] if m.get('id') == win.get('monitor')), None)
    pos = hyprctl_json(['cursorpos'])
    if not mon or not pos:
        return None
    w, h = mon['width'], mon['height']
    if mon.get('transform', 0) % 2:   # rotated 90/270
        w, h = h, w
    s = mon.get('scale') or 1.0
    rl, rt, rr, rb = (mon.get('reserved') or [0, 0, 0, 0])[:4]
    left, top = mon['x'] + rl, mon['y'] + rt
    right, bottom = mon['x'] + round(w / s) - rr, mon['y'] + round(h / s) - rb
    fw, fh = right - left, bottom - top
    nw, nh = min(round(max(fw, fh) * NEW_SIZE[0]), fw), min(round(min(fw, fh) * NEW_SIZE[1]), fh)
    cx, cy = pos['x'], pos['y']
    if not (mon['x'] <= cx < mon['x'] + round(w / s) and mon['y'] <= cy < mon['y'] + round(h / s)):
        # cursor on another monitor (window sent there by keybind): its free area's centre
        cx, cy = (left + right) / 2, (top + bottom) / 2
    x = min(max(round(cx - nw / 2), left), right - nw)
    y = min(max(round(cy - nh / 2), top), bottom - nh)
    bar = bar_height()   # the box holds the title bar above the window too
    return x, y + bar, nw, nh - bar

# Ventanas cuya clase no deberia entrar en el conteo ni ser tocada
# (ajustar segun necesidad -- p.ej. paneles/overlays de quickshell que
# ya manejan su propio floating y no deberian ser "destilados").
IGNORE_CLASSES = set()

RETRY_DELAYS = (0.0, 0.05, 0.15)  # reintentos por si el evento llega
                                   # antes de que "clients -j" refleje
                                   # la ventana nueva


def get_socket2_path():
    sig = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')
    runtime = os.environ.get('XDG_RUNTIME_DIR') or f'/run/user/{os.getuid()}'
    if not sig:
        raise RuntimeError("HYPRLAND_INSTANCE_SIGNATURE no esta seteada")
    return f'{runtime}/hypr/{sig}/.socket2.sock'


def get_clients():
    try:
        r = subprocess.run(['hyprctl', 'clients', '-j'],
                            capture_output=True, text=True, timeout=1)
        return json.loads(r.stdout)
    except Exception:
        return []


def normalize_address(addr):
    addr = addr.strip()
    return addr if addr.startswith('0x') else f'0x{addr}'


# ChromaShell: on/off from the shell config (Nexus: ChromaShell Extras > Canvas),
# read per window so a change applies right away
SHELL_CONFIG = os.path.join(os.environ.get('XDG_CONFIG_HOME') or os.path.expanduser('~/.config'),
                            'caelestia', 'shell.json')


def enabled():
    try:
        with open(SHELL_CONFIG) as f:
            return json.load(f).get('general', {}).get('canvas', {}).get('autoLayout', True) is not False
    except (OSError, ValueError):
        return True


# ChromaShell: the workspace's stored mode (hypr config/canvas.lua), not a count of
# floating windows, so empty workspaces can be canvases too
MODES_FILE = os.path.join(os.environ.get('XDG_RUNTIME_DIR') or '/tmp', 'canvas-modes.json')


def read_modes():
    try:
        with open(MODES_FILE) as f:
            modes = json.load(f)
        return modes if isinstance(modes, dict) else {}
    except (OSError, ValueError):
        return {}


def is_canvas(ws_id):
    return read_modes().get(str(ws_id)) is True


def set_canvas(ws_id, canvas):
    modes = read_modes()
    if (modes.get(str(ws_id)) is True) == canvas:
        return
    if canvas:
        modes[str(ws_id)] = True
    else:
        modes.pop(str(ws_id), None)
    with open(MODES_FILE, 'w') as f:   # in place, not via rename: the bar watches this file
        json.dump(modes, f)


def sync_mode(address):
    """A window was floated or tiled by hand: all windows of its workspace floating
    -> canvas, all tiled -> tiling, mixed -> the mode stays (a canvas keeps a tiled
    window, a tiling workspace a floating dialog)."""
    clients = get_clients()
    win = next((w for w in clients if w.get('address') == address), None)
    if win is None:
        return
    ws_id = win.get('workspace', {}).get('id')
    on_ws = [w for w in clients if w.get('workspace', {}).get('id') == ws_id]
    floating = sum(1 for w in on_ws if w.get('floating'))
    if floating == len(on_ws):
        set_canvas(ws_id, True)
    elif floating == 0:
        set_canvas(ws_id, False)


def decide_and_apply(new_address):
    if not enabled():
        return

    # La espera con retry (que puede tardar hasta ~0.2s) se hace FUERA
    # del lock: no tiene sentido bloquear a floating_tile_toggle.py
    # mientras esperamos a que la ventana aparezca en "clients -j".
    # Recien tomamos el lock para la parte que importa: leer el estado
    # que vamos a usar para decidir, y aplicar el toggle en base a eso,
    # como una operacion atomica frente a Super+D.
    new_win = None
    for delay in RETRY_DELAYS:
        if delay:
            time.sleep(delay)
        clients = get_clients()
        new_win = next((w for w in clients if w.get('address') == new_address), None)
        if new_win is not None:
            break
    if new_win is None:
        return  # la ventana ya cerro, o el evento llego corrupto

    if new_win.get('class', '') in IGNORE_CLASSES:
        return

    with desktop_lock():
        # Releer clients() ya DENTRO del lock: el snapshot de arriba
        # (tomado antes de tomar el lock) puede haber quedado viejo si
        # floating_tile_toggle.py corrio un batch mientras esperabamos
        # el lock.
        clients = get_clients()
        new_win = next((w for w in clients if w.get('address') == new_address), None)
        if new_win is None:
            return

        ws_id = new_win.get('workspace', {}).get('id')
        if ws_id is None:
            return

        # ChromaShell: tiling is the default and windows that open floating got
        # there via a window rule (dialogs, pavucontrol, ...), so only ever
        # promote tiled -> floating on canvas workspaces, never demote.
        if is_canvas(ws_id) and not new_win.get('floating', False):
            exprs = [toggle_floating_lua(new_address)]
            geo = canvas_geometry(new_win)
            if geo:
                x, y, w, h = geo
                exprs += [resize_window_exact_lua(w, h, new_address), move_window_exact_lua(x, y, new_address)]
            batch(exprs)


def listen_loop():
    path = get_socket2_path()
    buf = ''
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(path)
        print(f"[auto_layout_mode] conectado a {path}", flush=True)
        while True:
            data = s.recv(4096)
            if not data:
                raise ConnectionError("socket2 cerro la conexion")
            buf += data.decode('utf-8', errors='ignore')
            while '\n' in buf:
                line, buf = buf.split('\n', 1)
                if line.startswith('openwindow>>'):
                    handler = decide_and_apply
                elif line.startswith('changefloatingmode>>'):
                    handler = sync_mode
                else:
                    continue
                addr_raw = line.split('>>', 1)[1].split(',', 1)[0]
                if not addr_raw:
                    continue
                try:
                    handler(normalize_address(addr_raw))
                except Exception as e:
                    print(f"[auto_layout_mode] error procesando {line!r}: {e}", flush=True)


def main():
    # Reconecta solo si el socket2 se cae (p.ej. Hyprland recargo); no
    # deberia pasar en uso normal, pero es gratis protegerse.
    while True:
        try:
            listen_loop()
        except Exception as e:
            print(f"[auto_layout_mode] desconectado ({e}), reintentando en 2s...", flush=True)
            time.sleep(2)


if __name__ == '__main__':
    main()
