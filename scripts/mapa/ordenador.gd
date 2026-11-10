# La mesa del ordenador de la sala de mantenimiento (Ordenador en src/props.js del JS): pegada a la pared de
# arriba, con el monitor que brilla un poco para que se vea que se puede usar. Delante tiene una zona
# invisible (zona_usar.gd): con Johnny en ella y el clic (atacar), avisa con "usar" y la
# partida enciende la pantalla de ConserjeOS (ui/ordenador.gd). El dibujo sale de
# PixelLab, al estilo de los muebles, como el banco y el baúl (tools/ordenador_mantenimiento.py).
extends StaticBody2D

signal usar

const ZONA_USAR := preload("res://scripts/mapa/zona_usar.gd")

const EXCLAMACION := preload("res://scripts/mapa/exclamacion.gd")   # el «!» de encima cuando hay novedades
const ANCHO := 92.0   # lo que ocupa en el suelo: de la pared a las patas de delante (como en el JS)
const HONDO := 44.0

var zona: Area2D      # la de delante (zona_usar.gd)
var brillo: PointLight2D
var marca: Node2D    # el «!» de encima (mapa.marcas_sala lo mira)
var t := 0.0


# "x": su centro; "arriba": donde acaba el muro de arriba
func montar(x: float, arriba: float) -> void:
	name = "Ordenador"   # no-tr
	add_to_group("obstaculos")
	position = Vector2(x, arriba + HONDO)   # el pie de la mesa, para ordenarse con los personajes
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/mesa-ordenador.png")
	sprite.scale = Vector2(2, 2)
	sprite.centered = false
	var tam := sprite.texture.get_size()
	sprite.offset = Vector2(-floorf(tam.x / 2.0), -tam.y)
	add_child(sprite)
	# un «!» que bota encima mientras haya algo nuevo en ConserjeOS (L11) o no se haya visto su tutorial (Tutoriales.marca):
	# no se quita hasta que no queda nada nuevo dentro
	marca = EXCLAMACION.new()
	marca.name = "Exclamacion"
	marca.condicion = func() -> bool: return Tutoriales.marca("ordenador") or not novedades(Guardado.cargar()).is_empty()
	marca.position = Vector2(0, -tam.y * 2.0 - 30.0)
	add_child(marca)

	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ANCHO, HONDO)
	forma.shape = rect
	forma.position = Vector2(0, -HONDO / 2.0)
	add_child(forma)

	# el resplandor azulado del monitor, sobre la pantalla
	brillo = PointLight2D.new()
	brillo.texture = load("res://escenas/luces/luz_suave.tres")
	brillo.texture_scale = 0.35
	brillo.color = Color("#78dcff")
	brillo.position = Vector2(-2, -76)
	add_child(brillo)

	# la zona de delante, donde se para Johnny para usarlo: se abre con el clic (zona_usar.gd)
	zona = ZONA_USAR.new()
	zona.montar(ANCHO)
	add_child(zona)
	zona.usar.connect(usar.emit)


func _process(delta: float) -> void:
	t += delta
	brillo.energy = 0.7 + sin(t * 2.5) * 0.2


# El tutorial de cada programa de ConserjeOS (Tutoriales.LISTA): sale al abrirlo la primera vez (ui/ordenador.gd, abrir)
const TUTORIAL_DE := {"puntos": "talentos", "armas": "tienda", "logros": "logros", "dosier": "dosier",
	"colecciones": "colecciones", "videos": "videos"}


# Qué programas de ConserjeOS tienen algo nuevo para el jugador, de un guardado: los que tienen su tutorial sin ver
# (TUTORIAL_DE; mientras los tutoriales estén encendidos: Tutoriales.marca), «colecciones» (un enemigo nuevo), «logros»
# (alguno conseguido y sin cobrar) y «armas» (el regalo de bienvenida de la tienda, la pistola gratis, sin coger:
# tienda_armas.gd). Lo usan el «!» de la mesa y los iconos del escritorio (ui/ordenador.gd); con alguno, el de la mesa
# sigue y, en la primera partida, no se sale de la sala de mantenimiento (partida.falta_sala). Sin "con_tutoriales",
# solo lo de verdad nuevo (el rótulo amarillo del icono, «¡NUEVO!» o «¡COBRAR!», sale solo con eso)
static func novedades(s: Dictionary, con_tutoriales := true) -> Array:
	var lista := []
	for programa in TUTORIAL_DE:
		if con_tutoriales and Tutoriales.marca(TUTORIAL_DE[programa]):
			lista.append(programa)
	if s.colecciones_nuevo and not "colecciones" in lista:
		lista.append("colecciones")
	if Logros.LISTA.any(func(l): return Logros.estado(s, l.id) == "conseguido") and not "logros" in lista:
		lista.append("logros")
	if not s.regalo_cogido and not "armas" in lista:
		lista.append("armas")
	return lista
