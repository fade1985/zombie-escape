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
    else:
        _encima(t, nombre, color, rnd)


g.encima = encima

if __name__ == '__main__':
    if sys.argv[1:2] == ['quita']:
        for r in sys.argv[2:]:
            g.quita(r)
        sys.exit()
    for nombre, (largo, fondo, alto, respaldo, color, estilo, con_lado) in T.items():
        g.guia(nombre, largo, fondo, alto, respaldo, color, estilo, False)
        if con_lado:
            g.guia(nombre, largo, fondo, alto, respaldo, color, estilo, True)
