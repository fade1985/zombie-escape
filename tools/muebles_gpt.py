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
    # el dibujo de la fregona para la mochila (inventario.gd, como los de la tienda de armas: en diagonal, de 48 con aire alrededor;
    # 13 nov). Sale a 44x44 y se centra en 48x48 al final de este archivo (el mocho, abajo a la izquierda)
    "fregona": ("assets/sources/fregona-gpt.png", "assets/ui/tienda/fregona.png", 44, 44, False),
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
    # y el del Centro comercial, a juego: cuatro plantas de hormigón, el cartel luminoso con la bolsa de la compra (sin
    # letras: a 32 de alto no se leerían), el toldo rojo y blanco y los escaparates con luz (11 nov, bloque M)
    "icono_centro": ("assets/sources/centro-gpt.webp", "assets/ui/tarjeta-centro.png", 23, 32, False),
    # los aparatos de la azotea (planta.gd, AZOTEA_APARATOS; 11 nov, bloque M): el aire acondicionado industrial, gris
    # sucio con su ventilador y dos cables, y la torre de antena de celosía roja y blanca. La torre es toda huecos: el
    # negro de entre las barras no se llega desde el borde, así que se vacía todo el negro puro ("negro")
    "aire_acondicionado": ("assets/sources/aire-acondicionado-gpt.webp", "assets/sprites/mueble-acunit.png", 64, 57, True),
    "torre_antena": ("assets/sources/torre-antena-gpt.webp", "assets/sprites/mueble-antennas.png", 36, 86, True, (), "negro"),
    # y el candado de los edificios cerrados, de acero gastado con óxido; el hueco del arco, que el fondo no alcanza
    # desde el borde, se vacía también (la semilla, en el medio del arco de la imagen de GPT)
    "icono_candado": ("assets/sources/candado-gpt.webp", "assets/ui/tarjeta-candado.png", 22, 32, False, (), [(640, 350)]),
    # el mismo candado, para los iconos de 32x32 (17 nov: el único candado del juego; el minimapa, en las salas cerradas y
    # la salida de incendios, y el árbol de talentos), y la calavera de la sala del jefe del centro comercial con la
    # llave maestra cogida (minimapa.gd). Se centran en un lienzo de 32x32 al final de este archivo
    "mapa_candado": ("assets/sources/candado-gpt.webp", "assets/ui/iconos/candado.png", 16, 23, False, (), [(640, 350)]),
    "mapa_calavera": ("assets/sources/calavera-gpt.webp", "assets/ui/iconos/calavera.png", 18, 24, False),
    # el «!» de las novedades (M3, 9 nov): degradado de amarillo a naranja con contorno oscuro, sin globo. El grande,
    # encima de la mesa del ordenador y de la taquilla (mapa/exclamacion.gd); el pequeño, en los iconos del escritorio de
    # ConserjeOS y en los apartados de Logros (ui/ordenador.gd, ui/archivador_logros.gd)
    "exclamacion": ("assets/sources/exclamacion-gpt.webp", "assets/sprites/exclamacion.png", 10, 28, False),
    "exclamacion_pequena": ("assets/sources/exclamacion-gpt.webp", "assets/ui/exclamacion-pequena.png", 7, 20, False),
    # la interrogación grande de los sujetos que aún no se han visto (ui/ordenador.gd, programa Sujetos, y ui/taquilla.gd;
    # 12 nov): rehecha más fina (L35, 13 nov), GPT con una interrogación curva de modelo; trazo de 2 píxeles, a su rejilla
    # justa, 32 px de la imagen por píxel. Sale amarilla: después, py tools/colorear_iconos.py la pone casi negra
    "interrogacion": ("assets/sources/interrogacion-gpt.webp", "assets/ui/interrogacion.png", 14, 33, False),
    # el fondo del menú del banco de trabajo (ui/inventario.gd, pintar_banco; 12 nov): el banco de frente, con el tablero
    # perforado y el cajón, del tamaño del lienzo del menú (912 × 616, a 2 unidades por píxel). Sin fondo que quitar
    "banco_fondo": ("assets/sources/banco-fondo-gpt.webp", "assets/ui/banco-fondo.png", 456, 308, False),
    # la flecha amarilla pintada en el suelo que guía en la primera partida (guia.gd, Flecha; M7, 9 nov), hacia la derecha
    "flecha_guia": ("assets/sources/flecha-gpt.webp", "assets/sprites/flecha-guia.png", 20, 20, False),
    # los iconos del escritorio de ConserjeOS (ui/ordenador.gd, ICONOS; M6, 9 nov), solo para el escritorio (los de
    # assets/ui/iconos/ de siempre se siguen usando en otros sitios): Talentos, tres flechas amarillas hacia arriba
    # (Talentos y la Tienda de armas salen amarillos: después se pasa py tools/colorear_iconos.py, que pone cada
    # flecha del color de su rama, la mirilla de metal,
    # la carpeta del Dosier en marrón y el cuaderno de Sujetos casi negro, 12 nov)
    "escritorio_talentos": ("assets/sources/escritorio-talentos-gpt.webp", "assets/ui/iconos/escritorio-talentos.png", 30, 23, False),
    # Tienda de armas, una mirilla amarilla; el centro y los cuatro huecos entre los aros, que el fondo no alcanza
    # desde el borde, se vacían también (las semillas)
    "escritorio_armas": ("assets/sources/escritorio-armas-gpt.webp", "assets/ui/iconos/escritorio-armas.png", 26, 26, False, (),
                         [(627, 627), (387, 387), (867, 387), (387, 867), (867, 867)]),
    # Logros, una copa amarilla lisa; los huecos de las asas se vacían también (las semillas)
    "escritorio_logros": ("assets/sources/escritorio-logros-gpt.webp", "assets/ui/iconos/escritorio-logros.png", 27, 25, False, (),
                          [(230, 400), (1020, 400)]),
    # Dosier VD-7, una carpeta amarilla lisa (colorear_iconos.py la pone marrón)
    "escritorio_dosier": ("assets/sources/escritorio-dosier-gpt.webp", "assets/ui/iconos/escritorio-dosier.png", 28, 22, False),
    # Colecciones, un cuaderno amarillo con su etiqueta crema (colorear_iconos.py lo pone casi negro)
    "escritorio_colecciones": ("assets/sources/escritorio-colecciones-gpt.webp", "assets/ui/iconos/escritorio-colecciones.png", 20, 27, False),
    # Apagar, el símbolo de encendido en rojo; el hueco de dentro del aro se vacía también (las semillas)
    "escritorio_apagar": ("assets/sources/escritorio-apagar-gpt.webp", "assets/ui/iconos/escritorio-apagar.png", 23, 26, False, (),
                          [(450, 750), (800, 750)]),
    # Vídeos, un «play» amarillo (aro con un triángulo dentro, 10 nov); el hueco entre el aro y el triángulo se vacía
    # también (las semillas)
    "escritorio_videos": ("assets/sources/escritorio-videos-gpt.webp", "assets/ui/iconos/escritorio-videos.png", 26, 26, False, (),
                          [(380, 620), (900, 620)]),
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
    # el mutágeno (15 nov): la doble hélice de ADN mutado, con manchas y gotas verdes, que sueltan los durmientes (partida.gd,
    # soltar_mutageno) y que sale en el inventario junto a los dólares. Los huecos entre peldaños, todo el negro puro
    "mutageno": ("assets/sources/mutageno-gpt.webp", "assets/ui/iconos/mutageno.png", 30, 32, False, (), "negro"),
    # los materiales de mejora de las armas (Objetos.PIEZAS; Fase 4, 15 nov): un engranaje de bronce (cuerpo a cuerpo), uno
    # de plata (a distancia), uno de oro (especiales) y un matraz con líquido verde (lanzables). Salen a 30 de alto y se
    # centran en un lienzo de 32x32 al final de este archivo, como los iconos de antes
    "pieza_cuerpo": ("assets/sources/pieza-cuerpo-gpt.webp", "assets/ui/iconos/obj-pieza_cuerpo.png", 30, 30, False),
    "pieza_distancia": ("assets/sources/pieza-distancia-gpt.webp", "assets/ui/iconos/obj-pieza_distancia.png", 30, 30, False),
    "pieza_especial": ("assets/sources/pieza-especial-gpt.webp", "assets/ui/iconos/obj-pieza_especial.png", 30, 30, False),
    "pieza_arrojable": ("assets/sources/pieza-arrojable-gpt.webp", "assets/ui/iconos/obj-pieza_arrojable.png", 20, 30, False),
    # la comida favorita de cada superviviente (Objetos.COMIDAS; M124, 16 nov): dónut (policía), manzana (médica), lata de
    # judías (militar), yogur de fresa (farmacéutica), bocadillo de chorizo (ferretero), bebida energética (técnico), porción
    # de pizza (informático joven), termo de café (limpiadora de noche) y ensalada (recepcionista). Como los materiales:
    # a 30 de lado lo más largo, centrados en un lienzo de 32x32 al final de este archivo
    "comida_donut": ("assets/sources/comida-donut-gpt.webp", "assets/ui/iconos/obj-donut.png", 30, 29, False),
    "comida_manzana": ("assets/sources/comida-manzana-gpt.webp", "assets/ui/iconos/obj-manzana.png", 27, 30, False),
    "comida_judias": ("assets/sources/comida-judias-gpt.webp", "assets/ui/iconos/obj-judias.png", 18, 30, False),
    "comida_yogur": ("assets/sources/comida-yogur-gpt.webp", "assets/ui/iconos/obj-yogur.png", 26, 30, False),
    "comida_bocadillo": ("assets/sources/comida-bocadillo-gpt.webp", "assets/ui/iconos/obj-bocadillo.png", 30, 15, False),
    "comida_energetica": ("assets/sources/comida-energetica-gpt.webp", "assets/ui/iconos/obj-energetica.png", 12, 30, False),
    "comida_pizza": ("assets/sources/comida-pizza-gpt.webp", "assets/ui/iconos/obj-pizza.png", 30, 26, False),
    "comida_cafe": ("assets/sources/comida-cafe-gpt.webp", "assets/ui/iconos/obj-cafe.png", 19, 30, False),
    "comida_ensalada": ("assets/sources/comida-ensalada-gpt.webp", "assets/ui/iconos/obj-ensalada.png", 30, 23, False),
    # los dibujos grandes de los efectos secundarios (ui/menus.gd, mutacion; 16 nov): uno por mutación, en un cuadrado de
    # 100 (se centran en un lienzo de 100x100 al final de este archivo); a 2 unidades por píxel, 200 en la pantalla
    "mutacion_tentacular": ("assets/sources/mutacion-tentacular-gpt.webp", "assets/ui/mutaciones/tentacular.png", 96, 100, False),
    "mutacion_gastro": ("assets/sources/mutacion-gastro-gpt.webp", "assets/ui/mutaciones/gastro.png", 97, 100, False),
    "mutacion_insensible": ("assets/sources/mutacion-insensible-gpt.webp", "assets/ui/mutaciones/insensible.png", 100, 98, False),
    "mutacion_canibal": ("assets/sources/mutacion-canibal-gpt.webp", "assets/ui/mutaciones/canibal.png", 85, 100, False),
    "mutacion_ansiedad": ("assets/sources/mutacion-ansiedad-gpt.webp", "assets/ui/mutaciones/ansiedad.png", 100, 94, False),
    "mutacion_endurecimiento": ("assets/sources/mutacion-endurecimiento-gpt.webp", "assets/ui/mutaciones/endurecimiento.png", 94, 100, False),
    "mutacion_locura": ("assets/sources/mutacion-locura-gpt.webp", "assets/ui/mutaciones/locura.png", 100, 99, False),
    "mutacion_flatulento": ("assets/sources/mutacion-flatulento-gpt.webp", "assets/ui/mutaciones/flatulento.png", 95, 100, False),
    # y a la mitad, para las cuatro casillas de las mutaciones que lleva Johnny, encima de la mochila (inventario.gd,
    # fila_mutaciones; 17 nov): centradas en un lienzo de 50x50
    "mini_mutacion_tentacular": ("assets/sources/mutacion-tentacular-gpt.webp", "assets/ui/mutaciones/mini/tentacular.png", 48, 50, False),
    "mini_mutacion_gastro": ("assets/sources/mutacion-gastro-gpt.webp", "assets/ui/mutaciones/mini/gastro.png", 48, 50, False),
    "mini_mutacion_insensible": ("assets/sources/mutacion-insensible-gpt.webp", "assets/ui/mutaciones/mini/insensible.png", 50, 49, False),
    "mini_mutacion_canibal": ("assets/sources/mutacion-canibal-gpt.webp", "assets/ui/mutaciones/mini/canibal.png", 42, 50, False),
    "mini_mutacion_ansiedad": ("assets/sources/mutacion-ansiedad-gpt.webp", "assets/ui/mutaciones/mini/ansiedad.png", 50, 47, False),
    "mini_mutacion_endurecimiento": ("assets/sources/mutacion-endurecimiento-gpt.webp", "assets/ui/mutaciones/mini/endurecimiento.png", 47, 50, False),
    "mini_mutacion_locura": ("assets/sources/mutacion-locura-gpt.webp", "assets/ui/mutaciones/mini/locura.png", 50, 49, False),
    "mini_mutacion_flatulento": ("assets/sources/mutacion-flatulento-gpt.webp", "assets/ui/mutaciones/mini/flatulento.png", 48, 50, False),
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
    "logro_sin_rasguno": ("assets/sources/logro-sin_rasguno-gpt.webp", "assets/ui/iconos/logro-sin_rasguno.png", 23, 32, False),
    "logro_por_los_pelos": ("assets/sources/logro-por_los_pelos-gpt.webp", "assets/ui/iconos/logro-por_los_pelos.png", 32, 29, False),
    "logro_visto_y_no_visto": ("assets/sources/logro-visto_y_no_visto-gpt.webp", "assets/ui/iconos/logro-visto_y_no_visto.png", 26, 32, False),
    "logro_cazajefes": ("assets/sources/logro-cazajefes-gpt.webp", "assets/ui/iconos/logro-cazajefes.png", 27, 32, False),
    "logro_fregona_oro": ("assets/sources/logro-fregona_oro-gpt.webp", "assets/ui/iconos/logro-fregona_oro.png", 28, 32, False),
    "logro_exterminador": ("assets/sources/logro-exterminador-gpt.webp", "assets/ui/iconos/logro-exterminador.png", 29, 32, False),
    "logro_limpieza_general": ("assets/sources/logro-limpieza_general-gpt.webp", "assets/ui/iconos/logro-limpieza_general.png", 28, 32, False),
    "logro_piromano": ("assets/sources/logro-piromano-gpt.webp", "assets/ui/iconos/logro-piromano.png", 31, 32, False),
    "logro_racha": ("assets/sources/logro-racha-gpt.webp", "assets/ui/iconos/logro-racha.png", 31, 32, False),
    "logro_sin_tiritas": ("assets/sources/logro-sin_tiritas-gpt.webp", "assets/ui/iconos/logro-sin_tiritas.png", 31, 32, False, (), [(490, 290), (232, 608), (965, 718), (671, 1031)]),
    "logro_intocable": ("assets/sources/logro-intocable-gpt.webp", "assets/ui/iconos/logro-intocable.png", 32, 32, False),
    "logro_manitas": ("assets/sources/logro-manitas-gpt.webp", "assets/ui/iconos/logro-manitas.png", 32, 31, False, (), [(287, 1052)]),
    "logro_joya_corona": ("assets/sources/logro-joya_corona-gpt.webp", "assets/ui/iconos/logro-joya_corona.png", 30, 32, False),
    "logro_arsenal": ("assets/sources/logro-arsenal-gpt.webp", "assets/ui/iconos/logro-arsenal.png", 32, 30, False),
    "logro_especialista": ("assets/sources/logro-especialista-gpt.webp", "assets/ui/iconos/logro-especialista.png", 32, 30, False),
    "logro_conserje_total": ("assets/sources/logro-conserje_total-gpt.webp", "assets/ui/iconos/logro-conserje_total.png", 26, 32, False),
    "logro_buen_vecino": ("assets/sources/logro-buen_vecino-gpt.webp", "assets/ui/iconos/logro-buen_vecino.png", 32, 30, False),
    "logro_comunidad": ("assets/sources/logro-comunidad-gpt.webp", "assets/ui/iconos/logro-comunidad.png", 29, 32, False),
    "logro_plantilla": ("assets/sources/logro-plantilla-gpt.webp", "assets/ui/iconos/logro-plantilla.png", 32, 29, False, (), [(768, 459), (621, 813)]),
    "logro_horas_extra": ("assets/sources/logro-horas_extra-gpt.webp", "assets/ui/iconos/logro-horas_extra.png", 21, 32, False),
    "logro_buena_compania": ("assets/sources/logro-buena_compania-gpt.webp", "assets/ui/iconos/logro-buena_compania.png", 21, 32, False, (), [(686, 251), (604, 428), (611, 877)]),
    "logro_caja_fuerte": ("assets/sources/logro-caja_fuerte-gpt.webp", "assets/ui/iconos/logro-caja_fuerte.png", 31, 32, False),
    "logro_se_fue_la_luz": ("assets/sources/logro-se_fue_la_luz-gpt.webp", "assets/ui/iconos/logro-se_fue_la_luz.png", 31, 32, False),
    "logro_simulacro": ("assets/sources/logro-simulacro-gpt.webp", "assets/ui/iconos/logro-simulacro.png", 32, 30, False),
    "logro_contra_marea": ("assets/sources/logro-contra_marea-gpt.webp", "assets/ui/iconos/logro-contra_marea.png", 32, 32, False),
    "logro_reto_aceptado": ("assets/sources/logro-reto_aceptado-gpt.webp", "assets/ui/iconos/logro-reto_aceptado.png", 31, 32, False),
    "logro_todas_reglas": ("assets/sources/logro-todas_reglas-gpt.webp", "assets/ui/iconos/logro-todas_reglas.png", 30, 32, False, (), [(932, 884), (342, 914)]),
    "logro_cambio_look": ("assets/sources/logro-cambio_look-gpt.webp", "assets/ui/iconos/logro-cambio_look.png", 28, 32, False),
    "logro_vestuario": ("assets/sources/logro-vestuario-gpt.webp", "assets/ui/iconos/logro-vestuario.png", 31, 32, False, (), [(630, 276), (214, 408), (365, 450), (664, 402), (821, 451), (1064, 391), (408, 994), (682, 1086)]),
    "logro_naturalista": ("assets/sources/logro-naturalista-gpt.webp", "assets/ui/iconos/logro-naturalista.png", 32, 30, False),
    "logro_investigador": ("assets/sources/logro-investigador-gpt.webp", "assets/ui/iconos/logro-investigador.png", 29, 32, False),
    "logro_chatarrero": ("assets/sources/logro-chatarrero-gpt.webp", "assets/ui/iconos/logro-chatarrero.png", 29, 32, False),
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
    # lo de los trasteros de las viviendas (M8, 10 nov; antes, de PixelLab y de tools/trastero.py). El colchón del suelo,
    # con la colcha mostaza: no va al juego tal cual, de él salen los nueve, uno por superviviente, con la colcha de su
    # color (py tools/camas_viviendas.py, después de este); más estrecho que el viejo (42) para no deformarlo
    "colchon_trastero": ("assets/sources/colchon-trastero-gpt.webp", "assets/sources/viviendas/colchon-gpt.png", 38, 66, False),
    # la estantería metálica vacía (la "storageshelf" del catálogo): acero galvanizado, cuatro baldas. Los huecos entre
    # baldas, negro puro, se vacían también (una semilla en cada uno), para que se vea la pared de detrás: en negro
    # parecía una librería negra
    "estanteria_trastero": ("assets/sources/estanteria-trastero-gpt.webp", "assets/sprites/mueble-storageshelf.png", 44, 63, True,
                            (), [(520, 340), (520, 700), (520, 1070)]),
    # la hoja de la puerta azul, cerrada y de frente (puerta_bano.gd la estira al hueco: tiene que medir 28 × 43, como
    # FRENTE). Las otras tres (abierta, y cerrada y abierta en un tabique de lado) siguen saliendo de tools/trastero.py,
    # con los azules sacados de esta
    "puerta_trastero": ("assets/sources/puerta-trastero-gpt.webp", "assets/sprites/puerta-trastero.png", 28, 43, False),
    # lo del pasillo de las viviendas (M9, 10 nov; antes, de PixelLab con tools/guias_trasteros.py): la pila de cajas de
    # mudanza (la "boxstack" del catálogo), dos abajo, dos en medio y una arriba
    "cajas_pila": ("assets/sources/cajas-pila-gpt.webp", "assets/sprites/mueble-boxstack.png", 32, 40, True),
    # las dos cajas abiertas en el suelo (la "boxpile"), con las solapas levantadas; más bajas que las viejas (27)
    "cajas_bajas": ("assets/sources/cajas-bajas-gpt.webp", "assets/sprites/mueble-boxpile.png", 28, 19, True),
    # la carretilla de mudanzas (la "handtruck"), roja con dos cajas; los dos huecos del armazón, encima y debajo de la
    # barra cruzada, se vacían también (las semillas), para que se vea el suelo de detrás
    "carretilla": ("assets/sources/carretilla-gpt.webp", "assets/sprites/mueble-handtruck.png", 20, 40, True,
                   (), [(512, 250), (512, 500)]),
    # la cocina de los pisos (M13, 10 nov; antes, de PixelLab con tools/guias_cocina.py). La nevera combi, blanca hueso,
    # con la caja de cereales y la cesta encima: GPT la hizo mucho más estrecha que la vieja (31 × 65), así que se deja
    # igual de alta y se estrecha a 22 (su largo en el catálogo, 44, a juego) en vez de dejarla de 92 de alto
    "nevera": ("assets/sources/nevera-gpt.webp", "assets/sprites/mueble-fridge.png", 22, 65, True),
    # la encimera con el fregadero, la tabla de cortar y un plato; cuatro puertas crema
    "encimera": ("assets/sources/encimera-gpt.webp", "assets/sprites/mueble-counter.png", 79, 47, True),
    # el fogón: cocina de gas con cuatro fuegos, cinco mandos y el horno
    "fogon": ("assets/sources/fogon-gpt.webp", "assets/sprites/mueble-stove.png", 28, 41, True),
    # la mesa de la cocina con sus dos sillas; los huecos de debajo de los asientos, entre el travesaño y el asiento, se
    # vacían también (las semillas)
    "mesa_cocina": ("assets/sources/mesa-cocina-gpt.webp", "assets/sprites/mueble-kitchentable.png", 56, 29, True,
                    (), [(213, 700), (1322, 699)]),
    # el salón de los pisos (M13, 10 nov; antes, de PixelLab). La tele con su mueble (32 × 42: GPT la hizo más estrecha que la vieja;
    # su largo en el catálogo, de 80 a 64), el sofá de espaldas (66 × 24: más bajo que el viejo, que lo deformaba), la estantería
    # de libros (21 × 42; largo de 46 a 42), la lámpara de pie (encendida, pantalla clara) y la planta (los huecos entre las
    # hojas, que el fondo no alcanza desde el borde, se vacían con las semillas)
    "tele": ("assets/sources/tele-gpt.webp", "assets/sprites/mueble-tv.png", 32, 42, True),
    "sofa_espalda": ("assets/sources/sofa-espalda-gpt.webp", "assets/sprites/mueble-sofaback.png", 66, 24, True),
    "estanteria_salon": ("assets/sources/estanteria-salon-gpt.webp", "assets/sprites/mueble-bookshelf.png", 21, 42, True),
    "lampara": ("assets/sources/lampara-gpt.webp", "assets/sprites/mueble-lamp.png", 15, 47, True),
    "planta_salon": ("assets/sources/planta-salon-gpt.webp", "assets/sprites/mueble-plant.png", 19, 34, True, (),
                     [(442, 349), (470, 353), (470, 486), (444, 623), (590, 631), (427, 768), (535, 782)]),
    # el dormitorio de los pisos (M13, 10 nov; antes, de PixelLab con tools/guias_dormitorio.py). Las dos camas, el armario y la
    # mesilla se quedan igual de altos y más estrechos, porque GPT los hizo más estrechos que los viejos (su largo en el
    # catálogo: cama de matrimonio de 124 a 114, individual de 84 a 62, armario de 96 a 78, mesilla de 40 a 34); el escritorio,
    # igual de ancho y algo más bajo (46 × 37). Los dibujos de lado de la cama de matrimonio y de la mesilla siguen siendo los
    # de antes. El hueco del reloj de la mesilla, que el fondo no alcanza desde el borde, se vacía con la semilla
    "cama_matrimonio": ("assets/sources/cama-matrimonio-gpt.webp", "assets/sprites/mueble-doublebed.png", 57, 75, True),
    "cama": ("assets/sources/cama-gpt.webp", "assets/sprites/mueble-bed.png", 31, 73, True),
    "armario": ("assets/sources/armario-gpt.webp", "assets/sprites/mueble-wardrobe.png", 39, 72, True),
    "mesilla": ("assets/sources/mesilla-gpt.webp", "assets/sprites/mueble-nightstand.png", 17, 33, True, (), [(690, 408)]),
    "escritorio": ("assets/sources/escritorio-gpt.webp", "assets/sprites/mueble-desk.png", 46, 37, True),
    # y sus dibujos de lado (para las paredes laterales; en la de la derecha se ponen en espejo), con el cabecero a la izquierda: las
    # dos camas, de 70 de largo como los de antes (48 de alto, algo más bajas), y la mesilla, igual de alta y más estrecha (13);
    # el hueco del reloj de la mesilla se vacía con la semilla
    "cama_matrimonio_lado": ("assets/sources/cama-matrimonio-lado-gpt.webp", "assets/sprites/mueble-doublebed-lado.png", 70, 48, True),
    "cama_lado": ("assets/sources/cama-lado-gpt.webp", "assets/sprites/mueble-bed-lado.png", 70, 48, True),
    "mesilla_lado": ("assets/sources/mesilla-lado-gpt.webp", "assets/sprites/mueble-nightstand-lado.png", 13, 32, True, (), [(631, 417)]),
    # la página del dosier que flota junto al científico muerto (M14, 10 nov; antes, un rectángulo pintado a mano en
    # mapa/cientifico.gd): la hoja amarillenta con su clip y la mancha de sangre. Más grande que la de antes (10 × 13): a 12 × 16 los renglones
    # se emborronaban y parecía una mancha marrón
    "dosier_pagina": ("assets/sources/dosier-pagina-gpt.webp", "assets/sprites/dosier-pagina.png", 14, 19, False),
    # M96 (13 nov): lo que va colgado en la pared de arriba de los baños de los pisos (planta.gd, colgados_bano): el
    # toallero negro con la toalla gris, la toalla blanca colgada de un gancho y la balda blanca con toallas y una planta
    "toallero": ("assets/sources/toallero-gpt.webp", "assets/sprites/toallero.png", 22, 24, False),
    "toalla_gancho": ("assets/sources/toalla-gancho-gpt.webp", "assets/sprites/toalla-gancho.png", 16, 28, False),
    "balda_bano": ("assets/sources/balda-bano-gpt.webp", "assets/sprites/balda-bano.png", 28, 24, False),
    # la palmera de la galería del centro comercial (17 nov, catalogo.gd: "palmera"): una areca en su maceta alta de piedra
    # blanca con motas; algo más alta que Johnny (48)
    "palmera": ("assets/sources/palmera-gpt.webp", "assets/sprites/mueble-palmera.png", 42, 65, True),
    # el banco de la galería del centro comercial (17 nov, catalogo.gd: "bancogaleria"): acero inoxidable y listones de
    # madera, en medio del pasillo delante de las dos tiendas de abajo. Los huecos entre los listones del respaldo y bajo
    # el asiento, todo el negro puro (el contorno es casi negro)
    "bancogaleria": ("assets/sources/banco-galeria-gpt.webp", "assets/sprites/mueble-bancogaleria.png", 48, 27, True, (), "negro"),
    # la placa de la sala de mantenimiento, junto a su puerta en el pasillo de los tres edificios (puerta.gd,
    # cartel_mantenimiento; 17 nov): chapa esmaltada azul con un casco de obra y dos llaves inglesas cruzadas, sin letras
    # (en vez del cartel «MANTENIMIENTO», que con la palabra no podía ser más corto). A 22, los cuadrados de GPT justos:
    # a 18 o 20 las llaves se emborronaban
    "placa_mantenimiento": ("assets/sources/placa-mantenimiento-gpt.webp", "assets/sprites/placa-mantenimiento.png", 22, 22, False),
    # la puerta automática del supermercado, de frente en la pared de arriba de la galería (puerta.gd; 17 nov): cuatro
    # cristales, los dos de los lados fijos y los dos del medio correderos. Entera; la parte en marco y hojas
    # tools/puerta_super.py
    "puerta_super": ("assets/sources/puerta-super-gpt.webp", "assets/sprites/puerta-super.png", 64, 40, False),
    # los dos escaparates del supermercado, a los lados de su puerta automática (mapa.poner_escaparates; 17 nov): a la
    # izquierda, el de bebidas; a la derecha, el de comida (el "-derecha"). Del mismo ancho que el de antes
    "escaparate_super": ("assets/sources/escaparate-super-bebidas-gpt.webp", "assets/sprites/escaparate-supermercado.png", 53, 36, False),
    # el letrero del supermercado, encima de su puerta (neon.gd, LETREROS; 17 nov): letras corpóreas azul marino, en
    # inglés para todos los idiomas, como una marca. Su resplandor azul lo hace tools/letrero_halo.py (con la K redibujada:
    # tools/letrero_super_k.py)
    # (el hueco de la V de la K, que con la E tocándola queda cerrado: también es fondo, no negro de las letras)
    "letrero_super": ("assets/sources/letrero-super-arreglado.png", "assets/sprites/letrero-supermercado.png", 100, 17, False,
                      (), [(1238, 482)]),
    "escaparate_super_derecha":("assets/sources/escaparate-super-comida-gpt.webp", "assets/sprites/escaparate-supermercado-derecha.png", 53, 37, False),
    # el escaparate de la farmacia, vacío, como el del súper pero más estrecho (17 nov, el dueño): dentro, por detrás del
    # cristal, va uno de sus neones (la cruz o la botella). Lo parte en fondo y reflejos tools/escaparate_farmacia.py
    "escaparate_farmacia": ("assets/sources/centro/escaparate-farmacia-vacio-gpt.webp", "assets/sprites/escaparate-farmacia-vacio.png", 44, 38, False),
    # la puerta de la ferretería, de cristal con una sola hoja, y el cartel «OPEN» que cuelga por detrás del cristal (17 nov, el
    # dueño). Los junta tools/puerta_ferreteria.py
    "puerta_ferreteria": ("assets/sources/centro/puerta-ferreteria-gpt.webp", "assets/sprites/puerta-ferreteria-entera.png", 30, 43, False),
    # los escaparates de la ferretería (17 nov, el dueño): a la izquierda, un panel de herramientas por detrás del cristal; a la derecha, un
    # neón de herramientas (tools/neones_galeria.py); los dos con la verja por delante (todo el negro, también el de entre las barras)
    "panel_herramientas": ("assets/sources/centro/panel-herramientas-gpt.webp", "assets/sprites/panel-herramientas.png", 36, 27, False),
    # el panel de llaves inglesas vandalizado de la ferretería (20 nov, el dueño): tablero perforado gris abollado, con la mitad de
    # las llaves arrancadas, óxido, sangre y una mano ensangrentada; para colgar en las paredes de la tienda (aún sin poner).
    # A escala 1 (un píxel, una unidad: el doble de detalle, como los muebles de la tienda de ropa), 136x86: cabe en la pared de la
    # tienda (96 unidades de alto). A escala 2 (60x38) no se veía ni un detalle
    "panel_llaves": ("assets/sources/centro/panel-llaves-gpt.webp", "assets/sprites/panel-llaves.png", 136, 86, False),
    "verja": ("assets/sources/centro/verja-gpt.webp", "assets/sprites/verja-escaparate.png", 44, 37, False, (), "negro"),
    # la puerta de la tienda de electrónica: la misma de la ferretería, un poco más pequeña, con su cartel más pequeño, dentro de un marco de neón
    "puerta_electronica": ("assets/sources/centro/puerta-ferreteria-gpt.webp", "assets/sprites/puerta-electronica-entera.png", 28, 40, False),
    "cartel_open_pequeno": ("assets/sources/centro/cartel-open-gpt.webp", "assets/sprites/cartel-open-pequeno.png", 17, 15, False),
    # la puerta doble de cristal sin marco del restaurante (17 nov, el dueño): dos hojas con pinzas de acero y barras largas
    "puerta_restaurante": ("assets/sources/centro/puerta-restaurante-gpt.webp", "assets/sprites/puerta-restaurante.png", 36, 43, False),
    # la misma, destrozada (19 nov, el dueño): la de la tienda de ropa inversa vista desde dentro (puerta.gd, RESTAURANTE_ROPA); la de fuera, limpia
    "puerta_ropa_destrozada": ("assets/sources/ropa/puerta-entrada-destrozada-gpt.webp", "assets/sprites/puerta-ropa-destrozada.png", 36, 43, False),
    # la puerta doble de acero pulido de la joyería (17 nov, el dueño): ventanas altas de cristal, barras largas y cerradura en el medio
    "puerta_joyeria": ("assets/sources/centro/puerta-joyeria-gpt.webp", "assets/sprites/puerta-joyeria.png", 34, 43, False),
    # el espejo de arco de los probadores de la tienda de ropa (18 nov, el dueño, catalogo.gd: "espejoprobador"; se levanta 11 píxeles al final de este archivo): marco dorado fino y
    # cristal vacío con dos brillos, en la pared de arriba de cada probador
    "espejoprobador": ("assets/sources/ropa/espejo-probador-gpt.webp", "assets/sprites/mueble-espejoprobador.png", 36, 50, True),
    # el puf redondo blanco de los probadores de la tienda de ropa (18 nov, el dueño, catalogo.gd: "pufprobador"): en la esquina de arriba a la izquierda
    # desde el 19 nov, destrozado (el dueño; GPT, ya en beige: no se tiñe)
    "pufprobador": ("assets/sources/ropa/puf-probador-destrozado-gpt.webp", "assets/sprites/mueble-pufprobador.png", 18, 20, True),
    # el gancho doble cromado de los probadores de la tienda de ropa (18 nov, el dueño, catalogo.gd: "ganchoprobador"): de perfil, con la
    # placa a la izquierda (el dibujo de la pared izquierda; en la derecha, en espejo). Se levanta del suelo al final de este archivo
    "ganchoprobador": ("assets/sources/ropa/perchero-probador-gpt.webp", "assets/sprites/mueble-ganchoprobador-lado.png", 10, 16, True),
    # la alfombrilla blanca de los probadores de la tienda de ropa (18 nov, el dueño): una pieza del suelo (mapa.gd, dibujar_fondo), sin .json
    # desde el 19 nov, destrozada (el dueño; GPT, ya redondeada y en beige: ni se recorta ni se tiñe), por su contorno (RECORTE)
    "alfombra_probador": ("assets/sources/ropa/alfombra-probador-destrozada-gpt.webp", "assets/sprites/alfombra-probador.png", 66, 44, False),
    # el almacén de la tienda de ropa, destrozado (19 nov, el dueño; GPT, a partir de las de antes): las cuatro estanterías con ropa (las
    # de antes salían de tools/ropa_estanterias.py; los huecos entre baldas, todo el negro puro, se vacían) y los montones de cajas
    "ropashelf": ("assets/sources/ropa/estanteria1-destrozada-gpt.webp", "assets/sprites/mueble-ropashelf.png", 44, 62, True, (), "negro"),
    "ropashelf2": ("assets/sources/ropa/estanteria2-destrozada-gpt.webp", "assets/sprites/mueble-ropashelf2.png", 44, 63, True, (), "negro"),
    "ropashelf3": ("assets/sources/ropa/estanteria3-destrozada-gpt.webp", "assets/sprites/mueble-ropashelf3.png", 44, 63, True, (), "negro"),
    "ropashelf4": ("assets/sources/ropa/estanteria4-destrozada-gpt.webp", "assets/sprites/mueble-ropashelf4.png", 44, 63, True, (), "negro"),
    "cajasropa": ("assets/sources/ropa/cajas-destrozadas-gpt.webp", "assets/sprites/mueble-cajasropa.png", 32, 39, True),
    # (19 nov, el dueño: «todas igual queda raro») cuatro montones más, cada uno destrozado de otra forma: uno distinto en cada sitio del almacén
    "cajasropa2": ("assets/sources/ropa/cajas-destrozadas2-gpt.webp", "assets/sprites/mueble-cajasropa2.png", 32, 36, True),
    "cajasropa3": ("assets/sources/ropa/cajas-destrozadas3-gpt.webp", "assets/sprites/mueble-cajasropa3.png", 32, 38, True),
    "cajasropa4": ("assets/sources/ropa/cajas-destrozadas4-gpt.webp", "assets/sprites/mueble-cajasropa4.png", 32, 39, True),
    "cajasropa5": ("assets/sources/ropa/cajas-destrozadas5-gpt.webp", "assets/sprites/mueble-cajasropa5.png", 32, 38, True),
    # (19 nov, el dueño) y la carretilla del almacén, destrozada (GPT, a partir de la carretilla): tipo propio, la de los trasteros de las
    # viviendas sigue igual; del mismo tamaño, y sus dos huecos del armazón, vaciados igual (las semillas)
    "carretillaropa": ("assets/sources/ropa/carretilla-destrozada-gpt.webp", "assets/sprites/mueble-carretillaropa.png", 20, 40, True,
                       (), [(512, 250), (512, 510)]),
    # (19 nov) el aseo de la tienda de ropa, destrozado como el almacén (GPT, a partir del lavabo, el váter, la taquilla y el banco del
    # vestuario de Johnny): tipos propios (catalogo.gd) para que el vestuario de la sala de mantenimiento y los baños de los pisos sigan igual
    "lavabo_ropa": ("assets/sources/ropa/lavabo-destrozado-gpt.webp", "assets/sprites/mueble-staffsinkropa-lado.png", 20, 66, True),
    "vater_ropa": ("assets/sources/ropa/vater-destrozado-gpt.webp", "assets/sprites/mueble-stafftoiletropa-lado.png", 26, 37, True),
    "taquilla_ropa": ("assets/sources/ropa/taquilla-destrozada-gpt.webp", "assets/sprites/mueble-taquillaropa.png", 28, 56, True),
    "banco_ropa": ("assets/sources/ropa/banco-vestuario-destrozado-gpt.webp", "assets/sprites/mueble-lockerbenchropa.png", 64, 28, True),
    # y el mismo banco «en vertical», pegado a la pared de la derecha (como el de tools/banco_vestuario_lado.py)
    "banco_ropa_lado": ("assets/sources/ropa/banco-vestuario-vertical-destrozado-gpt.webp", "assets/sprites/mueble-lockerbenchropa-lado.png", 14, 44, True, (), "negro"),
    "cartel_open": ("assets/sources/centro/cartel-open-gpt.webp", "assets/sprites/cartel-open.png", 20, 18, False),
}


# los que no se recortan por todo lo que no es fondo sino por una caja (en píxeles de la imagen de GPT): la alfombrilla destrozada, por
# su contorno, sin los flecos que le salen por fuera (así mide lo mismo que la limpia y va en su sitio)
RECORTE = {"assets/sources/ropa/alfombra-probador-destrozada-gpt.webp": (40, 42, 1572, 919)}


def pasar(origen, sprite, ancho, alto, con_json, quitar=(), semillas=()):
    im = Image.open(origen).convert("RGBA")
    W, H = im.size
    px = im.load()
    if semillas == "negro":   # (todo el negro puro, también el de los huecos encerrados)
        semillas = [(x, y) for y in range(H) for x in range(W) if max(px[x, y][:3]) < 6]
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
    im = im.crop(RECORTE.get(origen, im.getbbox()))
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

# la fregona va centrada en un lienzo de 48x48, como los demás dibujos de assets/ui/tienda
if "fregona" in (sys.argv[1:] or ["fregona"]):
    pequena = Image.open("assets/ui/tienda/fregona.png").convert("RGBA")
    lienzo = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    lienzo.paste(pequena, (2, 2))
    lienzo.save("assets/ui/tienda/fregona.png")

# los materiales, la comida y los iconos del mapa, centrados en un lienzo de 32x32 (los iconos de los objetos son todos de 32x32: partida.soltar_objeto)
for nombre in [n for n in (sys.argv[1:] or list(MUEBLES)) if n.startswith(("pieza_", "comida_", "mapa_"))]:
    ruta = MUEBLES[nombre][1]
    pequena = Image.open(ruta).convert("RGBA")
    lienzo = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    lienzo.paste(pequena, ((32 - pequena.width) // 2, (32 - pequena.height) // 2))
    lienzo.save(ruta)

# los efectos secundarios, centrados en un lienzo de 100x100 (todas las tarjetas de la pantalla de elegir, iguales)
for nombre in [n for n in (sys.argv[1:] or list(MUEBLES)) if n.startswith("mutacion_")]:
    ruta = MUEBLES[nombre][1]
    pequena = Image.open(ruta).convert("RGBA")
    lienzo = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
    lienzo.paste(pequena, ((100 - pequena.width) // 2, (100 - pequena.height) // 2))
    lienzo.save(ruta)

# los efectos secundarios a la mitad, centrados en un lienzo de 50x50 (las casillas de las mutaciones del inventario)
for nombre in [n for n in (sys.argv[1:] or list(MUEBLES)) if n.startswith("mini_mutacion_")]:
    ruta = MUEBLES[nombre][1]
    pequena = Image.open(ruta).convert("RGBA")
    lienzo = Image.new("RGBA", (50, 50), (0, 0, 0, 0))
    lienzo.paste(pequena, ((50 - pequena.width) // 2, (50 - pequena.height) // 2))
    lienzo.save(ruta)

# el banco de la galería, algo más claro (17 nov: en medio del pasillo hay poca luz y la madera se veía casi negra)
if "bancogaleria" in (sys.argv[1:] or ["bancogaleria"]):
    from PIL import ImageEnhance
    ruta = MUEBLES["bancogaleria"][1]
    banco = Image.open(ruta).convert("RGBA")
    alfa = banco.split()[3]
    banco = ImageEnhance.Brightness(banco.convert("RGB")).enhance(1.35).convert("RGBA")
    banco.putalpha(alfa)
    banco.save(ruta)

# el espejo de los probadores, levantado del suelo (18 nov, el dueño): 11 píxeles transparentes debajo: apoyado en el rodapié, para que no toque el suelo
if "espejoprobador" in (sys.argv[1:] or ["espejoprobador"]):
    ruta = MUEBLES["espejoprobador"][1]
    esp = Image.open(ruta).convert("RGBA")
    lienzo = Image.new("RGBA", (esp.width, esp.height + 11), (0, 0, 0, 0))
    lienzo.paste(esp, (0, 0))
    lienzo.save(ruta)
    with open(ruta.replace(".png", ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"cell": [lienzo.width, lienzo.height], "pivot": [lienzo.width // 2, lienzo.height], "scale": 1,
                   "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
        f.write("\n")

# el gancho, colgado a media altura: 20 píxeles transparentes debajo (18 nov, el dueño)
if "ganchoprobador" in (sys.argv[1:] or ["ganchoprobador"]):
    ruta = MUEBLES["ganchoprobador"][1]
    gancho = Image.open(ruta).convert("RGBA")
    lienzo = Image.new("RGBA", (gancho.width + 7, gancho.height + 20), (0, 0, 0, 0))
    lienzo.paste(gancho, (7, 0))   # (y 7 píxeles transparentes a la izquierda: con el hueco de 6 unidades, la placa queda justo en la pared y no se mete en el tabique)
    lienzo.save(ruta)
    with open(ruta.replace(".png", ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"cell": [lienzo.width, lienzo.height], "pivot": [lienzo.width // 2, lienzo.height], "scale": 1,
                   "anims": {"idle": {"fps": 1, "dirs": {"south": {"row": 0, "frames": 1}}}}}, f, indent=2)
        f.write("\n")

# la alfombrilla de los probadores, con las esquinas redondeadas (18 nov, el dueño: que no parezca hecha con escuadra y cartabón):
# se recorta cada esquina con un cuarto de círculo de 10 píxeles y el borde nuevo se pinta del color del contorno
if "alfombra_probador" in (sys.argv[1:] or ["alfombra_probador"]) and "destrozada" not in MUEBLES["alfombra_probador"][0]:
    ruta = MUEBLES["alfombra_probador"][1]
    alf = Image.open(ruta).convert("RGBA")
    w, h = alf.size
    R = 10
    px = alf.load()

    def dentro(x, y):
        if not (0 <= x < w and 0 <= y < h):
            return False
        cx = R - 0.5 - x if x < R else x - (w - R - 0.5) if x > w - R - 1 else None
        cy = R - 0.5 - y if y < R else y - (h - R - 0.5) if y > h - R - 1 else None
        if cx is None or cy is None:
            return True
        return cx * cx + cy * cy <= (R - 0.5) ** 2 + 1
    # el color del contorno: el del borde de arriba, en medio
    borde = px[w // 2, 0][:3]
    # beige en vez de blanco (18 nov, el dueño): lo claro se tiñe (el contorno, no)
    for y in range(h):
        for x in range(w):
            r, g, b, al = px[x, y]
            if al and max(r, g, b) > 150:
                px[x, y] = (r, int(g * 0.95), int(b * 0.86), al)
    mask = [[dentro(x, y) and px[x, y][3] > 0 for x in range(w)] for y in range(h)]
    for y in range(h):
        for x in range(w):
            if not mask[y][x]:
                px[x, y] = (0, 0, 0, 0)
            elif any(not (0 <= x + dx < w and 0 <= y + dy < h and mask[y + dy][x + dx]) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = borde + (255,)
    alf.save(ruta)

# el puf de los probadores, en beige como la alfombrilla y las cortinas (18 nov, el dueño): lo claro se tiñe (el contorno, no)
if "pufprobador" in (sys.argv[1:] or ["pufprobador"]) and "destrozado" not in MUEBLES["pufprobador"][0]:
    ruta = MUEBLES["pufprobador"][1]
    puf = Image.open(ruta).convert("RGBA")
    px = puf.load()
    for y in range(puf.height):
        for x in range(puf.width):
            r, g, b, al = px[x, y]
            if al and max(r, g, b) > 120:
                px[x, y] = (r, int(g * 0.95), int(b * 0.86), al)
    puf.save(ruta)
