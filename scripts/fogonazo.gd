# El fogonazo de un disparo de Johnny (pistola, MP5 y escopeta), hecho con pixelfx (tools/pixelfx/fogonazo.js,
# exportado con tools/pixelfx/exportar_fogonazo.mjs). Cada disparo suelta dos: la llama y el humo. Cada uno con dos
# hojas: el color y el brillo (que se suma, con mezcla "añadir").
#  - La llama viene ya girada en 9 ángulos, de hacia arriba (-90°) a hacia abajo (90°), de 22,5° en 22,5°; hacia la
#    izquierda se le da la vuelta. La pistola tiene 2 formas y la MP5 3, que se van turnando para que la ráfaga no se
#    repita.
#  - El humo, en 5 rumbos (de 45° en 45°) y sin girar, porque siempre sube por la pantalla.
# Se ordena con los personajes como las balas (va en el mismo sitio que ellas): disparando hacia arriba queda detrás
# de Johnny y, hacia los lados o hacia abajo, delante.
# La luz de alrededor no es de aquí: la pone el disparo (Luz.destello). El fogonazo dibujado en las hojas de Johnny
# sigue (se tapa con este).
class_name Fogonazo
extends Node2D

# (las medidas, copiadas de lo que escribe el exportador)
const TIPOS := {
	"pistola-llama": {"hojas": [preload("res://assets/sprites/fogonazo-pistola-llama.png"),
		preload("res://assets/sprites/fogonazo-pistola-llama-brillo.png")],
		"origen": Vector2(13, 46), "fotogramas": 6, "columnas": 6, "filas": 1, "fps": 30, "formas": 2},
	"pistola-humo": {"hojas": [preload("res://assets/sprites/fogonazo-pistola-humo.png"),
		preload("res://assets/sprites/fogonazo-pistola-humo-brillo.png")],
		"origen": Vector2(29, 40), "fotogramas": 23, "columnas": 16, "filas": 2, "fps": 15, "formas": 1},
	"mp5-llama": {"hojas": [preload("res://assets/sprites/fogonazo-mp5-llama.png"),
		preload("res://assets/sprites/fogonazo-mp5-llama-brillo.png")],
		"origen": Vector2(13, 46), "fotogramas": 5, "columnas": 5, "filas": 1, "fps": 30, "formas": 3},
	"mp5-humo": {"hojas": [preload("res://assets/sprites/fogonazo-mp5-humo.png"),
		preload("res://assets/sprites/fogonazo-mp5-humo-brillo.png")],
		"origen": Vector2(6, 27), "fotogramas": 21, "columnas": 16, "filas": 2, "fps": 15, "formas": 1},
	"escopeta-llama": {"hojas": [preload("res://assets/sprites/fogonazo-escopeta-llama.png"),
		preload("res://assets/sprites/fogonazo-escopeta-llama-brillo.png")],
		"origen": Vector2(29, 57), "fotogramas": 9, "columnas": 9, "filas": 1, "fps": 30, "formas": 1},
	"escopeta-humo": {"hojas": [preload("res://assets/sprites/fogonazo-escopeta-humo.png"),
		preload("res://assets/sprites/fogonazo-escopeta-humo-brillo.png")],
		"origen": Vector2(34, 79), "fotogramas": 42, "columnas": 16, "filas": 3, "fps": 15, "formas": 1},
}

var tipo := "pistola-llama"
var variante := 0           # la fila de la hoja: forma × ángulos + ángulo
var capas: Array[Sprite2D] = []
var t := 0.0
var de_calentar := false    # el de precalentar(): casi transparente, unos fotogramas y fuera

static var calentados := {}
static var turno := 0       # la forma de la llama que toca (se van turnando)


# ¿Tiene fogonazo esta arma? (las de fuego con balas: pistola, MP5 y escopeta)
static func tiene(arma: String) -> bool:
	return TIPOS.has(arma + "-llama")


# El disparo: la llama y el humo en la boca del arma ("boca": donde se ve, a la altura del cañón), hacia "angulo".
# "orden": a qué altura (y) se ordena con los personajes
static func soltar(sala: Node, arma: String, boca: Vector2, angulo: float, orden: float) -> void:
	if not tiene(arma):
		return
	# hacia la izquierda, el de la derecha dado la vuelta
	var vuelta := cos(angulo) < 0.0
	var a := wrapf(PI - angulo if vuelta else angulo, -PI, PI)
	a = clampf(a, -PI / 2.0, PI / 2.0)
	var llama: Dictionary = TIPOS[arma + "-llama"]
	turno += 1
	var forma: int = turno % int(llama.formas)
	crear(sala, arma + "-llama", forma * 9 + roundi((a + PI / 2.0) / (PI / 8.0)), boca, orden, vuelta)
	crear(sala, arma + "-humo", roundi((a + PI / 2.0) / (PI / 4.0)), boca, orden, vuelta)


static func crear(sala: Node, cual: String, fila: int, boca: Vector2, orden: float, vuelta: bool) -> Fogonazo:
	var f := Fogonazo.new()
	f.tipo = cual
	f.variante = fila
	f.position = Vector2(roundf(boca.x / 2.0) * 2.0, orden)
	f.scale.x = -1.0 if vuelta else 1.0
	f.set_meta("alto", roundf((boca.y - orden) / 2.0) * 2.0)   # (lo que sube el dibujo desde donde se ordena)
	sala.add_child.call_deferred(f)   # (puede salir en mitad de una consulta de física)
	return f


# La primera vez que se dibuja algo con la mezcla "añadir" del brillo, o una hoja nueva, el juego puede pararse un
# momento (sobre todo en la web). Para que no pase en el primer disparo, al coger el arma se pinta uno casi
# transparente en el centro de la pantalla (fuera de ella no se dibujaría y no serviría)
static func precalentar(sala: Node, arma: String) -> void:
	if calentados.has(arma) or not tiene(arma) or not sala.is_inside_tree():
		return
	var camara := sala.get_viewport().get_camera_2d()
	if camara == null:
		return
	calentados[arma] = true
	for parte in ["-llama", "-humo"]:
		var f := crear(sala, arma + parte, 0, camara.get_screen_center_position(), camara.get_screen_center_position().y, false)
		f.de_calentar = true


func _ready() -> void:
	var datos: Dictionary = TIPOS[tipo]
	var alto: float = get_meta("alto", 0.0)
	for i in 2:
		var capa := Sprite2D.new()
		capa.texture = datos.hojas[i]
		capa.hframes = datos.columnas
		capa.vframes = datos.filas * datos.formas * (9 if tipo.ends_with("-llama") else 5)
		capa.centered = false
		capa.offset = -datos.origen
		capa.position = Vector2(0, alto)
		capa.scale = Vector2(2, 2)
		if i == 1:
			var suma := CanvasItemMaterial.new()
			suma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			capa.material = suma
		add_child(capa)
		capas.append(capa)
	if de_calentar:
		modulate = Color(1, 1, 1, 0.02)   # (del todo transparente, el motor se lo salta y no prepara nada)
	poner(0)


func _process(delta: float) -> void:
	t += delta
	if de_calentar:
		if t > 0.1:
			queue_free()
		return
	var cuadro := int(t * TIPOS[tipo].fps)
	if cuadro >= TIPOS[tipo].fotogramas:
		queue_free()
		return
	poner(cuadro)


func poner(cuadro: int) -> void:
	var datos: Dictionary = TIPOS[tipo]
	var cols: int = datos.columnas
	var fila: int = variante * datos.filas + floori(cuadro / float(cols))
	for capa in capas:
		capa.frame = fila * cols + cuadro % cols
