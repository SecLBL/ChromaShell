#!/usr/bin/env python3
"""
auto_layout_mode.py

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
from hypr_ipc import toggle_floating, desktop_lock

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


def decide_and_apply(new_address):
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

        others = [w for w in clients
                  if w.get('address') != new_address
                  and w.get('workspace', {}).get('id') == ws_id
                  and w.get('class', '') not in IGNORE_CLASSES]

        if not others:
            return  # primera ventana del workspace: se queda como la dejo el rule (floating)

        floating_count = sum(1 for w in others if w.get('floating'))
        tiled_count = len(others) - floating_count

        if floating_count == tiled_count:
            return  # empate: no se toca, gana el comportamiento por defecto (floating)

        should_be_floating = floating_count > tiled_count
        is_floating = bool(new_win.get('floating', False))

        # ChromaShell: tiling is the default and windows that open floating got
        # there via a window rule (dialogs, pavucontrol, ...), so only ever
        # promote tiled -> floating, never demote.
        if should_be_floating and not is_floating:
            toggle_floating(new_address)


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
                if not line.startswith('openwindow>>'):
                    continue
                payload = line[len('openwindow>>'):]
                addr_raw = payload.split(',', 1)[0]
                if not addr_raw:
                    continue
                try:
                    decide_and_apply(normalize_address(addr_raw))
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
