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

# La pantalla del dibujo (mueble-tv.png, 32 × 42 píxeles, a escala 2 y con el pie abajo en medio), en unidades locales
const PANTALLA := Rect2(-16, -64, 32, 22)

var datos: Dictionary          # sitio.tele: {"estado"}
var pantalla: Polygon2D
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
	pantalla = Polygon2D.new()
	pantalla.polygon = PackedVector2Array([PANTALLA.position + Vector2(4, 0), Vector2(PANTALLA.end.x - 4, PANTALLA.position.y),
		Vector2(PANTALLA.end.x, PANTALLA.position.y + 4), Vector2(PANTALLA.end.x, PANTALLA.end.y - 4),
		Vector2(PANTALLA.end.x - 4, PANTALLA.end.y), Vector2(PANTALLA.position.x + 4, PANTALLA.end.y),
		Vector2(PANTALLA.position.x, PANTALLA.end.y - 4), Vector2(PANTALLA.position.x, PANTALLA.position.y + 4)])
	pantalla.color = Color("#f1f4f7")
	pantalla.material = luz   # (sin luz: una pantalla encendida se ve también a oscuras)
	pantalla.z_index = 1
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
	# la zona de delante, donde se para Johnny: se usa con el clic, como los botiquines (zona_usar.gd)
	zona = ZONA_USAR.new()
	zona.montar(ancho)
	zona.puede = func() -> bool: return datos.estado == "encendida"
	mueble.add_child(zona)
	zona.usar.connect(usar.emit)
	refrescar()


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
