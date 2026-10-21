# La puerta del baño donde se esconde el superviviente (PuertaBano en src/props.js del JS): tapa el hueco del
# tabique y no deja pasar hasta que se limpia el piso. Mientras está cerrada, tiembla cuando él da golpes desde
# dentro ("golpes", lo pone supervivientes.gd al gritar). "hueco" es la puerta de apt.puertas, en casillas.
# Al abrirse se encoge hacia un lado (gira sobre las bisagras) y deja de chocar.
# La del almacén del ferretero lleva además tablas clavadas por encima ("tablas", las que quedan): las va
# quitando él desde dentro (barricada.gd).
extends StaticBody2D

const CASILLA := 32
const ALTO := 86.0          # lo alto de la hoja vista de frente (casi lo alto de la cara del muro)
const LINEA := Color("#1d1b2c")

var hueco: Dictionary
var de_frente := false      # hueco en un tabique horizontal: la hoja se ve de frente, como los muros
var caja := Rect2()         # el hueco, en unidades del mundo
var abierta := 0.0          # 0 cerrada, 1 abierta del todo
var abriendo := false
var golpes := 0.0           # segundos que le quedan temblando
var tablas := 0             # las tablas que le quedan clavadas (la barricada del ferretero)
var tiempo := 0.0


func montar(datos: Dictionary) -> void:
	hueco = datos
	de_frente = hueco.fondo == 1
	caja = Rect2(hueco.c * CASILLA, hueco.f * CASILLA, hueco.ancho * CASILLA, hueco.fondo * CASILLA)
	# para ordenarla con lo demás: su "y" es el pie del hueco
	position = Vector2(caja.get_center().x, caja.end.y + 1)
	collision_layer = 1
	collision_mask = 0
	add_to_group("obstaculos")   # la navegación no cuenta con pasar por aquí mientras esté cerrada
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = caja.size
	forma.shape = rect
	forma.position = caja.get_center() - position
	add_child(forma)
	# y su sombra: cerrada, la luz tampoco pasa (la de las lámparas ni la linterna de Johnny)
	var sombra := LightOccluder2D.new()
	var huella := OccluderPolygon2D.new()
	var r := Rect2(caja.position - position, caja.size)
	huella.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	sombra.occluder = huella
	add_child(sombra)


# Se abre: deja de chocar y, poco a poco, gira
func abrir() -> void:
	abriendo = true
	remove_from_group("obstaculos")
	for hijo in get_children():
		if hijo is CollisionShape2D:
			hijo.set_deferred("disabled", true)
		elif hijo is LightOccluder2D:
			hijo.queue_free()


func _process(delta: float) -> void:
	tiempo += delta
	golpes = maxf(0.0, golpes - delta)
	if abriendo:
		abierta = minf(1.0, abierta + delta * 2.5)
	queue_redraw()


func _draw() -> void:
	if abierta >= 1.0:
		return
	var k := 1.0 - abierta
	var temblor := sin(tiempo * 70.0) * 2.0 * minf(1.0, golpes / 0.15) if golpes > 0.0 else 0.0
	var r := caja
	r.position -= position
	if de_frente:
		# de frente: del pie del hueco hasta casi lo alto del muro, con dos cuarterones y el pomo
		var abajo := r.end.y
		var arriba := abajo - ALTO
		var x0 := r.position.x + 4 + temblor
		var ancho := (r.size.x - 8) * k
		var hoja := Rect2(x0, arriba, ancho, abajo - arriba)
		draw_rect(hoja, Color("#4a3123"))
		draw_rect(hoja.grow(-3), Color("#6e4b35"))
		draw_rect(hoja, LINEA, false, 2.0)
		if ancho > 20:
			var pw := ancho - 16
			var ph := (abajo - arriba - 26) / 2.0
			draw_rect(Rect2(x0 + 8, arriba + 8, pw, ph), Color("#5a3d2b"))
			draw_rect(Rect2(x0 + 8, arriba + 18 + ph, pw, ph), Color("#5a3d2b"))
			var pomo := Rect2(x0 + ancho - 11, arriba + (abajo - arriba) / 2.0, 5, 5)
			draw_rect(pomo, Color("#c9a227"))
			draw_rect(pomo, LINEA, false, 1.0)
		# la barricada: tablas torcidas de lado a lado, más anchas que la puerta, con un clavo en cada punta
		for i in tablas:
			var y: float = arriba + (abajo - arriba) * [0.18, 0.4, 0.62, 0.84][i]
			tabla(Vector2(r.position.x - 6 + temblor, y - [5, -6, 4, -5][i] / 2.0),
				Vector2(r.end.x + 6 + temblor, y + [5, -6, 4, -5][i] / 2.0))
	else:
		# en un tabique de lado: una hoja de madera vista desde arriba
		var alto := (r.size.y - 4) * k
		var hoja := Rect2(r.get_center().x - 7 + temblor, r.position.y + 2, 14, alto)
		draw_rect(hoja, Color("#6e4b35"))
		draw_rect(hoja, LINEA, false, 2.0)
		if alto > 20:
			draw_rect(Rect2(hoja.position.x + 4, hoja.position.y + alto - 14, 5, 5), Color("#c9a227"))
		for i in tablas:
			var y: float = r.position.y + r.size.y * (i + 1) / (tablas + 1.0)
			tabla(Vector2(hoja.position.x - 10, y - 3), Vector2(hoja.end.x + 10, y + 3))


# Una tabla de la barricada, de "desde" a "hasta" (los centros de sus dos puntas)
func tabla(desde: Vector2, hasta: Vector2) -> void:
	var grueso := Vector2(0, 5)
	var forma := PackedVector2Array([desde - grueso, hasta - grueso, hasta + grueso, desde + grueso])
	draw_colored_polygon(forma, Color("#a0703f"))
	draw_line(desde - grueso + Vector2(0, 2), hasta - grueso + Vector2(0, 2), Color("#c4945c"), 2.0)   # el canto con luz
	forma.append(forma[0])
	draw_polyline(forma, LINEA, 2.0)
	for punta in [desde.lerp(hasta, 0.08), desde.lerp(hasta, 0.92)]:
		draw_rect(Rect2(punta - Vector2(2, 2), Vector2(4, 4)), Color("#c0c4d0"))
		draw_rect(Rect2(punta - Vector2(2, 2), Vector2(4, 4)), LINEA, false, 1.0)
