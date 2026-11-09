# Un «!» amarillo que bota encima de algo que tiene novedades (L11 de PENDIENTES.md): la mesa del ordenador cuando hay
# noticias nuevas, un logro por cobrar o algo nuevo en Colecciones, y la taquilla cuando hay una skin sin ver. Se
# esconde solo cuando ya no hay nada nuevo. "condicion" es lo que decide si se ve (sin parámetros, devuelve si hay algo
# nuevo) y se mira al montarlo y luego cada segundo: así no hay que avisarle desde cada sitio donde cambia algo. Se
# dibuja sin que le afecte la luz, para que se vea también a oscuras.
extends Node2D

const DIBUJO := preload("res://assets/sprites/exclamacion.png")   # de GPT (M3; tools/muebles_gpt.py)
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
	# el «!», con su pie donde acababa el rabito del globo de antes (así no hay que mover dónde se pone)
	var dibujo := Sprite2D.new()
	dibujo.texture = DIBUJO
	dibujo.scale = Vector2(2, 2)
	dibujo.position = Vector2(0, 26 - DIBUJO.get_height())
	dibujo.use_parent_material = true   # (sin luz, como el nodo)
	add_child(dibujo)
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

