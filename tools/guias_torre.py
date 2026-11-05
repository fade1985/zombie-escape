"""Bocetos (guías) de los muebles de Torre Velaria (parte 2 del tercer edificio), con el mismo método que
tools/guias_centro.py (mira su cabecera: la perspectiva del juego y por qué hace falta una guía). Se reutilizan
sus funciones y los estilos de frente; aquí solo están los muebles de oficina y lo que lleva encima cada uno.

  py tools/guias_torre.py               → assets/sources/torre/guias/<archivo>[-lado].png
  py tools/guias_torre.py quita <png>…  quita el fondo azul de lo que devuelve PixelLab (como el de guias_centro.py)
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import guias_centro as g

g.OUT = 'assets/sources/torre/guias'

# archivo: (largo, fondo, alto, respaldo, color, estilo, lleva_lado) (ver guias_centro.py)
T = {
    'cubiculo':        (96,  48, 30, 16, (110, 120, 135), 'mesa',     True),
    'escritorio':      (100, 48, 22, 0,  (150, 150, 155), 'mesa',     True),
    'impresora':       (64,  48, 34, 0,  (190, 190, 195), 'liso',     False),
    'fotocopiadora':   (80,  52, 34, 0,  (200, 200, 205), 'liso',     False),
    'rack-servidores': (56,  44, 56, 0,  (50, 55, 65),    'puertas-2', False),
    'fuente-agua':     (32,  28, 40, 0,  (180, 200, 215), 'liso',     False),
    'sofa-vestibulo':  (96,  40, 26, 0,  (150, 70, 60),   'liso',     True),
    'recepcion':       (124, 52, 34, 0,  (125, 90, 60),   'liso',     True),
    'torno':           (48,  40, 30, 0,  (140, 145, 150), 'liso',     False),
    'archivador':      (64,  36, 46, 0,  (120, 125, 125), 'puertas-2', False),
    'mesa-juntas':     (128, 64, 20, 0,  (110, 75, 50),   'mesa',     False),
    'mesa-direccion':  (100, 56, 22, 0,  (90, 60, 40),    'mesa',     True),
    'libreria':        (80,  36, 46, 0,  (95, 70, 50),    'estantes', False),
    'mesa-mezclas':    (100, 48, 22, 0,  (50, 50, 60),    'mesa',     False),
    'pared-monitores': (100, 36, 48, 0,  (40, 45, 55),    'teles',    False),
    'armero':          (84,  40, 46, 0,  (60, 70, 60),    'puertas-3', False),
    'mesa-entrevistas': (88, 48, 20, 0,  (150, 120, 90),  'mesa',     True),
    'office-cocina':   (88,  44, 26, 0,  (170, 170, 165), 'horno',    False),
    'maqueta-torre':   (64,  64, 22, 0,  (150, 150, 155), 'mesa',     False),
    # el Plató de presentaciones (el presentador, minijefe): la fila de butacas (vista de espaldas: miran al escenario,
    # arriba), el atril, el foco de pie y la pantalla gigante de la pared
    'butacas':         (128, 36, 30, 0,  (140, 40, 50),   'butacas',  False),
    'atril':           (40,  28, 40, 0,  (60, 45, 35),    'liso',     False),
    'foco':            (40,  36, 56, 0,  (45, 45, 50),    'foco',     False),
    'pantalla-plato':  (160, 24, 64, 0,  (35, 38, 45),    'pantalla', False),
    # el laboratorio de la planta 40 (parte 6, el Sujeto 1): la cápsula de cristal con un sujeto dentro, la misma
    # abierta y vacía (cuando la presidenta la abre) y la mesa de laboratorio
    'capsula':         (48,  40, 72, 0,  (185, 195, 200), 'capsula',  False),
    'capsula-abierta': (48,  40, 72, 0,  (185, 195, 200), 'capsula-abierta', False),
    'mesa-laboratorio': (96, 48, 22, 0,  (215, 220, 222), 'mesa',     True),
}

_encima = g.encima


def encima(t, nombre, color, rnd):
    """Lo que se ve encima de cada mueble, desde arriba"""
    if nombre in ('cubiculo', 'escritorio', 'mesa-direccion', 'mesa-entrevistas'):
        t.caja(0.0, 0.0, 1.0, 0.18, g.tono(color, 0.6)) if nombre == 'cubiculo' else None   # el panel del cubículo, detrás
        t.caja(0.55, 0.25, 0.85, 0.55, (40, 42, 48))      # el monitor
        t.caja(0.58, 0.28, 0.82, 0.48, (90, 140, 150), False)   # su pantalla
        t.caja(0.5, 0.6, 0.9, 0.8, (200, 200, 205))       # el teclado
        t.caja(0.08, 0.3, 0.3, 0.7, (225, 225, 215))      # papeles
        if nombre == 'mesa-entrevistas':
            t.caja(0.0, 0.55, 0.14, 0.95, (60, 60, 70))   # una silla
    elif nombre in ('impresora', 'fotocopiadora'):
        t.caja(0.06, 0.1, 0.94, 0.5, g.tono(color, 0.85))   # la tapa del escáner
        t.caja(0.1, 0.6, 0.5, 0.9, (70, 75, 85))             # el panel de mandos
        t.caja(0.6, 0.6, 0.9, 0.9, (225, 225, 215))          # la bandeja con papel
    elif nombre == 'rack-servidores':
        t.caja(0, 0, 1, 0.12, g.tono(color, 0.6))
        t.caja(0.1, 0.2, 0.9, 0.9, g.tono(color, 1.0))
        for k in range(3):
            t.caja(0.2, 0.3 + k * 0.2, 0.8, 0.36 + k * 0.2, (30, 35, 40), False)   # las rejillas
    elif nombre == 'fuente-agua':
        t.caja(0.2, 0.2, 0.8, 0.8, (150, 190, 215))   # la garrafa de agua, vista desde arriba
        t.caja(0.35, 0.35, 0.65, 0.65, (225, 240, 250), False)
    elif nombre == 'sofa-vestibulo':
        t.caja(0, 0, 1, 0.25, g.tono(color, 0.6))     # el respaldo, contra la pared
        t.caja(0.04, 0.3, 0.5, 0.95, g.tono(color, 1.1))   # dos cojines
        t.caja(0.5, 0.3, 0.96, 0.95, g.tono(color, 1.1))
    elif nombre == 'recepcion':
        t.caja(0.03, 0.1, 0.97, 0.4, g.tono(color, 0.7))   # el tablero alto de atrás
        t.caja(0.1, 0.5, 0.3, 0.9, (60, 60, 65))           # el ordenador
        t.caja(0.6, 0.5, 0.8, 0.8, (225, 225, 215))        # papeles
        t.caja(0.4, 0.55, 0.5, 0.75, (170, 40, 40))        # un timbre
    elif nombre == 'torno':
        t.caja(0.35, 0.1, 0.65, 0.9, (60, 65, 70))         # el brazo del torno
        t.caja(0.1, 0.1, 0.25, 0.4, (90, 190, 120), False)   # su lector
    elif nombre == 'archivador':
        t.caja(0, 0, 1, 0.12, g.tono(color, 0.6))
        t.caja(0.1, 0.25, 0.9, 0.9, g.tono(color, 1.0))
        t.caja(0.15, 0.4, 0.5, 0.7, (225, 225, 215))       # carpetas encima
    elif nombre == 'mesa-juntas':
        t.caja(0.06, 0.0, 0.94, 0.18, (60, 60, 70))        # las sillas de un lado
        t.caja(0.06, 0.82, 0.94, 1.0, (60, 60, 70))
        t.caja(0.0, 0.2, 1.0, 0.8, g.tono(color, 1.1))     # la mesa
        t.caja(0.4, 0.35, 0.6, 0.65, (40, 40, 45))         # el teléfono de conferencia
    elif nombre == 'libreria':
        t.caja(0, 0, 1, 0.12, g.tono(color, 0.6))
        t.caja(0.06, 0.2, 0.94, 0.9, g.tono(color, 1.0))
    elif nombre == 'mesa-mezclas':
        t.caja(0.05, 0.2, 0.7, 0.8, (30, 30, 35))          # la mesa de mezclas
        for k in range(8):
            t.caja(0.1 + k * 0.07, 0.3, 0.12 + k * 0.07, 0.7, (170, 170, 180), False)   # sus deslizadores
        t.caja(0.74, 0.15, 0.95, 0.5, (40, 42, 48))        # un monitor
    elif nombre == 'pared-monitores':
        t.caja(0, 0, 1, 0.12, g.tono(color, 0.6))
        t.caja(0.04, 0.2, 0.96, 0.9, (30, 34, 40))
    elif nombre == 'armero':
        t.caja(0, 0, 1, 0.12, g.tono(color, 0.6))
        t.caja(0.06, 0.2, 0.94, 0.9, g.tono(color, 1.0))
    elif nombre == 'office-cocina':
        t.caja(0.05, 0.15, 0.4, 0.85, (190, 195, 200))     # el fregadero
        t.caja(0.12, 0.3, 0.33, 0.7, (120, 125, 130), False)
        t.caja(0.5, 0.1, 0.8, 0.6, (70, 75, 80))           # el microondas
        t.caja(0.84, 0.2, 0.96, 0.6, (50, 50, 55))         # la cafetera
    elif nombre == 'maqueta-torre':
        t.caja(0.05, 0.05, 0.95, 0.95, (225, 225, 215))    # la base de la maqueta
        for i in range(3):
            for j in range(3):
                t.caja(0.12 + i * 0.28, 0.12 + j * 0.28, 0.3 + i * 0.28, 0.3 + j * 0.28,
                       (170, 185, 200) if (i + j) % 2 else (130, 150, 175))   # los edificios en miniatura
    elif nombre == 'butacas':
        for k in range(4):   # los cuatro asientos, vistos desde arriba, con los reposabrazos entre ellos
            t.caja(0.03 + k * 0.245, 0.0, 0.24 + k * 0.245, 0.75, g.tono(color, 1.15))
            t.caja(k * 0.245, 0.0, 0.03 + k * 0.245, 1.0, (40, 40, 45), False)
    elif nombre == 'atril':
        t.caja(0.1, 0.1, 0.9, 0.8, g.tono(color, 1.2))     # el tablero inclinado
        t.caja(0.25, 0.2, 0.75, 0.6, (225, 225, 215))      # los papeles del discurso
        t.caja(0.45, 0.0, 0.55, 0.25, (30, 30, 30), False)   # el micrófono de cuello de cisne
    elif nombre == 'foco':
        t.caja(0.15, 0.1, 0.85, 0.9, (30, 30, 35))         # el foco, de lado, sobre su trípode
        t.caja(0.25, 0.65, 0.75, 0.95, (240, 235, 190), False)   # su cristal, mirando al público
    elif nombre in ('capsula', 'capsula-abierta'):
        t.caja(0.05, 0.05, 0.95, 0.95, (150, 160, 165))    # la tapa de acero de arriba
        t.caja(0.3, 0.3, 0.7, 0.7, (60, 200, 140), False)  # su luz verde
    elif nombre == 'mesa-laboratorio':
        t.caja(0.06, 0.2, 0.2, 0.7, (120, 210, 150))       # probetas y matraces
        t.caja(0.25, 0.25, 0.35, 0.6, (170, 120, 210))
        t.caja(0.45, 0.2, 0.75, 0.75, (60, 65, 70))        # un microscopio
        t.caja(0.8, 0.3, 0.95, 0.8, (225, 225, 215))       # papeles
    elif nombre == 'pantalla-plato':
        t.caja(0, 0, 1, 0.5, g.tono(color, 0.6))
    else:
        _encima(t, nombre, color, rnd)


g.encima = encima

_frente = g.frente


def frente(dr, x, y, w, h, color, estilo, rnd):
    """Los frentes nuevos del plató; los demás, los de guias_centro.py"""
    if estilo == 'butacas':
        # los respaldos de las cuatro butacas, vistos por detrás, y sus patas
        bw = w // 4
        for k in range(4):
            dr.rectangle((x + k * bw + g.S, y, x + (k + 1) * bw - g.S - 1, y + h - 5 * g.S), fill=g.tono(color, 0.8), outline=g.RAYA)
        dr.rectangle((x, y + h - 5 * g.S, x + w - 1, y + h - 3 * g.S), fill=(40, 40, 45, 255), outline=g.RAYA)
        for px in (x + g.S, x + w - 4 * g.S):
            dr.rectangle((px, y + h - 3 * g.S, px + 3 * g.S - 1, y + h - 1), fill=(40, 40, 45, 255), outline=g.RAYA)
        return
    if estilo == 'foco':
        # el trípode: una barra y tres patas abiertas
        cx = x + w // 2
        dr.rectangle((cx - g.S, y, cx + g.S, y + h - 6 * g.S), fill=(60, 60, 65, 255), outline=g.RAYA)
        for px in (x + g.S, cx, x + w - 2 * g.S):
            dr.line((cx, y + h - 6 * g.S, px, y + h - 1), fill=g.RAYA, width=g.S)
        return
    if estilo == 'pantalla':
        # la pantalla gigante, apagada, con su marco
        dr.rectangle((x, y, x + w - 1, y + h - 1), fill=g.tono(color, 0.7), outline=g.RAYA)
        dr.rectangle((x + 3 * g.S, y + 3 * g.S, x + w - 3 * g.S, y + h - 3 * g.S), fill=(70, 95, 130, 255), outline=g.RAYA)
        return
    if estilo in ('capsula', 'capsula-abierta'):
        # el tubo de cristal con su base de acero; dentro, la silueta de un sujeto flotando en líquido verde
        dr.rectangle((x, y + h - 6 * g.S, x + w - 1, y + h - 1), fill=(120, 125, 130, 255), outline=g.RAYA)
        if estilo == 'capsula':
            dr.rectangle((x + 2 * g.S, y, x + w - 3 * g.S, y + h - 6 * g.S), fill=(120, 190, 160, 255), outline=g.RAYA)
            cx = x + w // 2
            dr.ellipse((cx - 4 * g.S, y + 6 * g.S, cx + 4 * g.S, y + 14 * g.S), fill=(70, 90, 80, 255))
            dr.rectangle((cx - 5 * g.S, y + 14 * g.S, cx + 5 * g.S, y + h - 12 * g.S), fill=(70, 90, 80, 255))
        else:
            dr.rectangle((x + 2 * g.S, y, x + w - 3 * g.S, y + h - 6 * g.S), fill=(60, 70, 72, 255), outline=g.RAYA)
            dr.rectangle((x + w - 5 * g.S, y, x + w + 0 * g.S, y + h - 6 * g.S), fill=(170, 200, 205, 255), outline=g.RAYA)
        return
    _frente(dr, x, y, w, h, color, estilo, rnd)


g.frente = frente

if __name__ == '__main__':
    if sys.argv[1:2] == ['quita']:
        for r in sys.argv[2:]:
            g.quita(r)
        sys.exit()
    for nombre, (largo, fondo, alto, respaldo, color, estilo, con_lado) in T.items():
        g.guia(nombre, largo, fondo, alto, respaldo, color, estilo, False)
        if con_lado:
            g.guia(nombre, largo, fondo, alto, respaldo, color, estilo, True)
