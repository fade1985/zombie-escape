# El árbol de talentos (src/talentos.js del JS): tres ramas, Militar, Superviviente y Químico (M14, 28 oct: el
# conserje sabe de productos de limpieza; mejora el fuego, el ácido, el rayo y el frío), con cinco niveles cada una
# (M16, 28 oct: el 4, con un talento debajo de cada uno del 3, y el 5, la «corona» de la rama, que pide los tres del 4
# al máximo).
#
# Los puntos de talento se compran con los dólares ahorrados en el ordenador de la sala de mantenimiento
# (ui/ordenador.gd) y se gastan aquí, de uno en uno: cada punto sube un nivel del talento. Lo comprado es para
# siempre (se guarda en "talentos" del guardado). Los dólares de la partida en curso no cuentan hasta que
# acaba (todos si completas el edificio; la mitad si caes).
#
# Para tocar un talento basta con cambiar su línea en LISTA: "max" es cuántos puntos admite, "pide" el talento
# que hay que tener al máximo antes (o una lista, si son varios); lo que hace con n puntos está en aplicar_uno(). Lo que no es un número
# (esquivar solo, el escudo, el golpe de Ninja, resucitar...) lo lee Johnny de sus atributos (johnny.gd).
class_name Talentos

const PRECIO_PUNTO := 10   # dólares que cuesta cada punto de talento (provisional, como en el JS)

# Los textos de RAMAS y de LISTA (nombre y desc) se traducen al enseñarlos, con nombre_rama(), nombre_de() y desc_de().
# Ojo: las desc no acaban en punto, porque ordenador.gd les pega detrás «. Te hace falta 1 punto.» y similares
# [traducir]
const RAMAS := [
	{"id": "militar", "nombre": "Militar", "icono": "militar"},
	{"id": "superviviente", "nombre": "Superviviente", "icono": "medico"},
	{"id": "quimico", "nombre": "Químico", "icono": "obj-bidon_acido"},
]
# [/traducir]
# El rayo de Pararrayos (johnny.gd, pararrayos): su daño (con el Catalizador, más), lo que aturde, cada cuánto como
# mucho y lo cerca que tiene que estar el que te ha pegado (los que disparan de lejos, no)
const PARARRAYOS := {"dano": 20, "aturde": 1.0, "cada": 3.0, "alcance": 200.0}
# Adrenalina (johnny.gd): por debajo de "vida" de la vida máxima, + "dano" de daño (se suma, como los demás) y
# + "velocidad" de velocidad
const ADRENALINA := {"vida": 0.5, "dano": 0.3, "velocidad": 0.2}
# Mezcla explosiva (zombi.gd, quimica_al_morir): la explosión del que muere con dos efectos (su radio y su daño, que el
# Catalizador sube), y lo que le dura al zombi la marca del rayo después del calambre ("rayo", en segundos)
const MEZCLA := {"radio": 90.0, "dano": 30, "rayo": 1.5}

# [traducir]
const LISTA := [
	# ── Militar
	{"id": "ataque", "rama": "militar", "nivel": 1, "nombre": "Ataque", "max": 5, "icono": "fuerza",
		"desc": "+10 % de daño por punto"},
	{"id": "punteria", "rama": "militar", "nivel": 1, "nombre": "Puntería", "max": 5, "icono": "diana",
		"desc": "+10 % de daño y de alcance al lanzar el molotov y la granada por punto"},
	{"id": "camorrista", "rama": "militar", "nivel": 2, "nombre": "Camorrista", "max": 5, "icono": "bate", "pide": "ataque",
		"desc": "+10 % de daño cuerpo a cuerpo por punto"},
	{"id": "tirador", "rama": "militar", "nivel": 2, "nombre": "Tirador", "max": 5, "icono": "pistola", "pide": "ataque",
		"desc": "+10 % de daño con armas a distancia por punto"},
	{"id": "artificiero", "rama": "militar", "nivel": 2, "nombre": "Artificiero", "max": 3, "icono": "molotov", "pide": "punteria",
		"desc": "+1 molotov y +1 granada por punto"},
	{"id": "larguirucho", "rama": "militar", "nivel": 3, "nombre": "Larguirucho", "max": 1, "icono": "guantes", "pide": "camorrista",
		"desc": "Duplica el alcance cuerpo a cuerpo"},
	{"id": "mirilla", "rama": "militar", "nivel": 3, "nombre": "Mirilla", "max": 1, "icono": "escopeta", "pide": "tirador",
		"desc": "Uno de cada 3 disparos es un crítico seguro (doble daño)"},
	{"id": "fabricante", "rama": "militar", "nivel": 3, "nombre": "Fabricante", "max": 1, "icono": "granada", "pide": "artificiero",
		"desc": "Fuego y explosiones más grandes, y el fuego dura más"},
	{"id": "frenesi", "rama": "militar", "nivel": 4, "nombre": "Frenesí", "max": 3, "icono": "cuchillo", "pide": "larguirucho",
		"desc": "Golpeas cuerpo a cuerpo un 10 % más rápido por punto"},
	{"id": "gatillo", "rama": "militar", "nivel": 4, "nombre": "Gatillo fácil", "max": 3, "icono": "mp5", "pide": "mirilla",
		"desc": "Disparas un 10 % más rápido y recargas un 10 % antes por punto"},
	{"id": "racimo", "rama": "militar", "nivel": 4, "nombre": "Racimo", "max": 3, "icono": "obj-pieza_arrojable", "pide": "fabricante",
		"desc": "El molotov y la granada sueltan 1 más pequeño alrededor por punto"},
	{"id": "veterano", "rama": "militar", "nivel": 5, "nombre": "Veterano", "max": 1, "icono": "trofeo",
		"pide": ["frenesi", "gatillo", "racimo"],
		"desc": "Críticos del 5 % al 15 % de las veces, y cada uno hace el triple de daño"},
	# ── Superviviente
	{"id": "corpulento", "rama": "superviviente", "nivel": 1, "nombre": "Corpulento", "max": 5, "icono": "vida",
		"desc": "+10 % de vida máxima por punto"},
	{"id": "lobezno", "rama": "superviviente", "nivel": 1, "nombre": "Lobezno", "max": 5, "icono": "corazon",
		"desc": "Regeneras 1 de vida cada 5 segundos por punto, hasta la mitad de tu vida"},
	{"id": "durito", "rama": "superviviente", "nivel": 2, "nombre": "Durito", "max": 3, "icono": "casco", "pide": "corpulento",
		"desc": "Cada golpe que recibes quita 1 menos por punto"},
	{"id": "reflejos", "rama": "superviviente", "nivel": 2, "nombre": "Reflejos", "max": 5, "icono": "reflejos", "pide": "corpulento",
		"desc": "Esquivas solo un golpe cada 10 s (1 s menos por cada punto más)"},
	{"id": "sanitario", "rama": "superviviente", "nivel": 2, "nombre": "Sanitario", "max": 5, "icono": "botiquin", "pide": "lobezno",
		"desc": "Los botiquines y las vendas curan 10 más por punto"},
	{"id": "acero", "rama": "superviviente", "nivel": 3, "nombre": "Acero", "max": 1, "icono": "cartucho", "pide": "durito",
		"desc": "Cada planta, un escudo de 50 que se gasta antes que la vida"},
	{"id": "ninja", "rama": "superviviente", "nivel": 3, "nombre": "Ninja", "max": 1, "icono": "dash", "pide": "reflejos",
		"desc": "Al acabar una esquiva, golpe en área que mata a los zombis (como mucho cada 5 s)"},
	{"id": "desfibrilador", "rama": "superviviente", "nivel": 3, "nombre": "Desfibrilador", "max": 1, "icono": "medico", "pide": "sanitario",
		"desc": "Una vez por edificio, si caes, resucitas con toda la vida"},
	{"id": "blindaje", "rama": "superviviente", "nivel": 4, "nombre": "Blindaje", "max": 3, "icono": "herramientas", "pide": "acero",
		"desc": "El escudo de Acero tiene 25 más por punto"},
	{"id": "sombra", "rama": "superviviente", "nivel": 4, "nombre": "Sombra", "max": 3, "icono": "reflejos", "pide": "ninja",
		"desc": "La esquiva se recarga un 15 % antes por punto"},
	{"id": "aliento", "rama": "superviviente", "nivel": 4, "nombre": "Segundo aliento", "max": 3, "icono": "cafe", "pide": "desfibrilador",
		"desc": "Una vez por planta, al bajar de un tercio de la vida, te curas 15 por punto"},
	{"id": "adrenalina", "rama": "superviviente", "nivel": 5, "nombre": "Adrenalina", "max": 1, "icono": "alerta",
		"pide": ["blindaje", "sombra", "aliento"],
		"desc": "Por debajo de la mitad de la vida, +30 % de daño y +20 % de velocidad"},
	# ── Químico
	{"id": "catalizador", "rama": "quimico", "nivel": 1, "nombre": "Catalizador", "max": 5, "icono": "obj-gasolina",
		"desc": "+10 % de daño de fuego, ácido, rayo y frío por punto"},
	{"id": "guantes_goma", "rama": "quimico", "nivel": 1, "nombre": "Guantes de goma", "max": 5, "icono": "guantes",
		"desc": "Fuego, ácido, venenos y frío te hacen un 10 % menos por punto"},
	{"id": "incendiario", "rama": "quimico", "nivel": 2, "nombre": "Incendiario", "max": 5, "icono": "lanzallamas", "pide": "catalizador",
		"desc": "Los zombis que prendes arden 0,5 s más por punto"},
	{"id": "desatascador", "rama": "quimico", "nivel": 2, "nombre": "Desatascador", "max": 5, "icono": "desintegrador", "pide": "catalizador",
		"desc": "Con ácido encima, todo les quita un 10 % más por punto"},
	{"id": "criogenia", "rama": "quimico", "nivel": 2, "nombre": "Criogenia", "max": 3, "icono": "congeladora", "pide": "guantes_goma",
		"desc": "+1 congeladora por punto, y congelan 0,5 s más por punto"},
	{"id": "reaccion", "rama": "quimico", "nivel": 3, "nombre": "Reacción en cadena", "max": 1, "icono": "molotov", "pide": "incendiario",
		"desc": "Los zombis que mueren ardiendo revientan y prenden a los de al lado"},
	{"id": "residuo", "rama": "quimico", "nivel": 3, "nombre": "Residuo tóxico", "max": 1, "icono": "obj-bidon_acido", "pide": "desatascador",
		"desc": "Los zombis que mueren con ácido dejan un charco de ácido (a ti no te hace nada)"},
	{"id": "pararrayos", "rama": "quimico", "nivel": 3, "nombre": "Pararrayos", "max": 1, "icono": "obj-bateria", "pide": "criogenia",
		"desc": "Al zombi que te golpea le salta un rayo que lo aturde y pasa a otro (como mucho cada 3 s)"},
	{"id": "napalm", "rama": "quimico", "nivel": 4, "nombre": "Napalm", "max": 3, "icono": "obj-gasolina", "pide": "reaccion",
		"desc": "El fuego del molotov dura 1 s más por punto"},
	{"id": "pegajoso", "rama": "quimico", "nivel": 4, "nombre": "Pegajoso", "max": 3, "icono": "desintegrador", "pide": "residuo",
		"desc": "Los zombis con ácido van un 10 % más lentos por punto"},
	{"id": "voltaje", "rama": "quimico", "nivel": 4, "nombre": "Alto voltaje", "max": 3, "icono": "pistola_electrica", "pide": "pararrayos",
		"desc": "El rayo del lanza rayos y el de Pararrayos saltan a 1 zombi más por punto"},
	{"id": "mezcla", "rama": "quimico", "nivel": 5, "nombre": "Mezcla explosiva", "max": 1, "icono": "obj-pieza_especial",
		"pide": ["napalm", "pegajoso", "voltaje"],
		"desc": "Los zombis que mueren con dos efectos a la vez (fuego, ácido, rayo o frío) explotan (a ti no te hace nada)"},
]
# [/traducir]


static func talento(id: String) -> Dictionary:
	for t in LISTA:
		if t.id == id:
			return t
	return {}


# El nombre y la descripción de un talento, ya en el idioma del jugador
static func nombre_de(id: String) -> String:
	return Idioma.t(talento(id).get("nombre", ""))


static func desc_de(id: String) -> String:
	return Idioma.t(talento(id).get("desc", ""))


# El nombre de una rama ("militar"), ya en el idioma del jugador
static func nombre_rama(id: String) -> String:
	for r in RAMAS:
		if r.id == id:
			return Idioma.t(r.nombre)
	return ""


# Un número con un decimal como se escribe en el idioma del jugador: 0,5 en español, portugués, alemán y francés y 0.5 en inglés
static func decimal(x: float) -> String:
	var texto := str(x)
	return texto if Idioma.actual == "en" else texto.replace(".", ",")


# Puntos puestos en un talento
static func nivel_de(s: Dictionary, id: String) -> int:
	return mini(int(s.talentos.get(id, 0)), talento(id).max)


# ¿Se le puede poner un punto más? Devuelve "" si se puede, o el motivo: "max", "bloqueado" o "sin_puntos"
static func motivo(s: Dictionary, id: String) -> String:
	var t := talento(id)
	if nivel_de(s, id) >= t.max:
		return "max"
	if not faltan(s, id).is_empty():
		return "bloqueado"
	if s.puntos < 1:
		return "sin_puntos"
	return ""


# Los talentos que pide ("pide": uno o, en los del nivel 5, una lista)
static func requisitos(id: String) -> Array:
	var pide = talento(id).get("pide", [])
	return pide if pide is Array else [pide]


# Los que pide y aún no están al máximo
static func faltan(s: Dictionary, id: String) -> Array:
	return requisitos(id).filter(func(p): return nivel_de(s, p) < talento(p).max)


# Unos talentos en una frase: "Frenesí", "Frenesí y Racimo", "Frenesí, Gatillo fácil y Racimo"
static func nombres(ids: Array) -> String:
	var lista: Array = ids.map(func(p): return nombre_de(p))
	if lista.size() < 2:
		return "".join(lista)
	return Idioma.t("%s y %s") % [", ".join(lista.slice(0, -1)), lista[-1]]


# Lo que hace cada talento con n puntos sobre los atributos de Johnny (mejoras.gd)
static func aplicar_uno(st: Dictionary, id: String, n: int) -> void:
	match id:
		"ataque": st.dano *= 1.0 + 0.1 * n
		"punteria":
			st.dano_lanzar *= 1.0 + 0.1 * n
			st.alcance_lanzar *= 1.0 + 0.1 * n
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
		"catalizador": st.dano_quimico *= 1.0 + 0.1 * n
		"guantes_goma": st.resiste_quimico += 0.1 * n
		"incendiario": st.arde_extra += 0.5 * n
		"desatascador": st.corroe_extra += 0.1 * n
		"criogenia":
			st.congeladoras += n
			st.congela_extra += 0.5 * n
		"reaccion": st.reaccion = true
		"residuo": st.residuo = true
		"pararrayos": st.pararrayos = true
		"frenesi": st.ritmo_cuerpo *= 1.0 + 0.1 * n
		"gatillo":
			st.ritmo_fuego *= 1.0 + 0.1 * n
			st.recarga *= 1.0 - 0.1 * n
		"racimo": st.racimo += n
		"veterano":
			st.critico += 0.1
			st.critico_x = 3.0
		"blindaje": st.escudo += 25 * n
		"sombra": st.esquiva_espera *= 1.0 - 0.15 * n
		"aliento": st.aliento += 15 * n
		"adrenalina": st.adrenalina = true
		"napalm": st.napalm += n
		"pegajoso": st.pegajoso += 0.1 * n
		"voltaje": st.saltos += n
		"mezcla": st.mezcla = true


# Lo que da un talento con n puntos, en pocas palabras, para que en el ordenador se vea lo que se tiene y lo que da el
# siguiente (M15). "" en los de un solo punto (para esos vale su "desc")
static func efecto(id: String, n: int) -> String:
	match id:
		"ataque": return Idioma.t("+%d %% de daño") % (10 * n)
		"punteria": return Idioma.t("+%d %% de daño y alcance") % (10 * n)
		"camorrista": return Idioma.t("+%d %% cuerpo a cuerpo") % (10 * n)
		"tirador": return Idioma.t("+%d %% a distancia") % (10 * n)
		"artificiero": return Idioma.n("+%d molotov y granada", "+%d molotovs y granadas", n) % n
		"corpulento": return Idioma.t("+%d %% de vida") % (10 * n)
		"lobezno": return Idioma.t("%d de vida cada 5 s") % n
		"durito": return Idioma.t("%d menos por golpe") % n
		"reflejos": return Idioma.t("una esquiva sola cada %d s") % (11 - n)
		"sanitario": return Idioma.t("+%d de cura") % (10 * n)
		"catalizador": return Idioma.t("+%d %% de fuego, ácido, rayo y frío") % (10 * n)
		"guantes_goma": return Idioma.t("%d %% menos de los efectos") % (10 * n)
		"incendiario": return Idioma.t("+%s s ardiendo") % decimal(0.5 * n)
		"desatascador": return Idioma.t("+%d %% con ácido") % (10 * n)
		"criogenia": return Idioma.n("+%d congeladora y +%s s", "+%d congeladoras y +%s s", n) % [n, decimal(0.5 * n)]
		"frenesi": return Idioma.t("+%d %% de rapidez cuerpo a cuerpo") % (10 * n)
		"gatillo": return Idioma.t("+%d %% de rapidez y recarga") % (10 * n)
		"racimo": return Idioma.t("suelta %d más") % n
		"blindaje": return Idioma.t("escudo de %d") % (50 + 25 * n)
		"sombra": return Idioma.t("esquiva un %d %% antes") % (15 * n)
		"aliento": return Idioma.t("+%d de vida por planta") % (15 * n)
		"napalm": return Idioma.t("+%d s de fuego") % n
		"pegajoso": return Idioma.t("%d %% más lentos con ácido") % (10 * n)
		"voltaje": return Idioma.t("salta a %d más") % n
	return ""


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
