# El cerco de fuego de la habitación del jefe de bomberos (peligros.gd, CERCO): una franja que arde siempre, pegada a
# las paredes y repartida como la porquería del Glotón (en medio, un óvalo limpio donde se pelea), menos delante de
# la puerta de entrada. Se decide al generar la planta (Peligros.del_bombero: qué casillas arden) y aquí se dibuja y
# quema. Así no se puede huir del giro con el lanzallamas (bombero.gd) arrimándose a la pared: la lengua llega hasta
# ella y el borde está ardiendo.
#
# Quema como el fuego de la cocina (fuego.gd): a Johnny le pone el estado "fuego" (sigue ardiendo un poco al salir;
# la esquiva lo cruza sin daño, como los charcos) y a los zombis despiertos los prende (al bombero no le hace nada y
# no se le prende: si no, gritaría «¡INMUNE!» sin parar al pisarlo). Se dibuja como él, a cuadraditos de pixel art,
# pero la franja es mucho más grande, así que, como la porquería del Glotón (porqueria.gd), lo que no cambia se pinta
# una vez (el nodo "Suelo") y aparte, repintándose y solo lo que se ve en pantalla, las celdas que tiemblan y las
# llamas. Contra la pared no se deshilacha (el fuego llega hasta ella); hacia dentro de la sala, sí. Y alumbra:
# unas luces de fuego repartidas por el borde del óvalo, sin sombras (la habitación es una sola), que tiemblan.
extends Node2D

const CASILLA := 32
const CELDA := 4.0                  # 2 píxeles del dibujo, como el fuego de la cocina
const BORDE := 12.0                 # el borde deshilachado, en unidades (como en fuego.gd)
const PINTA := 1.0 / 15.0           # cada cuánto se repintan las llamas y las celdas que tiemblan
const TEXTURA := preload("res://escenas/luces/luz_suave.tres")
const LUZ_RADIO := 300.0
const LUZ_FUERZA := 0.85

var datos: Dictionary
var mapa: Node
var suelo: Node2D                   # lo que no cambia, pintado una vez
var ruido := {}                     # casilla -> [64 números al azar, siempre los mismos para esa casilla]
var fin := {}                       # casilla -> hacia qué lados se acaba el fuego (izquierda, derecha, arriba, abajo)
var luces: Array = []
var t := 0.0
var tick := 0.0
var pinta := 0.0


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Cerco"
	z_index = -1   # en el suelo, como el fuego de la cocina
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # el fuego luce por sí mismo
	material = propio
	# hacia qué lados se acaba: donde la de al lado es suelo sin fuego (contra la pared, no: llega hasta ella)
	var apt: Dictionary = mapa.sitio.apt
	for c in datos.casillas:
		var lados := []
		for l in Peligros.LADOS:
			var v: Vector2i = c + l
			lados.append(not datos.casillas.has(v) and Peligros.dueno(apt, v.x, v.y) >= 0)
		fin[c] = lados
	suelo = Node2D.new()
	suelo.name = "Suelo"
	suelo.use_parent_material = true
	suelo.show_behind_parent = true   # lo fijo debajo; lo que tiembla y las llamas (el _draw de este nodo), encima
	suelo.draw.connect(pintar_suelo)
	add_child(suelo)
	# las luces: CERCO.luces repartidas por el borde del óvalo limpio, como las de la porquería (Peligros.luces_del_ovalo)
	for c in Peligros.luces_del_ovalo(datos, Peligros.CERCO.luces):
		luz_de_fuego(Peligros.centro(c))


# Una luz de fuego, naranja, sin sombras (como las del resplandor de la porquería): alumbra el suelo y lo que hay en
# la habitación
func luz_de_fuego(donde: Vector2) -> void:
	var l := PointLight2D.new()
	l.texture = TEXTURA
	l.texture_scale = LUZ_RADIO / 128.0
	l.color = Color(1.0, 0.47, 0.16)
	l.range_item_cull_mask = Luz.CAPA_SUELO | Luz.CAPA_COSAS | Luz.capa_sala(datos.sala)
	l.position = donde
	add_child(l)
	luces.append(l)


func _physics_process(delta: float) -> void:
	t += delta
	# las luces tiemblan, como las del fuego de la cocina
	for i in luces.size():
		luces[i].energy = LUZ_FUERZA * (0.82 + 0.1 * sin(t * 11.0 + i * 7.0) + 0.08 * sin(t * 23.7 + i * 3.0)) * Luz.fuerza()
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo:
		if mapa.zona_en(johnny.global_position) == datos.sala:
			Peligros.avisar(self, datos, "¡La habitación está en llamas! Lejos de las paredes")
		if datos.casillas.has(Peligros.casilla(johnny.global_position)):
			johnny.pisar({"fuego": {"dps": Peligros.CERCO.dps}})
	# cada poco, prende a los zombis despiertos que estén dentro (como el charco de fuego del molotov)
	tick += delta
	if tick >= Lanzables.MOLOTOV.tick:
		tick -= Lanzables.MOLOTOV.tick
		for zombi in get_tree().get_nodes_in_group("zombis"):
			if zombi.get("dormido") or zombi.get("inmune_fuego") or not datos.casillas.has(Peligros.casilla(zombi.global_position)):
				continue
			if zombi.has_method("prender"):
				zombi.prender()
			else:
				zombi.herir(Lanzables.MOLOTOV.quema * Lanzables.MOLOTOV.tick, Llamas.FUEGO[2])
	# lo de fuera solo si la habitación ya se ha descubierto (las chispas y el humo van por encima de la niebla)
	var visto: bool = mapa.niebla.get(datos.sala, 0.0) < 0.5
	if visto and not datos.casillas.is_empty():
		if randf() < 30.0 * delta:
			var p := Peligros.centro(datos.casillas.keys().pick_random()) + Vector2(randf_range(-14, 14), randf_range(-14, 10))
			Particulas.soltar(self, p, Vector2(randf_range(-10, 10), randf_range(-140, -70)), Llamas.FUEGO[randi() % 4], randf_range(1, 3), 0.45)
		if randf() < 6.0 * delta:
			var p := Peligros.centro(datos.casillas.keys().pick_random()) + Vector2(randf_range(-10, 10), -randf_range(10, 30))
			Particulas.soltar(self, p, Vector2(randf_range(-12, 12), randf_range(-50, -30)), Color(0.13, 0.11, 0.11, 0.5), randf_range(4, 7), 1.3)
	pinta -= delta
	if pinta <= 0.0 and mapa.niebla.get(datos.sala, 0.0) < 0.98:
		pinta = PINTA
		queue_redraw()


# El ruido de cada casilla (siempre el mismo para esa casilla), como en fuego.gd
func ruido_de(c: Vector2i) -> Array:
	if not ruido.has(c):
		var r := RandomNumberGenerator.new()
		r.seed = hash(c)
		var lista := []
		for i in 64:
			lista.append(r.randf())
		ruido[c] = lista
	return ruido[c]


# Lo que le falta a la celda "p" (dentro de su casilla) para llegar a un lado donde se acaba el fuego (en unidades)
func hondo_de(lados: Array, p: Vector2) -> float:
	var hondo := 99.0
	if lados[0]: hondo = minf(hondo, p.x)
	if lados[1]: hondo = minf(hondo, CASILLA - CELDA - p.x)
	if lados[2]: hondo = minf(hondo, p.y)
	if lados[3]: hondo = minf(hondo, CASILLA - CELDA - p.y)
	return hondo


# El color del fuego a "hondo" unidades del borde: rojo en el borde, amarillo más adentro (como en fuego.gd)
func color_de(hondo: float, temblor: float) -> Color:
	var calor := clampf(hondo / 16.0, 0.0, 1.0) + temblor
	var color: Color = Llamas.FUEGO[1] if calor > 0.85 else Llamas.FUEGO[2] if calor > 0.5 else Llamas.FUEGO[3] if calor > 0.25 else Llamas.FUEGO[4]
	color.a = 0.9
	return color


# Lo fijo: cada casilla que arde, entera (naranja); donde se acaba, a celdas, con el borde deshilachado y rojo. Se
# pinta una sola vez
func pintar_suelo() -> void:
	for c in datos.casillas:
		var o := Vector2(c) * CASILLA
		var lados: Array = fin[c]
		if not lados.has(true):
			suelo.draw_rect(Rect2(o, Vector2(CASILLA, CASILLA)), Color(Llamas.FUEGO[2], 0.9))
			continue
		var r := ruido_de(c)
		for i in 64:
			var p := Vector2(i % 8, i / 8) * CELDA
			var hondo := hondo_de(lados, p)
			if hondo + r[i] * 10.0 < 5.0:
				continue
			suelo.draw_rect(Rect2(o + p, Vector2(CELDA, CELDA)), color_de(hondo, 0.0))


# Lo que se mueve, solo en lo que se ve en pantalla: unas celdas de cada casilla que tiemblan (más claras o más
# oscuras) y una llama en la mitad de las casillas (siempre en las mismas), más alta cuanto más metida en el fuego
func _draw() -> void:
	var vista := (get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()).grow(CASILLA * 2.0)
	var llamas := []
	for c in datos.casillas:
		var o := Vector2(c) * CASILLA
		if not vista.has_point(o):
			continue
		var r := ruido_de(c)
		var lados: Array = fin[c]
		for i in 6:
			var k := int(r[i] * 64.0)
			var p := Vector2(k % 8, k / 8) * CELDA
			var hondo := hondo_de(lados, p)
			if hondo + r[k] * 10.0 < 5.0:
				continue
			var s := sin(t * 9.0 + r[k] * 20.0)
			if absf(s) > 0.3:
				draw_rect(Rect2(o + p, Vector2(CELDA, CELDA)), color_de(hondo, 0.25 * s) if lados.has(true) else
					Color(Llamas.FUEGO[1] if s > 0.0 else Llamas.FUEGO[3], 0.9))
		if r[0] < 0.55:
			var metida := 1.0 - lados.count(true) / 4.0
			llamas.append([o.x + 8.0 + r[1] * 16.0, o.y + 18.0 + r[2] * 10.0, roundf(4 + metida * 3), roundf(7 + metida * 9 + r[3] * 4), r[4] * 10.0])
	llamas.sort_custom(func(a, b): return a[1] < b[1])
	for l in llamas:
		Llamas.llama(self, l[0], l[1], l[2], l[3], t, l[4])
