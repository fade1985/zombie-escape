# Lo que Johnny lanza con el botón de lanzar (clic derecho, E o el gatillo LT): el cóctel molotov y la granada
# (src/molotov.js y src/granada.js del JS), la atraedora y la congeladora. Son aparte de sus armas y no gastan
# munición: se cuentan por unidades (hasta su "maximo").
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
#   - La atraedora y la congeladora (ARROJADIZAS): se lanzan como la granada, con su propio efecto. Hasta el 25 oct
#     se creaban en el banco de trabajo con una receta; ahora se cuentan como el molotov y la granada, pero no se
#     tienen al empezar ni las sueltan los zombis: solo se compran.
#   - Los cuatro se compran de uno en uno en la tienda de armas del ordenador (PRECIOS; ordenador.gd, comprar_lanzable).
#   - Cada paquete tiene su calidad (Armas.CALIDADES; parte 4 de la tienda y las piezas): la que no es Normal hace más
#     daño, con más radio, y caben más. Los de un tipo con dos calidades son dos paquetes, cada uno en su hueco: su
#     "clave" es el tipo y, si no es Normal, su calidad detrás («molotov:2», unos molotovs Raros; clave, tipo_de y
#     calidad_de). Lo de la tienda, lo de empezar y lo que sueltan los zombis es Normal; los mejorados se guardan en el
#     baúl (los Normales no) y salen de él.
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
	"dano": 80,        # daño de la explosión a los zombis (a Johnny, como mucho DANO_JOHNNY)
	"gravedad": 1400.0,
	"bote": 0.35,      # cuánta altura conserva al botar
	"rebote": 0.35,    # cuánta velocidad en el suelo conserva al botar
	"roce": 7.0,       # lo que frena al rodar
}
const FABRICANTE := {"radio": 1.3, "duracion": 1.5}   # el talento: fuego y explosiones más grandes y largos
# La atraedora y la congeladora (ARROJADIZAS de src/armas-creadas.js): granadas con otro efecto
#   inicio y maximo  como en el molotov y la granada (no se tiene ninguna al empezar) · dano  de la explosión
#   mecha    segundos hasta que revienta · radio  de la explosión · color  del dibujo, el aviso y los anillos
#   atrae    la atraedora suena y los zombis (a menos de esa distancia) van hacia ella en vez de hacia Johnny
#   congela  segundos que quedan quietos los que pilla
# Quedan esas dos: el 25 oct se quitaron del juego la lluvia ácida y las cuatro del centro comercial (la bomba de
# aceite, la mina despertador, la nube somnífera y la bomba de clavos), y el cóctel molotov del banco
const ATRAEDORA := {"inicio": 0, "maximo": 3, "dano": 80, "mecha": 3.0, "radio": 110.0, "color": Color("#ffd23f"), "atrae": 520.0}
const CONGELADORA := {"inicio": 0, "maximo": 3, "dano": 50, "mecha": 2.0, "radio": 120.0, "color": Color("#9fe8ff"), "congela": 3.0}
const ARROJADIZAS := {"atraedora": ATRAEDORA, "congeladora": CONGELADORA}
const DANO_JOHNNY := 25   # lo más que le hace a Johnny la explosión de una granada, una atraedora o una congeladora
const DATOS := {"molotov": MOLOTOV, "granada": GRANADA, "atraedora": ATRAEDORA, "congeladora": CONGELADORA}
const NOMBRES := {"molotov": "molotovs", "granada": "granadas", "atraedora": "atraedoras", "congeladora": "congeladoras"}
const UNO := {"molotov": "Molotov", "granada": "Granada", "atraedora": "Atraedora", "congeladora": "Congeladora"}
# Lo que cuesta uno en la tienda de armas del ordenador (el dueño, 25 oct): se compran de uno en uno, para esa partida
const PRECIOS := {"molotov": 5, "granada": 5, "atraedora": 8, "congeladora": 8}
const COLORES := {"molotov": Color("#ff9f1c"), "granada": Color("#9bbd5a"), "atraedora": Color("#ffd23f"),
	"congeladora": Color("#9fe8ff")}   # (los de ARROJADIZAS)
const ARTIFICIERO := ["molotov", "granada"]   # a los que el talento Artificiero les suma unidades (lanzar_extra)
const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")
const BOMBA := preload("res://scripts/granada.gd")
const MANO := 3            # los tipos que lleva a mano (F cambia entre ellos)
const REPUESTO := 8        # y los de repuesto

var johnny: Node2D
var partida: Node
var cantidades := {"molotov": 0, "granada": 0, "atraedora": 0, "congeladora": 0}   # cuántos de cada paquete (por su clave)
var mano: Array = []           # los paquetes que lleva a mano (sus claves), en el orden de F
var repuesto: Array = []       # y los de repuesto
var tipo := "molotov"          # el paquete que se lanza ahora (su clave; "" si no lleva nada a mano)
var apunte := Vector2.INF      # dónde caería, mientras se mantiene el botón (INF: no se apunta)
var apuntando := false         # se ha visto el botón apretado: al soltarlo, se lanza (y solo entonces)
var t := 0.0


func _ready() -> void:
	top_level = true   # se dibuja en las coordenadas del mundo
	z_index = 15


# La clave de un paquete: el tipo y, si no es Normal, su calidad («molotov:2»)
static func clave(k: String, calidad: int) -> String:
	return k if calidad <= 0 else "%s:%d" % [k, calidad]


# El tipo de un paquete por su clave («molotov»)
static func tipo_de(k: String) -> String:
	return k.get_slice(":", 0)


# Y su calidad (0 = Normal)
static func calidad_de(k: String) -> int:
	return k.get_slice(":", 1).to_int() if ":" in k else 0


# Al empezar la partida: las de siempre, más las del Artificiero, a mano (todas Normales)
func reiniciar(stats: Dictionary) -> void:
	cantidades = {}
	for k in DATOS:
		cantidades[k] = DATOS[k].inicio + (stats.lanzar_extra if k in ARTIFICIERO else 0)
	mano = ["molotov", "granada"]
	repuesto = []
	tipo = "molotov"


# El reto "Solo cuerpo a cuerpo": sin nada que lanzar
func vaciar() -> void:
	for k in cantidades:
		cantidades[k] = 0
	repasar()


# ¿Tiene dónde llevar uno de ese tipo? En su hueco, si ya lleva (a mano o de repuesto), o en uno libre
func hay_hueco(k: String) -> bool:
	return k in mano or k in repuesto or mano.size() < MANO or repuesto.size() < REPUESTO   # (cada paquete, en uno)


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
	for k in cantidades.keys():   # (los mejorados que se acaban, fuera)
		if calidad_de(k) > 0 and cantidades[k] <= 0:
			cantidades.erase(k)
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


# Las que le quedan de ese tipo
func cuantas(k: String) -> int:
	return cantidades.get(k, 0)


func nombre(k: String) -> String:
	return NOMBRES[tipo_de(k)]


# El color de su tipo (el de los textos y el apunte; el de la calidad, en el borde de la casilla: Armas.color)
func color(k: String) -> Color:
	return COLORES.get(tipo_de(k), Color(0.67, 0.67, 0.67))   # ("": sin nada a mano, en gris)


# Los que caben en un paquete: los de su tipo, más los del Artificiero y los de su calidad
func maximo(k: String) -> int:
	var t := tipo_de(k)
	var extra: int = johnny.stats.lanzar_extra if t in ARTIFICIERO else 0
	return DATOS[t].maximo + extra + Armas.CALIDADES[calidad_de(k)].unidades


# Coger uno del suelo: solo si no llega a su máximo y tiene hueco para él
func cabe(k: String) -> bool:
	return cuantas(k) < maximo(k) and hay_hueco(k)


func sumar(k: String) -> void:
	cantidades[k] = mini(cuantas(k) + 1, maximo(k))
	colocar(k)


# Mete "n" en ese paquete (sacándolos del baúl), hasta su máximo y si tiene hueco: devuelve los que han entrado
func meter(k: String, n: int) -> int:
	if not hay_hueco(k):
		return 0
	var entran := mini(n, maximo(k) - cuantas(k))
	if entran > 0:
		cantidades[k] = cuantas(k) + entran
		colocar(k)
	return maxi(entran, 0)


# Quita el paquete entero (al guardarlo en el baúl): devuelve cuántos tenía
func quitar(k: String) -> int:
	var n := cuantas(k)
	cantidades[k] = 0
	repasar()
	return n


# Sube un paquete a esa calidad (en el banco de trabajo): pasa a su clave nueva en el mismo hueco o, si ya llevaba otro
# de esa calidad, se junta con él (el banco mira antes que quepan). Devuelve la clave nueva
func mejorar(k: String, calidad: int) -> String:
	var nueva := clave(tipo_de(k), calidad)
	var n := cuantas(k)
	if cuantas(nueva) > 0:
		cantidades[nueva] += n
		quitar(k)
		return nueva
	cantidades[nueva] = n
	cantidades[k] = 0
	for lista in [mano, repuesto]:
		var i: int = lista.find(k)
		if i >= 0:
			lista[i] = nueva
	if tipo == k:
		tipo = nueva
	repasar()   # (la clave vieja, si era de un mejorado, fuera)
	return nueva


# Cuántos lleva de un tipo, sumando todos sus paquetes (el menú de pausa)
func total(t: String) -> int:
	var n := 0
	for k in cantidades:
		if tipo_de(k) == t:
			n += cantidades[k]
	return n


# Lo que se puede lanzar, en el orden del botón de cambiar: los que lleva a mano
func tipos() -> Array:
	return mano.duplicate()


func cambiar() -> void:
	if mano.is_empty():
		return
	tipo = mano[(mano.find(tipo) + 1) % mano.size()]
	Sonido.tocar("pitido")


func radio_zona() -> float:
	var fab: float = (FABRICANTE.radio if johnny.stats.fabricante else 1.0) * Armas.CALIDADES[calidad_de(tipo)].radio
	var t := tipo_de(tipo)
	if ARROJADIZAS.has(t):
		return ARROJADIZAS[t].radio * fab
	return (MOLOTOV.radio if t == "molotov" else GRANADA.radio) * fab


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
	cantidades[tipo] -= 1
	var t := tipo_de(tipo)
	var calidad: Dictionary = Armas.CALIDADES[calidad_de(tipo)]
	if t == "molotov":
		partida.logros.molotov_lanzado()
		var p := PROYECTIL.instantiate()
		p.tipo = "molotov"
		p.desde = johnny.global_position
		p.alto_salida = 20.0
		p.hasta = donde
		# Puntería y la skin del bombero (+50 %) se suman, como en las armas (johnny.gd, arma_de); la calidad multiplica
		p.dano_lanzar = (johnny.stats.dano_lanzar + Skins.quema(johnny.skin) - 1.0) * calidad.dano
		p.fabricante = johnny.stats.fabricante
		p.escala = calidad.radio
		p.racimo = Armas.TRUCO.racimo if calidad_de(tipo) >= Armas.EPICA else 0
		sala.add_child(p)
	else:
		# la granada, o la atraedora o la congeladora (la misma granada, con su mecha, su radio y su efecto)
		var g := BOMBA.new()
		g.tipo = t
		g.desde = johnny.global_position
		g.hasta = donde
		g.radio = radio_zona()
		g.dano_zombis = roundi(DATOS[t].dano * johnny.stats.dano_lanzar * calidad.dano)
		if ARROJADIZAS.has(t):
			g.fabricante = johnny.stats.fabricante
		g.racimo = Armas.TRUCO.racimo if calidad_de(tipo) >= Armas.EPICA else 0
		sala.add_child(g)
	repasar()   # (si era el último, su hueco lo ocupa el primero de repuesto)


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
	var molotov := tipo_de(tipo) == "molotov"
	draw_circle(Vector2.ZERO, r, Color(tono, (0.35 if molotov else 0.3) * (0.85 + 0.15 * sin(t * 8.0))))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(0.11, 0.1, 0.17, 0.6), 6.0)
	draw_set_transform(Vector2.ZERO)
	elipse_a_trozos(apunte, r, tono, 2.0, t * 0.6)
	if molotov:
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
