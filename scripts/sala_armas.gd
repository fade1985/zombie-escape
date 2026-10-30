# La sala de pruebas (F9 desde cualquier sitio de cualquier planta, y F9 otra vez para volver; el sitio lo hace
# planta.gd en la planta baja y partida.gd, sitio_pruebas, en las demás): una habitación vacía y con luz para probar
# armas, jefes y zombis. La monta mapa.gd al entrar y se va con él al salir. Tiene:
#   - el panel de pruebas (tecla P, ui/panel_pruebas.gd): sacar jefes y zombis, encender y apagar las ayudas, Johnny
#     invencible, la diana, ir a la exposición o a la sala de un jefe, y lo de las antiguas teclas de prueba
#   - el baúl de pruebas: todas las armas y los arrojables en cada calidad, para cogerlos y cambiarlos. Mientras se está
#     aquí, el baúl que se ve es ese (Guardado.baul_prueba); el de verdad no se toca
#   - la diana: un zombi normal en el centro que no pierde vida, no ataca y vuelve a su sitio si un golpe lo mueve
#     (zombi.gd, "diana"), para probar desde todas las direcciones. Sus números de daño, más grandes
#   - todas las armas de la tienda (también el lanzallamas, el lanza ácido y el lanza rayos): coma y punto pasan a
#     la anterior y a la siguiente
#   - munición sin fin, pero recargando: la reserva no se acaba nunca y el cargador sí (y el lanzallamas, el lanza
#     ácido y el lanza rayos se llenan sin gastar gasolina, bidones de ácido ni baterías)
#   - las líneas de ayuda, en el suelo (cada una se apaga en el panel): el alcance del arma (de fuego, un círculo;
#     cuerpo a cuerpo, el abanico del golpe), a quién apunta el apuntado (amarillo), por dónde irá la bala (azul: sale
#     de la boca del arma, no del centro de Johnny), el círculo de cada zombi dentro del que le da la bala (rojo) y el
#     camino de verdad de cada bala (verde si da; naranja si pasa por el lado de la diana; roja si choca con la pared o
#     se le acaba el alcance)
#   - el panel de daño, arriba a la izquierda: la ficha del arma y el recuento de disparos, aciertos, fallos (y por
#     qué), daño por segundo y cuántos zombis normales habría matado, con una vida de mentira (Retroceso lo pone a
#     cero)
#   - el guion esconde de golpe las líneas y el panel de daño, y otra vez los vuelve a sacar como estaban. La sala
#     empieza con ellos escondidos (el guion los saca) y se acuerda de cómo se dejaron hasta que acaba la partida
# Entra con la pistola en la mano; al salir, Johnny vuelve a llevar lo que llevaba al entrar: armas, balas, mochila y
# arrojables. Lo que se gana aquí no cuenta (partida.gd, en_pruebas: los zombis no sueltan nada).
class_name SalaArmas
extends Node2D

const ZOMBI := preload("res://escenas/personajes/zombi_normal.tscn")
const BALA := preload("res://scripts/bala.gd")
const ZOMBI_VIDA := 30     # la vida de un zombi normal (zombi_normal.tscn): la vida de mentira de la diana
const RASTRO := 2.5        # segundos que se ve el camino de una bala que ya ha acabado
const VENTANA := 3.0       # el daño por segundo se cuenta con el de los últimos 3 s
const POR_EL_LADO := 40.0  # una bala que falla pasando a menos de esto del círculo de la diana ha ido "por el lado"
const AMARILLO := Color("#ffd23f")
const AZUL := Color("#5ec8ff")
const VERDE := Color("#5fd35f")
const NARANJA := Color("#ff9f1c")
const ROJO := Color("#ff5d5d")
const BLANCO := Color(1, 1, 1, 0.45)
const CRITICO := Color("#ffb020")
const TINTA := Color(0.11, 0.1, 0.17)
# Lo que hace cada arma con efecto (su "efecto", armas_creadas.gd), para la ficha
const EFECTOS := {"llama": "llamarada continua que atraviesa", "acido": "chorro de ácido continuo que atraviesa",
	"rayo": "rayo continuo que aturde y salta de un zombi a otro"}

var johnny: Node2D
var diana: Zombi
var lista: Array = []      # las armas, en el orden en que se pasan: las de la tienda (Armas.DATOS)
var indice := 0            # la que lleva en la mano, de la lista
var en_mano := ""          # el id del arma que lleva en la mano (para saber cuándo cambia, también con Q o el baúl)
var entrada := {}          # las armas y balas con las que entró Johnny (se le devuelven al salir)
var panel: ColorRect
# Lo que se enciende y se apaga en el panel de pruebas (static: se acuerda de una vez para otra)
static var con_panel := true      # el panel de daño
static var escondido := true      # el guion: fuera todo de golpe (las líneas y el panel de daño); otra vez, vuelve como estaba.
                                  # Al empezar la partida, la sala sale así, limpia
static var ayudas := {"alcance": true, "apuntado": true, "trayectoria": true, "circulos": true, "balas": true}
static var con_diana := true
static var sin_fin := true        # munición sin fin
var partida: Node
var texto: Label
var reloj := 0.0           # el tiempo de la sala (solo corre jugando)
# Las balas que se siguen: {nodo, desde, hasta, radio, fin, t, pasa, vieja (salió antes de poner el recuento a cero)}. "fin": "" mientras vuela; "acierto", "lado",
# "pared" o "alcance" al acabar; "t", los segundos desde que acabó; "pasa", lo más cerca que ha pasado del centro
# de la diana
var balas: Array = []
# El recuento (Retroceso lo pone a cero; también al cambiar de arma)
var disparos_desde := 0    # los disparos que llevaba Johnny al empezar a contar
var tiros := 0             # las balas que han salido (la escopeta suelta cinco por disparo)
var aciertos := 0
var fallos := {"lado": 0, "pared": 0, "alcance": 0}
var ultimo_fallo := ""
var golpes: Array = []     # [momento, daño] de cada vez que le quitan vida a la diana, de los últimos 3 s
var total := 0
# La vida de mentira: la diana no pierde vida, pero se cuenta la que perdería un zombi normal para saber cuántos
# habría matado y cuánto ha tardado con el último
var vida_mentira := 0
var abatidos := 0
var vida_desde := 0.0      # cuándo le quitaron vida por primera vez desde que la tiene entera
var vida_golpes := 0       # y cuántas veces desde entonces
var ultima_muerte := ""


func _ready() -> void:
	z_index = 50   # las líneas, por encima de todo lo del suelo
	partida = get_tree().current_scene
	vida_mentira = ZOMBI_VIDA
	if con_diana:
		poner_diana()
	get_tree().node_added.connect(_al_aparecer)
	lista = Armas.DATOS.keys()
	indice = lista.find("pistola")
	# el baúl de pruebas: todas las armas y los arrojables (de 5) en cada calidad
	var equipo := []
	for id in Armas.DATOS:
		for c in Armas.CALIDADES.size():
			equipo.append({"id": id, "calidad": c})
	for id in Lanzables.DATOS:
		for c in Armas.CALIDADES.size():
			equipo.append({"id": id, "calidad": c, "n": 5})
	Guardado.baul_prueba = {"baul": {}, "baul_equipo": equipo}
	# el panel, en la pantalla (como el minimapa: por debajo del fundido a negro)
	panel = ColorRect.new()
	panel.color = Color(TINTA, 0.62)
	panel.position = Vector2(8, 8)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto = Label.new()
	texto.theme = Tema.crear()
	texto.position = Vector2(8, 6)
	panel.add_child(texto)
	var pantalla: Node = partida.get_node("Pantalla")
	pantalla.add_child(panel)
	pantalla.move_child(panel, partida.negro.get_index())


func _exit_tree() -> void:
	Guardado.baul_prueba = {}   # vuelve el baúl de verdad
	if is_instance_valid(panel):
		panel.queue_free()
	if not is_instance_valid(johnny) or entrada.is_empty():
		return
	# Johnny vuelve a llevar lo que llevaba al entrar (también la mochila, las armas de repuesto y los arrojables)
	johnny.huecos = entrada.huecos
	johnny.calidades = entrada.calidades
	johnny.balas = entrada.balas
	johnny.municion = entrada.municion
	johnny.deposito = entrada.deposito
	johnny.municion_sin_fin = entrada.sin_fin
	johnny.cargadores = entrada.cargadores
	johnny.sostener(entrada.mano)
	partida.mochila = entrada.mochila
	partida.armas_guardadas = entrada.guardadas
	var lz: Lanzables = partida.lanzables
	lz.cantidades = entrada.lz.cantidades
	lz.mano = entrada.lz.mano
	lz.repuesto = entrada.lz.repuesto
	lz.en_repuesto = entrada.lz.en_repuesto
	lz.tipo = entrada.lz.tipo


# ═════════════ Lo que cambia el panel de pruebas ═════════════

# La diana, en el centro de la sala
func poner_diana() -> void:
	if is_instance_valid(diana):
		return
	var mapa: Node2D = get_parent()
	diana = ZOMBI.instantiate()
	diana.diana = true
	diana.casa = Vector2(mapa.sitio.ancho, mapa.sitio.alto) / 2.0
	diana.position = diana.casa
	mapa.cosas.add_child(diana)
	diana.herido.connect(_al_herir)


func quitar_diana() -> void:
	if is_instance_valid(diana):
		diana.queue_free()
	diana = null


func con_sin_fin(si: bool) -> void:
	sin_fin = si
	if johnny:
		johnny.municion_sin_fin = si


func _physics_process(delta: float) -> void:
	if johnny == null:
		# (Johnny llega a la sala después de montarla)
		johnny = get_tree().get_first_node_in_group("jugador")
		if johnny == null:
			return
		var lz: Lanzables = partida.lanzables
		entrada = {"huecos": johnny.huecos.duplicate(), "mano": johnny.mano, "balas": johnny.balas,
			"municion": johnny.municion.duplicate(), "deposito": johnny.deposito, "cargadores": johnny.cargadores.duplicate(),
			"calidades": johnny.calidades.duplicate(), "sin_fin": johnny.municion_sin_fin,
			"mochila": partida.mochila.duplicate(), "guardadas": partida.armas_guardadas.duplicate(),
			"lz": {"cantidades": lz.cantidades.duplicate(), "mano": lz.mano.duplicate(), "repuesto": lz.repuesto.duplicate(),
				"en_repuesto": lz.en_repuesto.duplicate(), "tipo": lz.tipo}}
		johnny.calidades = {}   # (aquí se prueban como son, en Normal)
		johnny.municion_sin_fin = sin_fin   # munición sin fin, pero recargando: la reserva no se acaba nunca
		johnny.coger(lista[indice])
	reloj += delta
	# Otra arma en la mano (con coma y punto, Q o el baúl): el recuento empieza de cero
	if johnny.huecos[johnny.mano] != en_mano:
		en_mano = johnny.huecos[johnny.mano]
		if en_mano in lista:
			indice = lista.find(en_mano)
		a_cero()
	for b in balas:
		if b.fin == "":
			if is_instance_valid(b.nodo):
				b.hasta = b.nodo.global_position
		else:
			b.t += delta
	balas = balas.filter(func(b): return b.fin == "" or b.t < RASTRO)
	golpes = golpes.filter(func(g): return reloj - g[0] < VENTANA)
	escribir()
	queue_redraw()


func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo) or johnny == null:
		return
	match evento.keycode:
		KEY_COMMA:
			cambiar(-1)
		KEY_PERIOD:
			cambiar(1)
		KEY_BACKSPACE:
			a_cero()
		KEY_MINUS:
			escondido = not escondido
		_:
			return
	get_viewport().set_input_as_handled()


# Coma y punto: el arma anterior o la siguiente de la lista
func cambiar(paso: int) -> void:
	indice = posmod(indice + paso, lista.size())
	johnny.coger(lista[indice])
	Sonido.tocar("cambiar")


func a_cero() -> void:
	disparos_desde = johnny.disparos if johnny else 0
	tiros = 0
	aciertos = 0
	for k in fallos:
		fallos[k] = 0
	ultimo_fallo = ""
	golpes.clear()
	total = 0
	abatidos = 0
	ultima_muerte = ""
	vida_mentira = ZOMBI_VIDA
	for b in balas:
		if b.fin != "":
			b.t = RASTRO   # los caminos de antes se borran
		else:
			b.vieja = true   # y las que aún vuelan ya no cuentan
	vida_golpes = 0


# ═════════════ Las balas ═════════════

# Algo nuevo en la escena: si es una bala, se sigue. Su sitio aún no está puesto (Johnny lo pone justo después
# de meterla), así que se apunta al final de este paso, antes de que se mueva
func _al_aparecer(nodo: Node) -> void:
	if nodo.get_script() == BALA:
		seguir_bala.call_deferred(nodo)


func seguir_bala(bala: Node2D) -> void:
	if not is_instance_valid(bala) or bala.de_aliado:
		return
	var b := {"nodo": bala, "desde": bala.global_position, "hasta": bala.global_position, "radio": bala.radio,
		"fin": "", "t": 0.0, "pasa": INF, "vieja": false}
	balas.append(b)
	tiros += 1
	bala.tree_exiting.connect(acabar_bala.bind(b))


# La bala se acaba: ¿ha dado a un zombi, ha pasado por el lado de la diana, ha chocado o se le ha acabado el alcance?
func acabar_bala(b: Dictionary) -> void:
	var bala: Node2D = b.nodo
	if not bala.is_queued_for_deletion():   # (se va porque Johnny se va de la sala)
		return
	b.hasta = bala.global_position
	b.fin = "alcance" if bala.vida <= 0.0 else "pared"
	for z in get_tree().get_nodes_in_group("zombis"):
		if b.hasta.distance_to(z.global_position) < z.radio + bala.radio + 3.0:
			b.fin = "acierto"
	if not is_instance_valid(diana):
		if not b.vieja:
			if b.fin == "acierto":
				aciertos += 1
			else:
				fallos[b.fin] += 1
		return
	# lo más cerca que ha pasado del centro de la diana (la bala va en línea recta)
	var cerca := Geometry2D.get_closest_point_to_segment(diana.global_position, b.desde, b.hasta)
	b.pasa = cerca.distance_to(diana.global_position)
	if b.vieja:
		return
	if b.fin == "acierto":
		aciertos += 1
		return
	var le_da: float = diana.radio + bala.radio + 3.0
	if b.pasa < le_da + POR_EL_LADO and cerca != b.desde and cerca != b.hasta:
		b.fin = "lado"
		ultimo_fallo = "a %d del centro (da si < %d)" % [roundi(b.pasa), roundi(le_da)]
	fallos[b.fin] += 1


# ═════════════ La diana ═════════════

# Le han hecho daño a la diana: el número grande y el recuento (y la vida de mentira: si se acaba, uno más)
func _al_herir(cantidad: int, golpe: bool) -> void:
	if vida_mentira >= ZOMBI_VIDA:   # el primero desde que la tiene entera
		vida_desde = reloj
		vida_golpes = 0
	vida_golpes += 1
	vida_mentira -= cantidad
	golpes.append([reloj, cantidad])
	total += cantidad
	# (lo del fuego y los charcos ya lo enseña la diana, pequeño y de su color: zombi.gd, herir)
	if golpe:
		var critico: bool = johnny != null and cantidad > roundi(johnny.arma().dano)   # el doble: un crítico
		numero(str(cantidad) + ("!" if critico else ""), CRITICO if critico else Color.WHITE)
	if vida_mentira <= 0:
		abatidos += 1
		ultima_muerte = "%s s, %d %s" % [decimal(reloj - vida_desde, 1), vida_golpes, "golpe" if vida_golpes == 1 else "golpes"]
		vida_mentira = ZOMBI_VIDA


# Un texto grande que sube despacio sobre la diana y se desvanece
func numero(cual: String, color: Color) -> void:
	var etiqueta := Label.new()
	etiqueta.text = cual
	etiqueta.theme = Tema.crear()
	etiqueta.add_theme_font_size_override("font_size", 32)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_constant_override("outline_size", 8)
	etiqueta.add_theme_color_override("font_outline_color", TINTA)
	add_child(etiqueta)
	etiqueta.global_position = diana.global_position + Vector2(randf_range(-26.0, 6.0), -diana.altura - 24.0)
	var tween := etiqueta.create_tween()
	tween.tween_property(etiqueta, "position:y", etiqueta.position.y - 44.0, 1.1).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(etiqueta, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tween.tween_callback(etiqueta.queue_free)


# ═════════════ Las líneas de ayuda ═════════════

func _draw() -> void:
	if johnny == null or escondido:
		return
	var w: Dictionary = johnny.arma()
	var p := to_local(johnny.global_position)
	var fuego: bool = w.tipo == "fuego"
	var radio_bala := 3.0 if w.get("perdigones", 1) > 1 else 4.0
	# El círculo de cada zombi: si el centro de la bala entra en él, le da (cuerpo a cuerpo, le da si el abanico lo pilla)
	for z in get_tree().get_nodes_in_group("zombis") if ayudas.circulos else []:
		var c := to_local(z.global_position)
		Formas.arco(self, c, z.radio + radio_bala + 3.0 if fuego else z.radio, 0.0, TAU, 40, ROJO, 2.0)
		draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), ROJO)
	# Hacia dónde apunta, según el modo de atacar
	var objetivo: Node2D = null
	var angulo := INF
	match johnny.modo:
		"asistido":
			objetivo = johnny.buscar_objetivo(w)
			if objetivo:
				angulo = (objetivo.global_position - johnny.global_position).angle()
		"libre":
			if johnny.con_raton:
				angulo = johnny.ayuda_apunte((get_global_mouse_position() - johnny.global_position).angle())
	# El alcance: de fuego, hasta dónde busca a quién disparar y llega la bala; cuerpo a cuerpo, el abanico del golpe
	if not ayudas.alcance:
		pass
	elif fuego:
		Formas.arco(self, p, w.alcance, 0.0, TAU, 128, BLANCO, 2.0)
	else:
		var hacia: float = angulo if angulo != INF else johnny.DIRS.find(johnny.direccion) * PI / 4
		var mitad := deg_to_rad(w.arco) / 2.0 + 0.2   # (el golpe da un poco de margen: johnny.gd, golpear)
		if mitad >= PI:
			Formas.arco(self, p, w.alcance, 0.0, TAU, 96, BLANCO, 2.0)
		else:
			Formas.arco(self, p, w.alcance, hacia - mitad, hacia + mitad, 48, BLANCO, 2.0)
			draw_line(p, p + Vector2.from_angle(hacia - mitad) * w.alcance, BLANCO, 2.0)
			draw_line(p, p + Vector2.from_angle(hacia + mitad) * w.alcance, BLANCO, 2.0)
	if objetivo and ayudas.apuntado:
		var c := to_local(objetivo.global_position)
		draw_line(p, c, AMARILLO, 2.0)
		Formas.arco(self, c, 8.0, 0.0, TAU, 16, AMARILLO, 2.0)
	# Por dónde irá la bala: sale de la boca del arma y va al zombi que pille la línea de tiro (johnny.gd, tiro)
	if ayudas.trayectoria and fuego and w.has("boca") and angulo != INF:
		var t: Array = johnny.tiro(angulo, w, johnny.direccion_de(Vector2.from_angle(angulo)))
		var salida: Vector2 = t[0]
		var fin: Vector2 = salida + Vector2.from_angle(t[1]) * w.alcance
		var pared := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(salida, fin, 1))
		if pared:
			fin = pared.position
		draw_dashed_line(to_local(salida), to_local(fin), AZUL, 2.0, 8.0)
		draw_rect(Rect2(to_local(salida) - Vector2(3, 3), Vector2(6, 6)), AZUL)
	# El camino de verdad de cada bala, desde donde salió
	for b in balas if ayudas.balas else []:
		var color: Color = {"": Color.WHITE, "acierto": VERDE, "lado": NARANJA}.get(b.fin, ROJO)
		color.a = 1.0 if b.fin == "" else clampf(1.0 - b.t / RASTRO, 0.0, 1.0)
		var desde := to_local(b.desde)
		var hasta := to_local(b.hasta)
		draw_line(desde, hasta, color, 2.0)
		draw_rect(Rect2(desde - Vector2(2, 2), Vector2(4, 4)), color)
		if b.fin != "" and b.fin != "acierto":
			draw_line(hasta + Vector2(-5, -5), hasta + Vector2(5, 5), color, 2.0)
			draw_line(hasta + Vector2(-5, 5), hasta + Vector2(5, -5), color, 2.0)


# ═════════════ El panel ═════════════

func escribir() -> void:
	panel.visible = con_panel and not escondido
	if not panel.visible:
		return
	var w: Dictionary = johnny.arma()
	var fuego: bool = w.tipo == "fuego"
	var l: Array[String] = []
	l.append("SALA DE PRUEBAS  ·  P: panel  ·  F9: salir")
	l.append("%s (%d de %d) · coma y punto: otra" % [w.nombre, indice + 1, lista.size()])
	var perdigones: int = w.get("perdigones", 1)
	var deposito: bool = w.has("deposito")
	if deposito:
		l.append("Daño %s por segundo · %s" % [decimal(w.dano, 1), {"acido": "chorro de ácido continuo", "rayo": "rayo continuo"}.get(w.efecto, "llamarada continua")])
		l.append("Alcance %d (%s casillas)" % [roundi(w.alcance), decimal(w.alcance / Planta.CASILLA, 1)])
		l.append("Depósito %s s · se llena con %s en %s s" % [decimal(w.deposito, 1), Armas.RELLENOS[w.relleno].uno, decimal(w.recarga, 2)])
		if w.efecto == "rayo":
			l.append("Aturde %s s · la descarga salta a %d zombis más" % [decimal(Llamarada.ATURDE, 1), 1 + w.get("saltos", 0)])
		else:
			l.append("Empuje %s cada %s s" % [decimal(w.empuje, 1), decimal(Llamarada.TICK * Llamarada.EMPUJA, 1)])
	elif fuego:
		l.append("Daño %s%s · %s %s/s" % [decimal(w.dano, 1), " × %d perdigones" % perdigones if perdigones > 1
			else " por disparo", decimal(w.ritmo, 1), "disparo" if is_equal_approx(w.ritmo, 1.0) else "disparos"])
		l.append("Alcance %d (%s casillas)" % [roundi(w.alcance), decimal(w.alcance / Planta.CASILLA, 1)])
		l.append("Bala: %d/s, tarda %s s en llegar" % [roundi(w.velocidad), decimal(w.alcance / w.velocidad, 2)])
		l.append("Cargador %d · recarga %s s%s" % [w.cargador, decimal(w.recarga, 2), " por cartucho" if w.cartucho
			else (" · se llena con " + Armas.RELLENOS[w.relleno].uno) if w.has("relleno") else ""])
		var extra := "Empuje %s" % decimal(w.empuje, 1)
		if w.get("temblor", 0.0) > 0.0:
			extra += " · desvío %d°" % roundi(rad_to_deg(w.temblor) / 2.0)
		if perdigones > 1:
			extra += " · abanico %d°" % roundi(rad_to_deg(w.abertura))
		l.append(extra)
	else:
		l.append("Daño %s por golpe · %s %s/s" % [decimal(w.dano, 1), decimal(w.ritmo, 1), "golpe" if is_equal_approx(w.ritmo, 1.0) else "golpes"])
		l.append("Alcance %d (%s casillas) · abanico %d°" % [roundi(w.alcance), decimal(w.alcance / Planta.CASILLA, 1), roundi(w.arco)])
		l.append("Empuje %s" % decimal(w.empuje, 1))
	l.append("Crítico: el %d %% de las veces (×%d)" % [roundi(johnny.stats.critico * 100.0), roundi(johnny.stats.critico_x)])
	var dps: float = w.dano if deposito else w.dano * perdigones * w.ritmo
	var con_recargas := ""
	if deposito:
		con_recargas = " (recargando %s)" % decimal(w.dano * w.deposito / (w.deposito + w.recarga), 1)
	elif fuego:
		var vaciar: float = w.cargador / w.ritmo + w.recarga * (w.cargador if w.cartucho else 1)
		con_recargas = " (recargando %s)" % decimal(w.dano * perdigones * w.cargador / vaciar, 1)
	l.append("Daño por segundo %s%s" % [decimal(dps, 1), con_recargas])
	if w.has("efecto"):
		l.append("Efecto: " + EFECTOS.get(w.efecto, w.efecto))
	var modo := "Modo %s (F1)" % johnny.MODOS.get(johnny.modo, johnny.modo)
	if is_instance_valid(diana):
		modo += " · diana a %s casillas" % decimal(johnny.global_position.distance_to(diana.global_position) / Planta.CASILLA, 1)
	l.append(modo)
	l.append("")
	l.append("RECUENTO  ·  Retroceso: a cero")
	if fuego and not deposito:
		var disparos: int = johnny.disparos - disparos_desde
		var linea := "Disparos %d" % disparos
		if tiros > 0:
			var acabadas: int = aciertos + fallos.lado + fallos.pared + fallos.alcance
			if tiros != disparos:
				linea += " · balas %d" % tiros
			linea += " · aciertos %d%s" % [aciertos, " (%d %%)" % roundi(100.0 * aciertos / acabadas) if acabadas > 0 else ""]
			l.append(linea)
			l.append("Fallan: por el lado %d · pared %d · lejos %d" % [fallos.lado, fallos.pared, fallos.alcance])
			if ultimo_fallo != "":
				l.append("Último por el lado: " + ultimo_fallo)
		else:
			l.append(linea)
	var en_ventana := 0
	for g in golpes:
		en_ventana += g[1]
	l.append("Daño %d · %s por segundo (últimos 3 s)" % [total, decimal(en_ventana / VENTANA, 1)])
	l.append("Habría matado %d %s" % [abatidos, "zombi normal" if abatidos == 1 else "zombis normales"])
	if ultima_muerte != "":
		l.append("  el último, en " + ultima_muerte)
	l.append("Guion: esconder las líneas y este panel")
	texto.text = "
".join(l)
	panel.size = texto.get_minimum_size() + Vector2(16, 10)


# Un número con coma y, como mucho, los decimales que se pidan (11 y no 11,0)
static func decimal(x: float, decimales: int) -> String:
	var s := String.num(x, decimales)
	if s.contains("."):
		s = s.rstrip("0").trim_suffix(".")
	return s.replace(".", ",")
