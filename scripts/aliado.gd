# Un superviviente (SurvivorNPC y Ally del JS: src/props.js y src/entities.js). Según "modo":
#   - "encerrado": en el baño de su apartamento, temblando, hasta que Johnny limpia el piso y se le arrima.
#   - "equipo": sigue a Johnny dando vueltas a su alrededor y usa lo suyo: el policía y el militar disparan al
#     zombi más cercano; la médica cura a Johnny cada pocos segundos y al limpiar cada piso. Los del centro
#     comercial: el ferretero da martillazos a los que se le acercan, el técnico suelta
#     una descarga que deja quieto al zombi más cercano y, con la farmacéutica, los charcos de veneno y ácido le
#     hacen a Johnny la mitad (eso lo mira johnny.gd: charcos_a_medias).
#     En la horda (supervivientes.gd) se queda delante de la puerta forzando la cerradura ("forzando"): tiene
#     vida, los zombis van a por él y, si cae, se queda tumbado hasta que Johnny lo levanta.
#     La farmacéutica, en su rescate (escolta.gd), va herida ("herida"): cojea detrás de Johnny, despacio, con su
#     vida encima; los zombis van a por ella como en la horda y, si cae, igual.
#   - "vecino": rescatado en otra partida, espera en la sala de mantenimiento a que Johnny se le arrime.
# Los tres de los Apartamentos (policía, médica y militar) se dibujan con su hoja de PixelLab (HOJAS: assets/sprites/
# superviviente-<id>, hechas con tools/superviviente.py al tamaño y estilo de Johnny). Los del centro comercial siguen
# dibujados con formas, como en el JS (persona.gd).
class_name Aliado
extends CharacterBody2D

signal herido(cae: bool)   # en la horda: le han dado (y si se ha caído)

const RADIO := 14.0        # para los zombis: a qué distancia le alcanzan
const BALA := preload("res://escenas/armas/bala.tscn")
const CHARCOS := ["veneno", "acido", "toxico"]   # los que la farmacéutica deja a medias
const RUMBOS := ["e", "se", "s", "so", "o", "no", "n", "ne"]
const LINEA := Color("#1d1b2c")
const PAPEL := Color("#fff8ea")
const ALCANCE := 400.0     # a qué distancia busca zombis para disparar
const VIDA := 100          # la vida en la horda (HORDA.vida en el JS)
const DESTELLO := preload("res://escenas/personajes/destello.gdshader")   # el blanco al recibir un golpe (como los zombis)
# Los que tienen hoja de PixelLab (tools/superviviente.py). "boca": dónde está la boca del arma en cada dirección, en
# píxeles del dibujo desde los pies (como en armas.gd; lo dice la herramienta al montar la hoja). "fogonazo": a los
# cuántos segundos de empezar lo suyo sale el fogonazo (ahí sale la bala) o llega el pinchazo de la jeringa (ahí cura):
# la acción son 8 fotogramas a 15 por segundo y el fogonazo está en el 4º
const HOJAS := {
	"policia": {"hoja": preload("res://assets/sprites/superviviente-policia.tres"), "fogonazo": 0.2,
		"boca": {"s": Vector2(-4, -34), "se": Vector2(26, -29), "e": Vector2(23, -37), "ne": Vector2(23, -52),
			"n": Vector2(-1, -52), "no": Vector2(-29, -50), "o": Vector2(-33, -35), "so": Vector2(-27, -14)}},
	"medico": {"hoja": preload("res://assets/sprites/superviviente-medica.tres"), "fogonazo": 0.27},
	"militar": {"hoja": preload("res://assets/sprites/superviviente-militar.tres"), "fogonazo": 0.2,
		"boca": {"s": Vector2(24, -25), "se": Vector2(26, -23), "e": Vector2(32, -36), "ne": Vector2(28, -43),
			"n": Vector2(-1, -51), "no": Vector2(-24, -48), "o": Vector2(-31, -37), "so": Vector2(-27, -16)}},
}

var def: Dictionary
var modo := "equipo"
var johnny: Node2D
var partida: Node
var idx := 0               # su puesto en el equipo (para repartirse alrededor de Johnny)
var es_vecino := false     # viene de la sala de mantenimiento (y "casa" es su sitio allí)
var casa := Vector2.ZERO
var armado := true       # vecino: hay que apartarse un poco antes de que vuelva a contar el arrimarse
var asustado := true       # encerrado: mientras quedan zombis en el piso
var tiempo := 0.0
var direccion := "s"
var hab_t := 0.0           # lo que falta para usar lo suyo
var rafaga := 0            # balas que quedan de la ráfaga
var rafaga_t := 0.0
var cura_t := 0.0          # el destello de la curación
var rayo_t := 0.0          # la descarga del técnico (lo que le queda por verse) y adónde va
var rayo_a := Vector2.ZERO
var forzando := false
var sitio_forzar := Vector2.ZERO
var mira_forzar := Vector2.UP
var herida := false        # la farmacéutica, mientras Johnny la lleva a las escaleras (escolta.gd)
var vida := VIDA
var caido := false
var inv_t := 0.0
var golpe_t := 0.0
var levantar := 0.0        # de 0 a 1: lo que lleva Johnny levantándole (lo pone supervivientes.gd)
var dicho := ""            # lo que acaba de decir (bocadillo) y desde cuándo
var dicho_t := 99.0
var vivo: bool:
	get: return not caido

var cuerpo: Node2D         # su dibujo: la Persona (formas) o, con hoja, el nodo que lleva la sombra y el sprite
var persona: Persona = null   # el dibujo con formas (los del centro comercial)
var sprite: AnimatedSprite2D = null   # la hoja de PixelLab (los tres de los Apartamentos: HOJAS)
var accion_t := -1.0       # con hoja: lo que lleva lo suyo (disparo, ráfaga o cura); -1, nada en marcha
var accion_cura := 0       # con hoja: lo que curará la médica cuando llegue el pinchazo (0: nada pendiente)
var mirada := Vector2.DOWN # hacia dónde mira (y apunta)
var agente: NavigationAgent2D   # le busca el camino rodeando paredes y muebles (como a los zombis)
var encima: Node2D         # la vida, el bocadillo y su nombre, por encima de todo


func preparar(datos: Dictionary, en_modo: String) -> void:
	def = datos
	modo = en_modo
	add_to_group("aliados")
	collision_layer = 0
	collision_mask = 1     # solo choca con paredes y muebles
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RADIO
	forma.shape = circulo
	add_child(forma)
	agente = NavigationAgent2D.new()
	agente.path_desired_distance = 12.0
	agente.target_desired_distance = 12.0
	agente.path_max_distance = 60.0
	add_child(agente)
	if HOJAS.has(def.id):
		# con hoja de PixelLab: la sombra y el sprite, colocados como los de Johnny (los pies 16 por debajo del centro)
		cuerpo = Node2D.new()
		var sombra := Sombra.new()
		sombra.position = Vector2(0, 16)
		sombra.ancho = 50.0
		sombra.alto = 16.0
		cuerpo.add_child(sombra)
		sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = HOJAS[def.id].hoja
		sprite.position = Vector2(0, 16)
		sprite.scale = Vector2(2, 2)
		sprite.centered = false
		sprite.offset = Vector2(-48, -78)   # los pies de la casilla de la hoja (tools/superviviente.py)
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = DESTELLO
		sprite.play("reposo_s")
		cuerpo.add_child(sprite)
	else:
		persona = Persona.new()
		persona.look = def.look
		persona.arma = def.get("arma", "")
		persona.paso = randf() * 6.0
		cuerpo = persona
	add_child(cuerpo)
	encima = Node2D.new()
	encima.z_index = 40
	encima.draw.connect(dibujar_encima)
	add_child(encima)
	hab_t = randf_range(0.4, def.habilidad.cada)


func _physics_process(delta: float) -> void:
	tiempo += delta
	inv_t = maxf(0.0, inv_t - delta)
	golpe_t = maxf(0.0, golpe_t - delta)
	cura_t = maxf(0.0, cura_t - delta)
	rayo_t = maxf(0.0, rayo_t - delta)
	dicho_t += delta
	cuerpo.rotation = 0.0
	cuerpo.position = Vector2.ZERO
	if persona:
		persona.retroceso = maxf(0.0, persona.retroceso - delta * 10.0)
		persona.fogonazo = persona.retroceso > 0.6
	match modo:
		"encerrado":
			# tiembla de miedo mientras quedan zombis; luego mira a Johnny
			if asustado:
				cuerpo.position.x = sin(tiempo * 40.0) * 1.2
				animar("reposo", Vector2.DOWN)
			else:
				animar("reposo", johnny.global_position - global_position)
		"vecino":
			animar("reposo", johnny.global_position - global_position)
		"equipo":
			if forzando:
				forzar()
			elif herida:
				cojear()
			else:
				seguir()
				if johnny.vivo:
					habilidad(delta)
	# andar: el paso avanza con lo rápido que va
	var rapidez := velocity.length() if modo == "equipo" and not caido else 0.0
	if persona:
		persona.blanco = golpe_t > 0.0
		persona.paso += delta * (4.0 + rapidez / 22.0 if rapidez > 20.0 else 0.0)
		persona.andando = minf(1.0, rapidez / 150.0)
		persona.mueve = velocity.normalized() if rapidez > 1.0 else Vector2.ZERO
	else:
		dibujar_hoja(delta, rapidez)
	encima.queue_redraw()


# Se reparten alrededor de Johnny, dando vueltas despacio, y le siguen
func seguir() -> void:
	var n: int = maxi(1, partida.supervivientes.equipo.size())
	var angulo: float = float(idx) / n * TAU + partida.duracion * 0.6
	var meta: Vector2 = johnny.global_position + Vector2(cos(angulo) * 55.0, sin(angulo) * 42.0)
	ir_a(meta, 420.0)
	if velocity.length() > 20.0:
		animar("andar", velocity)
	else:
		animar("reposo", mirada)


# Va hacia "meta" por el camino (rodeando paredes y muebles), frenando al llegar
func ir_a(meta: Vector2, rapidez: float) -> void:
	var falta := global_position.distance_to(meta)
	if falta <= 2.0:
		velocity = Vector2.ZERO
		return
	agente.target_position = meta
	var siguiente := agente.get_next_path_position()
	if agente.is_navigation_finished() or siguiente.distance_to(global_position) < 1.0:
		siguiente = meta   # ya está en el último tramo (o el camino aún no está listo): derecho
	velocity = global_position.direction_to(siguiente) * minf(rapidez, falta * 6.0)
	move_and_slide()


# En la horda: ¿está ya en su sitio delante de la puerta? (la cerradura no avanza mientras va de camino)
func en_su_sitio() -> bool:
	return global_position.distance_to(sitio_forzar) < 16.0


# En la horda: a su sitio delante de la puerta, y ahí trastea de espaldas (o tumbado, si ha caído)
func forzar() -> void:
	if caido:
		tumbar()
		return
	ir_a(sitio_forzar, 220.0)
	animar("andar" if velocity.length() > 20.0 else "reposo", mira_forzar)


# Herida (escolta.gd): va detrás de Johnny, despacio y cojeando (o tumbada, si ha caído)
func cojear() -> void:
	if caido:
		tumbar()
		return
	var hacia := global_position.direction_to(johnny.global_position)
	ir_a(johnny.global_position - hacia * 60.0, Escolta.VELOCIDAD)
	if velocity.length() > 20.0:
		# la cojera: a cada paso se hunde un poco y se ladea
		var paso := sin(tiempo * 7.0)
		cuerpo.position.y = absf(paso) * 2.5
		cuerpo.rotation = paso * 0.08
		animar("andar", velocity)
	else:
		animar("reposo", johnny.global_position - global_position)


func habilidad(delta: float) -> void:
	var h: Dictionary = def.habilidad
	hab_t -= delta
	if h.tipo == "curar":
		if hab_t <= 0.0:
			hab_t = h.cada
			if sprite and johnny.vivo and johnny.vida < johnny.vida_tope():
				# con hoja: el gesto de la jeringa mirando a Johnny, y cura cuando llega el pinchazo (dibujar_hoja)
				animar("reposo", johnny.global_position - global_position)
				empezar_accion()
				accion_cura = h.cura
			else:
				curar(h.cura)
		return
	if h.tipo == "charcos":
		return   # lo suyo no se usa: se nota en los charcos (johnny.gd)
	var blanco := zombi_cercano()
	if h.tipo == "golpear" or h.tipo == "aturdir":
		if blanco:
			var hacia := blanco.global_position - global_position
			animar("reposo", hacia)
			if hab_t <= 0.0 and hacia.length() < h.alcance + blanco.radio:
				hab_t = h.cada
				if h.tipo == "golpear":
					martillazo(blanco, hacia)
				else:
					descarga(blanco)
		return
	if blanco:
		var hacia := blanco.global_position - global_position
		animar("reposo", hacia)
		if hab_t <= 0.0 and rafaga == 0:
			rafaga = h.rafaga
			rafaga_t = 0.0
			hab_t = h.cada
			if sprite:
				# con hoja: saca el arma, y la primera bala sale cuando llega el fogonazo
				empezar_accion()
				rafaga_t = HOJAS[def.id].fogonazo
	if rafaga > 0:
		rafaga_t -= delta
		if rafaga_t <= 0.0:
			if blanco:
				disparar(blanco)
			rafaga -= 1
			rafaga_t = h.get("hueco", 0.0)


# El zombi despierto más cercano que se ve (sin un muro en medio ni la niebla por encima)
func zombi_cercano() -> Node2D:
	var mejor: Node2D = null
	var cerca := ALCANCE
	for z in get_tree().get_nodes_in_group("zombis"):
		if z.get("dormido") or z.get("estado") == "muerto" or not z.visible:
			continue
		var d := global_position.distance_to(z.global_position)
		if d >= cerca:
			continue
		var rayo := PhysicsRayQueryParameters2D.create(global_position, z.global_position, 1)
		if get_world_2d().direct_space_state.intersect_ray(rayo).is_empty():
			cerca = d
			mejor = z
	return mejor


func disparar(blanco: Node2D) -> void:
	var hacia := global_position.direction_to(blanco.global_position).rotated(randf_range(-0.04, 0.04))
	var bala := BALA.instantiate()
	bala.velocidad = hacia * 620.0
	bala.dano = def.habilidad.dano
	bala.radio = 4.0
	bala.vida = 520.0 / 620.0
	get_parent().add_child(bala)
	Sonido.tocar("disparo_aliado")
	animar("reposo", hacia)
	var boca: Vector2
	if persona:
		persona.retroceso = 1.0
		# sale de la boca del arma (en su mano)
		boca = global_position + Vector2(cos(hacia.angle()) * 13, 3 + sin(hacia.angle()) * 9) 			+ hacia * (34.0 if def.get("arma", "") == "rifle" else 24.0) * persona.s
	else:
		# con hoja: la boca del arma del dibujo (en píxeles desde los pies, x2 para pasar a unidades; los pies van
		# 16 por debajo del centro), como en johnny.gd
		var b: Vector2 = HOJAS[def.id].boca[direccion] * 2.0
		boca = global_position + Vector2(b.x, 16.0 + b.y)
	# la bala de verdad va a ras de suelo y se dibuja a la altura de la boca, bajando enseguida (bala.gd)
	var alt := 13.0 if persona else 50.0
	bala.altura = alt
	bala.global_position = boca + Vector2(0, alt)
	Luz.destello(self, boca, 100.0, 0.07)


# El ferretero: un martillazo al zombi que tiene encima (la mano baja de golpe: persona.gd, con el retroceso)
func martillazo(z: Node2D, hacia: Vector2) -> void:
	z.recibir_golpe(def.habilidad.dano, hacia.normalized() * 160.0)
	persona.retroceso = 1.0   # (el ferretero se dibuja con formas)
	Sonido.tocar("barrido")
	Particulas.anillo(z, z.global_position, 22.0, Color("#ff9a3c"), 0.2)


# El técnico: una descarga que deja quieto un momento al zombi (sin hacerle daño); el rayo se dibuja encima
func descarga(z: Node2D) -> void:
	if "aturdido" in z:
		z.aturdido = maxf(z.aturdido, def.habilidad.segundos)
	rayo_t = 0.25
	rayo_a = z.global_position + Vector2(0, -24)
	Sonido.tocar("calambre")
	for i in 5:
		Particulas.soltar(z, rayo_a, Vector2.from_angle(randf() * TAU) * randf_range(60.0, 140.0), Color("#bff4ff"), 3.0, 0.25)


# ¿Va con Johnny alguien que deja a medias los charcos (la farmacéutica)? Lo pregunta johnny.gd al pisar uno
static func charcos_a_medias(arbol: SceneTree) -> float:
	for a in arbol.get_nodes_in_group("aliados"):
		if a.modo == "equipo" and a.def.habilidad.tipo == "charcos":
			return a.def.habilidad.parte
	return 1.0


# La médica: cura a Johnny (si le hace falta) con un anillo verde
func curar(cuanto: int) -> void:
	if not johnny.vivo or johnny.vida >= johnny.vida_tope():
		return
	johnny.curar(cuanto)
	Sonido.tocar("curar")
	cura_t = 0.45
	partida.numero(johnny.position, "+%d" % cuanto, Tema.VERDE)
	Particulas.anillo(johnny, johnny.global_position, 40.0, Tema.VERDE, 0.4)


# El piso se ha quedado limpio (la médica cura un poco más)
func al_limpiar() -> void:
	if def.habilidad.has("al_limpiar"):
		curar(def.habilidad.al_limpiar)


# Le alcanza un zarpazo (solo pasa en la horda y en la escolta: es cuando los zombis van a por él)
func recibir_dano(cantidad: int) -> void:
	if inv_t > 0.0 or caido:
		return
	vida -= cantidad
	Sonido.tocar("dano")
	inv_t = 0.5
	golpe_t = 0.15
	partida.numero(position, "-%d" % cantidad, Tema.ROJO)
	if vida <= 0:
		vida = 0
		caido = true
		remove_from_group("presa")
	herido.emit(caido)


func levantarse() -> void:
	caido = false
	Sonido.tocar("curar")
	vida = VIDA / 2
	inv_t = 1.5
	levantar = 0.0
	add_to_group("presa")


# ¿Va este zombi a por él en vez de a por Johnny? (presaDe del JS: si le pilla más cerca, o si Johnny se ha
# alejado demasiado de él)
func presa_de(z: Node2D, jugador: Node2D, lejos: float) -> bool:
	if not (forzando or herida) or caido:
		return false
	var dp := z.global_position.distance_to(jugador.global_position)
	var da := z.global_position.distance_to(global_position)
	return da < dp * 0.8 or jugador.global_position.distance_to(global_position) > lejos


func decir(texto: String) -> void:
	dicho = texto
	dicho_t = 0.0


func rumbo(v: Vector2) -> String:
	return RUMBOS[wrapi(roundi(v.angle() / (TAU / 8.0)), 0, 8)]


# Hacia dónde mira (y apunta el arma). "que" ("andar" o "reposo") ya lo saca el dibujo de lo rápido que va
func animar(_que: String, hacia: Vector2) -> void:
	if hacia.length() > 0.1:
		mirada = hacia.normalized()
		direccion = rumbo(hacia)
	if persona:
		persona.mira = mirada
		persona.apunte = mirada.angle()


# Tumbado en el suelo (ha caído en la horda o en la escolta): la Persona se gira −90°; la hoja tiene su postura de
# caído, que solo está dibujada mirando abajo (dibujar_hoja)
func tumbar() -> void:
	velocity = Vector2.ZERO
	mirada = Vector2.DOWN
	direccion = "s"
	if persona:
		persona.rotation = -PI / 2.0
		persona.position = Vector2(0, 6)
		persona.mira = Vector2.DOWN


# Con hoja: empieza lo suyo (sacar y disparar el arma, o la jeringa) en la dirección en que mira
func empezar_accion() -> void:
	accion_t = 0.0
	sprite.speed_scale = 1.0
	poner_animacion("ataque_" + direccion, true)


# Con hoja: elige la animación (caído, lo suyo, andar o reposo) en la dirección en que mira, y el blanco del golpe
func dibujar_hoja(delta: float, rapidez: float) -> void:
	sprite.material.set_shader_parameter("destello", 0.85 if golpe_t > 0.0 else 0.0)
	if caido:
		poner_animacion("caer_s")   # se desploma y se queda tumbado (no se repite)
		return
	if accion_t >= 0.0:
		accion_t += delta
		if accion_cura > 0 and accion_t >= HOJAS[def.id].fogonazo:
			curar(accion_cura)   # el pinchazo de la médica
			accion_cura = 0
		poner_animacion("ataque_" + direccion)
		if sprite.is_playing():
			return
		accion_t = -1.0   # ha acabado: vuelve a lo de siempre
	if rapidez > 20.0:
		poner_animacion("andar_" + direccion)
		sprite.speed_scale = ritmo_andar(rapidez)
	else:
		poner_animacion("reposo_" + direccion)
		sprite.speed_scale = 1.0


# El paso va según lo que avanza de verdad, como Johnny (johnny.gd, PASO): más despacio al arrancar y al frenar
func ritmo_andar(rapidez: float) -> float:
	var fotogramas := sprite.sprite_frames.get_frame_count(sprite.animation)
	var fps := sprite.sprite_frames.get_animation_speed(sprite.animation)
	return (rapidez / 140.0 * fotogramas) / fps


# Pone "andar_se", "ataque_n"... Si solo cambia la dirección, sigue por el mismo fotograma (como zombi.gd).
# "otra_vez" la vuelve a empezar aunque ya estuviera puesta
func poner_animacion(nombre: String, otra_vez := false) -> void:
	if not sprite.sprite_frames.has_animation(nombre):
		nombre = "reposo_" + direccion
	if sprite.animation == nombre and not otra_vez:
		return
	var mismo_estado := sprite.animation.get_slice("_", 0) == nombre.get_slice("_", 0)
	var fotograma := sprite.frame
	var avance := sprite.frame_progress
	sprite.play(nombre)
	if otra_vez:
		sprite.frame = 0
	elif mismo_estado:
		sprite.set_frame_and_progress(fotograma % sprite.sprite_frames.get_frame_count(nombre), avance)


# Por encima de todo: el rayo de la curación, su vida en la horda, el círculo para levantarlo, el bocadillo y
# su nombre
func dibujar_encima() -> void:
	var letra := Tema.FUENTE
	if cura_t > 0.0:
		var a := minf(1.0, cura_t / 0.2)
		encima.draw_line(Vector2(0, -10), johnny.global_position - global_position + Vector2(0, -10),
			Color(Tema.VERDE, 0.5 * a), 8.0)
	if rayo_t > 0.0:
		# la descarga: un zigzag de su aparato al zombi, que cambia cada poco
		var desde := Vector2(0, -6)
		var hasta := rayo_a - global_position
		var pts := PackedVector2Array([desde])
		var lado := (hasta - desde).orthogonal().normalized()
		for i in range(1, 6):
			pts.append(desde.lerp(hasta, i / 6.0) + lado * randf_range(-9.0, 9.0))
		pts.append(hasta)
		encima.draw_polyline(pts, LINEA, 6.0)
		encima.draw_polyline(pts, Color("#bff4ff"), 3.0)
	# con hoja mide lo que Johnny (el doble que el dibujo con formas): la vida y el bocadillo van más arriba
	var alto := -64.0 if persona else -104.0
	if forzando or herida:
		var barra := Rect2(-22, alto + 14, 44, 5)
		encima.draw_rect(barra.grow(2), LINEA)
		encima.draw_rect(barra, Color("#3a1d24"))
		var color := Color.WHITE if golpe_t > 0.0 else Tema.VERDE if vida > VIDA * 0.35 else Tema.ROJO
		encima.draw_rect(Rect2(barra.position, Vector2(barra.size.x * vida / VIDA, barra.size.y)), color)
		if caido:
			encima.draw_arc(Vector2.ZERO, 60.0, 0.0, TAU, 48, Color(Tema.AMARILLO, 0.35 + sin(tiempo * 8.0) * 0.2), 3.0)
			if levantar > 0.0:
				encima.draw_arc(Vector2.ZERO, 60.0, -PI / 2.0, -PI / 2.0 + levantar * TAU, 48, Tema.AMARILLO, 6.0)
			texto(letra, "Quédate a su lado para levantarlo", Vector2(0, 86), 16, Tema.AMARILLO)
	# el bocadillo: lo que acaba de decir o, si está esperando, su frase de siempre
	var frase := ""
	var alfa := 1.0
	var color_frase := Color("#2b2233")
	if dicho_t < 3.2:
		frase = dicho
		alfa = clampf((3.2 - dicho_t) / 0.4, 0.0, 1.0)
	elif modo == "encerrado":
		frase = "¡Socorro!" if asustado else "¡Llévame contigo!"
		color_frase = Tema.ROJO if asustado else Color("#2f9e44")
	elif modo == "vecino" and partida.supervivientes.vecino_cerca() == self:
		frase = "¿Te acompaño?"   # solo el que está más cerca de Johnny (si no, se pisan los bocadillos)
		color_frase = Color("#2f9e44")
	if frase != "":
		var y := alto - absf(sin(tiempo * 3.0)) * 4.0 * float(modo != "equipo")
		var ancho := letra.get_string_size(frase, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 22.0
		var caja := Rect2(-ancho / 2.0, y - 14, ancho, 28)
		encima.draw_rect(caja.grow(3), Color(LINEA, alfa))
		encima.draw_rect(caja, Color(PAPEL, alfa))
		encima.draw_colored_polygon(PackedVector2Array([Vector2(-6, y + 14), Vector2(0, y + 22), Vector2(6, y + 14)]),
			Color(PAPEL, alfa))
		encima.draw_string(letra, Vector2(-ancho / 2.0, y + 6), frase, HORIZONTAL_ALIGNMENT_CENTER, ancho, 16,
			Color(color_frase, alfa))
	if modo != "equipo":
		# (en la sala, el ferretero lo lleva más abajo: está detrás de su mostrador)
		texto(letra, def.nombre, Vector2(0, def.get("nombre_vecino", 42.0) if modo == "vecino" else 42.0), 16, Color.WHITE)


func texto(letra: Font, cual: String, donde: Vector2, tamano: int, color: Color) -> void:
	encima.draw_string_outline(letra, donde + Vector2(-200, 0), cual, HORIZONTAL_ALIGNMENT_CENTER, 400, tamano, 4, LINEA)
	encima.draw_string(letra, donde + Vector2(-200, 0), cual, HORIZONTAL_ALIGNMENT_CENTER, 400, tamano, color)
