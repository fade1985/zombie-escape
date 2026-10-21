# El gerente: el jefe final del centro comercial, en la azotea. Arturo Salcedo, el que firmó con Velaria el
# «Turno infinito» (historia.gd). Alto como la portera, con su traje roto, la corbata floja y el maletín. Lo común
# con los minijefes (la vida y su barra, enfadarse, llamar a otros, moverse y morir), en minijefe.gd.
#
# Anda despacio hacia Johnny, muy seguro de sí mismo, y hace tres cosas, cada una con su aviso:
#   - Contratos: saca un taco de papeles (unas rayas rojas en el suelo marcan por dónde irán) y los lanza en
#     abanico. Cortan: 10 cada uno. Los paran las paredes y los aparatos de la azotea (contrato.gd).
#   - Maletinazo: si Johnny se le acerca, marca un trozo de suelo (medio segundo) y le da con el maletín: 20 y le
#     aparta de un empujón.
#   - «¡A TRABAJAR!»: si quedan pocos zombis, grita y llegan dos dependientas y un vigilante.
# Enfadado (a media vida): más contratos y más rápidos, y todo más seguido. En la parte 3 del trozo 6
# (docs/CENTRO_COMERCIAL.md), a media vida se inyectará VD-7 y pasará a su forma mutada: ver al_enfadarse().
# Sus animaciones (PixelLab): andar, contratos, maletinazo, a_trabajar (solo de frente) y jeringa (solo de frente,
# para la parte 3). Los papeles salen justo en el fotograma en el que el brazo llega adelante (SUELTA) y el
# maletín hace daño en el del golpe (GOLPE).
extends Minijefe

const VELOCIDAD := 70.0
const AVISO_CONTRATOS := [0.6, 0.45]     # normal y enfadado
const CONTRATOS := [5, 7]                # los del abanico
const ABRE := [0.24, 0.2]                # lo que se separan entre sí, en radianes
const VELOCIDAD_CONTRATO := [330.0, 410.0]
const DANO_CONTRATO := 10
const LARGO_RAYAS := 300.0               # lo largas que se ven en el suelo las rayas del aviso
const AVISO_MALETINAZO := 0.5
const ALCANCE_MALETINAZO := 135.0
const MEDIO_MALETINAZO := 0.9            # medio ángulo del trozo que barre
const DANO_MALETINAZO := 20
const EMPUJE_MALETINAZO := 750.0
const DISTANCIA_MALETINAZO := 165.0      # si Johnny está más cerca que esto, prefiere el maletinazo
const A_TRABAJAR := ["dependienta", "dependienta", "vigilante"]   # los que llegan al grito
const POCOS := 1                         # grita si quedan como mucho estos zombis por ahí
const GRITO_A_TRABAJAR := 1.3            # lo que dura el grito (llegan a la mitad)
# lo que espera a repetir cada ataque (normal y enfadado)
const ESPERAS := {"contratos": [2.6, 1.7], "maletinazo": [1.4, 1.0], "a_trabajar": [15.0, 11.0]}
const PIE := 34.0                        # a qué altura dibuja los pies respecto a su centro
# El fotograma de "contratos" con el brazo adelante (cuando salen los papeles) y el del golpe del maletinazo,
# según hacia dónde mire
const SUELTA := {"s": 5, "se": 5, "e": 5, "ne": 5, "n": 5, "no": 5, "o": 6, "so": 6}
const GOLPE := {"s": 4, "se": 4, "e": 5, "ne": 4, "n": 5, "no": 5, "o": 5, "so": 4}
const DESPUES := 0.45                    # lo que tarda en acabar la animación después de soltar (y en volver a andar)

var espera := {"contratos": 1.2, "maletinazo": 0.8, "a_trabajar": 6.0}


func pensar(delta: float, johnny: Node2D) -> void:
	for k in espera:
		espera[k] -= delta
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	match estado:
		"andar":
			# a por Johnny sin prisa (rodeando los aparatos); de cerca, solo le mira
			if d > DISTANCIA_MALETINAZO * 0.7:
				perseguir(delta, johnny, VELOCIDAD)
			else:
				frenar(delta)
			mirada = marcha.normalized() if marcha.length() > 10.0 else hacia.normalized()
			if t >= dur:
				elegir(johnny, d)
		"aviso_contratos":
			frenar(delta)
			if t >= AVISO_CONTRATOS[fase - 1]:
				cambiar("contratos", {"angulo": datos.angulo})
				lanzar_contratos()
		"aviso_maletinazo":
			frenar(delta)
			if t >= AVISO_MALETINAZO:
				cambiar("maletinazo", {"angulo": datos.angulo})
				maletinazo(johnny)
		"contratos", "maletinazo":
			frenar(delta)
			if t >= DESPUES:
				andar(0.5 if enfadado() else 0.9)
		"a_trabajar":
			frenar(delta)
			mirada = Vector2.DOWN   # (su grito solo está dibujado de frente)
			if t >= GRITO_A_TRABAJAR * 0.5 and not datos.get("hecho", false):
				datos.hecho = true
				llamar_empleados()
			if t >= GRITO_A_TRABAJAR:
				andar(0.4)


func elegir(johnny: Node2D, d: float) -> void:
	var f := fase - 1
	var angulo := (johnny.global_position - global_position).angle()
	if d < DISTANCIA_MALETINAZO and espera.maletinazo <= 0.0:
		espera.maletinazo = ESPERAS.maletinazo[f]
		empezar("aviso_maletinazo", angulo)
		return
	if espera.a_trabajar <= 0.0 and secuaces() <= POCOS:
		espera.a_trabajar = ESPERAS.a_trabajar[f]
		cambiar("a_trabajar")
		gritar("¡A TRABAJAR!", Color("#ffd23f"), 26)
		Sonido.tocar("rugido")
		return
	if espera.contratos <= 0.0 and a_la_vista(johnny):
		espera.contratos = ESPERAS.contratos[f]
		empezar("aviso_contratos", angulo)
		return
	# nada a mano: sigue andando un poco y vuelve a mirar
	andar(0.3)


# Empieza un ataque mirando hacia donde está Johnny (el abanico y el maletinazo van hacia ahí, aunque se mueva)
func empezar(nuevo: String, angulo: float) -> void:
	cambiar(nuevo, {"angulo": angulo})
	mirada = Vector2.from_angle(angulo)


# Los contratos: salen en línea recta, repartidos alrededor de donde apuntó
func lanzar_contratos() -> void:
	var n: int = CONTRATOS[fase - 1]
	for i in n:
		var a: float = datos.angulo + (i - (n - 1) / 2.0) * ABRE[fase - 1]
		var c := Contrato.new()
		c.position = global_position + Vector2.from_angle(a) * (radio + 6.0)
		c.velocidad = Vector2.from_angle(a) * VELOCIDAD_CONTRATO[fase - 1] * randf_range(0.95, 1.05)
		c.dano = DANO_CONTRATO
		get_parent().add_child(c)
	Sonido.tocar("barrido")


# El maletinazo: daña y aparta a Johnny si está dentro del trozo marcado
func maletinazo(johnny: Node2D) -> void:
	Sonido.tocar("porrazo")
	var hacia: Vector2 = johnny.global_position - global_position
	var desvio := absf(angle_difference(hacia.angle(), datos.angulo))
	if hacia.length() - johnny.RADIO <= ALCANCE_MALETINAZO and desvio <= MEDIO_MALETINAZO + 0.15:
		johnny.recibir_dano(DANO_MALETINAZO)
		johnny.empujar(hacia.normalized() * EMPUJE_MALETINAZO)
		Temblor.temblar(6.0)


# «¡A TRABAJAR!»: llegan sus empleados, repartidos a su alrededor (donde se pueda estar: no dentro de un aparato)
func llamar_empleados() -> void:
	for i in A_TRABAJAR.size():
		var a := float(i) / A_TRABAJAR.size() * TAU + randf_range(-0.4, 0.4)
		var donde := global_position + Vector2(cos(a), sin(a) * 0.8) * 130.0
		if not libre(donde):
			donde = global_position + Vector2(cos(a), sin(a) * 0.8) * 75.0
		pide_zombi.emit(A_TRABAJAR[i], donde)


# Si Johnny está a la vista (sin paredes ni aparatos en medio): los contratos van en línea recta
func a_la_vista(johnny: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, johnny.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# Si ahí se puede estar (dentro del mapa de navegación: ni pared, ni aparato, ni fuera de la azotea)
func libre(p: Vector2) -> bool:
	return NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), p).distance_to(p) < 12.0


# A media vida. De momento se enfada como los minijefes; en la parte 3, aquí se pinchará la jeringa de VD-7
# (estado "jeringa", con su animación) y pasará a su forma mutada (gerente-mutado-128)
func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, "¡ESTÁS DESPEDIDO!")


# En la foto de la prueba (--captura): lanzando los contratos hacia Johnny
func foto(johnny: Node2D) -> void:
	empezar("aviso_contratos", (johnny.global_position - global_position).angle())
	t = AVISO_CONTRATOS[0] - 0.02


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	match estado:
		"aviso_contratos":
			preparar("contratos", dir, SUELTA[dir], AVISO_CONTRATOS[fase - 1])
		"contratos":
			soltar("contratos", dir, SUELTA[dir])
		"aviso_maletinazo":
			preparar("maletinazo", dir, GOLPE[dir], AVISO_MALETINAZO)
		"maletinazo":
			soltar("maletinazo", dir, GOLPE[dir])
		"a_trabajar":
			fijar("a_trabajar", "s", avance("a_trabajar_s", t / GRITO_A_TRABAJAR))
		"grito":
			# al enfadarse: el mismo grito, temblando de rabia
			fijar("a_trabajar", "s", avance("a_trabajar_s", minf(t / 0.9, 0.55)))
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)


# Antes de soltar: hasta el fotograma "golpe" (sin llegar) en lo que dura el aviso
func preparar(anim: String, dir: String, golpe: int, aviso: float) -> void:
	fijar(anim, dir, mini(golpe - 1, int(t / aviso * golpe)))


# Y desde el fotograma "golpe" hasta el final, en lo que tarda en volver a andar
func soltar(anim: String, dir: String, golpe: int) -> void:
	var resto := sprite.sprite_frames.get_frame_count(anim + "_" + dir) - golpe
	fijar(anim, dir, golpe + clampi(int(t / DESPUES * resto), 0, maxi(0, resto - 1)))


func morir() -> void:
	super()
	# no tiene animación de muerte (en la parte 3 el que cae es el mutado): cae de lado
	if sprite.sprite_frames.get_frame_count(sprite.animation) == 1:
		create_tween().tween_property(sprite, "rotation", PI / 2.0 * signf(mirada.x + 0.01), 0.4)


# Los avisos, en el suelo (por debajo de él): las rayas de los contratos y el trozo del maletinazo
func _draw() -> void:
	if estado == "muerto":
		return
	var rojo := Color(1, 0.24, 0.35)
	match estado:
		"aviso_contratos":
			var k := minf(1.0, t / AVISO_CONTRATOS[fase - 1])
			var n: int = CONTRATOS[fase - 1]
			draw_set_transform(Vector2(0, 6))
			for i in n:
				var a: float = datos.angulo + (i - (n - 1) / 2.0) * ABRE[fase - 1]
				var desde := Vector2.from_angle(a) * radio
				draw_line(desde, desde + Vector2.from_angle(a) * LARGO_RAYAS * k, Color(rojo, 0.35 + 0.5 * k), 3.0)
		"aviso_maletinazo":
			var k := minf(1.0, t / AVISO_MALETINAZO)
			var puntos := PackedVector2Array([Vector2.ZERO])
			for i in 17:
				var b: float = datos.angulo - MEDIO_MALETINAZO + i / 16.0 * MEDIO_MALETINAZO * 2.0
				puntos.append(Vector2.from_angle(b) * ALCANCE_MALETINAZO)
			draw_set_transform(Vector2(0, 6))
			draw_colored_polygon(puntos, Color(rojo, 0.1 + k * 0.25))
			puntos.append(Vector2.ZERO)
			draw_polyline(puntos, Color(rojo, 0.9), 3.0)
