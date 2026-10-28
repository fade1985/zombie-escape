# Un «!» amarillo que bota encima de algo que tiene novedades (L11 de PENDIENTES.md): la mesa del ordenador cuando hay
# noticias nuevas, un logro por cobrar o algo nuevo en Colecciones, y la taquilla cuando hay una skin sin ver. Se
# esconde solo cuando ya no hay nada nuevo. "condicion" es lo que decide si se ve (sin parámetros, devuelve si hay algo
# nuevo) y se mira al montarlo y luego cada segundo: así no hay que avisarle desde cada sitio donde cambia algo. Se
# dibuja sin que le afecte la luz, para que se vea también a oscuras.
extends Node2D

const AMARILLO := Color("#ffd23f")
const TINTA := Color("#1b1712")
const CADA := 1.0      # cada cuánto mira si hay novedades (leer el guardado no es gratis)
const BOTE := 5.0      # lo que sube y baja, en unidades

var condicion: Callable
var activa := false
var t := 0.0
var espera := 0.0
var base := 0.0        # la "y" en que se puso, que es donde está en medio del bote


func _ready() -> void:
	z_index = 20
	var luz := CanvasItemMaterial.new()
	luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = luz
	base = position.y
	refrescar()


func refrescar() -> void:
	activa = condicion.is_valid() and condicion.call()
	visible = activa


func _process(delta: float) -> void:
	espera -= delta
	if espera <= 0.0:
		espera = CADA
		refrescar()
	if activa:
		t += delta
		position.y = base + sin(t * 5.0) * BOTE


# El globo: un círculo amarillo con borde, su rabito hacia abajo (hacia lo que avisa) y el «!» (en múltiplos de 2
# unidades, como un píxel del dibujo)
func _draw() -> void:
	draw_circle(Vector2.ZERO, 18.0, TINTA)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 12), Vector2(8, 12), Vector2(0, 26)]), TINTA)
	draw_circle(Vector2.ZERO, 14.0, AMARILLO)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, 12), Vector2(5, 12), Vector2(0, 21)]), AMARILLO)
	draw_rect(Rect2(-3, -10, 6, 12), TINTA)
	draw_rect(Rect2(-3, 5, 6, 5), TINTA)
