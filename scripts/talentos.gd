# El árbol de talentos (src/talentos.js del JS): dos ramas, Militar y Superviviente, con tres niveles cada una.
#
# Los puntos de talento se compran con los dólares ahorrados en el ordenador de la sala de mantenimiento
# (ui/ordenador.gd) y se gastan aquí, de uno en uno: cada punto sube un nivel del talento. Lo comprado es para
# siempre (se guarda en "talentos" del guardado). Los dólares de la partida en curso no cuentan hasta que
# completas el edificio.
#
# Para tocar un talento basta con cambiar su línea en LISTA: "max" es cuántos puntos admite, "pide" el talento
# que hay que tener al máximo antes; lo que hace con n puntos está en aplicar_uno(). Lo que no es un número
# (esquivar solo, el escudo, el golpe de Ninja, resucitar...) lo lee Johnny de sus atributos (johnny.gd).
class_name Talentos

const PRECIO_PUNTO := 10   # dólares que cuesta cada punto de talento (provisional, como en el JS)

const RAMAS := [
	{"id": "militar", "nombre": "Militar", "icono": "militar"},
	{"id": "superviviente", "nombre": "Superviviente", "icono": "medico"},
]

# Los que llevan "(fase 7)" en la nota se pueden comprar, pero aún no hacen nada: van con el molotov, la
# granada y los botiquines
const LISTA := [
	# ── Militar
	{"id": "ataque", "rama": "militar", "nivel": 1, "nombre": "Ataque", "max": 5, "icono": "fuerza",
		"desc": "+10 % de daño por punto"},
	{"id": "punteria", "rama": "militar", "nivel": 1, "nombre": "Puntería", "max": 5, "icono": "diana",
		"desc": "+10 % de daño del molotov y la granada por punto"},
	{"id": "camorrista", "rama": "militar", "nivel": 2, "nombre": "Camorrista", "max": 5, "icono": "bate", "pide": "ataque",
		"desc": "+10 % de daño cuerpo a cuerpo por punto"},
	{"id": "tirador", "rama": "militar", "nivel": 2, "nombre": "Tirador", "max": 5, "icono": "pistola", "pide": "ataque",
		"desc": "+10 % de daño con armas de fuego por punto"},
	{"id": "artificiero", "rama": "militar", "nivel": 2, "nombre": "Artificiero", "max": 3, "icono": "molotov", "pide": "punteria",
		"desc": "+1 molotov y +1 granada por punto"},
	{"id": "larguirucho", "rama": "militar", "nivel": 3, "nombre": "Larguirucho", "max": 1, "icono": "guantes", "pide": "camorrista",
		"desc": "Duplica el alcance cuerpo a cuerpo"},
	{"id": "mirilla", "rama": "militar", "nivel": 3, "nombre": "Mirilla", "max": 1, "icono": "escopeta", "pide": "tirador",
		"desc": "Cada 3 disparos, el siguiente es un crítico seguro"},
	{"id": "fabricante", "rama": "militar", "nivel": 3, "nombre": "Fabricante", "max": 1, "icono": "granada", "pide": "artificiero",
		"desc": "Fuego y explosiones más grandes, y el fuego dura más"},
	# ── Superviviente
	{"id": "corpulento", "rama": "superviviente", "nivel": 1, "nombre": "Corpulento", "max": 5, "icono": "vida",
		"desc": "+10 % de vida máxima por punto"},
	{"id": "lobezno", "rama": "superviviente", "nivel": 1, "nombre": "Lobezno", "max": 5, "icono": "corazon",
		"desc": "Regeneras 1 de vida cada 3 segundos por punto"},
	{"id": "durito", "rama": "superviviente", "nivel": 2, "nombre": "Durito", "max": 5, "icono": "casco", "pide": "corpulento",
		"desc": "Cada golpe que recibes quita 1 menos por punto"},
	{"id": "reflejos", "rama": "superviviente", "nivel": 2, "nombre": "Reflejos", "max": 5, "icono": "reflejos", "pide": "corpulento",
		"desc": "Esquivas solo un golpe cada 10 s (1 s menos por cada punto más)"},
	{"id": "sanitario", "rama": "superviviente", "nivel": 2, "nombre": "Sanitario", "max": 5, "icono": "botiquin", "pide": "lobezno",
		"desc": "Los botiquines, las vendas y la comida curan 10 más por punto"},
	{"id": "acero", "rama": "superviviente", "nivel": 3, "nombre": "Acero", "max": 1, "icono": "cartucho", "pide": "durito",
		"desc": "Cada planta, un escudo de 50 que para la mitad de cada golpe"},
	{"id": "ninja", "rama": "superviviente", "nivel": 3, "nombre": "Ninja", "max": 1, "icono": "dash", "pide": "reflejos",
		"desc": "Al acabar una esquiva, golpe en área que mata a los zombis"},
	{"id": "desfibrilador", "rama": "superviviente", "nivel": 3, "nombre": "Desfibrilador", "max": 1, "icono": "medico", "pide": "sanitario",
		"desc": "Una vez por edificio, si caes, resucitas con toda la vida"},
]

# Los que aún no hacen nada
const MAS_ADELANTE := []


static func talento(id: String) -> Dictionary:
	for t in LISTA:
		if t.id == id:
			return t
	return {}


# Puntos puestos en un talento
static func nivel_de(s: Dictionary, id: String) -> int:
	return mini(int(s.talentos.get(id, 0)), talento(id).max)


# ¿Se le puede poner un punto más? Devuelve "" si se puede, o el motivo: "max", "bloqueado" o "sin_puntos"
static func motivo(s: Dictionary, id: String) -> String:
	var t := talento(id)
	if nivel_de(s, id) >= t.max:
		return "max"
	if t.has("pide") and nivel_de(s, t.pide) < talento(t.pide).max:
		return "bloqueado"
	if s.puntos < 1:
		return "sin_puntos"
	return ""


# Lo que hace cada talento con n puntos sobre los atributos de Johnny (mejoras.gd)
static func aplicar_uno(st: Dictionary, id: String, n: int) -> void:
	match id:
		"ataque": st.dano *= 1.0 + 0.1 * n
		"punteria": st.dano_lanzar *= 1.0 + 0.1 * n
		"camorrista": st.dano_cuerpo *= 1.0 + 0.1 * n
		"tirador": st.dano_fuego *= 1.0 + 0.1 * n
		"artificiero": st.lanzar_extra += n
		"larguirucho": st.alcance_cuerpo *= 2.0
		"mirilla": st.mirilla = true
		"fabricante": st.fabricante = true
		"corpulento": st.vida_max = roundi(st.vida_max * (1.0 + 0.1 * n))
		"lobezno": st.regenera += n
		"durito": st.armadura += n
		"reflejos": st.esquiva_sola = 11 - n
		"sanitario": st.botiquin_extra += 10 * n
		"acero": st.escudo = 50
		"ninja": st.ninja = true
		"desfibrilador": st.resucitar = true


# Aplica los talentos comprados a unos atributos (al empezar la partida y al comprar uno). Devuelve los mismos
static func aplicar(st: Dictionary, talentos: Dictionary) -> Dictionary:
	for t in LISTA:
		var n := mini(int(talentos.get(t.id, 0)), t.max)
		if n > 0:
			aplicar_uno(st, t.id, n)
	return st


# Compra n puntos con los dólares ahorrados. Devuelve el guardado nuevo, o {} si no llega el dinero
static func comprar_puntos(n: int) -> Dictionary:
	var s := Guardado.cargar()
	if n < 1 or s.dolares < n * PRECIO_PUNTO:
		return {}
	s.dolares -= n * PRECIO_PUNTO
	s.puntos += n
	Guardado.escribir(s)
	return s


# Pone un punto en un talento. Devuelve el guardado nuevo, o {} si no se puede
static func subir(id: String) -> Dictionary:
	var s := Guardado.cargar()
	if motivo(s, id) != "":
		return {}
	s.puntos -= 1
	s.talentos[id] = nivel_de(s, id) + 1
	Guardado.escribir(s)
	return s
