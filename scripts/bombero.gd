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
#   - El giro con el lanzallamas: se va al centro de la sala, avisa (el cono rojo en el suelo) y da vueltas
#     echando una lengua de fuego larga, que se para en las paredes y los muebles: al que pilla le quema y le
#     deja ardiendo. Una explosión (granada) se lo corta (se tambalea).
#   - Molotovs (proyectil.gd, "molotov_jefe"): en curva, con su marca roja donde caen; al caer dejan un charco de
#     fuego (charco.gd): daño al entrar y un rato después de salir.
#   - Hachazo de bombero: si Johnny se le pega, levanta el hacha (aviso) y le da: daño y empujón.
# Enfadado (a media vida, «¡TODO ARDE!»): se le rompe el traje y arde él mismo (llamas.gd encima): deja un rastro
# de fuego al andar; el doble de bolas, dos lenguas de fuego en el giro y el doble de molotovs.
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
const LARGO_LENGUA := 210.0
const ANCHO_LENGUA := 0.3              # medio ángulo de la lengua (radianes)
const GIRO := 1.5                      # lo deprisa que da la vuelta (radianes por segundo)
const TIEMPO_GIRO := 4.2
const AVISO_GIRO := 0.8
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
var rastro := Vector2.ZERO   # dónde dejó el último fuego del rastro
var llamas: Llamas = null    # enfadado: arde él mismo
var luz_giro: PointLight2D   # la luz de la lengua de fuego


func _ready() -> void:
	super()
	luz_giro = LUZ.instantiate()
	luz_giro.radio = 170.0
	luz_giro.fuerza = 0.8
	luz_giro.visible = false
	add_child(luz_giro)


func pensar(delta: float, johnny: Node2D) -> void:
	espera_bolas -= delta
	espera_giro -= delta
	espera_molotov -= delta
	espera_hacha -= delta
	aviso_inmune -= delta
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
				cambiar("giro", {"angulo": datos.angulo, "largos": []})
				Sonido.tocar("fuego")
				Sonido.tocar("rugido")
		"giro":
			frenar(delta, 12.0)
			datos.angulo += GIRO * delta
			datos.largos = []
			var n: int = LENGUAS[fase - 1]
			for i in n:
				datos.largos.append(quemar_lengua(datos.angulo + i * TAU / n, johnny))
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
		espera_giro = 7.0 if enfadado() else 9.5
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


# Se para y avisa: la lengua empezará apuntando a Johnny
func avisar_giro(johnny: Node2D) -> void:
	marcha = Vector2.ZERO
	var hacia: Vector2 = johnny.global_position - global_position
	var angulo := hacia.angle() if hacia != Vector2.ZERO else PI / 2.0
	mirada = Vector2.DOWN
	cambiar("aviso_giro", {"angulo": angulo})


# Una lengua de fuego hacia "a": hasta donde llega (se para en la primera pared o mueble), quema a Johnny si está
# dentro del cono (esquivando, no) y prende a los zombis que pilla. Devuelve lo larga que es ahora mismo
func quemar_lengua(a: float, johnny: Node2D) -> float:
	var dir := Vector2.from_angle(a)
	var largo := LARGO_LENGUA
	var rayo := PhysicsRayQueryParameters2D.create(global_position, global_position + dir * LARGO_LENGUA, 1)
	var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
	if not choque.is_empty():
		largo = global_position.distance_to(choque.position)
	var hacia: Vector2 = johnny.global_position - global_position
	if johnny.vivo and hacia.length() < largo + johnny.RADIO and absf(angle_difference(a, hacia.angle())) < ANCHO_LENGUA + 0.08 \
			and johnny.esquiva_t <= 0.0:
		johnny.recibir_dano(DANO_LENGUA)
		johnny.pisar(QUEMA_LENGUA)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi == self or not zombi.has_method("prender"):
			continue
		var d: Vector2 = zombi.global_position - global_position
		if d.length() < largo + zombi.radio and absf(angle_difference(a, d.angle())) < ANCHO_LENGUA:
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
	cambiar("giro", {"angulo": datos.angulo, "largos": []})
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
		luz_giro.position = Vector2.from_angle(datos.angulo) * datos.largos[0] * 0.5 + Vector2(0, -arriba * 0.3)


# Los avisos, en el suelo (por debajo de él): el arco del hachazo y, en el giro, el anillo hasta donde llega la
# lengua y el cono por donde va
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
			draw_set_transform(Vector2(0, PIE - 6), 0.0, Vector2(1, 0.6))
			draw_arc(Vector2.ZERO, LARGO_LENGUA, 0.0, TAU, 48, Color(ROJO, 0.25 + 0.4 * k), 3.0)
			var n: int = LENGUAS[fase - 1]
			for i in n:
				var a: float = datos.angulo + i * TAU / n
				var largo: float = datos.largos[i] if estado == "giro" and i < datos.largos.size() else LARGO_LENGUA
				var color := Color(ROJO, 0.15 + 0.25 * k) if estado == "aviso_giro" else Color(Llamas.FUEGO[2], 0.3)
				draw_colored_polygon(sector(a, ANCHO_LENGUA, largo), color)
				if estado == "aviso_giro":
					draw_line(Vector2.ZERO, Vector2.from_angle(a) * LARGO_LENGUA * k, Color(ROJO, 0.9), 3.0)
	draw_set_transform(Vector2.ZERO)


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
		if i < datos.largos.size():
			lengua(lienzo, datos.angulo + i * TAU / n, datos.largos[i])


# Una lengua de fuego a cuadraditos, de la boca de la manguera hacia "a": amarilla al salir y roja en la punta,
# cada vez más ancha, que se mece y se deshilacha al final. El suelo se ve desde arriba: hacia arriba y abajo se
# acorta (escala 0,6 en y después de girar)
func lengua(lienzo: Node2D, a: float, largo: float) -> void:
	lienzo.draw_set_transform_matrix(Transform2D(0.0, Vector2(1, 0.6), 0.0, Vector2(0, -arriba * 0.4)) * Transform2D(a, Vector2.ZERO))
	var s := 10.0
	while s < largo:
		var f := s / LARGO_LENGUA   # 0 al salir, 1 en la punta
		var hw := roundf((4.0 + 16.0 * f + sin(tiempo * 19.0 + s * 0.09) * 2.0) / 2.0) * 2.0
		var vaiven := roundf(sin(tiempo * 9.0 - s * 0.05) * f * 10.0 / 2.0) * 2.0
		if f > 0.8 and fmod(s * 7.3 + tiempo * 30.0, 10.0) < 3.0:
			s += 6.0
			continue   # la punta, deshilachada
		var borde: Color = Llamas.FUEGO[4] if f > 0.45 else Llamas.FUEGO[3]
		var dentro: Color = Llamas.FUEGO[3] if f > 0.7 else Llamas.FUEGO[2] if f > 0.4 else Llamas.FUEGO[1]
		lienzo.draw_rect(Rect2(s, vaiven - hw, 6.0, hw * 2.0), borde)
		if hw > 4.0:
			lienzo.draw_rect(Rect2(s, vaiven - hw + 2.0, 6.0, hw * 2.0 - 4.0), dentro)
		if hw > 8.0 and f < 0.5:
			lienzo.draw_rect(Rect2(s, vaiven - hw + 6.0, 6.0, hw * 2.0 - 12.0), Llamas.FUEGO[0] if f < 0.2 else Llamas.FUEGO[1])
		s += 6.0
	lienzo.draw_set_transform(Vector2.ZERO)
