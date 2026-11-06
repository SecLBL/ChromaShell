#!/usr/bin/env python3
"""
hypr_ipc.py
Capa de compatibilidad con hyprctl para Hyprland >= 0.55 (config Lua).

POR QUE EXISTE ESTE ARCHIVO
----------------------------
Desde Hyprland 0.55, `hyprctl dispatch <dispatcher> <args...>` (la sintaxis
posicional vieja de hyprlang, ej. `dispatch togglefloating address:0x123`)
ya NO funciona. hyprctl ahora parsea el argumento de `dispatch` como una
expresion Lua real y la ejecuta contra el namespace hl.dsp.*.

No es un bug ni algo especifico de tu hyprland.lua: es un cambio de diseño
deliberado, confirmado por el mantenedor de Hyprland (vaxerski) como
"expected behavior" cuando alguien reporto exactamente este problema.
Ver: github.com/hyprwm/Hyprland/discussions/14255

Sintaxis nueva (confirmada contra wiki.hypr.land/Configuring/Basics/Dispatchers):

    hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })'

en vez de:

    hyprctl dispatch togglefloating

Este modulo centraliza TODAS las llamadas a `hyprctl dispatch` para que,
cuando Hyprland vuelva a cambiar la API (va a pasar, esto es -git de hace
semanas), solo haya que tocar un archivo.

QUE ESTA CONFIRMADO
---------------------
Todo lo de este archivo esta confirmado contra la wiki oficial Y contra
pruebas en vivo con hyprctl (2026-07-01): toggle_floating, focus_window,
move_focus, move_window_tiled, exec_cmd, y tambien las dos funciones que
antes estaban marcadas como sin confirmar: move_window_exact_lua y
resize_window_exact_lua.

La wiki no publica el nombre de campo para posicionamiento/tamano exacto
por pixel, asi que se descubrio disparando la llamada a proposito y leyendo
el mensaje de error de Hyprland, que lista los argumentos esperados:

    $ hyprctl dispatch 'hl.dsp.window.move({ window = "activewindow", coords = {100,100} })'
    error: hl.window.move: unrecognized arguments.
           Expected one of: direction, x+y(+relative), workspace, into_group, out_of_group

    $ hyprctl dispatch 'hl.dsp.window.resize({ window = "activewindow", x = 100, y = 100 })'
    ok   # -> ventana redimensionada a 100x100px, confirmado visualmente

Osea: tanto window.move como window.resize usan los campos "x" / "y"
sueltos (no "coords" ni "size" como tabla), con "relative" opcional que
por defecto se comporta como absoluto (relative = false).
"""
import subprocess
import json
import fcntl
from contextlib import contextmanager
import os
RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"  # per-user; /tmp is shared between users


def _run(args, timeout=2):
    return subprocess.run(["hyprctl"] + args, capture_output=True, text=True, timeout=timeout)


def hyprctl_json(args, timeout=2):
    """Llamadas de solo lectura (clients, activewindow, monitors, etc).
    Estas NO pasan por el parser de dispatch, siguen funcionando igual
    que antes en Lua config."""
    r = _run(args + ["-j"], timeout=timeout)
    return json.loads(r.stdout) if r.stdout.strip() else None


def bar_height():
    """ChromaShell: height of the hyprbars title bar floating windows get (it sits
    above the window), 0 when the plugin isn't loaded."""
    try:
        return int((hyprctl_json(["getoption", "plugin:hyprbars:bar_height"]) or {}).get("int", 0))
    except (ValueError, AttributeError):
        return 0


# ─────────────────────────────────────────────────────────────
# CONDICION DE CARRERA REAL (encontrada 2026-07-29): varios scripts
# (peek_window.py, focus_window_from_taskbar.py, navigate_windows.py)
# hacen lo mismo -- leen "hyprctl clients -j" para saber DONDE esta
# cada ventana AHORA MISMO, calculan un movimiento en base a eso, y lo
# aplican. Si dos de estos corren casi al mismo tiempo (ej.: soltas el
# hover de un icono -- dispara restore() -- y clickeas OTRO antes de
# que termine -- dispara focus_window_from_taskbar.py), el segundo
# script puede leer la posicion a MITAD de camino del primero y
# calcular un movimiento incorrecto (mas chico del que hace falta).
# Repetido varias veces esto se ve como "las ventanas se van acercando
# de a poco" en vez de centrarse de una.
#
# Arreglo: un lock de archivo (fcntl.flock, exclusivo y BLOQUEANTE)
# compartido entre los 3 scripts. El que llega primero se queda con el
# lock hasta terminar su ciclo completo de "leer posiciones -> mover";
# el otro espera en la fila en vez de leer datos a medio aplicar.
# Cualquier script que lea posiciones de "clients -j" y despues las
# use para mover ventanas DEBE envolver ese ciclo completo con esto.
# ─────────────────────────────────────────────────────────────

DESKTOP_LOCK_FILE = os.path.join(RUNTIME_DIR, "qs_infinite_desktop.lock")


@contextmanager
def desktop_lock():
    fd = open(DESKTOP_LOCK_FILE, "w")
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        fcntl.flock(fd, fcntl.LOCK_UN)
        fd.close()


def dispatch(lua_expr, timeout=2):
    """Ejecuta hyprctl dispatch '<lua_expr>'.
    lua_expr debe ser una llamada completa a hl.dsp.*(...)"""
    return _run(["dispatch", lua_expr], timeout=timeout)


def dispatch_async(lua_expr):
    subprocess.Popen(["hyprctl", "dispatch", lua_expr],
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def batch(lua_exprs, timeout=5):
    """lua_exprs: lista de llamadas completas a hl.dsp.*(...)"""
    cmd = " ; ".join(f"dispatch {e}" for e in lua_exprs)
    return subprocess.run(["hyprctl", "--batch", cmd], capture_output=True, timeout=timeout)


def batch_async(lua_exprs):
    if not lua_exprs:
        return
    cmd = " ; ".join(f"dispatch {e}" for e in lua_exprs)
    subprocess.Popen(["hyprctl", "--batch", cmd],
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


# ─────────────────────────────────────────────────────────────
# Confirmado contra la wiki oficial
# ─────────────────────────────────────────────────────────────

def toggle_floating_lua(address=None):
    w = f', window = "address:{address}"' if address else ""
    return f'hl.dsp.window.float({{ action = "toggle"{w} }})'

def toggle_floating(address=None):
    return dispatch(toggle_floating_lua(address))


def focus_window_lua(address):
    return f'hl.dsp.focus({{ window = "address:{address}" }})'

def focus_window(address):
    return dispatch(focus_window_lua(address))


def move_focus_lua(direction_lud):  # 'l' | 'r' | 'u' | 'd'
    return f'hl.dsp.focus({{ direction = "{direction_lud}" }})'

def move_focus(direction_lud):
    return dispatch(move_focus_lua(direction_lud))


def move_window_tiled_lua(direction_lud):
    return f'hl.dsp.window.move({{ direction = "{direction_lud}" }})'

def move_window_tiled(direction_lud):
    return dispatch(move_window_tiled_lua(direction_lud))


def exec_cmd_lua(cmd):
    escaped = cmd.replace('\\', '\\\\').replace('"', '\\"')
    return f'hl.dsp.exec_cmd("{escaped}")'


# ─────────────────────────────────────────────────────────────
# Confirmado en vivo contra hyprctl (2026-07-01). Equivalentes de:
#     dispatch movewindowpixel exact X Y,address:ADDR
#     dispatch resizewindowpixel exact W H,address:ADDR
# ─────────────────────────────────────────────────────────────

def move_window_exact_lua(x, y, address):
    return (f'hl.dsp.window.move({{ window = "address:{address}", '
            f'x = {int(x)}, y = {int(y)}, relative = false }})')

def move_window_exact(x, y, address, timeout=2):
    return dispatch(move_window_exact_lua(x, y, address), timeout=timeout)

def move_window_exact_async(x, y, address):
    dispatch_async(move_window_exact_lua(x, y, address))


def resize_window_exact_lua(w, h, address):
    return (f'hl.dsp.window.resize({{ window = "address:{address}", '
            f'x = {int(w)}, y = {int(h)}, relative = false }})')

def resize_window_exact(w, h, address, timeout=2):
    return dispatch(resize_window_exact_lua(w, h, address), timeout=timeout)


# ─────────────────────────────────────────────────────────────
# ABANDONADO DEFINITIVAMENTE (2026-07-29), segundo intento fallido:
# incluso con el desktop_lock protegiendo la secuencia de la carrera
# entre scripts, el toggle disable->move->enable de "windowsMove"
# termino afectando animaciones de OTRAS operaciones (drag, etc.), no
# solo el peek. La wiki explica por que esto es dificil de aislar: los
# cambios de config (incluida "hl.animation") se aplican via un "prop
# refresh" agrupado al FINAL de cada evento, no linea por linea -- nuestras
# 3 llamadas a hyprctl (disable/move/enable) son 3 eventos separados,
# sin garantia de que el estado se "asiente" limpio entre uno y el
# siguiente antes de que otra animacion arranque. No hay forma
# confirmada de evitar esto con lo que expone Hyprland hoy: no existe
# un dispatcher de "warp"/instantaneo para window.move (los unicos
# campos validos son direction, x+y(+relative), workspace,
# into_group, out_of_group), ni un window_rule de on/off para
# animacion especifico de una ventana ("immediate" es para tearing en
# juegos, no tiene relacion). NO USAR move_window_instant -- queda
# solo como referencia de lo que se probo. El peek/restore usa
# move_window_exact, igual que cualquier otro movimiento de ventana.
#
# Si en algun momento la animacion de windowsMove queda en un estado
# raro por los intentos anteriores, esto la deja explicitamente en los
# valores que le gustan al usuario:
#   hyprctl eval 'hl.animation({ leaf = "windowsMove", enabled = true, speed = 8, bezier = "default" })'
# ─────────────────────────────────────────────────────────────

def get_animation_leaf(leaf, timeout=2):
    r = _run(["animations", "-j"], timeout=timeout)
    try:
        data = json.loads(r.stdout)
    except Exception:
        return None
    anims = data[0] if (isinstance(data, list) and len(data) == 2
                        and isinstance(data[0], list)) else data
    if not isinstance(anims, list):
        return None
    for a in anims:
        if isinstance(a, dict) and a.get("name") == leaf:
            return a
    return None


def get_effective_animation(leaf, timeout=2):
    info = get_animation_leaf(leaf, timeout=timeout)
    if info and info.get("overridden") and info.get("speed"):
        return info
    return get_animation_leaf("global", timeout=timeout)


def set_windows_move_animation(enabled, timeout=2):
    if not enabled:
        return _run(["eval", 'hl.animation({ leaf = "windowsMove", enabled = false })'],
                    timeout=timeout)

    info = get_effective_animation("windowsMove", timeout=timeout)
    speed = (info.get("speed") if info else None) or 8
    bezier = info.get("bezier") if info else None
    style = info.get("style") if info else None

    fields = [f'leaf = "windowsMove"', "enabled = true", f"speed = {speed}"]
    if bezier:
        fields.append(f'bezier = "{bezier}"')
    if style:
        fields.append(f'style = "{style}"')

    expr = "hl.animation({ " + ", ".join(fields) + " })"
    return _run(["eval", expr], timeout=timeout)


def move_window_instant(x, y, address, timeout=2):
    """Como move_window_exact, pero apaga la animacion de windowsMove
    justo antes del salto y la reactiva justo despues -- SOLO para
    usar desde dentro de un "with desktop_lock():" ya tomado por quien
    llama (ver nota arriba)."""
    set_windows_move_animation(False, timeout=timeout)
    result = move_window_exact(x, y, address, timeout=timeout)
    set_windows_move_animation(True, timeout=timeout)
    return result




# ─────────────────────────────────────────────────────────────
# Estado compartido del peek del taskbar (ver peek_window.py). Vive
# aca, no solo en peek_window.py, porque focus_window_from_taskbar.py
# TAMBIEN necesita consultarlo: si el usuario clickea una ventana
# mientras esta peekeada (en la esquina), hay que devolverla a su
# posicion REAL antes de calcular el paneo de centrado -- si no, el
# paneo se calcula desde la posicion peekeada (cerca del borde) en vez
# de la posicion real, dando un dx/dy incorrecto que "encoge" el
# canvas un poco en cada click sobre una ventana lejana (bug real
# reportado por el usuario).
# ─────────────────────────────────────────────────────────────

PEEK_STATE_FILE = os.path.join(RUNTIME_DIR, "qs_peek_state.json")


def _load_peek_state():
    try:
        with open(PEEK_STATE_FILE) as f:
            return json.load(f)
    except Exception:
        return {}


def _save_peek_state(state):
    try:
        with open(PEEK_STATE_FILE, "w") as f:
            json.dump(state, f)
    except Exception:
        pass


def pop_peek_original_pos(address):
    """Si 'address' tiene una posicion original guardada por un peek
    pendiente, la quita del registro y la devuelve como {"x":.., "y":..}.
    Si no hay nada guardado, devuelve None."""
    state = _load_peek_state()
    orig = state.pop(address, None)
    if orig is not None:
        _save_peek_state(state)
    return orig