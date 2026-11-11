# El agua con corriente de la tienda de electrónica (peligros.gd): un charco grande en la sala de venta con un
# cable pelado dentro. Mientras hay corriente, cada "pulso" da un calambrazo a todo el charco: a Johnny le quita
# vida y lo deja tieso un momento (el estado "calambre", estados.gd), y a los zombis despiertos los hiere y los
# aturde, así que se quedan dentro y les vuelve a dar.
#
# La corriente es la de toda la tienda: con ella, las estanterías de teles dan luz y la tienda está más clara que
# un piso; en el cuadro eléctrico (cuadro.gd) se baja la palanca y el agua deja de hacer daño, pero la tienda se
# queda a oscuras (solo se ve con la linterna). Se puede volver a subir: atraes a la horda al agua y das la luz.
# Si el técnico la arregla (su rescate, averia.gd), el cable queda empalmado con cinta aislante y el agua ya no da
# calambres nunca más ("arreglado"); la corriente sigue siendo la de la luz de la tienda.
#
# Se dibuja todo con código: el charco (de una vez, con su borde irregular), los brillos que se mueven, las
# chispitas sobre el agua, los rayos de cada calambrazo y el cable, que baja por la pared y llega hasta el agua.
extends Node2D

const CASILLA := 32
const LAMPARA := preload("res://escenas/luces/lampara.tscn")
const RAYO := Color("#9fe8ff")
const CABLE := Color("#16171b")
const COBRE := Color("#d9873f")
const TELE := Color(0.55, 0.75, 1.0)

var datos: Dictionary
var mapa: Node
var mojado := {}             # las casillas del charco
var charco: Node2D           # el dibujo del agua (se pinta una vez)
var chispas: Node2D          # lo eléctrico: luce por sí mismo
var cuadro: Node2D
var pared: Node2D            # el cable que baja por la pared
var teles: Array = []        # las luces de las estanterías de teles
var luz_cable: PointLight2D
var brillos: Array = []      # [casilla, x, y, semilla]
var rayos: Array = []        # cada uno, una lista de puntos; se ven mientras "destello" > 0
var punta: Vector2           # la punta pelada del cable
var t := 0.0
var pulso := 0.0
var destello := 0.0
var textura: ImageTexture   # el dibujo del charco (hacer_textura)
var pixeles: Image
var esquina: Vector2        # dónde empieza la imagen


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Agua"   # no-tr (nombre de nodo)
	z_index = -1
	light_mask = Luz.CAPA_SUELO   # lo alumbran las luces del suelo (la linterna, las teles)
	for c in d.casillas:
		mojado[c] = true
	punta = Peligros.centro(d.cable) + Vector2(-6, 2)
	charco = Node2D.new()
	charco.name = "Charco"
	charco.light_mask = Luz.CAPA_SUELO
	charco.draw.connect(dibujar_charco)
	add_child(charco)
	chispas = Node2D.new()
	chispas.name = "Chispas"
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	chispas.material = propio
	chispas.draw.connect(dibujar_chispas)
	add_child(chispas)
	for i in maxi(16, d.casillas.size()):
		brillos.append([d.casillas.pick_random(), randf_range(4, 24), randf_range(4, 28), randf() * TAU])
	# lo que va en la pared: el cable que baja hasta el suelo, y el cuadro eléctrico
	pared = Node2D.new()
	pared.name = "CablePared"
	pared.position = d.cable_desde + Vector2(0, 1)
	pared.draw.connect(dibujar_cable_pared.bind(pared))
	m.cosas.add_child(pared)
	cuadro = preload("res://scripts/peligros/cuadro.gd").new()
	cuadro.montar(d.cuadro, self, m)
	m.cosas.add_child(cuadro)
	# la lucecita azul de la punta del cable
	luz_cable = PointLight2D.new()
	luz_cable.texture = preload("res://escenas/luces/luz_suave.tres")
	luz_cable.texture_scale = 110.0 / 128.0
	luz_cable.color = RAYO
	luz_cable.range_item_cull_mask = Luz.CAPA_SUELO | Luz.CAPA_COSAS | Luz.capa_sala(0)
	luz_cable.position = punta
	add_child(luz_cable)
	poner_teles()
	encender(d.corriente, false)


func _enter_tree() -> void:   # (también al volver a un mapa guardado)
	Luz.extra = Peligros.AGUA.oscuro_con if datos.corriente else Peligros.AGUA.oscuro_sin


func _exit_tree() -> void:
	Luz.extra = 0.0


# Las estanterías de teles de la sala de venta (unas pocas, repartidas) dan una luz azulada que parpadea
func poner_teles() -> void:
	var lista: Array = mapa.muebles.filter(func(mueble): return mueble.datos.tipo == "tvshelf" and mueble.zona == 0)
	lista.sort_custom(func(a, b): return a.position.x < b.position.x)
	var n := mini(Peligros.AGUA.teles, lista.size())
	for i in n:
		var mueble: Node2D = lista[int((i + 0.5) * lista.size() / n)]
		var luz := LAMPARA.instantiate()
		luz.parpadea = true
		luz.semilla = fposmod(mueble.position.x * 0.0137, 1.0)
		luz.radio = 170.0
		luz.alto = 40.0
		luz.suelo = Vector2(0, 26)   # delante de la estantería (dentro de su hueco, su sombra lo taparía)
		luz.mapa = mapa
		luz.zona = 0
		luz.get_node("Bombilla").visible = false
		for nombre in ["LuzSuelo", "LuzCosas"]:   # no-tr (nombres de nodo)
			luz.get_node(nombre).color = TELE
		luz.get_node("LuzCosas").range_item_cull_mask = Luz.CAPA_COSAS | Luz.capa_sala(0)
		mueble.add_child(luz)
		luz.get_node("Polvo").visible = false
		teles.append(luz)


# Con corriente o sin ella: el agua, las teles, la luz del cable y lo oscura que está la tienda
func encender(si: bool, avisar := true) -> void:
	datos.corriente = si
	for luz in teles:
		luz.fuerza = 0.8 if si else 0.0
	luz_cable.visible = si and not datos.get("arreglado", false)
	Luz.extra = Peligros.AGUA.oscuro_con if si else Peligros.AGUA.oscuro_sin
	pulso = 0.0
	if avisar:
		Sonido.tocar("encendido" if si else "apagon")
		var partida := get_tree().current_scene
		if partida and partida.has_method("decir"):
			partida.decir(Idioma.t("¡Ha vuelto la corriente!") if si else Idioma.t("¡Clac! Se ha ido la luz de la tienda"))


func cambiar_corriente() -> void:
	encender(not datos.corriente)


# El técnico ha arreglado el cable (averia.gd): ya no hay calambres ni chispas, y se ve el empalme
func arreglar() -> void:
	datos.arreglado = true
	luz_cable.visible = false
	destello = 0.0
	charco.queue_redraw()
	pared.queue_redraw()


func en_agua(p: Vector2) -> bool:
	return mojado.has(Peligros.casilla(p))


func _physics_process(delta: float) -> void:
	t += delta
	destello = maxf(0.0, destello - delta)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if datos.corriente and not datos.get("arreglado", false):
		if johnny and johnny.vivo and cerca(johnny.global_position, 90.0):
			Peligros.avisar(self, datos, Idioma.t("¡Ojo! El agua tiene corriente"))
		pulso += delta
		if pulso >= Peligros.AGUA.pulso:
			pulso -= Peligros.AGUA.pulso
			calambrazo(johnny)
		# la punta del cable chisporrotea
		if randf() < 9.0 * delta:
			var a := randf() * TAU
			Particulas.soltar(self, punta + Vector2(randf_range(-3, 3), -randf_range(0, 6)), Vector2(cos(a), sin(a) - 0.6) * randf_range(40, 110),
				Color.WHITE if randf() < 0.4 else RAYO, 2, randf_range(0.15, 0.3))
			if johnny and johnny.global_position.distance_to(punta) < 260.0 and randf() < 0.3:
				Sonido.tocar("chispa")
		luz_cable.energy = (0.5 + 0.35 * randf() + destello * 4.0) * Luz.fuerza()
	charco.modulate = Color.WHITE.lerp(Color(1.7, 2.0, 2.3), destello / 0.2)
	queue_redraw()
	chispas.queue_redraw()


# ¿Está a menos de "margen" de alguna casilla del charco?
func cerca(p: Vector2, margen: float) -> bool:
	var c := Peligros.casilla(p)
	var n := ceili(margen / CASILLA)
	for f in range(c.y - n, c.y + n + 1):
		for cc in range(c.x - n, c.x + n + 1):
			if mojado.has(Vector2i(cc, f)) and Rect2(Vector2(cc, f) * CASILLA, Vector2(CASILLA, CASILLA)).grow(margen).has_point(p):
				return true
	return false


# El calambrazo: rayos desde el cable por el agua, un fogonazo azul y daño a todo el que esté dentro
func calambrazo(johnny: Node2D) -> void:
	var a: Dictionary = Peligros.AGUA
	destello = 0.2
	rayos.clear()
	for i in 4:
		rayos.append(rayo_hasta(datos.casillas.pick_random()))
	var visto: bool = mapa.niebla.get(0, 0.0) < 0.5
	if visto:
		Luz.destello(self, punta, 260.0, 0.25, 0.8, RAYO)
	var dio := false
	if johnny and johnny.vivo and johnny.esquiva_t <= 0.0 and en_agua(johnny.global_position):
		johnny.pisar({"calambre": {"despues": a.tieso}})
		johnny.recibir_dano(a.dano, null, "agua")
		dio = true
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi.get("dormido") or zombi.get("estado") == "muerto" or not en_agua(zombi.global_position):
			continue
		zombi.herir(a.dano_zombi, Estados.LISTA.calambre.color)
		if "aturdido" in zombi:
			zombi.aturdido = maxf(zombi.aturdido, a.aturde)
		for k in 6:
			Particulas.soltar(zombi, zombi.global_position + Vector2(randf_range(-14, 14), -randf_range(0, 50)),
				Vector2(randf_range(-60, 60), randf_range(-60, 30)), Color.WHITE if k % 2 else RAYO, 2, 0.2)
		dio = true
	if dio or (johnny and cerca(johnny.global_position, 200.0)):
		Sonido.tocar("calambre")


# Un rayo de la punta del cable hasta una casilla del charco, yendo por el agua (casilla a casilla, en zigzag)
func rayo_hasta(meta: Vector2i) -> Array:
	var ruta := Peligros.camino(mojado, datos.cable, meta)
	var puntos := [punta]
	for c in ruta.slice(1):
		puntos.append(Peligros.centro(c) + Vector2(randf_range(-10, 10), randf_range(-10, 10)))
	return puntos


# ── Dibujos ──

# El charco, de una vez, con el aspecto de los charcos de agua de los aspersores (el dibujo objeto-charco-lejia.png
# teñido de azul, charco.gd): contorno negro, orilla azul oscura (más gruesa por abajo), el interior azul claro con
# alguna mancha y gotitas sueltas alrededor. Como este es grande y con forma de casillas, se calcula píxel a píxel
# (uno del dibujo = 2 unidades) en una imagen que se pinta entera; el borde se redondea y ondula con algo de ruido
func dibujar_charco() -> void:
	if textura == null:
		hacer_textura()
	charco.draw_set_transform(esquina, 0.0, Vector2(2, 2))
	charco.draw_texture(textura, Vector2.ZERO)
	charco.draw_set_transform(Vector2.ZERO)
	# el cable por el suelo, desde el pie de la pared hasta el agua, con una curva
	var desde: Vector2 = datos.cable_desde + Vector2(0, 4)
	var lado := Vector2(punta - desde).orthogonal().normalized() * (18.0 if hash(datos.cable) % 2 else -18.0)
	var medio := (desde + punta) / 2.0 + lado
	var n := maxi(8, int(desde.distance_to(punta) / 2.0))
	for i in n + 1:
		var k := float(i) / n
		var p := desde.lerp(medio, k).lerp(medio.lerp(punta, k), k)
		p = (p / 2.0).floor() * 2.0
		charco.draw_rect(Rect2(p, Vector2(4, 4)), CABLE)
		charco.draw_rect(Rect2(p, Vector2(2, 2)), Color("#3c3f47"))
	# la punta: los hilos de cobre abiertos o, arreglado, el empalme con cinta aislante
	if datos.get("arreglado", false):
		charco.draw_rect(Rect2(punta + Vector2(-8, -4), Vector2(12, 8)), CABLE)
		charco.draw_rect(Rect2(punta + Vector2(-6, -2), Vector2(8, 4)), Color("#3f4a5c"))
		charco.draw_rect(Rect2(punta + Vector2(-6, -2), Vector2(8, 2)), Color("#5d6b80"))
		return
	for h in [Vector2(-6, -4), Vector2(-7, 2), Vector2(-4, 6)]:
		charco.draw_line(punta, punta + h, COBRE, 2.0)


# Los colores: los del dibujo de los charcos de agua (objeto-charco-lejia.png con su tinte azul)
const PIX_BORDE := Color("#030406")
const PIX_ORILLA := [Color("#2e609d"), Color("#3265a5")]
const PIX_MEDIO := Color("#4474af")
const PIX_DENTRO := [Color("#7dbbf3"), Color("#7ab6f0"), Color("#7fbdf4")]
const PIX_MANCHA := [Color("#71ace7"), Color("#5083bd")]

# La imagen del charco: cada casilla son 16x16 píxeles del dibujo. "lejos" es, para cada píxel mojado, a cuántos
# píxeles está del suelo seco; el agua llega hasta donde "lejos" pasa de un umbral que ondula (el borde redondo)
func hacer_textura() -> void:
	var c0 := Vector2i(999999, 999999)
	var c1 := Vector2i(-999999, -999999)
	for c in datos.casillas:
		c0 = Vector2i(mini(c0.x, c.x), mini(c0.y, c.y))
		c1 = Vector2i(maxi(c1.x, c.x), maxi(c1.y, c.y))
	esquina = Vector2(c0) * CASILLA
	var an := (c1.x - c0.x + 1) * 16
	var al := (c1.y - c0.y + 1) * 16
	var mojada := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < an and y < al and mojado.has(c0 + Vector2i(x / 16, y / 16))
	var lejos := distancias(an, al, mojada)
	var semilla := float(hash(c0) % 1000)
	# la distancia, emborronada (la media de un cuadrado de 7x7): así las esquinas de las casillas no dejan picos
	var suave := PackedFloat32Array()
	suave.resize(an * al)
	for y in al:
		for x in an:
			var suma := 0.0
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var xx := clampi(x + dx, 0, an - 1)
					var yy := clampi(y + dy, 0, al - 1)
					suma += minf(lejos[yy * an + xx], 12.0)
			suave[y * an + x] = suma / 49.0
	var agua := PackedByteArray()
	agua.resize(an * al)
	for y in al:
		for x in an:
			var ruido := sin(x * 0.27 + semilla) + sin(y * 0.33 + semilla * 1.7) + sin((x - y) * 0.17 + semilla * 0.3)
			agua[y * an + x] = 1 if lejos[y * an + x] > 0.0 and suave[y * an + x] > 5.0 + ruido * 1.6 else 0
	var dentro := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < an and y < al and agua[y * an + x] == 1
	var hondo := distancias(an, al, dentro)   # a cuántos píxeles del borde del agua
	var img := Image.create(an, al, false, Image.FORMAT_RGBA8)
	var r := RandomNumberGenerator.new()
	r.seed = hash(c0) + 7
	for y in al:
		for x in an:
			if agua[y * an + x] == 0:
				continue
			var h: float = hondo[y * an + x]
			var abajo: bool = not dentro.call(x, y + 2) or not dentro.call(x, y + 3)   # la orilla, más gruesa por abajo
			var color: Color
			if h <= 1.0:
				color = PIX_BORDE
			elif h <= 2.5 or (abajo and h <= 3.5):
				color = PIX_ORILLA[0]
			elif h <= 3.5 or (abajo and h <= 4.5):
				color = PIX_MEDIO
			else:
				color = PIX_DENTRO[0] if r.randf() < 0.85 else PIX_DENTRO[1 + r.randi() % 2]
			img.set_pixel(x, y, color)
	# alguna mancha más oscura dentro (como las del dibujo)
	for i in datos.casillas.size() * 2:
		var x := r.randi_range(0, an - 3)
		var y := r.randi_range(0, al - 2)
		if hondo[y * an + x] > 4.0 and hondo[y * an + x + 2] > 4.0:
			var color: Color = PIX_MANCHA[r.randi() % 2]
			img.set_pixel(x, y, color)
			img.set_pixel(x + 1, y, color)
			if r.randf() < 0.5:
				img.set_pixel(x + 1, y + 1, color)
	# gotitas sueltas en el suelo seco de las casillas del borde, separadas del charco
	var gotas := 0
	for i in 400:
		if gotas >= maxi(3, datos.casillas.size() / 3):
			break
		var x := r.randi_range(1, an - 5)
		var y := r.randi_range(1, al - 4)
		var w := 4 if r.randf() < 0.5 else 5
		var libre := true   # sobre las casillas del charco, y sin tocar el agua
		for dy in range(-1, 5):
			for dx in range(-1, w + 1):
				if dentro.call(x + dx, y + dy):
					libre = false
		for dy in 4:
			for dx in w:
				if not mojada.call(x + dx, y + dy):
					libre = false
		if not libre or hondo[y * an + x] > 7.0:
			continue
		var cerca_agua := false   # que no quede lejos del charco
		for dy in range(-6, 9):
			for dx in range(-6, w + 6):
				if dentro.call(x + dx, y + dy):
					cerca_agua = true
		if not cerca_agua:
			continue
		gotas += 1
		# 4 de alto: contorno negro, arriba claro y abajo la orilla oscura, como las gotas del dibujo
		for dy in 4:
			for dx in w:
				if (dx == 0 or dx == w - 1) and (dy == 0 or dy == 3):
					continue
				var color: Color = PIX_BORDE
				if dx > 0 and dx < w - 1 and dy == 1:
					color = PIX_DENTRO[0]
				elif dx > 0 and dx < w - 1 and dy == 2:
					color = PIX_ORILLA[0]
				img.set_pixel(x + dx, y + dy, color)
	pixeles = img
	textura = ImageTexture.create_from_image(img)


# Para cada píxel de la imagen, a cuántos píxeles está del primero que no cumple "vale" (fuera de la imagen tampoco
# cumple). Dos pasadas, con 1 en recto y 1,4 en diagonal: basta para un borde redondo
func distancias(an: int, al: int, vale: Callable) -> PackedFloat32Array:
	var d := PackedFloat32Array()
	d.resize(an * al)
	for y in al:
		for x in an:
			d[y * an + x] = 9999.0 if vale.call(x, y) else 0.0
	for y in al:
		for x in an:
			var i := y * an + x
			if d[i] == 0.0:
				continue
			var m := d[i]
			m = minf(m, (d[i - 1] if x > 0 else 0.0) + 1.0)
			m = minf(m, (d[i - an] if y > 0 else 0.0) + 1.0)
			m = minf(m, (d[i - an - 1] if x > 0 and y > 0 else 0.0) + 1.4)
			m = minf(m, (d[i - an + 1] if x < an - 1 and y > 0 else 0.0) + 1.4)
			d[i] = m
	for y in range(al - 1, -1, -1):
		for x in range(an - 1, -1, -1):
			var i := y * an + x
			if d[i] == 0.0:
				continue
			var m := d[i]
			m = minf(m, (d[i + 1] if x < an - 1 else 0.0) + 1.0)
			m = minf(m, (d[i + an] if y < al - 1 else 0.0) + 1.0)
			m = minf(m, (d[i + an + 1] if x < an - 1 and y < al - 1 else 0.0) + 1.4)
			m = minf(m, (d[i + an - 1] if x > 0 and y < al - 1 else 0.0) + 1.4)
			d[i] = m
	return d


# ¿Hay agua dibujada en ese punto? (para que los brillos no caigan en el suelo seco del borde)
func hay_agua(p: Vector2) -> bool:
	var q := Vector2i(((p - esquina) / 2.0).floor())
	return (pixeles != null and q.x >= 0 and q.y >= 0 and q.x < pixeles.get_width() and q.y < pixeles.get_height()
			and pixeles.get_pixel(q.x, q.y).a > 0.0)


# Brillos que van y vienen sobre el agua (los alumbra la linterna)
func _draw() -> void:
	for b in brillos:
		var s := sin(t * 1.4 + b[3])
		if s < 0.2:
			continue
		var o: Vector2 = Vector2(b[0]) * CASILLA + Vector2(b[1] + sin(t * 0.7 + b[3]) * 3.0, b[2])
		if not hay_agua(o) or not hay_agua(o + Vector2(12, 0)):
			continue
		draw_rect(Rect2((o / 2.0).floor() * 2.0, Vector2(roundf(2 + s * 4) * 2.0, 2)), Color(0.85, 0.95, 1.0, 0.6 * s))


# Lo eléctrico, que luce solo: chispitas sueltas sobre el agua y, en cada calambrazo, los rayos
func dibujar_chispas() -> void:
	if not datos.corriente or datos.get("arreglado", false):
		return
	for i in 6:
		var c: Vector2i = datos.casillas[int(fposmod(t * 13.0 + i * 7.3, 1.0) * datos.casillas.size())]
		if randf() < 0.5:
			chispas.draw_rect(Rect2(Vector2(c) * CASILLA + Vector2(randi_range(1, 14), randi_range(1, 14)) * 2.0, Vector2(2, 2)), RAYO)
	if destello <= 0.0:
		return
	for puntos in rayos:
		for i in puntos.size() - 1:
			chispas.draw_line(puntos[i], puntos[i + 1], Color(RAYO, 0.6), 6.0)
			chispas.draw_line(puntos[i], puntos[i + 1], Color.WHITE, 2.0)


# En la pared: el cable baja desde una caja de empalmes reventada hasta el suelo
func dibujar_cable_pared(pared: Node2D) -> void:
	pared.draw_rect(Rect2(-2, -58, 4, 58), CABLE)
	pared.draw_rect(Rect2(-2, -58, 2, 58), Color("#3c3f47"))
	pared.draw_rect(Rect2(-10, -72, 20, 14), Color("#2b2d33"))
	pared.draw_rect(Rect2(-8, -70, 16, 10), Color("#6b7078"))
	pared.draw_rect(Rect2(-8, -70, 16, 2), Color("#9aa1aa"))
	if datos.get("arreglado", false):
		pared.draw_rect(Rect2(-6, -68, 12, 6), Color("#3f4a5c"))   # tapada con cinta aislante
		pared.draw_rect(Rect2(-6, -68, 12, 2), Color("#5d6b80"))
	else:
		pared.draw_rect(Rect2(-2, -66, 6, 4), Color("#1a1b1f"))   # la tapa arrancada
	# una mancha de quemado alrededor
	for p in [Vector2(-14, -76), Vector2(10, -74), Vector2(-12, -60), Vector2(8, -58)]:
		pared.draw_rect(Rect2(p, Vector2(4, 4)), Color(0.08, 0.07, 0.07, 0.6))
