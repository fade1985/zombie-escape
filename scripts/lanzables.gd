# Lo que Johnny lanza con el botón de lanzar (clic derecho, E o el gatillo LT): el cóctel molotov y la granada
# (src/molotov.js y src/granada.js del JS) y las arrojadizas creadas. Son aparte de sus armas y no gastan munición:
# se cuentan por unidades (el molotov y la granada, hasta su "maximo").
#   - Se MANTIENE el botón para apuntar: en el suelo se ven el alcance (la elipse de puntos alrededor de
#     Johnny), la zona que arderá o explotará y la trayectoria. Al SOLTAR, lo lanza.
#   - Con ratón apunta al puntero; con mando, hacia donde se empuja el stick derecho (tan lejos como se
#     empuje). Si no se apunta a nada, al zombi más cercano a tiro (o, si no hay, un poco por delante).
#   - Con la ayuda "Lanzar apuntando solo" (Opciones > Ayudas), va siempre al zombi más cercano a la vista
#     (el mismo que buscaría el modo de atacar asistido); si no se ve ninguno, se apunta como siempre.
#   - Lleva MANO tipos a mano y REPUESTO de repuesto (parte 2 del inventario nuevo); cada tipo, en un hueco. F o RB
#     cambian lo que se lanza entre los de la mano. Al empezar, el molotov y la granada, a mano. Lo que consigue de un
#     tipo que ya lleva va a su hueco; si es de otro, a la mano si hay sitio y si no, al repuesto (y si tampoco, no lo
#     coge). Cuando se acaba uno de la mano, su hueco lo ocupa el primero de repuesto. Desde el inventario se pasan de
#     la mano al repuesto y al revés (a_la_mano, al_repuesto).
#   - Las arrojadizas creadas (fase 7b2, sacadas del baúl): se lanzan como la granada con su propio efecto
#     (ARROJADIZAS).
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
	# el fuego se contagia (zombi.gd, contagiar): el que arde prende a los zombis que tiene pegados
	"contagia": 0.5,   # cada cuánto lo pasa
	"pegado": 24.0,    # "pegados": a menos de esto, de borde a borde (en una horda apretada se quedan a unos 14: zombi_*.tscn, avoidance)
	"contagio": 1.5,   # segundos que arde el que se contagia
	"chamuscado": 2.0, # recién apagado, lo que tarda en poder contagiarse otra vez (si no, dos pegados se prenderían sin fin)
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
#   congela  segundos que quedan quietos los que pilla
# Quedan esas dos: el 25 oct se quitaron del juego la lluvia ácida y las cuatro del centro comercial (la bomba de
# aceite, la mina despertador, la nube somnífera y la bomba de clavos), y el cóctel molotov del banco
const ARROJADIZAS := {
	"atraedora": {"mecha": 3.0, "radio": 110.0, "color": Color("#ffd23f"), "atrae": 520.0},
	"congeladora": {"mecha": 2.0, "radio": 120.0, "color": Color("#9fe8ff"), "congela": 3.0},
}
const DANO_JOHNNY := 25   # lo más que le hace a Johnny la explosión de una arrojadiza creada
const DATOS := {"molotov": MOLOTOV, "granada": GRANADA}
const NOMBRES := {"molotov": "molotovs", "granada": "granadas"}
const COLORES := {"molotov": Color("#ff9f1c"), "granada": Color("#9bbd5a")}
const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")
const BOMBA := preload("res://scripts/granada.gd")
const MANO := 3            # los tipos que lleva a mano (F cambia entre ellos)
const REPUESTO := 8        # y los de repuesto

var johnny: Node2D
var partida: Node
var cantidades := {"molotov": 0, "granada": 0}
var creadas: Array = []        # las arrojadizas creadas sacadas del baúl, cada una con sus "unidades"
var mano: Array = []           # los tipos que lleva a mano, en el orden de F (molotov, granada o la receta de una creada)
var repuesto: Array = []       # y los de repuesto
var tipo := "molotov"          # lo que se lanza ahora ("" si no lleva nada a mano)
var apunte := Vector2.INF      # dónde caería, mientras se mantiene el botón (INF: no se apunta)
var apuntando := false         # se ha visto el botón apretado: al soltarlo, se lanza (y solo entonces)
var t := 0.0


func _ready() -> void:
	top_level = true   # se dibuja en las coordenadas del mundo
	z_index = 15


# Al empezar la partida: las de siempre, más las del Artificiero, a mano
func reiniciar(stats: Dictionary) -> void:
	for k in cantidades:
		cantidades[k] = DATOS[k].inicio + stats.lanzar_extra
	creadas.clear()
	mano = ["molotov", "granada"]
	repuesto = []
	tipo = "molotov"


# El reto "Solo cuerpo a cuerpo": sin nada que lanzar
func vaciar() -> void:
	for k in cantidades:
		cantidades[k] = 0
	creadas.clear()
	repasar()


# Una arrojadiza creada sacada del baúl. Va a su hueco (colocar); si no le cabe, no la coge y devuelve false
func sacar(a: Dictionary) -> bool:
	if not hay_hueco(a.receta):
		return false
	creadas.append(a.duplicate())
	colocar(a.receta)
	return true


# ¿Tiene dónde llevar uno de ese tipo? En su hueco, si ya lleva (a mano o de repuesto), o en uno libre
func hay_hueco(k: String) -> bool:
	return k in mano or k in repuesto or mano.size() < MANO or repuesto.size() < REPUESTO


# Le busca hueco a ese tipo si aún no lo tiene: a mano si hay sitio (y si no llevaba nada a mano, es lo que se
# lanza) y si no, de repuesto
func colocar(k: String) -> void:
	if k in mano or k in repuesto:
		return
	if mano.size() < MANO:
		mano.append(k)
		if tipo == "":
			tipo = k
	elif repuesto.size() < REPUESTO:
		repuesto.append(k)


# Quita los que se han acabado: el hueco de la mano lo ocupa el primero de repuesto. Si se acaba el que se lanzaba, se
# lanza el que ocupa su sitio (o el siguiente de la mano)
func repasar() -> void:
	repuesto = repuesto.filter(func(k): return cuantas(k) > 0)
	var i := 0
	while i < mano.size():
		if cuantas(mano[i]) > 0:
			i += 1
			continue
		var era: String = mano[i]
		if repuesto.is_empty():
			mano.remove_at(i)
		else:
			mano[i] = repuesto.pop_front()
		if tipo == era:
			tipo = mano[mini(i, mano.size() - 1)] if not mano.is_empty() else ""
	if not tipo in mano:
		tipo = mano[0] if not mano.is_empty() else ""


# Desde el inventario: pasa ese tipo del repuesto a la mano, y es lo que se lanza. Con la mano llena, cambia por lo
# que se lanzaba, que pasa a su sitio en el repuesto. Con "por" (arrastrándolo encima de uno de la mano), cambia por ese
func a_la_mano(k: String, por := "") -> void:
	var i := repuesto.find(k)
	if i < 0:
		return
	if mano.size() < MANO and not por in mano:
		repuesto.remove_at(i)
		mano.append(k)
	else:
		var fuera := por if por in mano else tipo
		repuesto[i] = fuera
		mano[mano.find(fuera)] = k
	tipo = k


# Y al revés: de la mano al repuesto, si hay sitio
func al_repuesto(k: String) -> void:
	if not k in mano or repuesto.size() >= REPUESTO:
		return
	mano.erase(k)
	repuesto.append(k)
	if tipo == k:
		tipo = mano[0] if not mano.is_empty() else ""


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
	if ARROJADIZAS.has(k):
		return ARROJADIZAS[k].color
	return COLORES.get(k, Color(0.67, 0.67, 0.67))   # ("": sin nada a mano, en gris)


func maximo(k: String) -> int:
	return DATOS[k].maximo + johnny.stats.lanzar_extra


# Coger uno del suelo: solo si no llega a su máximo y tiene hueco para él
func cabe(k: String) -> bool:
	return cantidades[k] < maximo(k) and hay_hueco(k)


func sumar(k: String) -> void:
	cantidades[k] = mini(cantidades[k] + 1, maximo(k))
	colocar(k)


# Lo que se puede lanzar, en el orden del botón de cambiar: los que lleva a mano
func tipos() -> Array:
	return mano.duplicate()


func cambiar() -> void:
	if mano.is_empty():
		return
	tipo = mano[(mano.find(tipo) + 1) % mano.size()]
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
	var solo: Node2D = johnny.buscar_objetivo({"tipo": "fuego", "alcance": MOLOTOV.alcance}) 		if Guardado.ajuste("lanzar_solo") else null
	if solo:
		hacia = solo.global_position - desde   # ayuda "Lanzar apuntando solo"
	elif stick.length() > 0.25:
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
	if tipo == "" or cuantas(tipo) <= 0:
		var aviso := "¡Sin %s!" % nombre(tipo) if tipo != "" else "¡Nada que lanzar!"
		Zombi.texto_flotante(johnny.get_parent(), johnny.global_position + Vector2(-50, -80), aviso, color(tipo), 18)
		Sonido.tocar("no")
		return
	Sonido.tocar("lanzar")
	var sala: Node = johnny.get_parent()
	if ARROJADIZAS.has(tipo):
		lanzar_creada(donde, sala)
		repasar()   # (si era la última, su hueco lo ocupa el primero de repuesto)
		return
	cantidades[tipo] -= 1
	if tipo == "molotov":
		partida.logros.molotov_lanzado()
		var p := PROYECTIL.instantiate()
		p.tipo = "molotov"
		p.desde = johnny.global_position
		p.alto_salida = 20.0
		p.hasta = donde
		p.dano_lanzar = johnny.stats.dano_lanzar * Skins.quema(johnny.skin)   # (la skin del bombero: × 3)
		p.fabricante = johnny.stats.fabricante
		sala.add_child(p)
	else:
		var g := BOMBA.new()
		g.desde = johnny.global_position
		g.hasta = donde
		g.radio = radio_zona()
		g.dano_zombis = roundi(GRANADA.dano * johnny.stats.dano_lanzar)
		sala.add_child(g)
	repasar()   # (si era el último, su hueco lo ocupa el primero de repuesto)


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
