# El ratón durante la partida (lo pone partida.gd):
#   - Jugando en el modo asistido no hace falta (Johnny apunta solo): se esconde, para que no tape lo que pasa. Solo
#     sale (la mirilla) mientras se apunta un lanzable con el ratón (manteniendo E o el clic derecho: lanzables.gd).
#   - Jugando en el modo de apuntar libre se apunta con él: en vez de la flecha, una mirilla de pixel art.
#   - Con un menú abierto (la pausa, el inventario, el ordenador, la tienda...: todos paran el juego) o al acabar la
#     partida, la flecha de siempre, y al cerrarlo vuelve lo de antes.
# La mirilla se dibuja aquí (MIRILLA), con cada píxel del dibujo del tamaño de los del juego (2 × la escala de la
# pantalla, pantalla.gd), y se rehace si cambia la escala. Al salir de la partida, el ratón vuelve a ser el de siempre.
class_name Raton
extends Node

# La mirilla: "#" es blanco, "o" el punto del centro (amarillo); alrededor se le pone un borde oscuro, para que se vea
# sobre el suelo claro y sobre el oscuro
const MIRILLA := [
	"......#......",
	"......#......",
	"......#......",
	"......#......",
	".............",
	".............",
	"####..o..####",
	".............",
	".............",
	"......#......",
	"......#......",
	"......#......",
	"......#......",
]
const BLANCO := Color("#f2f2f2")
const PUNTO := Color("#ffd23f")
const BORDE := Color(0.08, 0.07, 0.09, 0.85)

var johnny: Node2D
var partida: Node
var puesto := ""          # lo que hay puesto ahora: "oculto", "mirilla" o "flecha"
var escala_hecha := 0.0   # la escala de la pantalla con la que se hizo la mirilla


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # (también con el juego parado, para devolver la flecha)


func _process(_delta: float) -> void:
	poner(que_toca())


# Lo que toca ahora: con un menú abierto o la partida acabada, la flecha; jugando, según el modo de atacar
func que_toca() -> String:
	if johnny == null or get_tree().paused or partida.terminada or not johnny.vivo:
		return "flecha"
	if johnny.modo == "asistido" and not (partida.lanzables.apuntando and johnny.con_raton):
		return "oculto"
	return "mirilla"


func poner(que: String) -> void:
	var escala := get_window().content_scale_factor
	if que == puesto and (que != "mirilla" or escala == escala_hecha):
		return
	puesto = que
	if que == "mirilla":
		escala_hecha = escala
		var px := maxi(1, roundi(2.0 * escala))
		Input.set_custom_mouse_cursor(dibujar(px), Input.CURSOR_ARROW, Vector2(7, 7) * px + Vector2(px, px) / 2.0)
	else:
		Input.set_custom_mouse_cursor(null)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if que == "oculto" else Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# La mirilla, con su borde, a "px" píxeles de la pantalla por píxel del dibujo
static func dibujar(px: int) -> ImageTexture:
	var lado: int = MIRILLA.size() + 2   # (un píxel más a cada lado para el borde)
	var img := Image.create(lado * px, lado * px, false, Image.FORMAT_RGBA8)
	for y in lado:
		for x in lado:
			var c := color_en(x - 1, y - 1)
			if c.a == 0.0:
				for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					if color_en(x - 1 + d.x, y - 1 + d.y).a > 0.0:
						c = BORDE
						break
			if c.a > 0.0:
				img.fill_rect(Rect2i(x * px, y * px, px, px), c)
	return ImageTexture.create_from_image(img)


static func color_en(x: int, y: int) -> Color:
	if y < 0 or y >= MIRILLA.size() or x < 0 or x >= MIRILLA[y].length():
		return Color(0, 0, 0, 0)
	match MIRILLA[y][x]:
		"#":
			return BLANCO
		"o":
			return PUNTO
	return Color(0, 0, 0, 0)
