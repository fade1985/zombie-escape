# La porquería del Glotón (peligros.gd, PORQUERIA): su habitación no tiene más muebles que unas lámparas y, pegada a
# las paredes, una franja de charcos de diarrea y montones de mierda con ácido (en medio, un óvalo limpio donde se pelea), salpicada
# también por las paredes. Se decide al generar la planta (Peligros.del_gloton: qué casillas están sucias y cuáles
# llevan montón) y aquí se dibuja y quema: a Johnny le pone
# el estado "porqueria" (estados.gd) mientras la pisa (la esquiva la cruza sin daño, como los charcos); a los zombis
# no les hace nada (es del Glotón). Se dibuja a cuadraditos de pixel art como el fuego de la cocina (fuego.gd): cada
# casilla sucia entera, con el borde deshilachado donde se acaba, y encima los montones; eso se pinta una vez
# (el nodo "Suelo") y aparte, repintándose, las burbujas de ácido que revientan y las moscas sobre los montones.
# Las salpicaduras de la pared de arriba son texturas hechas aquí mismo (salpicon), puestas como adornos de las caras
# de muro (cara_pared.gd), como los restos del centro comercial; en los lomos de los otros tres muros, que se ven
# desde arriba, van pegotes a celdas (pegote). Y el ácido reluce (luz_de_acido): con las lámparas, luz de sobra.
extends Node2D

const CASILLA := 32
const CELDA := 4.0                  # 2 píxeles del dibujo
const BORDE := 10.0                 # el borde deshilachado de cada charco, en unidades
const PINTA := 1.0 / 12.0           # cada cuánto se repintan las burbujas y las moscas
# Los colores: la diarrea (el charco: borde, medio y claro), la mierda (el montón: contorno, oscuro, medio y brillo),
# el ácido y las moscas
const CHARCO := [Color("#4a4412"), Color("#6b661a"), Color("#8a8626")]   # (oliva: que se distinga de la madera del suelo)
const MONTON := [Color("#2e1d0c"), Color("#4a2f12"), Color("#6b4a1f"), Color("#8a6a3a")]
const ACIDO := Color("#b5d634")
const ACIDO_OSCURO := Color("#7e9a1c")
const MOSCA := Color("#15100c")
# El resplandor del ácido: unas luces verdosas suaves repartidas por la franja (como las del fuego de la cocina, sin
# sombras), que laten despacio; con ellas y las lámparas de pie se ve bien dónde pisar
const TEXTURA := preload("res://escenas/luces/luz_suave.tres")
const LUCES := 8                    # cuántas, repartidas por el borde del óvalo limpio
const LUZ_RADIO := 380.0            # (llegan hasta el medio de la zona de pelea)
const LUZ_COLOR := Color(0.62, 0.86, 0.38)
const LUZ_FUERZA := 0.5

var datos: Dictionary
var mapa: Node
var suelo: Node2D                   # lo que no cambia (charcos y montones), pintado una vez
var ruido := {}                     # casilla -> [64 números al azar, siempre los mismos para esa casilla]
var moscas: Array = []              # [casilla del montón, fase] de cada mosca que zumba
var luces: Array = []               # las del resplandor del ácido
var t := 0.0
var pinta := 0.0


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Porqueria"
	z_index = -2   # en el suelo, por debajo de los charcos (que se le echen encima), como las manchas
	light_mask = Luz.CAPA_SUELO   # la alumbra la linterna de Johnny, como al suelo (y sus propias luces)
	suelo = Node2D.new()
	suelo.name = "Suelo"
	suelo.light_mask = Luz.CAPA_SUELO
	suelo.show_behind_parent = true   # lo fijo debajo; las burbujas y las moscas (el _draw de este nodo), encima
	suelo.draw.connect(pintar_suelo)
	add_child(suelo)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(mapa.sitio.get("surtido", 0)) + 911   # al volver, las mismas moscas y salpicaduras
	for c in datos.casillas:
		if datos.casillas[c] == 2 and rng.randf() < 0.5:
			moscas.append([c, rng.randf() * TAU])
	# las salpicaduras de la pared de la habitación: unas cuantas por cara, de las que gotean
	for cara in mapa.caras.get(datos.sala, []):
		cara.adornos += salpicones(cara.ancho, rng)
		cara.queue_redraw()
	for c in focos_de_luz():
		luz_de_acido(Peligros.centro(c))


# Dónde va cada luz del resplandor: LUCES puntos repartidos por el borde del óvalo limpio (la franja sucia empieza
# ahí), cada uno en la casilla sucia más cercana; así alumbran la franja y, hacia dentro, la zona de pelea
func focos_de_luz() -> Array:
	var ov: Dictionary = datos.ovalo
	var focos := []
	for i in LUCES:
		var a := i * TAU / LUCES
		var meta: Vector2 = ov.centro + Vector2(cos(a) * ov.rx, sin(a) * ov.ry)
		var mejor := Vector2i(-1, -1)
		var cerca := 4.0   # como mucho a 4 casillas del punto
		for c in datos.casillas:
			var d: float = (Vector2(c) + Vector2(0.5, 0.5)).distance_to(meta)
			if d < cerca:
				cerca = d
				mejor = c
		if mejor != Vector2i(-1, -1) and not mejor in focos:
			focos.append(mejor)
	return focos


# Una luz del resplandor: suave, verdosa y sin sombras (la habitación es una sola: no hay a quién colarse), que
# alumbra el suelo y lo que hay en él
func luz_de_acido(donde: Vector2) -> void:
	var l := PointLight2D.new()
	l.texture = TEXTURA
	l.texture_scale = LUZ_RADIO / 128.0
	l.color = LUZ_COLOR
	l.range_item_cull_mask = Luz.CAPA_SUELO | Luz.CAPA_COSAS | Luz.capa_sala(datos.sala)
	l.position = donde
	add_child(l)
	luces.append(l)


func _physics_process(delta: float) -> void:
	t += delta
	# el resplandor late despacio, cada luz a su ritmo
	for i in luces.size():
		luces[i].energy = LUZ_FUERZA * (0.88 + 0.12 * sin(t * 1.3 + i * 2.1)) * Luz.fuerza()
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo:
		if mapa.zona_en(johnny.global_position) == datos.sala:
			Peligros.avisar(self, datos, "¡Qué peste! El suelo está lleno de mierda con ácido: no la pises")
		if datos.casillas.has(Peligros.casilla(johnny.global_position)):
			johnny.pisar({"porqueria": {"dps": Peligros.PORQUERIA.dps, "despues": Peligros.PORQUERIA.despues}})
	# lo de fuera solo si la habitación ya se ha descubierto: de vez en cuando, el chisporroteo de una burbuja de ácido
	var visto: bool = mapa.niebla.get(datos.sala, 0.0) < 0.5
	if visto and not datos.casillas.is_empty() and randf() < 4.0 * delta:
		var c: Vector2i = datos.casillas.keys().pick_random()
		var p := Peligros.centro(c) + Vector2(randf_range(-12, 12), randf_range(-10, 10))
		for i in 3:
			Particulas.soltar(self, p, Vector2(randf_range(-20, 20), randf_range(-45, -20)), ACIDO if i < 2 else ACIDO_OSCURO,
				randf_range(1, 2.5), 0.35)
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


# Los charcos (cada casilla sucia entera; donde se acaban, el borde a celdas deshilachado con el ruido) y, encima,
# los montones. Se pinta una sola vez
func pintar_suelo() -> void:
	for c in datos.casillas:
		var r := ruido_de(c)
		var o := Vector2(c) * CASILLA
		# hacia qué lados se acaba el charco (ahí el borde se deshilacha y se oscurece)
		var fin := []
		for d in Peligros.LADOS:
			fin.append(not datos.casillas.has(c + d))
		if not fin.has(true):
			suelo.draw_rect(Rect2(o, Vector2(CASILLA, CASILLA)), CHARCO[1])
			# algo de textura: unas celdas más claras, más oscuras y de ácido sueltas, siempre las mismas
			for i in 6:
				var k := int(r[i] * 64.0)
				suelo.draw_rect(Rect2(o + Vector2(k % 8, k / 8) * CELDA, Vector2(CELDA, CELDA)),
					CHARCO[2] if i < 2 else (CHARCO[0] if i < 4 else ACIDO_OSCURO))
			continue
		for i in 64:
			var p := Vector2(i % 8, i / 8) * CELDA
			# lo que le falta a la celda para llegar al borde que se acaba (en unidades)
			var hondo := 99.0
			if fin[0]: hondo = minf(hondo, p.x)
			if fin[1]: hondo = minf(hondo, CASILLA - CELDA - p.x)
			if fin[2]: hondo = minf(hondo, p.y)
			if fin[3]: hondo = minf(hondo, CASILLA - CELDA - p.y)
			if hondo + r[i] * BORDE < 5.0:
				continue
			suelo.draw_rect(Rect2(o + p, Vector2(CELDA, CELDA)), CHARCO[0] if hondo < CELDA * 1.5 else CHARCO[1])
	for c in datos.casillas:
		if datos.casillas[c] != 2:
			continue
		var r := ruido_de(c)
		# un poco descentrado en su casilla, y en celdas enteras para que case con el resto del dibujo
		var o: Vector2 = ((Peligros.centro(c) + Vector2(r[10] - 0.5, r[11] - 0.5) * 8.0) / CELDA).round() * CELDA
		monton(o, r)
	# los pegotes de los lomos de los muros (este nodo va por encima de las tapas de los muros, que están a z -10)
	for c in datos.get("paredes", {}):
		pegote(c, ruido_de(c), datos.paredes[c])


# Un pegote de mierda en el lomo de un muro, visto desde arriba: un racimo de celdas, con alguna del borde más
# oscura, otra de diarrea y una mota de ácido. "forma" (0 a 2) lo hace más grande
func pegote(c: Vector2i, r: Array, forma: int) -> void:
	var o: Vector2 = (Vector2(c) * CASILLA + Vector2(6.0 + r[30] * 16.0, 6.0 + r[31] * 16.0)).snapped(Vector2(CELDA, CELDA))
	var celdas := 6 + forma * 2
	for i in celdas:
		var p := o + Vector2(roundf((r[32 + i] - 0.5) * 4.0), roundf((r[40 + i] - 0.5) * 3.0)) * CELDA
		var color: Color = MONTON[2]
		if r[48 + i] < 0.3:
			color = MONTON[1]
		elif r[48 + i] > 0.85:
			color = CHARCO[1]
		suelo.draw_rect(Rect2(p, Vector2(CELDA, CELDA)), color)
	suelo.draw_rect(Rect2(o, Vector2(CELDA, CELDA)), ACIDO_OSCURO if r[56] < 0.5 else MONTON[3])


# Un montón de mierda: una pila redondeada (más ancha que alta), con su contorno, la sombra abajo a la derecha, el
# brillo arriba a la izquierda y el pico de arriba
func monton(o: Vector2, r: Array) -> void:
	var rx: float = 10.0 + r[12] * 4.0
	var ry: float = 6.0 + r[13] * 3.0
	var n := ceili(rx / CELDA) + 1
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * CELDA
			var centro := p + Vector2(CELDA, CELDA) / 2.0
			var d := Vector2(centro.x / rx, centro.y / ry).length()
			if d > 1.0:
				continue
			var color: Color = MONTON[2]
			if d > 0.78:
				color = MONTON[0]
			elif centro.x < -rx * 0.15 and centro.y < -ry * 0.1 and d < 0.6:
				color = MONTON[3] if d < 0.35 else MONTON[2]
			elif centro.x > 0.0 and centro.y > 0.0:
				color = MONTON[1]
			suelo.draw_rect(Rect2(o + p, Vector2(CELDA, CELDA)), color)
	suelo.draw_rect(Rect2(o + Vector2(-CELDA / 2.0, -ry - CELDA), Vector2(CELDA, CELDA)), MONTON[1])
	suelo.draw_rect(Rect2(o + Vector2(-CELDA / 2.0, -ry - CELDA * 2.0), Vector2(CELDA, CELDA)), MONTON[0])
	suelo.draw_rect(Rect2(o + Vector2(CELDA / 2.0, -ry - CELDA * 2.0), Vector2(CELDA, CELDA)), MONTON[0])


# Lo que se mueve: en un tercio de los charcos, una burbuja de ácido que crece y revienta (siempre en el mismo sitio
# de su casilla), y las moscas dando vueltas sobre los montones
func _draw() -> void:
	for c in datos.casillas:
		var r := ruido_de(c)
		if r[24] > 0.33:
			continue
		var ciclo := fmod(t * (0.25 + r[20] * 0.2) + r[21] * 10.0, 1.0)
		if ciclo > 0.3:
			continue
		var k := ciclo / 0.3   # de 0 a 1: crece y revienta
		var p := Vector2(c) * CASILLA + Vector2(int(r[22] * 5.0) + 1, int(r[23] * 5.0) + 1) * CELDA
		if k < 0.7:
			draw_rect(Rect2(p, Vector2(CELDA, CELDA)), ACIDO_OSCURO)
			if k > 0.3:
				draw_rect(Rect2(p + Vector2(CELDA, 0), Vector2(CELDA, CELDA)), ACIDO)
		else:
			for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
				draw_rect(Rect2(p + d * CELDA, Vector2(CELDA, CELDA)), ACIDO)
	for m in moscas:
		var o: Vector2 = Peligros.centro(m[0])
		var p := o + Vector2(cos(t * 2.3 + m[1]) * 12.0, sin(t * 3.7 + m[1] * 2.0) * 4.0 - 16.0)
		p = (p / 2.0).floor() * 2.0
		draw_rect(Rect2(p, Vector2(2, 2)), MOSCA)
		draw_rect(Rect2(p + Vector2(-2, 0), Vector2(2, 2)), Color(MOSCA, 0.5))


# Las salpicaduras de una cara de muro de "ancho" unidades: [{dibujo, x, y}] en píxeles del dibujo desde la esquina
# de abajo a la izquierda (como mapa.restos_de_pared), más o menos una por cada tramo de 3 casillas
static func salpicones(ancho: float, rng: RandomNumberGenerator) -> Array:
	var lista := []
	var tramo := 48.0   # 96 unidades, en píxeles del dibujo
	var tramos := floori(ancho / 2.0 / tramo)
	for i in tramos:
		if rng.randf() > 0.7:
			continue
		var tex := salpicon(rng)
		var x := i * tramo + rng.randf_range(0.0, maxf(0.0, tramo - tex.get_width()))
		var y := -rng.randf_range(minf(tex.get_height() + 6.0, 46.0), 46.0)   # sin pisar el rodapié ni la moldura
		lista.append({"dibujo": tex, "x": floorf(x), "y": floorf(y)})
	return lista


# Una salpicadura de mierda que gotea: un pegote arriba (con su brillo) y dos o tres chorretones hacia abajo
static func salpicon(rng: RandomNumberGenerator) -> ImageTexture:
	var w := rng.randi_range(14, 22)
	var h := rng.randi_range(16, 28)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)   # (empieza transparente)
	var cx := w / 2.0
	var cy := h * 0.3
	var rx := w * 0.42
	var ry := h * 0.22
	var fase := rng.randf() * TAU
	for y in h:
		for x in w:
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			var a := atan2(dy, dx)
			var d := Vector2(dx, dy).length() / (1.0 + 0.18 * sin(a * 5.0 + fase) + 0.1 * sin(a * 9.0 - fase))
			if d > 1.0:
				continue
			var color: Color = MONTON[1] if d > 0.72 else MONTON[2]
			if dx < -0.2 and dy < -0.3 and d < 0.6:
				color = MONTON[3]
			elif d < 0.8 and (x * 7 + y * 3) % 11 == 0:
				color = ACIDO_OSCURO   # alguna mota de ácido
			img.set_pixel(x, y, color)
	for i in rng.randi_range(2, 3):
		var x := clampi(roundi(cx + rng.randf_range(-rx * 0.7, rx * 0.7)), 0, w - 1)
		var y0 := int(cy + ry * 0.6)
		var largo := rng.randi_range(4, maxi(4, h - y0 - 1))
		for k in largo:
			var y := y0 + k
			if y >= h:
				break
			img.set_pixel(x, y, MONTON[2] if k < largo - 1 else MONTON[3])   # la gota del final, con brillo
			if k < largo / 2 and x + 1 < w:
				img.set_pixel(x + 1, y, MONTON[1])
	return ImageTexture.create_from_image(img)
