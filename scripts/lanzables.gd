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
#     (2; más con la calidad y los talentos: maximo). Lleva MANO montones a mano, de la clave que quiera: desde el 16 nov
#     también dos o tres de la misma (F o RB cambian lo que se lanza entre ellos: elegido), y REPUESTO de repuesto (desde
#     el 13 nov, ninguno). No hay tope por tipo: se coge mientras quede sitio. Lo que consigue va a los montones de su
#     clave que no estén llenos (primero los de la mano); si están llenos, a un montón nuevo: a la mano si hay hueco, y si
#     no, al repuesto (y si tampoco, no lo coge: meter, cabe). Cuando se acaba el que se lanza, se lanza otro de su clave
#     (o el que ocupa su sitio); el hueco lo ocupa otro de repuesto, si hay (repasar). Desde el inventario se pasan de la
#     mano al repuesto y al revés (a_la_mano, al_repuesto), se cambian de sitio en la mano (mover_en_mano) y dos montones
#     de la misma clave sin llenar se juntan arrastrando uno encima del otro (juntar). Un
#     montón se señala por su "sitio", el nombre de su casilla en el inventario: "l1" el 2.º a mano, "e3" el 4.º de
#     repuesto (clave_en, cuantos_en).
#   - Al completar el edificio, todos los que le quedan van al baúl (partida.equipo_encima), también los Normales. En
#     el baúl, los del mismo tipo y calidad se juntan en casillas de un montón como el de la mano (Objetos.monton_arrojables)
#     (Objetos.arrojables_al_baul), y se sacan de montón en montón.
#   - La atraedora y la congeladora (ARROJADIZAS): se lanzan como la granada, con su propio efecto. Se
#     cuentan como el molotov y la granada.
#   - Desde el 15 nov no se empieza con ninguno ni los suelta ningún zombi (ni la barricada ni los supervivientes): se
#     compran en la tienda (van al baúl) o se sacan del baúl. La primera vez, la tienda regala un molotov, una granada y
#     una atraedora (tienda_armas.gd, REGALO_LANZABLES).
#   - Los cuatro se compran de uno en uno en la tienda de armas del ordenador (PRECIOS; ordenador.gd, comprar_lanzable).
#   - Cada paquete tiene su calidad (Armas.CALIDADES; parte 4 de la tienda y las piezas): la que no es Normal hace más
#     daño y con más radio (en su montón caben los mismos: F26). Los de un tipo con dos calidades van en montones distintos: su
#     "clave" es el tipo y, si no es Normal, su calidad detrás («molotov:2», unos molotovs Raros; clave, tipo_de y
#     calidad_de). Lo de la tienda es Normal.
# El molotov vuela en parábola (proyectil.gd) y deja un charco de fuego (charco.gd). La granada bota, rueda y
# explota a los 2 s (granada.gd).
class_name Lanzables
extends Node2D

# Números del molotov (provisionales, como en el JS)
const MOLOTOV := {
	"inicio": 0,       # botellas al empezar la partida (desde el 15 nov, ninguna: se compran en la tienda o se sacan del baúl;
	                   # antes 2. Y desde entonces ya no las suelta ningún zombi: antes, un 3 % de las veces)
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
	"inicio": 0,       # (como el molotov: antes 2, y un 2,5 % de las veces la soltaba un zombi)
	"vuelo": 0.45,     # segundos hasta tocar el suelo
	"mecha": 2.0,      # segundos desde el lanzamiento hasta que explota
	"radio": 110.0,    # radio de la explosión
	"dano": 80,        # daño de la explosión a los zombis (a Johnny, como mucho DANO_JOHNNY)
	"gravedad": 1400.0,
	"bote": 0.35,      # cuánta altura conserva al botar
	"rebote": 0.35,    # cuánta velocidad en el suelo conserva al botar
	"roce": 7.0,       # lo que frena al rodar
}
# Lo que les hacen a los jefes (la portera y los Minijefe) el fuego y las explosiones: la mitad (M42), para que no se
# caigan solo a base de lanzables. Lo miran explosion.gd, charco.gd (el fuego del suelo) y proyectil.gd (la llamarada)
const A_JEFES := 0.5
const FABRICANTE := {"radio": 1.15, "duracion": 1.25}   # el talento: fuego y explosiones más grandes y largos
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
# (15 nov, lo pidió el dueño: antes 5, 5, 8 y 8)
const PRECIOS := {"molotov": 5, "granada": 5, "atraedora": 10, "congeladora": 10}   # (16 nov: antes 2, 2, 4 y 4)
const COLORES := {"molotov": Color("#ff9f1c"), "granada": Color("#9bbd5a"), "atraedora": Color("#ffd23f"),
	"congeladora": Color("#9fe8ff")}   # (los de ARROJADIZAS)
const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")
const BOMBA := preload("res://scripts/granada.gd")
const MANO := 3            # los montones que lleva a mano (F cambia entre ellos)
const REPUESTO := 0        # y los de repuesto: ninguno desde el 13 nov (M67: antes 4; y antes aún, 8). El código de
                           # repuesto sigue, pero no se usa: solo se llevan los 3 a mano (los que sobran de una partida
                           # guardada van al baúl: partida_guardada.gd, sobrantes_al_baul)
const MONTON := 2          # los que caben en un montón (M74: antes 3; M42: antes 5; y antes aún, un tope por tipo: 5 molotovs, 4 granadas y 3 de las otras)

var johnny: Node2D
var partida: Node
var mano: Array = []           # las claves de los montones que lleva a mano, en el orden de F (desde el 16 nov pueden
                               # repetirse: dos o tres montones de molotovs, si quiere)
var en_mano: Array = []        # cuántos hay en cada montón de la mano (en el orden de "mano")
var elegido := 0               # el montón de la mano que se lanza ahora (su sitio en "mano")
var repuesto: Array = []       # y las de los de repuesto (puede haber varios de la misma)
var en_repuesto: Array = []    # cuántos hay en cada montón de repuesto (en el orden de "repuesto")
var quedan := {}               # las partidas que les quedan después de esta a los de cada clave (la durabilidad:
                               # Armas.nuevas); la que no está, las de unos nuevos de su calidad (quedan_de)
var tocado := -1               # el montón de la mano en el que acaba de entrar algo (meter: sitio_de lo enseña)
var apunte := Vector2.INF      # dónde caería, mientras se mantiene el botón (INF: no se apunta)
var apuntando := false         # se ha visto el botón apretado: al soltarlo, se lanza (y solo entonces)
var t := 0.0
# La clave del montón que se lanza ahora ("" si no lleva nada a mano). Al darle una clave, se elige el primer montón de
# la mano que la tenga (si no lleva ninguno, no cambia)
var tipo: String:
	get:
		return mano[elegido] if elegido >= 0 and elegido < mano.size() else ""
	set(valor):
		var i := mano.find(valor)
		if i >= 0:
			elegido = i


func _ready() -> void:
	top_level = true   # se dibuja en las coordenadas del mundo
	z_index = 15


# Por cuánto se multiplica el daño del fuego o de una explosión a ese zombi (A_JEFES a los jefes; 1 a los demás)
static func a_jefe(zombi: Node) -> float:
	return A_JEFES if zombi is Minijefe or zombi.get_meta("tipo", "") == "portera" else 1.0


# M107 (15 nov): lo que lanza Johnny, al explotar (la granada, la atraedora, la congeladora) o al romperse (el molotov),
# dentro de un apartamento se oye como un disparo (johnny.oir_disparo): despierta a todos los dormidos del piso, que van
# a por él. Fuera de los apartamentos no hace ruido (como antes)
static func ruido(desde: Node) -> void:
	var johnny := desde.get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.has_method("en_apartamento") and johnny.en_apartamento():
		johnny.oir_disparo()


# La clave de un paquete: el tipo y, si no es Normal, su calidad («molotov:2»)
static func clave(k: String, calidad: int) -> String:
	return k if calidad <= 0 else "%s:%d" % [k, calidad]


# El tipo de un paquete por su clave («molotov»)
static func tipo_de(k: String) -> String:
	return k.get_slice(":", 0)


# Y su calidad (0 = Normal)
static func calidad_de(k: String) -> int:
	return k.get_slice(":", 1).to_int() if ":" in k else 0


# Al empezar la partida: los de "inicio" de cada uno (desde el 15 nov, ninguno: ni con el Artificiero, que solo hace
# que quepan más en cada montón)
func reiniciar(_stats: Dictionary) -> void:
	mano = []
	en_mano = []
	for k in DATOS:
		if DATOS[k].inicio > 0:
			mano.append(k)
			en_mano.append(DATOS[k].inicio)
	elegido = 0
	repuesto = []
	en_repuesto = []
	quedan = {}
	tocado = -1


# El reto "Solo cuerpo a cuerpo": sin nada que lanzar
func vaciar() -> void:
	mano = []
	en_mano = []
	repuesto = []
	en_repuesto = []
	elegido = 0


# Pone "n" en el primer montón de la mano de esa clave (si no lleva ninguno, uno nuevo al final): para las pruebas y la
# sala de pruebas, que preparan lo que lleva sin pasar por meter
func poner(k: String, n: int) -> void:
	var i := mano.find(k)
	if i < 0:
		mano.append(k)
		en_mano.append(n)
	else:
		en_mano[i] = n


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
		return en_mano[i] if i < en_mano.size() else 0
	return en_repuesto[i] if sitio.begins_with("e") and i < en_repuesto.size() else 0


# El sitio de un montón de esa clave: el de la mano en el que acaba de entrar algo (tocado), si es de esa clave; si no,
# el primero de la mano y, si no la lleva a mano, el primero de repuesto ("" si no lleva)
func sitio_de(k: String) -> String:
	if tocado >= 0 and tocado < mano.size() and mano[tocado] == k:
		return "l%d" % tocado
	if k in mano:
		return "l%d" % mano.find(k)
	return "e%d" % repuesto.find(k) if k in repuesto else ""


# ¿Le cabe uno más de esa clave? En un montón suyo que no esté lleno, o en uno nuevo: a mano si hay hueco (desde el 16 nov,
# aunque ya lleve otro de esa clave) o de repuesto
func cabe(k: String) -> bool:
	for i in mano.size():
		if mano[i] == k and en_mano[i] < maximo(k):
			return true
	for i in repuesto.size():
		if repuesto[i] == k and en_repuesto[i] < maximo(k):
			return true
	return mano.size() < MANO or repuesto.size() < REPUESTO


# Coger uno (del suelo o de la tienda)
func sumar(k: String) -> void:
	meter(k, 1)


# Mete "n" de esa clave (los que coge o los que saca del baúl): primero en sus montones que no estén llenos (los de la
# mano, en orden) y luego en montones nuevos: a mano si hay hueco (aunque ya lleve otro de esa clave: 16 nov, lo pidió el
# dueño) y si no, de repuesto. Devuelve los que han entrado (los demás no caben)
func meter(k: String, n: int) -> int:
	self.quedan.erase(k)   # (unos nuevos: los de esa clave duran lo que unos nuevos, que es lo más que pueden durar)
	var quedan := n
	for i in mano.size():
		if quedan > 0 and mano[i] == k and en_mano[i] < maximo(k):
			var entran := mini(quedan, maximo(k) - en_mano[i])
			en_mano[i] += entran
			quedan -= entran
			tocado = i
	for i in repuesto.size():
		if quedan > 0 and repuesto[i] == k and en_repuesto[i] < maximo(k):
			var entran := mini(quedan, maximo(k) - en_repuesto[i])
			en_repuesto[i] += entran
			quedan -= entran
	while quedan > 0:
		var entran := mini(quedan, maximo(k))
		if mano.size() < MANO:
			if mano.is_empty():
				elegido = 0   # (no llevaba nada a mano: es lo que se lanza)
			mano.append(k)
			en_mano.append(entran)
			tocado = mano.size() - 1
		elif repuesto.size() < REPUESTO:
			repuesto.append(k)
			en_repuesto.append(entran)
		else:
			break
		quedan -= entran
	return n - quedan


# Mete "n" de esa clave que salen del baúl con "q" partidas por delante (la durabilidad: Armas.estrenar). Si ya llevaba
# de esa clave, se quedan las partidas de los que más tengan. Devuelve los que han entrado
func meter_de_baul(k: String, n: int, q: int) -> int:
	var antes := total_clave(k)
	var mas := quedan_de(k)
	var entran := meter(k, n)
	quedan[k] = maxi(q, mas) if antes > 0 else q
	return entran


# Las partidas que les quedan después de esta a los de esa clave (la durabilidad: Armas.nuevas)
func quedan_de(k: String) -> int:
	return int(quedan.get(k, Armas.nuevas(calidad_de(k))))


# Cuántos lleva de esa clave, en todos sus montones (a mano y de repuesto)
func total_clave(k: String) -> int:
	var n := 0
	for i in mano.size():
		if mano[i] == k:
			n += en_mano[i]
	for i in repuesto.size():
		if repuesto[i] == k:
			n += en_repuesto[i]
	return n


# Quita los montones que se han acabado. El hueco de la mano lo ocupa otro de repuesto (relevo). Si se acaba el que se
# lanzaba, se lanza otro montón de la misma clave que lleve a mano y, si no hay, el que ocupa su sitio (o el de antes)
func repasar() -> void:
	for j in range(repuesto.size() - 1, -1, -1):
		if en_repuesto[j] <= 0:
			repuesto.remove_at(j)
			en_repuesto.remove_at(j)
	var lanzaba := tipo
	var acabado := false   # (se ha acabado el que se lanzaba)
	var i := 0
	while i < mano.size():
		if en_mano[i] > 0:
			i += 1
			continue
		if i == elegido:
			acabado = true
		var j := relevo(mano[i])
		if j >= 0:
			mano[i] = repuesto[j]
			en_mano[i] = en_repuesto[j]
			repuesto.remove_at(j)
			en_repuesto.remove_at(j)
			continue
		mano.remove_at(i)
		en_mano.remove_at(i)
		if i < elegido:
			elegido -= 1
		if tocado == i:
			tocado = -1
		elif tocado > i:
			tocado -= 1
	elegido = clampi(elegido, 0, maxi(mano.size() - 1, 0))
	if acabado and lanzaba in mano and mano[elegido] != lanzaba:
		elegido = mano.find(lanzaba)


# El montón de repuesto que pasa a la mano cuando se acaba uno de esa clave (-1 si no queda ninguno): uno de la misma
# clave, si no uno del mismo tipo y si no, el primero
func relevo(k: String) -> int:
	if repuesto.is_empty():
		return -1
	if k in repuesto:
		return repuesto.find(k)
	for j in repuesto.size():
		if tipo_de(repuesto[j]) == tipo_de(k):
			return j
	return 0


# Desde el inventario: pasa el montón "j" del repuesto a la mano, y es lo que se lanza. Si lleva a mano uno de esa clave
# sin llenar, se juntan (lo que sobra se queda de repuesto). Si no, a un hueco libre de la mano; con la mano llena, cambia
# por lo que se lanzaba, que pasa a su sitio en el repuesto; con "por" (la clave de uno de la mano, arrastrándolo
# encima), cambia por ese
func a_la_mano(j: int, por := "") -> void:
	if j < 0 or j >= repuesto.size():
		return
	var k: String = repuesto[j]
	var a := -1
	for i in mano.size():
		if mano[i] == k and en_mano[i] < maximo(k):
			a = i
			break
	if a >= 0:
		var entran := clampi(maximo(k) - en_mano[a], 0, en_repuesto[j])
		en_mano[a] += entran
		en_repuesto[j] -= entran
	elif mano.size() < MANO and not por in mano:
		mano.append(k)
		en_mano.append(en_repuesto[j])
		en_repuesto[j] = 0
		a = mano.size() - 1
	else:
		a = mano.find(por) if por in mano else elegido
		var fuera: String = mano[a]
		var n: int = en_mano[a]
		mano[a] = k
		en_mano[a] = en_repuesto[j]
		repuesto[j] = fuera
		en_repuesto[j] = n
	elegido = a
	repasar()   # (el montón de repuesto que se ha vaciado, fuera)


# ¿Se pueden juntar el montón de "de" con el de "a" ("l1", "e3")? Si son de la misma clave (el mismo tipo y la misma
# calidad), sitios distintos y al de "a" aún le caben más
func se_juntan(de: String, a: String) -> bool:
	var k := clave_en(de)
	return de != a and k != "" and clave_en(a) == k and cuantos_en(a) < maximo(k)


# Desde el inventario (arrastrando uno encima del otro): pasa al montón de "a" todos los de "de" que le quepan; lo que no
# cabe se queda en "de". Si "de" se vacía, se quita (repasar). Devuelve los que han pasado
func juntar(de: String, a: String) -> int:
	if not se_juntan(de, a):
		return 0
	var k := clave_en(de)
	var pasan := mini(cuantos_en(de), maximo(k) - cuantos_en(a))
	for s in [[de, -pasan], [a, pasan]]:
		var i: int = s[0].substr(1).to_int()
		if s[0].begins_with("l"):
			en_mano[i] += s[1]
		else:
			en_repuesto[i] += s[1]
	repasar()
	return pasan


# Desde el inventario: el montón de la mano "i" pasa al sitio "j" de la mano (16 nov). Si allí hay otro de la misma clave
# sin llenar, se juntan (juntar); si hay otro, se cambian de sitio; si está vacío, va al final de los que lleva. El que se
# lanzaba sigue siendo el mismo montón. Devuelve el sitio donde queda ("l2")
func mover_en_mano(i: int, j: int) -> String:
	if i < 0 or i >= mano.size() or i == j:
		return "l%d" % i
	if se_juntan("l%d" % i, "l%d" % j):
		var antes := mano.size()
		juntar("l%d" % i, "l%d" % j)
		return "l%d" % (j - 1 if mano.size() < antes and i < j else j)
	var lanza := elegido
	j = mini(j, mano.size() - 1)
	var k: String = mano[i]
	var n: int = en_mano[i]
	mano[i] = mano[j]
	en_mano[i] = en_mano[j]
	mano[j] = k
	en_mano[j] = n
	elegido = j if lanza == i else i if lanza == j else lanza
	return "l%d" % j


# ¿Se juntaría con el de la mano sin que pase nada? Desde el 16 nov nunca: si los de su clave están llenos, va a un hueco
# libre o se cambia por el que se lanza (a_la_mano)
func mano_llena_de(_j: int) -> bool:
	return false


# Y al revés: el montón "i" de la mano, al repuesto, si hay hueco
func al_repuesto(i: int) -> void:
	if i < 0 or i >= mano.size() or repuesto.size() >= REPUESTO:
		return
	repuesto.append(mano[i])
	en_repuesto.append(en_mano[i])
	mano.remove_at(i)
	en_mano.remove_at(i)
	if i < elegido:
		elegido -= 1
	repasar()


# Las que le quedan en un montón de la mano de esa clave: el que se lanza, si es de esa clave, y si no, el primero (0 si
# no la lleva a mano; las de un sitio concreto, cuantos_en)
func cuantas(k: String) -> int:
	if k != "" and k == tipo:
		return en_mano[elegido]
	var i := mano.find(k)
	return en_mano[i] if i >= 0 else 0


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


# Los que caben en un montón: MONTON, más los del Artificiero (la calidad no cambia cuántos caben: F26, 16 nov)
func maximo(k: String) -> int:
	return cabe_en_monton(tipo_de(k), calidad_de(k), johnny.stats)


# Los que caben en un montón de ese tipo y esa calidad con esos atributos (también en una casilla del baúl:
# Objetos.monton_arrojables, con los talentos del guardado)
static func cabe_en_monton(t: String, _calidad: int, stats: Dictionary) -> int:
	return MONTON + extra_talentos(t, stats)


# Las unidades de más de un tipo por los talentos: el Artificiero, en todos (desde el 15 nov; antes solo molotovs y
# granadas, y Criogenia daba congeladoras)
static func extra_talentos(_t: String, stats: Dictionary) -> int:
	return stats.lanzar_extra


# Quita "n" del montón de ese sitio (al guardarlos en el baúl; sin "n", el montón entero): devuelve cuántos ha quitado.
# Si se vacía el de la mano, su hueco lo ocupa otro de repuesto (repasar)
func quitar(sitio: String, n := 1000) -> int:
	var i := sitio.substr(1).to_int()
	var fuera := mini(n, cuantos_en(sitio))
	if fuera <= 0:
		return 0
	if sitio.begins_with("l"):
		en_mano[i] -= fuera
	else:
		en_repuesto[i] -= fuera
	repasar()
	return fuera


# Cuántos lleva de un tipo, sumando todos sus montones (el menú de pausa y la tienda)
func total(t: String) -> int:
	var n := 0
	for i in mano.size():
		if tipo_de(mano[i]) == t:
			n += en_mano[i]
	for i in repuesto.size():
		if tipo_de(repuesto[i]) == t:
			n += en_repuesto[i]
	return n


# Todos los montones que lleva, a mano y de repuesto: [[clave, cuántos], ...] (lo que va al baúl al completar el edificio)
func montones() -> Array:
	var lista := []
	for i in mano.size():
		lista.append([mano[i], en_mano[i]])
	for i in repuesto.size():
		lista.append([repuesto[i], en_repuesto[i]])
	return lista


# Lo que se puede lanzar, en el orden del botón de cambiar: los que lleva a mano
func tipos() -> Array:
	return mano.duplicate()


func cambiar() -> void:
	if mano.is_empty():
		return
	elegido = (elegido + 1) % mano.size()
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


# El zombi más cercano a tiro (para lanzar con un toque, sin apuntar). Todo lo que se lanza choca con las paredes (las
# granadas rebotan y el molotov se rompe; desde el 10 nov, también él): a uno tras una pared no se le apunta
func mas_cercano() -> Node2D:
	var mejor: Node2D = null
	var cerca: float = alcance()
	var mapa := get_tree().get_first_node_in_group("mapa")
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if mapa and mapa.oculto(zombi.global_position):
			continue
		var d: float = johnny.global_position.distance_to(zombi.global_position)
		if d < cerca and (mapa == null or mapa.muro_entre(johnny.global_position, zombi.global_position).is_empty()):
			cerca = d
			mejor = zombi
	return mejor


func lanzar(donde: Vector2) -> void:
	if tipo != "" and Garaje.prohibido(tipo):   # (el garaje del reto del día, «Sin lanzables»: garaje.gd)
		Garaje.avisar(johnny)
		return
	if tipo == "" or cuantas(tipo) <= 0:
		var aviso := Idioma.t("¡Sin %s!") % nombre(tipo) if tipo != "" else Idioma.t("¡Nada que lanzar!")
		Zombi.texto_flotante(johnny.get_parent(), johnny.global_position + Vector2(-50, -80), aviso, color(tipo), 18)
		Sonido.tocar("no")
		return
	Sonido.tocar("lanzar")
	var sala: Node = johnny.get_parent()
	en_mano[elegido] -= 1
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
		g.racimo += johnny.stats.racimo   # (Racimo: todos los lanzables, 1 más pequeño por punto)
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
	Formas.disco(self, Vector2.ZERO, r, Color(tono, (0.35 if molotov else 0.3) * (0.85 + 0.15 * sin(t * 8.0))))
	Formas.arco(self, Vector2.ZERO, r, 0.0, TAU, 64, Color(0.11, 0.1, 0.17, 0.6), 6.0)
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
