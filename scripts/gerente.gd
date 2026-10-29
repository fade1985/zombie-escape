# El gerente: el jefe final del centro comercial, en la azotea. Arturo Salcedo, el que firmó con Velaria el
# «Turno infinito» (historia.gd). Alto como la portera, con su traje roto, la corbata floja y el maletín. Lo común
# con los minijefes (la vida y su barra, enfadarse, llamar a otros, moverse y morir), en minijefe.gd.
# Su dibujo es de lienzo 128, como el del mutado: la escena lo pone a escala 1,2 en vez de 2 para que antes de
# mutar mida lo que los minijefes, y al mutar (mutar()) crece hasta 2 y se ve bien que se ha hecho más fuerte.
#
# Anda despacio hacia Johnny, muy seguro de sí mismo, y hace tres cosas, cada una con su aviso:
#   - Contratos: saca un taco de papeles (unas rayas rojas en el suelo marcan por dónde irán) y los lanza en
#     abanico. Cortan: 10 cada uno. Los paran las paredes y los aparatos de la azotea (contrato.gd).
#   - Maletinazo: si Johnny se le acerca, marca un trozo de suelo (medio segundo) y le da con el maletín: 20 y le
#     aparta de un empujón.
#   - «¡A TRABAJAR!»: si quedan pocos zombis, grita y llegan dos dependientas y un vigilante.
# A media vida no se enfada como los minijefes: se pincha VD-7 en el cuello para no parar nunca (la jeringa, sin
# que se le pueda hacer daño) y, con un fogonazo, se convierte en el MUTADO: más grande y más rápido, con cuatro
# tentáculos en la espalda. La barra sigue con la vida que tenía. El mutado ya no lanza contratos ni llama a
# nadie (ya no piensa: solo ataca) y hace dos cosas, también con aviso:
#   - Latigazos: le salen tres tentáculos de la espalda, se levantan por encima de la cabeza y se enroscan,
#     mientras en el suelo sale en abanico hacia Johnny el aviso de las cargas (flechas y una X al final); al rato
#     se estiran como látigos por ahí. Se paran en las paredes y los aparatos (el aviso acaba en estrella). Son los
#     del zombi de tentáculos (tentaculo.gd), pero más largos y gruesos, y morados como los suyos.
#   - Embestida: si Johnny está lejos, una franja roja y sale corriendo en línea recta. Si atropella a Johnny le
#     tira; si se estrella contra un aparato o el murete, se queda atontado un rato (el momento de pegarle).
# Antes de mutar no puede caer (aunque le den mucho de golpe, se queda con 1): la mutación siempre llega. Al caer
# el mutado, la partida enseña la página del dosier y trae el helicóptero de Velaria (partida.gd).
# Sus animaciones (PixelLab): andar, contratos, maletinazo, a_trabajar (solo de frente) y jeringa (solo de frente).
# Los papeles salen justo en el fotograma en el que el brazo llega adelante (SUELTA) y el maletín hace daño en el
# del golpe (GOLPE). Las del mutado, en otra hoja (jefe-gerente-mutado): andar, latigazo, embestida y muerte.
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

# La jeringa y el mutado
const MUTADO := preload("res://assets/sprites/jefe-gerente-mutado.tres")
const JERINGA := 2.6                     # lo que tarda en pincharse (los 13 fotogramas de jeringa_s)
const MUTAR := 1.3                       # el cambio: fogonazo, temblor y un rugido, también sin que le hagan daño
const VERDE := Color("#b6ff6a")          # el VD-7 (el líquido de la jeringa)
const RADIO_MUTADO := 46.0
const ARRIBA_MUTADO := 230.0
const OFFSET_MUTADO := Vector2(-80, -157)
const PIE_MUTADO := 34.0
const VELOCIDAD_MUTADO := 110.0
const LATIGAZOS := 3                     # tentáculos a la vez, en abanico
const ABRE_LATIGAZO := 0.42
const LARGO_LATIGAZO := 340.0
const ANCHO_LATIGAZO := 18.0             # medio ancho de cada franja
const AVISO_LATIGAZO := 0.75
const DANO_LATIGAZO := 18
const AVISO_EMBESTIDA := 0.8
const VELOCIDAD_EMBESTIDA := 560.0
const TIEMPO_EMBESTIDA := 1.0
const DANO_EMBESTIDA := 24
const LEJOS_EMBESTIDA := 240.0           # si Johnny está más lejos que esto, prefiere embestir
const ATONTADO := 2.2
const ESPERAS_MUTADO := {"latigazo": 1.5, "embestida": 3.4}
# El fotograma del latigazo en el que los tentáculos llegan abajo (cuando salen los de código)
const LATIGAZO := {"s": 3, "se": 3, "e": 3, "ne": 5, "n": 4, "no": 5, "o": 4, "so": 4}
const MORADO := Color("#8d4f9e")         # los tentáculos (para las chispas al mutar)
# Los tentáculos de los latigazos, pintados con código (tentaculo.gd), iguales que los de su espalda (colores
# sacados píxel a píxel de su hoja): morados por arriba, más claros hacia el lado de la luz, y granates por debajo,
# con una raya oscura entre los dos colores y las ventosas como puntitos claros. Las capas, de la más oscura (todo
# el ancho) a la más clara: color y lo que ocupa (en partes del ancho, contando desde el borde de la luz)
const PALETA := {
	"contorno": Color("#1e1514"),
	"capas": [
		[Color("#4e2e29"), 1.0],
		[Color("#653030"), 0.93],
		[Color("#6b3947"), 0.76],
		[Color("#37252d"), 0.6],
		[Color("#45313f"), 0.55],
		[Color("#523c4d"), 0.48],
		[Color("#5c455b"), 0.4],
		[Color("#6a516c"), 0.3],
		[Color("#7a5f7c"), 0.2],
		[Color("#8a6f91"), 0.08],
	],
	"ventosas": {"punto": Color("#79636a")},
}
const RECOGE := 0.38                     # cuándo acaban de recogerse después del golpe
# De dónde salen: tres puntos de su espalda en cada dirección, medidos en el fotograma 0 de su latigazo (a cada
# latigazo le toca el del lado hacia el que va, así no se cruzan). Van enteros por delante de su dibujo, también
# de frente: salen justo de donde salen los tentáculos de su dibujo, y si la base fuera por detrás, esos la
# cruzarían por encima y el tentáculo parecería partido
const RAICES := {
	"s": [Vector2(-36, -188), Vector2(4, -200), Vector2(44, -188)],
	"se": [Vector2(-36, -188), Vector2(8, -200), Vector2(40, -192)],
	"e": [Vector2(-16, -188), Vector2(-4, -200), Vector2(4, -184)],
	"ne": [Vector2(-32, -180), Vector2(-12, -184), Vector2(-20, -164)],
	"n": [Vector2(-28, -172), Vector2(0, -180), Vector2(28, -172)],
	"no": [Vector2(-12, -176), Vector2(12, -184), Vector2(32, -168)],
	"o": [Vector2(0, -188), Vector2(12, -196), Vector2(8, -176)],
	"so": [Vector2(-4, -196), Vector2(20, -200), Vector2(40, -188)],
}
# Y lo que se mueve el cuerpo en cada fotograma del latigazo (se agacha y se echa hacia delante al lanzarlos), en
# píxeles de su dibujo: medido en su hoja, buscando dónde encaja mejor el cuerpo sin los tentáculos
const MUEVE := {
	"s": [[0, 0], [0, 0], [1, 10], [2, 18], [2, 18], [1, 14], [1, 6], [0, 0], [0, 0]],
	"se": [[0, 0], [-1, -1], [3, 3], [11, 8], [10, 8], [8, 7], [5, 5], [3, 3], [0, 0]],
	"e": [[0, 0], [-2, -1], [-5, -3], [15, 11], [12, 3], [12, 5], [9, 6], [4, 3], [0, 0]],
	"ne": [[0, 0], [0, 0], [1, 1], [3, 3], [6, 5], [6, 5], [3, 3], [1, 1], [0, 0]],
	"n": [[0, 0], [0, 0], [3, 1], [9, 4], [10, 5], [10, 5], [7, 3], [3, 0], [0, 0]],
	"no": [[0, 0], [0, 0], [-4, 3], [-6, 6], [-7, 5], [-8, 6], [-3, 2], [-2, 1], [0, 0]],
	"o": [[0, 0], [0, 0], [0, 0], [-9, 2], [-7, 6], [-9, 2], [-7, 1], [-3, 0], [0, 0]],
	"so": [[0, 0], [0, 0], [0, 0], [-3, 2], [-12, 8], [-11, 8], [-7, 5], [-3, 2], [0, 0]],
}

var espera := {"contratos": 1.2, "maletinazo": 0.8, "a_trabajar": 6.0}
var mutado := false
var espera_mutado := {"latigazo": 0.6, "embestida": 1.8}
var tentaculos := []                     # los de los latigazos (Tentaculo), uno por franja
var delante: Node2D                      # pinta los tentáculos, por delante del cuerpo


func _ready() -> void:
	super()
	for i in LATIGAZOS:
		var tentaculo := Tentaculo.new(PALETA)
		tentaculo.grueso = 10.5
		tentaculo.fino = 3.0
		tentaculo.enroscado = 150.0
		tentaculo.alto = 1.6
		tentaculo.largo = LARGO_LATIGAZO
		tentaculo.ancho = ANCHO_LATIGAZO
		tentaculo.desfase = i * 0.37
		tentaculos.append(tentaculo)
	# Los tentáculos se pintan en "delante", que va después del dibujo y por eso queda encima (el propio gerente
	# pinta siempre por detrás)
	delante = Node2D.new()
	delante.draw.connect(pintar_tentaculos)
	add_child(delante)


func _physics_process(delta: float) -> void:
	super(delta)
	delante.queue_redraw()


# Al empezar los latigazos, cada tentáculo apunta a su franja y mide hasta dónde llega (por si hay una pared o un
# aparato por medio)
func cambiar(nuevo: String, nuevos_datos := {}) -> void:
	super(nuevo, nuevos_datos)
	if nuevo == "aviso_latigazo":
		var angulos := angulos_latigazo()
		for i in LATIGAZOS:
			tentaculos[i].apuntar(self, angulos[i])


func pensar(delta: float, johnny: Node2D) -> void:
	if mutado:
		pensar_mutado(delta, johnny)
		return
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
		"jeringa":
			sin_tocar(delta)
			mirada = Vector2.DOWN   # (la jeringa solo está dibujada de frente)
			if t >= JERINGA * 0.3 and not datos.get("pinchado", false):
				datos.pinchado = true
				Sonido.tocar("jeringa")
			if t >= JERINGA:
				mutar()


# Quieto y sin que le hagan daño (pinchándose y mutando)
func sin_tocar(delta: float) -> void:
	invulnerable = true
	contacto = 0
	frenar(delta)


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
		gritar(Idioma.t("¡A TRABAJAR!"), Color("#ffd23f"), 26)
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
		c.dueno = self
		c.position = global_position + Vector2.from_angle(a) * (radio + 6.0)
		c.velocidad = Vector2.from_angle(a) * VELOCIDAD_CONTRATO[fase - 1] * randf_range(0.95, 1.05)
		c.dano = DANO_CONTRATO
		get_parent().add_child(c)
	Sonido.tocar("barrido")


# El maletinazo: daña y aparta a Johnny si está dentro del trozo marcado (y no hay una pared o un mueble en medio)
func maletinazo(johnny: Node2D) -> void:
	Sonido.tocar("porrazo")
	var hacia: Vector2 = johnny.global_position - global_position
	var desvio := absf(angle_difference(hacia.angle(), datos.angulo))
	if hacia.length() - johnny.RADIO <= ALCANCE_MALETINAZO and desvio <= MEDIO_MALETINAZO + 0.15 \
			and not Aviso.tapado(self, johnny.global_position):
		johnny.recibir_dano(DANO_MALETINAZO, self)
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


# A media vida: en vez de enfadarse como los minijefes, se pincha VD-7. Borra los contratos que vuelan y aparta a
# Johnny (para que vea la jeringa), y luego muta (mutar())
func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	for bala in get_tree().get_nodes_in_group("balas_zombi"):
		bala.queue_free()
	gritar(Idioma.t("¡AQUÍ NO PARA NADIE!"), Color("#ffd23f"), 24)
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() < 240.0:
		johnny.empujar(hacia.normalized() * 800.0)
	cambiar("jeringa")


# Antes de pincharse no puede caer: como mucho se queda con 1 (y a media vida se pincha seguro)
func danar(cantidad: int, _fuerza: Vector2, _de_lleno: bool) -> int:
	return cantidad if mutado else mini(cantidad, vida - 1)


# Con el mordisco del glotón, igual
func morder(cantidad: int) -> void:
	super(cantidad if mutado else mini(cantidad, vida - 1))


# El cambio: otro dibujo (más grande), un fogonazo verde, temblor y un rugido. Se hincha de golpe desde el tamaño
# que tenía (escala 1,2, la de los minijefes) hasta la escala de todos (2)
func mutar() -> void:
	mutado = true
	vapor = false   # (el vapor de enfadado es de los minijefes)
	Bestiario.apuntar("gerente_mutado")   # visto: al bestiario de las Colecciones del ordenador
	set_meta("tipo", "gerente_mutado")    # (y quién es ahora: Bestiario.de)
	cambiar("mutar")
	sprite.sprite_frames = MUTADO
	sprite.offset = OFFSET_MUTADO
	sprite.play("reposo_s")
	radio = RADIO_MUTADO
	arriba = ARRIBA_MUTADO
	dano_contacto = 14
	$Choque.shape = $Choque.shape.duplicate()
	$Choque.shape.radius = radio
	$Sombra.ancho = 124.0
	$Sombra.alto = 34.0
	$Sombra.queue_redraw()
	sprite.modulate = Color(2.2, 2.6, 1.8)
	var tw := create_tween().set_parallel()
	tw.tween_property(sprite, "scale", Vector2(2, 2), 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.6)
	Luz.destello(self, global_position + Vector2(0, -100), 420.0, 0.7, 1.8, VERDE)
	Temblor.temblar(14.0)
	Sonido.tocar("rugido")
	Sonido.tocar("explosion")
	gritar(Idioma.t("¡GRAAAAH!"), VERDE, 30)
	for i in 24:
		Particulas.soltar(self, global_position + Vector2(randf_range(-40, 40), randf_range(-150, 0)),
			Vector2.from_angle(randf() * TAU) * randf_range(60, 160), [VERDE, MORADO, Color("#7a1f1a")].pick_random(), 4, 0.8)


# ── El mutado ──

func pensar_mutado(delta: float, johnny: Node2D) -> void:
	for k in espera_mutado:
		espera_mutado[k] -= delta
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	match estado:
		"mutar":
			sin_tocar(delta)
			mirada = Vector2.DOWN
			if t >= MUTAR:
				andar(0.3)
		"andar":
			if d > 110.0:
				perseguir(delta, johnny, VELOCIDAD_MUTADO)
			else:
				frenar(delta)
			mirada = marcha.normalized() if marcha.length() > 10.0 else hacia.normalized()
			if t >= dur:
				elegir_mutado(johnny, d)
		"aviso_latigazo":
			frenar(delta)
			if t >= AVISO_LATIGAZO:
				cambiar("latigazo", {"angulo": datos.angulo})
				Sonido.tocar("latigazo")
				latigazos(johnny)
		"latigazo":
			frenar(delta)
			if t >= DESPUES:
				andar(0.4)
		"aviso_embestida":
			# encorvado y temblando; la franja roja marca por dónde irá (ya no cambia de idea)
			frenar(delta, 12.0)
			if t >= AVISO_EMBESTIDA:
				cambiar("embestida")
				Sonido.tocar("rugido")
		"embestida":
			match embestir(delta, johnny, VELOCIDAD_EMBESTIDA, DANO_EMBESTIDA, TIEMPO_EMBESTIDA, PIE_MUTADO):
				"pillado":
					cambiar("recuperar", {"dur": 0.6})
				"pared":
					estrellarse()
				"fin":
					marcha *= 0.3
					cambiar("recuperar", {"dur": 0.5})
		"recuperar":
			frenar(delta, 5.0)
			if t >= datos.dur:
				andar(0.5)
		"atontado":
			frenar(delta, 4.0)
			if t >= ATONTADO:
				andar(0.4)


func elegir_mutado(johnny: Node2D, d: float) -> void:
	var angulo := (johnny.global_position - global_position).angle()
	if d > LEJOS_EMBESTIDA and espera_mutado.embestida <= 0.0 and a_la_vista(johnny):
		espera_mutado.embestida = ESPERAS_MUTADO.embestida
		empezar("aviso_embestida", angulo)
		return
	if d < LARGO_LATIGAZO + 20.0 and espera_mutado.latigazo <= 0.0:
		espera_mutado.latigazo = ESPERAS_MUTADO.latigazo
		empezar("aviso_latigazo", angulo)
		return
	andar(0.3)


# Los ángulos de los tres latigazos, alrededor de donde apuntó
func angulos_latigazo() -> Array:
	var lista := []
	for i in LATIGAZOS:
		lista.append(datos.angulo + (i - (LATIGAZOS - 1) / 2.0) * ABRE_LATIGAZO)
	return lista


# ¿Está Johnny dentro de alguna franja, hasta donde llega? (como el zombi de tentáculos)
func latigazos(johnny: Node2D) -> void:
	Temblor.temblar(5.0)
	for tentaculo in tentaculos:
		if tentaculo.golpea(self, johnny):
			johnny.recibir_dano(DANO_LATIGAZO, self)
			return


# En la foto de la prueba (--captura): lanzando los contratos hacia Johnny
func foto(johnny: Node2D) -> void:
	if mutado:
		empezar("aviso_latigazo", (johnny.global_position - global_position).angle())
		t = AVISO_LATIGAZO - 0.05
		return
	empezar("aviso_contratos", (johnny.global_position - global_position).angle())
	t = AVISO_CONTRATOS[0] - 0.02


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	if mutado:
		animar_mutado(dir)
		return
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
		"jeringa":
			# los 13 fotogramas en lo que dura; del 10 en adelante (tira la jeringa y se encorva), temblando
			var f := avance("jeringa_s", t / JERINGA)
			fijar("jeringa", "s", f)
			if f >= 10:
				sprite.position.x = sin(tiempo * 60.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)


func animar_mutado(dir: String) -> void:
	sprite.position = Vector2(0, PIE_MUTADO)
	match estado:
		"mutar":
			poner("reposo_s")
			sprite.position.x = sin(tiempo * 70.0) * 3.0 * (1.0 - t / MUTAR)
		"aviso_latigazo":
			preparar("latigazo", dir, LATIGAZO[dir], AVISO_LATIGAZO)
		"latigazo":
			soltar("latigazo", dir, LATIGAZO[dir])
		"aviso_embestida":
			# el primer paso de la carrera, quieto y temblando de rabia
			fijar("embestida", dir, 0)
			sprite.position.x = sin(tiempo * 55.0) * 2.0
		"embestida":
			poner("embestida_" + dir, 1.2)
		"recuperar", "atontado":
			poner("reposo_" + dir)
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD_MUTADO, 0.5, 1.5))
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
	# (el gerente sin mutar no tiene animación de muerte: si cayera así, de lado; el mutado cae con la suya)
	if sprite.sprite_frames.get_frame_count(sprite.animation) == 1:
		create_tween().tween_property(sprite, "rotation", PI / 2.0 * signf(mirada.x + 0.01), 0.4)


# Los avisos, en el suelo (por debajo de él): las rayas de los contratos, el trozo del maletinazo y, del mutado,
# los latigazos y la embestida
func _draw() -> void:
	if estado == "muerto":
		return
	match estado:
		"aviso_contratos":
			# una barra fina por donde irá cada contrato, que se llena hacia fuera (aviso.gd)
			var k := minf(1.0, t / AVISO_CONTRATOS[fase - 1])
			var n: int = CONTRATOS[fase - 1]
			for i in n:
				var a: float = datos.angulo + (i - (n - 1) / 2.0) * ABRE[fase - 1]
				Aviso.barra(self, Vector2(0, 6), a, radio, radio + LARGO_RAYAS, 3.0, k, tiempo, i)
		"aviso_maletinazo":
			Aviso.golpe(self, Vector2(0, 6), datos.angulo, MEDIO_MALETINAZO, ALCANCE_MALETINAZO,
				minf(1.0, t / AVISO_MALETINAZO), tiempo)
		"aviso_latigazo":
			# los tres latigazos avisan como las cargas de los jefes: flechas que se encienden hacia fuera y, al
			# final, una X (o una estrella, si se paran en una pared o un aparato)
			for i in LATIGAZOS:
				tentaculos[i].avisar(self, Vector2(0, 6), minf(1.0, t / AVISO_LATIGAZO), tiempo, i)
		"aviso_embestida":
			franja(VELOCIDAD_EMBESTIDA * TIEMPO_EMBESTIDA, minf(1.0, t / AVISO_EMBESTIDA))


# Los tentáculos de los latigazos, enteros por delante del dibujo (ver RAICES)
func pintar_tentaculos() -> void:
	if not mutado:
		return
	for i in LATIGAZOS:
		var puntos := puntos_tentaculo(i)
		if not puntos.is_empty():
			tentaculos[i].pintar(delante, puntos, 0, Tentaculo.PUNTOS)


# Los puntos del tentáculo "i" en este momento, de la base a la punta (ninguno si no está dando latigazos). Sale del
# punto de su espalda del lado hacia el que va (si va justo abajo o justo arriba, se enrosca hacia ese lado, por
# fuera del cuerpo), y se mueve con el cuerpo en cada fotograma
func puntos_tentaculo(i: int) -> PackedVector2Array:
	if estado != "aviso_latigazo" and (estado != "latigazo" or t >= RECOGE):
		return PackedVector2Array()
	var dir := direccion()
	var abre := Vector2.from_angle(datos.angulo - PI / 2)   # hacia donde se abre el primero
	var raices: Array = RAICES[dir].duplicate()
	raices.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.dot(abre) > b.dot(abre))
	var lado := -1.0 if raices[i].x < 0.0 else 1.0
	var mueve: Array = MUEVE[dir][mini(sprite.frame, 8)] if sprite.animation.begins_with("latigazo") else [0, 0]
	var raiz: Vector2 = raices[i] + Vector2(mueve[0], mueve[1]) * 2.0 + Vector2(sprite.position.x, 0)
	if estado == "aviso_latigazo":
		return tentaculos[i].levantado(raiz, minf(1.0, t / AVISO_LATIGAZO), t, lado)
	return tentaculos[i].latigo(raiz, Vector2(0, 6), t, RECOGE, lado)
	draw_set_transform(Vector2.ZERO)
