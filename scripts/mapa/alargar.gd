# Alarga un dibujo hacia arriba sin estirarlo (sin que sus píxeles salgan desiguales): repite la franja de en medio
# (16 filas o las que hagan falta) las veces que haga falta hasta llegar al alto pedido. Lo usan las tiendas de pared
# alta (Tienda.TIPOS "sube"): el papel de la pared (cara_pared.gd) y las puertas de dentro (puerta_bano.gd), hechos
# para la pared de siempre, de 3 casillas, se alargan para la de 4. Se guardan, para no rehacerlos cada vez
extends RefCounted

const FRANJA := 16   # las filas de en medio que se repiten

static var hechos := {}


# El dibujo con "alto" filas (si ya las tiene o más, el mismo)
static func dibujo(tex: Texture2D, alto: int) -> Texture2D:
	var h := tex.get_height()
	if h >= alto:
		return tex
	var clave := "%d-%d" % [tex.get_rid().get_id(), alto]
	if hechos.has(clave):
		return hechos[clave]
	var img: Image = tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var franja := mini(FRANJA, h)
	var desde := (h - franja) / 2   # la franja: las filas de en medio
	var nueva := Image.create(w, alto, false, Image.FORMAT_RGBA8)
	# lo de arriba de la franja, tal cual
	nueva.blit_rect(img, Rect2i(0, 0, w, desde), Vector2i.ZERO)
	# la franja, repetida hasta llenar lo que falta
	var y := desde
	var falta := alto - h + franja
	while falta > 0:
		var trozo := mini(franja, falta)
		nueva.blit_rect(img, Rect2i(0, desde, w, trozo), Vector2i(0, y))
		y += trozo
		falta -= trozo
	# y lo de debajo de la franja, tal cual, hasta el pie
	nueva.blit_rect(img, Rect2i(0, desde + franja, w, h - desde - franja), Vector2i(0, y))
	var hecho := ImageTexture.create_from_image(nueva)
	hechos[clave] = hecho
	return hecho
