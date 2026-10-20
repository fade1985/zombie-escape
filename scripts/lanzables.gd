# Lo que Johnny lanza con el botón de lanzar (clic derecho, E o el gatillo RT): el cóctel molotov y la granada
# (src/molotov.js y src/granada.js del JS). Son aparte de sus dos armas y tienen su propia munición.
#   - Se MANTIENE el botón para apuntar: en el suelo se ven el alcance (la elipse de puntos alrededor de
#     Johnny), la zona que arderá o explotará y la trayectoria. Al SOLTAR, lo lanza.
#   - Con ratón apunta al puntero; con mando, hacia donde se empuja el stick derecho (tan lejos como se
#     empuje). Si no se apunta a nada, al zombi más cercano a tiro (o, si no hay, un poco por delante).
#   - F o LB cambian lo que se lanza: molotov → granada → las arrojadizas creadas que queden → molotov.
#   - Las arrojadizas creadas (fase 7b2, sacadas del baúl): se lanzan como la granada con su propio efecto
#     (ARROJADIZAS). El cóctel molotov no está aquí: sus botellas se suman a los molotovs.
# El molotov vuela en parábola (proyectil.gd) y deja un charco de fuego (charco.gd). La granada bota, rueda y
# explota a los 2 s (granada.gd).
class_name Lanzables
extends Node2D

# Números del molotov (provisionales, como en el JS)
const MOLOTOV := {
	"inicio": 2,       # botellas al empezar la partida
	"maximo": 5,       # las que caben en la mochila
	"suelta": 0.06,    # probabilidad de que un zombi suelte una al morir
	"alcance": 300.0,  # lo más lejos que se puede lanzar
	"vuelo": 0.55,     # segundos en el aire
	"altura": 110.0,   # altura de la parábola
	"radio": 64.0,     # radio del fuego (en el suelo es una elipse: de alto mide el 60 %)
	"vida": 4.0,       # segundos que dura el fuego
	"golpe": 10,       # daño a los zombis que pilla de lleno al romperse
	"quema": 22.0,     # daño por segundo a los zombis que arden
	"dps": 12.0,       # daño por segundo a Johnny dentro del fuego (la esquiva lo cruza sin quemarse)
	"tick": 0.25,      # cada cuánto se reparte la quemadura a los zombis
	"sigue": 2.0,      # segundos que un zombi sigue ardiendo después de salir del fuego
}
# Números de la granada
const GRANADA := {
	"inicio": 2,
	"maximo": 4,
	"suelta": 0.05,
	"vuelo": 0.45,     # segundos hasta tocar el suelo
	"mecha": 2.0,      # segundos desde el lanzamiento hasta que explota
	"radio": 110.0,    # radio de la explosión
	"dano": 80,        # daño de la explosión (a zombis y a Johnny)
	"gravedad": 1400.0,
	"bote": 0.35,      # cuánta altura conserva al botar
	"rebote": 0.35,    # cuánta velocidad en el suelo conserva al botar
	"roce": 7.0,       # lo que frena al rodar
}
const FABRICANTE := {"radio": 1.3, "duracion": 1.5}   # el talento: fuego y explosiones más grandes y largos
# Las arrojadizas creadas (ARROJADIZAS de src/armas-creadas.js). El daño lo trae cada una (receta + rareza)
#   mecha    segundos hasta que revienta · radio  de la explosión · color  del dibujo, el aviso y los anillos
#   atrae    la atraedora suena y los zombis (a menos de esa distancia) van hacia ella en vez de hacia Johnny
#   congela  segundos que quedan quietos los que pilla · charco  deja la lluvia ácida (charco.gd, solo zombis)
const ARROJADIZAS := {
	"atraedora": {"mecha": 3.0, "radio": 110.0, "color": Color("#ffd23f"), "atrae": 520.0},
	"congeladora": {"mecha": 2.0, "radio": 120.0, "color": Color("#9fe8ff"), "congela": 3.0},
	"lluvia_acida": {"mecha": 2.0, "radio": 90.0, "color": Color("#c7e04a"), "charco": true},
}
const DANO_JOHNNY := 25   # lo más que le hace a Johnny la explosión de una arrojadiza creada
const DATOS := {"molotov": MOLOTOV, "granada": GRANADA}
const NOMBRES := {"molotov": "molotovs", "granada": "granadas"}
const COLORES := {"molotov": Color("#ff9f1c"), "granada": Color("#9bbd5a")}
const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")
const BOMBA := preload("res://scripts/granada.gd")

var johnny: Node2D
var partida: Node
var cantidades := {"molotov": 0, "granada": 0}
var creadas: Array = []        # las arrojadizas creadas sacadas del baúl, cada una con sus "unidades"
var tipo := "molotov"          # lo que se lanza ahora
var apunte := Vector2.INF      # dónde caería, mientras se mantiene el botón (INF: no se apunta)
var apuntando := false         # se ha visto el botón apretado: al soltarlo, se lanza (y solo entonces)
var t := 0.0


func _ready() -> void:
	top_level = true   # se dibuja en las coordenadas del mundo
	z_index = 15


# Al empezar la partida: las de siempre, más las del Artificiero
func reiniciar(stats: Dictionary) -> void:
	for k in cantidades:
		cantidades[k] = DATOS[k].inicio + stats.lanzar_extra
	creadas.clear()
	tipo = "molotov"


# Una arrojadiza creada sacada del baúl: el cóctel suma sus botellas a los molotovs (aunque pase del máximo)
func sacar(a: Dictionary) -> void:
	if a.receta == "molotov":
		cantidades.molotov += a.unidades
	else:
		creadas.append(a.duplicate())


# Las que le quedan de ese tipo (de siempre o creada, sumando todas las que haya sacado)
func cuantas(k: String) -> int:
	if cantidades.has(k):
		return cantidades[k]
	var n := 0
	for a in creadas:
		if a.receta == k:
			n += a.unidades
	return n


func nombre(k: String) -> String:
	return NOMBRES[k] if NOMBRES.has(k) else Recetas.LISTA[k].nombre.to_lower()


func color(k: String) -> Color:
	return COLORES[k] if COLORES.has(k) else ARROJADIZAS[k].color


func maximo(k: String) -> int:
	return DATOS[k].maximo + johnny.stats.lanzar_extra


# Coger uno del suelo: solo si cabe en la mochila
func cabe(k: String) -> bool:
	return cantidades[k] < maximo(k)


func sumar(k: String) -> void:
	cantidades[k] = mini(cantidades[k] + 1, maximo(k))


# Lo que se puede lanzar, en el orden del botón de cambiar: molotov, granada y las creadas que queden
func tipos() -> Array:
	return ["molotov", "granada"] + ARROJADIZAS.keys().filter(func(k): return cuantas(k) > 0)


func cambiar() -> void:
	var ks := tipos()
	tipo = ks[(ks.find(tipo) + 1) % ks.size()]
	Sonido.tocar("pitido")


func radio_zona() -> float:
	var fab: float = FABRICANTE.radio if johnny.stats.fabricante else 1.0
	if ARROJADIZAS.has(tipo):
		return ARROJADIZAS[tipo].radio * fab
	return (MOLOTOV.radio if tipo == "molotov" else GRANADA.radio) * fab


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()
	apunte = Vector2.INF
	if johnny == null or not johnny.vivo:
		apuntando = false
		return
	if Input.is_action_just_pressed("cambiar_lanzable"):
		cambiar()
	if Input.is_action_pressed("lanzar"):
		apunte = objetivo()
		apuntando = true
	elif apuntando:
		apuntando = false
		lanzar(objetivo())


# Dónde caería (ver arriba), sin pasarse del alcance: como todo en el suelo, el alcance es una elipse
func objetivo() -> Vector2:
	var desde: Vector2 = johnny.global_position
	var hacia := Vector2.ZERO
	var stick := Input.get_vector("apuntar_izquierda", "apuntar_derecha", "apuntar_arriba", "apuntar_abajo")
	if stick.length() > 0.25:
		hacia = Vector2(stick.x, stick.y * 0.6) * MOLOTOV.alcance
	elif johnny.con_raton:
		hacia = get_global_mouse_position() - desde
	else:
		var zombi := mas_cercano()
		if zombi:
			hacia = zombi.global_position - desde
		else:
			hacia = Vector2.from_angle(johnny.DIRS.find(johnny.direccion) * PI / 4) * MOLOTOV.alcance * 0.6
	var d := Vector2(hacia.x, hacia.y / 0.6).length()
	if d > MOLOTOV.alcance:
		hacia *= MOLOTOV.alcance / d
	return desde + hacia


# El zombi más cercano a tiro (para lanzar con un toque, sin apuntar)
func mas_cercano() -> Node2D:
	var mejor: Node2D = null
	var cerca: float = MOLOTOV.alcance
	var mapa := get_tree().get_first_node_in_group("mapa")
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if mapa and mapa.oculto(zombi.global_position):
			continue
		var d: float = johnny.global_position.distance_to(zombi.global_position)
		if d < cerca:
			cerca = d
			mejor = zombi
	return mejor


func lanzar(donde: Vector2) -> void:
	if cuantas(tipo) <= 0:
		Zombi.texto_flotante(johnny.get_parent(), johnny.global_position + Vector2(-50, -80), "¡Sin %s!" % nombre(tipo), color(tipo), 18)
		Sonido.tocar("no")
		return
	Sonido.tocar("lanzar")
	var sala: Node = johnny.get_parent()
	if ARROJADIZAS.has(tipo):
		lanzar_creada(donde, sala)
		return
	cantidades[tipo] -= 1
	if tipo == "molotov":
		var p := PROYECTIL.instantiate()
		p.tipo = "molotov"
		p.desde = johnny.global_position
		p.alto_salida = 20.0
		p.hasta = donde
		p.dano_lanzar = johnny.stats.dano_lanzar
		p.fabricante = johnny.stats.fabricante
		sala.add_child(p)
	else:
		var g := BOMBA.new()
		g.desde = johnny.global_position
		g.hasta = donde
		g.radio = radio_zona()
		g.dano_zombis = roundi(GRANADA.dano * johnny.stats.dano_lanzar)
		sala.add_child(g)


# Lanza una unidad de la arrojadiza creada elegida (como la granada, con su mecha, su radio y su efecto)
func lanzar_creada(donde: Vector2, sala: Node) -> void:
	var a: Dictionary = creadas.filter(func(o): return o.receta == tipo)[0]
	a.unidades -= 1
	if a.unidades <= 0:
		creadas.erase(a)
	var g := BOMBA.new()
	g.tipo = tipo
	g.desde = johnny.global_position
	g.hasta = donde
	g.radio = radio_zona()
	g.dano_zombis = roundi(a.dano * johnny.stats.dano_lanzar)
	g.fabricante = johnny.stats.fabricante
	sala.add_child(g)
	if cuantas(tipo) <= 0:
		tipo = "molotov"   # era la última: vuelve al molotov


# ── Dibujo del apunte ──

func _draw() -> void:
	if apunte == Vector2.INF:
		return
	var hay: bool = cuantas(tipo) > 0
	var tono: Color = color(tipo) if hay else Color(0.67, 0.67, 0.67)
	var desde: Vector2 = johnny.global_position
	# el alcance máximo, a puntos (con un borde oscuro debajo, para que se vea en suelos claros y oscuros)
	elipse_a_trozos(desde, MOLOTOV.alcance, Color(0.11, 0.1, 0.17, 0.45), 4.0, 0.0)
	# la zona que arderá o explotará, latiendo, con su borde a trozos que gira
	var r := radio_zona()
	draw_set_transform(apunte, 0.0, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, r, Color(tono, (0.35 if tipo == "molotov" else 0.3) * (0.85 + 0.15 * sin(t * 8.0))))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(0.11, 0.1, 0.17, 0.6), 6.0)
	draw_set_transform(Vector2.ZERO)
	elipse_a_trozos(apunte, r, tono, 2.0, t * 0.6)
	if tipo == "molotov":
		# la cruz del centro: donde se rompe la botella
		draw_rect(Rect2(apunte + Vector2(-6, -1), Vector2(12, 2)), tono)
		draw_rect(Rect2(apunte + Vector2(-1, -6), Vector2(2, 12)), tono)
	# la trayectoria: puntitos en parábola desde la mano de Johnny
	var salida := desde - Vector2(0, 20)
	for i in range(1, 12):
		var k := i / 12.0
		var p := salida.lerp(apunte, k) - Vector2(0, sin(k * PI) * MOLOTOV.altura)
		p = (p / 2.0).round() * 2.0
		draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), Color(0.11, 0.1, 0.17, 0.7))
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), tono)


# Una elipse de suelo (de alto, el 60 %) hecha de trocitos, como una línea de puntos
func elipse_a_trozos(centro: Vector2, r: float, tono: Color, grueso: float, giro: float) -> void:
	var trozos := maxi(12, int(r / 6.0))
	for i in trozos:
		var a := giro + TAU * i / trozos
		var b := a + TAU / trozos * 0.45
		var pa := centro + Vector2(cos(a) * r, sin(a) * r * 0.6)
		var pb := centro + Vector2(cos(b) * r, sin(b) * r * 0.6)
		draw_line(pa, pb, tono, grueso)
