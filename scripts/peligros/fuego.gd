# El fuego de la cocina del restaurante (peligros.gd). Arde por casillas: el foco (delante del fogón o de la
# freidora) no se apaga nunca y, cada "ronda", cada casilla que arde puede prender una de al lado. Cada casilla
# arde un rato, se apaga dejando ceniza y tarda en poder volver a prender: el fuego se va moviendo por la cocina,
# sin pasar nunca del tope ni salir de ella. Lo que arde se apunta en el sitio, así sigue igual al volver.
#
# Quema como el del molotov: a Johnny le pone el estado "fuego" (sigue ardiendo un poco al salir) y a los zombis
# despiertos los prende (zombi.gd). Se dibuja igual que él (charco.gd), a cuadraditos de pixel art con llamas
# (llamas.gd), chispas, humo y luz naranja; y encima del fogón, sus llamas de siempre.
extends Node2D

const CASILLA := 32
const CELDA := 4.0                  # 2 píxeles del dibujo, como el fuego del molotov
const BORDE := 12.0                 # el borde deshilachado del fuego, en unidades (lo de dentro va de un tirón)
const PINTA := 1.0 / 20.0           # se repinta 20 veces por segundo: de sobra para que tiemble, y gasta menos
const PRENDE := 0.6                 # lo que tarda una casilla en prenderse del todo
const APAGA := 1.5                  # y en apagarse (antes, se va quedando en brasas)
const TEXTURA := preload("res://escenas/luces/luz_suave.tres")

var datos: Dictionary
var mapa: Node
var se_quema := {}                  # las casillas que pueden arder
var prendida := {}                  # casilla -> cuándo empezó a arder (para dibujarla creciendo)
static var ruido := {}              # casilla -> [64 números al azar, siempre los mismos para esa casilla] (para que el
                                    # borde sea irregular; lo comparten cerco.gd y porqueria.gd)
var t := 0.0
var ronda := 0.0
var tick := 0.0
var pinta := 0.0
var luces: Array = []               # una en cada foco y otra que va con el resto del fuego (luz_de_fuego)


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Fuego"   # no-tr (nombre de nodo)
	z_index = -1   # en el suelo, como los charcos
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # el fuego luce por sí mismo
	material = propio
	for c in d.casillas:
		se_quema[c] = true
	# la primera vez que entras ya lleva un rato ardiendo
	if d.nuevo:
		d.nuevo = false
		for i in Peligros.FUEGO.antes:
			pasar(Peligros.FUEGO.ronda)
			extender()
	for c in d.arde:
		prendida[c] = -PRENDE
	for i in d.focos.size() + 1:
		var luz := luz_de_fuego(150.0 if i < d.focos.size() else 210.0)
		luz.position = Peligros.centro(d.focos[i]) if i < d.focos.size() else Vector2.ZERO
	mover_luz()
	poner_fogones()


# Una luz de fuego hecha como las lámparas (lampara.gd): la del suelo hace sombras, así no se cuela por las
# paredes a la sala de al lado, y la de lo demás (personajes, muebles) solo alumbra la cocina
func luz_de_fuego(radio: float) -> Node2D:
	var luz := Node2D.new()
	for suelo in [true, false]:
		var l := PointLight2D.new()
		l.texture = TEXTURA
		l.texture_scale = radio / 128.0
		l.color = Color(1.0, 0.47, 0.16)
		if suelo:
			l.range_item_cull_mask = Luz.CAPA_SUELO
			l.shadow_enabled = true
			l.shadow_color = Color.BLACK
			l.shadow_filter = Light2D.SHADOW_FILTER_PCF5
			l.shadow_filter_smooth = 3.0
			l.shadow_item_cull_mask = Luz.SOMBRAS
		else:
			l.range_item_cull_mask = Luz.CAPA_COSAS | Luz.capa_sala(datos.sala)
		luz.add_child(l)
	add_child(luz)
	luces.append(luz)
	return luz


# Encima del fogón (o la freidora) del foco, sus llamas de siempre, como las de alguien que arde
func poner_fogones() -> void:
	for mueble in mapa.muebles:
		if mueble.zona != datos.sala or not mueble.datos.tipo in ["industrialstove", "fryer"]:
			continue
		var h := Muebles.hueco(mueble.datos)
		if not Peligros.casilla(Vector2(h.get_center().x, h.end.y + CASILLA * 0.5)) in datos.focos:
			continue
		var alto: float = mueble.get_node("Sprite").texture.get_size().y * 2.0
		var llamas := Llamas.new()
		llamas.alto = 34.0
		llamas.ancho = minf(h.size.x * 0.32, 22.0)
		llamas.position = Vector2(0, -alto * 0.42)
		mueble.add_child(llamas)


# Pasa el tiempo: lo que arde se va consumiendo, y lo apagado se enfría
func pasar(dt: float) -> void:
	for c in datos.arde.keys():
		datos.arde[c] -= dt
		if datos.arde[c] <= 0.0:
			datos.arde.erase(c)
			prendida.erase(c)
			datos.apagadas[c] = Peligros.FUEGO.enfria
			datos.quemadas[c] = true
	for c in datos.apagadas.keys():
		datos.apagadas[c] -= dt
		if datos.apagadas[c] <= 0.0:
			datos.apagadas.erase(c)


# Cada casilla que arde puede prender una de al lado (si no se ha llegado al tope)
func extender() -> void:
	var f: Dictionary = Peligros.FUEGO
	for c in datos.arde.keys():
		if datos.arde.size() >= datos.tope:
			return
		if randf() >= f.prende:
			continue
		var vecinas := []
		for d in Peligros.LADOS:
			var v: Vector2i = c + d
			if se_quema.has(v) and not datos.arde.has(v) and not datos.apagadas.has(v):
				vecinas.append(v)
		if not vecinas.is_empty():
			var v: Vector2i = vecinas.pick_random()
			datos.arde[v] = randf_range(f.arde[0], f.arde[1])
			prendida[v] = t


# La luz grande va al medio de lo que arde (sin contar los focos, que llevan la suya): a la casilla que arde más
# cerca del medio y sin un mueble encima (si la luz saliera de dentro de un mueble, su sombra lo taparía todo)
func mover_luz() -> void:
	var suma := Vector2.ZERO
	var lista := []
	for c in datos.arde:
		if not c in datos.focos and not Peligros.bajo_mueble(mapa.sitio, c):
			suma += Peligros.centro(c)
			lista.append(c)
	var luz: Node2D = luces[-1]
	luz.visible = not lista.is_empty()
	if lista.is_empty():
		return
	var medio := suma / lista.size()
	lista.sort_custom(func(a, b): return Peligros.centro(a).distance_to(medio) < Peligros.centro(b).distance_to(medio))
	luz.position = Peligros.centro(lista[0])


func arde_en(p: Vector2) -> bool:
	var c := Peligros.casilla(p)
	return datos.arde.has(c) and t - prendida.get(c, 0.0) > PRENDE * 0.5


func _physics_process(delta: float) -> void:
	t += delta
	pasar(delta)
	ronda += delta
	if ronda >= Peligros.FUEGO.ronda:
		ronda -= Peligros.FUEGO.ronda
		extender()
		mover_luz()
	# las luces tiemblan, como las del molotov (fuego.gd)
	for i in luces.size():
		var b := 0.82 + 0.1 * sin(t * 11.0 + i * 7.0) + 0.08 * sin(t * 23.7 + i * 3.0)
		for l in luces[i].get_children():
			l.energy = 0.9 * b * Luz.fuerza()
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo:
		if mapa.zona_en(johnny.global_position) == datos.sala:
			Peligros.avisar(self, datos, Idioma.t("¡La cocina está ardiendo!"))
		if arde_en(johnny.global_position):
			johnny.pisar({"fuego": {"dps": Peligros.FUEGO.dps}})
	# cada poco, prende a los zombis despiertos que estén dentro (como el charco de fuego del molotov)
	tick += delta
	if tick >= Lanzables.MOLOTOV.tick:
		tick -= Lanzables.MOLOTOV.tick
		for zombi in get_tree().get_nodes_in_group("zombis"):
			if zombi.get("dormido") or not arde_en(zombi.global_position):
				continue
			if zombi.has_method("prender"):
				zombi.prender()
			else:
				zombi.herir(Lanzables.MOLOTOV.quema * Lanzables.MOLOTOV.tick, Llamas.FUEGO[2])
	# lo de fuera solo si la cocina ya se ha descubierto (las chispas y el humo van por encima de la niebla)
	var visto: bool = mapa.niebla.get(datos.sala, 0.0) < 0.5
	if visto and not datos.arde.is_empty():
		var lista: Array = datos.arde.keys()
		if randf() < 24.0 * delta:
			var p := Peligros.centro(lista.pick_random()) + Vector2(randf_range(-14, 14), randf_range(-14, 10))
			Particulas.soltar(self, p, Vector2(randf_range(-10, 10), randf_range(-140, -70)), Llamas.FUEGO[randi() % 4], randf_range(1, 3), 0.45)
		if randf() < 5.0 * delta:
			var p := Peligros.centro(lista.pick_random()) + Vector2(randf_range(-10, 10), -randf_range(10, 30))
			Particulas.soltar(self, p, Vector2(randf_range(-12, 12), randf_range(-50, -30)), Color(0.13, 0.11, 0.11, 0.5), randf_range(4, 7), 1.3)
	pinta -= delta
	if pinta <= 0.0 and mapa.niebla.get(datos.sala, 0.0) < 0.98:
		pinta = PINTA
		queue_redraw()


# El ruido de cada celda de una casilla (siempre el mismo para esa casilla). También lo usan el cerco del bombero y la
# porquería del Glotón: FUEGO.ruido_de(c)
static func ruido_de(c: Vector2i) -> Array:
	if not ruido.has(c):
		var r := RandomNumberGenerator.new()
		r.seed = hash(c)
		var lista := []
		for i in 64:
			lista.append(r.randf())
		ruido[c] = lista
	return ruido[c]


func _draw() -> void:
	# la ceniza de lo que ya ha ardido (debajo de todo)
	for c in datos.quemadas:
		if datos.arde.has(c):
			continue
		var r := ruido_de(c)
		draw_rect(Rect2(Vector2(c) * CASILLA, Vector2(CASILLA, CASILLA)), Color("#1c120e", 0.35))
		for i in 6:
			draw_rect(Rect2(Vector2(c) * CASILLA + Vector2(floorf(r[i] * 8.0), floorf(r[i + 6] * 8.0)) * CELDA, Vector2(CELDA, CELDA)),
				Color("#2a1a14", 0.6))
	var llamas := []
	for c in datos.arde:
		var r := ruido_de(c)
		var crece := clampf((t - prendida.get(c, 0.0)) / PRENDE, 0.0, 1.0)
		var queda: float = clampf(datos.arde[c] / APAGA, 0.0, 1.0)
		# hacia qué lados se acaba el fuego (ahí el borde se deshilacha y se pone rojo)
		var fin := []
		for d in Peligros.LADOS:
			fin.append(not datos.arde.has(c + d))
		var o := Vector2(c) * CASILLA
		var limpio: bool = crece >= 1.0 and queda >= 1.0
		if limpio and not fin.has(true):
			# por dentro, de un tirón (y unas celdas más claras que tiemblan)
			draw_rect(Rect2(o, Vector2(CASILLA, CASILLA)), Color(Llamas.FUEGO[2], 0.9))
			for i in 16:
				var k := int(r[i] * 64.0)
				var s := sin(t * 9.0 + r[k] * 20.0)
				if absf(s) > 0.3:
					draw_rect(Rect2(o + Vector2(k % 8, k / 8) * CELDA, Vector2(CELDA, CELDA)), Color(Llamas.FUEGO[1] if s > 0.0 else Llamas.FUEGO[3], 0.9))
		else:
			# a celdas: lo de dentro de cada borde, recortado con el ruido
			var dentro := Rect2(o, Vector2(CASILLA, CASILLA))
			if limpio:
				var izq := BORDE if fin[0] else 0.0
				var arr := BORDE if fin[2] else 0.0
				dentro = Rect2(o + Vector2(izq, arr), Vector2(CASILLA - izq - (BORDE if fin[1] else 0.0), CASILLA - arr - (BORDE if fin[3] else 0.0)))
				draw_rect(dentro, Color(Llamas.FUEGO[2], 0.9))
			for i in 64:
				var p := Vector2(i % 8, i / 8) * CELDA
				if limpio and dentro.has_point(o + p + Vector2(1, 1)):
					continue
				# lo que le falta para llegar al borde que se acaba (en unidades)
				var hondo := 99.0
				if fin[0]: hondo = minf(hondo, p.x)
				if fin[1]: hondo = minf(hondo, CASILLA - CELDA - p.x)
				if fin[2]: hondo = minf(hondo, p.y)
				if fin[3]: hondo = minf(hondo, CASILLA - CELDA - p.y)
				if hondo + r[i] * 10.0 < 5.0:
					continue
				if r[i] > crece:
					continue   # aún no le ha llegado
				var color: Color
				if r[i] > queda:
					color = Color("#6e1d12")   # se está apagando: brasa
				else:
					var calor := clampf(hondo / 16.0, 0.0, 1.0) + 0.12 * sin(t * 9.0 + r[i] * 20.0)
					color = Llamas.FUEGO[1] if calor > 0.85 else Llamas.FUEGO[2] if calor > 0.5 else Llamas.FUEGO[3] if calor > 0.25 else Llamas.FUEGO[4]
					color.a = 0.9
				draw_rect(Rect2(o + p, Vector2(CELDA, CELDA)), color)
		# una llama en la mitad de las casillas (siempre en las mismas), más alta cuanto más metida en el fuego
		if r[0] < 0.55 or c in datos.focos:
			var metida := 1.0 - fin.count(true) / 4.0
			llamas.append([o.x + 8.0 + r[1] * 16.0, o.y + 18.0 + r[2] * 10.0, roundf(4 + metida * 3), roundf(7 + metida * 9 + r[3] * 4), r[4] * 10.0, minf(crece, queda)])
	llamas.sort_custom(func(a, b): return a[1] < b[1])
	for l in llamas:
		Llamas.llama(self, l[0], l[1], l[2], l[3], t, l[4], l[5])
