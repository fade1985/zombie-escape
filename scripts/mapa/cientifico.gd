# El científico de Velaria muerto en el suelo (historia.gd): tumbado con su bata blanca manchada de sangre seca
# (sprite de PixelLab con la piel y el pelo de su página; el jefe de seguridad y la secretaria del centro comercial,
# que llevan su ropa, todavía dibujados con formas, como persona.gd) y, a su lado, la página del dosier, que brilla
# y sube y baja hasta que Johnny se arrima.
# Entonces avisa con "cogida" (la partida la enseña y la guarda). Ya cogida, el cuerpo se queda sin la página.
extends Node2D

signal cogida

const ALCANCE := 46.0   # lo cerca que hay que pasar para coger la página

var pagina: Dictionary    # la página que lleva (Historia.DOSIERES)
var johnny: Node2D
var mapa: Node = null     # para la niebla de su habitación (su brillo no se ve desde fuera)
var zona := -1
var look := {}            # piel y pelo (los de su página)
var papel: Node2D
var brillo: PointLight2D
var t := 0.0


func montar(p: Dictionary, pos: Vector2) -> void:
	pagina = p
	name = "Cientifico"
	position = pos
	look = p.look
	z_index = -1   # en el suelo: los que pasen por encima se ven delante
	if look.has("ropa"):
		queue_redraw()   # los que no son científicos, todavía dibujados con formas (_draw)
	else:
		# el dibujo de PixelLab, en tres capas: el cuerpo, y la piel y el pelo en grises que se pintan con los
		# colores de su página (tools/cientifico_muerto.py). La piel, apagada y grisácea: lleva tiempo muerto
		capa(CUERPO, Color.WHITE)
		capa(PIEL, Color(look.skin).lerp(Color("#969696"), 0.35))
		capa(PELO, look.hair)
	# la página: un papel con renglones
	papel = Node2D.new()
	papel.position = Vector2(28, 30)
	papel.scale = Vector2(1.4, 1.4)
	papel.draw.connect(func():
		papel.draw_rect(Rect2(-7, -9, 14, 18), Historia.PAPEL)
		papel.draw_rect(Rect2(-7, -9, 14, 18), Historia.TINTA, false, 1.0)
		for i in 4:
			papel.draw_line(Vector2(-4, -5 + i * 4), Vector2(4, -5 + i * 4), Color(Historia.TINTA, 0.5), 1.0))
	add_child(papel)
	brillo = PointLight2D.new()
	brillo.texture = load("res://escenas/luces/luz_suave.tres")
	brillo.texture_scale = 0.22
	brillo.color = Color("#ffd23f")
	brillo.position = papel.position
	add_child(brillo)


func _physics_process(delta: float) -> void:
	t += delta
	if papel == null:
		return
	papel.position.y = 30 - absf(sin(t * 2.5)) * 6.0
	var oscuro: float = mapa.niebla.get(zona, 0.0) if mapa and zona >= 0 else 0.0
	brillo.energy = (0.6 + sin(t * 3.0) * 0.15) * (1.0 - oscuro)
	brillo.enabled = oscuro < 0.98
	if johnny and johnny.vivo and johnny.global_position.distance_to(global_position + papel.position) < ALCANCE:
		papel.queue_free()
		brillo.queue_free()
		papel = null
		cogida.emit()


const CUERPO := preload("res://assets/sprites/cientifico-muerto.png")
const PIEL := preload("res://assets/sprites/cientifico-muerto-piel.png")
const PELO := preload("res://assets/sprites/cientifico-muerto-pelo.png")


# Una capa del dibujo, a escala 2 como los demás sprites, más o menos donde estaba el cuerpo dibujado a mano
func capa(textura: Texture2D, color: Color) -> void:
	var s := Sprite2D.new()
	s.texture = textura
	s.scale = Vector2(2, 2)
	s.position = Vector2(0, -6)
	s.modulate = color
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(s)   # antes que la página: queda debajo


const LINEA := Color("#1d1b2c")
const BATA := Color("#eeeee6")
const BATA_SOMBRA := Color("#b9bcc6")
const PANTALON := Color("#4b4f5e")
const SANGRE := Color("#5e1212")


# Tumbado a lo largo (la cabeza a la izquierda). Las medidas son unidades del mundo (2 por píxel)
func _draw() -> void:
	if not look.has("ropa"):
		return   # los científicos ya son un sprite (montar)
	# el charco de sangre, con unas salpicaduras
	draw_set_transform(Vector2(-12, 6), 0.0, Vector2(1.0, 0.42))
	Formas.disco(self, Vector2.ZERO, 50.0, Color(SANGRE, 0.85))
	draw_set_transform(Vector2.ZERO)
	for g in [[Vector2(-58, 14), 6.0], [Vector2(30, 22), 5.0], [Vector2(-40, -12), 4.0], [Vector2(44, 2), 3.0]]:
		Formas.disco(self, g[0], g[1], Color(SANGRE, 0.85))
	# piernas y zapatos
	for y in [-9.0, 2.0]:
		pieza(Rect2(10, y, 34, 8), look.get("pantalon", PANTALON))
		pieza(Rect2(44, y - 1, 7, 10), LINEA)
	# brazo estirado hacia arriba (manga y mano) y el otro pegado al cuerpo
	var ropa: Color = look.get("ropa", BATA)   # los que no son científicos llevan su ropa (historia.gd)
	pieza(Rect2(-14, -30, 8, 20), ropa)
	Formas.disco(self, Vector2(-10, -33), 5.0, look.skin)
	Formas.arco(self, Vector2(-10, -33), 5.0, 0, TAU, 12, LINEA, 2.0)
	pieza(Rect2(-6, 12, 18, 7), ropa)
	Formas.disco(self, Vector2(15, 16), 4.5, look.skin)
	Formas.arco(self, Vector2(15, 16), 4.5, 0, TAU, 12, LINEA, 2.0)
	# la bata: el cuerpo, con la solapa, el bolsillo y la tarjeta de Velaria
	var sombra: Color = BATA_SOMBRA if not look.has("ropa") else ropa.darkened(0.35)
	pieza(Rect2(-24, -13, 38, 26), ropa)
	draw_line(Vector2(-24, 0), Vector2(6, 0), sombra, 2.0)
	draw_rect(Rect2(-4, -10, 8, 6), sombra, false, 1.5)
	draw_rect(Rect2(-18, 3, 7, 8), look.get("tarjeta", Color("#3d63c9")))
	# la cabeza, de lado, con el pelo
	Formas.disco(self, Vector2(-35, 2), 11.0, look.skin)
	Formas.disco(self, Vector2(-39, 0), 9.0, look.hair)
	Formas.arco(self, Vector2(-35, 2), 11.0, 0, TAU, 20, LINEA, 2.0)
	# los ojos cerrados
	draw_line(Vector2(-30, -1), Vector2(-26, -1), LINEA, 1.5)
	draw_line(Vector2(-30, 5), Vector2(-26, 5), LINEA, 1.5)


# Un trozo del cuerpo: relleno y contorno
func pieza(r: Rect2, color: Color) -> void:
	draw_rect(r, color)
	draw_rect(r, LINEA, false, 2.0)


# Sin la página (ya cogida en esta partida): solo el cuerpo
func vaciar() -> void:
	if papel:
		papel.queue_free()
		brillo.queue_free()
		papel = null
