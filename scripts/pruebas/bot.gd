# El jugador automático (el bot): juega a Johnny él solo para medir lo difícil que es el juego (docs/BOT.md). Lo usan
# las pruebas del bot (prueba_bot.gd, --bot-jefes). Ve lo mismo que vería una persona —los avisos de los ataques de los
# jefes (aviso.gd), las balas y lo que le lanzan, los charcos y los zombis— y reacciona con más o menos reflejos y
# puntería según su nivel (NIVELES): un novato tarda en ver los avisos, a veces ni los ve, y falla más tiros.
# Mueve a Johnny como un mando (Input.action_press con las acciones de siempre) y apunta y ataca él (Johnny en el modo
# "quieto" de las pruebas, con intentar_atacar), fallando un poco a propósito. No toca el juego: solo pulsa botones.
extends Node

# Cómo juega cada nivel:
#   reaccion   lo que tarda en reaccionar (s): ve dónde estaba el jefe hace ese rato y los avisos, ese rato tarde
#   error      lo que se desvía cada tiro (grados, de media)
#   ve_avisos  la probabilidad de darse cuenta de cada aviso de ataque de un jefe
#   ve_balas   la de darse cuenta de cada bala o cosa que le lanzan
#   esquiva    la de hacer la esquiva (el acelerón) cuando está en peligro, en vez de solo andar
#   pensar     cada cuánto decide hacia dónde ir (s): un novato cambia de idea más despacio
#   lanza      la probabilidad de acordarse de tirarle al jefe un molotov o una granada cuando puede (cada LANZA_CADA s)
const NIVELES := {
	"novato": {"reaccion": 0.45, "error": 14.0, "ve_avisos": 0.45, "ve_balas": 0.35, "esquiva": 0.2, "pensar": 0.22, "lanza": 0.25},
	"normal": {"reaccion": 0.25, "error": 7.0, "ve_avisos": 0.75, "ve_balas": 0.65, "esquiva": 0.5, "pensar": 0.12, "lanza": 0.6},
	"bueno": {"reaccion": 0.12, "error": 3.0, "ve_avisos": 0.95, "ve_balas": 0.9, "esquiva": 0.85, "pensar": 0.06, "lanza": 0.9},
}
const LANZA_CADA := 4.0
const DIRECCIONES := 16      # hacia cuántos lados mira antes de elegir hacia dónde andar
const MIRA := 0.35           # lo lejos que mira hacia delante al elegir (s andando)
const PROYECTIL := preload("res://scripts/proyectil.gd")
const ANDAR := ["izquierda", "derecha", "arriba", "abajo"]

var partida: Node = null     # (partida.gd)
var johnny: Node = null
var nivel := "normal"
var n: Dictionary = NIVELES.normal
var activo := false

var pedido := Vector2.ZERO   # hacia dónde anda ahora (largo 0 o 1)
var pensar_t := 0.0
var giro := 1.0              # el sentido en que rodea al jefe (1 o -1); cambia de vez en cuando
var giro_t := 0.0
var vistos := {}             # cada aviso o bala que ha visto: {id: {"desde": t, "ve": si se ha dado cuenta}}
var historial: Array = []    # [t, posición] del objetivo, para verlo con retraso (reaccion)
var objetivo_de := 0         # el id del objetivo del historial
var t := 0.0
var esquivas := 0            # las esquivas que ha hecho (para el resumen)
var lanzados := 0            # los molotovs y granadas que ha tirado
var lanza_t := 0.0
var meta := Vector2.INF      # adónde quiere ir (fase 2, prueba_bot.gd: una puerta, la llave, un zombi dormido)


func _ready() -> void:
	process_physics_priority = -10   # antes que Johnny: así lee los botones de este mismo paso


func empezar(nivel_: String) -> void:
	nivel = nivel_
	n = NIVELES[nivel]
	johnny.modo = "quieto"
	activo = true
	t = 0.0
	esquivas = 0
	lanzados = 0
	lanza_t = randf_range(1.0, LANZA_CADA)
	vistos.clear()
	historial.clear()
	pedido = Vector2.ZERO
	giro = 1.0 if randf() < 0.5 else -1.0
	giro_t = randf_range(2.0, 5.0)


func parar() -> void:
	activo = false
	soltar()


func soltar() -> void:
	for a in ANDAR:
		Input.action_release(a)


func _physics_process(delta: float) -> void:
	if not activo or get_tree().paused or not johnny.vivo:
		soltar()
		return
	t += delta
	giro_t -= delta
	lanza_t -= delta
	if giro_t <= 0.0:
		giro = -giro
		giro_t = randf_range(2.0, 6.0)
	olvidar()
	pensar_t -= delta
	if pensar_t <= 0.0:
		pensar_t = n.pensar
		elegir()
	mover(pedido)
	atacar()


# Pulsa las flechas para andar hacia "v" (como un stick: cada eje con su fuerza)
func mover(v: Vector2) -> void:
	soltar()
	if v.x > 0.01:
		Input.action_press("derecha", v.x)
	elif v.x < -0.01:
		Input.action_press("izquierda", -v.x)
	if v.y > 0.01:
		Input.action_press("abajo", v.y)
	elif v.y < -0.01:
		Input.action_press("arriba", -v.y)


# ── A quién pega ──

# El jefe si se le ve; si no (escondido, tapado), el zombi más cercano que se vea
func objetivo() -> Node2D:
	var jefa: Node2D = partida.jefa
	if vale(jefa) and not escondido(jefa) and johnny.se_ve(jefa):
		return jefa
	var mejor: Node2D = null
	var cerca := INF
	for z in get_tree().get_nodes_in_group("zombis"):
		if not vale(z) or escondido(z) or z.get("sentado"):
			continue
		var d: float = johnny.global_position.distance_to(z.global_position)
		if d < cerca and johnny.se_ve(z):
			cerca = d
			mejor = z
	return mejor


# Un número de un nodo que puede no tenerlo (o tenerlo de otra cosa): si no, "si_no"
func numero(v, si_no: float) -> float:
	return float(v) if v is float or v is int else si_no


func vale(z) -> bool:
	return is_instance_valid(z) and z.is_inside_tree() and numero(z.get("vida"), 1.0) > 0


func escondido(z: Node2D) -> bool:
	return z.has_method("escondida") and z.escondida()


# Dónde ve al objetivo: donde estaba hace "reaccion" segundos (lo que tarda en enterarse de que se ha movido)
func visto_en(z: Node2D) -> Vector2:
	if z.get_instance_id() != objetivo_de:
		objetivo_de = z.get_instance_id()
		historial.clear()
	historial.append([t, z.global_position])
	while historial.size() > 2 and historial[1][0] <= t - n.reaccion:
		historial.pop_front()
	return historial[0][1]


func atacar() -> void:
	var z := objetivo()
	if z == null:
		johnny.empezar_recarga()   # sin nadie a tiro, aprovecha para recargar (como el disparo asistido)
		return
	var hacia: Vector2 = visto_en(z) - johnny.global_position
	if z == partida.jefa and lanza_t <= 0.0:
		lanza_t = LANZA_CADA
		lanzar(johnny.global_position + hacia)
	var w: Dictionary = johnny.arma()
	if w.tipo == "cuerpo" and hacia.length() - numero(z.get("radio"), 16.0) > w.alcance + 10.0:
		return
	if w.tipo != "cuerpo" and hacia.length() > w.alcance:
		return
	johnny.intentar_atacar(hacia.angle() + deg_to_rad(randfn(0.0, n.error)))


# Un molotov o una granada al jefe, si lleva y está a tiro (y si se acuerda: n.lanza), con su error de puntería
func lanzar(donde: Vector2) -> void:
	var l = partida.lanzables
	var d: float = johnny.global_position.distance_to(donde)
	if d < 120.0 or d > l.alcance() or randf() >= n.lanza:
		return
	for k in ["granada", "molotov"]:
		# (la granada, solo con el jefe lejos: si no, la explosión le pilla a él)
		if k in l.mano and l.cuantas(k) > 0 and d >= (230.0 if k == "granada" else 150.0):
			l.tipo = k
			var fallo := Vector2.from_angle(randf() * TAU) * absf(randfn(0.0, n.error * 3.0))
			l.lanzar(donde + fallo)
			lanzados += 1
			return


# ── Hacia dónde va ──

# Prueba DIRECCIONES lados (y quedarse quieto) y se queda con el que menos peligro tiene; si donde está hay peligro y
# la esquiva está lista, a veces (n.esquiva) la hace hacia el mejor lado
func elegir() -> void:
	var desde: Vector2 = johnny.global_position
	var paso: float = johnny.stats.velocidad * MIRA
	var mejor := Vector2.ZERO
	var coste_mejor := INF
	var lados: Array = [Vector2.ZERO]
	for i in DIRECCIONES:
		lados.append(Vector2.from_angle(TAU * i / DIRECCIONES))
	var aqui := peligro(desde)
	# con una meta (fase 2: una puerta, la llave...) y sin pelea, sigue el camino hacia ella; si no, la distancia al jefe
	var guia := hacia_meta(desde)
	var pelea := guia == Vector2.ZERO or en_pelea()
	for v in lados:
		var p: Vector2 = desde + v * paso
		var coste := peligro(p) + peligro(desde + v * paso * 0.5) * 0.5 + pared(desde, v, paso)
		coste += distancia(p, v) if pelea else -v.dot(guia) * 8.0 + (6.0 if v == Vector2.ZERO else 0.0)
		coste += (1.0 - v.dot(pedido)) * 0.6   # sin cambiar de idea a cada momento
		if coste < coste_mejor:
			coste_mejor = coste
			mejor = v
	pedido = mejor
	if aqui >= 30.0 and mejor != Vector2.ZERO and johnny.esquiva_espera <= 0.0 and johnny.esquiva_t <= 0.0 			and randf() < n.esquiva:
		johnny.esquivar(mejor)
		esquivas += 1


# La dirección hacia la meta (meta) por el camino del mapa (rodeando paredes y muebles), o nada si no hay meta o ya está
func hacia_meta(desde: Vector2) -> Vector2:
	if meta == Vector2.INF or desde.distance_to(meta) < 6.0:
		return Vector2.ZERO
	var camino := NavigationServer2D.map_get_path(johnny.get_world_2d().navigation_map, desde, meta, true)
	for punto in camino:
		if punto.distance_to(desde) > 14.0:
			return (punto - desde).normalized()
	return (meta - desde).normalized()


# Si hay que pelear: un zombi despierto a la vista y cerca (a los dormidos se les dispara, pero sin pararse)
func en_pelea() -> bool:
	for z in get_tree().get_nodes_in_group("zombis"):
		if vale(z) and not z.get("dormido") and not escondido(z) and not z.get("sentado") 				and johnny.global_position.distance_to(z.global_position) < 420.0 and johnny.se_ve(z):
			return true
	return false


# A qué distancia le gusta estar del jefe: lejos con un arma de fuego (dentro de su alcance), cerca con la de golpe;
# y rodeándolo hacia un lado (giro), que es lo que hace una persona
func distancia(p: Vector2, v: Vector2) -> float:
	var z: Node2D = partida.jefa if vale(partida.jefa) else objetivo()
	if z == null:
		return 0.0
	var w: Dictionary = johnny.arma()
	var radio := numero(z.get("radio"), 16.0)
	var ideal: float = clampf(w.alcance * 0.6, 160.0, 280.0) if w.tipo == "fuego" else radio + johnny.RADIO + w.alcance * 0.6
	var d := p.distance_to(z.global_position)
	var coste := minf(pow((d - ideal) / 110.0, 2.0) * 4.0, 25.0)
	var rodear: Vector2 = (z.global_position - johnny.global_position).normalized().orthogonal() * giro
	return coste - v.dot(rodear) * 0.8


# Lo peligroso que es estar en "p": dentro de un aviso (que haya visto), en el camino de una bala, donde cae algo,
# en un charco o pegado a un zombi
func peligro(p: Vector2) -> float:
	var total := 0.0
	var margen: float = johnny.RADIO + 6.0
	for jefe in jefes():
		for c in jefe.get_children():
			if c is Aviso and c.visible and lo_ve(c, n.ve_avisos):
				var dentro := en_aviso(c, p, margen)
				if dentro > 0.0:
					total += 60.0 + minf(dentro, 150.0) / 150.0 * 60.0   # cuanto más dentro, peor
	for b in get_tree().get_nodes_in_group("balas_zombi"):
		if not lo_ve(b, n.ve_balas):
			continue
		var vel: Vector2 = b.get("velocidad") if b.get("velocidad") is Vector2 else Vector2.ZERO
		var a: Vector2 = b.global_position
		var cerca := Geometry2D.get_closest_point_to_segment(p, a, a + vel * 0.7)
		if cerca.distance_to(p) < numero(b.get("radio"), 9.0) + margen:
			total += 45.0
	for c in johnny.get_parent().get_children():
		if c.get_script() == PROYECTIL and c.get("dueno") != johnny and lo_ve(c, n.ve_balas):
			var cae: Vector2 = c.cae_en if c.cae_en != Vector2.ZERO else c.hasta
			if cae.distance_to(p) < 70.0:
				total += 50.0
	for c in get_tree().get_nodes_in_group("charcos"):
		if c.get("dueno") != johnny and c.dentro(p, johnny.RADIO):
			total += 25.0
	total += suelo(p)
	for z in get_tree().get_nodes_in_group("zombis"):
		if not vale(z):
			continue
		var lim: float = numero(z.get("radio"), 16.0) + johnny.RADIO + (90.0 if z == partida.jefa else 35.0)
		var d := p.distance_to(z.global_position)
		if d < lim:
			total += (1.0 - d / lim) * (60.0 if z == partida.jefa else 25.0)
	return total


# Los peligros del suelo del sitio (peligros.gd): la porquería del Glotón, el cerco de fuego del bombero, el fuego de la
# cocina, el agua con corriente, las cosas tiradas que hacen tropezar, el frío de la cámara y el gas. Se ven siempre
# (están pintados en el suelo), sin retraso
func suelo(p: Vector2) -> float:
	var m = partida.mapa
	if m == null:
		return 0.0
	var local: Vector2 = m.to_local(p)
	var c := Peligros.casilla(local)
	var total := 0.0
	for d in m.sitio.get("peligros", []):
		match d.tipo:
			"porqueria", "cerco":
				if d.casillas.has(c):
					total += 70.0
			"fuego":
				if d.arde.has(c):
					total += 70.0
			"agua":
				if c in d.casillas and d.get("corriente", true) and not d.get("arreglado", false):
					total += 70.0
			"tropiezos":
				for cosa in d.cosas:
					if not cosa.get("volcado", false) and local.distance_to(cosa.pos) < 34.0:
						total += 20.0
	for nodo in m.get("peligros") if m.get("peligros") is Array else []:
		if is_instance_valid(nodo) and nodo.has_method("dentro") and nodo.dentro(p):
			total += 25.0
	return total


# Los que pueden tener avisos de ataque: el jefe y los zombis grandes que haya (los avisos van de hijos suyos)
func jefes() -> Array:
	var lista := []
	for z in get_tree().get_nodes_in_group("zombis"):
		if is_instance_valid(z) and (z == partida.jefa or numero(z.get("vida_max"), 0.0) >= 300):
			lista.append(z)
	if vale(partida.jefa) and not partida.jefa in lista:
		lista.append(partida.jefa)
	return lista


# Si se ha dado cuenta de algo (un aviso, una bala): lo decide una vez, al verlo, y no reacciona hasta pasado su rato
func lo_ve(cosa: Node, probabilidad: float) -> bool:
	var id := cosa.get_instance_id()
	if not vistos.has(id):
		vistos[id] = {"desde": t, "ve": randf() < probabilidad, "nodo": cosa}
	var v: Dictionary = vistos[id]
	return v.ve and t - v.desde >= n.reaccion


# Los avisos que se han apagado y las balas que ya no están se olvidan: el siguiente ataque se vuelve a sortear
func olvidar() -> void:
	for id in vistos.keys():
		var cosa = vistos[id].nodo
		if not is_instance_valid(cosa) or (cosa is Aviso and not cosa.visible):
			vistos.erase(id)


# Lo metido que está "p" (con un margen, el cuerpo de Johnny) en el aviso: lo que le falta para salir por el borde más
# cercano (negativo, fuera). La franja y la barra son rectángulos desde su origen hacia "angulo"; el abanico, un trozo
# de círculo (aplastado de arriba abajo). Así, dentro de un aviso grande (el aspirado del Glotón), sabe hacia dónde
# queda la salida
func en_aviso(a: Aviso, p: Vector2, margen: float) -> float:
	var o: Vector2 = a.to_global(a.desde)
	var d := p - o
	if a.forma == 0 or a.forma == 2:
		var l := d.rotated(-a.angulo)
		return minf(minf(l.x - a.inicio + margen, a.largo + margen - l.x), a.medio + margen - absf(l.y))
	var e := Vector2(d.x, d.y / maxf(a.aplasta, 0.1))
	var fondo := a.largo + margen - e.length()
	if a.medio >= PI - 0.01:
		return fondo
	var lado := (a.medio - absf(angle_difference(a.angulo, e.angle()))) * e.length() + margen
	return minf(fondo, lado)


# Lo que cuesta ir hacia "v": nada si hay suelo, mucho si da contra una pared o un mueble (fuera de la navegación) y,
# en la azotea, si se sale de la plataforma
func pared(desde: Vector2, v: Vector2, paso: float) -> float:
	if v == Vector2.ZERO:
		return 0.0
	var mapa_nav: RID = johnny.get_world_2d().navigation_map
	var coste := 0.0
	# cerca (lo que anda en un momento) cuenta mucho; más lejos, poco: si no, en un paso estrecho que gira, todo lo que
	# hay detrás del giro parece pared y se queda parado
	for k in [[22.0, 40.0], [44.0, 25.0], [paso, 6.0]]:
		var p: Vector2 = desde + v * k[0]
		if NavigationServer2D.map_get_closest_point(mapa_nav, p).distance_to(p) > 8.0:
			coste += k[1]
		var m = partida.mapa
		if m and m.sitio.has("helipuerto") and not m.en_plataforma(p, johnny.RADIO):
			coste += 40.0
	return coste
