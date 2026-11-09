# La sombra bajo los pies de un personaje: una elipse pixel art (con píxeles de 2 unidades, como los dibujos),
# en tres capas que se suman: casi negra en el centro y cada vez más suave hacia fuera. Va como primer hijo del
# personaje, así se dibuja por debajo de él. Al morir se apaga poco a poco (apagar()).
class_name Sombra
extends Node2D

const COLOR := Color(0.024, 0.016, 0.055)   # el mismo morado casi negro que la sombra de los aliados (persona.gd)
const PIXEL := 2.0

@export var ancho := 36.0   # en unidades del juego (2 por píxel del dibujo)
@export var alto := 12.0


# Las tres capas ya sumadas en una imagen, una por cada forma de sombra (los zombis de un tipo comparten la suya).
# Antes eran unos 24 rectángulos por personaje, y con una horda de 150 zombis costaba casi 1 ms cada fotograma;
# así es un solo dibujo y se ve igual, píxel a píxel
static var imagenes := {}

const CAPAS := [[1.0, 0.2], [0.76, 0.22], [0.5, 0.24]]   # de fuera hacia dentro: [tamaño, opacidad]


func _ready() -> void:
	z_index = -1


func _draw() -> void:
	var filas := []   # [Rect2, opacidad] de cada fila de cada capa
	for capa in CAPAS:
		filas.append_array(_elipse(ancho * capa[0], alto * capa[0], capa[1]))
	if filas.is_empty():
		return
	if not imagenes.has(filas):
		imagenes[filas] = _imagen(filas)
	var hecha: Array = imagenes[filas]
	draw_texture(hecha[0], hecha[1])


# Una elipse hecha de filas de píxeles: cada fila tan ancha como la elipse a esa altura, redondeada al píxel
func _elipse(w: float, h: float, opacidad: float) -> Array:
	var lista := []
	var filas := maxi(2, roundi(h / PIXEL))
	var mitad := filas / 2.0
	for i in filas:
		var y := (i + 0.5 - mitad) / mitad   # de -1 a 1
		var medio := roundi(w / PIXEL / 2.0 * sqrt(1.0 - y * y)) * PIXEL
		if medio > 0:
			lista.append([Rect2(-medio, (i - mitad) * PIXEL, medio * 2.0, PIXEL), opacidad])
	return lista


# Pinta las filas en una imagen (un punto por unidad del juego) como se sumarían dibujadas una encima de otra:
# donde se pisan, lo que deja pasar cada una se multiplica. Devuelve [textura, esquina de arriba a la izquierda]
static func _imagen(filas: Array) -> Array:
	var caja: Rect2 = filas[0][0]
	for f in filas:
		caja = caja.merge(f[0])
	var img := Image.create(int(caja.size.x), int(caja.size.y), false, Image.FORMAT_RGBA8)
	var pasa := PackedFloat32Array()   # lo que deja pasar del suelo cada punto (1, todo)
	pasa.resize(int(caja.size.x * caja.size.y))
	pasa.fill(1.0)
	for f in filas:
		var r: Rect2 = f[0]
		for y in range(int(r.position.y - caja.position.y), int(r.end.y - caja.position.y)):
			for x in range(int(r.position.x - caja.position.x), int(r.end.x - caja.position.x)):
				pasa[y * int(caja.size.x) + x] *= 1.0 - f[1]
	for y in int(caja.size.y):
		for x in int(caja.size.x):
			img.set_pixel(x, y, Color(COLOR, 1.0 - pasa[y * int(caja.size.x) + x]))
	return [ImageTexture.create_from_image(img), caja.position]


# Al morir: el cuerpo queda tirado en el suelo y la sombra de "estar de pie" se desvanece
func apagar(tiempo := 0.4) -> void:
	create_tween().tween_property(self, "modulate:a", 0.0, tiempo)
