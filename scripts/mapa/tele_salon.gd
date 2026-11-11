# La tele de un salón que enseña las noticias de Canal 8 (M91). Cada planta tiene una: planta.gd marca un mueble "tv" de
# un salón al azar (sitio.tele = {"estado"}) y mapa.gd le cuelga este nodo. Estados:
#   "apagada"    todavía no se ha limpiado el apartamento (o ya no quedan noticias): es un mueble más
#   "encendida"  pantalla en blanco, con su «!» encima: con Johnny delante y el clic (zona_usar.gd) sale la noticia
#   "vista"      ya se ha visto la noticia: apagada para siempre
# Va de hijo del mueble (mueble.gd), así que el contorno amarillo de la zona se saca de su dibujo.
extends Node2D

signal usar

const ZONA_USAR := preload("res://scripts/mapa/zona_usar.gd")
const EXCLAMACION := preload("res://scripts/mapa/exclamacion.gd")
const POLIGONO := preload("res://scripts/poligono.gd")   # (no un Polygon2D: ver poligono.gd)

# La pantalla del dibujo (mueble-tv.png, 32 × 42 píxeles, a escala 2 y con el pie abajo en medio), en unidades locales
const PANTALLA := Rect2(-16, -64, 32, 22)

var datos: Dictionary          # sitio.tele: {"estado"}
var pantalla: Node2D
var brillo: PointLight2D
var marca: Node2D
var zona: Area2D
var t := 0.0


# "mueble": el mueble "tv" (mueble.gd), donde se cuelga la zona de uso (así el contorno sale de su dibujo); "ancho": lo que
# ocupa en el suelo
func montar(d: Dictionary, mueble: Node2D, ancho: float) -> void:
	datos = d
	name = "TeleSalon"   # no-tr
	var luz := CanvasItemMaterial.new()
	luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	pantalla = POLIGONO.new()
	pantalla.polygon = PackedVector2Array([PANTALLA.position + Vector2(4, 0), Vector2(PANTALLA.end.x - 4, PANTALLA.position.y),
		Vector2(PANTALLA.end.x, PANTALLA.position.y + 4), Vector2(PANTALLA.end.x, PANTALLA.end.y - 4),
		Vector2(PANTALLA.end.x - 4, PANTALLA.end.y), Vector2(PANTALLA.position.x + 4, PANTALLA.end.y),
		Vector2(PANTALLA.position.x, PANTALLA.end.y - 4), Vector2(PANTALLA.position.x, PANTALLA.position.y + 4)])
	pantalla.color = Color("#f1f4f7")
	pantalla.material = luz   # (sin luz: una pantalla encendida se ve también a oscuras)
	add_child(pantalla)
	brillo = PointLight2D.new()
	brillo.texture = load("res://escenas/luces/luz_suave.tres")
	brillo.texture_scale = 0.4
	brillo.color = Color("#dbe8ff")
	brillo.position = Vector2(0, -52)
	add_child(brillo)
	# el «!» que bota encima mientras está encendida y sin ver
	marca = EXCLAMACION.new()
	marca.name = "Exclamacion"   # no-tr
	marca.condicion = func() -> bool: return datos.estado == "encendida"
	marca.position = Vector2(0, -84.0 - 30.0)
	add_child(marca)
	# la zona de alrededor (delante, detrás y a los lados: una tele contra la pared de abajo se ve de espaldas y Johnny
	# llega por detrás), donde se para Johnny: se usa con el clic, como los botiquines (zona_usar.gd). Solo desde la
	# misma habitación que la tele: que no se encienda a través de la pared
	var fondo: float = mueble.datos.get("h", 40.0)
	zona = ZONA_USAR.new()
	zona.montar_rect(Rect2(-(ancho + 20) / 2.0, -fondo - 34.0, ancho + 20, fondo + 34.0 + 38.0))
	zona.puede = func() -> bool: return datos.estado == "encendida" and en_su_sala(zona.johnny)
	mueble.add_child(zona)
	zona.usar.connect(usar.emit)
	refrescar()


# Si Johnny está en la misma habitación que la tele (mapa.gd, sala_de), para no usarla desde el otro lado de la pared
func en_su_sala(quien: Node2D) -> bool:
	if quien == null:
		return true   # (sin Johnny en la zona no se usa igualmente; así el contorno con el ratón sale como antes)
	var mapa := get_parent()
	while mapa and not mapa.has_method("sala_de"):
		mapa = mapa.get_parent()
	if mapa == null:
		return true
	var casilla := func(p: Vector2) -> Vector2i: return Vector2i((mapa.to_local(p) / 32.0).floor())   # (32: mapa.CASILLA)
	# la tele, por el medio de su hueco en el suelo (su pie está en el borde de abajo)
	var t: Vector2i = casilla.call(get_parent().global_position - Vector2(0, get_parent().datos.get("h", 40.0) / 2.0))
	var j: Vector2i = casilla.call(quien.global_position)
	if mapa.es_muro(j.x, j.y):
		return false
	return mapa.sala_de(t.x, t.y) == mapa.sala_de(j.x, j.y)


# Enciende la pantalla en blanco (al limpiar el apartamento)
func encender() -> void:
	datos.estado = "encendida"
	refrescar()
	marca.refrescar()


# Ya vista: se apaga y se queda así
func apagar() -> void:
	datos.estado = "vista"
	refrescar()
	marca.refrescar()


func refrescar() -> void:
	var encendida: bool = datos.estado == "encendida"
	pantalla.visible = encendida
	brillo.visible = encendida


func _process(delta: float) -> void:
	t += delta
	if datos.estado == "encendida":
		# parpadea un poco, como una tele sin señal
		pantalla.color = Color("#f1f4f7").darkened(0.06 * (0.5 + 0.5 * sin(t * 23.0) * sin(t * 7.0)))
		brillo.energy = 0.7 + sin(t * 9.0) * 0.08
