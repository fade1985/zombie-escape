# Las cosas tiradas por el suelo con las que se tropieza (peligros.gd, TROPIEZOS): las mancuernas del gimnasio del
# Gymbro y los cubos del cuarto de la limpieza de la portera. Se reparten al generar la planta (Peligros.del_gymbro y
# Peligros.de_la_portera) y aquí se dibujan y se vigilan: si los pies de Johnny pasan por encima de una (sin rodar),
# se cae y tarda en levantarse (johnny.gd, caer), y la cosa sale rodando hacia donde iba él hasta que se para o
# choca con una pared o un mueble (el cubo, además, vuelca y salpica agua sucia). Dónde se queda se apunta en el
# sitio: al volver, sigue ahí. A los zombis y al jefe no les pasa nada.
# Cada cosa tiene su forma ("mancuerna": el mismo dibujo que las pesas que lanza el Gymbro, pesa.gd; "cubo": un cubo
# de fregar, dibujado aquí a cuadraditos). Para otra, basta con darle su tamaño en caja(), su dibujo en _draw() y su
# aviso en AVISOS.
extends Node2D

const RUEDA_T := 0.5      # lo que tarda en pararse la cosa que sale rodando
const PIES := 14.0        # los pies de Johnny, por debajo de su centro (donde apoya: su sombra)
# Lo que dice Johnny la primera vez que entra en la habitación
const AVISOS := {"mancuerna": "Cuidado con las mancuernas del suelo: si piso una, me la pego",
	"cubo": "Cuidado con los cubos del suelo: si tropiezo con uno, me la pego"}
# El cubo, píxel a píxel (cada letra, un píxel del dibujo; los colores en CUBO_COLORES): de pie, con el agua sucia
# (y su espuma) dentro y el asa a los lados, y volcado, con la boca hacia la derecha (hacia la izquierda, en espejo)
const CUBO_DE_PIE := [
	"   OOOOOOO   ",
	"  OLLLLLLLO  ",
	" OLWWSWWWWLO ",
	" OLWWWWWSWLO ",
	" HLLWWWWWLLH ",
	" OCLLLLLLLCO ",
	" OCCCCCCCCDO ",
	" ODDDDDDDDDO ",
	"  OCCCCCCDO  ",
	"  OCCCCCCDO  ",
	"  OCCCCCCDO  ",
	"   OOOOOOO   ",
]
const CUBO_VOLCADO := [
	"    OOOOOOOO  ",
	"  OOCCCCCCCLO ",
	" OCCCCCCDCLVLO",
	"OCCCCCCCDCLVLO",
	"ODCCCCCCDCLVLO",
	" ODDDDDDDDLVLO",
	"  OODDDDDDDLO ",
	"    OOOOOOOO  ",
]
# Los tres colores de cubo (cuerpo, sombra y brillo; vivos, para que se vean en la penumbra) y lo que tienen todos:
# contorno, agua, espuma, el hueco y el asa
const CUBO_COLORES := [[Color("#4a7fc0"), Color("#2f5688"), Color("#8fb6e0")],
	[Color("#b84a3e"), Color("#7e3329"), Color("#e08a7a")],
	[Color("#d4ad42"), Color("#977a2c"), Color("#f0d688")]]
const CUBO_FIJOS := {"O": Color("#1d1b2c"), "W": Color("#6b7a6e"), "S": Color("#a9b8aa"), "V": Color("#24262c"),
	"H": Color("#9aa0a8")}
const AGUA := Color("#6f7f6a")   # las gotas que salpica al volcar

var datos: Dictionary
var mapa: Node
var rodando := {}         # cosa que sale rodando (su índice) -> {desde, hasta, t}
var aviso := ""


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Tropiezos"
	z_index = -1   # en el suelo, como los charcos: los personajes pasan por encima
	light_mask = Luz.CAPA_SUELO   # la alumbra la linterna de Johnny, como al suelo
	aviso = AVISOS[datos.cosas[0].forma if not datos.cosas.is_empty() else "mancuerna"]


func _physics_process(delta: float) -> void:
	for i in rodando.keys():
		var r: Dictionary = rodando[i]
		r.t += delta
		var k := minf(1.0, r.t / RUEDA_T)
		# frena poco a poco, en píxeles enteros del dibujo
		datos.cosas[i].pos = (r.desde.lerp(r.hasta, 1.0 - (1.0 - k) * (1.0 - k)) / 2.0).round() * 2.0
		if k >= 1.0:
			rodando.erase(i)
		queue_redraw()
	var johnny := get_tree().get_first_node_in_group("jugador")
	if not johnny or not johnny.vivo:
		return
	if mapa.zona_en(johnny.global_position) == datos.sala:
		Peligros.avisar(self, datos, aviso)
	var pies: Vector2 = johnny.global_position + Vector2(0, PIES)
	for i in datos.cosas.size():
		if rodando.has(i) or not caja(datos.cosas[i]).grow(Peligros.TROPIEZOS.pie).has_point(pies):
			continue
		var iba: Vector2 = johnny.velocity
		if johnny.caer(Peligros.TROPIEZOS.caido):
			rodar(i, iba if iba.length() > 10.0 else datos.cosas[i].pos - pies)
		break


# Lo que ocupa una cosa en el suelo (la mancuerna: 14 × 8 píxeles del dibujo, tumbada a lo ancho o a lo largo; el
# cubo: 13 × 9 de pie y 14 × 8 volcado)
func caja(c: Dictionary) -> Rect2:
	var tam := Vector2(28, 16)
	if c.forma == "cubo":
		tam = Vector2(26, 18) if int(c.get("volcado", 0)) == 0 else Vector2(28, 16)
	elif absf(c.giro) > 0.1:
		tam = Vector2(tam.y, tam.x)
	return Rect2(c.pos - tam / 2.0, tam)


# La cosa del tropiezo sale rodando hacia donde iba Johnny (más lejos cuanto más rápido iba), hasta donde pueda
# llegar sin meterse en una pared o en un mueble
func rodar(i: int, hacia: Vector2) -> void:
	var desde: Vector2 = datos.cosas[i].pos
	var dir := hacia.normalized() if hacia != Vector2.ZERO else Vector2.RIGHT
	var largo: float = Peligros.TROPIEZOS.rueda * clampf(hacia.length() / 220.0, 0.5, 1.0)
	var hasta := desde
	var paso := 4.0
	while paso <= largo and cabe(desde + dir * paso):
		hasta = desde + dir * paso
		paso += 4.0
	rodando[i] = {"desde": desde, "hasta": hasta, "t": 0.0}
	var cosa: Dictionary = datos.cosas[i]
	if cosa.forma == "cubo":
		# vuelca hacia donde sale (con la boca por delante) y salpica el agua sucia que llevaba
		cosa.volcado = 1 if dir.x >= 0.0 else -1
		for k in 10:
			Particulas.soltar(self, desde, Vector2(randf_range(-80, 80) + dir.x * 50.0, randf_range(-70, -15)), AGUA, 3, 0.45)
		return
	for k in 6:
		Particulas.soltar(self, desde, Vector2(randf_range(-60, 60), randf_range(-50, -10)), Color("#8a7a66"), 3, 0.35)


# ¿Cabe ahí una cosa rodando? En el suelo de su sala, sin tocar las paredes ni los muebles
func cabe(p: Vector2) -> bool:
	for d in [Vector2(-14, -10), Vector2(14, -10), Vector2(-14, 10), Vector2(14, 10)]:
		if mapa.zona_en(p + d) != datos.sala:
			return false
	for m in mapa.sitio.muebles:
		if Muebles.hueco(m).grow(14.0).has_point(p):
			return false
	return true


func _draw() -> void:
	for c in datos.cosas:
		var p := to_local(c.pos)
		match c.forma:
			"mancuerna":
				# su sombra en el suelo y la mancuerna tumbada (la misma que lanza el Gymbro)
				draw_set_transform(p + Vector2(0, 5), 0.0, Vector2(1, 0.45))
				draw_circle(Vector2.ZERO, 17.0, Color(0, 0, 0, 0.3))
				Pesa.dibujar(self, p, c.giro)
			"cubo":
				draw_set_transform(p + Vector2(0, 6), 0.0, Vector2(1, 0.45))
				draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.3))
				draw_set_transform(Vector2.ZERO)
				dibujar_cubo(p, c)
	draw_set_transform(Vector2.ZERO)


# Un cubo a cuadraditos (CUBO_DE_PIE o CUBO_VOLCADO, en espejo si tiene la boca a la izquierda), con sus colores
func dibujar_cubo(p: Vector2, c: Dictionary) -> void:
	var volcado := int(c.get("volcado", 0))
	var filas: Array = CUBO_DE_PIE if volcado == 0 else CUBO_VOLCADO
	var tonos: Array = CUBO_COLORES[int(c.get("color", 0)) % CUBO_COLORES.size()]
	var colores := CUBO_FIJOS.merged({"C": tonos[0], "D": tonos[1], "L": tonos[2]})
	var ancho: int = filas[0].length()
	var origen := p + (Vector2(-12, -16) if volcado == 0 else Vector2(-14, -8))
	for f in filas.size():
		var fila: String = filas[f]
		for i in ancho:
			var letra := fila[i] if volcado >= 0 else fila[ancho - 1 - i]
			if letra != " ":
				draw_rect(Rect2(origen + Vector2(i, f) * 2.0, Vector2(2, 2)), colores[letra])
