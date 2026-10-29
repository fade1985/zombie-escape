# El impacto de una bala contra una pared, sacado de la librería de efectos de Sprite Fusion (impact.ts, licencia MIT,
# Copyright (c) 2026 Hugo Duprez) y pasado a Godot con sus tiempos, colores y números. En orden:
#   - una estrella de 8 puntas (blanca, amarilla y con borde naranja) estirada hacia donde rebota, 2 fotogramas
#   - sus 4 puntas más largas salen volando como medias lunas que se enfrían, y un anillo que se abre
#   - chispas que caen y rebotan en el suelo, trocitos de pared, polvo y una voluta de humo que sube
#   - un destello de luz (Luz.destello) en vez del "buffer de luz" del original
# Todo en cuadraditos de pixel art (2 unidades) y los fundidos con tramado (Bayer 4×4), como el original.
# De momento es una PRUEBA (--impacto, prueba_armas.gd): solo se usa con Impacto.activo, que el juego deja apagado.
class_name Impacto
extends Node2D

static var activo := false   # con true, las balas que dan en una pared sueltan este impacto (bala.gd, chocar)

const PX := 2.0              # unidades por píxel del dibujo
const GRAVEDAD := 1900.0
const RAMPA := [Color("#ffffff"), Color("#fff3a6"), Color("#ffe26b"), Color("#ff8a2a"), Color("#f2561d"), Color("#c9281f")]
const HUMO := Color("#6a6278")
const RAMPA_HUMO := [Color("#7b6f72"), Color("#5d5660"), Color("#433d48"), Color("#2b2630"), Color("#1a171e")]
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
enum { CHISPA, TROZO, POLVO, VOLUTA }

var talla := 1.0             # 0,6 es un toque flojo (perdigón); 1, una bala normal
var rampa: Array = RAMPA     # los colores, de blanco a oscuro
var rebote := 0.0            # hacia dónde sale rebotada (la dirección de la bala, reflejada en la pared)
var normal := -PI / 2        # hacia dónde mira la pared
var suelo := 0.0             # el suelo de debajo (y, en unidades desde el choque): ahí caen las chispas y los trozos
var t := 0.0
var puntas := []             # [ángulo, largo, ancho] de cada punta de la estrella
var esquirlas := []          # [ángulo, radio, velocidad, arco] de las medias lunas
var cosas := []              # las chispas, los trozos, el polvo y el humo


# Suelta un impacto en "donde" (lo que se ve de la bala), de una bala que iba hacia "angulo" y ha dado en una pared que
# mira hacia "normal". "altura": lo alto que va la bala sobre el suelo (ahí caen las chispas y los trozos)
static func soltar(desde: Node, donde: Vector2, angulo: float, normal_pared: float, altura: float, superficie: Color,
		talla_ := 1.0) -> void:
	if not desde.is_inside_tree():
		return
	var fx := Impacto.new()
	fx.talla = talla_
	fx.normal = normal_pared
	fx.suelo = altura
	fx.z_index = 20   # por encima de los personajes, como las otras partículas
	fx.position = (donde / PX).round() * PX   # encajado en la cuadrícula del dibujo
	fx.preparar(angulo, superficie)
	desde.get_tree().current_scene.add_child(fx)
	Luz.destello(desde, donde, (22.0 * talla_ + 6.0) * PX, 0.15, 0.9, RAMPA[3])


func preparar(angulo: float, superficie: Color) -> void:
	var s := talla
	var d := Vector2.from_angle(angulo)
	var n := Vector2.from_angle(normal)
	rebote = (d - 2.0 * d.dot(n) * n).angle()
	for i in 8:
		var a := rebote + i / 8.0 * TAU + randf_range(-0.18, 0.18)
		var cb := cos(a - rebote)
		var largo := (7.0 + randf_range(0, 3)) * s * (1.0 + 1.8 * pow(maxf(0, cb), 3) + 0.6 * pow(maxf(0, -cb), 3))
		if cos(a - normal) < -0.2:
			largo *= 0.3   # las que apuntan hacia dentro de la pared, cortas
		puntas.append([a, largo, (1.5 + randf_range(0, 0.6)) * s])
	var abiertas := puntas.filter(func(p): return abierto(p[0]))
	abiertas.sort_custom(func(p, q): return p[1] > q[1])
	for p in abiertas.slice(0, 4):
		esquirlas.append([p[0] + randf_range(-0.15, 0.15), p[1] * 0.8, p[1] * randf_range(5, 8), randf_range(0.35, 0.6)])
	for i in roundi(6 + 12 * s):
		var a := rebote + randf_range(-1, 1) * 0.85
		var v := Vector2.from_angle(a) * randf_range(260, 900) * (0.6 + 0.4 * s) + Vector2(0, -60)
		meter(CHISPA, Vector2.ZERO, v, randf_range(0.1, 0.3))
	var polvo := superficie.lerp(Color8(150, 140, 150), 0.35)
	for i in roundi(3 + 5 * s):
		var a := normal + randf_range(-0.8, 0.8)
		var tono := 1.25 if randf() < 0.5 else (1.0 if randf() < 0.5 else 0.7)
		var c := Color(superficie.r * tono, superficie.g * tono, superficie.b * tono)
		meter(TROZO, n * 2.0, Vector2.from_angle(a) * randf_range(150, 420) * s, randf_range(0.8, 1.4), c, 2 if randf() < 0.3 else 1)
	for i in roundi(3 + 4 * s):
		var a := normal + randf_range(-1, 1)
		meter(POLVO, n * 3.0, Vector2.from_angle(a) * randf_range(20, 90) * s, randf_range(0.35, 0.7), polvo, randf_range(1.4, 2.8) * sqrt(s))
	meter(VOLUTA, n * 4.0, Vector2(randf_range(-8, 8), randf_range(-30, -14)), randf_range(0.8, 1.3), HUMO, randf_range(1.6, 2.4) * sqrt(s), 0.05)


func meter(tipo: int, pos: Vector2, v: Vector2, vida: float, color := Color.WHITE, tam := 1.0, espera := 0.0) -> void:
	cosas.append({"tipo": tipo, "pos": pos, "v": v, "vida": vida, "max": vida, "color": color, "tam": tam,
		"semilla": randf() * 100.0, "espera": espera})


# Lo que queda del lado de fuera de la pared (las medias lunas y el anillo no se ven por dentro)
func abierto(a: float) -> bool:
	return cos(a - normal) > -0.25


func _process(delta: float) -> void:
	t += delta
	for i in range(cosas.size() - 1, -1, -1):
		var p: Dictionary = cosas[i]
		if p.espera > 0.0:
			p.espera -= delta
			continue
		p.vida -= delta
		if p.vida <= 0.0:
			cosas.remove_at(i)
			continue
		var v: Vector2 = p.v
		var pos: Vector2 = p.pos
		match p.tipo:
			CHISPA:
				v.y += GRAVEDAD * 0.45 * delta
				v -= v * 2.2 * delta
				var y := pos.y + v.y * delta
				pos.x += v.x * delta
				if v.y > 0 and pos.y <= suelo and y >= suelo:   # rebota en el suelo
					v = Vector2(v.x * 0.7, -v.y * 0.45)
					pos.y = suelo - 0.5
				else:
					pos.y = y
			TROZO:
				v.y += GRAVEDAD * delta
				v.x -= v.x * 0.6 * delta
				var y := pos.y + v.y * delta
				pos.x += v.x * delta
				if v.y > 0 and pos.y <= suelo and y >= suelo:
					pos.y = suelo - 0.5
					if v.y > 220.0:
						v = Vector2(v.x * 0.5 + randf_range(-20, 20), -v.y * 0.3)
					else:
						v = Vector2.ZERO   # se queda en el suelo y se va
						p.vida = minf(p.vida, 0.5)
				else:
					pos.y = y
			POLVO:
				v -= v * 4.0 * delta + Vector2(0, 10.0 * delta)
				pos += v * delta
			VOLUTA:
				v.y -= 32.0 * delta
				v.x += sin(t * 1.3 + p.semilla) * 16.0 * delta
				v.x -= v.x * 1.6 * delta
				v.y -= v.y * 1.2 * delta
				pos += v * delta
		p.v = v
		p.pos = pos
	if t > 0.2 and cosas.is_empty():
		queue_free()
	queue_redraw()


func _draw() -> void:
	# detrás: los trozos, el polvo y el humo
	for p in cosas:
		if p.espera <= 0.0 and p.tipo != CHISPA:
			dibujar_cosa(p)
	var f := maxi(1, ceili(t * 60.0 - 1e-6))
	if f == 1:
		estrella(1.0, 1.0, rampa[0], rampa[1], rampa[2], rampa[4])
	elif f == 2:
		estrella(1.25, 0.55, rampa[1], rampa[2], rampa[3], rampa[4])
	if f >= 3 and t < 0.13:
		var k := (t - 2.0 / 60.0) / (0.13 - 2.0 / 60.0)
		var c: Color = rampa[2] if k < 0.4 else (rampa[3] if k < 0.7 else rampa[4])
		for e in esquirlas:
			media_luna(e[0], e[1] + e[2] * (t - 2.0 / 60.0), e[3] * (1.0 - 0.4 * k), c, 1.0 - k)
	if f >= 3 and t < 0.2:
		var k := (t - 2.0 / 60.0) / (0.2 - 2.0 / 60.0)
		var r := (8.0 + 12.0 * (1.0 - pow(1.0 - k, 3))) * talla
		var grueso := maxf(1.0, 2.0 * (1.0 - k) * talla)
		var c: Color = rampa[1] if k < 0.3 else (rampa[2] if k < 0.6 else rampa[3])
		var n := ceili(r * TAU * 1.3)
		for j in n:
			var a := float(j) / n * TAU
			if not abierto(a):
				continue
			var o := -grueso / 2.0
			while o <= grueso / 2.0:
				punto(cos(a) * (r + o), sin(a) * (r + o), c, 1.15 - k)
				o += 0.5
	# delante: las chispas
	for p in cosas:
		if p.espera <= 0.0 and p.tipo == CHISPA:
			dibujar_cosa(p)


func dibujar_cosa(p: Dictionary) -> void:
	var k: float = p.vida / p.max
	var a: Vector2 = p.pos / PX
	match p.tipo:
		CHISPA:
			var caliente: Color = rampa[1] if k > 0.6 else (rampa[2] if k > 0.3 else rampa[3])
			var v: Vector2 = p.v
			var u := v.normalized() if v.length() > 0.0 else Vector2.RIGHT
			var largo := minf(9.0, 1.0 + v.length() * 0.011)
			linea(a - u * largo, a - u * largo * 0.4, caliente if k > 0.5 else rampa[4])
			linea(a - u * largo * 0.45, a, caliente)
		TROZO:
			var px := floori(a.x)
			var py := floori(a.y)
			if k > 0.25 or bayer(px, py) < k * 4.0:
				pixel(px, py, p.color)
				if p.tam >= 2:
					pixel(px + 1, py, p.color)
					var c: Color = p.color
					pixel(px, py + 1, Color(c.r * 0.8, c.g * 0.8, c.b * 0.8))
		POLVO:
			disco(a, p.tam * (0.6 + (1.0 - k) * 0.9), p.color, pow(k, 1.3) * 0.7)
		VOLUTA:
			var edad := 1.0 - k
			var r: float = p.tam * (0.65 + minf(1.0, edad * 2.5) * 0.45 + edad * 0.4)
			var al := minf(1.0, edad * 12.0) * minf(1.0, k * 2.4) * 0.5
			var i := clampf(edad, 0.0, 0.9999) * (RAMPA_HUMO.size() - 1)
			var c: Color = p.color.lerp(RAMPA_HUMO[int(i)].lerp(RAMPA_HUMO[int(i) + 1], i - int(i)), edad)
			disco(a, r, c, al * 0.45)
			disco(a + Vector2(r * 0.05, r * 0.06), r * 0.74, c, al * 0.62)


# La estrella: 8 puntas como cometas afiladas, en 3 pasadas (borde, cuerpo y centro) y un disco en medio
func estrella(escala: float, grueso: float, centro: Color, cuerpo: Color, dentro: Color, borde: Color) -> void:
	for pasada in 3:
		for p in puntas:
			var c := cos(p[0])
			var s := sin(p[0])
			var largo: float = p[1] * escala
			var d := 0.0
			while d <= largo:
				var mitad: float = p[2] * grueso * (1.0 - d / largo) * minf(1.0, 0.5 + d / 3.0)
				if pasada == 0:
					mitad += 0.8
				elif pasada == 2:
					if d > largo * 0.55:
						break
					mitad *= 0.45
				var col := borde if pasada == 0 else ((dentro if d < largo * 0.35 else cuerpo) if pasada == 1 else centro)
				var o := -mitad
				while o <= mitad:
					pixel(floori(c * d - s * o), floori(s * d + c * o), col)
					o += 0.5
				d += 0.5
	var r := 2.4 * talla * escala * sqrt(grueso)
	disco(Vector2.ZERO, r + 0.8, dentro)
	disco(Vector2.ZERO, r, centro)


func media_luna(a: float, r: float, arco: float, c: Color, k: float) -> void:
	var n := ceili(r * arco * 2.2)
	for j in n + 1:
		var u := float(j) / n - 0.5
		var th := a + u * arco
		var w := 1.4 * (1.0 - absf(u) * 2.0)
		var o := -w * 0.5
		while o <= w * 0.5 + 0.01:
			punto(cos(th) * (r + o), sin(th) * (r + o), c, k)
			o += 0.5


# Un píxel del dibujo (en píxeles del dibujo desde el choque)
func pixel(x: int, y: int, c: Color) -> void:
	draw_rect(Rect2(x * PX, y * PX, PX, PX), c)


# Un píxel que se va fundiendo con el tramado: con "a" (de 0 a 1) se ven más o menos píxeles, todos opacos
func punto(x: float, y: float, c: Color, a := 1.0) -> void:
	var px := floori(x)
	var py := floori(y)
	if a >= 1.0 or a > bayer(px, py):
		pixel(px, py, c)


func bayer(x: int, y: int) -> float:
	return (BAYER[((y & 3) << 2) | (x & 3)] + 0.5) / 16.0


func disco(centro: Vector2, r: float, c: Color, a := 1.0) -> void:
	if a <= 0.01:
		return
	c.a *= a
	if r <= 0.5:
		pixel(roundi(centro.x), roundi(centro.y), c)
		return
	for y in range(floori(centro.y - r), ceili(centro.y + r) + 1):
		var dy := y + 0.5 - centro.y
		for x in range(floori(centro.x - r), ceili(centro.x + r) + 1):
			var dx := x + 0.5 - centro.x
			if dx * dx + dy * dy <= r * r:
				pixel(x, y, c)


func linea(desde: Vector2, hasta: Vector2, c: Color) -> void:
	var a := Vector2i(desde.round())
	var b := Vector2i(hasta.round())
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var p := Vector2(a).lerp(Vector2(b), float(i) / maxf(1, n)).round()
		pixel(int(p.x), int(p.y), c)
