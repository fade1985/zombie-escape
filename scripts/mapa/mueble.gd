# Un mueble del mapa, montado a partir de sus datos (muebles.gd): su dibujo, su choque (para Johnny, los zombis
# y las balas) y su "Sombra" para la fase de luz. Se ve "en tres cuartos", como los personajes: el dibujo se
# apoya en el borde de abajo del hueco que ocupa en el suelo y sube lo que mida de alto.
#
# En las paredes de los lados lleva su dibujo de lado (hecho para la pared izquierda: en la derecha, en espejo).
# Variantes: mueble-<tipo> es la de siempre y mueble-<tipo>-b, -c... las demás. Cada sitio elige una por tipo con
# su número "surtido": todas las neveras de una casa son iguales, pero la de al lado puede tener otra.
extends StaticBody2D

const LETRAS := "bcdefghijklmnopqrstuvwxyz"

var datos: Dictionary
var zona := -1


# El dibujo que le toca: [ruta del png, en espejo]
static func dibujo(tipo: String, lado: String, surtido: int) -> Array:
	var v := variante(tipo, surtido)
	if lado == "izquierda" or lado == "derecha":
		for id in ["mueble-%s%s-lado" % [tipo, v], "mueble-%s-lado" % tipo]:
			if existe(id):
				return [ruta(id), lado == "derecha"]
	return [ruta("mueble-%s%s" % [tipo, v]), false]


static func ruta(id: String) -> String:
	return "res://assets/sprites/%s.png" % id


static func existe(id: String) -> bool:
	return ResourceLoader.exists(ruta(id))


# Cuántas variantes tiene un tipo (la de siempre cuenta) y cuál le toca a este sitio: "" o "-b", "-c"...
static func variante(tipo: String, surtido: int) -> String:
	var n := 1
	while n <= LETRAS.length() and existe("mueble-%s-%s" % [tipo, LETRAS[n - 1]]):
		n += 1
	if n == 1:
		return ""
	var i := absi(hash(str(surtido) + tipo)) % n
	return "" if i == 0 else "-" + LETRAS[i - 1]


func montar(m: Dictionary, surtido: int) -> void:
	datos = m
	zona = m.zona
	name = m.tipo.capitalize()
	add_to_group("obstaculos")
	add_to_group("muebles")
	# el "pie" del mueble es el borde de abajo de su hueco: así se ordena bien con los personajes
	position = Vector2(m.x, m.y + m.h / 2.0)
	var queda: Array = dibujo(m.tipo, m.lado, surtido)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load(queda[0])
	sprite.scale = Vector2(2, 2)   # cada píxel del dibujo, 2 unidades (como los personajes)
	sprite.centered = false
	sprite.flip_h = queda[1] != m.get("espejo", false)   # (con "espejo", el dibujo del revés: muebles.gd, colocados)
	var t := sprite.texture.get_size()
	sprite.offset = Vector2(-floorf(t.x / 2.0), -t.y)
	add_child(sprite)

	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(m.w, m.h)
	forma.shape = rect
	forma.position = Vector2(0, -m.h / 2.0)
	add_child(forma)

	var sombra := LightOccluder2D.new()
	sombra.name = "Sombra"
	var huella := OccluderPolygon2D.new()
	huella.polygon = PackedVector2Array([Vector2(-m.w / 2.0, -m.h), Vector2(m.w / 2.0, -m.h), Vector2(m.w / 2.0, 0),
		Vector2(-m.w / 2.0, 0)])
	sombra.occluder = huella
	add_child(sombra)
