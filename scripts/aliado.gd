# Un superviviente (SurvivorNPC y Ally del JS: src/props.js y src/entities.js). Según "modo":
#   - "encerrado": en el baño de su apartamento, temblando, hasta que Johnny limpia el piso y se le arrima.
#   - "equipo": sigue a Johnny dando vueltas a su alrededor y usa lo suyo: el policía y el militar disparan al
#     zombi más cercano; la médica cura a Johnny cada pocos segundos y al limpiar cada piso.
#     En la horda (supervivientes.gd) se queda delante de la puerta forzando la cerradura ("forzando"): tiene
#     vida, los zombis van a por él y, si cae, se queda tumbado hasta que Johnny lo levanta.
#   - "vecino": rescatado en otra partida, espera en la sala de mantenimiento a que Johnny se le arrime.
# El dibujo es provisional: el de Johnny teñido de su color (el JS los pinta con formas, sin hoja de PixelLab).
class_name Aliado
extends CharacterBody2D

signal herido(cae: bool)   # en la horda: le han dado (y si se ha caído)

const RADIO := 14.0        # para los zombis: a qué distancia le alcanzan
const BALA := preload("res://escenas/armas/bala.tscn")
const RUMBOS := ["e", "se", "s", "so", "o", "no", "n", "ne"]
const LINEA := Color("#1d1b2c")
const PAPEL := Color("#fff8ea")
const ALCANCE := 400.0     # a qué distancia busca zombis para disparar
const VIDA := 100          # la vida en la horda (HORDA.vida en el JS)

var def: Dictionary
var modo := "equipo"
var johnny: Node2D
var partida: Node
var idx := 0               # su puesto en el equipo (para repartirse alrededor de Johnny)
var es_vecino := false     # viene de la sala de mantenimiento (y "casa" es su sitio allí)
var casa := Vector2.ZERO
var armado := true         # vecino: hay que apartarse un poco antes de que vuelva a contar el arrimarse
var asustado := true       # encerrado: mientras quedan zombis en el piso
var tiempo := 0.0
var direccion := "s"
var hab_t := 0.0           # lo que falta para usar lo suyo
var rafaga := 0            # balas que quedan de la ráfaga
var rafaga_t := 0.0
var cura_t := 0.0          # el destello de la curación
var forzando := false
var sitio_forzar := Vector2.ZERO
var mira_forzar := Vector2.UP
var vida := VIDA
var caido := false
var inv_t := 0.0
var golpe_t := 0.0
var levantar := 0.0        # de 0 a 1: lo que lleva Johnny levantándole (lo pone supervivientes.gd)
var dicho := ""            # lo que acaba de decir (bocadillo) y desde cuándo
var dicho_t := 99.0
var vivo: bool:
	get: return not caido

var sprite: AnimatedSprite2D
var agente: NavigationAgent2D   # le busca el camino rodeando paredes y muebles (como a los zombis)
var encima: Node2D         # la vida, el bocadillo y su nombre, por encima de todo


func preparar(datos: Dictionary, en_modo: String) -> void:
	def = datos
	modo = en_modo
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
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = load("res://assets/sprites/conserje-48-%s.tres" % def.hoja)
	sprite.position = Vector2(0, 16)
	sprite.scale = Vector2(2, 2)
	sprite.centered = false
	sprite.offset = Vector2(-48, -72)
	sprite.modulate = Color.WHITE.lerp(def.color, 0.55)
	add_child(sprite)
	sprite.play("reposo_s")
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
	dicho_t += delta
	sprite.rotation = 0.0
	sprite.position = Vector2(0, 16)
	match modo:
		"encerrado":
			# tiembla de miedo mientras quedan zombis; luego mira a Johnny
			if asustado:
				sprite.position.x = sin(tiempo * 40.0) * 1.2
				animar("reposo", Vector2.DOWN)
			else:
				animar("reposo", johnny.global_position - global_position)
		"vecino":
			animar("reposo", johnny.global_position - global_position)
		"equipo":
			if forzando:
				forzar()
			else:
				seguir()
				if johnny.vivo:
					habilidad(delta)
	sprite.modulate = Color.WHITE if golpe_t > 0.0 else Color.WHITE.lerp(def.color, 0.55)
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
		animar("reposo", Vector2.from_angle(TAU / 8.0 * RUMBOS.find(direccion)))


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
		velocity = Vector2.ZERO
		sprite.rotation = -PI / 2.0
		sprite.position = Vector2(-20, 6)
		sprite.play("reposo_s")
		return
	ir_a(sitio_forzar, 220.0)
	animar("andar" if velocity.length() > 20.0 else "reposo", mira_forzar)


func habilidad(delta: float) -> void:
	var h: Dictionary = def.habilidad
	hab_t -= delta
	if h.tipo == "curar":
		if hab_t <= 0.0:
			hab_t = h.cada
			curar(h.cura)
		return
	var blanco := zombi_cercano()
	if blanco:
		var hacia := blanco.global_position - global_position
		direccion = rumbo(hacia)
		sprite.play("reposo_" + direccion)
		if hab_t <= 0.0 and rafaga == 0:
			rafaga = h.rafaga
			rafaga_t = 0.0
			hab_t = h.cada
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
	var salida := global_position + Vector2(0, 16) + hacia * 18.0
	bala.global_position = salida
	Luz.destello(self, salida - Vector2(0, 50), 100.0, 0.07)


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


# Le alcanza un zarpazo (solo pasa en la horda: es cuando los zombis van a por él)
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
	if not forzando or caido:
		return false
	var dp := z.global_position.distance_to(jugador.global_position)
	var da := z.global_position.distance_to(global_position)
	return da < dp * 0.8 or jugador.global_position.distance_to(global_position) > lejos


func decir(texto: String) -> void:
	dicho = texto
	dicho_t = 0.0


func rumbo(v: Vector2) -> String:
	return RUMBOS[wrapi(roundi(v.angle() / (TAU / 8.0)), 0, 8)]


func animar(que: String, hacia: Vector2) -> void:
	if hacia.length() > 0.1:
		direccion = rumbo(hacia)
	sprite.play(que + "_" + direccion)


# Por encima de todo: el rayo de la curación, su vida en la horda, el círculo para levantarlo, el bocadillo y
# su nombre
func dibujar_encima() -> void:
	var letra := Tema.FUENTE
	if cura_t > 0.0:
		var a := minf(1.0, cura_t / 0.2)
		encima.draw_line(Vector2(0, -10), johnny.global_position - global_position + Vector2(0, -10),
			Color(Tema.VERDE, 0.5 * a), 8.0)
	if forzando:
		var barra := Rect2(-22, -104, 44, 5)
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
	elif modo == "vecino":
		frase = "¿Te acompaño?"
		color_frase = Color("#2f9e44")
	if frase != "":
		var y := -132.0 - absf(sin(tiempo * 3.0)) * 4.0 * float(modo != "equipo")
		var ancho := letra.get_string_size(frase, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 22.0
		var caja := Rect2(-ancho / 2.0, y - 14, ancho, 28)
		encima.draw_rect(caja.grow(3), Color(LINEA, alfa))
		encima.draw_rect(caja, Color(PAPEL, alfa))
		encima.draw_colored_polygon(PackedVector2Array([Vector2(-6, y + 14), Vector2(0, y + 22), Vector2(6, y + 14)]),
			Color(PAPEL, alfa))
		encima.draw_string(letra, Vector2(-ancho / 2.0, y + 6), frase, HORIZONTAL_ALIGNMENT_CENTER, ancho, 16,
			Color(color_frase, alfa))
	if modo != "equipo":
		texto(letra, def.nombre, Vector2(0, 50), 16, Color.WHITE)


func texto(letra: Font, cual: String, donde: Vector2, tamano: int, color: Color) -> void:
	encima.draw_string_outline(letra, donde + Vector2(-200, 0), cual, HORIZONTAL_ALIGNMENT_CENTER, 400, tamano, 4, LINEA)
	encima.draw_string(letra, donde + Vector2(-200, 0), cual, HORIZONTAL_ALIGNMENT_CENTER, 400, tamano, color)
