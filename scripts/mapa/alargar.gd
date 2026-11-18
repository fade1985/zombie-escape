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


# Como "dibujo", pero para las hojas con un pomo (las metálicas): el pomo (las filas k0 a k1, incluida) no se repite, y lo que se añade se
# reparte a mitades por encima y por debajo de él, repitiendo 4 filas de justo al lado: así sale uno solo y queda en el medio
static func dibujo_con_pomo(tex: Texture2D, alto: int, k0: int, k1: int) -> Texture2D:
	var h := tex.get_height()
	if h >= alto:
		return tex
	var clave := "%d-%d-pomo" % [tex.get_rid().get_id(), alto]
	if hechos.has(clave):
		return hechos[clave]
	var img: Image = tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var mas := alto - h
	var arriba := mas / 2
	var abajo := mas - arriba
	var nueva := Image.create(w, alto, false, Image.FORMAT_RGBA8)
	var y := 0
	nueva.blit_rect(img, Rect2i(0, 0, w, k0), Vector2i(0, y))
	y += k0
	for i in arriba:   # las filas k0-4 a k0-1, una y otra vez
		nueva.blit_rect(img, Rect2i(0, k0 - 4 + i % 4, w, 1), Vector2i(0, y))
		y += 1
	nueva.blit_rect(img, Rect2i(0, k0, w, k1 - k0 + 1), Vector2i(0, y))
	y += k1 - k0 + 1
	for i in abajo:   # las filas k1+1 a k1+4
		nueva.blit_rect(img, Rect2i(0, k1 + 1 + i % 4, w, 1), Vector2i(0, y))
		y += 1
	nueva.blit_rect(img, Rect2i(0, k1 + 1, w, h - k1 - 1), Vector2i(0, y))
	var hecho := ImageTexture.create_from_image(nueva)
	hechos[clave] = hecho
	return hecho
