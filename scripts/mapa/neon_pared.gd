# La tira de luz de neón de una pared (27 nov, el dueño: la tira roja de la sala de juegos de la electrónica, que luzca como un neón
# rojo). Va de hija de la cara del muro (cara_pared.gd) y pinta encima, tramo a tramo y con el mismo dibujo que le toque a cada tramo,
# su capa de luz (pared-<x>-neon.png, de tools/suelos_electronica_gpt.py: el tubo y su resplandor, transparente en lo demás). No le
# afecta la oscuridad (como los letreros de neón, neon.gd): se ve aunque la sala esté a oscuras. Zumba un poco y, de vez en cuando,
# falla un momento, como los neones
extends Node2D

var cara: Node2D
var tiempo := 0.0
var semilla := 0.0
var fallo := 0.0           # lo que le queda al fallo de ahora (apagada)
var proximo_fallo := 0.0   # cuánto falta para el siguiente
var capas := {}            # dibujo de la pared -> su capa de luz (o null si no tiene)


func _ready() -> void:
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = propio
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	semilla = fposmod(cara.position.x * 0.0137 + cara.position.y * 0.0071, 1.0)
	tiempo = semilla * 20.0
	proximo_fallo = 3.0 + semilla * 9.0


func _process(delta: float) -> void:
	tiempo += delta
	proximo_fallo -= delta
	if proximo_fallo <= 0.0:
		fallo = randf_range(0.06, 0.25)
		proximo_fallo = randf_range(4.0, 14.0)
	fallo = maxf(fallo - delta, 0.0)
	# el zumbido: casi siempre encendida, temblando un poco; al fallar, casi apagada
	var b := 0.9 + 0.1 * sin(tiempo * 37.0) * sin(tiempo * 5.3)
	modulate.a = 0.15 if fallo > 0.0 else b
	queue_redraw()


func capa_de(dibujo: Texture2D) -> Texture2D:
	if not capas.has(dibujo):
		var ruta := dibujo.resource_path.replace(".png", "-neon.png")
		capas[dibujo] = load(ruta) if ruta != "" and ResourceLoader.exists(ruta) else null
	return capas[dibujo]


# Lo mismo que pinta la cara (cara_pared._draw y pintar_papel), pero con la capa de luz de cada dibujo
func _draw() -> void:
	if cara.tapa:
		return
	var x0: float = cara.position.x / 2.0
	var w: float = cara.ancho / 2.0
	var visto: float = (cara.alto - cara.desde) / 2.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	if cara.paredes.is_empty():
		pintar(cara.pared, 0.0, w, x0, visto)
		return
	var t := float((cara.paredes[0][0] as Texture2D).get_width())
	for k in range(floori(x0 / t), ceili((x0 + w) / t)):
		var a := maxf(x0, k * t)
		var b := minf(x0 + w, (k + 1) * t)
		if b > a:
			pintar(cara.elegir(cara.paredes, k, int(cara.position.y)), a - x0, b - a, a, visto)


func pintar(dibujo: Texture2D, x: float, w: float, x_mapa: float, visto: float) -> void:
	var capa := capa_de(dibujo)
	if capa == null or dibujo.get_height() * 2.0 < cara.alto:   # (sin capa, o en una pared alargada: nada)
		return
	draw_texture_rect_region(capa, Rect2(x, -cara.alto / 2.0, w, visto), Rect2(x_mapa, 0, w, capa.get_height() * visto * 2.0 / cara.alto))
