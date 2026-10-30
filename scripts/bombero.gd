# El jefe de bomberos: uno de los cuatro minijefes de los Apartamentos (docs/historial/JEFES_APARTAMENTOS.md, apartado 3).
# Un bombero zombi grande y ancho, con el traje ignífugo chamuscado y abierto por el pecho (arde por dentro), el
# casco con la visera rota, la botella de la espalda hecha depósito de gasolina y una manguera que escupe fuego.
# Lo común de los minijefes, en minijefe.gd.
#
#   - El traje le protege: EL FUEGO NO LE HACE NADA (molotov, lanzallamas, aceite ardiendo, el fuego del bate de
#     fuego —el porrazo del bate sí le entra—...): hay que cambiar de arma. Lo dice con un «¡INMUNE!»
#     ("inmune_fuego", que miran proyectil.gd y armas_creadas.gd; los charcos de fuego le llaman a prender(), que
#     aquí no hace nada).
#   - Bolas de fuego (bola_fuego.gd): tres de una vez, en abanico hacia Johnny (de cerca no se cabe entre dos: hay
#     que rodar o apartarse bastante); al dar, daño y le dejan ardiendo un momento.
#   - El giro con el lanzallamas: se va al centro de la sala, avisa (el cono rojo por donde empieza, apuntando a
#     Johnny, y unas flechas en el suelo que dicen hacia qué lado va a girar: cada vez, uno al azar) y da algo más
#     de una vuelta entera echando un cono de fuego (40 grados: estrecho al salir de la manguera y cada vez más ancho)
#     que llega hasta la pared (atraviesa los muebles): al que pilla le quema y le deja ardiendo. Como su habitación
#     arde por el borde (peligros/cerco.gd), no hay donde quedarse fuera: solo se libra quien corre delante del cono,
#     en su mismo sentido y a su paso (rodando no se cruza: es más ancho que la voltereta y quema igual). Mientras
#     sale el fuego le rodea una burbuja de fuego (como la cúpula del científico jefe, pero
#     sin vida propia: no se rompe) y NADA LE QUITA VIDA: ni balas, ni golpes, ni explosiones (y la explosión tampoco
#     le corta el giro); donde le dan, saltan chispas y la burbuja brilla. En el aviso todavía no la tiene: ahí sí se le puede pegar, y
#     una explosión (granada) se lo corta (se tambalea).
#   - Molotovs (proyectil.gd, "molotov_jefe"): dos de una vez, uno donde está Johnny y otro donde va a estar; en
#     curva, con su marca roja donde caen; al caer dejan un charco de fuego (charco.gd): daño al entrar y un rato
#     después de salir.
#   - Hachazo de bombero: si Johnny se le pega, levanta el hacha (aviso) y le da: daño y empujón.
# Enfadado (a media vida, «¡TODO ARDE!»): se le rompe el traje y arde él mismo (llamas.gd encima): deja un rastro
# de fuego al andar; cinco bolas en abanico, dos conos de fuego opuestos en el giro (hay que correr por el hueco entre
# los dos, a su paso: ni más deprisa ni más despacio) y tres molotovs en fila (detrás de Johnny, donde está y delante:
# hay que salir de lado); bolas y molotovs, más seguidos.
extends Minijefe

const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")
const CHARCO := preload("res://escenas/armas/charco.tscn")
const LUZ := preload("res://escenas/luces/fuego.tscn")
const VELOCIDAD := 70.0
const DANO_HACHA := 22
const ALCANCE_HACHA := 64.0            # hasta dónde llega el hacha (desde su centro)
const AVISO_HACHA := 0.4
const BOLAS := [3, 5]                  # cuántas bolas de fuego de una vez (normal y enfadado), en abanico...
const ABANICO_BOLAS := 0.26            # ...con 15 grados (en radianes) de una a otra
const ESPERA_BOLAS := [2.2, 1.6]       # cada cuánto las tira (normal y enfadado)
const VELOCIDAD_BOLA := 340.0
const DANO_BOLA := 14
const QUEMA_BOLA := {"fuego": {"dps": 8.0, "despues": 1.5}}     # lo que arde Johnny al darle una bola
const MOLOTOVS := [2, 3]
const ESPERA_MOLOTOV := [4.0, 2.8]
const SEPARA_MOLOTOV := 110.0          # lo menos que se separan los molotovs de una vez (lo que mide su fuego, de borde
                                       # a borde): así no caen unos encima de otros
const CONOS := [1, 2]                  # conos de fuego en el giro
const ESPERA_GIRO := [22.0, 18.0]      # cada cuánto gira, normal y enfadado
const LARGO_MAX := 1600.0              # el cono llega hasta la pared (esto, por si no la encuentra)
const ABERTURA := 0.35                 # medio cono, en radianes: 20 grados a cada lado del medio (40 en total)
const RAYOS := 10                      # en cuántos trozos se parte el cono de borde a borde para medir hasta dónde
                                       # llega cada uno y dibujarlo (de 4 grados cada uno)
const GIRO := 1.0                     # lo deprisa que da la vuelta (radianes por segundo): una vuelta en 6,3 s. Johnny
                                       # le sigue el paso corriendo a unas 6 casillas de él (con poca vida, más cerca)
const TIEMPO_GIRO := 6.6               # algo más de una vuelta: pasa por toda la sala
const AVISO_GIRO := 1.0                # (le da tiempo a mirar las flechas y echar a correr)
const DANO_CONO := 10
const QUEMA_CONO := {"fuego": {"dps": 10.0, "despues": 1.5}}
const BURBUJA_RADIO := 92.0            # la burbuja de fuego del giro (la cúpula del científico, 78: él es más ancho)
const BURBUJA_ALTO := 0.42             # a qué altura tiene el centro (de "arriba")
const BURBUJA_SUBE := 0.4              # lo que tarda en subir (y en bajar)
# La burbuja, dibujada: el escudo "divine-shield" de pixelfx en colores de fuego (tools/pixelfx/escudo-fuego.js), en
# tres hojas de 8 × 6 fotogramas de 112 px a 20 por segundo: lo de detrás de él, lo de delante y el brillo, que se suma
const ESCUDO := [preload("res://assets/sprites/escudo-fuego-detras.png"),
	preload("res://assets/sprites/escudo-fuego-delante.png"), preload("res://assets/sprites/escudo-fuego-brillo.png")]
const ESCUDO_CENTRO := Vector2(56, 58)   # el centro de la esfera en cada fotograma (en píxeles del dibujo)
const ESCUDO_FPS := 20.0
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

var inmune_fuego := true     # lo miran proyectil.gd, armas_creadas.gd y llamarada.gd: ni el molotov ni el lanzallamas le hacen nada
var espera_bolas := 1.5
var espera_giro := 4.5
var espera_molotov := 3.0
var espera_hacha := 0.0
var aviso_inmune := 0.0      # para no gritar «¡INMUNE!» sin parar
var quema_t := 0.0           # lo que falta para que el cono pueda volver a quemar a Johnny aunque esté rodando
var rastro := Vector2.ZERO   # dónde dejó el último fuego del rastro
var llamas: Llamas = null    # enfadado: arde él mismo
var luz_giro: PointLight2D   # la luz del cono de fuego
var burbuja := 0.0           # lo subida que está la burbuja de fuego del giro (0 = no hay, 1 = entera)
var destello := 0.0          # lo que brilla la burbuja porque le acaban de dar (de 1 a 0)
var destello_por := Vector2.ZERO   # hacia dónde le han dado (desde él); Vector2.ZERO, por todos lados (una explosión)
var escudo: Array[Sprite2D] = []   # las tres capas de la burbuja (detrás, delante y brillo)
var chorros: Array[ChorroFuego] = [ChorroFuego.new(), ChorroFuego.new()]   # el fuego de cada cono del giro


func _ready() -> void:
	super()
	luz_giro = LUZ.instantiate()
	luz_giro.radio = 300.0   # (el cono, ancho: alumbra más que una lengua)
	luz_giro.fuerza = 0.85
	luz_giro.visible = false
	add_child(luz_giro)
	# la burbuja: lo de detrás, por debajo de su dibujo; lo de delante y el brillo, encima (y debajo de $Vapor, que
	# pinta los conos de fuego: salen de dentro)
	for i in 3:
		var capa := Sprite2D.new()
		capa.texture = ESCUDO[i]
		capa.hframes = 8
		capa.vframes = 6
		capa.offset = Vector2(56, 56) - ESCUDO_CENTRO
		capa.position = Vector2(0, -arriba * BURBUJA_ALTO)
		capa.visible = false
		if i > 0:
			capa.z_index = 1
		if i == 2:
			var suma := CanvasItemMaterial.new()
			suma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			capa.material = suma
		add_child(capa)
		move_child(capa, $Sprite.get_index() + (0 if i == 0 else i))
		escudo.append(capa)


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
			datos.puntas = medir_conos()   # (el aviso dibuja el cono entero, hasta la pared)
			if t >= AVISO_GIRO:
				cambiar("giro", {"angulo": datos.angulo, "sentido": datos.sentido, "largos": [], "puntas": datos.puntas})
				Sonido.tocar("fuego")
				Sonido.tocar("rugido")
		"giro":
			frenar(delta, 12.0)
			datos.angulo += GIRO * datos.sentido * delta
			# hasta dónde llega cada cono (desde sus pies, en el suelo, rayo a rayo: para dibujarlo) y lo que quema; y
			# lo largo que es por el medio (desde él)
			datos.puntas = medir_conos()
			datos.largos = []
			var n: int = CONOS[fase - 1]
			for i in mini(n, datos.puntas.size()):
				datos.largos.append(quemar_cono(datos.angulo + i * TAU / n, johnny, datos.puntas[i]))
			if randf() < delta * 2.0:
				Sonido.tocar("fuego")
			if t >= TIEMPO_GIRO:
				andar(0.5 if enfadado() else 0.8)
		"tambaleo":
			frenar(delta, 5.0)
			if t >= TAMBALEO:
				andar(0.4)
	# mientras sale el fuego, la burbuja de fuego le protege: nada le quita vida (recibir_golpe)
	if estado == "giro":
		invulnerable = true


func elegir(johnny: Node2D) -> void:
	var d := global_position.distance_to(johnny.global_position)
	var gira := espera_giro <= 0.0 and d < 440.0
	var bolas := espera_bolas <= 0.0 and d > 100.0
	var molotov := espera_molotov <= 0.0 and d > 140.0 and d < 520.0
	if gira:
		# (el giro solo ya dura unos 8 s; hasta el 27 oct, cada 15 y 12 s: pasaba la mitad del combate en su burbuja)
		espera_giro = ESPERA_GIRO[1] if enfadado() else ESPERA_GIRO[0]
		gritar(Idioma.t("¡A ARDER!"), Color("#ff9f1c"), 20)
		var centro := centro_sala()
		if centro.distance_to(global_position) < 30.0:
			avisar_giro(johnny)
		else:
			cambiar("ir_centro", {"centro": centro})
		return
	if molotov and (not bolas or randf() < 0.45):
		espera_molotov = ESPERA_MOLOTOV[fase - 1]
		mirada = global_position.direction_to(johnny.global_position)
		cambiar("molotov", {"lanzado": false})
		return
	if bolas:
		espera_bolas = ESPERA_BOLAS[fase - 1]
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


# Baja el hacha: si Johnny sigue delante (y no está esquivando ni hay una pared o un mueble en medio), le da y le empuja
func dar_hachazo(johnny: Node2D) -> void:
	Temblor.temblar(5.0)
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() < ALCANCE_HACHA + johnny.RADIO + 8.0 and absf(angle_difference(mirada.angle(), hacia.angle())) < 1.1 \
			and johnny.esquiva_t <= 0.0 and not Aviso.tapado(self, johnny.global_position):
		johnny.recibir_dano(DANO_HACHA, self)
		johnny.empujar(mirada * 650.0)
		Sonido.tocar("porrazo")
	else:
		Sonido.tocar("clonc")   # el hacha contra el suelo
		for i in 6:
			Particulas.soltar(self, global_position + mirada * ALCANCE_HACHA * 0.8 + Vector2(0, PIE * 0.5),
				Vector2(randf_range(-60, 60), randf_range(-70, -20)), Color("#8a7a66"), 3, 0.4)


# ── Las bolas de fuego ──

# En abanico: la del medio, a donde está Johnny; las demás, de ABANICO_BOLAS en ABANICO_BOLAS a cada lado
func lanzar_bolas(johnny: Node2D) -> void:
	Sonido.tocar("fuego")
	var mano := global_position + Vector2(mirada.x * 24.0, 0)
	var hacia := mano.direction_to(johnny.global_position)
	var n: int = BOLAS[fase - 1]
	for i in n:
		var bola := BolaFuego.new()
		bola.dueno = self
		bola.desde = mano
		bola.velocidad = hacia.rotated((i - (n - 1) / 2.0) * ABANICO_BOLAS) * VELOCIDAD_BOLA
		bola.dano = DANO_BOLA
		bola.quema = QUEMA_BOLA
		get_parent().add_child(bola)
	Luz.destello(get_parent(), mano, 120.0, 0.25, 0.6)


# ── Los molotovs ──

# Uno a donde está Johnny y otro a donde va a estar (si va despacio, un poco más allá; si está quieto, a un lado);
# enfadado, un tercero al otro lado: una fila de fuego de la que hay que salir de lado. Se separan por lo menos
# SEPARA_MOLOTOV, para que no caigan unos encima de otros. Caen donde se pueda estar (no dentro de una pared)
func lanzar_molotovs(johnny: Node2D) -> void:
	Sonido.tocar("lanzar")
	var aqui: Vector2 = johnny.global_position
	var va: Vector2 = johnny.velocity * 0.9   # (lo que tarda el molotov en caer)
	if va.length() < 20.0:
		va = global_position.direction_to(aqui).orthogonal() * (1.0 if randf() < 0.5 else -1.0)
	if va.length() < SEPARA_MOLOTOV:
		va = va.normalized() * SEPARA_MOLOTOV
	var donde: Array = [aqui, aqui + va, aqui - va].slice(0, MOLOTOVS[fase - 1])
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


# Se para y avisa: el cono empezará apuntando a Johnny y girará hacia "sentido" (1, como las agujas del reloj; -1, al
# revés; 0, uno al azar)
func avisar_giro(johnny: Node2D, sentido := 0.0) -> void:
	marcha = Vector2.ZERO
	var hacia: Vector2 = johnny.global_position - global_position
	var angulo := hacia.angle() if hacia != Vector2.ZERO else PI / 2.0
	mirada = Vector2.DOWN
	if sentido == 0.0:
		sentido = 1.0 if randf() < 0.5 else -1.0
	cambiar("aviso_giro", {"angulo": angulo, "sentido": sentido, "puntas": []})


# El ángulo del rayo "j" (de 0 a RAYOS, de un borde al otro) de un cono que apunta hacia "a"
func angulo_rayo(a: float, j: int) -> float:
	return a + ABERTURA * (2.0 * j / RAYOS - 1.0)


# Hasta dónde llega cada cono, desde sus pies (en el suelo): por cada uno, lo largo de sus RAYOS + 1 rayos, de un
# borde al otro (cada uno, hasta la pared)
func medir_conos() -> Array:
	var conos := []
	var pies := global_position + Vector2(0, PIE - 6)
	var n: int = CONOS[fase - 1]
	for i in n:
		var rayos := []
		for j in RAYOS + 1:
			rayos.append(hasta_la_pared(pies, Vector2.from_angle(angulo_rayo(datos.angulo + i * TAU / n, j))))
		conos.append(rayos)
	return conos


# ¿Está "p" dentro del cono que apunta hacia "a"? (con "margen" de más a los lados y en la punta). Se abre ABERTURA a
# cada lado y llega hasta la pared
func en_cono(p: Vector2, a: float, margen: float) -> bool:
	var d := p - global_position
	var dir := Vector2.from_angle(a)
	var a_lo_largo := d.dot(dir)
	if a_lo_largo <= 0.0 or absf(d.cross(dir)) >= a_lo_largo * tan(ABERTURA) + margen:
		return false
	return d.length() < hasta_la_pared(global_position, d.normalized()) + margen


# Hasta dónde llega un rayo del cono que sale de "desde" hacia "dir": hasta la pared de la sala, atravesando los muebles
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


# Un cono de fuego hacia "a" ("puntas", lo largo de cada rayo desde sus pies: medir_conos): llega hasta la pared,
# quema a Johnny si está dentro (también rodando: la voltereta no lo cruza, solo se libra quien corre delante de él) y
# prende a los zombis que pilla. Devuelve lo largo que es por el medio (desde él)
func quemar_cono(a: float, johnny: Node2D, puntas: Array) -> float:
	# (con la skin del bombero, a Johnny el cono no le hace nada)
	if johnny.vivo and not johnny.ignifugo() and en_cono(johnny.global_position, a, johnny.RADIO * 0.5):
		# rodando, la voltereta le haría invulnerable: el cono se lo salta (una vez por cada rato sin poder darle)
		if johnny.esquiva_t > 0.0 and quema_t <= 0.0:
			johnny.invulnerable = 0.0
		if johnny.invulnerable <= 0.0:
			quema_t = johnny.INVULNERABLE
		johnny.recibir_dano(DANO_CONO, self)
		Estados.pisar(johnny.pisando, QUEMA_CONO)   # (johnny.pisar() no apunta nada mientras rueda)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi == self or not zombi.has_method("prender"):
			continue
		if en_cono(zombi.global_position, a, zombi.radio):
			zombi.prender()
	# chispas que saltan del cono, por todo él (a la altura del fuego, que baja de la manguera al suelo de la pared)
	for k in 2:
		if randf() < 0.5:
			var j := randi() % (RAYOS + 1)
			var dir := Vector2.from_angle(angulo_rayo(a, j))
			var f := randf_range(0.2, 1.0)
			var donde := Vector2(0, -arriba * 0.4).lerp(Vector2(0, PIE - 6), f) + dir * float(puntas[j]) * f
			Particulas.soltar(self, global_position + donde + Vector2(0, randf_range(-6, 6)),
				dir * 60.0 + Vector2(randf_range(-20, 20), randf_range(-60, -20)), Llamas.FUEGO[randi() % 4], randf_range(1, 3), 0.4)
	return hasta_la_pared(global_position, Vector2.from_angle(a))


# ── Inmune al fuego ──

# Los charcos de fuego y el molotov le llaman a prender(): a él no le pasa nada
func prender(_dano_lanzar := 1.0) -> void:
	decir_inmune()


# Lo dice de vez en cuando, no a cada golpe: «¡INMUNE!»
func decir_inmune() -> void:
	if aviso_inmune <= 0.0 and estado != "muerto":
		aviso_inmune = 1.5
		gritar(Idioma.t("¡INMUNE!"), Llamas.FUEGO[1], 18)


# El fuego de los charcos tampoco le quema por dentro
func herir(_cantidad: float, _color := Color.WHITE) -> void:
	prender()


# Una explosión le corta lo que esté haciendo (también el aviso del giro): se tambalea. Girando, no: la burbuja de
# fuego se lo lleva todo (golpes, balas y explosiones), sin quitarle vida ni pararle, y brilla donde le dan
func recibir_golpe(cantidad: int, fuerza: Vector2, de_lleno := false, de_aliado := false) -> void:
	if invulnerable and estado == "giro":
		rebote(fuerza, de_lleno)
		return
	var antes := vida
	super(cantidad, fuerza, de_lleno, de_aliado)
	if estado == "muerto" or vida == antes:
		return
	if de_lleno and estado != "grito" and estado != "tambaleo":
		cambiar("tambaleo")
		marcha = Vector2.ZERO


# Le han dado con la burbuja puesta: la burbuja brilla, saltan chispas de fuego por donde viene el golpe (una
# explosión, por todos lados) y, de vez en cuando, grita «¡INMUNE!». "fuerza" va hacia donde empuja el golpe
func rebote(fuerza: Vector2, de_lleno: bool) -> void:
	destello = 1.0
	destello_por = Vector2.ZERO if de_lleno else -fuerza.normalized()
	var centro := global_position + Vector2(0, -arriba * BURBUJA_ALTO)
	for i in 6:
		var a := randf() * TAU if destello_por == Vector2.ZERO else destello_por.angle() + randf_range(-0.4, 0.4)
		var donde := centro + Vector2.from_angle(a) * BURBUJA_RADIO
		Particulas.soltar(self, donde, Vector2(cos(a), sin(a)) * randf_range(60.0, 150.0) + Vector2(0, -40),
			Llamas.FUEGO[i % 4], 3, 0.3)
	Sonido.tocar("chispa")
	decir_inmune()


# ── Enfadado: todo arde ──

func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, Idioma.t("¡TODO ARDE!"))
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


# En la foto de la prueba (--captura): dando vueltas con el lanzallamas, el cono hacia Johnny (con la burbuja ya
# subida)
func foto(johnny: Node2D) -> void:
	avisar_giro(johnny)
	cambiar("giro", {"angulo": datos.angulo, "sentido": datos.sentido, "largos": [], "puntas": []})
	t = 0.3
	burbuja = 1.0


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
	# la burbuja de fuego sube al empezar el giro y baja al acabar; el destello de un golpe se apaga enseguida
	var paso := get_physics_process_delta_time()
	burbuja = clampf(burbuja + paso / BURBUJA_SUBE * (1.0 if estado == "giro" else -1.0), 0.0, 1.0)
	destello = maxf(0.0, destello - paso * 4.0)
	var cuadro := int(tiempo * ESCUDO_FPS) % 48
	for i in 3:
		escudo[i].visible = burbuja > 0.0
		escudo[i].scale = Vector2.ONE * 2.0 * burbuja
		escudo[i].frame = cuadro
	# donde le acaban de dar, brilla: más brillo y la burbuja más clara
	escudo[1].modulate = Color.WHITE.lerp(Color(1.6, 1.4, 1.2), destello)
	escudo[2].modulate = Color.WHITE * (1.0 + 2.0 * destello)
	# el fuego de los conos: sale mientras gira; al parar, lo que ya ha salido llega a la pared y se apaga
	var n: int = CONOS[fase - 1]
	for i in chorros.size():
		var c := chorros[i]
		var echa: bool = estado == "giro" and i < n and i < datos.get("puntas", []).size()
		if echa:
			c.angulo = datos.angulo + i * TAU / n
			c.puntas = datos.puntas[i]
			c.abertura = ABERTURA
			c.boca = Vector2(0, -arriba * 0.4)
			c.pies = Vector2(0, PIE - 6)
		c.avanzar(paso, echa)
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
		# (el cono es más ancho lejos de él: la luz, algo más allá de la mitad)
		luz_giro.position = Vector2.from_angle(datos.angulo) * minf(datos.largos[0] * 0.6, 300.0) + Vector2(0, -arriba * 0.3)


# Los avisos, en el suelo (por debajo de él): el arco del hachazo y, en el giro, el cono por donde va cada fuego,
# desde sus pies hasta la pared (aviso.gd: en el aviso, rojo y llenándose, con las flechas del lado al que va a girar;
# girando, naranja)
func _draw() -> void:
	if estado == "muerto":
		return
	match estado:
		"aviso_hacha":
			Aviso.golpe(self, Vector2(0, 6), mirada.angle(), 1.1, ALCANCE_HACHA + 10.0, minf(1.0, t / AVISO_HACHA),
				tiempo, 0.6)
		"aviso_giro", "giro":
			var k := minf(1.0, t / AVISO_GIRO) if estado == "aviso_giro" else 1.0
			var pies := Vector2(0, PIE - 6)
			var n: int = CONOS[fase - 1]
			for i in mini(n, datos.puntas.size()):
				var a: float = datos.angulo + i * TAU / n
				# el cono, hasta la pared (aviso.gd): en el aviso se llena; girando, lleno y naranja
				var cono := Aviso.abanico(self, pies, a, ABERTURA, 0.0, k, tiempo, 1.0, 0.0, i)
				cono.rayos(datos.puntas[i])
				if estado == "giro":
					cono.tinte = Llamas.FUEGO[2]
					cono.destella = false
			if estado == "aviso_giro":
				Aviso.flechas_giro(self, pies, datos.sentido, minf(1.0, k * 3.0), tiempo, CONOS.max())
	draw_set_transform(Vector2.ZERO)


# Por encima de él (y de la burbuja de fuego: salen de dentro): el fuego de los conos del giro (chorro_fuego.gd)
func pintar_encima(lienzo: Node2D) -> void:
	for c in chorros:
		c.pintar(lienzo)
