# La puerta de dentro de las casas: tapa el hueco de un tabique entre dos habitaciones ("hueco" es la puerta de
# apt.puertas, en casillas). Cerrada choca, no deja pasar la luz ni ver lo de dentro (la niebla, mapa.gd) y para las
# balas y la vista de los zombis (sus rayos chocan con la capa 1, como con los muros). Al abrirse deja de chocar y
# gira sobre las bisagras. De frente es un dibujo de PixelLab (puerta-bano) que se tuerce hacia la habitación de
# abajo hasta quedarse casi de canto, dentro de un marco que llena el hueco hasta el dintel (el trozo de muro de
# encima, que pone mapa.gd); de lado (hoja_de_lado), la puerta tumbada a lo largo del hueco, que lo llena entero
# (puerta-bano-lado-cerrada, de tools/puerta_lado_cerrada.py), y que al abrirse gira de pie hasta quedarse casi pegada a
# la pared. Abierta, se queda así: lo apunta en su hueco ("abierta") para que siga abierta al volver. Abierta del todo
# es otro dibujo de PixelLab (de frente puerta-bano-abierta y de lado puerta-bano-abierta-lado, de
# tools/puerta_abierta.py): nuestra puerta casi de canto, con su canto, su pomo y su sombra en el suelo.
#
# Las "libres" las pone mapa.gd en cada hueco de los pisos, las tiendas y la sala de mantenimiento: empiezan cerradas
# y las abren Johnny y los que le acompañan con solo arrimarse, y los zombis despiertos empujándolas un momento. La
# navegación cuenta con pasar por ellas, para que los zombis vayan a abrirlas.
# Las demás van cerradas con llave (su hueco lleva "cerrada", y ahí mapa.gd no pone la libre) y la navegación no cuenta
# con pasar por ellas hasta que se abren:
#   - la del baño donde se esconde el superviviente (PuertaBano en src/props.js del JS), hasta que se limpia el piso.
#     Tiembla cuando él da golpes desde dentro ("golpes", lo pone supervivientes.gd al gritar). La del almacén del
#     ferretero lleva además tablas clavadas por encima ("tablas", las que quedan): las va quitando él (barricada.gd)
#   - las de las viviendas de quien aún no está rescatado (mapa.gd)
#   - la blindada de la cámara acorazada de la joyería (joyeria.gd): de acero ("acero", también en su hueco)
extends StaticBody2D

const CASILLA := 32
const ALTO := 86.0          # lo alto de la hoja vista de frente (casi lo alto de la cara del muro)
const LINEA := Color("#1d1b2c")
const DIBUJO := preload("res://assets/sprites/puerta-bano.png")   # la hoja de frente: 28 × 43 píxeles (56 × 86 unidades)
const MARCO := 4.0          # de frente, el grueso del marco (2 píxeles): con la hoja, llena el hueco de lado a lado
const DINTEL := ALTO + MARCO   # de frente, lo alto del marco; por encima va el dintel (mapa.gd: poner_caras)
const ABIERTA := preload("res://assets/sprites/puerta-bano-abierta.png")   # la hoja abierta del todo, de frente: 14 × 67 píxeles (64 de hoja y 3 de sombra)
const GIRO := 1.1071        # lo que gira de frente al abrirse del todo, 63 grados (cada píxel hacia un lado, dos hacia abajo)
const ABIERTA_LADO := preload("res://assets/sprites/puerta-bano-abierta-lado.png")   # la de lado, abierta del todo: 14 × 67
const SOMBRA_LADO := 3      # las filas de abajo de ese dibujo que son la sombra del suelo
const GIRO_LADO := 2.6779   # lo que gira de lado al abrirse del todo, 153 grados: casi pegada a la pared (cada píxel hacia un lado, dos hacia arriba)
const CERRADA_LADO := preload("res://assets/sprites/puerta-bano-lado-cerrada.png")   # la de lado, cerrada: 16 × 32 (el hueco entero)
const FIN_CERRADA := 0.2    # de lado, lo que tarda en irse el dibujo de la cerrada al empezar a abrirse
const ARRIMADO := 26.0      # a cuánto del hueco, por delante o por detrás, hay que llegar para abrir una libre
const EMPUJE := 0.5         # los segundos que tarda un zombi en abrir una libre empujándola
const MIRAR := 0.1          # cada cuánto mira una libre si alguien la empuja

var hueco: Dictionary
var de_frente := false      # hueco en un tabique horizontal: la hoja se ve de frente, como los muros
var caja := Rect2()         # el hueco, en unidades del mundo
var arrimo := Rect2()       # dónde hay que estar para abrir una libre: delante o detrás del hueco
var abierta := 0.0          # 0 cerrada, 1 abierta del todo
var abriendo := false
var golpes := 0.0           # segundos que le quedan temblando
var tablas := 0:            # las tablas que le quedan clavadas (la barricada del ferretero)
	set(n):
		tablas = n
		queue_redraw()
var acero := false          # la puerta blindada de la cámara acorazada de la joyería (joyeria.gd): de acero, sin madera
var libre := false          # se abre empujando (ver arriba)
var empuje := 0.0           # lo que lleva un zombi empujándola
var mirar_t := 0.0
var tiempo := 0.0


func montar(datos: Dictionary) -> void:
	hueco = datos
	de_frente = hueco.fondo == 1
	acero = acero or hueco.get("acero", false)
	caja = Rect2(hueco.c * CASILLA, hueco.f * CASILLA, hueco.ancho * CASILLA, hueco.fondo * CASILLA)
	arrimo = caja.grow_individual(4, ARRIMADO, 4, ARRIMADO) if de_frente else caja.grow_individual(ARRIMADO, 4, ARRIMADO, 4)
	# para ordenarla con lo demás: su "y" es el pie del hueco (la de lado, abierta, se queda arriba: ver arriba_de_lado)
	position = Vector2(caja.get_center().x, caja.end.y + 1)
	collision_layer = 1
	collision_mask = 0
	if libre and hueco.get("abierta", false):
		abierta = 1.0   # ya la abrió alguien: sigue abierta, sin chocar
		abriendo = true
		arriba_de_lado()
		return
	if libre:
		hueco.abierta = false
	else:
		add_to_group("obstaculos")   # la navegación no cuenta con pasar por aquí mientras esté cerrada
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = caja.size
	forma.shape = rect
	forma.position = caja.get_center() - position
	add_child(forma)
	# y su sombra: cerrada, la luz tampoco pasa (la de las lámparas ni la linterna de Johnny)
	var sombra := LightOccluder2D.new()
	var huella := OccluderPolygon2D.new()
	var r := Rect2(caja.position - position, caja.size)
	huella.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	sombra.occluder = huella
	add_child(sombra)


# Se abre: deja de chocar y, poco a poco, gira
func abrir() -> void:
	if abriendo:
		return
	abriendo = true
	hueco.abierta = true
	remove_from_group("obstaculos")
	for hijo in get_children():
		if hijo is CollisionShape2D:
			hijo.set_deferred("disabled", true)
		elif hijo is LightOccluder2D:
			hijo.queue_free()
	arriba_de_lado()


# La de lado, abierta, se queda de pie arriba del hueco (su bisagra, 4 unidades por debajo del borde): se ordena con lo
# demás por ahí (si no, taparía a quien pase por debajo de ella)
func arriba_de_lado() -> void:
	if not de_frente:
		position.y = caja.position.y + 4


# Una libre, cerrada: si Johnny o uno de los suyos se arrima, se abre; si un zombi despierto la empuja, tiembla y,
# al rato, también
func _physics_process(delta: float) -> void:
	if not libre or abriendo:
		return
	mirar_t -= delta
	if mirar_t > 0.0:
		return
	mirar_t = MIRAR
	var johnny := get_tree().get_first_node_in_group("jugador") as Node2D
	if johnny and arrimo.has_point(johnny.global_position):
		abrir_empujando()
		return
	for a in get_tree().get_nodes_in_group("aliados"):
		if a.modo == "equipo" and arrimo.has_point(a.global_position):
			abrir_empujando()
			return
	for z in get_tree().get_nodes_in_group("zombis"):
		if z is Zombi and not z.dormido and z.estado != "muerto" and arrimo.has_point(z.global_position):
			empuje += MIRAR
			golpes = MIRAR + 0.05
			if empuje >= EMPUJE:
				abrir_empujando()
			return
	empuje = 0.0


func abrir_empujando() -> void:
	abrir()
	Sonido.tocar("crujido")


func _process(delta: float) -> void:
	tiempo += delta
	var cambia := golpes > 0.0 or (abriendo and abierta < 1.0)
	golpes = maxf(0.0, golpes - delta)
	if abriendo:
		abierta = minf(1.0, abierta + delta * 2.5)
	if cambia:
		queue_redraw()


func _draw() -> void:
	var temblor := sin(tiempo * 70.0) * 2.0 * minf(1.0, golpes / 0.15) if golpes > 0.0 else 0.0
	var r := caja
	r.position -= position
	if de_frente:
		# el marco, que llena el hueco de lado a lado y hasta el dintel: oscuro por fuera y claro por dentro
		var oscuro := Color("#2b3036") if acero else Color("#4a2e1e")
		var claro := Color("#7a848c") if acero else Color("#a0704a")
		var arriba := r.end.y - DINTEL
		draw_rect(Rect2(r.position.x, arriba, r.size.x, MARCO), claro)
		draw_rect(Rect2(r.position.x, arriba, MARCO, DINTEL), claro)
		draw_rect(Rect2(r.end.x - MARCO, arriba, MARCO, DINTEL), claro)
		draw_rect(Rect2(r.position.x, arriba, r.size.x, 2), oscuro)
		draw_rect(Rect2(r.position.x, arriba, 2, DINTEL), oscuro)
		draw_rect(Rect2(r.end.x - 2, arriba, 2, DINTEL), oscuro)
		# la hoja, del pie del hueco hasta el marco. Gira sobre las bisagras, a la izquierda, hacia la habitación de
		# abajo: se estrecha, se tuerce hacia abajo y se oscurece, y se le va viendo el canto
		var ancho := r.size.x - MARCO * 2
		var giro := abierta * GIRO
		var bisagra := Vector2(r.position.x + MARCO + temblor, r.end.y)
		if abierta >= 1.0 and not acero:
			# abierta del todo: su dibujo, con la esquina de arriba a la izquierda en la bisagra (con su canto y su sombra)
			draw_texture_rect(ABIERTA, Rect2(bisagra - Vector2(0, ALTO), ABIERTA.get_size() * 2.0), false)
		else:
			draw_set_transform_matrix(Transform2D(Vector2(cos(giro), sin(giro)), Vector2(0, 1), bisagra))
			var hoja := Rect2(0, -ALTO, ancho, ALTO)
			if acero:
				acero_de_frente(hoja)
			else:
				draw_texture_rect(DIBUJO, hoja, false, Color.WHITE.darkened(0.15 * abierta))
			draw_set_transform_matrix(Transform2D.IDENTITY)
			if abierta > 0.0:
				# el canto de fuera, que da a la luz
				var punta := bisagra + Vector2(cos(giro), sin(giro)) * ancho
				var canto := Rect2(punta.x, punta.y - ALTO, maxf(2.0, 6.0 * sin(giro)), ALTO)
				draw_rect(canto, Color("#9aa3aa") if acero else Color("#b07a4e"))
				draw_rect(canto, LINEA, false, 2.0)
		# la barricada: tablas torcidas de lado a lado, más anchas que la puerta, con un clavo en cada punta
		for i in tablas:
			var y: float = r.end.y - ALTO + ALTO * [0.18, 0.4, 0.62, 0.84][i]
			tabla(Vector2(r.position.x - 6 + temblor, y - [5, -6, 4, -5][i] / 2.0),
				Vector2(r.end.x + 6 + temblor, y + [5, -6, 4, -5][i] / 2.0))
	else:
		# en un tabique de lado: el umbral, el suelo del hueco, que lo llena de lado a lado del grueso del muro (al
		# abrirse se va: abierta, la puerta se ordena por arriba y les taparía los pies a los que pasan)
		if abierta < 1.0:
			var umbral := Color("#2b3036") if acero else Color("#4a3428")
			var borde := LINEA
			umbral.a = 1.0 - abierta
			borde.a = 1.0 - abierta
			draw_rect(r, umbral)
			draw_rect(Rect2(r.position.x, r.position.y, 2, r.size.y), borde)
			draw_rect(Rect2(r.end.x - 2, r.position.y, 2, r.size.y), borde)
		if acero or tablas > 0:
			# la blindada y la del almacén con tablas: la hoja vista desde arriba, de punta a punta del hueco, con la
			# bisagra arriba; gira hacia la habitación de la derecha hasta quedarse de través, contra el marco
			var grueso := 18.0 if acero else 14.0
			draw_set_transform(Vector2(r.get_center().x + temblor, r.position.y + grueso / 2), -abierta * PI / 2)
			var hoja := Rect2(-grueso / 2, -grueso / 2, grueso, r.size.y)
			if acero:
				draw_rect(hoja, Color("#5c646c"))
				draw_rect(Rect2(hoja.position.x + 3, hoja.position.y, 4, hoja.size.y), Color("#7a848c"))
				draw_rect(hoja, LINEA, false, 2.0)
				draw_rect(Rect2(hoja.position.x + 6, hoja.end.y - 16, 6, 6), Color("#23272b"))
			else:
				draw_rect(hoja, Color("#6e4b35"))
				draw_rect(hoja, LINEA, false, 2.0)
				draw_rect(Rect2(hoja.position.x + 4, hoja.end.y - 14, 5, 5), Color("#c9a227"))   # el pomo
			for i in tablas:
				var y: float = hoja.position.y + r.size.y * (i + 1) / (tablas + 1.0)
				tabla(Vector2(hoja.position.x - 10, y - 3), Vector2(hoja.end.x + 10, y + 3))
			draw_set_transform(Vector2.ZERO)
		else:
			hoja_de_lado(r, temblor)


# La hoja de madera de un tabique de lado, con la bisagra arriba del hueco: cerrada, su dibujo (puerta-bano-lado-cerrada:
# la puerta tumbada a lo largo del hueco, que lo llena entero; en cuanto empieza a girar se va); al abrirse, la puerta de
# verdad (la de frente, torcida) gira hacia la habitación de la derecha hasta quedarse casi pegada a la pared, de pie,
# con su cara hacia quien mira y su canto de la bisagra a la izquierda; y abierta del todo es su dibujo
# (puerta-bano-abierta-lado). La bisagra pasa del medio del hueco al borde de la habitación para que la hoja no se
# quede encima del tabique
func hoja_de_lado(r: Rect2, temblor: float) -> void:
	if abierta < FIN_CERRADA:
		var tinte := Color.WHITE
		tinte.a = 1.0 - abierta / FIN_CERRADA
		draw_texture_rect(CERRADA_LADO, Rect2(r.position.x + temblor, r.position.y, r.size.x, r.size.y), false, tinte)
	if abierta <= 0.0:
		return
	var bisagra := Vector2(lerpf(r.get_center().x, r.end.x - 2.0, abierta) + temblor, r.position.y + 4.0)
	if abierta >= 1.0:
		# (la esquina de arriba a la izquierda del dibujo, 4 unidades a la izquierda de la cara: el canto de la bisagra)
		var tam := ABIERTA_LADO.get_size() * 2.0
		draw_texture_rect(ABIERTA_LADO, Rect2(bisagra + Vector2(-4.0, -tam.y + SOMBRA_LADO * 2.0), tam), false)
		return
	var giro := abierta * GIRO_LADO
	draw_set_transform_matrix(Transform2D(Vector2(sin(giro), cos(giro)), Vector2(0, 1), bisagra))
	draw_texture_rect(DIBUJO, Rect2(0, -ALTO, r.size.y - 8.0, ALTO), false, Color.WHITE.darkened(0.15 * abierta))
	draw_set_transform_matrix(Transform2D.IDENTITY)


# La puerta blindada de la cámara acorazada de la joyería, de frente ("hoja" con el pie en 0): una plancha de acero con
# sus remaches, la rueda de la combinación y el tirador. Gira como la de madera
func acero_de_frente(hoja: Rect2) -> void:
	draw_rect(hoja, Color("#3b4046"))
	draw_rect(hoja.grow(-3), Color("#5c646c"))
	draw_rect(Rect2(hoja.position + Vector2(3, 3), Vector2(hoja.size.x - 6, 4)), Color("#7a848c"))   # el brillo de arriba
	draw_rect(hoja, LINEA, false, 2.0)
	for px in [hoja.position.x + 6, hoja.end.x - 10]:
		for py in [hoja.position.y + 8, hoja.end.y - 12]:
			draw_rect(Rect2(px, py, 4, 4), Color("#23272b"))   # los remaches
	var cy := hoja.get_center().y
	var cx := hoja.position.x + hoja.size.x * 0.4
	draw_circle(Vector2(cx, cy), 10.0, Color("#23272b"))   # la rueda de la combinación
	draw_circle(Vector2(cx, cy), 6.0, Color("#8a949c"))
	draw_rect(Rect2(cx - 1, cy - 6, 2, 6), Color("#23272b"))
	var tirador := Rect2(hoja.position.x + hoja.size.x * 0.68, cy - 12, 5, 24)
	draw_rect(tirador, Color("#9aa3aa"))
	draw_rect(tirador, LINEA, false, 1.0)


# Una tabla de la barricada, de "desde" a "hasta" (los centros de sus dos puntas)
func tabla(desde: Vector2, hasta: Vector2) -> void:
	var grueso := Vector2(0, 5)
	var forma := PackedVector2Array([desde - grueso, hasta - grueso, hasta + grueso, desde + grueso])
	draw_colored_polygon(forma, Color("#a0703f"))
	draw_line(desde - grueso + Vector2(0, 2), hasta - grueso + Vector2(0, 2), Color("#c4945c"), 2.0)   # el canto con luz
	forma.append(forma[0])
	draw_polyline(forma, LINEA, 2.0)
	for punta in [desde.lerp(hasta, 0.08), desde.lerp(hasta, 0.92)]:
		draw_rect(Rect2(punta - Vector2(2, 2), Vector2(4, 4)), Color("#c0c4d0"))
		draw_rect(Rect2(punta - Vector2(2, 2), Vector2(4, 4)), LINEA, false, 1.0)
