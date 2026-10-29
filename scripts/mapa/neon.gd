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
