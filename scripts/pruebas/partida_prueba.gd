# La partida de prueba ("-- --captura", ver CLAUDE.md): la partida de siempre (partida.gd) y, encima, las fotos
# y las comprobaciones que van saliendo en la terminal. La monta escenas/partida_prueba.tscn, que es la escena de
# la partida con este script en vez del suyo; con --captura, el menú abre esa en vez de la normal.
#
# Las pruebas van repartidas por temas en una cadena de archivos: cada uno hereda del anterior y este, el último, los
# tiene todos. Así, para tocar una prueba basta con abrir su archivo:
#   prueba_comun.gd (hereda de partida.gd) → prueba_jefes_salas.gd → prueba_jefes.gd → prueba_armas.gd →
#   prueba_skins.gd → prueba_inventario.gd → prueba_fotos.gd → prueba_sitios.gd → prueba_varias.gd →
#   prueba_larga.gd → trailer.gd → partida_prueba.gd
# Una función solo puede llamar a las de su archivo o a las de los de antes en la cadena (si no, Godot no compila y
# arranca la partida normal): lo que usen varios archivos va en el primero de ellos. Prueba nueva: su función en el
# archivo de su tema, su opción en empezar_prueba() (abajo) y su línea en esta lista.
#
# Sin nada más, la prueba larga (_process, en prueba_larga.gd): un apartamento, el jefe, los menús, el ordenador, el
# inventario, las armas de efecto, la historia, las Colecciones... y se cierra. Con algo más, solo una parte:
#   --edificio centro   en el centro comercial (vale también con las demás; lo lee menu_principal.gd)
#   --edificios         solo la pantalla «Elige edificio»: las dos tarjetas como están en el guardado y con el centro
#                       comercial cerrado (se cierra sin entrar en la partida; lo lee menu_principal.gd)
#   --jefe X            el jefe de la 1ª planta (centro: el antidisturbios si no se dice; Apartamentos: la portera, en la
#                       planta baja). OJO: solo elige el jefe; a secas, sin otra opción de esta lista, es la prueba larga
#   --porqueria, --gimnasio, --cubos, --llamas   (con --jefe gloton, gymbro, portera o bombero) la habitación de ese
#                       jefe; con --llamas, también su giro con el lanzallamas            [prueba_jefes_salas.gd]
#   --aspirar           (con --jefe gloton) su sangre ácida y lo que tira al aspirar a 3, 5, 8 y 12 casillas, normal y
#                       enfadado                                                           [prueba_jefes.gd]
#   --pesas             (con --jefe gymbro) sus suplementos, su salto y las pesas que lanza, en el aire y en el suelo
#                                                                                          [prueba_jefes.gd]
#   --gotas             (con --jefe portera) el abanico de agua sucia y sus salpicaduras    [prueba_jefes_salas.gd]
#   --vapor             el vapor de la cabeza de cada minijefe al enfadarse                [prueba_jefes_salas.gd]
#   --franja            el aviso de las cargas (antidisturbios y mascota), a medio llenar   [prueba_jefes_salas.gd]
#   --rebote            (con --edificio centro --jefe mascota) la mascota enfadada rebota en la pared y avisa con su
#                       franja antes de volver a salir                                     [prueba_jefes_salas.gd]
#   --golpes            el aviso de los golpes cuerpo a cuerpo de cada jefe                 [prueba_jefes_salas.gd]
#   --avisos            el resto de los avisos de los jefes (lenguas, rayas, círculos...)  [prueba_jefes_salas.gd]
#   --ir-jefe           derecho a la habitación de cada jefe (Glotón, Gymbro, portera, bombero) [prueba_jefes_salas.gd]
#   --presentacion      (con --jefe X, si se quiere) la entrada del jefe al aparecer         [prueba_jefes.gd]
#   --azotea            la azotea y su helipuerto elevado: la rampa, el jefe esperando, la valla y el jefe final
#                       (el científico; con --edificio centro, el gerente)                    [prueba_jefes.gd]
#   --latigazos         el gerente mutado en la sala de pruebas: sus tres latigazos con Johnny abajo, arriba, de
#                       lado, en diagonal, por detrás y junto a una pared                  [prueba_varias.gd]
#   --lenguas           las lenguas del Glotón (también enfadado) y de la criatura del científico, en la sala de
#                       pruebas: avisando y dando el golpe en varias direcciones y junto a una pared [prueba_varias.gd]
#   --disparos          las barras de aviso de los disparos de los jefes (contratos, alfileres, cuchillos y bolas de
#                       fuego) en la sala de pruebas: junto a la pared (que las corta) y en campo abierto [prueba_varias.gd]
#   --golpes-pared      ¿los golpes de los jefes (cuerpo a cuerpo, saltos, círculo y onda) atraviesan las paredes?
#                       Cada uno con Johnny justo al otro lado de la pared y, de control, en campo abierto; y su
#                       aviso, cortado en la pared                                        [prueba_varias.gd]
#   --armas             la sala de pruebas (F9): la diana, las armas y las líneas de ayuda   [prueba_armas.gd]
#   --sala-pruebas      la sala de pruebas: el baúl de pruebas, el panel (P), un jefe quieto,
#                       apagar y encender ayudas y volver con F9                          [prueba_armas.gd]
#   --lanzallamas, --desintegrador, --pistola-electrica   cada arma de efecto: comprarla, su daño, su depósito o su
#                       batería, las 8 direcciones y las 4 skins                           [prueba_armas.gd]
#   --tintes            el fuego y el ácido pintados en los enemigos, con luz y a oscuras    [prueba_armas.gd]
#   --fuego-acido       el fuego se contagia y el ácido come la armadura                     [prueba_armas.gd]
#   --molotov-carga     cuánto tarda cada fotograma al caer un molotov entre muchos zombis; con --zombis N, cuántos (12) [prueba_armas.gd]
#   --charcos           los charcos que burbujean (veneno, ácido, vómito) junto al de fuego  [prueba_armas.gd]
#   --epicas            el truco de la Épica de cada familia: golpe de gracia, balas que atraviesan, estallido y
#                       racimo                                                             [prueba_armas.gd]
#   --aura              lo que se ve de la calidad del arma en la mano: la luz, las chispas y la estela del golpe y de la
#                       bala, con luz y a oscuras                                           [prueba_armas.gd]
#   --sensacion         que golpear se note: el parón de cada golpe (cada arma, al matar, el de gracia, explosiones,
#                       daño a Johnny; sin sumarse, el respiro y la pausa) y el tono de los sonidos [prueba_armas.gd]
#   --temblor           el ajuste «Temblor de pantalla» de Opciones: el botón (Normal, Suave, Sin temblor), que
#                       se guarda y que multiplica el temblor y el parón de los golpes          [prueba_armas.gd]
#   --musica            la música por capas: qué capas se oyen explorando, con zombis, en la horda y con el jefe, y
#                       que van a la par (va sin sonido: lo dice en la terminal)              [prueba_armas.gd]
#   --skins             las skins: desbloqueo, taquilla, caras y lo que hace cada una        [prueba_skins.gd]
#   --inventario        la pantalla del inventario; luego, las vendas y el botiquín          [prueba_inventario.gd]
#   --arrastrar         arrastrar con el ratón o el dedo en el inventario y en el baúl       [prueba_inventario.gd]
#   --baul              la pantalla del baúl: guardar, sacar y el baúl lleno                 [prueba_inventario.gd]
#   --repuesto          dos armas de cada tipo: la de la mano y la de repuesto; y al comprar una tercera, la de repuesto
#                       va al baúl (M26)                                                  [prueba_inventario.gd]
#   --tienda            la tienda de armas: sus secciones y comprar arrojables de uno en uno [prueba_inventario.gd]
#   --piezas            las piezas de mejora: quién las suelta, la mochila, el baúl, «Piezas al baúl» y los 5 objetos
#                       quitados                                                       [prueba_inventario.gd]
#   --objetos           qué objetos salen al azar en cada sitio de los dos edificios, y el baúl con las piezas [prueba_larga.gd]
#   --noticias          el programa de Noticias del ordenador: la tele con la reportera hablando [prueba_larga.gd]
#   --novedades         los avisos de lo nuevo: el «!» de la mesa del ordenador, de la taquilla y de los iconos, y el
#                       grito grande de las noticias, los logros y las skins                [prueba_larga.gd]
#   --avisos-ordenador  los «!» de los iconos de ConserjeOS se quitan al mirar o cobrar lo nuevo, sin apagar [prueba_larga.gd]
#   --ordenador-arriba  cada programa del ordenador recién abierto: tiene que empezar arriba      [prueba_larga.gd]
#   --historia          todos los textos de la historia: cada página del dosier en su hoja y cada noticia entera en la
#                       tele, para ver si caben                                        [prueba_larga.gd]
#   --calidades         las calidades de las armas y los arrojables: lo que dan, una de cada arma, el baúl, caer y
#                       completar el edificio                                          [prueba_inventario.gd]
#   --banco-mejorar     el banco de trabajo: subir de calidad armas y arrojables (los que lleva y los del baúl)
#                       gastando piezas                                                [prueba_inventario.gd]
#   --municion          la munición por tipos y los arrojables (3 a mano y 8 de repuesto)    [prueba_inventario.gd]
#   --montones          los arrojables en montones de 5: varios del mismo tipo, el inventario lleno, otros 5 a la
#                       mano al acabarse, el baúl (juntos, de 5 en 5) y completar el edificio  [prueba_inventario.gd]
#   --municion-suelo    la munición, un molotov y una granada en el suelo (con luz y a oscuras), la caja según el arma y un
#                       molotov en vuelo                                                   [prueba_inventario.gd]
#   --atraedora         la atraedora (dinamita con despertador) y la congeladora (extintor con temporizador) en vuelo,
#                       en el HUD y en el inventario                                       [prueba_inventario.gd]
#   --fotos-tiendas, --fotos-luz, --fotos-ayudas, --fotos-supervivientes   fotos para mirar  [prueba_fotos.gd]
#   --sala              la sala de mantenimiento: sus tres estancias y sus muebles           [prueba_sitios.gd]
#   --ascensor          el ascensor arreglado: bajar a la sala y volver                      [prueba_sitios.gd]
#   --viviendas         las viviendas de los rescatados                                      [prueba_sitios.gd]
#   --pasillo           el pasillo de las 4 plantas con ascensor: su cartel, sin muebles, y el nombre de la planta y de sus
#                       puertas en el idioma de la prueba (con --lang en, un número más que en español)   [prueba_sitios.gd]
#   --llegada           por dónde se llega a cada planta: el portal a la izquierda, las demás (y la azotea) por la derecha [prueba_sitios.gd]
#   --salida            la salida de incendios del fondo del pasillo (escaleras): cerrada y, al caer la jefa, abierta [prueba_sitios.gd]
#   --piso              el piso de los apartamentos (siempre el mismo): puerta abajo y arriba [prueba_sitios.gd]
#   --zombis-sala       cuántos zombis hay en cada habitación de los apartamentos, y que no se amontonen [prueba_sitios.gd]
#   --volver            salir de un sitio y volver lo deja como estaba: un piso a medias, ya limpio, el pasillo, el jefe,
#                       el superviviente, los eventos, la sala de pruebas y lo que ocupa una planta entera; con
#                       --edificio centro --joyeria, también el guardia y la joyería         [prueba_sitios.gd]
#   --puertas           las puertas de dentro de los pisos (con --edificio centro, de las tiendas) y de la sala de
#                       mantenimiento: cerradas, Johnny y un zombi las abren, y siguen abiertas [prueba_sitios.gd]
#   --joyeria           (con --edificio centro) la cámara acorazada de la joyería            [prueba_sitios.gd]
#   --tiendas           (con --edificio centro) cada tienda de las cuatro primeras plantas, entera, también la del
#                       minijefe                                                           [prueba_sitios.gd]
#   --acustica          cómo suena la pistola en cada habitación de la planta baja y en la azotea: seca, con eco o
#                       con un rebote corto (con --edificio centro, en las tiendas)          [prueba_sitios.gd]
#   --alerta N          las reglas de esa alerta (1 a 5)                                     [prueba_varias.gd]
#   --llave             la llave de la jefa en el suelo, con su luz blanca, con y sin ella      [prueba_varias.gd]
#   --curas             las vendas y el botiquín: casillas del HUD, teclas 1 y 2, el tercio que devuelve el botiquín, la
#                       velocidad por tercios, baúl, el armarito del baño y la mitad de los dólares al caer [prueba_inventario.gd]
#   --tutorial          los tutoriales: la ventana, la cola, la lista desde la pausa, el del baúl antes del baúl y
#                       la casilla de Ayudas                                                [prueba_varias.gd]
#   --relato            los textos de la historia sobre negro: la introducción, los dos finales, cómo se pasan y se
#                       saltan, el cartel del final y que quedan apuntados (mirarlos también con --lang ru y
#                       --lang zh_CN, por si se sale alguna línea)                           [prueba_varias.gd]
#   --mando             A confirma y B vuelve en los menús, con botones del mando de verdad: el menú principal, la pausa,
#                       Opciones, un tutorial, el inventario, la taquilla, el ordenador, una página, el panel de pruebas
#                       y el cartel del final; que A siga esquivando (project.godot pone A en ui_accept y B en ui_cancel)
#                                                                  [prueba_varias.gd, pruebas/prueba_mando.gd]
#   --formas            que las formas de formas.gd (disco, arco, polígono, polilínea) salgan como las de CanvasItem: dos
#                       fotos y su diferencia píxel a píxel                                  [prueba_varias.gd]
#   --dibujos           lo que cuesta cada tipo de dibujo (rectángulos, círculos, abanicos y anillos de primitivas) según cuántos por
#                       fotograma, con las llamadas, los triángulos y si la página estaba a la vista; en la web, 200
#                       círculos tardan 1 s y 12 800 rectángulos, 17 ms (docs/WEB.md)        [prueba_varias.gd, pruebas/dibujos.gd]
#   --lentos            (con cualquier otra) avisa de cada fotograma que tarda más de 60 ms, con cuántos dibujos llevaba, y da
#                       un resumen al acabar: para cazar en la web lo que la atasca (docs/WEB.md) [pruebas/lentos.gd]
#   --rendimiento       cuánto tarda cada fotograma durante el latigazo del Glotón (3 y 6 lenguas); en la web, el atasco
#                       de los draw_circle (docs/WEB.md)                                       [prueba_varias.gd]
#   --pantalla          la pantalla completa del ordenador: F11 y Alt+Intro la ponen y la quitan, y se guarda [prueba_varias.gd]
#   --escala            que la imagen llene la ventana: la escala de cada pantalla y al cambiar de tamaño [prueba_varias.gd]
#   --guiado            el tutorial disimulado de la primera partida: las pistas sobre Johnny, el latido del HUD, la
#                       flecha del suelo, el apartamento fácil y la llavecita del zombi de la llave [prueba_varias.gd]
#   --guiado --sin-hacer  la guía con un jugador que no hace lo que le piden: lo enseñado cuenta igual como visto y su
#                       ventana no se repite en la partida siguiente, tras morir (F18)         [prueba_varias.gd]
#   --idioma            solo el menú, Opciones (4 pestañas y las licencias, y el botón de avisar de un texto mal traducido, con
#                       y sin enlace), el cambio de idioma en caliente y «Elige edificio»; con
#                       --alerta 3 --reto, con su alerta y su reto             [prueba_idioma.gd; lo lanza menu_principal.gd]
#   --ingles            (con cualquier prueba) el juego en inglés; al cerrar, cuenta los textos sin traducir [idioma.gd]
#   --lang X            lo mismo con otro idioma: pt_BR, de, fr, ru o zh_CN (--ingles es --lang en)       [idioma.gd]
#   --letras            si cada letra de las traducciones la tiene alguna fuente (el cirílico, el chino...) y cuánto mide
#                       una línea con cada una                                                [prueba_letras.gd]
#   --medidas           los textos cortos que en cada idioma salen más anchos que en español (se pasan de su caja); con
#                       --todo, todos y no solo los 25 peores                                  [prueba_letras.gd]
#   --hud               las armas y los lanzables en la esquina del HUD: quietos, al cambiar (Q y F), el aviso del modo de
#                       atacar (F1) y en el móvil                                            [prueba_varias.gd]
#   --mutaciones        solo el recuadro de las mutaciones: foto, elegir una y ver lo que cambia [prueba_larga.gd]
#   --pausa             solo la pausa (sus números y las armas) y el cartel del final                [prueba_larga.gd]
#   --derrota           el cartel de derrota: quién te ha pillado (un zombi, explosiones, el fuego), lo conseguido en
#                       la partida, «Otra vez» y la R; y por el fuego, por un jefe y ganando    [prueba_varias.gd]
#   --continuar         la partida a medias: se guarda al subir a la 1ª planta, el menú enseña «Continuar partida» y,
#                       al continuarla, la planta y lo que se llevaba son iguales             [prueba_varias.gd]
#   --escudo            el escudo de Acero: se gasta antes que la vida, y su barra encima de la de vida [prueba_varias.gd]
#   --tentaculos        el zombi de tentáculos: andar, avisar y dar el latigazo, el golpe y la muerte, y su tentáculo
#                       con Johnny abajo, arriba, de lado, en diagonal y junto a una pared [prueba_varias.gd]
#   --reto si           el reto del día (--reto <regla> fuerza esa regla)                    [prueba_varias.gd]
#   --equilibrio        los números del equilibrio: talentos y skin sumados, daño mínimo, Ninja, Ajolote, los
#                       premios (jefes, reto, apagón e incendio), el tope de curas y los armaritos, y los
#                       números de jefes, mutaciones y aliados                             [prueba_varias.gd]
#   --logros            las ayudas de Opciones apagan los logros: el aviso, el ordenador, cobrar y Exterminador; y los
#                       40 logros (M17): el repaso del guardado, los de jefes, racha, arsenal, ganar, reto y horda, y
#                       el ordenador por apartados                                          [prueba_varias.gd]
#   --quimico           la rama Químico de los talentos: cada talento con sus números, las fotos del nivel 3 y el
#                       árbol con las tres ramas en el ordenador                            [prueba_varias.gd]
#   --equilibrio-talentos  Durito hasta 3 (y los puntos de más, devueltos), Ajolote hasta la mitad, el alcance de
#                       Puntería, Mirilla (1 de cada 3, en amarillo) y las tarjetas «Ahora / Con otro» [prueba_varias.gd]
#   --talentos-altos    los niveles 4 y 5 de las tres ramas: cada talento con sus números, fotos del racimo, el
#                       Segundo aliento, la Adrenalina, el rayo de Alto voltaje y la Mezcla explosiva, y las coronas
#                       en el ordenador                                                      [prueba_varias.gd]
#   --caza              el acompañante va a por los zombis que ve                            [prueba_varias.gd]
#   --gastro            el vómito de la Gastroenteritis no cruza las paredes                 [prueba_varias.gd]
#   --flatulento        el alcance de la mutación Flatulento (140): quién se paraliza a 50, 110 y 190 [prueba_varias.gd]
#   --rescate           el superviviente encerrado en su baño (y su horda), los vecinos de las viviendas, la barricada,
#                       la escolta y la avería: lo mismo que en la prueba larga          [supervivientes.gd, probar()]
#   --evento X          ese evento sorpresa: apagon, incendio u horda                        [eventos.gd, probar()]
#   --banco             lo quitado desaparece del guardado; luego el banco, las armas de efecto y Colecciones
#                                                                                            [prueba_larga.gd]
#   --trailer           el trailer: Johnny juega solo unas escenas con textos y el título (docs/TRAILER.md) [trailer.gd]
extends "res://scripts/pruebas/trailer.gd"


# Ya en la sala de mantenimiento: la prueba que se haya pedido (si no, la larga, que sigue en _process)
func empezar_prueba() -> void:
	var args := OS.get_cmdline_user_args()
	if "--trailer" in args:
		grabar_trailer()
	elif "--volver" in args:
		set_process(false)   # sin la prueba larga
		probar_volver()
	elif "--fotos-tiendas" in args:
		fotos_tiendas()
	elif "--fotos-luz" in args:
		fotos_luz()
	elif "--fotos-ayudas" in args:
		fotos_ayudas()
	elif "--fotos-supervivientes" in args:
		fotos_supervivientes()
	elif "--gastro" in args:
		set_process(false)   # sin la prueba larga
		probar_gastro()
	elif "--flatulento" in args:
		set_process(false)   # sin la prueba larga
		probar_flatulento()
	elif "--caza" in args:
		set_process(false)   # sin la prueba larga
		probar_caza()
	elif "--porqueria" in args:
		set_process(false)   # sin la prueba larga
		probar_porqueria()
	elif "--aspirar" in args:
		set_process(false)   # sin la prueba larga
		await probar_aspirar()
		get_tree().quit()
	elif "--pesas" in args:
		set_process(false)   # sin la prueba larga
		await probar_pesas()
		get_tree().quit()
	elif "--gimnasio" in args:
		set_process(false)   # sin la prueba larga
		probar_gimnasio()
	elif "--cubos" in args:
		set_process(false)   # sin la prueba larga
		probar_cubos()
	elif "--vapor" in args:
		set_process(false)   # sin la prueba larga
		probar_vapor()
	elif "--franja" in args:
		set_process(false)   # sin la prueba larga
		probar_franja()
	elif "--rebote" in args:
		set_process(false)   # sin la prueba larga
		probar_rebote()
	elif "--golpes" in args:
		set_process(false)   # sin la prueba larga
		probar_golpes()
	elif "--avisos" in args:
		set_process(false)   # sin la prueba larga
		probar_avisos()
	elif "--gotas" in args:
		set_process(false)   # sin la prueba larga
		probar_gotas()
	elif "--llamas" in args:
		set_process(false)   # sin la prueba larga
		probar_llamas()
	elif "--sala-pruebas" in args:
		set_process(false)   # sin la prueba larga
		probar_sala_pruebas()
	elif "--ir-jefe" in args:
		set_process(false)   # sin la prueba larga
		probar_ir_jefe()
	elif "--presentacion" in args:
		set_process(false)   # sin la prueba larga
		probar_presentacion()
	elif "--azotea" in args:
		set_process(false)   # sin la prueba larga
		probar_azotea_sola()
	elif "--skins" in args:
		set_process(false)   # sin la prueba larga
		probar_skins()
	elif "--banco" in args:
		set_process(false)   # sin la prueba larga
		probar_banco()
	elif "--baul" in args:
		set_process(false)   # sin la prueba larga
		probar_baul()
	elif "--repuesto" in args:
		set_process(false)   # sin la prueba larga
		probar_repuesto()
	elif "--tienda" in args:
		set_process(false)   # sin la prueba larga
		probar_tienda()
	elif "--piezas" in args:
		set_process(false)   # sin la prueba larga
		probar_piezas()
	elif "--calidades" in args:
		set_process(false)   # sin la prueba larga
		probar_calidades()
	elif "--banco-mejorar" in args:
		set_process(false)   # sin la prueba larga
		probar_banco_mejorar()
	elif "--objetos" in args:
		set_process(false)   # sin la prueba larga
		await probar_objetos()
		get_tree().quit()
	elif "--noticias" in args:
		set_process(false)   # sin la prueba larga
		await probar_noticias()
		get_tree().quit()
	elif "--novedades" in args:
		await probar_novedades()
		get_tree().quit()
	elif "--avisos-ordenador" in args:
		await probar_avisos_ordenador()
		get_tree().quit()
	elif "--ordenador-arriba" in args:
		set_process(false)   # sin la prueba larga
		await probar_ordenador_arriba()
		get_tree().quit()
	elif "--historia" in args:
		set_process(false)   # sin la prueba larga
		await probar_historia_entera()
		get_tree().quit()
	elif "--municion" in args:
		set_process(false)   # sin la prueba larga
		probar_municion()
	elif "--montones" in args:
		set_process(false)   # sin la prueba larga
		probar_montones()
	elif "--municion-suelo" in args:
		set_process(false)   # sin la prueba larga
		probar_municion_suelo()
	elif "--atraedora" in args:
		set_process(false)   # sin la prueba larga
		probar_atraedora()
	elif "--inventario" in args:
		set_process(false)   # sin la prueba larga
		probar_inventario()
	elif "--arrastrar" in args:
		set_process(false)   # sin la prueba larga
		probar_arrastrar()
	elif "--lanzallamas" in args:
		set_process(false)   # sin la prueba larga
		probar_lanzallamas()
	elif "--desintegrador" in args:
		set_process(false)   # sin la prueba larga
		probar_desintegrador()
	elif "--pistola-electrica" in args:
		set_process(false)   # sin la prueba larga
		probar_pistola_electrica()
	elif "--tintes" in args:
		set_process(false)   # sin la prueba larga
		probar_tintes()
	elif "--charcos" in args:
		set_process(false)   # sin la prueba larga
		probar_charcos()
	elif "--fuego-acido" in args:
		set_process(false)   # sin la prueba larga
		probar_fuego_acido()
	elif "--molotov-carga" in args:
		set_process(false)   # sin la prueba larga
		probar_molotov_carga()
	elif "--epicas" in args:
		set_process(false)   # sin la prueba larga
		probar_epicas()
	elif "--aura" in args:
		set_process(false)   # sin la prueba larga
		probar_aura()
	elif "--derrota" in args:
		set_process(false)   # sin la prueba larga
		probar_derrota()
	elif "--sensacion" in args:
		set_process(false)   # sin la prueba larga
		probar_sensacion()
	elif "--temblor" in args:
		set_process(false)   # sin la prueba larga
		probar_temblor()
	elif "--musica" in args:
		set_process(false)   # sin la prueba larga
		probar_musica()
	elif "--ascensor" in args:
		set_process(false)   # sin la prueba larga
		probar_ascensor()
	elif "--rescate" in args:
		set_process(false)   # sin la prueba larga
		await supervivientes.probar()
		get_tree().quit()
	elif "--viviendas" in args:
		set_process(false)   # sin la prueba larga
		probar_viviendas()
	elif "--acustica" in args:
		set_process(false)   # sin la prueba larga
		probar_acustica()
	elif "--sala" in args:
		set_process(false)   # sin la prueba larga
		probar_sala()
	elif "--pasillo" in args:
		set_process(false)   # sin la prueba larga
		probar_pasillo()
	elif "--llegada" in args:
		set_process(false)   # sin la prueba larga
		probar_llegada()
	elif "--salida" in args:
		set_process(false)   # sin la prueba larga
		probar_salida()
	elif "--piso" in args:
		set_process(false)   # sin la prueba larga
		probar_piso()
	elif "--zombis-sala" in args:
		set_process(false)   # sin la prueba larga
		probar_zombis_sala()
	elif "--puertas" in args:
		set_process(false)   # sin la prueba larga
		probar_puertas()
	elif "--tiendas" in args:
		set_process(false)   # sin la prueba larga
		probar_tiendas()
	elif "--armas" in args:
		set_process(false)   # sin la prueba larga
		probar_armas()
	elif "--joyeria" in args:
		set_process(false)   # sin la prueba larga
		probar_joyeria()
	elif "--llave" in args:
		set_process(false)   # sin la prueba larga
		probar_llave()
	elif "--curas" in args:
		set_process(false)   # sin la prueba larga
		probar_curas_rapidas()
	elif "--hud" in args:
		set_process(false)   # sin la prueba larga
		probar_hud()
	elif "--escudo" in args:
		set_process(false)   # sin la prueba larga
		probar_escudo()
	elif "--continuar" in args:
		set_process(false)   # sin la prueba larga
		probar_continuar()
	elif "--mutaciones" in args:
		set_process(false)   # sin la prueba larga
		probar_mutaciones_solo()
	elif "--pausa" in args:
		set_process(false)   # sin la prueba larga
		probar_pausa_y_fin()
	elif "--latigazos" in args:
		set_process(false)   # sin la prueba larga
		probar_latigazos()
	elif "--lenguas" in args:
		set_process(false)   # sin la prueba larga
		probar_lenguas()
	elif "--golpes-pared" in args:
		set_process(false)   # sin la prueba larga
		probar_golpes_pared()
	elif "--disparos" in args:
		set_process(false)   # sin la prueba larga
		probar_disparos()
	elif "--tentaculos" in args:
		set_process(false)   # sin la prueba larga
		probar_tentaculos()
	elif "--tutorial" in args:
		set_process(false)   # sin la prueba larga
		probar_tutorial()
	elif "--relato" in args:
		set_process(false)   # sin la prueba larga (la suya ya va: empieza en prueba_comun.gd, antes que esta)
	elif "--mando" in args:
		set_process(false)   # sin la prueba larga (el menú principal ya ha hecho su parte: menu_principal.gd)
		probar_mando()
	elif "--formas" in args:
		set_process(false)   # sin la prueba larga
		probar_formas()
	elif "--dibujos" in args:
		set_process(false)   # sin la prueba larga
		probar_dibujos()
	elif "--rendimiento" in args:
		set_process(false)   # sin la prueba larga
		probar_rendimiento()
	elif "--pantalla" in args:
		set_process(false)   # sin la prueba larga
		probar_pantalla()
	elif "--escala" in args:
		set_process(false)   # sin la prueba larga
		probar_escala()
	elif "--sin-hacer" in args:
		set_process(false)   # sin la prueba larga
		probar_guia_sin_hacer()
	elif "--guiado" in args:
		set_process(false)   # sin la prueba larga
		probar_guiado()
	elif "--equilibrio" in args:
		set_process(false)   # sin la prueba larga
		probar_equilibrio()
	elif "--logros" in args:
		set_process(false)   # sin la prueba larga
		probar_logros()
	elif "--quimico" in args:
		set_process(false)   # sin la prueba larga
		probar_quimico()
	elif "--equilibrio-talentos" in args:
		set_process(false)   # sin la prueba larga
		probar_equilibrio_talentos()
	elif "--talentos-altos" in args:
		set_process(false)   # sin la prueba larga
		probar_talentos_altos()
	elif eventos.forzado != "":
		set_process(false)   # sin la prueba larga
		eventos.probar(eventos.forzado)
	elif Reto.activo:
		set_process(false)   # sin la prueba larga
		probar_reto()
	elif Alerta.nivel > 0:
		set_process(false)   # sin la prueba larga
		probar_alerta()
	else:
		contar_planta()
