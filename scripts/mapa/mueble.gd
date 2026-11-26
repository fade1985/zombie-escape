# Un mueble del mapa, montado a partir de sus datos (muebles.gd): su dibujo, su choque (para Johnny, los zombis
# y las balas) y su "Sombra" para la fase de luz. Se ve "en tres cuartos", como los personajes: el dibujo se
# apoya en el borde de abajo del hueco que ocupa en el suelo y sube lo que mida de alto.
#
# En las paredes de los lados lleva su dibujo de lado (hecho para la pared izquierda: en la derecha, en espejo).
# Variantes: mueble-<tipo> es la de siempre y mueble-<tipo>-b, -c... las demás. Cada sitio elige una por tipo con
# su número "surtido": todas las neveras de una casa son iguales, pero la de al lado puede tener otra.
#
# Los que se abren (Objetos.MUEBLES_CON_PIEZA: el armario, la mesilla... y en el centro y la torre los suyos; 15 y 16 nov) llevan
# además la zona de delante (zona_usar.gd, con su contorno amarillo), como el armarito del baño: avisan con "usar" y la
# partida los abre (abrir_mueble), que a veces sueltan un material. Ya abierto ("abierto" en sus datos, que se quedan en
# la planta) no se vuelve a abrir. Su dibujo no cambia, de momento. La nevera y la encimera de las cocinas
# (Objetos.MUEBLES_CON_COMIDA, M124) se abren igual, pero solo si ya vive alguien en los trasteros: dan su comida favorita.
extends StaticBody2D

signal usar

const LETRAS := "bcdefghijklmnopqrstuvwxyz"
const ZONA_USAR := preload("res://scripts/mapa/zona_usar.gd")
const LUZ := preload("res://scripts/mapa/luz_mueble.gd")

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
	var escala: float = Catalogo.MUEBLES.get(m.tipo, {}).get("escala", 2.0)   # (los de la sala de venta de la tienda de ropa, a 1: el doble de detalle, como la dependienta)
	sprite.scale = Vector2(escala, escala)   # cada píxel del dibujo, 2 unidades (como los personajes)
	sprite.centered = false
	sprite.flip_h = queda[1] != m.get("espejo", false)   # (con "espejo", el dibujo del revés: muebles.gd, colocados)
	var t := sprite.texture.get_size()
	sprite.offset = Vector2(-floorf(t.x / 2.0), -t.y)
	add_child(sprite)
	# (27 nov) si tiene lo que luce aparte (mueble-<tipo>-luz.png: las torres y pantallas de los puestos de juego), encima y sin
	# oscuridad (luz_mueble.gd)
	var capa: String = (queda[0] as String).replace(".png", "-luz.png")
	if ResourceLoader.exists(capa):
		var luz := Sprite2D.new()
		luz.name = "Luz"
		luz.set_script(LUZ)
		luz.texture = load(capa)
		luz.scale = sprite.scale
		luz.centered = false
		luz.flip_h = sprite.flip_h
		luz.offset = sprite.offset
		add_child(luz)

	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var alto: float = m.h
	if m.lado in ["izquierda", "derecha"] and Catalogo.MUEBLES.has(m.tipo):
		alto = minf(alto, Catalogo.MUEBLES[m.tipo].get("choque_lado", alto))   # (lo que mide su dibujo de lado: F23)
	rect.size = Vector2(m.w, alto)
	forma.shape = rect
	forma.position = Vector2(0, -alto / 2.0)
	add_child(forma)

	var sombra := LightOccluder2D.new()
	sombra.name = "Sombra"
	var huella := OccluderPolygon2D.new()
	huella.polygon = PackedVector2Array([Vector2(-m.w / 2.0, -m.h), Vector2(m.w / 2.0, -m.h), Vector2(m.w / 2.0, 0),
		Vector2(-m.w / 2.0, 0)])
	sombra.occluder = huella
	add_child(sombra)
	if m.tipo in Objetos.MUEBLES_CON_PIEZA or (m.tipo in Objetos.MUEBLES_CON_COMIDA and Objetos.hay_comida()):
		poner_zona()


# La zona donde se para Johnny para abrirlo: alrededor de todo su hueco del suelo (está pegado a una pared, pero puede
# ser la de arriba, la de abajo o una de los lados), solo mientras sigue cerrado
func poner_zona() -> void:
	var zona_usar := ZONA_USAR.new()
	zona_usar.montar_rect(Rect2(-datos.w / 2.0 - 28.0, -datos.h - 28.0, datos.w + 56.0, datos.h + 56.0))
	zona_usar.puede = func() -> bool: return not datos.get("abierto", false)
	add_child(zona_usar)
	zona_usar.usar.connect(usar.emit)


# Ya abierto: se apunta en sus datos (en la planta) y deja de tener contorno
func abrir() -> void:
	datos.abierto = true
