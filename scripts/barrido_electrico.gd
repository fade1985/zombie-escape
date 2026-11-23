# El barrido eléctrico del antidisturbios (fase 2, sin escudo; docs/JEFES_CENTRO.md): golpea el suelo con la porra y
# salen varias olas de chispas, una tras otra, que cruzan la sala de pared a pared. Cada ola es una raya recta (de lado
# a lado de la sala, a lo ancho o a lo alto) que avanza desde él hacia la pared de enfrente, con un hueco por donde
# pasar (marcado con dos bolas eléctricas), cada ola en otro sitio. Solo se pasa por el hueco: esquivando, también da
# (21 nov, lo pidió el dueño). Si toca a Johnny, le quita lo suyo (una vez por ola).
# Va recta, a lo ancho o a lo alto (la dirección hacia Johnny, redondeada): así cruza la sala de pared a pared.
# Las paredes la paran (los muebles, no: va por el suelo). Se dibuja con código, a cuadraditos de 2.
# Se crea con BarridoElectrico.new(); se le ponen "dir", "olas" y "dueno" y se mete en la escena donde está el jefe.
class_name BarridoElectrico
extends Node2D

const VELOCIDAD := 170.0   # lo deprisa que avanza cada ola (21 nov: 300 era muy deprisa)
const HUECO := 64.0        # medio ancho del hueco de cada ola
const GROSOR := 14.0       # lo que tiene que estar Johnny de cerca de la raya para que le dé
const DANO := 14
const MAX_LADO := 1400.0   # lo más lejos que se busca la pared a cada lado

var dir := Vector2.RIGHT     # hacia dónde avanzan (ya redondeada a lo ancho o a lo alto)
var olas: Array = []         # cada una: {"sale": segundos}; su "hueco" (dónde está, a lo largo de la raya) lo pone _ready
var dueno: Node2D = null
var cerca_de := Vector2.INF  # si se pone (el sitio de Johnny), el hueco de la primera ola sale cerca de él
var t := 0.0
var lado := Vector2.DOWN     # a lo largo de la raya
var desde := -600.0          # dónde acaba la raya a cada lado (lo que deja la pared)
var hasta := 600.0
var fondo := 1200.0          # hasta dónde avanza (la pared de enfrente)
# lo que cambia la ola de aceite del cocinero (ola_aceite.gd, que es este mismo barrido con otro dibujo)
var velocidad := VELOCIDAD
var dano := DANO
var sonido_sale := "calambre"
var sonido_da := "rayo"


func _ready() -> void:
	z_index = -1   # en el suelo, por debajo de todos
	# a lo ancho o a lo alto
	dir = Vector2(signf(dir.x), 0) if absf(dir.x) >= absf(dir.y) else Vector2(0, signf(dir.y))
	lado = dir.orthogonal()
	desde = -hasta_pared(-lado)
	hasta = hasta_pared(lado)
	fondo = hasta_pared(dir)
	# el hueco de cada ola, al azar dentro de la sala, y lejos del de la anterior (que haya que moverse)
	var anterior := INF
	for ola in olas:
		if ola.has("hueco"):
			continue
		var h := 0.0
		if anterior == INF and cerca_de != Vector2.INF:
			# la primera, cerca de Johnny: que le dé tiempo a llegar (23 nov, lo pidió el dueño)
			var s := (cerca_de - global_position).dot(lado) + randf_range(-HUECO, HUECO)
			ola.hueco = clampf(s, desde + HUECO + 24.0, maxf(desde + HUECO + 24.0, hasta - HUECO - 24.0))
			anterior = ola.hueco
			continue
		for i in 8:
			h = randf_range(desde + HUECO + 24.0, maxf(desde + HUECO + 24.0, hasta - HUECO - 24.0))
			if absf(h - anterior) >= 220.0:
				break
		ola.hueco = h
		anterior = h
	Sonido.tocar(sonido_sale)


# Lo que hay desde aquí hasta la pared (los muros del mapa; los muebles no la paran)
func hasta_pared(hacia: Vector2) -> float:
	var espacio := get_world_2d().direct_space_state
	var rayo := PhysicsRayQueryParameters2D.create(global_position, global_position + hacia * MAX_LADO, 1)
	for i in 12:
		var choque := espacio.intersect_ray(rayo)
		if choque.is_empty():
			return MAX_LADO
		if (choque.collider as Node).is_in_group("muros"):
			return global_position.distance_to(choque.position)
		rayo.exclude = rayo.exclude + [choque.rid]   # (un mueble: sigue buscando)
	return MAX_LADO


func _physics_process(delta: float) -> void:
	var antes := t
	t += delta
	queue_redraw()
	var quedan := false
	var johnny := get_tree().get_first_node_in_group("jugador")
	for ola in olas:
		var d1: float = (t - ola.sale) * velocidad
		if d1 <= fondo:
			quedan = true
		if d1 < 0.0 or ola.get("dio", false) or johnny == null or not johnny.vivo:
			continue
		var d0: float = (antes - ola.sale) * velocidad
		var rel: Vector2 = johnny.global_position - global_position
		var p := rel.dot(dir)
		var s := rel.dot(lado)
		# ¿la raya ha pasado por encima de él en este paso? (fuera del hueco y de la sala, no)
		if p >= d0 - GROSOR and p <= d1 + GROSOR and d1 <= fondo + GROSOR and absf(s - ola.hueco) > HUECO \
				and s >= desde and s <= hasta:
			ola.dio = true
			if johnny.esquiva_t > 0.0:
				johnny.invulnerable = 0.0   # (lo que protege la esquiva no vale aquí: solo el hueco)
			johnny.recibir_dano(dano, dueno)
			johnny.empujar(dir * 350.0)
			Sonido.tocar(sonido_da)
	if not quedan:
		queue_free()


func _draw() -> void:
	for ola in olas:
		var d: float = (t - ola.sale) * velocidad
		if d < 0.0 or d > fondo:
			continue
		pintar_ola(d, ola.hueco)
		postes(dir * d, ola.hueco)


# Una ola: un rayo en zigzag que parpadea, de pared a pared, con su hueco entre dos postes amarillos. Por capas: el
# brillo azul en el suelo (una franja ancha y flojita), un rayo fino de acompañante, el rayo gordo (azul claro con el
# centro blanco), ramitas que salen hacia delante y chispas que saltan
func pintar_ola(d: float, hueco: float) -> void:
	var base := dir * d
	var cuadro := int(t * 18.0)   # (el zigzag cambia 18 veces por segundo: parpadea)
	for tramo in [[desde, hueco - HUECO], [hueco + HUECO, hasta]]:
		var a: float = maxf(tramo[0], desde)
		var b: float = minf(tramo[1], hasta)
		if b - a < 4.0:
			continue
		# el brillo en el suelo
		var r := Rect2(base + lado * a - dir * 14.0, Vector2.ZERO).expand(base + lado * b + dir * 14.0)
		draw_rect(r.abs(), Color("#2a6cff", 0.18))
		draw_rect(Rect2(base + lado * a - dir * 6.0, Vector2.ZERO).expand(base + lado * b + dir * 6.0).abs(),
			Color("#5fd3ff", 0.16))
		# el rayo fino y el gordo
		var fino := zigzag(base, a, b, cuadro * 31 + 7, 9.0)
		var gordo := zigzag(base, a, b, cuadro * 17 + 1, 6.0)
		trazar(fino, 2.0, Color("#9fe8ff", 0.7))
		trazar(gordo, 6.0, Color("#5fd3ff"))
		trazar(gordo, 2.0, Color("#ffffff"))
		# ramitas: cada pocos puntos, un trocito de rayo hacia delante (o hacia atrás), cortito
		for k in gordo.size():
			var h := absi(hash(Vector2i(k, cuadro)))
			if h % 6 != 0:
				continue
			var p: Vector2 = gordo[k]
			var hacia := dir * (1.0 if h % 4 < 2 else -1.0)
			var q := p + hacia * 10.0 + lado * float(h % 9 - 4) * 2.0
			trazar(PackedVector2Array([p, q, q + hacia * 8.0 + lado * float(h % 5 - 2) * 3.0]), 2.0, Color("#bff3ff"))
			# y una chispa que salta
			if h % 12 == 0:
				draw_rect(Rect2(((q + Vector2(0, -8 - h % 7)) / 2.0).floor() * 2.0, Vector2(2, 2)), Color("#fff3a8"))


# Los puntos de un rayo de "a" a "b" (a lo largo de la raya), cada 14, movidos al azar a un lado y a otro (hasta "tiembla")
func zigzag(base: Vector2, a: float, b: float, semilla: int, tiembla: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	var s := a
	var i := 0
	while true:
		var fuera := 0.0 if s == a or s >= b else float(absi(hash(Vector2i(i, semilla))) % 100) / 50.0 - 1.0
		puntos.append(base + lado * minf(s, b) + dir * fuera * tiembla)
		if s >= b:
			break
		s += 14.0
		i += 1
	return puntos


# Una línea de pixel art: cuadraditos de "grueso" cada 2 unidades, en la cuadrícula de los píxeles del dibujo
func trazar(puntos: PackedVector2Array, grueso: float, color: Color) -> void:
	var medio := Vector2(grueso, grueso) / 2.0
	for k in puntos.size() - 1:
		var p0 := puntos[k]
		var p1 := puntos[k + 1]
		var pasos := maxi(1, ceili(p0.distance_to(p1) / 2.0))
		for j in pasos:
			var p := (p0.lerp(p1, float(j) / pasos) / 2.0).floor() * 2.0
			draw_rect(Rect2(p - medio, Vector2(grueso, grueso)), color)


# Los bordes del hueco: donde se corta el rayo, una bola de electricidad que chisporrotea (brillo azul, centro blanco y
# unas chispitas que saltan hacia fuera, distintas cada poco). Hasta el 21 nov, dos postes amarillos
func postes(base: Vector2, hueco: float) -> void:
	var cuadro := int(t * 14.0)
	for borde in [hueco - HUECO, hueco + HUECO]:
		if borde < desde or borde > hasta:
			continue
		var p: Vector2 = ((base + lado * borde) / 2.0).floor() * 2.0
		var late := 1.0 + sin(t * 20.0 + borde) * 0.15
		Formas.disco(self, p, 13.0 * late, Color("#2a6cff", 0.35))
		Formas.disco(self, p, 8.0 * late, Color("#5fd3ff"))
		Formas.disco(self, p, 4.0, Color("#ffffff"))
		# las chispitas: tres rayitos cortos que salen de la bola
		for j in 3:
			var h := absi(hash(Vector2i(int(borde), cuadro * 3 + j)))
			var a := float(h % 360) * PI / 180.0
			var q := p + Vector2.from_angle(a) * 10.0
			var r := q + Vector2.from_angle(a + float(h % 5 - 2) * 0.4) * 8.0
			trazar(PackedVector2Array([q, r]), 2.0, Color("#bff3ff"))
