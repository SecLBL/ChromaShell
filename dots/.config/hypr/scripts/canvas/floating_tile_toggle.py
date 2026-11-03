#!/usr/bin/env python3
"""
floating_tile_toggle.py
Super+D: alterna entre mosaico y flotante en el workspace activo.

DECISION DE DISEÑO (2026-08): consolidacion de geometria en cambio de
contexto.
---------------------------------------------------------------------
Con auto_layout_mode.py en juego, una ventana puede llegar a "mosaico"
por dos caminos distintos:
  (a) estaba flotante y este script la tileo (Super+D primera vez) ->
      su posicion/tamano ORIGINAL como flotante quedan guardados en
      STATE_FILE.
  (b) se abrio directo en mosaico porque la mayoria del workspace ya
      estaba en mosaico (decision de auto_layout_mode.py) -> nunca
      tuvo una posicion flotante guardada.

El dilema: si despues de (a) se abren ventanas nuevas por (b), el
layout de mosaico se reacomoda para hacerles lugar -- la ventana de
(a) ya NO esta en el rectangulo que tenia cuando se guardo su posicion
original. Si al volver a flotante se le restaura esa posicion vieja,
queda flotando en un lugar que no tiene relacion con donde estan las
demas ventanas (que van a quedar con SU geometria de mosaico actual,
por no tener nada guardado) -- se ve desordenado, se pisan.

Solucion adoptada: comparar el conjunto de direcciones que tienen
posicion guardada contra el conjunto de ventanas que estan en mosaico
AHORA, en el momento de precionar Super+D para volver a flotante.
  - Si son el MISMO conjunto (nadie se sumo ni se fue desde que se
    guardo): nada cambio -> se restaura la posicion/tamano original
    guardado, como siempre.
  - Si son conjuntos DISTINTOS (se sumaron ventanas en mosaico desde
    entonces, o alguna guardada ya no esta): el contexto cambio -> se
    descarta lo guardado para TODAS las ventanas (incluida la que si
    tenia posicion original) y cada una vuelve a flotante conservando
    la geometria (posicion y tamaño) que tenia en mosaico justo antes
    del toggle. Esto preserva el acomodo relativo que tenian entre si
    en el mosaico, que es lo que importa visualmente en ese momento.

ORDEN DE INSERCION AL PASAR A MOSAICO (2026-08, revisado)
---------------------------------------------------------------------
Al togglear varias ventanas flotantes a mosaico de una, tanto dwindle
como master arman el arbol/stack insertando cada ventana nueva en el
lugar de la que este ENFOCADA en ese instante -- no segun su posicion
como flotante. Ademas, en master, la PRIMERA ventana tileada se vuelve
master automaticamente (sin hacer falta ningun dispatch especial tipo
"swapwithmaster" -- no hay ninguno confirmado contra la API Lua nueva,
asi que directamente se evita necesitarlo).

Con eso alcanza para controlar el acomodo con precision, segun el
layout activo (detectado via "hyprctl getoption general:layout -j",
lectura simple, no pasa por el parser de "dispatch"):

  - MASTER: se lee la orientacion configurada ("hyprctl getoption
    master:orientation -j": left/right/top/bottom). Se elige como
    master la ventana flotante mas cercana al lado del area de master
    (ej. la mas a la izquierda si orientation=left) y se la tilea
    PRIMERO. El resto se ordena por el eje perpendicular (arriba a
    abajo si el master esta a un costado, izquierda a derecha si esta
    arriba/abajo) y se tilean en ese orden para el stack. Asi "la de
    la izquierda" cae en el area de master y "la de arriba-derecha" /
    "abajo-derecha" quedan en ese orden en el stack, como layout real
    de 3 ventanas descrito por el usuario.

  - DWINDLE: se mantiene el orden por proximidad (cadena de vecino
    mas cercano) de la version anterior -- ahi el arbol de splits
    depende de la relacion de aspecto de cada ventana en el momento
    de cada division, no hay un mapeo posicional exacto posible sin
    dispatches de "preselect" que tampoco estan confirmados todavia.

En ambos casos, antes de cada toggle se enfoca explicitamente la
ventana correspondiente (hl.dsp.focus), que es lo que efectivamente
controla donde se inserta.

NOTA: el orden dentro del stack de master asume que las ventanas
tileadas despues de la primera se van agregando en el orden en que se
las tilea (de arriba a abajo, o lo que indique MASTER_STACK_REVERSE
mas abajo si tu config tiene "master:new_on_top" en el sentido
contrario). Probar y ajustar ese flag si el stack sale al reves.

Uso: python3 floating_tile_toggle.py
     (llamado desde un bind en hyprland.lua)
"""

import subprocess
import json
import sys
import os
import fcntl

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hypr_ipc import (hyprctl_json, toggle_floating_lua, move_window_exact_lua,
                       resize_window_exact_lua, focus_window_lua, move_window_tiled_lua,
                       batch, desktop_lock)
RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"  # per-user; /tmp is shared between users

LOCK_FILE  = os.path.join(RUNTIME_DIR, "floating_tile_toggle.lock")
STATE_FILE = os.path.join(RUNTIME_DIR, "floating_tile_state.json")

# ──────────────────────────────────────────────
# Integracion con el modo lienzo de Quickshell (CanvasMode.qml)
# ──────────────────────────────────────────────
# En el lienzo las ventanas reales estan ESTACIONADAS en una esquina del
# monitor (todas en el mismo punto) y lo que ves son miniaturas. Si este
# script usara las posiciones reales, el orden de tileo saldria al azar y
# la posicion "original" guardada seria la esquina. Por eso, con el lienzo
# activo:
#   1. se avisa a Quickshell ANTES de tocar nada (congela las capturas para
#      que la animacion no muestre frames rotos y guarda su geometria);
#   2. se usa la geometria que cada ventana tiene EN EL LIENZO (la escribe
#      CanvasMode.qml en CANVAS_GEO_FILE) en lugar de "at"/"size" reales.
CANVAS_STATE_FILE = os.path.join(RUNTIME_DIR, "qs_canvas_mode")
CANVAS_GEO_FILE   = os.path.join(RUNTIME_DIR, "qs_canvas_geo.json")

def canvas_active():
    return os.path.exists(CANVAS_STATE_FILE)

def canvas_prepare():
    try:
        subprocess.run(["qs", "ipc", "call", "canvas", "prepareLayout"],
                       capture_output=True, timeout=2)
    except Exception:
        pass

def apply_canvas_geometry(windows):
    """Reemplaza at/size reales por los del lienzo (solo para decidir orden
    y para guardar la posicion 'original'). Devuelve copias, no toca hyprctl."""
    try:
        with open(CANVAS_GEO_FILE) as f:
            geo = json.load(f)
    except Exception:
        return windows
    out = []
    for w in windows:
        g = geo.get(w["address"])
        if g:
            w = dict(w)
            w["at"] = [g[0], g[1]]
            w["size"] = [g[2], g[3]]
        out.append(w)
    return out


def _ts():
    import time
    return time.strftime("%H:%M:%S", time.localtime()) + f".{int(time.time()*1000)%1000:03d}"

_orig_print = print
def print(*args, **kwargs):
    _orig_print(f"[{_ts()}]", *args, **kwargs)


# ──────────────────────────────────────────────
# Estado
# ──────────────────────────────────────────────

def load_state():
    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except Exception:
        return {}

def save_state(state):
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)

def clear_state(workspace_id):
    state = load_state()
    state.pop(str(workspace_id), None)
    save_state(state)


# Si el stack de master sale en el orden contrario al esperado
# (deberia ser arriba->abajo o izquierda->derecha segun la
# orientacion), probar cambiando esto a True. Depende de como este
# configurado "master:new_on_top" en tu hyprland.lua/conf.
MASTER_STACK_REVERSE = False


# ──────────────────────────────────────────────
# Deteccion de layout activo (lectura simple, no pasa por el parser
# de "dispatch" que obliga a confirmar todo contra la wiki/en vivo)
# ──────────────────────────────────────────────

def get_current_layout():
    info = hyprctl_json(["getoption", "general:layout"]) or {}
    return (info.get("str") or "dwindle").strip().lower()

def get_master_orientation():
    info = hyprctl_json(["getoption", "master:orientation"]) or {}
    return (info.get("str") or "left").strip().lower()


# ──────────────────────────────────────────────
# Orden de insercion para dwindle -- dos estrategias disponibles
# ──────────────────────────────────────────────

def _center(w):
    return (w["at"][0] + w["size"][0] / 2.0, w["at"][1] + w["size"][1] / 2.0)

def _dist2(a, b):
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2

# Que estrategia de orden usar para dwindle: "reading" (filas por
# cercania en Y, izquierda a derecha dentro de cada fila) o
# "proximity" (cadena de vecino mas cercano, la version anterior).
# Cambiar aca para comparar cual da mejor resultado con tu forma de
# acomodar ventanas.
DWINDLE_ORDER_STRATEGY = "reading"

# Que tan cerca en Y deben estar dos ventanas para considerarse "en la
# misma fila", como fraccion de la altura promedio de las ventanas
# involucradas. Subir este numero agrupa filas mas generosamente
# (tolera mas desalineacion vertical); bajarlo las hace mas estrictas.
DWINDLE_ROW_TOLERANCE_FRAC = 0.6


def order_by_proximity(windows):
    """Ordena ventanas para minimizar el salto entre una y la
    siguiente: arranca en la mas arriba-izquierda (lectura natural) y
    en cada paso agrega la restante mas cercana a la ultima agregada.
    Es un vecino-mas-cercano voraz, no el camino optimo global, pero
    para la cantidad de ventanas tipica de un workspace (pocas
    unidades) el resultado es mas que suficiente y deterministico."""
    if not windows:
        return []
    remaining = list(windows)
    remaining.sort(key=lambda w: (_center(w)[0], _center(w)[1]))
    ordered = [remaining.pop(0)]
    while remaining:
        last_c = _center(ordered[-1])
        idx = min(range(len(remaining)), key=lambda i: _dist2(last_c, _center(remaining[i])))
        ordered.append(remaining.pop(idx))
    return ordered


def order_by_reading(windows, row_tolerance_frac=DWINDLE_ROW_TOLERANCE_FRAC):
    """Agrupa las ventanas en 'filas' segun que tan cerca esta su
    centro en Y (umbral = altura promedio * row_tolerance_frac),
    ordena las filas de arriba a abajo y, dentro de cada fila, de
    izquierda a derecha -- orden de lectura natural. A diferencia de
    la cadena de vecino mas cercano, esto no salta en diagonal entre
    ventanas: agrupa primero por altura similar, lo que tiende a dar
    un acomodo mas parecido a una grilla cuando las ventanas estan
    razonablemente alineadas entre si."""
    if not windows:
        return []
    if len(windows) == 1:
        return list(windows)

    heights = [w["size"][1] for w in windows if w["size"][1] > 0]
    avg_h = (sum(heights) / len(heights)) if heights else 100
    threshold = avg_h * row_tolerance_frac

    rows = []  # cada fila: {"members": [...], "y_sum": float}
    for w in sorted(windows, key=lambda w: _center(w)[1]):
        cy = _center(w)[1]
        for row in rows:
            row_avg_y = row["y_sum"] / len(row["members"])
            if abs(cy - row_avg_y) <= threshold:
                row["members"].append(w)
                row["y_sum"] += cy
                break
        else:
            rows.append({"members": [w], "y_sum": cy})

    rows.sort(key=lambda row: row["y_sum"] / len(row["members"]))

    ordered = []
    for row in rows:
        row["members"].sort(key=lambda w: _center(w)[0])
        ordered.extend(row["members"])
    return ordered


def order_for_dwindle(windows):
    if DWINDLE_ORDER_STRATEGY == "proximity":
        return order_by_proximity(windows)
    return order_by_reading(windows)


# ──────────────────────────────────────────────
# Pasada de correccion post-tileo para dwindle: el orden de insercion
# solo no alcanza (el split de dwindle depende de la relacion de
# aspecto del espacio en cada momento, no es un modelo secuencial
# como master), asi que despues de tilear todo se compara el orden
# real resultante contra el deseado y se corrige lo que quedo mal
# ubicado con intercambios direccionales -- bubble sort adyacente
# usando hl.dsp.window.move({direction=...}) (move_window_tiled_lua),
# que ya esta confirmado: mueve/intercambia una ventana tileada con su
# vecina en esa direccion.
# ──────────────────────────────────────────────

DWINDLE_CORRECTION_PASS = False  # desactivada: las idas y vueltas a
# hyprctl para verificar y corregir la hacian sentir lenta al usarla.
# Queda solo el orden de insercion (order_for_dwindle) sin pasada de
# verificacion -- mejora el resultado pero no lo garantiza al 100%
# como si hacia la correccion. La funcion correct_dwindle_order()
# sigue abajo por si mas adelante se quiere retomar (p.ej. optimizada
# para hacer menos consultas, o como opcion manual bajo un bind
# aparte en vez de en cada Super+D).
# Tope de intercambios para no quedar en un loop si el acomodo no
# converge (p.ej. por una relacion diagonal ambigua entre ventanas).
# n*(n-1) es la cota clasica de bubble sort por pares.

def _swap_direction(w_from, w_to):
    """Direccion (l/r/u/d) para mover w_from hacia donde esta w_to."""
    ca, cb = _center(w_from), _center(w_to)
    dx, dy = cb[0] - ca[0], cb[1] - ca[1]
    if abs(dx) >= abs(dy):
        return "r" if dx > 0 else "l"
    return "d" if dy > 0 else "u"

def correct_dwindle_order(workspace_id, desired_addrs):
    """desired_addrs: direcciones en el orden deseado (el que se uso
    para tilear). Reconsulta el estado real despues de cada
    intercambio, porque un swap puede alterar mas de lo esperado en
    el arbol de dwindle -- no se puede precalcular toda la secuencia
    de un tiro."""
    desired_index = {addr: i for i, addr in enumerate(desired_addrs)}
    n = len(desired_addrs)
    max_swaps = n * (n - 1)

    for _ in range(max_swaps):
        tiled = get_tiled_windows(workspace_id)
        actual = order_by_reading([w for w in tiled if w["address"] in desired_index])
        actual_addrs = [w["address"] for w in actual]

        swapped = False
        for i in range(len(actual) - 1):
            a_addr, b_addr = actual_addrs[i], actual_addrs[i + 1]
            if desired_index[a_addr] > desired_index[b_addr]:
                wa, wb = actual[i], actual[i + 1]
                direction = _swap_direction(wa, wb)
                batch([focus_window_lua(a_addr), move_window_tiled_lua(direction)], timeout=3)
                swapped = True
                break  # reconsultar posiciones reales antes de seguir comparando

        if not swapped:
            print(f"  orden de dwindle corregido y consistente ({len(actual_addrs)} ventanas)")
            return
    print(f"  aviso: se llego al tope de {max_swaps} intercambios sin converger del todo, "
          f"revisar el resultado visual")


# ──────────────────────────────────────────────
# Orden posicional exacto para master: la ventana mas cercana al lado
# del area de master entra primero (se vuelve master automaticamente
# al ser la primera tileada); el resto se ordena por el eje
# perpendicular para el stack.
# ──────────────────────────────────────────────

def order_for_master(windows, orientation):
    if len(windows) <= 1:
        return list(windows)

    cx = lambda w: _center(w)[0]
    cy = lambda w: _center(w)[1]

    if orientation in ("right",):
        master_key, master_reverse = cx, True   # area de master a la derecha -> la mas a la derecha
        stack_key = cy                          # stack ordenado arriba->abajo
    elif orientation in ("top",):
        master_key, master_reverse = cy, False  # area de master arriba -> la mas arriba
        stack_key = cx                          # stack ordenado izquierda->derecha
    elif orientation in ("bottom",):
        master_key, master_reverse = cy, True   # area de master abajo -> la mas abajo
        stack_key = cx
    else:  # "left" (default de Hyprland) y "center" como aproximacion
        master_key, master_reverse = cx, False  # area de master a la izquierda -> la mas a la izquierda
        stack_key = cy

    by_master_side = sorted(windows, key=master_key, reverse=master_reverse)
    master_w = by_master_side[0]
    stack_ws = [w for w in windows if w is not master_w]
    stack_ws.sort(key=stack_key, reverse=MASTER_STACK_REVERSE)

    return [master_w] + stack_ws


# ──────────────────────────────────────────────
# Lógica principal
# ──────────────────────────────────────────────

def get_active_workspace():
    ws = hyprctl_json(["activeworkspace"])
    return ws["id"] if ws else None

def get_floating_windows(workspace_id):
    clients = hyprctl_json(["clients"]) or []
    return [
        w for w in clients
        if w.get("floating") and w.get("workspace", {}).get("id") == workspace_id
    ]

def get_tiled_windows(workspace_id):
    """Todas las ventanas en mosaico del workspace, vengan de donde
    vengan (toggleadas por este script o abiertas directo en mosaico
    por auto_layout_mode.py)."""
    clients = hyprctl_json(["clients"]) or []
    return [
        w for w in clients
        if not w.get("floating")
        and w.get("workspace", {}).get("id") == workspace_id
    ]

def tile_floating_windows(workspace_id):
    """Guarda posiciones/tamaños actuales y pone en mosaico todas las
    flotantes del workspace. Todo el ciclo lectura -> decision ->
    batch va adentro de desktop_lock, para no pisarse con
    auto_layout_mode.py (misma carrera lectura-stale-y-toggle que ya
    describe la nota de hypr_ipc.py)."""
    with desktop_lock():
        windows = get_floating_windows(workspace_id)
        if not windows:
            print("No hay ventanas flotantes en el workspace activo.")
            return False
        if canvas_active():
            windows = apply_canvas_geometry(windows)

        positions = {}
        for w in windows:
            positions[w["address"]] = {
                "x": w["at"][0],
                "y": w["at"][1],
                "w": w["size"][0],
                "h": w["size"][1],
                "class": w.get("class", ""),
                "title": w.get("title", ""),
            }

        state = load_state()
        state[str(workspace_id)] = positions
        save_state(state)

        # Orden de insercion segun el layout activo: en master, mapeo
        # posicional exacto (master area + eje perpendicular para el
        # stack); en dwindle (o cualquier otro), cadena de vecino mas
        # cercano. Se enfoca cada ventana justo antes de togglearla --
        # eso es lo que controla donde se inserta en ambos layouts.
        layout = get_current_layout()
        if layout == "master":
            orientation = get_master_orientation()
            ordered = order_for_master(windows, orientation)
            print(f"Layout master (orientation={orientation}). Tileando en orden: "
                  + " -> ".join(w.get("class") or w["address"] for w in ordered))
        else:
            ordered = order_for_dwindle(windows)
            print(f"Layout {layout} (orden={DWINDLE_ORDER_STRATEGY}). Guardadas {len(positions)} ventanas. "
                  f"Tileando en orden: " + " -> ".join(w.get("class") or w["address"] for w in ordered))

        exprs = []
        for w in ordered:
            exprs.append(focus_window_lua(w["address"]))
            exprs.append(toggle_floating_lua(w["address"]))
        batch(exprs, timeout=5)

        if layout != "master" and DWINDLE_CORRECTION_PASS and len(ordered) > 1:
            correct_dwindle_order(workspace_id, [w["address"] for w in ordered])

        return True


def restore_floating_windows(workspace_id):
    """Vuelve a flotante todas las ventanas en mosaico del workspace.
    Ver docstring del modulo: decide entre restaurar posicion original
    guardada o consolidar geometria actual, segun si el conjunto de
    ventanas en mosaico cambio desde que se guardo esa posicion."""
    with desktop_lock():
        state = load_state()
        saved_positions = state.get(str(workspace_id), {})

        tiled = get_tiled_windows(workspace_id)

        if not tiled:
            print("No hay ventanas en mosaico para restaurar.")
            clear_state(workspace_id)
            return False

        tiled_addrs = {w["address"] for w in tiled}
        saved_addrs = set(saved_positions.keys())
        layout_changed = tiled_addrs != saved_addrs

        if layout_changed and saved_addrs:
            print(f"El conjunto de ventanas en mosaico cambio desde el ultimo guardado "
                  f"(guardadas: {len(saved_addrs)}, ahora: {len(tiled_addrs)}) -> "
                  f"consolidando geometria actual para todas, se descarta lo guardado.")
        positions = {} if layout_changed else saved_positions

        con_posicion = sum(1 for w in tiled if w["address"] in positions)
        print(f"Restaurando {len(tiled)} ventanas a flotante "
              f"({con_posicion} con posicion original, {len(tiled) - con_posicion} "
              f"consolidando su geometria de mosaico)...")

        # Paso 1: togglefloating a todas en un batch
        toggle_exprs = [toggle_floating_lua(w["address"]) for w in tiled]
        batch(toggle_exprs, timeout=5)

        if canvas_active():
            # En el lienzo, posicion y tamano los restaura Quickshell (las
            # miniaturas). Si aca se las moviera a las coordenadas del lienzo
            # podrian quedar TOTALMENTE fuera del monitor, y Hyprland deja de
            # mandar frames de captura de ventanas que no tocan ningun monitor
            # (miniaturas congeladas / en gris).
            clear_state(workspace_id)
            return True

        # Paso 2: redimensionar y mover, en DOS llamadas a batch()
        # separadas (no una lista combinada), para garantizar que el
        # resize termina de aplicarse antes de que arranque el move --
        # si hl.dsp.window.resize ancla el cambio de tamaño desde el
        # centro de la ventana, podria correr el x,y fijado por move.
        # Con el move como llamada final e independiente, la posicion
        # queda exacta pase lo que pase con el anclaje del resize.
        resize_exprs = []
        move_exprs = []
        for w in tiled:
            addr = w["address"]
            pos = positions.get(addr)
            if pos:
                x, y = pos["x"], pos["y"]
                w2, h2 = pos.get("w"), pos.get("h")
                origen = "original"
            else:
                x, y = w["at"][0], w["at"][1]
                w2, h2 = w["size"][0], w["size"][1]
                origen = "mosaico"
            if w2 and h2:
                resize_exprs.append(resize_window_exact_lua(w2, h2, addr))
            move_exprs.append(move_window_exact_lua(x, y, addr))
            print(f"  ✓ {pos.get('class', addr) if pos else w.get('class', addr)} "
                  f"-> ({x}, {y}) [{w2}x{h2}] ({origen})")

        if resize_exprs:
            batch(resize_exprs, timeout=5)
        if move_exprs:
            batch(move_exprs, timeout=5)

        clear_state(workspace_id)
        return True


def main():
    # Lock file: si otra instancia ya corre, salir silenciosamente
    lock_fd = open(LOCK_FILE, "w")
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print("Otra instancia ya está corriendo, ignorando.")
        sys.exit(0)

    try:
        workspace_id = get_active_workspace()
        if workspace_id is None:
            print("Error: no se pudo obtener el workspace activo.")
            sys.exit(1)

        # Direccion del toggle decidida por la composicion ACTUAL del
        # workspace, no por un flag de historial: si hay alguna
        # ventana flotante, vamos hacia mosaico (tileamos esas); si no
        # hay ninguna flotante pero si hay tileadas, vamos hacia
        # flotante (restauramos/consolidamos todas). Esto se
        # autocorrige solo si el estado guardado quedara desincronizado
        # por cualquier motivo.
        floating = get_floating_windows(workspace_id)
        if canvas_active() and (floating or get_tiled_windows(workspace_id)):
            canvas_prepare()
        # ChromaShell: "tile" / "float" force the direction (the workspace's stored
        # mode, config/canvas.lua), so one floating dialog can't turn the toggle around
        direction = sys.argv[1] if len(sys.argv) > 1 else ("tile" if floating else "float")
        if direction == "tile" and floating:
            tile_floating_windows(workspace_id)
        elif direction == "float" and get_tiled_windows(workspace_id):
            restore_floating_windows(workspace_id)
        else:
            print("Nada que cambiar en el workspace activo.")
    finally:
        fcntl.flock(lock_fd, fcntl.LOCK_UN)
        lock_fd.close()

if __name__ == "__main__":
    main()