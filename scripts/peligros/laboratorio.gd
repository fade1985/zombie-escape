# El laboratorio de la planta 40 de Torre Velaria (parte 6 del plan: el Sujeto 1). Lo pone mapa.gd cuando el sitio
# lleva "laboratorio" (planta.gd, laboratorio). Hace cuatro cosas:
#   - La CABINA blindada de la presidenta de Velaria, en medio de la pared de arriba: un ventanal con su marco, las
#     pantallas de dentro, la presidenta (presidenta.png, de PixelLab) y la consola delante. No se le puede pegar: el
#     cristal para las balas (está en la pared). Mientras dura la pelea, maneja el laboratorio desde su tableta, uno de
#     sus tres TRUCOS cada rato (TRUCOS):
#       · Láser: una línea roja fina que parpadea (el aviso) cruza la sala de pared a pared, en horizontal o en vertical,
#         y luego el rayo de verdad, un rato. Quema a quien lo toca: a Johnny (esquivando, no), a los zombis y al jefe.
#       · Cápsulas: abre dos de las cápsulas de cristal de la pared de arriba y salen sus sujetos (zombis). Solo si
#         quedan pocos zombis y cápsulas cerradas.
#       · Gas: las rejillas del suelo echan el VD-7 concentrado un rato. A Johnny no le hace nada (es el Sujeto 0); a los
#         zombis los pone frenéticos al momento, sin dormirlos (zombi.gd, gasear).
#     A media vida del jefe (o cuando lo pida su script: romper_cabina), la cabina se rompe (cristales por el suelo) y la
#     presidenta huye por detrás hacia el helipuerto. Desde ahí el laboratorio queda EN AUTOMÁTICO: solo láseres al azar,
#     más seguidos y a veces dos a la vez.
#   - La PUERTA del helipuerto, en la pared de arriba: cerrada (luz roja) hasta que cae el jefe; entonces se abre (luz
#     verde) y, al llegar Johnny a ella, se acaba el edificio (partida.gd, fin_del_edificio).
# Todo se dibuja con código menos la presidenta y las cápsulas (muebles de catalogo.gd: capsule y capsuleopen).
extends Node2D

const PRESIDENTA := preload("res://assets/sprites/presidenta.png")
const PRESIDENTA_COLUMNAS := 9           # la hoja: fila 0, la tableta (el 0, quieta); fila 1, huyendo
const CAPSULA_ABIERTA := preload("res://assets/sprites/mueble-capsuleopen.png")
const MURO := 64.0
# Cada cuánto hace un truco (con la cabina entera y en automático) y lo que espera al empezar la pelea
const CADA := [7.5, 5.5]
const PRIMERO := 3.5
const LASER := {"aviso": 1.0, "dura": 1.8, "ancho": 16.0, "dano": 15, "dano_zombi": 40, "dano_jefe": 20}
const DOS_LASERES := 0.45                # en automático, la probabilidad de que salgan dos a la vez
const CAPSULAS_DE_GOLPE := 2
const SUJETOS := ["normal", "rapido"]
const POCOS := 2                         # abre cápsulas si quedan como mucho estos zombis por ahí
const GAS := {"dura": 5.0, "radio": 95.0}
const ROJO := Color(1.0, 0.18, 0.2)
const MORADO := Color(0.5, 0.26, 0.7, 0.3)
const MORADO_CLARO := Color(0.72, 0.5, 0.9, 0.26)

var datos: Dictionary
var mapa: Node
var jefe: Node2D                         # lo pone partida.gd al salir el jefe
var t := 0.0
var espera := PRIMERO
var ultimo := ""                         # el último truco (no repite el mismo tres veces seguidas)
var seguidos := 0
var rota := false                        # la cabina, rota: en automático
var lasers: Array = []                   # [{horizontal, pos, t, pillados}]
var gas_t := 0.0                         # lo que le queda al gas
var bocanadas: Array = []                # [x, y, vx, vy, edad, dura, tamaño, semilla] (como gas.gd)
var avisado_gas := false
var cerradas: Array = []                 # los índices (en sitio.muebles) de las cápsulas aún cerradas
var salida_abierta := false
var al_salir: Callable                   # lo que pasa al llegar Johnny a la puerta abierta
var salido := false
var cabina: Node2D                       # en mapa.cosas, al pie de la pared de arriba (se ordena con los personajes)
var frente: Node2D                       # la consola y el cristal, por delante de la presidenta
var presidenta: Sprite2D
var tableta := -1.0                      # el tiempo desde que empezó a tocar la tableta (-1: quieta)
var huyendo := false
var cristales: Array = []                # los trozos del cristal roto, en el suelo de la cabina: [x, y, tamaño]
var puerta: Node2D
var abre := 0.0                          # lo abierta que está la puerta (0 a 1)
var suelo: Node2D                        # las rejillas, en el suelo


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Laboratorio"   # no-tr (nombre de nodo)
	z_index = 4   # los rayos y el gas, por delante de los personajes
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # el láser y el gas lucen por sí mismos
	material = propio
	cerradas = d.capsulas.duplicate()
	suelo = Node2D.new()
	suelo.name = "Rejillas"
	suelo.z_index = -5
	suelo.light_mask = Luz.CAPA_SUELO
	suelo.draw.connect(dibujar_suelo)
	add_child(suelo)
	# la cabina y la puerta, en la pared de arriba
	var r: Rect2 = d.cabina
	cabina = Node2D.new()
	cabina.name = "Cabina"
	cabina.position = Vector2(r.position.x + r.size.x / 2.0, MURO + 1)
	cabina.material = propio
	cabina.draw.connect(dibujar_cabina)
	mapa.cosas.add_child(cabina)
	presidenta = Sprite2D.new()
	presidenta.texture = PRESIDENTA
	presidenta.hframes = PRESIDENTA_COLUMNAS
	presidenta.vframes = 2
	presidenta.scale = Vector2(2, 2)
	presidenta.centered = true
	# los pies, escondidos detrás de la consola
	presidenta.position = Vector2(0, r.end.y - 4.0 - PRESIDENTA.get_height() / 2.0)   # (media celda = media hoja: 2 filas a escala 2)
	cabina.add_child(presidenta)
	frente = Node2D.new()
	frente.draw.connect(dibujar_frente)
	cabina.add_child(frente)
	puerta = Node2D.new()
	puerta.name = "PuertaHelipuerto"
	puerta.position = Vector2(d.puerta, MURO + 1)
	puerta.material = propio
	puerta.draw.connect(dibujar_puerta)
	mapa.cosas.add_child(puerta)


# Lo que se puso en las cosas del mapa se borra solo cuando se borra este nodo de verdad: al salir de la planta, el
# mapa se guarda fuera de la escena (partida.gd, dejar_mapa) y, al volver, tiene que seguir ahí
func _notification(que: int) -> void:
	if que != NOTIFICATION_PREDELETE:
		return
	for n in [cabina, puerta]:
		if is_instance_valid(n):
			n.queue_free()


# La pelea está en marcha: el jefe ha salido, ya no espera y le queda vida
func activo() -> bool:
	return is_instance_valid(jefe) and jefe.vida > 0 and not jefe.get("esperando")


func _physics_process(delta: float) -> void:
	t += delta
	mover_lasers(delta)
	mover_gas(delta)
	animar_presidenta(delta)
	if salida_abierta:
		abre = move_toward(abre, 1.0, delta * 1.5)
		var johnny := get_tree().get_first_node_in_group("jugador")
		if not salido and abre >= 1.0 and johnny and johnny.vivo \
				and to_local(johnny.global_position).distance_to(Vector2(datos.puerta, MURO + 22)) < 44.0:
			salido = true
			al_salir.call()
	if activo():
		if not rota and jefe.vida * 2 <= jefe.vida_max:
			romper_cabina()
		espera -= delta
		if espera <= 0.0:
			truco()
	queue_redraw()
	suelo.queue_redraw()
	cabina.queue_redraw()
	frente.queue_redraw()
	puerta.queue_redraw()


# ═════════════ Los trucos de la presidenta ═════════════

func truco() -> void:
	espera = CADA[1] if rota else CADA[0]
	if rota:
		# en automático: un láser al azar, a veces dos
		poner_laser()
		if randf() < DOS_LASERES:
			poner_laser()
		return
	var hay := ["laser"]
	if not cerradas.is_empty() and zombis_vivos() <= POCOS:
		hay.append("capsulas")
		hay.append("capsulas")   # (si se puede, más a menudo: sin zombis, la sala se queda vacía)
	if gas_t <= 0.0:
		hay.append("gas")
	if seguidos >= 2:
		hay = hay.filter(func(h): return h != ultimo)
		if hay.is_empty():
			hay = ["laser"]
	var elegido: String = hay.pick_random()
	seguidos = seguidos + 1 if elegido == ultimo else 1
	ultimo = elegido
	tableta = 0.0
	Sonido.tocar("camara")   # el pitido de la tableta
	match elegido:
		"laser":
			poner_laser()
		"capsulas":
			abrir_capsulas()
		"gas":
			echar_gas()


func zombis_vivos() -> int:
	var n := 0
	for z in get_tree().get_nodes_in_group("zombis"):
		if z != jefe and not z is Minijefe and z.get("estado") != "muerto":
			n += 1
	return n


# Un láser de pared a pared, en horizontal o en vertical, por donde está Johnny (para que haya que apartarse) o al azar
func poner_laser() -> void:
	var ancho: float = mapa.sitio.ancho
	var alto: float = mapa.sitio.alto
	var johnny := get_tree().get_first_node_in_group("jugador")
	var horizontal := randf() < 0.5
	var pos := 0.0
	if horizontal:
		pos = randf_range(MURO + 150, alto - MURO - 40)
		if johnny and randf() < 0.6:
			pos = clampf(to_local(johnny.global_position).y + 12, MURO + 150, alto - MURO - 40)
	else:
		pos = randf_range(MURO + 40, ancho - MURO - 40)
		if johnny and randf() < 0.6:
			pos = clampf(to_local(johnny.global_position).x, MURO + 40, ancho - MURO - 40)
	# (que dos láseres a la vez no caigan casi en el mismo sitio)
	for l in lasers:
		if l.horizontal == horizontal and absf(l.pos - pos) < 60.0:
			pos += 120.0 if pos < (alto if horizontal else ancho) / 2.0 else -120.0
	lasers.append({"horizontal": horizontal, "pos": pos, "t": 0.0, "pillados": {}})


func mover_lasers(delta: float) -> void:
	var quedan := []
	for l in lasers:
		var antes: float = l.t
		l.t += delta
		if antes < LASER.aviso and l.t >= LASER.aviso:
			Sonido.tocar("siseo")
		if l.t >= LASER.aviso:
			quemar(l)
		if l.t < LASER.aviso + LASER.dura:
			quedan.append(l)
	lasers = quedan


# ¿Toca el rayo el punto p (los pies de alguien)?
func en_rayo(l: Dictionary, p: Vector2, margen: float) -> bool:
	return absf((p.y if l.horizontal else p.x) - l.pos) < LASER.ancho / 2.0 + margen


func quemar(l: Dictionary) -> void:
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and not l.pillados.has(johnny) and johnny.esquiva_t <= 0.0:
		var pies: Vector2 = to_local(johnny.global_position) + Vector2(0, 12)
		if en_rayo(l, pies, 8.0):
			l.pillados[johnny] = true
			johnny.recibir_dano(LASER.dano, null, "laser")
			chispas(to_global(pies))
	for z in get_tree().get_nodes_in_group("zombis"):
		if l.pillados.has(z) or z.get("estado") == "muerto" or not z.has_method("herir"):
			continue
		var pz: Vector2 = to_local(z.global_position) + Vector2(0, 8)
		if en_rayo(l, pz, 10.0):
			l.pillados[z] = true
			var de_jefe: bool = z is Minijefe
			z.herir(LASER.dano_jefe if de_jefe else LASER.dano_zombi, ROJO)
			chispas(to_global(pz))


func chispas(donde: Vector2) -> void:
	for k in 6:
		Particulas.soltar(get_parent(), donde + Vector2(randf_range(-8, 8), -10),
			Vector2.from_angle(randf() * TAU) * 110.0, Color("#ffb0a0"), 3, 0.25)


# Abre dos cápsulas cerradas: el dibujo pasa al de la abierta, un siseo y sale su sujeto, ya despierto
func abrir_capsulas() -> void:
	cerradas.shuffle()
	for k in mini(CAPSULAS_DE_GOLPE, cerradas.size()):
		var i: int = cerradas.pop_back()
		var m: Dictionary = mapa.sitio.muebles[i]
		var nodo: Node2D = mapa.muebles[i]
		var dibujo: Sprite2D = nodo.get_node("Sprite")
		dibujo.texture = CAPSULA_ABIERTA
		var tam := CAPSULA_ABIERTA.get_size()
		dibujo.offset = Vector2(-floorf(tam.x / 2.0), -tam.y)
		for j in 10:
			Particulas.soltar(mapa.cosas, mapa.to_global(Vector2(m.x, m.y + 10)) + Vector2(randf_range(-14, 14), 0),
				Vector2(randf_range(-60, 60), randf_range(-90, -20)), Color("#7dffb0"), 3, 0.5)
		var partida := get_tree().current_scene
		if partida and partida.has_method("meter_zombi"):
			var zombi: Node2D = partida.meter_zombi(SUJETOS.pick_random(), Vector2(m.x, m.y + m.h / 2.0 + 30.0))
			if zombi and zombi.has_method("despertar"):
				zombi.despertar()
	Sonido.tocar("siseo")


func echar_gas() -> void:
	gas_t = GAS.dura
	Sonido.tocar("siseo")


func mover_gas(delta: float) -> void:
	if gas_t > 0.0:
		gas_t -= delta
		for r in datos.rejillas:
			if randf() < 20.0 * delta:
				var a := randf() * TAU
				bocanadas.append([r.x + randf_range(-6, 6), r.y + randf_range(-4, 4), cos(a) * randf_range(14, 40),
					sin(a) * randf_range(10, 26) - 6.0, 0.0, randf_range(1.6, 2.6), randf_range(14, 24), randf() * TAU])
		var johnny := get_tree().get_first_node_in_group("jugador")
		if johnny and johnny.vivo and dentro_gas(to_local(johnny.global_position)) and not avisado_gas:
			avisado_gas = true
			var partida := get_tree().current_scene
			if partida and partida.has_method("decir"):
				partida.decir(Idioma.t("Huele raro... pero a mí no me hace nada"))
		for z in get_tree().get_nodes_in_group("zombis"):
			if z.has_method("gasear") and not z is Minijefe and dentro_gas(to_local(z.global_position)):
				z.gasear(0.05)   # (casi sin dormir: despierta frenético al momento)
	var vivas := []
	for b in bocanadas:
		b[4] += delta
		b[0] += b[2] * delta
		b[1] += b[3] * delta
		if b[4] < b[5]:
			vivas.append(b)
	bocanadas = vivas


func dentro_gas(p: Vector2) -> bool:
	return gas_t > 0.0 and datos.rejillas.any(func(r): return p.distance_to(r) < GAS.radio)


# ═════════════ La cabina y la presidenta ═════════════

# Se rompe el cristal (cristales por el suelo y un estruendo) y la presidenta huye por detrás, hacia el helipuerto
func romper_cabina() -> void:
	if rota:
		return
	rota = true
	espera = minf(espera, 2.5)
	lasers.clear()
	gas_t = 0.0
	Sonido.tocar("cristal")
	var r: Rect2 = datos.cabina
	for k in 40:
		var x := randf_range(-r.size.x / 2.0, r.size.x / 2.0)
		Particulas.soltar(mapa.cosas, cabina.global_position + Vector2(x, r.position.y + r.size.y * randf_range(0.2, 0.8)),
			Vector2(randf_range(-80, 80), randf_range(20, 160)), Color("#cfeff5"), randf_range(2, 4), randf_range(0.5, 1.0))
	for k in 18:
		cristales.append([randf_range(-r.size.x / 2.0 + 10, r.size.x / 2.0 - 10), randf_range(4, 22), 2.0 * randi_range(1, 3)])
	var partida := get_tree().current_scene
	if partida and partida.has_method("decir"):
		partida.decir(Idioma.t("¡La presidenta huye hacia el helipuerto! El laboratorio se queda en automático"), 4.0)
	huyendo = true
	presidenta.flip_h = true   # (la hoja corre hacia la derecha: huye hacia la izquierda, hacia la puerta)
	var tw := create_tween()
	tw.tween_property(presidenta, "position:x", -r.size.x / 2.0 + 20.0, 1.6)
	tw.tween_property(presidenta, "modulate:a", 0.0, 0.3)


func animar_presidenta(delta: float) -> void:
	if huyendo:
		presidenta.frame = PRESIDENTA_COLUMNAS + 1 + int(t * 12.0) % (PRESIDENTA_COLUMNAS - 1)
		return
	if tableta >= 0.0:
		tableta += delta
		var f := int(tableta * 9.0)
		if f >= PRESIDENTA_COLUMNAS:
			tableta = -1.0
			f = 0
		presidenta.frame = f
	else:
		presidenta.frame = 0


# La cabina, de detrás hacia delante: el marco de acero, la pared del fondo con sus pantallas (verdes; en rojo mientras
# toca la tableta) y la luz de alarma de encima. La presidenta va encima (su Sprite2D) y, delante, frente
func dibujar_cabina() -> void:
	var r: Rect2 = datos.cabina
	var x0 := -r.size.x / 2.0
	var y0 := r.position.y   # (desde el pie de la pared)
	var alto := r.size.y
	cabina.draw_rect(Rect2(x0 - 10, y0 - 10, r.size.x + 20, alto + 16), Color("#3a4048"))
	cabina.draw_rect(Rect2(x0 - 10, y0 - 10, r.size.x + 20, 4), Color("#7c8794"))
	cabina.draw_rect(Rect2(x0, y0, r.size.x, alto), Color("#141a22"))
	# las pantallas del fondo
	var aviso := tableta >= 0.0 and int(t * 8.0) % 2 == 0
	for i in 5:
		var px := x0 + 14 + i * (r.size.x - 28) / 5.0
		var c := Color("#c8323a") if aviso else Color("#2f8f6a")
		cabina.draw_rect(Rect2(px, y0 + 12, 52, 30), Color("#0a0d12"))
		cabina.draw_rect(Rect2(px + 2, y0 + 14, 48, 26), c.darkened(0.35))
		for k in 3:
			cabina.draw_rect(Rect2(px + 6, y0 + 18 + k * 7, 16 + (i * 7 + k * 11) % 24, 2), c.lightened(0.3))
	# la luz de alarma, encima del marco
	var luz := Color("#ff3b3b") if (rota and int(t * 3.0) % 2 == 0) or aviso else Color("#5a1d1d")
	cabina.draw_rect(Rect2(-10, y0 - 22, 20, 12), Color("#2a2e34"))
	cabina.draw_rect(Rect2(-8, y0 - 20, 16, 8), luz)
	if rota:
		# los trozos de cristal, por el suelo de la cabina
		for c in cristales:
			cabina.draw_rect(Rect2(c[0], r.end.y - 34 - c[1] * 0.4, c[2], c[2]), Color("#cfeff5", 0.8))


# Delante de la presidenta: la consola (con sus botones) y el cristal blindado, con sus brillos; roto, solo el marco
# con unos picos de cristal en los bordes
func dibujar_frente() -> void:
	var r: Rect2 = datos.cabina
	var x0 := -r.size.x / 2.0
	var y0 := r.position.y
	var alto := r.size.y
	# la consola, a lo ancho de abajo
	frente.draw_rect(Rect2(x0, r.end.y - 34, r.size.x, 34), Color("#2c323a"))
	frente.draw_rect(Rect2(x0, r.end.y - 34, r.size.x, 4), Color("#56606c"))
	for i in 14:
		var bx := x0 + 12 + i * (r.size.x - 24) / 14.0
		var on := (i * 5 + int(t * 2.0)) % 7 < 3
		frente.draw_rect(Rect2(bx, r.end.y - 24, 6, 4), Color("#ffd166") if on else Color("#4fd18b"))
	if not rota:
		frente.draw_rect(Rect2(x0, y0, r.size.x, alto), Color(0.6, 0.85, 0.95, 0.12))
		for k in 3:   # los brillos en diagonal
			var bx := x0 + 30 + k * 120.0
			for j in 10:
				frente.draw_rect(Rect2(bx + j * 4, y0 + 8 + j * 8, 6, 8), Color(1, 1, 1, 0.16))
	else:
		for k in 8:
			var bx := x0 + k * r.size.x / 8.0
			frente.draw_colored_polygon(PackedVector2Array([Vector2(bx, y0), Vector2(bx + 22, y0), Vector2(bx + 8, y0 + 14 + (k * 7) % 12)]),
				Color(0.75, 0.92, 1.0, 0.5))
	# el marco, encima de todo (los parteluces)
	for k in 3:
		var mx := x0 + (k + 1) * r.size.x / 4.0 - 3
		frente.draw_rect(Rect2(mx, y0, 6, alto - 34), Color("#3a4048"))


# La puerta del helipuerto, en la pared de arriba: dos hojas de acero que se abren hacia los lados, con el símbolo del
# helipuerto (una H en un círculo) y la luz de encima: roja cerrada, verde abierta. Abierta: dentro, la escalera que sube
func dibujar_puerta() -> void:
	var w := 64.0
	var h := 84.0
	var x0 := -w / 2.0
	var y0 := -h - 2.0
	puerta.draw_rect(Rect2(x0 - 6, y0 - 6, w + 12, h + 8), Color("#4a525c"))
	puerta.draw_rect(Rect2(x0, y0, w, h), Color("#0e1116"))
	for k in 6:   # los peldaños de la escalera, subiendo
		puerta.draw_rect(Rect2(x0 + 4, y0 + h - 10 - k * 13, w - 8, 4), Color("#3c434c"))
	var hoja := (w / 2.0) * (1.0 - abre)
	for lado in [-1.0, 1.0]:
		var hx := x0 if lado < 0 else x0 + w - hoja
		puerta.draw_rect(Rect2(hx, y0, hoja, h), Color("#9aa4ae"))
		puerta.draw_rect(Rect2(hx, y0, hoja, 3), Color("#c4ccd4"))
	if abre < 0.5:
		# la H en su círculo (a pixeles de 2)
		var c := Vector2(0, y0 + 34)
		for yy in range(-9, 10):
			var aw := roundf(sqrt(maxf(81.0 - yy * yy, 0.0)))
			puerta.draw_rect(Rect2(c.x - aw * 2, c.y + yy * 2, aw * 4, 2), Color("#e8c53a"))
		puerta.draw_rect(Rect2(c.x - 8, c.y - 10, 4, 20), Color("#2a2e34"))
		puerta.draw_rect(Rect2(c.x + 4, c.y - 10, 4, 20), Color("#2a2e34"))
		puerta.draw_rect(Rect2(c.x - 8, c.y - 2, 16, 4), Color("#2a2e34"))
	var luz := Color("#5dff8a") if salida_abierta else Color("#ff3b3b")
	puerta.draw_rect(Rect2(-8, y0 - 18, 16, 8), luz)
	if salida_abierta and int(t * 3.0) % 2 == 0:
		puerta.draw_rect(Rect2(x0, -4, w, 4), Color(0.4, 1.0, 0.55, 0.5))   # una franja verde en el suelo, delante


# Cae el jefe: se abre la puerta del helipuerto; al llegar Johnny a ella, "fin" (el final del edificio)
func abrir_salida(fin: Callable) -> void:
	al_salir = fin
	salida_abierta = true
	lasers.clear()
	gas_t = 0.0
	Sonido.tocar("siseo")


# ═════════════ Lo de encima del suelo ═════════════

# Las rejillas del gas y, bajo los láseres, los emisores en las paredes: un piloto rojo en cada punta
func dibujar_suelo() -> void:
	for r in datos.rejillas:
		var o := Vector2(r.x - 12, r.y - 8)
		suelo.draw_rect(Rect2(o, Vector2(24, 16)), Color("#2a2c31"))
		suelo.draw_rect(Rect2(o + Vector2(2, 2), Vector2(20, 12)), Color("#15161a"))
		for k in 3:
			suelo.draw_rect(Rect2(o + Vector2(2, 3 + k * 4), Vector2(20, 2)), Color("#6b707a"))
		if gas_t > 0.0:
			suelo.draw_rect(Rect2(o + Vector2(2, 2), Vector2(20, 12)), Color(0.7, 0.4, 0.95, 0.4))


# Los láseres (el aviso: una línea fina que parpadea; el rayo: una franja roja con el centro blanco) y el gas
func _draw() -> void:
	var ancho: float = mapa.sitio.ancho
	var alto: float = mapa.sitio.alto
	for l in lasers:
		var largo := Rect2()
		if l.horizontal:
			largo = Rect2(MURO, l.pos - LASER.ancho / 2.0, ancho - 2 * MURO, LASER.ancho)
		else:
			largo = Rect2(l.pos - LASER.ancho / 2.0, MURO, LASER.ancho, alto - 2 * MURO)
		var centro := largo.get_center()
		if l.t < LASER.aviso:
			if int(l.t * 10.0) % 2 == 0:
				var fina := Rect2(largo.position.x, centro.y - 1, largo.size.x, 2) if l.horizontal \
					else Rect2(centro.x - 1, largo.position.y, 2, largo.size.y)
				draw_rect(fina, Color(ROJO, 0.7))
		else:
			var parpadeo := 0.85 + 0.15 * sin(t * 40.0)
			draw_rect(largo.grow(4), Color(ROJO, 0.25 * parpadeo))
			draw_rect(largo, Color(ROJO, 0.85 * parpadeo))
			var hilo := Rect2(largo.position.x, centro.y - 2, largo.size.x, 4) if l.horizontal \
				else Rect2(centro.x - 2, largo.position.y, 4, largo.size.y)
			draw_rect(hilo, Color(1, 0.92, 0.9, parpadeo))
		# los emisores de las dos puntas
		for punta in ([Vector2(MURO, centro.y), Vector2(ancho - MURO, centro.y)] if l.horizontal
				else [Vector2(centro.x, MURO), Vector2(centro.x, alto - MURO)]):
			draw_rect(Rect2(punta - Vector2(6, 6), Vector2(12, 12)), Color("#2a2e34"))
			draw_rect(Rect2(punta - Vector2(3, 3), Vector2(6, 6)), ROJO)
	for b in bocanadas:
		var k: float = b[4] / b[5]
		var radio: float = b[6] * (0.5 + k)
		var alfa: float = sin(k * PI)
		var c := Vector2(roundf(b[0] / 2.0) * 2.0, roundf(b[1] / 2.0) * 2.0)
		var color := MORADO.lerp(MORADO_CLARO, 0.5 + 0.5 * sin(t * 2.0 + b[7]))
		color.a *= alfa
		var rr := roundf(radio / 2.0)
		for y in range(-rr, rr + 1):
			var aw := roundf(sqrt(maxf(rr * rr - y * y, 0.0)))
			draw_rect(Rect2(c.x - aw * 2.0, c.y + y * 2.0, aw * 4.0, 2), color)
