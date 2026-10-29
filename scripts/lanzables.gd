# Lo que Johnny lanza con el botón de lanzar (clic derecho, E o el gatillo LT): el cóctel molotov y la granada
# (src/molotov.js y src/granada.js del JS), la atraedora y la congeladora. Son aparte de sus armas y no gastan
# munición: se cuentan por unidades, en montones (MONTON).
#   - Se MANTIENE el botón para apuntar: en el suelo se ven el alcance (la elipse de puntos alrededor de
#     Johnny), la zona que arderá o explotará y la trayectoria. Al SOLTAR, lo lanza.
#   - Con ratón apunta al puntero; con mando, hacia donde se empuja el stick derecho (tan lejos como se
#     empuje). Si no se apunta a nada, al zombi más cercano a tiro (o, si no hay, un poco por delante).
#   - Con la ayuda "Lanzar apuntando solo" (Opciones > Ayudas), va siempre al zombi más cercano a la vista
#     (el mismo que buscaría el modo de atacar asistido); si no se ve ninguno, se apunta como siempre.
#   - Van en montones (el M18 del dueño, 28 oct): cada hueco lleva un montón de un tipo y una calidad, de hasta MONTON
#     (5; más con la calidad y los talentos: maximo). Lleva MANO montones a mano, uno de cada clave (F o RB cambian lo
#     que se lanza entre ellos), y REPUESTO de repuesto, donde puede haber varios de la misma. No hay tope por tipo: se
#     coge mientras quede sitio. Al empezar, el molotov y la granada, a mano. Lo que consigue va al montón de su clave
#     que no esté lleno (primero el de la mano); si están llenos, a un montón nuevo: a la mano si hay hueco y no lleva
#     ya esa clave a mano, y si no, al repuesto (y si tampoco, no lo coge: meter, cabe). Cuando se acaba el de la
#     mano, su hueco lo ocupa otro montón de repuesto de la misma clave; si no hay, uno del mismo tipo y, si tampoco,
#     el primero (repasar). Desde el inventario se pasan de la mano al repuesto y al revés (a_la_mano, al_repuesto). Un
#     montón se señala por su "sitio", el nombre de su casilla en el inventario: "l1" el 2.º a mano, "e3" el 4.º de
#     repuesto (clave_en, cuantos_en).
#   - Al completar el edificio, todos los que le quedan van al baúl (partida.equipo_encima), también los Normales. En
#     el baúl, los del mismo tipo y calidad se juntan en una casilla de hasta 99, como los objetos
#     (Objetos.arrojables_al_baul), y se sacan de montón en montón.
#   - La atraedora y la congeladora (ARROJADIZAS): se lanzan como la granada, con su propio efecto. Se
#     cuentan como el molotov y la granada, pero no se tienen al empezar ni las sueltan los zombis: solo se compran.
#   - Los cuatro se compran de uno en uno en la tienda de armas del ordenador (PRECIOS; ordenador.gd, comprar_lanzable).
#   - Cada paquete tiene su calidad (Armas.CALIDADES; parte 4 de la tienda y las piezas): la que no es Normal hace más
#     daño, con más radio, y caben más en su montón. Los de un tipo con dos calidades van en montones distintos: su
#     "clave" es el tipo y, si no es Normal, su calidad detrás («molotov:2», unos molotovs Raros; clave, tipo_de y
#     calidad_de). Lo de la tienda, lo de empezar y lo que sueltan los zombis es Normal.
# El molotov vuela en parábola (proyectil.gd) y deja un charco de fuego (charco.gd). La granada bota, rueda y
# explota a los 2 s (granada.gd).
class_name Lanzables
extends Node2D

# Números del molotov (provisionales, como en el JS)
const MOLOTOV := {
	"inicio": 2,       # botellas al empezar la partida
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
#   inicio   como en el molotov y la granada (no se tiene ninguna al empezar) · dano  de la explosión
#   mecha    segundos hasta que revienta · radio  de la explosión · color  del dibujo, el aviso y los anillos
#   atrae    la atraedora suena y los zombis (a menos de esa distancia) van hacia ella en vez de hacia Johnny
#   congela  segundos que quedan quietos los que pilla
# Quedan esas dos: el 25 oct se quitaron del juego la lluvia ácida y las cuatro del centro comercial (la bomba de
# aceite, la mina despertador, la nube somnífera y la bomba de clavos), y el cóctel molotov del banco
const ATRAEDORA := {"inicio": 0, "dano": 80, "mecha": 3.0, "radio": 110.0, "color": Color("#ffd23f"), "atrae": 520.0}
const CONGELADORA := {"inicio": 0, "dano": 50, "mecha": 2.0, "radio": 120.0, "color": Color("#9fe8ff"), "congela": 3.0}
const ARROJADIZAS := {"atraedora": ATRAEDORA, "congeladora": CONGELADORA}
const DANO_JOHNNY := 25   # lo más que le hace a Johnny la explosión de una granada, una atraedora o una congeladora
const DATOS := {"molotov": MOLOTOV, "granada": GRANADA, "atraedora": ATRAEDORA, "congeladora": CONGELADORA}
# Cómo se dice uno («Molotov»); para enseñarlo, uno(), que lo traduce. El plural, en minúscula, para dentro de una frase
# («¡Sin molotovs!»), está en varios()
# [traducir]
const UNO := {"molotov": "Molotov", "granada": "Granada", "atraedora": "Atraedora", "congeladora": "Congeladora"}
# [/traducir]
# Lo que cuesta uno en la tienda de armas del ordenador (el dueño, 25 oct): se compran de uno en uno, para esa partida
const PRECIOS := {"molotov": 5, "granada": 5, "atraedora": 8, "congeladora": 8}
const COLORES := {"molotov": Color("#ff9f1c"), "granada": Color("#9bbd5a"), "atraedora": Color("#ffd23f"),
	"congeladora": Color("#9fe8ff")}   # (los de ARROJADIZAS)
const ARTIFICIERO := ["molotov", "granada"]   # a los que el talento Artificiero les suma unidades (lanzar_extra)
const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")
const BOMBA := preload("res://scripts/granada.gd")
const MANO := 3            # los montones que lleva a mano (F cambia entre ellos)
const REPUESTO := 8        # y los de repuesto
const MONTON := 5          # los que caben en un montón (antes, un tope por tipo: 5 molotovs, 4 granadas y 3 de las otras)

var johnny: Node2D
var partida: Node
var cantidades := {"molotov": 0, "granada": 0, "atraedora": 0, "congeladora": 0}   # cuántos hay en el montón de la mano de cada clave (0 si no la lleva a mano)
var mano: Array = []           # las claves de los montones que lleva a mano (sin repetir), en el orden de F
var repuesto: Array = []       # y las de los de repuesto (puede haber varios de la misma)
var en_repuesto: Array = []    # cuántos hay en cada montón de repuesto (en el orden de "repuesto")
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


# Al empezar la partida: las de siempre, más las del Artificiero, a mano (todas Normales). Con Criogenia, también sus
# congeladoras, a mano
func reiniciar(stats: Dictionary) -> void:
	cantidades = {}
	for k in DATOS:
		cantidades[k] = DATOS[k].inicio + extra_talentos(k, stats)
	mano = ["molotov", "granada"]
	if cantidades.congeladora > 0:
		mano.append("congeladora")
	repuesto = []
	en_repuesto = []
	tipo = "molotov"


# El reto "Solo cuerpo a cuerpo": sin nada que lanzar
func vaciar() -> void:
	for k in cantidades:
		cantidades[k] = 0
	repuesto = []
	en_repuesto = []
	repasar()


# La clave del montón de ese sitio ("l1", "e3"; "" si está vacío)
func clave_en(sitio: String) -> String:
	var i := sitio.substr(1).to_int()
	if sitio.begins_with("l"):
		return mano[i] if i < mano.size() else ""
	return repuesto[i] if sitio.begins_with("e") and i < repuesto.size() else ""


# Y cuántos hay en él
func cuantos_en(sitio: String) -> int:
	var i := sitio.substr(1).to_int()
	if sitio.begins_with("l"):
		return cuantas(mano[i]) if i < mano.size() else 0
	return en_repuesto[i] if sitio.begins_with("e") and i < en_repuesto.size() else 0


# El sitio de un montón de esa clave: el de la mano si la lleva a mano y si no, el primero de repuesto ("" si no lleva)
func sitio_de(k: String) -> String:
	if k in mano:
		return "l%d" % mano.find(k)
	return "e%d" % repuesto.find(k) if k in repuesto else ""


# ¿Le cabe uno más de esa clave? En un montón suyo que no esté lleno, o en uno nuevo: a mano (si hay hueco y no la lleva
# ya a mano) o de repuesto
func cabe(k: String) -> bool:
	if k in mano and cuantas(k) < maximo(k):
		return true
	for i in repuesto.size():
		if repuesto[i] == k and en_repuesto[i] < maximo(k):
			return true
	return (mano.size() < MANO and not k in mano) or repuesto.size() < REPUESTO


# Coger uno (del suelo o de la tienda)
func sumar(k: String) -> void:
	meter(k, 1)


# Mete "n" de esa clave (los que coge, los que compra o los que saca del baúl): primero en sus montones que no estén
# llenos (el de la mano, el primero) y luego en montones nuevos: a mano si hay hueco (y si no llevaba nada a mano, es lo
# que se lanza) y si no, de repuesto. Devuelve los que han entrado (los demás no caben)
func meter(k: String, n: int) -> int:
	var quedan := n
	if k in mano:
		var entran := clampi(maximo(k) - cuantas(k), 0, quedan)
		cantidades[k] = cuantas(k) + entran
		quedan -= entran
	for i in repuesto.size():
		if quedan > 0 and repuesto[i] == k and en_repuesto[i] < maximo(k):
			var entran := mini(quedan, maximo(k) - en_repuesto[i])
			en_repuesto[i] += entran
			quedan -= entran
	while quedan > 0:
		var entran := mini(quedan, maximo(k))
		if mano.size() < MANO and not k in mano:
			mano.append(k)
			cantidades[k] = entran
			if tipo == "":
				tipo = k
		elif repuesto.size() < REPUESTO:
			repuesto.append(k)
			en_repuesto.append(entran)
		else:
			break
		quedan -= entran
	return n - quedan


# Quita los montones que se han acabado. El hueco de la mano lo ocupa otro de repuesto (relevo). Si se acaba el que se
# lanzaba, se lanza el que ocupa su sitio (o el siguiente de la mano)
func repasar() -> void:
	for j in range(repuesto.size() - 1, -1, -1):
		if en_repuesto[j] <= 0:
			repuesto.remove_at(j)
			en_repuesto.remove_at(j)
	var i := 0
	while i < mano.size():
		var era: String = mano[i]
		if cuantas(era) > 0:
			i += 1
			continue
		var j := relevo(era)
		if j < 0:
			mano.remove_at(i)
		else:
			cantidades[era] = 0
			mano[i] = repuesto[j]
			cantidades[mano[i]] = en_repuesto[j]
			repuesto.remove_at(j)
			en_repuesto.remove_at(j)
		if tipo == era:
			tipo = mano[mini(i, mano.size() - 1)] if not mano.is_empty() else ""
	for k in cantidades.keys():   # (lo que no está a mano, a 0; los mejorados, fuera)
		if not k in mano:
			if calidad_de(k) > 0:
				cantidades.erase(k)
			else:
				cantidades[k] = 0
	if not tipo in mano:
		tipo = mano[0] if not mano.is_empty() else ""


# El montón de repuesto que pasa a la mano cuando se acaba el de esa clave (-1 si no queda ninguno): uno de la misma
# clave, si no uno del mismo tipo y si no, el primero (de los que no lleva ya a mano)
func relevo(k: String) -> int:
	var libres := range(repuesto.size()).filter(func(j): return repuesto[j] == k or not repuesto[j] in mano)
	for j in libres:
		if repuesto[j] == k:
			return j
	for j in libres:
		if tipo_de(repuesto[j]) == tipo_de(k):
			return j
	return libres[0] if not libres.is_empty() else -1


# Desde el inventario: pasa el montón "j" del repuesto a la mano, y es lo que se lanza. Si ya lleva esa clave a mano, se
# juntan (el de la mano se llena y lo que sobra se queda de repuesto). Si no, con la mano llena, cambia por lo que se
# lanzaba, que pasa a su sitio en el repuesto; con "por" (arrastrándolo encima de uno de la mano), cambia por ese
func a_la_mano(j: int, por := "") -> void:
	if j < 0 or j >= repuesto.size():
		return
	var k: String = repuesto[j]
	if k in mano:
		var entran := clampi(maximo(k) - cuantas(k), 0, en_repuesto[j])
		cantidades[k] += entran
		en_repuesto[j] -= entran
	elif mano.size() < MANO and not por in mano:
		mano.append(k)
		cantidades[k] = en_repuesto[j]
		en_repuesto[j] = 0
	else:
		var fuera := por if por in mano else tipo
		var n := cuantas(fuera)
		mano[mano.find(fuera)] = k
		cantidades[fuera] = 0
		cantidades[k] = en_repuesto[j]
		repuesto[j] = fuera
		en_repuesto[j] = n
	tipo = k
	repasar()   # (el montón de repuesto que se ha vaciado, fuera)


# ¿Se juntaría con el de la mano sin que pase nada? (el de repuesto "j" es de una clave que ya lleva a mano, y ese montón
# está lleno)
func mano_llena_de(j: int) -> bool:
	return j < repuesto.size() and repuesto[j] in mano and cuantas(repuesto[j]) >= maximo(repuesto[j])


# Y al revés: el montón "i" de la mano, al repuesto, si hay hueco
func al_repuesto(i: int) -> void:
	if i < 0 or i >= mano.size() or repuesto.size() >= REPUESTO:
		return
	var k: String = mano[i]
	repuesto.append(k)
	en_repuesto.append(cuantas(k))
	mano.remove_at(i)
	cantidades[k] = 0
	if tipo == k:
		tipo = mano[0] if not mano.is_empty() else ""
	repasar()


# Las que le quedan en el montón de la mano de esa clave (las de repuesto: cuantos_en)
func cuantas(k: String) -> int:
	return cantidades.get(k, 0)


# El nombre de un paquete («molotovs»), en plural y en minúscula, para dentro de una frase, en el idioma del jugador
func nombre(k: String) -> String:
	return varios(tipo_de(k))


# Cómo se dice uno de un tipo («Molotov») y cómo se dicen varios («molotovs»), en el idioma del jugador. Los plurales, uno por
# uno en su Idioma.t: en una tabla marcada, una palabra suelta en minúscula no la recogería la herramienta de traducciones
static func uno(cual: String) -> String:
	return Idioma.t(UNO[cual])


static func varios(cual: String) -> String:
	match cual:
		"molotov":
			return Idioma.t("molotovs")
		"granada":
			return Idioma.t("granadas")
		"atraedora":
			return Idioma.t("atraedoras")
	return Idioma.t("congeladoras")


# El color de su tipo (el de los textos y el apunte; el de la calidad, en el borde de la casilla: Armas.color)
func color(k: String) -> Color:
	return COLORES.get(tipo_de(k), Color(0.67, 0.67, 0.67))   # ("": sin nada a mano, en gris)


# Los que caben en un montón: MONTON, más los del Artificiero (o Criogenia) y los de su calidad
func maximo(k: String) -> int:
	return MONTON + extra_talentos(tipo_de(k), johnny.stats) + Armas.CALIDADES[calidad_de(k)].unidades


# Las unidades de más de un tipo por los talentos: el Artificiero, molotovs y granadas; Criogenia, congeladoras
static func extra_talentos(t: String, stats: Dictionary) -> int:
	if t in ARTIFICIERO:
		return stats.lanzar_extra
	return stats.congeladoras if t == "congeladora" else 0


# Quita "n" del montón de ese sitio (al guardarlos en el baúl; sin "n", el montón entero): devuelve cuántos ha quitado.
# Si se vacía el de la mano, su hueco lo ocupa otro de repuesto (repasar)
func quitar(sitio: String, n := 1000) -> int:
	var i := sitio.substr(1).to_int()
	var fuera := mini(n, cuantos_en(sitio))
	if fuera <= 0:
		return 0
	if sitio.begins_with("l"):
		cantidades[mano[i]] -= fuera
	else:
		en_repuesto[i] -= fuera
	repasar()
	return fuera


# Sube el montón de ese sitio a esa calidad (en el banco de trabajo): pasa a su clave nueva en el mismo hueco. Si es de
# la mano y ya llevaba a mano otro de esa calidad, se junta con él (el banco mira antes que quepan) y su hueco lo ocupa
# otro de repuesto. Devuelve el sitio donde queda
func mejorar(sitio: String, calidad: int) -> String:
	var k := clave_en(sitio)
	var nueva := clave(tipo_de(k), calidad)
	var i := sitio.substr(1).to_int()
	if sitio.begins_with("e"):
		repuesto[i] = nueva
		return sitio
	var n := cuantas(k)
	cantidades[k] = 0
	if nueva in mano:
		cantidades[nueva] += n
	else:
		mano[i] = nueva
		cantidades[nueva] = n
	if tipo == k:
		tipo = nueva
	repasar()   # (la clave vieja, si era de un mejorado, fuera)
	return sitio_de(nueva)


# Cuántos lleva de un tipo, sumando todos sus montones (el menú de pausa y la tienda)
func total(t: String) -> int:
	var n := 0
	for k in mano:
		if tipo_de(k) == t:
			n += cuantas(k)
	for i in repuesto.size():
		if tipo_de(repuesto[i]) == t:
			n += en_repuesto[i]
	return n


# Todos los montones que lleva, a mano y de repuesto: [[clave, cuántos], ...] (lo que va al baúl al completar el edificio)
func montones() -> Array:
	var lista := []
	for k in mano:
		lista.append([k, cuantas(k)])
	for i in repuesto.size():
		lista.append([repuesto[i], en_repuesto[i]])
	return lista


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


# Lo más lejos que se lanza: lo del molotov, con Puntería más (un 10 % por punto)
func alcance() -> float:
	return MOLOTOV.alcance * johnny.stats.alcance_lanzar


# Lo que suma la Adrenalina al daño de lo que se lanza (por debajo de la mitad de la vida), como en las armas
func adrenalina() -> float:
	return Talentos.ADRENALINA.dano if johnny.adrenalina() else 0.0


# Dónde caería (ver arriba), sin pasarse del alcance: como todo en el suelo, el alcance es una elipse
func objetivo() -> Vector2:
	var desde: Vector2 = johnny.global_position
	var hacia := Vector2.ZERO
	var stick := Input.get_vector("apuntar_izquierda", "apuntar_derecha", "apuntar_arriba", "apuntar_abajo")
	var solo: Node2D = johnny.buscar_objetivo({"tipo": "fuego", "alcance": alcance()}) 		if Guardado.ajuste("lanzar_solo") else null
	if solo:
		hacia = solo.global_position - desde   # ayuda "Lanzar apuntando solo"
	elif stick.length() > 0.25:
		hacia = Vector2(stick.x, stick.y * 0.6) * alcance()
	elif johnny.con_raton:
		hacia = get_global_mouse_position() - desde
	else:
		var zombi := mas_cercano()
		if zombi:
			hacia = zombi.global_position - desde
		else:
			hacia = Vector2.from_angle(johnny.DIRS.find(johnny.direccion) * PI / 4) * alcance() * 0.6
	var d := Vector2(hacia.x, hacia.y / 0.6).length()
	if d > alcance():
		hacia *= alcance() / d
	return desde + hacia


# El zombi más cercano a tiro (para lanzar con un toque, sin apuntar)
func mas_cercano() -> Node2D:
	var mejor: Node2D = null
	var cerca: float = alcance()
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
		var aviso := Idioma.t("¡Sin %s!") % nombre(tipo) if tipo != "" else Idioma.t("¡Nada que lanzar!")
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
		# Puntería, la skin del bombero (+50 %) y el Catalizador se suman, como en las armas (johnny.gd, arma_de); la
		# calidad multiplica
		p.dano_lanzar = (johnny.stats.dano_lanzar + Skins.quema(johnny.skin) + johnny.stats.dano_quimico - 2.0
			+ adrenalina()) * calidad.dano
		p.fabricante = johnny.stats.fabricante
		p.escala = calidad.radio
		# (las Épicas sueltan 2 más pequeños; el talento Racimo, 1 más por punto)
		p.racimo = (Armas.TRUCO.racimo if calidad_de(tipo) >= Armas.EPICA else 0) + johnny.stats.racimo
		sala.add_child(p)
	else:
		# la granada, o la atraedora o la congeladora (la misma granada, con su mecha, su radio y su efecto)
		var g := BOMBA.new()
		g.tipo = t
		g.desde = johnny.global_position
		g.hasta = donde
		g.radio = radio_zona()
		# (a la congeladora, el Catalizador también se le suma; y Criogenia la deja congelados más tiempo)
		var quimico: float = johnny.stats.dano_quimico - 1.0 if t == "congeladora" else 0.0
		g.dano_zombis = roundi(DATOS[t].dano * (johnny.stats.dano_lanzar + quimico + adrenalina()) * calidad.dano)
		if ARROJADIZAS.has(t):
			g.fabricante = johnny.stats.fabricante
			g.congela_extra = johnny.stats.congela_extra
		g.racimo = Armas.TRUCO.racimo if calidad_de(tipo) >= Armas.EPICA else 0
		if t == "granada":
			g.racimo += johnny.stats.racimo   # (Racimo: la granada, 1 granadita más por punto)
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
	elipse_a_trozos(desde, alcance(), Color(0.11, 0.1, 0.17, 0.45), 4.0, 0.0)
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
