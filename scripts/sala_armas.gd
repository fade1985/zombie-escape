# La sala de pruebas de armas (tecla F11 en la planta baja; el sitio lo hace planta.gd): una habitación vacía y con
# luz para ver con detalle cómo funciona cada arma. La monta mapa.gd al entrar y se va con él al salir. Tiene:
#   - la diana: un zombi normal en el centro que no pierde vida, no ataca y vuelve a su sitio si un golpe lo mueve
#     (zombi.gd, "diana"), para probar desde todas las direcciones. Sus números de daño, más grandes
#   - todas las armas, también las del banco de trabajo: coma y punto pasan a la anterior y a la siguiente
#   - munición sin fin, pero recargando: la reserva no se acaba nunca y el cargador sí
#   - las líneas de ayuda, en el suelo: el alcance del arma (de fuego, un círculo; cuerpo a cuerpo, el abanico del
#     golpe), a quién apunta el apuntado (amarillo), por dónde irá la bala (azul: sale de la boca del arma, no del
#     centro de Johnny), el círculo de cada zombi dentro del que le da la bala (rojo) y el camino de verdad de cada
#     bala (verde si da; naranja si pasa por el lado de la diana; roja si choca con la pared o se le acaba el alcance)
#   - el panel de arriba a la izquierda: la ficha del arma y el recuento de disparos, aciertos, fallos (y por qué),
#     daño por segundo y cuántos zombis normales habría matado, con una vida de mentira (Retroceso lo pone a cero; el
#     guion lo esconde y lo vuelve a sacar)
# Entra con la pistola en la mano; al salir, Johnny vuelve a llevar las armas y las balas con las que entró.
class_name SalaArmas
extends Node2D

const ZOMBI := preload("res://escenas/personajes/zombi_normal.tscn")
const BALA := preload("res://scripts/bala.gd")
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
# Lo que hace cada arma creada (su "efecto", armas_creadas.gd), para la ficha
const EFECTOS := {"aturde": "aturde", "fuego": "prende fuego", "sangra": "hace sangrar", "descarga": "aturde y salta a otro",
	"veneno": "envenena", "circulo": "pega a todo alrededor", "tira": "echa lejos y tira al suelo", "congela": "congela",
	"llama": "chorro de fuego", "cono": "cono de fuego", "acido": "chorro de ácido", "bumeran": "va, atraviesa y vuelve",
	"chispa": "chispa que aturde y salta", "garfio": "engancha y trae"}

var johnny: Node2D
var diana: Zombi
var lista: Array = []      # las armas, en el orden en que se pasan: las seis de siempre y las del banco de trabajo
var indice := 0            # la que lleva en la mano, de la lista
var en_mano := ""          # el id del arma que lleva en la mano (para saber cuándo cambia, también con Q o 1-6)
var creadas := {}          # receta → id de su arma creada (se hacen al cogerlas, una vez por visita)
var entrada := {}          # las armas y balas con las que entró Johnny (se le devuelven al salir)
var panel: ColorRect
var con_panel := true      # el guion lo esconde y lo vuelve a sacar
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
	var mapa: Node2D = get_parent()
	diana = ZOMBI.instantiate()
	diana.diana = true
	diana.casa = Vector2(mapa.sitio.ancho, mapa.sitio.alto) / 2.0
	diana.position = diana.casa
	mapa.cosas.add_child(diana)
	diana.herido.connect(_al_herir)
	get_tree().node_added.connect(_al_aparecer)
	for id in Armas.ORDEN:
		lista.append(id)
	for receta in Recetas.LISTA:
		if Armas.CREADAS.has(receta):
			lista.append(receta)
	indice = lista.find("pistola")
	# el panel, en la pantalla (como el minimapa: por debajo del fundido a negro)
	var partida := get_tree().current_scene
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
	if is_instance_valid(panel):
		panel.queue_free()
	if not is_instance_valid(johnny):
		return
	# Johnny vuelve a llevar lo que llevaba al entrar
	johnny.huecos = entrada.huecos
	johnny.balas = entrada.balas
	johnny.reserva = entrada.reserva
	johnny.municion_guardada = entrada.municion_guardada
	johnny.sostener(entrada.mano)


func _physics_process(delta: float) -> void:
	if johnny == null:
		# (Johnny llega a la sala después de montarla)
		johnny = get_tree().get_first_node_in_group("jugador")
		if johnny == null:
			return
		entrada = {"huecos": johnny.huecos.duplicate(), "mano": johnny.mano, "balas": johnny.balas,
			"reserva": johnny.reserva, "municion_guardada": johnny.municion_guardada.duplicate(true)}
		johnny.coger(lista[indice])
	reloj += delta
	# Otra arma en la mano (con coma y punto, Q o 1-6): el recuento empieza de cero
	if johnny.huecos[johnny.mano] != en_mano:
		en_mano = johnny.huecos[johnny.mano]
		var clave: String = Armas.sacadas[en_mano].receta if Armas.es_creada(en_mano) else en_mano
		if clave in lista:
			indice = lista.find(clave)
		a_cero()
	# Munición sin fin, pero recargando: la reserva siempre llena
	var w: Dictionary = Armas.datos(johnny.huecos.fuego)
	if not w.get("sin_municion", false):
		johnny.reserva = maxi(johnny.reserva, w.cargador * johnny.RESERVA_MAX)
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
			con_panel = not con_panel
		_:
			return
	get_viewport().set_input_as_handled()


# Coma y punto: el arma anterior o la siguiente de la lista
func cambiar(paso: int) -> void:
	indice = posmod(indice + paso, lista.size())
	johnny.coger(id_de(lista[indice]))
	Sonido.tocar("cambiar")


# El id con el que Johnny coge esa arma: las de siempre, el suyo; las del banco, una creada con su daño de serie
func id_de(clave: String) -> String:
	if Armas.DATOS.has(clave):
		return clave
	if not creadas.has(clave):
		creadas[clave] = Armas.apuntar(Recetas.crear(clave, "verde"))
	return creadas[clave]


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
	vida_mentira = diana.vida_max
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
	if vida_mentira >= diana.vida_max:   # el primero desde que la tiene entera
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
		vida_mentira = diana.vida_max


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
	if johnny == null:
		return
	var w: Dictionary = johnny.arma()
	var p := to_local(johnny.global_position)
	var fuego: bool = w.tipo == "fuego"
	var radio_bala := 3.0 if w.get("perdigones", 1) > 1 else 4.0
	# El círculo de cada zombi: si el centro de la bala entra en él, le da (cuerpo a cuerpo, le da si el abanico lo pilla)
	for z in get_tree().get_nodes_in_group("zombis"):
		var c := to_local(z.global_position)
		draw_arc(c, z.radio + radio_bala + 3.0 if fuego else z.radio, 0.0, TAU, 40, ROJO, 2.0)
		draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), ROJO)
	# Hacia dónde apunta, según el modo de atacar
	var objetivo: Node2D = null
	var angulo := INF
	match johnny.modo:
		"asistido":
			objetivo = johnny.buscar_objetivo(w)
			if objetivo:
				angulo = (objetivo.global_position - johnny.global_position).angle()
		"mira":
			angulo = johnny.DIRS.find(johnny.direccion) * PI / 4
		"libre":
			if johnny.con_raton:
				angulo = johnny.ayuda_apunte((get_global_mouse_position() - johnny.global_position).angle())
	# El alcance: de fuego, hasta dónde busca a quién disparar y llega la bala; cuerpo a cuerpo, el abanico del golpe
	if fuego:
		draw_arc(p, w.alcance, 0.0, TAU, 128, BLANCO, 2.0)
	else:
		var hacia: float = angulo if angulo != INF else johnny.DIRS.find(johnny.direccion) * PI / 4
		var mitad := deg_to_rad(w.arco) / 2.0 + 0.2   # (el golpe da un poco de margen: johnny.gd, golpear)
		if mitad >= PI:
			draw_arc(p, w.alcance, 0.0, TAU, 96, BLANCO, 2.0)
		else:
			draw_arc(p, w.alcance, hacia - mitad, hacia + mitad, 48, BLANCO, 2.0)
			draw_line(p, p + Vector2.from_angle(hacia - mitad) * w.alcance, BLANCO, 2.0)
			draw_line(p, p + Vector2.from_angle(hacia + mitad) * w.alcance, BLANCO, 2.0)
	if objetivo:
		var c := to_local(objetivo.global_position)
		draw_line(p, c, AMARILLO, 2.0)
		draw_arc(c, 8.0, 0.0, TAU, 16, AMARILLO, 2.0)
	# Por dónde irá la bala: sale de la boca del arma (como en johnny.gd, disparar) y va paralela a la línea amarilla
	if fuego and w.has("boca") and angulo != INF:
		var boca: Vector2 = w.boca[johnny.direccion_de(Vector2.from_angle(angulo))] * 2.0
		var salida: Vector2 = johnny.global_position + Vector2(boca.x, 16.0 + boca.y + 50.0)
		var fin: Vector2 = salida + Vector2.from_angle(angulo) * w.alcance
		var pared := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(salida, fin, 1))
		if pared:
			fin = pared.position
		draw_dashed_line(to_local(salida), to_local(fin), AZUL, 2.0, 8.0)
		draw_rect(Rect2(to_local(salida) - Vector2(3, 3), Vector2(6, 6)), AZUL)
	# El camino de verdad de cada bala, desde donde salió
	for b in balas:
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
	panel.visible = con_panel
	if not con_panel:
		return
	var w: Dictionary = johnny.arma()
	var fuego: bool = w.tipo == "fuego"
	var l: Array[String] = []
	l.append("PRUEBAS DE ARMAS  ·  F11 salir")
	l.append("%s (%d de %d) · coma y punto: otra" % [w.nombre, indice + 1, lista.size()])
	var perdigones: int = w.get("perdigones", 1)
	if fuego:
		l.append("Daño %s%s · %s %s/s" % [decimal(w.dano, 1), " × %d perdigones" % perdigones if perdigones > 1
			else " por disparo", decimal(w.ritmo, 1), "disparo" if is_equal_approx(w.ritmo, 1.0) else "disparos"])
		l.append("Alcance %d (%s casillas)" % [roundi(w.alcance), decimal(w.alcance / Planta.CASILLA, 1)])
		l.append("Bala: %d/s, tarda %s s en llegar" % [roundi(w.velocidad), decimal(w.alcance / w.velocidad, 2)])
		if not w.get("sin_municion", false):
			l.append("Cargador %d · recarga %s s%s" % [w.cargador, decimal(w.recarga, 2), " por cartucho" if w.cartucho else ""])
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
	l.append("Crítico: el %d %% de las veces (×2)" % roundi(johnny.stats.critico * 100.0))
	var dps: float = w.dano * perdigones * w.ritmo
	var con_recargas := ""
	if fuego and not w.get("sin_municion", false):
		var vaciar: float = w.cargador / w.ritmo + w.recarga * (w.cargador if w.cartucho else 1)
		con_recargas = " (recargando %s)" % decimal(w.dano * perdigones * w.cargador / vaciar, 1)
	l.append("Daño por segundo %s%s" % [decimal(dps, 1), con_recargas])
	if w.has("efecto"):
		l.append("Efecto: " + EFECTOS.get(w.efecto, w.efecto))
	var lejos := johnny.global_position.distance_to(diana.global_position)
	l.append("Modo %s (F1) · diana a %s casillas" % [johnny.MODOS[johnny.modo], decimal(lejos / Planta.CASILLA, 1)])
	l.append("")
	l.append("RECUENTO  ·  Retroceso: a cero")
	if fuego:
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
	l.append("Guion: esconder este panel")
	texto.text = "
".join(l)
	panel.size = texto.get_minimum_size() + Vector2(16, 10)


# Un número con coma y, como mucho, los decimales que se pidan (11 y no 11,0)
static func decimal(x: float, decimales: int) -> String:
	var s := String.num(x, decimales)
	if s.contains("."):
		s = s.rstrip("0").trim_suffix(".")
	return s.replace(".", ",")
