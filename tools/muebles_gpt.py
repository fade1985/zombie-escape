# Los muebles sacados de imágenes de GPT (pedidas en pixel art sobre fondo negro puro), pasados a sprite como las
# tuberías del taller (tools/taller_tuberias.py + importar.py): se quita el fondo (solo el negro puro que se llega desde
# el borde: los contornos y los huecos, casi negros, se quedan), se recorta y se reduce MEZCLANDO colores (cada píxel,
# la media de su trozo). Así se quedan las sombras suaves, los brillos y el volumen de la imagen, como las tuberías.
# (Del 7 nov: antes se probó reducir sin mezclar, que salía dentado, y redibujarlos a mano con pocos colores planos, que
# salía limpio pero plano, de dibujo animado, al lado de las tuberías.)
# Cada mueble: su imagen de GPT, su sprite, su tamaño en píxeles (a 2 unidades por píxel) y, si es del catálogo
# (catalogo.gd; no pasa por importar.py, que lo pisaría), su .json.
#   py tools/muebles_gpt.py            → todos
#   py tools/muebles_gpt.py banco      → solo ese
#   (y luego Godot --headless --path . --import)
import json
import sys
from collections import deque
from PIL import Image

MUEBLES = {
    # el banco de trabajo del taller (arrimable.gd, mapa.gd): acero gris con el tablero perforado naranja
    "banco": ("assets/sources/banco-trabajo-gpt.webp", "assets/sprites/banco-trabajo.png", 48, 58, False),
    # la estantería del taller, entre el banco y el baúl (el "canshelf" del catálogo): de acero galvanizado con cajas
    "estanteria": ("assets/sources/estanteria-metal-gpt.webp", "assets/sprites/mueble-canshelf.png", 40, 68, True),
    # la mesa del ordenador del despacho (ordenador.gd): de nogal, con el monitor y la torre beige de los 90
    "mesa_ordenador": ("assets/sources/mesa-ordenador-gpt.webp", "assets/sprites/mesa-ordenador.png", 48, 49, False),
    # el corcho colgado en la pared del despacho, a la izquierda de la mesa (mapa.gd): sin marco, con papeles crema
    # y chinchetas doradas (antes, de tools/guias_mantenimiento.py, que ya no se usa para él)
    "corcho": ("assets/sources/corcho-gpt.webp", "assets/sprites/corcho.png", 44, 29, False),
    # la papelera del despacho, a la derecha de la mesa (el "wastebasket" del catálogo): de rejilla gris oscura con
    # papeles blancos dentro; a 14 de ancho (la vieja, 12), que a 12 la rejilla casi no se leía
    "papelera": ("assets/sources/papelera-gpt.webp", "assets/sprites/mueble-wastebasket.png", 14, 21, True,
                 [(0, 7), (13, 7)]),   # (dos píxeles negros que sobresalían a los lados, debajo del aro)
    # los dibujos de las tarjetas de «Elige edificio» (menu_principal.gd; los iconos del minimapa y los logros siguen como
    # estaban), a 32 de alto como los demás: el
    # edificio de los Apartamentos, de ladrillo con escaleras de incendios, de noche (9 nov)
    "icono_apartamentos": ("assets/sources/apartamentos-gpt.webp", "assets/ui/tarjeta-apartamentos.png", 25, 32, False),
    # y el candado de los edificios cerrados, de acero gastado con óxido; el hueco del arco, que el fondo no alcanza
    # desde el borde, se vacía también (la semilla, en el medio del arco de la imagen de GPT)
    "icono_candado": ("assets/sources/candado-gpt.webp", "assets/ui/tarjeta-candado.png", 22, 32, False, (), [(640, 350)]),
    # el «!» de las novedades (M3, 9 nov): degradado de amarillo a naranja con contorno oscuro, sin globo. El grande,
    # encima de la mesa del ordenador y de la taquilla (mapa/exclamacion.gd); el pequeño, en los iconos del escritorio de
    # ConserjeOS y en los apartados de Logros (ui/ordenador.gd, ui/archivador_logros.gd)
    "exclamacion": ("assets/sources/exclamacion-gpt.webp", "assets/sprites/exclamacion.png", 10, 28, False),
    "exclamacion_pequena": ("assets/sources/exclamacion-gpt.webp", "assets/ui/exclamacion-pequena.png", 7, 20, False),
    # la flecha amarilla pintada en el suelo que guía en la primera partida (guia.gd, Flecha; M7, 9 nov), hacia la derecha
    "flecha_guia": ("assets/sources/flecha-gpt.webp", "assets/sprites/flecha-guia.png", 20, 20, False),
    # los iconos del escritorio de ConserjeOS (ui/ordenador.gd, ICONOS; M6, 9 nov), solo para el escritorio (los de
    # assets/ui/iconos/ de siempre se siguen usando en otros sitios): Talentos, tres flechas amarillas hacia arriba
    "escritorio_talentos": ("assets/sources/escritorio-talentos-gpt.webp", "assets/ui/iconos/escritorio-talentos.png", 30, 23, False),
    # Tienda de armas, una mirilla amarilla; el centro y los cuatro huecos entre los aros, que el fondo no alcanza
    # desde el borde, se vacían también (las semillas)
    "escritorio_armas": ("assets/sources/escritorio-armas-gpt.webp", "assets/ui/iconos/escritorio-armas.png", 26, 26, False, (),
                         [(627, 627), (387, 387), (867, 387), (387, 867), (867, 867)]),
    # Logros, una copa amarilla lisa; los huecos de las asas se vacían también (las semillas)
    "escritorio_logros": ("assets/sources/escritorio-logros-gpt.webp", "assets/ui/iconos/escritorio-logros.png", 27, 25, False, (),
                          [(230, 400), (1020, 400)]),
    # Dosier VD-7, una carpeta amarilla lisa
    "escritorio_dosier": ("assets/sources/escritorio-dosier-gpt.webp", "assets/ui/iconos/escritorio-dosier.png", 28, 22, False),
    # Colecciones, un cuaderno amarillo con su etiqueta crema
    "escritorio_colecciones": ("assets/sources/escritorio-colecciones-gpt.webp", "assets/ui/iconos/escritorio-colecciones.png", 20, 27, False),
    # Apagar, el símbolo de encendido en rojo; el hueco de dentro del aro se vacía también (las semillas)
    "escritorio_apagar": ("assets/sources/escritorio-apagar-gpt.webp", "assets/ui/iconos/escritorio-apagar.png", 23, 26, False, (),
                          [(450, 750), (800, 750)]),
    # los iconos del árbol de talentos del ordenador (talentos.gd, "icono"; M2, 9 nov): uno propio por talento, sin
    # tocar los de los objetos; caben en un cuadrado de 32 (ui/arbol_talentos.gd, en_caja)
    "talento_ataque": ("assets/sources/talento-ataque-gpt.webp", "assets/ui/iconos/talento-ataque.png", 32, 32, False),
    "talento_punteria": ("assets/sources/talento-punteria-gpt.webp", "assets/ui/iconos/talento-punteria.png", 30, 32, False),
    "talento_camorrista": ("assets/sources/talento-camorrista-gpt.webp", "assets/ui/iconos/talento-camorrista.png", 32, 19, False, (),
                           [(220, 590), (490, 540), (760, 540), (1040, 590), (630, 780)]),
    "talento_tirador": ("assets/sources/talento-tirador-gpt.webp", "assets/ui/iconos/talento-tirador.png", 31, 32, False),
    "talento_artificiero": ("assets/sources/talento-artificiero-gpt.webp", "assets/ui/iconos/talento-artificiero.png", 30, 32, False, (),
                            [(690, 380)]),
    "talento_larguirucho": ("assets/sources/talento-larguirucho-gpt.webp", "assets/ui/iconos/talento-larguirucho.png", 32, 25, False),
    "talento_mirilla": ("assets/sources/talento-mirilla-gpt.webp", "assets/ui/iconos/talento-mirilla.png", 32, 32, False, (),
                        [(400, 400), (850, 400), (400, 850), (850, 850)]),
    "talento_frenesi": ("assets/sources/talento-frenesi-gpt.webp", "assets/ui/iconos/talento-frenesi.png", 32, 32, False),
    "talento_gatillo": ("assets/sources/talento-gatillo-gpt.webp", "assets/ui/iconos/talento-gatillo.png", 32, 31, False),
    "talento_racimo": ("assets/sources/talento-racimo-gpt.webp", "assets/ui/iconos/talento-racimo.png", 32, 31, False),
    "talento_veterano": ("assets/sources/talento-veterano-gpt.webp", "assets/ui/iconos/talento-veterano.png", 19, 32, False),
    "talento_fabricante": ("assets/sources/talento-fabricante-gpt.webp", "assets/ui/iconos/talento-fabricante.png", 32, 32, False),
    "talento_corpulento": ("assets/sources/talento-corpulento-gpt.webp", "assets/ui/iconos/talento-corpulento.png", 29, 32, False),
    # Ajolote (su id es "lobezno")
    "talento_lobezno": ("assets/sources/talento-lobezno-gpt.webp", "assets/ui/iconos/talento-lobezno.png", 32, 21, False),
    "talento_durito": ("assets/sources/talento-durito-gpt.webp", "assets/ui/iconos/talento-durito.png", 32, 26, False),
    "talento_reflejos": ("assets/sources/talento-reflejos-gpt.webp", "assets/ui/iconos/talento-reflejos.png", 32, 32, False),
    "talento_sanitario": ("assets/sources/talento-sanitario-gpt.webp", "assets/ui/iconos/talento-sanitario.png", 32, 32, False),
    "talento_acero": ("assets/sources/talento-acero-gpt.webp", "assets/ui/iconos/talento-acero.png", 26, 32, False),
    "talento_ninja": ("assets/sources/talento-ninja-gpt.webp", "assets/ui/iconos/talento-ninja.png", 30, 32, False),
    "talento_desfibrilador": ("assets/sources/talento-desfibrilador-gpt.webp", "assets/ui/iconos/talento-desfibrilador.png", 32, 30, False, (),
                              [(175, 570), (1085, 570)]),
    "talento_blindaje": ("assets/sources/talento-blindaje-gpt.webp", "assets/ui/iconos/talento-blindaje.png", 27, 32, False),
    "talento_sombra": ("assets/sources/talento-sombra-gpt.webp", "assets/ui/iconos/talento-sombra.png", 32, 25, False, (),
                       [(1040, 470), (560, 830), (225, 560)]),
    "talento_aliento": ("assets/sources/talento-aliento-gpt.webp", "assets/ui/iconos/talento-aliento.png", 32, 31, False),
    "talento_adrenalina": ("assets/sources/talento-adrenalina-gpt.webp", "assets/ui/iconos/talento-adrenalina.png", 32, 23, False),
    "talento_catalizador": ("assets/sources/talento-catalizador-gpt.webp", "assets/ui/iconos/talento-catalizador.png", 20, 32, False),
    "talento_guantes_goma": ("assets/sources/talento-guantes-goma-gpt.webp", "assets/ui/iconos/talento-guantes-goma.png", 32, 32, False),
    "talento_desatascador": ("assets/sources/talento-desatascador-gpt.webp", "assets/ui/iconos/talento-desatascador.png", 26, 32, False),
    "talento_incendiario": ("assets/sources/talento-incendiario-gpt.webp", "assets/ui/iconos/talento-incendiario.png", 24, 32, False),
    "talento_criogenia": ("assets/sources/talento-criogenia-gpt.webp", "assets/ui/iconos/talento-criogenia.png", 29, 32, False, (),
                          [(450, 350), (770, 350), (370, 610), (870, 610), (470, 830), (740, 830)]),
    "talento_reaccion": ("assets/sources/talento-reaccion-gpt.webp", "assets/ui/iconos/talento-reaccion.png", 32, 31, False),
    "talento_residuo": ("assets/sources/talento-residuo-gpt.webp", "assets/ui/iconos/talento-residuo.png", 32, 29, False),
    "talento_pararrayos": ("assets/sources/talento-pararrayos-gpt.webp", "assets/ui/iconos/talento-pararrayos.png", 16, 32, False),
    "talento_napalm": ("assets/sources/talento-napalm-gpt.webp", "assets/ui/iconos/talento-napalm.png", 30, 32, False, (), [(400, 540)]),
    "talento_pegajoso": ("assets/sources/talento-pegajoso-gpt.webp", "assets/ui/iconos/talento-pegajoso.png", 31, 32, False),
    "talento_voltaje": ("assets/sources/talento-voltaje-gpt.webp", "assets/ui/iconos/talento-voltaje.png", 32, 27, False),
    "talento_mezcla": ("assets/sources/talento-mezcla-gpt.webp", "assets/ui/iconos/talento-mezcla.png", 32, 32, False),
    # los tres iconos pequeños de las ramas del árbol (el emblema redondo de cada columna, que se dibuja a 24 × 24: se hacen
    # ya a ese tamaño para que no se estiren); el hueco de dentro de la correa se vacía con la semilla
    "rama_militar": ("assets/sources/rama-militar-gpt.webp", "assets/ui/iconos/rama-militar.png", 24, 23, False, (), [(620, 950)]),
    "rama_superviviente": ("assets/sources/rama-superviviente-gpt.webp", "assets/ui/iconos/rama-superviviente.png", 22, 24, False),
    "rama_quimico": ("assets/sources/rama-quimico-gpt.webp", "assets/ui/iconos/rama-quimico.png", 24, 24, False),
    # los iconos de los logros (logros.gd, "icono"; M4, 9 nov): uno propio por logro, sin tocar los de los objetos; se dibujan en un
    # cuadrado de 32 sin estirarse (ui/archivador_logros.gd, en_caja)
    "logro_primer_turno": ("assets/sources/logro-primer_turno-gpt.webp", "assets/ui/iconos/logro-primer_turno.png", 28, 32, False),
    "logro_sube_conserje": ("assets/sources/logro-sube_conserje-gpt.webp", "assets/ui/iconos/logro-sube_conserje.png", 29, 32, False),
    "logro_liquidacion": ("assets/sources/logro-liquidacion-gpt.webp", "assets/ui/iconos/logro-liquidacion.png", 32, 28, False),
    "logro_reestructuracion": ("assets/sources/logro-reestructuracion-gpt.webp", "assets/ui/iconos/logro-reestructuracion.png", 20, 32, False),
    "logro_alerta_naranja": ("assets/sources/logro-alerta_naranja-gpt.webp", "assets/ui/iconos/logro-alerta_naranja.png", 32, 24, False),
    "logro_alerta_maxima": ("assets/sources/logro-alerta_maxima-gpt.webp", "assets/ui/iconos/logro-alerta_maxima.png", 32, 29, False),
    "logro_jornada_expres": ("assets/sources/logro-jornada_expres-gpt.webp", "assets/ui/iconos/logro-jornada_expres.png", 32, 31, False),
    "logro_empleado_mes": ("assets/sources/logro-empleado_mes-gpt.webp", "assets/ui/iconos/logro-empleado_mes.png", 32, 31, False, (), [(210, 380), (1060, 380)]),
    "logro_fin_jornada": ("assets/sources/logro-fin_jornada-gpt.webp", "assets/ui/iconos/logro-fin_jornada.png", 27, 32, False),
    "logro_desahucio": ("assets/sources/logro-desahucio-gpt.webp", "assets/ui/iconos/logro-desahucio.png", 22, 32, False),
    # la ducha del vestuario y de los baños de los pisos (el "showertray" del catálogo): mampara de cristal azulado de
    # frente, con perfiles de aluminio, sobre su plato blanco
    "ducha": ("assets/sources/ducha-gpt.webp", "assets/sprites/mueble-showertray.png", 36, 66, True),
    # el lavabo de pie con su espejo, de lado (el "staffsink" del catálogo, que solo tiene dibujo de lado): para la pared
    # de la izquierda; en la de la derecha, el juego le da la vuelta
    "lavabo": ("assets/sources/lavabo-gpt.webp", "assets/sprites/mueble-staffsink-lado.png", 20, 66, True),
    # el váter, de lado (el "stafftoilet" del catálogo, que solo tiene dibujo de lado): la cisterna en la pared de la
    # izquierda y la taza con la tapa levantada; en la pared de la derecha, el juego le da la vuelta
    "vater": ("assets/sources/vater-gpt.webp", "assets/sprites/mueble-stafftoilet-lado.png", 26, 37, True),
    # el banco largo del vestuario, suelto en medio (el "lockerbench" del catálogo): listones de haya sobre tubo gris
    # con su zapatero
    "banco_vestuario": ("assets/sources/banco-vestuario-gpt.webp", "assets/sprites/mueble-lockerbench.png", 64, 28, True),
    # la taquilla de las skins, en el vestuario (mapa.gd, partida.abrir_taquilla): gris claro con tres puertas azules;
    # mismo ancho que la vieja (28), más alta que Johnny como una de verdad (antes, de tools/taquilla.py)
    "taquilla": ("assets/sources/taquilla-gpt.webp", "assets/sprites/taquilla.png", 28, 56, False),
    # la planta del pasillo de los Apartamentos (la "plantapasillo" del catálogo): un ficus mustio en su maceta de barro
    # agrietada; algo más baja que Johnny (48)
    "planta_pasillo": ("assets/sources/planta-pasillo-gpt.webp", "assets/sprites/mueble-plantapasillo.png", 24, 42, True),
}


def pasar(origen, sprite, ancho, alto, con_json, quitar=(), semillas=()):
    im = Image.open(origen).convert("RGBA")
    W, H = im.size
    px = im.load()
    # el fondo: el negro puro que se llega desde el borde
    fondo = bytearray(W * H)
    cola = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)] + list(semillas))
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= W or y >= H or fondo[y * W + x] or max(px[x, y][:3]) >= 6:
            continue
        fondo[y * W + x] = 1
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    for y in range(H):
        for x in range(W):
            if fondo[y * W + x]:
                px[x, y] = (0, 0, 0, 0)
    im = im.crop(im.getbbox())
    # mezclando colores (premultiplicado: el fondo transparente no tiñe los bordes), y el borde, sin medias tintas
    salida = im.convert("RGBa").resize((ancho, alto), Image.LANCZOS).convert("RGBA")
    salida.putalpha(salida.split()[3].point(lambda v: 255 if v > 110 else 0))
    for xy in quitar:   # los píxeles sueltos que sobran, a mano
        salida.putpixel(xy, (0, 0, 0, 0))
    salida.save(sprite)
    if con_json:
        with open(sprite.replace(".png", ".json"), "w", encoding="utf-8", newline="\n") as f:
            json.dump({"cell": [ancho, alto], "pivot": [ancho // 2, alto], "scale": 1,
                       "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
            f.write("\n")
    print(f"{sprite}: {ancho}x{alto}")


for nombre in sys.argv[1:] or list(MUEBLES):
    pasar(*MUEBLES[nombre])
