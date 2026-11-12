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
    # el «!» de las novedades (M3, 9 nov): degradado de amarillo a naranja con contorno oscuro, sin globo. El grande,
    # encima de la mesa del ordenador y de la taquilla (mapa/exclamacion.gd); el pequeño, en los iconos del escritorio de
    # ConserjeOS y en los apartados de Logros (ui/ordenador.gd, ui/archivador_logros.gd)
    "exclamacion": ("assets/sources/exclamacion-gpt.webp", "assets/sprites/exclamacion.png", 10, 28, False),
    "exclamacion_pequena": ("assets/sources/exclamacion-gpt.webp", "assets/ui/exclamacion-pequena.png", 7, 20, False),
    # la flecha amarilla pintada en el suelo que guía en la primera partida (guia.gd, Flecha; M7, 9 nov), hacia la derecha
    "flecha_guia": ("assets/sources/flecha-gpt.webp", "assets/sprites/flecha-guia.png", 20, 20, False),
    # los iconos del escritorio de ConserjeOS (ui/ordenador.gd, ICONOS; M6, 9 nov), solo para el escritorio (los de
    # assets/ui/iconos/ de siempre se siguen usando en otros sitios): Talentos, tres flechas amarillas hacia arriba
    # (Talentos y la Tienda de armas salen amarillos: después se pasa py tools/colorear_iconos.py, que pone cada
    # flecha del color de su rama, la mirilla en rojo y
    # la carpeta del Dosier en marrón, 12 nov)
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
    # Colecciones, un cuaderno amarillo con su etiqueta crema
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
}


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
