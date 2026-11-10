# Una explosión (la del zombi explosivo y la granada). Al aparecer hace daño a Johnny y a los
# zombis que pillen dentro del círculo (¡reacciones en cadena!), enseña la bola de fuego y se va.
# Como en el juego (explode en src/game-ataques.js). Ninguna pasa las paredes ("paredes"): ni la de las granadas de
# Johnny, ni la del zombi explosivo, ni la de Mezcla explosiva (estas dos, desde el 10 nov).
# Lo que se ve es la explosión de pixelfx (tools/pixelfx/explosion.js, exportada con exportar_explosion.mjs): un destello
# blanco y unos anillos, el fuego que se vuelve humo y sube, chispas, tizones, piedras y la marca del suelo. Dos hojas:
# el color y el brillo (que se suma, con mezcla "añadir"). Las pequeñas (el racimo de las Épicas), a la mitad de tamaño.
extends Node2D

const EMPUJE := 170.0 * 2.2   # las explosiones lanzan a los zombis más lejos que un golpe
const PARADA := 0.06          # segundos que el juego se queda casi parado si pilla a alguien
# La hoja de pixelfx (las medidas, copiadas de lo que escribe el exportador)
const HOJAS := [preload("res://assets/sprites/explosion.png"), preload("res://assets/sprites/explosion-brillo.png")]
const ORIGEN := Vector2(180, 202)   # el punto de la explosión (en el suelo), en cada fotograma
const FOTOGRAMAS := 75
const COLUMNAS := 16
const FILAS := 5
const FPS := 30.0
const APAGA := 0.4                  # los últimos segundos, se apaga (lo que queda es humo que casi no se ve)
const FRIO := Color(0.55, 0.85, 1.0)  # la luz de la helada
const RADIO_ESCARCHA := 120.0       # el radio para el que está hecho el estallido de escarcha (el de la congeladora)
const PEQUENA := 70.0               # con menos radio, la explosión se ve a la mitad de tamaño

var radio := 90.0
var dano := 30
var dano_zombis := -1     # si es distinto (la granada con Puntería les hace más a ellos): -1 = el mismo
var origen: Node = null       # quien ha reventado (no se hace daño a sí mismo)
var a_johnny := true          # si le hace daño a Johnny (la de Mezcla explosiva, no: zombi.gd)
var de := "granada"           # de quién es, para el cartel de derrota (johnny.gd, golpe_de): la del dinamitero lleva
                              # "explosivo"; las demás que le dan a Johnny son de su granada
var helada := false           # la de la congeladora (M51): en vez de la bola de fuego, el estallido de escarcha de pixelfx
                              # (EfectoSuelo, "escarcha"), con luz fría y sonido de cristal
var paredes := true           # si la paran las paredes, las puertas cerradas y las barricadas (los muebles, no). Desde
                              # el 10 nov, todas (antes, la del dinamitero y la de Mezcla explosiva las pasaban)
var tiempo := 0.0
var capas: Array[Sprite2D] = []


func _ready() -> void:
	Sonido.tocar("explosion")
	Temblor.temblar(14.0)
	var johnny := get_tree().get_first_node_in_group("jugador")
	var pilla := false   # si pilla a alguien, el juego se para un instante (Temblor.parar)
	if a_johnny and johnny and johnny.vivo and global_position.distance_to(johnny.global_position) <= radio + johnny.RADIO \
			and not tapado(johnny.global_position):
		johnny.recibir_dano(dano, null, de)
		pilla = true
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi == origen:
			continue
		var hacia: Vector2 = zombi.global_position - global_position
		if hacia.length() <= radio + zombi.radio and not tapado(zombi.global_position):
			pilla = true
			var cuanto := roundi((dano if dano_zombis < 0 else dano_zombis) * Lanzables.a_jefe(zombi))   # (a los jefes, la mitad)
			if zombi is Minijefe:   # la explosión les da de lleno (el escudo del antidisturbios no la para)
				zombi.recibir_golpe(cuanto, hacia.normalized() * EMPUJE, true)
			else:
				zombi.recibir_golpe(cuanto, hacia.normalized() * EMPUJE)
	if pilla:
		Temblor.parar(PARADA)
	if helada:
		Sonido.tocar("cristal")
		Luz.destello(self, global_position, maxf(200.0, radio * 2.5), 0.6, 1.0, FRIO)
		EfectoSuelo.soltar(get_parent(), "escarcha", global_position, radio / RADIO_ESCARCHA)
		queue_free()
		return
	# La explosión ilumina toda la zona, y el resplandor del fuego tarda en apagarse
	Luz.destello(self, global_position, maxf(200.0, radio * 2.5), 0.4)
	Luz.destello(self, global_position, maxf(160.0, radio * 1.8), 1.2, 0.5)
	# La explosión de pixelfx: el color y, encima, el brillo sumado
	var escala := 2.0 if radio >= PEQUENA else 1.0
	for i in 2:
		var capa := Sprite2D.new()
		capa.texture = HOJAS[i]
		capa.hframes = COLUMNAS
		capa.vframes = FILAS
		capa.centered = false
		capa.offset = -ORIGEN
		capa.scale = Vector2(escala, escala)
		capa.material = Recorte.material("aire", i == 1)   # (sin pintarse encima de las paredes; la de brillo, sumada)
		add_child(capa)
		capas.append(capa)


# Si a esta explosión la para una pared de camino a ese sitio
func tapado(donde: Vector2) -> bool:
	var mapa := get_tree().get_first_node_in_group("mapa") if paredes else null
	return mapa != null and not mapa.muro_entre(global_position, donde).is_empty()


func _process(delta: float) -> void:
	tiempo += delta
	var cuadro := int(tiempo * FPS)
	if cuadro >= FOTOGRAMAS:
		queue_free()
		return
	for capa in capas:
		capa.frame = cuadro
	modulate.a = clampf((FOTOGRAMAS / FPS - tiempo) / APAGA, 0.0, 1.0)
