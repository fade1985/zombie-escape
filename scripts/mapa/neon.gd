# El letrero de neón de una tienda del centro comercial, encima de su puerta en la pared de arriba del pasillo
# (lo pone mapa.gd; el texto, ya traducido, de Tienda.neon, y el color, de Tienda.TIPOS). Está roto, como todo: alguna
# letra está fundida (se ve el tubo apagado) y el resto parpadea y falla a trompicones, con la misma cuenta que los apliques (lampara.gd).
# Lleva su luz de color, que tiembla con él, y se ve aunque el pasillo esté a oscuras (no le afecta la penumbra).
extends Node2D

const LAMPARA := preload("res://escenas/luces/lampara.tscn")
const TAMANO := 32           # la fuente pixel art a 32: cada píxel de la letra, 2 unidades (como los dibujos)
const ALTO := 104.0          # a qué altura va, por encima del pie del muro (justo encima de la puerta)
const TUBO := Color(0.3, 0.28, 0.33)   # una letra fundida: el tubo de cristal apagado

var texto := "TIENDA"   # no-tr (lo cambia siempre mapa.gd, ya traducido: Tienda.neon)
var color := Color("#ff4fa0")
var semilla := 0.5
var iluminado := false       # en Torre Velaria: un rótulo de departamento iluminado por detrás (placa blanca y fría), no un neón
var fundidas := {}           # las letras que no se encienden (su posición en el texto)
var luz: Node2D
var tiempo := 0.0
var fuente: Font


func _ready() -> void:
	fuente = Tema.crear().default_font
	tiempo = semilla * 10.0
	# una o dos letras fundidas (nunca un espacio), elegidas con la semilla para que no cambien al volver
	var letras := []
	for i in texto.length():
		if texto[i] != " ":
			letras.append(i)
	var cuantas := 1 + int(semilla * 10.0) % 2
	for k in cuantas:
		fundidas[letras[int(fposmod(semilla * 7.31 + k * 0.37, 1.0) * letras.size())]] = true
	# lo que no se ilumina con la penumbra: el neón luce por sí mismo
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = propio
	# su luz de color en el suelo del pasillo, parpadeando (una lámpara sin bombilla ni polvo)
	luz = LAMPARA.instantiate()
	luz.parpadea = true
	luz.semilla = semilla
	luz.radio = 170.0
	luz.alto = ALTO
	luz.suelo = Vector2(0, 50)
	luz.fuerza = 0.8
	add_child(luz)
	luz.get_node("Bombilla").visible = false
	for nombre in ["LuzSuelo", "LuzCosas"]:   # no-tr (nombres de nodo)
		luz.get_node(nombre).color = color
	luz.get_node("Polvo").visible = false


func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()


func _draw() -> void:
	var b: float = luz.brillo(tiempo) if luz else 1.0
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO).x
	var x := -roundf(ancho / 2.0 / 2.0) * 2.0
	var y := -ALTO
	if iluminado:
		dibujar_rotulo(x, y, ancho, b)
		return
	# el soporte: una chapa oscura detrás de las letras, atornillada a la pared
	draw_rect(Rect2(x - 8, y - TAMANO + 2, ancho + 16, TAMANO + 6), Color(0.08, 0.07, 0.1, 0.85))
	for i in texto.length():
		var letra := texto[i]
		var w := fuente.get_string_size(letra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO).x
		if letra != " ":
			if fundidas.has(i):
				draw_string(fuente, Vector2(x, y), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, TUBO)
			else:
				# cada letra falla un poco por su cuenta además del parpadeo de todo el letrero
				var propio := b * (0.75 + 0.25 * sin(tiempo * (9.0 + i * 1.7) + i * 2.3))
				var c := TUBO.lerp(color, clampf(propio, 0.0, 1.0))
				# el halo: la letra un poco más gorda y transparente por detrás
				var halo := Color(color.r, color.g, color.b, 0.28 * propio)
				draw_string_outline(fuente, Vector2(x, y), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, 6, halo)
				draw_string(fuente, Vector2(x, y), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, c)
		x += w


# El rótulo de un departamento de la torre: una placa blanca y fría iluminada por detrás, con el nombre en gris azulado oscuro
# en un marco de aluminio. Casi no parpadea (la luz de la torre falla poco), pero a veces se apaga un instante
func dibujar_rotulo(x: float, y: float, ancho: float, b: float) -> void:
	var luz_placa := clampf(0.55 + 0.45 * b, 0.0, 1.0)
	var placa := Color(0.84, 0.92, 1.0).lerp(color, 0.25) * Color(luz_placa, luz_placa, luz_placa, 1.0)
	var marco := Color(0.22, 0.25, 0.3)
	var rect := Rect2(x - 12, y - TAMANO + 0, ancho + 24, TAMANO + 10)
	# el halo frío alrededor
	draw_rect(rect.grow(6), Color(0.7, 0.85, 1.0, 0.12 * luz_placa))
	draw_rect(rect.grow(2), marco)
	draw_rect(rect, placa)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), Color(1, 1, 1, 0.5 * luz_placa))   # el brillo de arriba
	draw_string(fuente, Vector2(x, y + 2), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, Color(0.13, 0.17, 0.25))
