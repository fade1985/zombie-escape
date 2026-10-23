# El jefe de bomberos: uno de los cuatro minijefes de los Apartamentos (docs/JEFES_APARTAMENTOS.md, apartado 3).
# Un bombero zombi grande y ancho, con el traje ignífugo chamuscado y abierto por el pecho (arde por dentro), el
# casco con la visera rota, la botella de la espalda hecha depósito de gasolina y una manguera que escupe fuego.
# Lo común de los minijefes, en minijefe.gd.
#
#   - El traje le protege: EL FUEGO NO LE HACE NADA (molotov, lanzallamas, aceite ardiendo, el fuego del bate de
#     fuego —el porrazo del bate sí le entra—...): hay que cambiar de arma. Lo dice con un «¡INMUNE!»
#     ("inmune_fuego", que miran proyectil.gd y armas_creadas.gd; los charcos de fuego le llaman a prender(), que
#     aquí no hace nada).
#   - Bolas de fuego (bola_fuego.gd): van rectas a Johnny; al dar, daño y le dejan ardiendo un momento.
#   - El giro con el lanzallamas: se va al centro de la sala, avisa (la franja roja por donde empieza, apuntando a
#     Johnny, y unas flechas en el suelo que dicen hacia qué lado va a girar: cada vez, uno al azar) y da algo más
#     de una vuelta entera echando una lengua de fuego que llega hasta la pared (atraviesa los muebles): al que pilla
#     le quema y le deja ardiendo. Como su habitación arde por el borde (peligros/cerco.gd), no hay donde quedarse
#     fuera: solo se libra quien corre delante de la lengua, en su mismo sentido y a su paso (rodando no se cruza:
#     quema igual). Una explosión (granada) se lo corta (se tambalea).
#   - Molotovs (proyectil.gd, "molotov_jefe"): en curva, con su marca roja donde caen; al caer dejan un charco de
#     fuego (charco.gd): daño al entrar y un rato después de salir.
#   - Hachazo de bombero: si Johnny se le pega, levanta el hacha (aviso) y le da: daño y empujón.
# Enfadado (a media vida, «¡TODO ARDE!»): se le rompe el traje y arde él mismo (llamas.gd encima): deja un rastro
# de fuego al andar; el doble de bolas, dos lenguas de fuego opuestas en el giro (hay que correr entre las dos, a su
# paso: ni más deprisa ni más despacio) y el doble de molotovs.
extends Minijefe

const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")
const CHARCO := preload("res://escenas/armas/charco.tscn")
const LUZ := preload("res://escenas/luces/fuego.tscn")
const VELOCIDAD := 70.0
const DANO_HACHA := 22
const ALCANCE_HACHA := 64.0            # hasta dónde llega el hacha (desde su centro)
const AVISO_HACHA := 0.4
const BOLAS := [1, 2]                  # cuántas bolas de fuego de una vez (normal y enfadado)
const VELOCIDAD_BOLA := 340.0
const DANO_BOLA := 14
const QUEMA_BOLA := {"fuego": {"dps": 8.0, "despues": 1.5}}     # lo que arde Johnny al darle una bola
const MOLOTOVS := [1, 2]
const LENGUAS := [1, 2]                # lenguas de fuego en el giro
const LARGO_MAX := 1600.0              # la lengua llega hasta la pared (esto, por si no la encuentra)
const ANCHO_LENGUA := 30.0             # medio ancho de la lengua (al salir de la manguera, menos: ancho_lengua)
const GIRO := 1.0                      # lo deprisa que da la vuelta (radianes por segundo): una vuelta en 6,3 s. Johnny
                                       # le sigue el paso corriendo a unas 6 casillas de él (con poca vida, más cerca)
const TIEMPO_GIRO := 6.6               # algo más de una vuelta: pasa por toda la sala
const AVISO_GIRO := 1.0                # (le da tiempo a mirar las flechas y echar a correr)
const DANO_LENGUA := 10
const QUEMA_LENGUA := {"fuego": {"dps": 10.0, "despues": 1.5}}
const TAMBALEO := 0.7
const RASTRO_CADA := 44.0              # enfadado: cada cuántas unidades andadas deja fuego
const RASTRO_ESCALA := 0.35            # el fuego del rastro, respecto al del molotov...
const RASTRO_DURA := 0.5               # ...y lo que dura (x 4 s)
const PIE := 30.0                      # a qué altura dibuja los pies respecto a su centro
const ROJO := Color(1, 0.24, 0.35)
# Los fotogramas de sus animaciones de PixelLab (assets/pixellab.json → apartamentos-jefes → bombero-72): la bola y
# el molotov salen de la mano en SUELTA; el hacha baja en HACHA_PEGA; el giro es una vuelta entera de frente, que
# empieza en GIRO_DESDE (antes levanta la manguera) y da la vuelta en el sentido SENTIDO
const SUELTA := 4
const HACHA_PEGA := 4
const GIRO_DESDE := 1
const SENTIDO := 1.0

var inmune_fuego := true     # lo miran proyectil.gd y armas_creadas.gd: ni el molotov ni el lanzallamas le hacen nada
var espera_bolas := 1.5
var espera_giro := 4.5
var espera_molotov := 3.0
var espera_hacha := 0.0
var aviso_inmune := 0.0      # para no gritar «¡INMUNE!» sin parar
var quema_t := 0.0           # lo que falta para que la lengua pueda volver a quemar a Johnny aunque esté rodando
var rastro := Vector2.ZERO   # dónde dejó el último fuego del rastro
var llamas: Llamas = null    # enfadado: arde él mismo
var luz_giro: PointLight2D   # la luz de la lengua de fuego


func _ready() -> void:
	super()
	luz_giro = LUZ.instantiate()
	luz_giro.radio = 220.0
	luz_giro.fuerza = 0.8
	luz_giro.visible = false
	add_child(luz_giro)


func pensar(delta: float, johnny: Node2D) -> void:
	espera_bolas -= delta
	espera_giro -= delta
	espera_molotov -= delta
	espera_hacha -= delta
	aviso_inmune -= delta
	quema_t -= delta
	if enfadado() and estado != "giro":
		rastro_de_fuego()
	match estado:
		"andar":
			perseguir(delta, johnny, VELOCIDAD)
			if marcha.length() > 10.0:
				mirada = marcha.normalized()
			if espera_hacha <= 0.0 and a_mano(johnny):
				levantar_hacha(johnny)
			elif t >= dur:
				elegir(johnny)
		"aviso_hacha":
			frenar(delta, 12.0)
			if t >= AVISO_HACHA:
				cambiar("hachazo", {"dado": false})
				Sonido.tocar("barrido")
		"hachazo":
			frenar(delta, 12.0)
			if not datos.dado and sprite.frame >= HACHA_PEGA:
				datos.dado = true
				dar_hachazo(johnny)
			if t >= 0.75:
				andar(0.4)
		"bolas", "molotov":
			frenar(delta, 12.0)
			if not datos.lanzado and sprite.frame >= SUELTA:
				datos.lanzado = true
				if estado == "bolas":
					lanzar_bolas(johnny)
				else:
					lanzar_molotovs(johnny)
			if t >= 0.8:
				andar(0.5 if enfadado() else 0.8)
		"ir_centro":
			# al centro de la sala, por donde se pueda andar
			agente.target_position = datos.centro
			var hacia := global_position.direction_to(agente.get_next_path_position())
			marcha += (hacia * VELOCIDAD * 1.3 - marcha) * (1.0 - exp(-delta * 6.0))
			if marcha.length() > 10.0:
				mirada = marcha.normalized()
			if global_position.distance_to(datos.centro) < 24.0 or agente.is_navigation_finished() or t > 5.0:
				avisar_giro(johnny)
		"aviso_giro":
			frenar(delta, 12.0)
			if t >= AVISO_GIRO:
				cambiar("giro", {"angulo": datos.angulo, "sentido": datos.sentido, "largos": [], "puntas": []})
				Sonido.tocar("fuego")
				Sonido.tocar("rugido")
		"giro":
			frenar(delta, 12.0)
			datos.angulo += GIRO * datos.sentido * delta
			# lo largas que son (desde él, para quemar) y hasta dónde se dibujan (desde sus pies, en el suelo)
			datos.largos = []
			datos.puntas = []
			var n: int = LENGUAS[fase - 1]
			for i in n:
				var a: float = datos.angulo + i * TAU / n
				datos.largos.append(quemar_lengua(a, johnny))
				datos.puntas.append(hasta_la_pared(global_position + Vector2(0, PIE - 6), Vector2.from_angle(a)))
			if randf() < delta * 2.0:
				Sonido.tocar("fuego")
			if t >= TIEMPO_GIRO:
				andar(0.5 if enfadado() else 0.8)
		"tambaleo":
			frenar(delta, 5.0)
			if t >= TAMBALEO:
				andar(0.4)


func elegir(johnny: Node2D) -> void:
	var d := global_position.distance_to(johnny.global_position)
	var gira := espera_giro <= 0.0 and d < 440.0
	var bolas := espera_bolas <= 0.0 and d > 100.0
	var molotov := espera_molotov <= 0.0 and d > 140.0 and d < 520.0
	if gira:
		espera_giro = 12.0 if enfadado() else 15.0   # (el giro solo ya dura unos 8 s)
		gritar("¡A ARDER!", Color("#ff9f1c"), 20)
		var centro := centro_sala()
		if centro.distance_to(global_position) < 30.0:
			avisar_giro(johnny)
		else:
			cambiar("ir_centro", {"centro": centro})
		return
	if molotov and (not bolas or randf() < 0.45):
		espera_molotov = 3.2 if enfadado() else 4.6
		mirada = global_position.direction_to(johnny.global_position)
		cambiar("molotov", {"lanzado": false})
		return
	if bolas:
		espera_bolas = 1.9 if enfadado() else 2.8
		mirada = global_position.direction_to(johnny.global_position)
		cambiar("bolas", {"lanzado": false})
		return
	# nada a mano: sigue andando un poco y vuelve a mirar
	andar(0.3)


# ── El hachazo ──

func a_mano(johnny: Node2D) -> bool:
	return global_position.distance_to(johnny.global_position) < ALCANCE_HACHA + johnny.RADIO


# Levanta el hacha mirando a Johnny (el aviso: ya no cambia de idea)
func levantar_hacha(johnny: Node2D) -> void:
	espera_hacha = 1.6
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia != Vector2.ZERO:
		mirada = hacia.normalized()
	marcha = Vector2.ZERO
	cambiar("aviso_hacha")


# Baja el hacha: si Johnny sigue delante (y no está esquivando), le da y le empuja
func dar_hachazo(johnny: Node2D) -> void:
	Temblor.temblar(5.0)
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() < ALCANCE_HACHA + johnny.RADIO + 8.0 and absf(angle_difference(mirada.angle(), hacia.angle())) < 1.1 \
			and johnny.esquiva_t <= 0.0:
		johnny.recibir_dano(DANO_HACHA)
		johnny.empujar(mirada * 650.0)
		Sonido.tocar("porrazo")
	else:
		Sonido.tocar("clonc")   # el hacha contra el suelo
		for i in 6:
			Particulas.soltar(self, global_position + mirada * ALCANCE_HACHA * 0.8 + Vector2(0, PIE * 0.5),
				Vector2(randf_range(-60, 60), randf_range(-70, -20)), Color("#8a7a66"), 3, 0.4)


# ── Las bolas de fuego ──

# La primera, a donde está Johnny; enfadado, otra a donde va a estar si sigue andando igual
func lanzar_bolas(johnny: Node2D) -> void:
	Sonido.tocar("fuego")
	var mano := global_position + Vector2(mirada.x * 24.0, 0)
	var donde: Array = [johnny.global_position]
	if BOLAS[fase - 1] > 1:
		donde.append(johnny.global_position + johnny.velocity * 0.5)
	for p in donde:
		var bola := BolaFuego.new()
		bola.desde = mano
		bola.velocidad = mano.direction_to(p) * VELOCIDAD_BOLA
		bola.dano = DANO_BOLA
		bola.quema = QUEMA_BOLA
		get_parent().add_child(bola)
	Luz.destello(get_parent(), mano, 120.0, 0.25, 0.6)


# ── Los molotovs ──

# Uno a donde está Johnny; enfadado, otro a donde va a estar. Caen donde se pueda estar (no dentro de una pared)
func lanzar_molotovs(johnny: Node2D) -> void:
	Sonido.tocar("lanzar")
	var donde: Array = [johnny.global_position]
	if MOLOTOVS[fase - 1] > 1:
		donde.append(johnny.global_position + johnny.velocity * 0.9)
	for i in donde.size():
		var p: Node2D = PROYECTIL.instantiate()
		p.tipo = "molotov_jefe"
		p.desde = global_position + mirada * 20.0 + Vector2(0, PIE * 0.5)
		p.alto_salida = arriba * 0.5
		p.hasta = NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), donde[i])
		p.dueno = self
		get_parent().add_child(p)


# ── El giro con el lanzallamas ──

# El centro de la sala en la que está (por donde se pueda andar); si no se sabe, donde está
func centro_sala() -> Vector2:
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa == null or not mapa.sitio.has("apt"):
		return global_position
	var zona: int = mapa.zona_en(global_position)
	if zona < 0 or zona >= mapa.sitio.apt.salas.size():
		return global_position
	var sala: Dictionary = mapa.sitio.apt.salas[zona]
	var centro := Vector2((sala.c0 + sala.ancho / 2.0) * Planta.CASILLA, (sala.f0 + sala.fondo / 2.0) * Planta.CASILLA)
	return NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), centro)


# Se para y avisa: la lengua empezará apuntando a Johnny y girará hacia "sentido" (1, como las agujas del reloj; -1, al
# revés; 0, uno al azar)
func avisar_giro(johnny: Node2D, sentido := 0.0) -> void:
	marcha = Vector2.ZERO
	var hacia: Vector2 = johnny.global_position - global_position
	var angulo := hacia.angle() if hacia != Vector2.ZERO else PI / 2.0
	mirada = Vector2.DOWN
	if sentido == 0.0:
		sentido = 1.0 if randf() < 0.5 else -1.0
	cambiar("aviso_giro", {"angulo": angulo, "sentido": sentido})


# Lo ancha que es la lengua (la mitad) a "s" de él: estrecha al salir de la manguera y enseguida, ANCHO_LENGUA
func ancho_lengua(s: float) -> float:
	return minf(ANCHO_LENGUA, 8.0 + s * 0.3)


# ¿Está "p" dentro de la lengua que va hacia "dir" y mide "largo"? (con "margen" de más a los lados y en la punta)
func en_lengua(p: Vector2, dir: Vector2, largo: float, margen: float) -> bool:
	var d := p - global_position
	var a_lo_largo := d.dot(dir)
	return a_lo_largo > 0.0 and a_lo_largo < largo + margen and absf(d.cross(dir)) < ancho_lengua(a_lo_largo) + margen


# Hasta dónde llega una lengua que sale de "desde" hacia "dir": hasta la pared de la sala, atravesando los muebles
# (se mira en el plano del piso, casilla a casilla: a saltos y, al dar con la pared, afinando). Fuera de un piso
# (la exposición), hasta la primera pared o mueble
func hasta_la_pared(desde: Vector2, dir: Vector2) -> float:
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa == null or not mapa.sitio.has("apt"):
		var rayo := PhysicsRayQueryParameters2D.create(desde, desde + dir * LARGO_MAX, 1)
		var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
		return LARGO_MAX if choque.is_empty() else desde.distance_to(choque.position)
	var apt: Dictionary = mapa.sitio.apt
	var s := 0.0
	var paso := 16.0
	while s < LARGO_MAX:
		var c := Peligros.casilla(desde + dir * (s + paso))
		if Peligros.dueno(apt, c.x, c.y) >= 0:
			s += paso
		elif paso > 1.0:
			paso /= 2.0
		else:
			break
	return s


# Una lengua de fuego hacia "a": llega hasta la pared, quema a Johnny si está dentro (también rodando: la voltereta no
# la cruza, solo se libra quien corre delante de ella) y prende a los zombis que pilla. Devuelve lo larga que es
func quemar_lengua(a: float, johnny: Node2D) -> float:
	var dir := Vector2.from_angle(a)
	var largo := hasta_la_pared(global_position, dir)
	if johnny.vivo and en_lengua(johnny.global_position, dir, largo, johnny.RADIO * 0.5):
		# rodando, la voltereta le haría invulnerable: la lengua se lo salta (una vez por cada rato sin poder darle)
		if johnny.esquiva_t > 0.0 and quema_t <= 0.0:
			johnny.invulnerable = 0.0
		if johnny.invulnerable <= 0.0:
			quema_t = johnny.INVULNERABLE
		johnny.recibir_dano(DANO_LENGUA)
		Estados.pisar(johnny.pisando, QUEMA_LENGUA)   # (johnny.pisar() no apunta nada mientras rueda)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi == self or not zombi.has_method("prender"):
			continue
		if en_lengua(zombi.global_position, dir, largo, zombi.radio):
			zombi.prender()
	# chispas que saltan de la lengua
	if randf() < 0.5:
		var s := randf_range(0.2, 1.0) * largo
		Particulas.soltar(self, global_position + dir * s + Vector2(0, -arriba * 0.4 + randf_range(-6, 6)),
			dir * 60.0 + Vector2(randf_range(-20, 20), randf_range(-60, -20)), Llamas.FUEGO[randi() % 4], randf_range(1, 3), 0.4)
	return largo


# ── Inmune al fuego ──

# Los charcos de fuego y el molotov le llaman a prender(): a él no le pasa nada (lo dice, de vez en cuando)
func prender(_dano_lanzar := 1.0) -> void:
	if aviso_inmune <= 0.0 and estado != "muerto":
		aviso_inmune = 1.5
		gritar("¡INMUNE!", Llamas.FUEGO[1], 18)


# El fuego de los charcos tampoco le quema por dentro
func herir(_cantidad: float, _color := Color.WHITE) -> void:
	prender()


# Una explosión le corta el giro (y lo demás que esté haciendo): se tambalea
func recibir_golpe(cantidad: int, fuerza: Vector2, de_lleno := false) -> void:
	var antes := vida
	super(cantidad, fuerza, de_lleno)
	if estado == "muerto" or vida == antes:
		return
	if de_lleno and estado != "grito" and estado != "tambaleo":
		cambiar("tambaleo")
		marcha = Vector2.ZERO


# ── Enfadado: todo arde ──

func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, "¡TODO ARDE!")
	espera_giro = minf(espera_giro, 2.0)
	llamas = Llamas.new()
	llamas.alto = arriba * 0.8
	llamas.ancho = radio
	add_child(llamas)
	Luz.destello(get_parent(), global_position, 260.0, 0.4, 1.0)
	for i in 18:
		var a := randf() * TAU
		Particulas.soltar(self, global_position + Vector2(0, -arriba * 0.5), Vector2(cos(a) * 160.0, sin(a) * 90.0 - 60.0),
			Llamas.FUEGO[i % 4], randf_range(2, 4), 0.6)
	rastro = global_position


# Enfadado, al andar va dejando fuego en el suelo (charcos pequeños y cortos, que a él no le hacen nada)
func rastro_de_fuego() -> void:
	if global_position.distance_to(rastro) < RASTRO_CADA:
		return
	rastro = global_position
	var fuego: Node2D = CHARCO.instantiate()
	fuego.tipo = "fuego"
	fuego.escala = RASTRO_ESCALA
	fuego.duracion = RASTRO_DURA
	fuego.dueno = self
	fuego.position = ((global_position + Vector2(0, PIE * 0.5)) / 2.0).round() * 2.0
	get_parent().add_child(fuego)


# En la foto de la prueba (--captura): dando vueltas con el lanzallamas, la lengua hacia Johnny
func foto(johnny: Node2D) -> void:
	avisar_giro(johnny)
	cambiar("giro", {"angulo": datos.angulo, "sentido": datos.sentido, "largos": [], "puntas": []})
	t = 0.3


func morir() -> void:
	sprite.position = Vector2(0, PIE)
	luz_giro.visible = false
	if llamas:
		llamas.fuerza = 0.0
	super()


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	luz_giro.visible = estado == "giro"   # (aquí y no en pensar(): animar() se llama siempre, también en el grito)
	match estado:
		"aviso_hacha":
			# levanta el hacha, a punto de bajarla
			fijar("hachazo", dir, int(minf(1.0, t / AVISO_HACHA) * (HACHA_PEGA - 1)))
			sprite.position.x = sin(tiempo * 40.0) * 1.5
		"hachazo":
			var resto := sprite.sprite_frames.get_frame_count("hachazo_" + dir) - HACHA_PEGA
			fijar("hachazo", dir, HACHA_PEGA + clampi(int(t / 0.75 * resto), 0, maxi(0, resto - 1)))
		"bolas", "molotov":
			fijar("lanzar", dir, avance("lanzar_" + dir, t / 0.8))
		"aviso_giro":
			# levanta la manguera
			fijar("giro", "s", int(minf(1.0, t / AVISO_GIRO) * GIRO_DESDE))
			sprite.position.x = sin(tiempo * 40.0) * 2.0
		"giro":
			var total := sprite.sprite_frames.get_frame_count("giro_s")
			var k := fposmod((datos.angulo - PI / 2.0) * SENTIDO, TAU) / TAU
			fijar("giro", "s", GIRO_DESDE + int(k * (total - GIRO_DESDE)) % maxi(1, total - GIRO_DESDE))
		"tambaleo":
			fijar("golpe", dir, avance("golpe_" + dir, minf(1.0, t / TAMBALEO)))
			sprite.position.x = sin(tiempo * 6.0) * 3.0
		"grito":
			fijar("quieto", "s", 0)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)
	if estado == "giro" and not datos.largos.is_empty():
		luz_giro.position = Vector2.from_angle(datos.angulo) * minf(datos.largos[0] * 0.5, 240.0) + Vector2(0, -arriba * 0.3)


# Los avisos, en el suelo (por debajo de él): el arco del hachazo y, en el giro, la franja por donde va cada lengua,
# desde sus pies hasta la pared (en el aviso, roja y creciendo, con la raya por donde empieza y las flechas del lado
# al que va a girar; girando, naranja)
func _draw() -> void:
	if estado == "muerto":
		return
	match estado:
		"aviso_hacha":
			var k := minf(1.0, t / AVISO_HACHA)
			var r := ALCANCE_HACHA + 10.0
			draw_set_transform(Vector2(0, 6), 0.0, Vector2(1, 0.6))
			draw_colored_polygon(sector(mirada.angle(), 1.1, r), Color(ROJO, 0.1 + 0.2 * k))
			draw_arc(Vector2.ZERO, r, mirada.angle() - 1.1, mirada.angle() + 1.1, 16, Color(ROJO, 0.9), 3.0)
		"aviso_giro", "giro":
			var k := minf(1.0, t / AVISO_GIRO) if estado == "aviso_giro" else 1.0
			var pies := Vector2(0, PIE - 6)
			var n: int = LENGUAS[fase - 1]
			for i in n:
				var dir := Vector2.from_angle(datos.angulo + i * TAU / n)
				if estado == "aviso_giro":
					var largo := hasta_la_pared(global_position + pies, dir) * k
					if largo > 4.0:
						draw_colored_polygon(franja_lengua(pies, dir, largo), Color(ROJO, 0.2 + 0.35 * k))
						draw_line(pies, pies + dir * largo, Color(ROJO, 0.9), 4.0)
				elif i < datos.puntas.size() and datos.puntas[i] > 4.0:
					draw_colored_polygon(franja_lengua(pies, dir, datos.puntas[i]), Color(Llamas.FUEGO[2], 0.3))
			if estado == "aviso_giro":
				flechas(pies, datos.sentido, minf(1.0, k * 3.0))
	draw_set_transform(Vector2.ZERO)


# Los puntos de la franja de una lengua en el suelo: de "desde" hacia "dir", "largo" de larga y con su ancho
# (ancho_lengua: más estrecha al salir)
func franja_lengua(desde: Vector2, dir: Vector2, largo: float) -> PackedVector2Array:
	var lado := dir.orthogonal()
	var izq := PackedVector2Array()
	var der := PackedVector2Array()
	var s := 0.0
	while true:
		izq.append(desde + dir * s + lado * ancho_lengua(s))
		der.append(desde + dir * s - lado * ancho_lengua(s))
		if s >= largo:
			break
		s = minf(s + 24.0, largo)
	der.reverse()
	return izq + der


# Las flechas del aviso del giro: dos anillos de puntas de flecha en el suelo, alrededor de "centro", que corren hacia
# el lado al que va a girar la lengua ("sentido": 1, como las agujas del reloj; -1, al revés). Rojas y con el borde
# oscuro, para que se vean en cualquier suelo. "k", lo que se ven (0 a 1)
func flechas(centro: Vector2, sentido: float, k: float) -> void:
	for anillo in [[110.0, 6], [200.0, 10]]:
		var r: float = anillo[0]
		var n: int = anillo[1]
		for j in n:
			var b := j * TAU / n + tiempo * 1.2 * sentido
			var fuera := Vector2.from_angle(b)
			var hacia := Vector2.from_angle(b + PI / 2.0 * sentido)   # por donde va a girar
			var p := centro + fuera * r
			var punta := PackedVector2Array([p + hacia * 11.0, p - hacia * 9.0 + fuera * 14.0, p - hacia * 3.0,
				p - hacia * 9.0 - fuera * 14.0])
			draw_colored_polygon(punta, Color(ROJO, 0.95 * k))
			punta.append(punta[0])
			draw_polyline(punta, Color(0.16, 0.03, 0.05, 0.8 * k), 2.0)


# Los puntos de un sector de círculo: del centro, el arco de "a - ancho" a "a + ancho" a "r" de distancia
func sector(a: float, ancho: float, r: float) -> PackedVector2Array:
	var puntos := PackedVector2Array([Vector2.ZERO])
	for i in 13:
		puntos.append(Vector2.from_angle(a - ancho + 2.0 * ancho * i / 12.0) * r)
	return puntos


# Por encima de él: las lenguas de fuego del giro
func pintar_encima(lienzo: Node2D) -> void:
	if estado != "giro":
		return
	var n: int = LENGUAS[fase - 1]
	for i in n:
		if i < datos.puntas.size():
			lengua(lienzo, datos.angulo + i * TAU / n, datos.puntas[i])


# Una lengua de fuego a cuadraditos hacia "a", "largo" de larga (en el suelo, desde sus pies hasta la pared): sale en
# alto de la boca de la manguera y va bajando hasta tocar el suelo en la pared. Amarilla al salir y roja en la punta,
# más ancha al alejarse, que se mece y se deshilacha al final. Cada trozo, de 6 unidades, girado hacia "a"
func lengua(lienzo: Node2D, a: float, largo: float) -> void:
	var dir := Vector2.from_angle(a)
	var boca := Vector2(0, -arriba * 0.4)
	var pies := Vector2(0, PIE - 6)
	var s := 10.0
	while s < largo:
		var f := s / largo   # 0 al salir, 1 en la punta
		var hw := roundf((ancho_lengua(s) * 0.75 + sin(tiempo * 19.0 + s * 0.09) * 2.0) / 2.0) * 2.0
		var vaiven := roundf(sin(tiempo * 9.0 - s * 0.05) * minf(1.0, s / 150.0) * 8.0 / 2.0) * 2.0
		if f > 0.85 and fmod(s * 7.3 + tiempo * 30.0, 10.0) < 3.0:
			s += 6.0
			continue   # la punta, deshilachada
		# (cada trozo, algo más largo que el paso: al ir bajando, si no, quedarían rendijas entre uno y otro)
		lienzo.draw_set_transform(boca.lerp(pies, f) + dir * s, a)
		var borde: Color = Llamas.FUEGO[4] if f > 0.45 else Llamas.FUEGO[3]
		var dentro: Color = Llamas.FUEGO[3] if f > 0.7 else Llamas.FUEGO[2] if f > 0.4 else Llamas.FUEGO[1]
		lienzo.draw_rect(Rect2(0.0, vaiven - hw, 8.0, hw * 2.0), borde)
		if hw > 4.0:
			lienzo.draw_rect(Rect2(0.0, vaiven - hw + 2.0, 8.0, hw * 2.0 - 4.0), dentro)
		if hw > 8.0 and f < 0.5:
			lienzo.draw_rect(Rect2(0.0, vaiven - hw + 6.0, 8.0, hw * 2.0 - 12.0), Llamas.FUEGO[0] if f < 0.2 else Llamas.FUEGO[1])
		s += 6.0
	lienzo.draw_set_transform(Vector2.ZERO)
