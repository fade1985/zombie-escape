# El cuerpo de un zombi que muere ardiendo (Corpse de src/zombies.js). Se engancha al zombi muerto y, contando
# desde que toca el suelo: cae ardiendo (con sus llamas), se apaga mientras se vuelve carbón, le quedan brasas que parpadean y
# columnas de humo, y al final se deshace en ceniza. Quedan una quemadura en el suelo y unos huesos (que ya no
# se van). Las brasas, el humo y los restos salen de los píxeles de verdad de su dibujo tendido.
class_name Quemado
extends Node2D

const CARBON := 1.5     # segundos en apagarse y ennegrecer (BURNT.char del JS)
const BRASAS := 5.0     # hasta aquí le quedan brasas y humo
const CENIZA := 6.5     # y entre BRASAS y CENIZA se deshace: debajo aparecen sus restos
const NEGRO := Color("#2c211c")   # el carbón (se multiplica: oscurece sin borrar las sombras)
const BRASA := [Color("#ffd23f"), Color("#f0541e")]
const HUMO := [Color("#4a4542"), Color("#6b6560")]
const CENIZAS := [Color("#3a3330"), Color("#76706a")]
const RESTOS := preload("res://assets/sprites/objeto-restos.png")
const CELDA_RESTOS := 20   # cada pieza de la hoja de restos mide 20×20; filas: calavera y hueso de cada talla
const FILAS := {"grande": 0, "mediano": 2, "pequeno": 4}

var zombi: Node2D
var sprite: AnimatedSprite2D
var talla := "mediano"    # la de la calavera y los huesos: va con la cabeza del zombi
var t := 0.0
var caida := 0.0          # lo que dura su animación de caer
var puntos: Array = []    # píxeles de su dibujo tendido (en el sitio del zombi), con su fase para parpadear
var restos: Node2D        # la quemadura y los huesos, por debajo del cuerpo


# Lo llama el zombi al morir ardiendo
static func empezar(z: Node2D, s: AnimatedSprite2D, talla_restos: String) -> void:
	var q := Quemado.new()
	q.zombi = z
	q.sprite = s
	q.talla = talla_restos
	q.z_index = 1   # las brasas y el humo, encima del cuerpo
	var anim := s.animation
	q.caida = s.sprite_frames.get_frame_count(anim) / s.sprite_frames.get_animation_speed(anim)
	z.add_child(q)


func _ready() -> void:
	# los píxeles del último fotograma de caer (el cuerpo tendido), pasados al sitio del zombi
	var anim := sprite.animation
	var imagen := sprite.sprite_frames.get_frame_texture(anim, sprite.sprite_frames.get_frame_count(anim) - 1).get_image()
	var solidos: Array = []
	for y in imagen.get_height():
		for x in imagen.get_width():
			if imagen.get_pixel(x, y).a > 0.78:
				solidos.append(sprite.position + (sprite.offset + Vector2(x, y)) * sprite.scale)
	for i in mini(80, solidos.size()):
		puntos.append([solidos.pick_random(), randf() * 10.0])
	restos = Node2D.new()
	restos.z_index = -1   # por debajo del cuerpo
	restos.modulate.a = 0.0
	restos.draw.connect(dibujar_restos)
	zombi.add_child.call_deferred(restos)


func _process(delta: float) -> void:
	t += delta
	var tg := t - caida   # desde que tocó el suelo (negativo: aún cae)
	var llamas: Llamas = zombi.llamas
	if tg < 0.0:
		# cae ardiendo, como en vida
		sprite.self_modulate = Color.WHITE
		pintar_fuego(1.0)
	elif tg < CARBON:
		# en el suelo: el fuego se apaga mientras el carbón aparece por encima
		var k := tg / CARBON
		sprite.self_modulate = Color.WHITE.lerp(NEGRO, k)
		pintar_fuego(1.0 - k)
		if llamas:
			llamas.fuerza = 1.0 - k
	elif tg < CENIZA:
		# carbón; al final se va deshaciendo y debajo aparecen sus restos
		sprite.self_modulate = NEGRO
		pintar_fuego(0.0)
		if llamas:
			llamas.fuerza = 0.0
		var k := maxf(0.0, (tg - BRASAS) / (CENIZA - BRASAS))
		sprite.modulate.a = 1.0 - k
		restos.modulate.a = k
		if k > 0.0:
			ceniza(delta)
	else:
		# solo quedan la quemadura del suelo y los huesos
		sprite.hide()
		if llamas:
			llamas.fuerza = 0.0
		restos.modulate.a = 1.0
		set_process(false)
	queue_redraw()


# Las llamas de su shader, las mismas que en vida (Zombi.quemaduras), con "k" de fuerza (0 = apagadas)
func pintar_fuego(k: float) -> void:
	Zombi.quemaduras(sprite, k, 0.0, t)


# Se deshace: copos de ceniza que se levantan del cuerpo
func ceniza(delta: float) -> void:
	var n := 30.0 * delta
	while n > 0.0:
		if n < 1.0 and randf() > n:
			break
		n -= 1.0
		var p: Vector2 = puntos.pick_random()[0] if not puntos.is_empty() else Vector2(0, -10)
		Particulas.soltar(zombi, zombi.global_position + p + Vector2(randf_range(-6, 6), 0),
			Vector2(randf_range(-20, 20), randf_range(-60, -25)), CENIZAS[randi() % 2], randf_range(3.0, 6.0), randf_range(0.4, 0.8))


# Brasas que parpadean sobre el cuerpo y cuatro columnas de bocanadas de humo que crecen al subir y se deshacen
func _draw() -> void:
	var tg := t - caida
	if tg < 0.0 or tg >= BRASAS:
		return
	var quedan := 1.0 - tg / BRASAS   # de 1 (recién caído) a 0 (apagado)
	for i in mini(12, puntos.size()):
		var p: Vector2 = puntos[i][0]
		var brillo := sin(Time.get_ticks_msec() / 1000.0 * 7.0 + puntos[i][1]) * 0.5 + 0.5
		if brillo * quedan < 0.2:
			continue   # apagada en este momento
		var c: Color = BRASA[0] if brillo > 0.7 else BRASA[1]
		c.a = minf(1.0, quedan * 1.5)
		draw_rect(Rect2(encajar(p), Vector2(2, 2)), c)
	var reloj := Time.get_ticks_msec() / 1000.0
	for i in mini(4, puntos.size()):
		var p: Vector2 = puntos[i][0]
		var fase: float = puntos[i][1]
		for k in 8:
			var c := fmod(reloj * 0.6 + fase + k / 8.0, 1.0)   # 0 = sale, 1 = se deshace
			var lado := 2.0 * (3.0 + c * 5.0)
			var color: Color = HUMO[0] if c < 0.3 else HUMO[1]
			color.a = (1.0 - c) * 0.55 * minf(1.0, quedan * 1.3)
			var centro := p + Vector2(sin(c * 5.0 + fase) * 8.0, -c * 70.0)
			draw_rect(Rect2(encajar(centro - Vector2(lado, lado) / 2.0), Vector2(lado, lado)), color)


# En la cuadrícula de píxeles del dibujo (2 unidades)
func encajar(p: Vector2) -> Vector2:
	return ((zombi.global_position + p) / 2.0).round() * 2.0 - zombi.global_position


# La quemadura del suelo (irregular, más negra en el centro, con motas de ceniza) y encima una calavera y uno o
# dos huesos al azar, la calavera hacia un lado y los huesos hacia el otro. Se calcula una vez y se pinta fija
func dibujar_restos() -> void:
	if not restos.has_meta("celdas"):
		preparar_restos()
	for c in restos.get_meta("celdas"):
		restos.draw_rect(Rect2(c[0], Vector2(2, 2)), c[1])
	for pieza in restos.get_meta("piezas"):
		restos.draw_texture_rect_region(RESTOS, Rect2(pieza[0], Vector2(CELDA_RESTOS, CELDA_RESTOS) * 2.0), pieza[1])


func preparar_restos() -> void:
	# lo que mide el cuerpo tendido, en píxeles del dibujo
	var minimo := Vector2(-10, -16)
	var maximo := Vector2(10, 0)
	for q in puntos:
		minimo = minimo.min(q[0] / 2.0)
		maximo = maximo.max(q[0] / 2.0)
	var centro := (minimo + maximo)   # en unidades (x2 / 2)
	var w := maximo.x - minimo.x
	var h := maximo.y - minimo.y
	var rx := maxf(10.0, w / 2.0 + 3.0)
	var ry := maxf(6.0, minf(rx * 0.55, h / 2.0 + 4.0))
	var bultos := []
	for i in 5:
		bultos.append([randf() * TAU, randf_range(0.1, 0.25)])
	var celdas := []
	for py in range(-ceili(ry) - 1, ceili(ry) + 2):
		for px in range(-ceili(rx) - 1, ceili(rx) + 2):
			var dx := px / rx
			var dy := py / ry
			var a := atan2(dy, dx)
			var bulto := 0.0
			for b in bultos:
				bulto += cos(a * 3.0 + b[0]) * b[1]
			var d := Vector2(dx, dy).length() - bulto / 2.0 + randf_range(-0.08, 0.08)
			if d > 1.0:
				continue
			var color: Color
			if randf() < 0.05:
				color = Color8(122, 116, 110, 204)   # mota de ceniza
			elif d < 0.45:
				color = Color8(20, 15, 13, 230)
			elif d < 0.75:
				color = Color8(42, 26, 20, 178)
			else:
				color = Color8(58, 42, 34, 102)
			celdas.append([encajar(centro + Vector2(px, py) * 2.0), color])
	var fila: int = FILAS.get(talla, 2)
	var lado := -1.0 if randf() < 0.5 else 1.0
	var piezas := []
	var trozo := func(fila_hoja: int, donde: Vector2) -> Array:
		var region := Rect2(randi() % 3 * CELDA_RESTOS, fila_hoja * CELDA_RESTOS, CELDA_RESTOS, CELDA_RESTOS)
		return [encajar(donde - Vector2(CELDA_RESTOS, CELDA_RESTOS)), region]
	for i in (1 if randf() < 0.5 else 2):
		piezas.append(trozo.call(fila + 1, centro + Vector2(-lado * randf_range(0.1, 0.45) * rx, randf_range(-ry, ry) * 0.3) * 2.0))
	piezas.append(trozo.call(fila, centro + Vector2(lado * randf_range(0.1, 0.35) * rx, randf_range(-ry, ry) * 0.25) * 2.0))
	restos.set_meta("celdas", celdas)
	restos.set_meta("piezas", piezas)
