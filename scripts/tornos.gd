# El rescate propio de la recepcionista de Torre Velaria (docs/PLAN_TERCER_EDIFICIO.md, «Los supervivientes»). No está
# en un departamento: se esconde en el vestíbulo (el pasillo de la planta baja), detrás del mostrador de recepción, con
# la persiana metálica bajada (Persiana, aquí abajo; su sitio lo pone planta.gd, mostrador). Grita como los demás y,
# cuando Johnny llega al mostrador, sube la persiana y sale. Al unirse, quiere abrir los tornos de la entrada con su
# tarjeta: va hasta ellos, se pone entre los dos y pasa la tarjeta una y otra vez (aliado.gd: "forzando" con
# "con_tarjeta"), mientras entran zombis por las puertas del vestíbulo, cada vez más. Hay que protegerla DURA segundos.
# Mientras tanto, los tornos, a medio abrir, se atascan: el zombi que pasa cerca de ellos va a FRENO de su velocidad
# (zombi.gd, ir_hacia: freno), y en el suelo se ve la zona amarilla. Si la tumban, como en la horda.
#
# Lo monta supervivientes.gd: montar_persiana() al montar el vestíbulo con ella escondida, mirar() cada paso,
# empezar() al unirse y dibujar() en su capa de la pantalla. partida.gd pregunta no_cruzar() antes de cruzar una
# puerta. Los números son provisionales.
class_name Tornos
extends Node

const DURA := 60.0          # segundos abriendo los tornos (no cuentan caída ni yendo a su sitio)
const TOPE := 50            # zombis a la vez, como mucho
const CADA := [3.2, 1.6]    # segundos entre grupo y grupo, al principio y al final
const GRUPO := [3, 8]       # zombis por grupo, igual
const FRENO := 0.45         # a cuánto de su velocidad va el zombi que pasa por los tornos
const ZONA := 80.0          # lo cerca de un torno que hay que estar para que frene
const SUBE := 110.0         # a esta distancia del mostrador, sube la persiana
const PASA := 1.5           # cada cuánto pasa la tarjeta (su gesto)
const TIPOS := [["lento", "normal", "normal", "oficinista"],
	["normal", "rapido", "oficinista", "oficinista", "explosivo"]]   # la primera mitad y la segunda
# Lo que dice (en español; sale con Idioma.t)
# [traducir]
const FRASES := [
	[0.02, "Los tornos se han bloqueado. ¡Cúbreme mientras los abro!"],
	[0.15, "Tarjeta… rechazada. Otra vez"],
	[0.3, "¡Mira, se atascan con los tornos!"],
	[0.5, "¡Toma, esto estaba en objetos perdidos!"],
	[0.65, "«Acceso restringido: planta 40»… ¿qué hay ahí arriba?"],
	[0.8, "Ya casi está…"],
	[0.92, "¡Un poco más!"],
]
const LLAMADAS := ["¡Johnny, vuelve!", "¡No me dejes aquí!", "¡Que me comen!"]   # cuando le dan y Johnny anda lejos
# [/traducir]

# Dónde frenan los tornos (el pie de cada uno) mientras ella los abre; vacío: no frena nada (zombi.gd lo mira)
static var frenan: Array = []

var sup: Supervivientes
var ella: Aliado = null      # la recepcionista mientras dura su rescate (null: no hay)
var persiana: Persiana = null
var zona: Node2D = null      # la marca amarilla de los tornos en el suelo
var hecho := 0.0
var grupo_t := 0.0
var frase_i := 0
var levantando := 0.0
var cuenta := false
var tiempo := 0.0


static func es_suyo(def: Dictionary) -> bool:
	return def.get("rescate", "") == "tornos"


# Lo que frena el torno que tiene cerca un zombi en "donde" (1: nada)
static func freno(donde: Vector2) -> float:
	for t: Vector2 in frenan:
		if donde.distance_to(t) < ZONA:
			return FRENO
	return 1.0


func activa() -> bool:
	return ella != null


# Recién montado el vestíbulo con ella escondida: la persiana bajada delante del mostrador
func montar_persiana() -> Persiana:
	persiana = Persiana.new()
	persiana.position = sup.partida.planta.superviviente.mostrador + Vector2(0, 1)   # (por delante del mostrador)
	for m in sup.partida.get_tree().get_nodes_in_group("muebles"):
		if m.datos.tipo == "reception":
			persiana.tam = m.get_node("Sprite").texture.get_size() * 2.0
	sup.partida.mapa.cosas.add_child(persiana)
	return persiana


# Cada paso, con ella aún escondida: si Johnny llega al mostrador, sube la persiana y sale
func mirar(npc: Aliado) -> void:
	var s: Dictionary = sup.partida.planta.superviviente
	npc.visible = not s.puerta.cerrada
	if not s.puerta.cerrada or persiana == null or not sup.johnny.vivo:
		return
	if sup.johnny.position.distance_to(s.mostrador) < SUBE:
		s.puerta.merge({"cerrada": false, "abierta": true}, true)
		persiana.abrir()
		Sonido.tocar("puerta")
		npc.visible = true
		npc.asustado = false
		npc.decir(Idioma.t(npc.def.get("al_abrir", "")))


# Se le ha unido: se va a los tornos y se pone a abrirlos con su tarjeta; se cierran las puertas del vestíbulo
func empezar(a: Aliado) -> void:
	var partida: Node = sup.partida
	var s: Dictionary = partida.planta.superviviente
	if s.get("tornos", []).is_empty():
		return   # (sin tornos no hay rescate: se queda en el equipo, sin más)
	ella = a
	hecho = 0.0
	frase_i = 0
	levantando = 0.0
	cuenta = false
	grupo_t = 3.0
	var medio := Vector2.ZERO
	for t: Vector2 in s.tornos:
		medio += t
	medio /= s.tornos.size()
	a.sitio_forzar = medio + Vector2(0, 26)   # entre los dos, de cara a ellos
	a.mira_forzar = Vector2.UP
	a.forzando = true
	a.con_tarjeta = true
	a.vida = Aliado.VIDA
	a.caido = false
	a.add_to_group("presa")
	frenan = s.tornos.map(func(t): return t + Vector2(0, 10))
	zona = Zona.new()
	zona.sitios = frenan
	partida.mapa.cosas.add_child(zona)
	Sonido.musica("horda")
	Sonido.tocar("portazo")
	partida.decir(Idioma.t("¡Se han cerrado las puertas! Protege a la %s mientras abre los tornos") % Idioma.t(a.def.nombre), 4.0)


func _physics_process(delta: float) -> void:
	tiempo += delta
	var partida: Node = sup.partida if sup else null
	if ella == null or partida == null or partida.mapa == null or partida.cambiando:
		return
	if not is_instance_valid(ella) or not ella in sup.equipo:
		soltar()
		return
	var johnny: Node2D = sup.johnny
	var a := ella
	if a.caido:
		if johnny.vivo and johnny.position.distance_to(a.position) < 60.0:
			levantando += delta
		else:
			levantando = maxf(0.0, levantando - delta * 2.0)
		a.levantar = levantando / Supervivientes.HORDA.levantar
		if levantando >= Supervivientes.HORDA.levantar:
			levantando = 0.0
			a.levantarse()
			a.decir(Idioma.t("¡Gracias! Sigo con los tornos"))
			Particulas.anillo(a, a.global_position, 50.0, Tema.VERDE, 0.4)
	elif a.en_su_sitio():
		hecho = minf(DURA, hecho + delta)
	var k := hecho / DURA
	while frase_i < FRASES.size() and k >= FRASES[frase_i][0]:
		var frase: Array = FRASES[frase_i]
		frase_i += 1
		a.decir(Idioma.t(frase[1]))
		if frase[0] == 0.5:
			sup.soltar_provisiones(a)
	if not a.caido and DURA - hecho <= 10.0 and not cuenta:
		cuenta = true
		Sonido.tocar("jefe")
	grupo_t -= delta
	if grupo_t <= 0.0 and DURA - hecho > 3.0:
		grupo_t = lerpf(CADA[0], CADA[1], k)
		grupo(roundi(lerpf(GRUPO[0], GRUPO[1], k)), TIPOS[0 if hecho < DURA / 2.0 else 1])
	if hecho >= DURA:
		acabar()


# Un grupo de zombis entra al vestíbulo por una de sus puertas (la más lejos de Johnny, casi siempre)
func grupo(n: int, tipos: Array) -> void:
	var partida: Node = sup.partida
	n = mini(n, TOPE - get_tree().get_nodes_in_group("zombis").size())
	if n <= 0:
		return
	var dentro := {"arriba": Vector2(0, 60), "abajo": Vector2(0, -60), "izquierda": Vector2(60, 0), "derecha": Vector2(-60, 0)}
	var puertas: Array = partida.mapa.puertas.filter(func(p): return p.salida.tipo != "ascensor" and p.salida.a != partida.planta.armas)
	if puertas.is_empty():
		return
	puertas.sort_custom(func(p, q): return p.position.distance_to(sup.johnny.position) > q.position.distance_to(sup.johnny.position))
	var p: Node2D = puertas[0] if randf() < 0.6 or puertas.size() == 1 else puertas[randi_range(1, puertas.size() - 1)]
	var desde: Vector2 = p.position + dentro.get(p.salida.dir, Vector2.ZERO)
	for i in n:
		var pos := desde + Vector2(randf_range(-28, 28), randf_range(-16, 16))
		if pos.distance_to(sup.johnny.position) < 140.0:
			continue
		partida.meter_zombi(tipos.pick_random(), pos)


# Abiertos: se abren las puertas, los tornos dejan de frenar y ella sigue en el equipo como los demás
func acabar() -> void:
	var partida: Node = sup.partida
	var a := ella
	soltar()
	a.forzando = false
	a.con_tarjeta = false
	a.levantar = 0.0
	a.remove_from_group("presa")
	if not sup.rescate.is_empty():
		sup.rescate.horda_hecha = true
	partida.logros.cumplir("buen_vecino")
	Sonido.musica("menu")
	a.decir(Idioma.t("¡Abiertos! Ya podemos subir"))
	partida.decir(Idioma.t("¡La %s ha abierto los tornos!") % Idioma.t(a.def.nombre), 3.5)
	Sonido.tocar("limpio")
	get_tree().create_timer(0.25, false).timeout.connect(Sonido.tocar.bind("puerta"))
	Particulas.anillo(a, a.global_position, 50.0, a.def.color, 0.5)


# Se acaba (o se deja a medias al cambiar de sitio): los tornos ya no frenan
func soltar() -> void:
	ella = null
	frenan = []
	if is_instance_valid(zona):
		zona.queue_free()
	zona = null


# Le han dado: si se ha caído, lo dice; si Johnny anda lejos, se queja (como mucho cada 6 s)
func al_herir(cae: bool) -> void:
	if ella == null:
		return
	if cae:
		levantando = 0.0
		ella.decir(Idioma.t("¡Ayúdame, no puedo levantarme!"))
	elif sup.johnny.position.distance_to(ella.position) > Supervivientes.HORDA.lejos and ella.dicho_t > 6.0:
		ella.decir(Idioma.t(LLAMADAS.pick_random()))


# Antes de cruzar una puerta: lo que dice si no se puede, o "" si sí
func no_cruzar() -> String:
	if ella == null:
		return ""
	return Idioma.t("Aguanta: la %s está abriendo los tornos") % Idioma.t(ella.def.nombre)


# En la pantalla, la barra con la cuenta atrás (como la horda)
func dibujar(capa: Control) -> void:
	if ella == null:
		return
	var a := ella
	var falta := ceili(DURA - hecho)
	var parpadeo := int(tiempo * 6.0) % 2 == 0
	var relleno: Color = a.def.color
	var texto := Idioma.t("La %s abre los tornos · %d:%02d") % [Idioma.t(a.def.nombre), falta / 60, falta % 60]
	var color := Tema.TINTA
	if a.caido:
		relleno = Color("#ff2d4b") if parpadeo else Color("#7a2030")
		texto = Idioma.t("¡La %s ha caído!") % Idioma.t(a.def.nombre)
		color = Color("#ff8a8a")
	CuentaAtras.dibujar(capa, texto, color, hecho / DURA, relleno, falta, fmod(hecho, 1.0), not a.caido)


# ═════════════ Para probar ═════════════

# Con --captura --edificio torre --recepcionista (prueba_sitios.gd): el vestíbulo con la persiana bajada y su grito
# (captura-recepcionista-persiana.png); Johnny llega y sube la persiana (captura-recepcionista-abierta.png); se une y
# abre los tornos, con su barra y un zombi frenado (captura-recepcionista-tornos.png) y que no deja salir; tumbarla y
# levantarla; acabar (captura-recepcionista-fin.png). Luego lo suyo: el aviso de la planta, el «¡Detrás!»
# (captura-recepcionista-detras.png) y su habitación (captura-recepcionista-sala.png). Deja el equipo y el guardado
# como estaban
func probar() -> void:
	var partida: Node = sup.partida
	var johnny: Node2D = sup.johnny
	var antes: Array = sup.equipo
	for a in antes:
		if a.get_parent():
			a.get_parent().remove_child(a)
	sup.equipo = []
	sup.poner_rescate(Supervivientes.DATOS.recepcionista, 1)
	partida.nueva_planta(1)
	await partida.montar(0, 0, false)
	var s: Dictionary = partida.planta.superviviente
	print("Recepcionista: escondida en el pasillo %s · mostrador %s · tornos %d · encerrada %s · persiana %s" % [
		s.get("sitio", -1) == 0, s.get("mostrador", Vector2.ZERO), s.get("tornos", []).size(), sup.encerrado(),
		persiana != null])
	if not s.has("mostrador") or persiana == null:
		print("Recepcionista: ERROR, no sale detrás del mostrador")
		dejar(antes)
		return
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	johnny.position = s.mostrador + Vector2(-60, 220)
	johnny.get_node("Camara").reset_smoothing()
	sup.socorro_t = 0.0
	await get_tree().create_timer(0.4, false).timeout
	print("Recepcionista: se la ve %s (esperado: false)" % [sup.npc.visible if sup.npc else "sin npc"])
	Captura.foto("captura-recepcionista-persiana.png")
	# llega al mostrador: sube la persiana
	johnny.position = s.mostrador + Vector2(-50, 80)
	await get_tree().create_timer(0.9, false).timeout
	print("Recepcionista: persiana subida %s · encerrada %s · se la ve %s" % [persiana.abierta >= 1.0, sup.encerrado(),
		sup.npc.visible if sup.npc else "sin npc"])
	Captura.foto("captura-recepcionista-abierta.png")
	johnny.position = s.pos + Vector2(0, 30)
	Aliado.borrar_huellas()
	await get_tree().create_timer(0.5, false).timeout
	if ella == null:
		print("Recepcionista: ERROR, no ha empezado con los tornos (rescatada %s)" % [sup.rescate.get("rescatado", false)])
		dejar(antes)
		return
	var a := ella
	johnny.position = a.sitio_forzar + Vector2(-90, 110)
	Aliado.borrar_huellas()
	await get_tree().create_timer(2.5, false).timeout
	print("Recepcionista: en el equipo %s · en su sitio %s · lleva %.1f s · no deja salir: '%s'" % [a in sup.equipo,
		a.en_su_sitio(), hecho, no_cruzar()])
	# un zombi junto a los tornos (frenado) y otro lejos de ellos
	var cerca: Node2D = partida.meter_zombi("normal", frenan[0] + Vector2(20, 30))
	var lejos: Node2D = partida.meter_zombi("normal", frenan[0] + Vector2(-500, 150))
	print("Recepcionista: freno junto al torno %.2f · lejos %.2f (esperado: %.2f y 1.00)" % [freno(cerca.global_position),
		freno(lejos.global_position), FRENO])
	await get_tree().create_timer(0.6, false).timeout
	Captura.foto("captura-recepcionista-tornos.png")
	# tumbarla y levantarla
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	a.vida = 1
	a.inv_t = 0.0
	a.recibir_dano(5)
	var parado := hecho
	await get_tree().create_timer(0.5, false).timeout
	print("Recepcionista: caída %s · no avanza %s" % [a.caido, is_equal_approx(parado, hecho)])
	johnny.position = a.position + Vector2(30, 0)
	await get_tree().create_timer(Supervivientes.HORDA.levantar + 0.6, false).timeout
	print("Recepcionista: levantada %s" % [not a.caido])
	# acabar (adelantado)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	hecho = DURA - 0.2
	frase_i = FRASES.size()
	await get_tree().create_timer(0.6, false).timeout
	print("Recepcionista: acabado %s · tornos sin freno %s · deja salir %s · sigue en el equipo %s · dice '%s'" % [
		ella == null, frenan.is_empty(), no_cruzar() == "", a in sup.equipo, a.dicho])
	johnny.position = a.position + Vector2(-60, 90)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-recepcionista-fin.png")
	await probar_mejora(a)
	dejar(antes)


# Lo suyo, ya rescatada: el aviso de la planta, el «¡Detrás!» y su habitación
func probar_mejora(a: Aliado) -> void:
	var partida: Node = sup.partida
	var johnny: Node2D = sup.johnny
	var g := Guardado.cargar()
	var guardado := [g.rescatados.duplicate(), g.acompanante]
	Guardado.cambiar(func(x): x.rescatados = ["recepcionista"])
	print("Recepcionista: aviso en la planta %d: '%s'" % [partida.planta.num, sup.pista()])
	# el «¡Detrás!»: con Johnny mirando al sur, un zombi dormido delante no cuenta; uno que llega por detrás, sí
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	johnny.position = a.sitio_forzar + Vector2(-260, 130)
	johnny.direccion = "s"
	a.position = johnny.position + Vector2(70, 0)
	a.hab_t = 0.0
	await get_tree().create_timer(0.1, false).timeout
	var delante: Node2D = partida.meter_zombi("normal", johnny.position + Vector2(0, 60))
	await get_tree().physics_frame
	johnny.direccion = "s"
	print("Recepcionista: con uno delante, avisa %s (esperado: false)" % [a.por_detras(0.5) != null])
	delante.queue_free()
	johnny.get_node("Camara").reset_smoothing()
	var detras: Node2D = partida.meter_zombi("normal", johnny.position + Vector2(0, -80))
	var avisado := false
	for i in 60:
		johnny.direccion = "s"
		await get_tree().physics_frame
		if a.dicho == Idioma.t("¡Detrás!") and a.dicho_t < 1.0:
			avisado = true
			break
	print("Recepcionista: con uno detrás, grita «¡Detrás!» %s · el zombi a %.0f de Johnny" % [avisado,
		detras.global_position.distance_to(johnny.global_position) if is_instance_valid(detras) else -1.0])
	await get_tree().create_timer(0.15, false).timeout
	Captura.foto("captura-recepcionista-detras.png")
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	# su habitación en las viviendas, con ella dentro
	for x in sup.equipo:
		x.queue_free()
	sup.equipo = []
	await partida.montar(partida.planta.mantenimiento, 0, false)
	johnny.position = partida.mapa.puertas[1].position + Vector2(-16, 0)
	await get_tree().create_timer(1.0, false).timeout
	johnny.position = Viviendas.casa("recepcionista") + Vector2(-70, 50)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	print("Recepcionista: en las viviendas, vecinos %s" % [sup.vecinos.map(func(v): return v.def.id)])
	Captura.foto("captura-recepcionista-sala.png")
	Guardado.cambiar(func(x):
		x.rescatados = guardado[0]
		x.acompanante = guardado[1])


func dejar(antes: Array) -> void:
	soltar()
	for a in sup.equipo:
		if is_instance_valid(a):
			a.queue_free()
	sup.equipo = antes
	sup.rescate = {}
	Planta.mostrador_fijo = 0


# ═════════════ La persiana y la zona de los tornos ═════════════

# La persiana metálica bajada delante del mostrador (dibujada con código): la caja de arriba, las lamas grises y la barra
# de abajo con su asa. Tiembla cuando ella da golpes ("golpes", como la puerta del baño) y sube al abrirse
class Persiana extends Node2D:
	var tam := Vector2(132, 128)   # lo que mide el dibujo del mostrador (montar_persiana lo cambia por el de verdad)
	var abierta := 0.0             # de 0 (bajada) a 1 (subida del todo)
	var abriendo := false
	var golpes := 0.0

	func abrir() -> void:
		abriendo = true
		var tween := create_tween()
		tween.tween_property(self, "abierta", 1.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(func(): abriendo = false)

	func _process(delta: float) -> void:
		golpes = maxf(0.0, golpes - delta)
		queue_redraw()

	func _draw() -> void:
		var linea := Color("#1d1b2c")
		var ancho := tam.x - 8.0
		var x0 := -ancho / 2.0 + (sin(Time.get_ticks_msec() * 0.06) * 1.5 if golpes > 0.0 else 0.0)
		var arriba := -tam.y + 6.0
		var caja := 14.0
		# la caja donde se enrolla
		draw_rect(Rect2(x0 - 2, arriba - 2, ancho + 4, caja + 4), linea)
		draw_rect(Rect2(x0, arriba, ancho, caja), Color("#4a4e57"))
		draw_rect(Rect2(x0, arriba, ancho, 2), Color("#6a6f7a"))
		var largo := floorf((tam.y - 10.0 - caja) * (1.0 - abierta) / 2.0) * 2.0
		if largo < 4.0:
			return
		var y0 := arriba + caja
		# las lamas
		draw_rect(Rect2(x0 - 2, y0, ancho + 4, largo + 2), linea)
		var y := y0
		var i := 0
		while y < y0 + largo:
			var alto := minf(6.0, y0 + largo - y)
			draw_rect(Rect2(x0, y, ancho, alto), Color("#9aa0ab") if i % 2 == 0 else Color("#80868f"))
			draw_rect(Rect2(x0, y + alto - 2, ancho, 2), Color("#5d626c"))
			y += 6.0
			i += 1
		# la barra de abajo, con el asa y el candado
		draw_rect(Rect2(x0, y0 + largo - 6, ancho, 6), Color("#3e424a"))
		draw_rect(Rect2(-8, y0 + largo - 10, 16, 4), linea)
		draw_rect(Rect2(-6, y0 + largo - 9, 12, 2), Color("#c9ccd2"))


# La zona de los tornos que frena a los zombis: una mancha amarilla en el suelo, con rayas, que respira despacio
class Zona extends Node2D:
	var sitios: Array = []
	var t := 0.0

	func _ready() -> void:
		z_index = -1   # en el suelo, por debajo de todos

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.26 + 0.08 * sin(t * 3.0)
		for s: Vector2 in sitios:
			draw_circle(s, Tornos.ZONA, Color(1.0, 0.8, 0.2, a))
			# el borde, a trazos amarillos y negros, como la cinta de peligro
			for i in 24:
				var desde := TAU * i / 24.0
				draw_arc(s, Tornos.ZONA, desde, desde + TAU / 24.0, 4,
					Color(1.0, 0.8, 0.2, 0.85) if i % 2 == 0 else Color(0.1, 0.1, 0.12, 0.7), 4.0)
