# Un charco en el suelo: el moco verde del venenoso, la lejía de la portera, el vómito de Johnny (mutación
# Gastroenteritis), el fuego del molotov, el aceite de la bomba de aceite (centro comercial), que resbala y al
# secarse arde: se convierte en un fuego como el del molotov, un poco más grande, o el aceite hirviendo del cocinero.
# Cada uno pone sus estados (estados.gd) a quien lo pisa: el veneno te sigue envenenando al salir, la lejía resbala,
# el ácido solo daña a los zombis... Al rato se seca.
# Como HAZARDS en src/game-ataques.js.
#
# El fuego (makeFire y burnFire de src/molotov.js) es especial: se dibuja con código, a cuadraditos de pixel
# art. Se extiende desde el centro, arde con llamas y ascuas, se apaga por trozos al final y deja una mancha
# de ceniza. Prende a los zombis que lo pisan (siguen ardiendo al salir: zombi.gd) y lleva su luz de fuego.
#
# El aceite hirviendo del cocinero ("hirviendo") quema como el fuego (a Johnny y a los zombis, pero no a él: es su
# "dueno"); se dibuja también con código, una mancha dorada con burbujas que revientan y algo de vapor.
extends Node2D

const VENENO := preload("res://assets/sprites/objeto-charco-veneno.png")
const LEJIA := preload("res://assets/sprites/objeto-charco-lejia.png")
const LUZ_FUEGO := preload("res://escenas/luces/fuego.tscn")

# Cada tipo: su dibujo, su tamaño (radio), cuánto dura y los estados que pone. "solo_zombis": a Johnny no le
# hace nada. El del molotov tiene sus números en MOLOTOV (lanzables.gd)
const TIPOS := {
	"veneno": {"dibujo": VENENO, "radio": 64.0, "vida": 4.0, "estados": {"veneno": {}}},
	"lejia": {"dibujo": LEJIA, "radio": 54.0, "vida": 5.0, "estados": {"resbaladizo": {}, "toxico": {"dps": 3.0}}},
	# el ácido que salpica la portera con la fregona: quema al pisarlo y deja veneno al salir (ACIDO en el JS)
	"acido": {"dibujo": VENENO, "radio": 58.0, "vida": 6.0, "estados": {"acido": {}, "veneno": {}},
		"tinte": Color(1.0, 1.0, 0.55)},
	"vomito": {"dibujo": VENENO, "radio": 55.0, "vida": 4.0, "estados": {"acido": {"dps": 8.0}}, "solo_zombis": true,
		"tinte": Color(1.0, 1.0, 0.45)},
	"lluvia": {"dibujo": VENENO, "radio": 150.0, "vida": 7.0, "estados": {"acido": {"dps": 10.0}}, "solo_zombis": true,
		"tinte": Color(1.0, 1.0, 0.45)},   # la lluvia ácida (arrojadiza creada)
	"fuego": {"radio": 64.0, "vida": 4.0, "estados": {"fuego": {"dps": 12.0}}},
	"aceite": {"dibujo": LEJIA, "radio": 54.0, "vida": 2.0, "estados": {"resbaladizo": {}}, "tinte": Color(1.0, 0.8, 0.25)},
	"hirviendo": {"radio": 60.0, "vida": 6.0, "estados": {"fuego": {"dps": 12.0}}, "prende": true},   # el del cocinero
	# el agua de los aspersores (la alarma de incendios, eventos.gd): solo resbala, y no se seca mientras dure
	"agua": {"dibujo": LEJIA, "radio": 54.0, "vida": 99999.0, "estados": {"resbaladizo": {}}, "tinte": Color(0.55, 0.8, 1.0)},
}
const ACEITE_ARDE := 1.25   # el fuego del aceite, así de grande respecto al del molotov
# El fuego por fuera: cuánto tarda en extenderse, cuánto antes de acabar empieza a apagarse, lo que brilla en
# blanco el frente y lo que dura la brasa de un trozo recién apagado
const EXTIENDE := 0.35
const APAGA := 1.4
const FRENTE := 0.07
const BRASA := 0.3
const CELDA := 4.0   # 2 píxeles del dibujo

var tipo := "veneno"
var dueno: Node2D = null   # quien lo ha tirado: a él no le hace nada (el cocinero y su aceite hirviendo)
var escala := 1.0          # el Fabricante hace el fuego más grande...
var duracion := 1.0        # ...y más largo
var dano_lanzar := 1.0     # Puntería: el fuego quema más a los zombis
var vida := 0.0
var vida_max := 0.0
var t := 0.0
var tick := 0.0
var celdas: Array = []     # el fuego: [posición, distancia al centro (0-1), cuándo prende, cuándo se apaga, ruido]
var llamas: Array = []     # [x, y, ancho, alto, semilla, prende, apaga]
var ascuas: Array = []
var burbujas: Array = []   # el aceite hirviendo: [sitio, cuándo empieza, cada cuánto revienta]


func _ready() -> void:
	vida_max = TIPOS[tipo].vida * duracion
	vida = vida_max
	z_index = -1   # en el suelo: por debajo de todos
	add_to_group("charcos")
	if tipo == "hirviendo":
		hacer_hirviendo()
	if tipo == "fuego":
		hacer_fuego()
		var luz := LUZ_FUEGO.instantiate()
		luz.radio = radio() * 3.0
		luz.vida = vida_max
		add_child(luz)


func radio() -> float:
	return TIPOS[tipo].radio * escala


func _physics_process(delta: float) -> void:
	vida -= delta
	t += delta
	if vida <= 0.0:
		if tipo == "fuego":
			dejar_ceniza()
		elif tipo == "aceite":
			arder()
		queue_free()
		return
	if tipo == "fuego":
		quemar(delta)
	elif tipo == "aceite":
		modulate.a = 1.0   # el aceite no se seca: arde
	else:
		if TIPOS[tipo].get("prende", false):
			prender_zombis(delta)
		if tipo == "hirviendo":
			hervir(delta)
		# Al final se va secando (más transparente)
		modulate.a = clampf(vida / 0.6, 0.0, 1.0)
	queue_redraw()
	var datos: Dictionary = TIPOS[tipo]
	var johnny := get_tree().get_first_node_in_group("jugador")
	if not datos.get("solo_zombis", false) and johnny and johnny.vivo and arde_en(johnny.global_position, johnny.RADIO * 0.3):
		johnny.pisar(datos.estados)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi != dueno and zombi.has_method("pisar") and arde_en(zombi.global_position, zombi.radio * 0.3):
			zombi.pisar(datos.estados)


# El charco es una elipse (más ancha que alta, porque el suelo se ve un poco desde arriba)
func dentro(punto: Vector2, margen: float) -> bool:
	var d := punto - global_position
	var r := radio() + margen
	return (d.x / r) ** 2 + (d.y / (r * 0.6)) ** 2 <= 1.0


# Si ahí se ve el charco: el fuego, solo donde ya ha llegado y aún no se ha apagado
func arde_en(punto: Vector2, margen: float) -> bool:
	if not dentro(punto, margen):
		return false
	if tipo != "fuego":
		return true
	var d := punto - global_position
	var k := Vector2(d.x, d.y / 0.6).length() / radio()
	var e := vida_max - vida
	return e >= k * EXTIENDE and vida > APAGA * k * 0.5


# ── El fuego ──

func hacer_fuego() -> void:
	var r := radio()
	var ondas := []
	for k in [3, 5, 7]:
		ondas.append([k, randf() * TAU, randf_range(0.05, 0.12)])
	var n := ceili(r / CELDA)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * CELDA
			var a := atan2(p.y / 0.6, p.x)
			var borde := 1.0
			for o in ondas:
				borde += sin(a * o[0] + o[1]) * o[2]
			var d := Vector2(p.x, p.y / 0.6).length() / r / borde
			var ruido := randf()
			if d > 1.0 or (d > 0.85 and ruido < 0.4):
				continue
			# prende del centro hacia fuera; se apaga a trozos, antes por los bordes
			var prende := d * EXTIENDE + ruido * 0.05
			var apaga := vida_max - APAGA * (1.0 - d * 0.6) * (0.5 + ruido * 0.5)
			celdas.append([p, d, prende, apaga, ruido])
	# las llamas, en sitios al azar (de atrás adelante, para que las de delante tapen a las de detrás)
	for i in 14:
		var c: Array = celdas.pick_random()
		if c[1] > 0.8:
			continue
		var grande: float = 1.0 - c[1]
		llamas.append([c[0].x + 2.0, c[0].y + 2.0, roundf(4 + grande * 5 + i % 2), roundf(6 + grande * 13 + (i % 3) * 2), randf() * 10.0, c[2], c[3]])
	llamas.sort_custom(func(a, b): return a[1] < b[1])
	for i in 24:
		ascuas.append(celdas.pick_random())


# Cada poco, prende a los zombis que estén dentro; y suelta chispas de donde aún arde
func quemar(delta: float) -> void:
	prender_zombis(delta)
	if randf() < 30.0 * delta:
		var a := randf() * TAU
		var r := sqrt(randf()) * radio() * 0.85
		var p := global_position + Vector2(cos(a) * r, sin(a) * r * 0.6)
		if arde_en(p, 0.0):
			Particulas.soltar(self, p, Vector2(randf_range(-10, 10), randf_range(-140, -70)), Llamas.FUEGO[randi() % 4], randf_range(1, 3), 0.45)


func prender_zombis(delta: float) -> void:
	tick += delta
	if tick >= Lanzables.MOLOTOV.tick:
		tick -= Lanzables.MOLOTOV.tick
		for zombi in get_tree().get_nodes_in_group("zombis"):
			if zombi == dueno or not arde_en(zombi.global_position, zombi.radio * 0.5):
				continue
			# el zombi se prende y la quemadura la lleva él: dentro se le renueva sin parar, y al salir sigue
			# ardiendo unos segundos. La portera no sabe arder: a ella se la quema solo dentro del fuego
			if zombi.has_method("prender"):
				zombi.prender(dano_lanzar)
			else:
				zombi.herir(Lanzables.MOLOTOV.quema * Lanzables.MOLOTOV.tick * dano_lanzar, Llamas.FUEGO[2])


# El aceite, al acabar, arde: en su sitio, un fuego como el del molotov (con su llamarada)
func arder() -> void:
	var fuego: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
	fuego.tipo = "fuego"
	fuego.escala = escala * ACEITE_ARDE
	fuego.duracion = duracion
	fuego.dano_lanzar = dano_lanzar
	fuego.dueno = dueno   # (a quien tiró el aceite, el científico jefe, tampoco le quema su fuego)
	fuego.position = position
	get_parent().add_child(fuego)
	Sonido.tocar("fuego")
	Luz.destello(get_parent(), global_position, radio() * 3.0, 0.3, 0.8)
	for i in 16:
		var a := randf() * TAU
		Particulas.soltar(self, global_position + Vector2(0, -6), Vector2(cos(a) * 160.0, sin(a) * 90.0 - 40.0), Llamas.FUEGO[i % 4],
			randf_range(2, 4), 0.5)


# Al apagarse del todo, la ceniza se queda en el suelo como una mancha más
func dejar_ceniza() -> void:
	var m := Mancha.new()
	m.position = position
	for c in celdas:
		m.celdas.append([c[0], Color("#1c120e", 0.7) if c[4] < 0.5 else Color("#2a1a14", 0.6)])
	get_parent().add_child(m)


# ── El aceite hirviendo del cocinero ──

# Su forma, en cuadraditos como el fuego (con el borde ondulado), y dónde salen las burbujas
func hacer_hirviendo() -> void:
	var r := radio()
	var ondas := []
	for k in [3, 5]:
		ondas.append([k, randf() * TAU, randf_range(0.06, 0.12)])
	var n := ceili(r / CELDA)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * CELDA
			var a := atan2(p.y / 0.6, p.x)
			var borde := 1.0
			for o in ondas:
				borde += sin(a * o[0] + o[1]) * o[2]
			var d := Vector2(p.x, p.y / 0.6).length() / r / borde
			if d <= 1.0:
				celdas.append([p, d, 0.0, 0.0, randf()])
	for i in 9:
		var c: Array = celdas.pick_random()
		if c[1] < 0.8:
			burbujas.append([c[0], randf() * 2.0, randf_range(0.7, 1.4)])


# Hierve: algo de vapor que sube
func hervir(delta: float) -> void:
	if randf() < 5.0 * delta:
		var a := randf() * TAU
		var r := sqrt(randf()) * radio() * 0.7
		Particulas.soltar(self, global_position + Vector2(cos(a) * r, sin(a) * r * 0.6), Vector2(randf_range(-8, 8), randf_range(-50, -30)),
			Color(1, 0.95, 0.85, 0.4), randf_range(3, 5), 0.7)


func pintar_hirviendo() -> void:
	var crece := minf(1.0, t / 0.25)   # al caer, se extiende en un momento
	for c in celdas:
		if c[1] > crece:
			continue
		var color := Color("#5e3510") if c[1] > 0.88 else Color("#9a5a16") if c[1] > 0.6 or c[4] < 0.25 else Color("#c07a22")
		if c[4] > 0.93:
			color = Color("#e8b04a")   # brillos
		draw_rect(Rect2(c[0], Vector2(CELDA, CELDA)), color)
	# las burbujas: crecen y revientan (un anillo claro), cada una a su ritmo
	for b in burbujas:
		var k: float = fmod(t + b[1], b[2]) / b[2]
		var p: Vector2 = b[0] + Vector2(2, 2)
		if k < 0.8:
			draw_circle(p, 1.0 + k * 4.0, Color("#f0c060"))
			draw_circle(p + Vector2(-1, -1), 1.0, Color("#fff1c4"))
		else:
			draw_arc(p, 6.0, 0.0, TAU, 10, Color("#fff1c4", 0.8), 1.5)


func _draw() -> void:
	if tipo == "hirviendo":
		pintar_hirviendo()
		return
	if tipo != "fuego":
		var datos: Dictionary = TIPOS[tipo]
		var dibujo: Texture2D = datos.dibujo
		# A escala 2, como todo el pixel art (estirarlo a su radio exacto deformaría los píxeles)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
		draw_texture(dibujo, -Vector2(dibujo.get_size()) / 2.0, datos.get("tinte", Color.WHITE))
		return
	var e := vida_max - vida
	for c in celdas:
		if e < c[2]:
			continue
		var color: Color
		if e >= c[3]:
			# ya apagado: brasa un momento y luego ceniza
			color = Color("#6e1d12") if e - c[3] < BRASA else (Color("#1c120e", 0.7) if c[4] < 0.5 else Color("#2a1a14", 0.6))
		elif e - c[2] < FRENTE:
			color = Llamas.FUEGO[0]   # el frente del fuego, recién prendido
		else:
			var d: float = c[1] + 0.12 * sin(t * 9.0 + c[4] * 20.0)   # el color tiembla un poco
			color = Llamas.FUEGO[1] if d < 0.3 else Llamas.FUEGO[2] if d < 0.55 else Llamas.FUEGO[3] if d < 0.8 else Llamas.FUEGO[4]
			color.a = 0.9
		draw_rect(Rect2(c[0], Vector2(CELDA, CELDA)), color)
	# ascuas: píxeles sueltos que se encienden y se apagan (solo donde arde)
	for i in ascuas.size():
		var c: Array = ascuas[i]
		if e < c[2] or e >= c[3]:
			continue
		var brillo := sin(t * (6 + i % 5) + i * 2.3)
		if brillo > 0.2:
			draw_rect(Rect2(c[0], Vector2(2, 2)), Llamas.FUEGO[0] if brillo > 0.7 else Llamas.FUEGO[1])
	# las llamas: cada una crece cuando le llega el fuego y se encoge antes de que se apague su trozo
	for m in llamas:
		var k: float = minf(1.0, minf((e - m[5]) / 0.25, (m[6] - e) / 0.5))
		if k > 0.0:
			Llamas.llama(self, m[0], m[1], m[2], m[3], t, m[4], k)
