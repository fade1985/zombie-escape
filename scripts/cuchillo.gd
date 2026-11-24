# Un cuchillo del cocinero (minijefe del centro comercial), dibujado con código como la botella de lejía de la
# portera. Llega de dos maneras:
#   - "vuela": lanzado en línea recta, dando vueltas en el aire a la altura del cuerpo (el abanico).
#   - "cae": primero sale su marca en el suelo (el aviso de los jefes, aviso.gd) y, al acabarse, cae de punta desde
#     arriba (la lluvia).
# Si le da a Johnny le quita lo suyo. Si no, se queda clavado un rato (en el suelo o en la pared) y se desvanece.
# Se crea con Cuchillo.new(); el cocinero también usa dibujar() para los que lleva en la mano.
class_name Cuchillo
extends Node2D

const CLAVADO := 4.0      # lo que se queda clavado
const CAIDA := 0.22       # lo que tarda en caer desde arriba
const ALTO := 420.0       # desde qué altura cae
const RADIO_CAE := 26.0   # el tamaño de la marca: si Johnny la pisa cuando cae, le da
const TIEMBLA := 0.4      # lo que vibra al clavarse
const ALTURA := 22.0      # a qué altura del suelo vuela (la del cuerpo, como las balas de los zombis)

var modo := "vuela"
var velocidad := Vector2.ZERO   # "vuela"
var dano := 12
var dueno: Node2D = null        # quien lo lanza, el cocinero (para la skin del glotón: johnny.gd, devolver())
var aviso := 0.8                # "cae": lo que dura la marca antes de caer
var espera := 0.0               # "cae": lo que tarda en salir la marca (para que no caigan todos a la vez)
var t := 0.0
var clavado := -1.0             # lo que le queda clavado (-1 = aún no se ha clavado)
var giro := 0.0                 # hacia dónde apunta la hoja
var alto := ALTURA              # a qué altura se dibuja
var tiembla := 0.0              # recién clavado, lo que vibra (se va calmando)
var giro_clavado := 0.0


func _ready() -> void:
	add_to_group("balas_zombi")   # así, al enfadarse el cocinero, se borran los que van por el aire
	z_index = 4
	if modo == "cae":
		z_index = -1   # la marca, en el suelo, por debajo de todos
		giro = PI / 2.0 + randf_range(-0.3, 0.3)   # de punta, un poco torcido
		visible = false


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()
	if clavado >= 0.0:
		clavado -= delta
		tiembla = maxf(0.0, tiembla - delta)
		giro = giro_clavado + sin(t * 55.0) * 0.22 * (tiembla / TIEMBLA)
		modulate.a = clampf(clavado / 0.6, 0.0, 1.0)
		if clavado <= 0.0:
			queue_free()
		return
	if modo == "vuela":
		volar(delta)
	else:
		caer()


func volar(delta: float) -> void:
	giro = t * 18.0
	if t > 3.0:
		queue_free()
		return
	var antes := global_position
	var despues := antes + velocidad * delta
	var rayo := PhysicsRayQueryParameters2D.create(antes, despues, 1)
	var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
	if not choque.is_empty():
		# se clava en la pared o en el mueble, con la punta por delante
		global_position = choque.position - velocidad.normalized() * (LARGO - 6.0)   # (la punta, metida en la pared)
		giro = velocidad.angle()
		for i in 4:
			Particulas.soltar(get_parent(), choque.position, (-velocidad.normalized()).rotated(randf_range(-1.0, 1.0)) * randf_range(60, 130),
				Color("#fff4c0"), 2, 0.2)
		clavar()
		return
	global_position = despues
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and global_position.distance_to(johnny.global_position) < johnny.RADIO + 10.0:
		johnny.recibir_dano(dano, dueno)
		queue_free()


func caer() -> void:
	visible = t >= espera
	if t < espera + aviso:
		return
	z_index = 5   # cayendo, por encima de todo
	var k := (t - espera - aviso) / CAIDA
	alto = ALTO * (1.0 - minf(k, 1.0)) + LARGO - 6.0
	if k < 1.0:
		return
	# ¡clavado! Si Johnny está encima de la marca, le da
	alto = LARGO - 6.0   # (la punta, metida en el suelo)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and dentro(johnny.global_position, johnny.RADIO * 0.6):
		johnny.recibir_dano(dano, dueno)
	for i in 5:
		Particulas.soltar(self, global_position, Vector2(randf_range(-70, 70), randf_range(-60, -20)), Color("#8a7a66"), 3, 0.35)
	clavar()


func clavar() -> void:
	clavado = CLAVADO
	tiembla = TIEMBLA
	giro_clavado = giro
	z_index = 0   # ya quieto: se ordena con los demás por su "y"
	remove_from_group("balas_zombi")
	Sonido.tocar("clavado")


# La marca es una elipse (el suelo se ve un poco desde arriba)
func dentro(punto: Vector2, margen: float) -> bool:
	var d := punto - global_position
	var r := RADIO_CAE + margen
	return (d.x / r) ** 2 + (d.y / (r * 0.6)) ** 2 <= 1.0


func _draw() -> void:
	if modo == "cae" and clavado < 0.0:
		# la marca: el aviso de los jefes (aviso.gd, un círculo aplastado de cuadraditos que se va llenando, como los
		# saltos), del tamaño de lo que pilla; y, cayendo, la sombra del cuchillo
		if t >= espera:
			var k := clampf((t - espera) / aviso, 0.0, 1.0)
			Aviso.abanico(self, Vector2.ZERO, 0.0, PI, RADIO_CAE, k, t, 0.6)
		if t < espera + aviso:
			return
		Formas.disco(self, Vector2.ZERO, 6.0 + 6.0 * (1.0 - alto / ALTO), Color(0, 0, 0, 0.3))
		if alto > LARGO:
			# cayendo: una raya de aire por encima
			for i in 4:
				dibujar(self, Vector2(0, -alto - 14.0 - i * 14.0), giro, 1.0, 0.25 - i * 0.06)
	elif modo == "vuela" and clavado < 0.0:
		# volando: su sombra en el suelo y la estela de las vueltas de antes
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		Formas.disco(self, Vector2.ZERO, 12.0, Color(0, 0, 0, 0.28))
		draw_set_transform(Vector2.ZERO)
		var atras := -velocidad * 0.012
		dibujar(self, Vector2(0, -alto) + atras * 2.0, giro - 0.7, 1.0, 0.18)
		dibujar(self, Vector2(0, -alto) + atras, giro - 0.35, 1.0, 0.35)
	dibujar(self, Vector2(0, -alto), giro)


# El cuchillo de cocinero, a cuadraditos (2 unidades por píxel del dibujo): mango de madera oscura con dos remaches
# dorados, la virola de acero y la hoja ancha con el lomo recto y el filo que sube hasta la punta (DIBUJO, mirando a
# la derecha). Para que al girar los píxeles sigan rectos (y no cuadraditos torcidos), se gira de antemano en GIROS
# posiciones (hojas(), a la primera que hace falta) y se pinta la más cercana a "angulo". "escala": más grande,
# como los de la cruz del cocinero; "alfa": más o menos transparente (las estelas)
const DIBUJO := [
	"........oooooooooooo..",
	".ooooooobdddddddddddoo",
	"oWWrWWrWbsssssssssssSo",
	"owwwwwwwbssssssssssSo.",
	".ooooooobeeeeeeeeeo...",
	"........oooooooooo....",
]
const COLORES := {"o": "#1d1b2c", "W": "#8a5a36", "w": "#5a361f", "r": "#d9b36c", "b": "#8d94a3", "d": "#7c8594",
	"s": "#b9c1cc", "S": "#dfe5ec", "e": "#f4f7fb"}
const GIROS := 32
const LADO := 24                 # cada giro, en un cuadrado de 24×24 píxeles del dibujo (cabe entero en cualquier ángulo)
const LARGO := 22.0              # de la punta del mango a la punta de la hoja (píxeles del dibujo)

static var giros_hechos: Array[ImageTexture] = []


static func hojas() -> Array[ImageTexture]:
	if not giros_hechos.is_empty():
		return giros_hechos
	var ancho: int = DIBUJO[0].length()
	var alto: int = DIBUJO.size()
	var centro := Vector2(ancho / 2.0, alto / 2.0)
	for g in GIROS:
		var a := g * TAU / GIROS
		var img := Image.create(LADO, LADO, false, Image.FORMAT_RGBA8)
		for y in LADO:
			for x in LADO:
				# el píxel del dibujo que cae aquí (girando hacia atrás desde el centro de este píxel)
				var p := (Vector2(x + 0.5, y + 0.5) - Vector2(LADO / 2.0, LADO / 2.0)).rotated(-a) + centro
				var i := int(floor(p.x))
				var j := int(floor(p.y))
				if i < 0 or j < 0 or i >= ancho or j >= alto:
					continue
				var c: String = DIBUJO[j][i]
				if c != ".":
					img.set_pixel(x, y, Color(COLORES[c]))
		giros_hechos.append(ImageTexture.create_from_image(img))
	return giros_hechos


static func dibujar(lienzo: CanvasItem, donde: Vector2, angulo: float, escala := 1.0, alfa := 1.0) -> void:
	var g := posmod(roundi(angulo / TAU * GIROS), GIROS)
	var tam := LADO * 2.0 * escala
	# (la esquina, en múltiplos de 2: que los píxeles caigan en la rejilla)
	var esquina := ((donde - Vector2(tam, tam) / 2.0) / 2.0).round() * 2.0
	lienzo.draw_texture_rect(hojas()[g], Rect2(esquina, Vector2(tam, tam)), false, Color(1, 1, 1, alfa))
