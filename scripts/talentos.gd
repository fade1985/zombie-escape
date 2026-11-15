# El árbol de talentos (src/talentos.js del JS): tres ramas, Militar, Superviviente y Químico (M14, 28 oct: el
# conserje sabe de productos de limpieza; mejora el fuego, el ácido, el rayo y el frío), con cinco niveles cada una
# (M16, 28 oct: el 4, con un talento debajo de cada uno del 3, y el 5, la «corona» de la rama, que pide los tres del 4
# al máximo).
#
# Cada punto de un talento se compra directamente en él, con mutágeno (lo suelta cada durmiente; parte 2 del mutágeno,
# 15 nov), en el ordenador de la sala de mantenimiento (ui/ordenador.gd, TALENTOS.EXE): cada punto sube un nivel y
# cuesta más que el anterior del mismo talento (PRECIOS: 25, 50, 75, 100 y 125; los de un solo punto, 125). Llenar el
# árbol entero sale por 7.800. Se puede gastar el guardado más el de la partida en curso (partida.mutageno_total): se
# gasta primero el de la partida (el que se perdería al caer) y luego el guardado. Lo comprado es para siempre (se
# guarda en "talentos" del guardado). Resetear es gratis y no
# devuelve nada. Hasta el 15 nov se pagaban con los dólares ahorrados, y antes del 6 nov con «puntos de talento»: los
# guardados de entonces empiezan el árbol de cero (guardado.gd, "talentos_mutageno").
#
# Para tocar un talento basta con cambiar su línea en LISTA: "max" es cuántos puntos admite, "pide" el talento
# que hay que tener al máximo antes (o una lista, si son varios); lo que hace con n puntos está en aplicar_uno(). Lo que no es un número
# (esquivar solo, el escudo, el golpe de Ninja, resucitar...) lo lee Johnny de sus atributos (johnny.gd).
class_name Talentos

# Lo que cuesta, en mutágeno, cada punto dentro de un talento: el 1.º, el 2.º... Los talentos de un solo punto cuestan
# PRECIO_UNICO. Llenar el árbol entero sale por 7.800 (2.600 cada rama); una partida da unos 300-340
const PRECIOS := [25, 50, 75, 100, 125]
const PRECIO_UNICO := 125

# Los textos de RAMAS y de LISTA (nombre y desc) se traducen al enseñarlos, con nombre_rama(), nombre_de() y desc_de().
# Ojo: las desc no acaban en punto, porque ordenador.gd les pega detrás «. Te hace falta 1 punto.» y similares
# [traducir]
const RAMAS := [
	{"id": "militar", "nombre": "Militar", "icono": "rama-militar"},
	{"id": "superviviente", "nombre": "Superviviente", "icono": "rama-superviviente"},
	{"id": "quimico", "nombre": "Químico", "icono": "rama-quimico"},
]
# [/traducir]
# El rayo de Pararrayos (johnny.gd, pararrayos): su daño (con el Catalizador, más), lo que aturde, cada cuánto como
# mucho y lo cerca que tiene que estar el que te ha pegado (los que disparan de lejos, no)
const PARARRAYOS := {"dano": 10, "aturde": 0.5, "cada": 3.0, "alcance": 200.0}
# Adrenalina (johnny.gd): por debajo de "vida" de la vida máxima, + "dano" de daño (se suma, como los demás) y
# + "velocidad" de velocidad
const ADRENALINA := {"vida": 0.5, "dano": 0.15, "velocidad": 0.1}
# Mezcla explosiva (zombi.gd, quimica_al_morir): la explosión del que muere con dos efectos (su radio y su daño, que el
# Catalizador sube), y lo que le dura al zombi la marca del rayo después del calambre ("rayo", en segundos)
const MEZCLA := {"radio": 45.0, "dano": 15, "rayo": 1.5}

# [traducir]
const LISTA := [
	# ── Militar
	{"id": "ataque", "rama": "militar", "nivel": 1, "nombre": "Ataque", "max": 5, "icono": "talento-ataque",
		"desc": "+5 % de daño por punto"},
	{"id": "punteria", "rama": "militar", "nivel": 1, "nombre": "Puntería", "max": 5, "icono": "talento-punteria",
		"desc": "+5 % de daño y de alcance al utilizar un lanzable por punto"},
	{"id": "camorrista", "rama": "militar", "nivel": 2, "nombre": "Camorrista", "max": 5, "icono": "talento-camorrista", "pide": "ataque",
		"desc": "+5 % de daño cuerpo a cuerpo por punto"},
	{"id": "tirador", "rama": "militar", "nivel": 2, "nombre": "Tirador", "max": 5, "icono": "talento-tirador", "pide": "ataque",
		"desc": "+5 % de daño con armas a distancia por punto"},
	{"id": "artificiero", "rama": "militar", "nivel": 2, "nombre": "Artificiero", "max": 3, "icono": "talento-artificiero", "pide": "punteria",
		"desc": "+1 lanzable en cada montón por punto"},
	{"id": "larguirucho", "rama": "militar", "nivel": 3, "nombre": "Larguirucho", "max": 1, "icono": "talento-larguirucho", "pide": "camorrista",
		"desc": "Aumenta un 50 % el alcance cuerpo a cuerpo"},
	{"id": "mirilla", "rama": "militar", "nivel": 3, "nombre": "Mirilla", "max": 1, "icono": "talento-mirilla", "pide": "tirador",
		"desc": "Uno de cada 6 disparos es un crítico seguro (doble daño)"},
	{"id": "fabricante", "rama": "militar", "nivel": 3, "nombre": "Fabricante", "max": 1, "icono": "talento-fabricante", "pide": "artificiero",
		"desc": "Fuego y explosiones más grandes, y el fuego dura más"},
	{"id": "frenesi", "rama": "militar", "nivel": 4, "nombre": "Frenesí", "max": 3, "icono": "talento-frenesi", "pide": "larguirucho",
		"desc": "Golpeas cuerpo a cuerpo un 5 % más rápido por punto"},
	{"id": "gatillo", "rama": "militar", "nivel": 4, "nombre": "Gatillo fácil", "max": 3, "icono": "talento-gatillo", "pide": "mirilla",
		"desc": "Disparas un 5 % más rápido y recargas un 5 % antes por punto"},
	{"id": "racimo", "rama": "militar", "nivel": 4, "nombre": "Racimo", "max": 3, "icono": "talento-racimo", "pide": "fabricante",
		"desc": "Los lanzables sueltan 1 más pequeño alrededor por punto"},
	{"id": "veterano", "rama": "militar", "nivel": 5, "nombre": "Veterano", "max": 1, "icono": "talento-veterano",
		"pide": ["frenesi", "gatillo", "racimo"],
		"desc": "Críticos del 5 % al 10 % de las veces, y cada uno hace 2,5 veces el daño"},
	# ── Superviviente
	{"id": "corpulento", "rama": "superviviente", "nivel": 1, "nombre": "Corpulento", "max": 5, "icono": "talento-corpulento",
		"desc": "+5 % de vida máxima por punto"},
	# (hasta el 29 oct se llamaba Lobezno, pero Wolverine es marca de Marvel; el id se queda, que va en las partidas guardadas)
	{"id": "lobezno", "rama": "superviviente", "nivel": 1, "nombre": "Ajolote", "max": 5, "icono": "talento-lobezno",
		"desc": "Regeneras 1 de vida cada 10 segundos por punto, hasta la mitad de tu vida"},
	{"id": "durito", "rama": "superviviente", "nivel": 2, "nombre": "Durito", "max": 3, "icono": "talento-durito", "pide": "corpulento",
		"desc": "Cada golpe que recibes quita 2 menos por punto"},
	{"id": "reflejos", "rama": "superviviente", "nivel": 2, "nombre": "Reflejos", "max": 5, "icono": "talento-reflejos", "pide": "corpulento",
		"desc": "Esquivas el próximo golpe que vayas a recibir cada 10 s (0,5 s menos por cada punto más)"},
	{"id": "sanitario", "rama": "superviviente", "nivel": 2, "nombre": "Sanitario", "max": 5, "icono": "talento-sanitario", "pide": "lobezno",
		"desc": "Los botiquines y las vendas curan 5 más por punto"},
	{"id": "acero", "rama": "superviviente", "nivel": 3, "nombre": "Acero", "max": 1, "icono": "talento-acero", "pide": "durito",
		"desc": "Cada planta, un escudo de 25 que se gasta antes que la vida"},
	{"id": "ninja", "rama": "superviviente", "nivel": 3, "nombre": "Ninja", "max": 1, "icono": "talento-ninja", "pide": "reflejos",
		"desc": "Al acabar una esquiva, golpe en área que mata a los durmientes (como mucho cada 5 s)"},
	{"id": "desfibrilador", "rama": "superviviente", "nivel": 3, "nombre": "Desfibrilador", "max": 1, "icono": "talento-desfibrilador", "pide": "sanitario",
		"desc": "Una vez por edificio, si caes, resucitas con la mitad de la vida"},
	{"id": "blindaje", "rama": "superviviente", "nivel": 4, "nombre": "Blindaje", "max": 3, "icono": "talento-blindaje", "pide": "acero",
		"desc": "El escudo de Acero tiene 5 más por punto"},
	{"id": "sombra", "rama": "superviviente", "nivel": 4, "nombre": "Sombra", "max": 3, "icono": "talento-sombra", "pide": "ninja",
		"desc": "La esquiva se recarga un 7,5 % antes por punto"},
	{"id": "aliento", "rama": "superviviente", "nivel": 4, "nombre": "Segundo aliento", "max": 3, "icono": "talento-aliento", "pide": "desfibrilador",
		"desc": "Una vez por planta, al bajar de un tercio de la vida, te curas 7 por punto"},
	{"id": "adrenalina", "rama": "superviviente", "nivel": 5, "nombre": "Adrenalina", "max": 1, "icono": "talento-adrenalina",
		"pide": ["blindaje", "sombra", "aliento"],
		"desc": "Por debajo de la mitad de la vida, +15 % de daño y +10 % de velocidad"},
	# ── Químico
	{"id": "catalizador", "rama": "quimico", "nivel": 1, "nombre": "Catalizador", "max": 5, "icono": "talento-catalizador",
		"desc": "+5 % de daño de fuego, ácido, rayo y frío por punto"},
	{"id": "guantes_goma", "rama": "quimico", "nivel": 1, "nombre": "Guantes de goma", "max": 5, "icono": "talento-guantes-goma",
		"desc": "Fuego, ácido, venenos y frío te hacen un 5 % menos por punto"},
	{"id": "incendiario", "rama": "quimico", "nivel": 2, "nombre": "Incendiario", "max": 5, "icono": "talento-incendiario", "pide": "catalizador",
		"desc": "Los durmientes que prendes arden 0,25 s más por punto"},
	{"id": "desatascador", "rama": "quimico", "nivel": 2, "nombre": "Desatascador", "max": 5, "icono": "talento-desatascador", "pide": "catalizador",
		"desc": "Con ácido encima, todo les quita un 5 % más por punto"},
	{"id": "criogenia", "rama": "quimico", "nivel": 2, "nombre": "Criogenia", "max": 3, "icono": "talento-criogenia", "pide": "guantes_goma",
		"desc": "Congelan 0,25 s más por punto"},
	{"id": "reaccion", "rama": "quimico", "nivel": 3, "nombre": "Reacción en cadena", "max": 1, "icono": "talento-reaccion", "pide": "incendiario",
		"desc": "Los durmientes que mueren ardiendo revientan y prenden a los de al lado"},
	{"id": "residuo", "rama": "quimico", "nivel": 3, "nombre": "Residuo tóxico", "max": 1, "icono": "talento-residuo", "pide": "desatascador",
		"desc": "Los durmientes que mueren con ácido dejan un charco de ácido que afecta a todos"},
	{"id": "pararrayos", "rama": "quimico", "nivel": 3, "nombre": "Pararrayos", "max": 1, "icono": "talento-pararrayos", "pide": "criogenia",
		"desc": "Al durmiente que te golpea le salta un rayo que lo aturde y pasa a otro (como mucho cada 3 s)"},
	{"id": "napalm", "rama": "quimico", "nivel": 4, "nombre": "Napalm", "max": 3, "icono": "talento-napalm", "pide": "reaccion",
		"desc": "El fuego del molotov dura 0,5 s más por punto"},
	{"id": "pegajoso", "rama": "quimico", "nivel": 4, "nombre": "Pegajoso", "max": 3, "icono": "talento-pegajoso", "pide": "residuo",
		"desc": "Los durmientes con ácido van un 5 % más lentos por punto"},
	{"id": "voltaje", "rama": "quimico", "nivel": 4, "nombre": "Alto voltaje", "max": 3, "icono": "talento-voltaje", "pide": "pararrayos",
		"desc": "El rayo del lanza rayos y el de Pararrayos saltan a 1 durmiente más por punto"},
	{"id": "mezcla", "rama": "quimico", "nivel": 5, "nombre": "Mezcla explosiva", "max": 1, "icono": "talento-mezcla",
		"pide": ["napalm", "pegajoso", "voltaje"],
		"desc": "Los durmientes que mueren con dos efectos a la vez (fuego, ácido, rayo o frío) explotan"},
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


# Un número con un decimal como se escribe en el idioma del jugador: 0,5 en español, portugués, alemán, francés y ruso y 0.5
# en inglés y chino
static func decimal(x: float) -> String:
	return Idioma.puntuar(str(roundi(x)) if fmod(x, 1.0) == 0.0 else str(x))


# Puntos puestos en un talento
# Un porcentaje con decimales solo si hacen falta: 5, 7,5, 10, 12,5...
static func pct(x: float) -> String:
	return decimal(x)


static func nivel_de(s: Dictionary, id: String) -> int:
	return mini(int(s.talentos.get(id, 0)), talento(id).max)


# Lo que cuesta en mutágeno el próximo punto de este talento (con los que ya tiene en "s"; al máximo, lo del último)
static func precio(s: Dictionary, id: String) -> int:
	var t := talento(id)
	if int(t.max) == 1:
		return PRECIO_UNICO
	return PRECIOS[clampi(nivel_de(s, id), 0, PRECIOS.size() - 1)]


# ¿Se le puede poner un punto más con este mutágeno? Devuelve "" si se puede, o el motivo: "max", "bloqueado" o
# "sin_mutageno"
static func motivo(s: Dictionary, id: String, mutageno: int) -> String:
	var t := talento(id)
	if nivel_de(s, id) >= t.max:
		return "max"
	if not faltan(s, id).is_empty():
		return "bloqueado"
	if mutageno < precio(s, id):
		return "sin_mutageno"
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
		"ataque": st.dano *= 1.0 + 0.05 * n
		"punteria":
			st.dano_lanzar *= 1.0 + 0.05 * n
			st.alcance_lanzar *= 1.0 + 0.05 * n
		"camorrista": st.dano_cuerpo *= 1.0 + 0.05 * n
		"tirador": st.dano_fuego *= 1.0 + 0.05 * n
		"artificiero": st.lanzar_extra += n   # (uno más en cada montón de lanzables por punto: 15 nov; L38)
		"larguirucho": st.alcance_cuerpo *= 1.5
		"mirilla": st.mirilla = true
		"fabricante": st.fabricante = true
		"corpulento": st.vida_max = roundi(st.vida_max * (1.0 + 0.05 * n))
		"lobezno": st.regenera += n   # (cada REGENERA_CADA, ahora 10 s: la mitad)
		"durito": st.armadura += 2 * n   # (15 nov: antes 1 cada 2 puntos)
		"reflejos": st.esquiva_sola = 10.5 - 0.5 * n   # (15 nov: 10 s con un punto)
		"sanitario": st.botiquin_extra += 5 * n
		"acero": st.escudo = 25
		"ninja": st.ninja = true
		"desfibrilador": st.resucitar = true
		"catalizador": st.dano_quimico *= 1.0 + 0.05 * n
		"guantes_goma": st.resiste_quimico += 0.05 * n
		"incendiario": st.arde_extra += 0.25 * n
		"desatascador": st.corroe_extra += 0.05 * n
		"criogenia": st.congela_extra += 0.25 * n   # (15 nov: ya no da congeladoras; las da el Artificiero)
		"reaccion": st.reaccion = true
		"residuo": st.residuo = true
		"pararrayos": st.pararrayos = true
		"frenesi": st.ritmo_cuerpo *= 1.0 + 0.05 * n
		"gatillo":
			st.ritmo_fuego *= 1.0 + 0.05 * n
			st.recarga *= 1.0 - 0.05 * n
		"racimo": st.racimo += n   # (15 nov: uno por punto, en todos los lanzables)
		"veterano":
			st.critico += 0.05
			st.critico_x = 2.5
		"blindaje": st.escudo += 5 * n   # (15 nov: antes 12)
		"sombra": st.esquiva_espera *= 1.0 - 0.075 * n
		"aliento": st.aliento += 7 * n
		"adrenalina": st.adrenalina = true
		"napalm": st.napalm += 0.5 * n
		"pegajoso": st.pegajoso += 0.05 * n
		"voltaje": st.saltos += n   # (15 nov: uno por punto)
		"mezcla": st.mezcla = true


# Lo que da un talento con n puntos, en pocas palabras, para que en el ordenador se vea lo que se tiene y lo que da el
# siguiente (M15). "" en los de un solo punto (para esos vale su "desc")
static func efecto(id: String, n: int) -> String:
	match id:
		"ataque": return Idioma.t("+%s %% de daño") % pct(5.0 * n)
		"punteria": return Idioma.t("+%s %% de daño y alcance") % pct(5.0 * n)
		"camorrista": return Idioma.t("+%s %% cuerpo a cuerpo") % pct(5.0 * n)
		"tirador": return Idioma.t("+%s %% a distancia") % pct(5.0 * n)
		"artificiero": return Idioma.t("+%d en cada montón de lanzables") % n
		"corpulento": return Idioma.t("+%s %% de vida") % pct(5.0 * n)
		"lobezno": return Idioma.t("%d de vida cada 10 s") % n
		"durito": return Idioma.t("%d menos por golpe") % (2 * n)
		"reflejos": return Idioma.t("una esquiva sola cada %s s") % decimal(10.5 - 0.5 * n)
		"sanitario": return Idioma.t("+%d de cura") % (5 * n)
		"catalizador": return Idioma.t("+%s %% de fuego, ácido, rayo y frío") % pct(5.0 * n)
		"guantes_goma": return Idioma.t("%s %% menos de los efectos") % pct(5.0 * n)
		"incendiario": return Idioma.t("+%s s ardiendo") % decimal(0.25 * n)
		"desatascador": return Idioma.t("+%s %% con ácido") % pct(5.0 * n)
		"criogenia": return Idioma.t("+%s s congelados") % decimal(0.25 * n)
		"frenesi": return Idioma.t("+%s %% de rapidez cuerpo a cuerpo") % pct(5.0 * n)
		"gatillo": return Idioma.t("+%s %% de rapidez y recarga") % pct(5.0 * n)
		"racimo": return Idioma.t("suelta %d más") % n
		"blindaje": return Idioma.t("escudo de %d") % (25 + 5 * n)
		"sombra": return Idioma.t("esquiva un %s %% antes") % pct(7.5 * n)
		"aliento": return Idioma.t("+%d de vida por planta") % (7 * n)
		"napalm": return Idioma.t("+%s s de fuego") % decimal(0.5 * n)
		"pegajoso": return Idioma.t("%s %% más lentos con ácido") % pct(5.0 * n)
		"voltaje": return Idioma.t("salta a %d más") % n
	return ""


# Aplica los talentos comprados a unos atributos (al empezar la partida y al comprar uno). Devuelve los mismos
static func aplicar(st: Dictionary, talentos: Dictionary) -> Dictionary:
	for t in LISTA:
		var n := mini(int(talentos.get(t.id, 0)), t.max)
		if n > 0:
			aplicar_uno(st, t.id, n)
	return st


# Los puntos puestos en todo el árbol
static func puestos(s: Dictionary) -> int:
	var n := 0
	for t in LISTA:
		n += nivel_de(s, t.id)
	return n


# ¿Se puede resetear? Hace falta algún punto puesto (es gratis)
static func se_puede_resetear(s: Dictionary) -> bool:
	return puestos(s) > 0


# Quita todos los puntos puestos (M32). Lo gastado en ellos NO se devuelve (lo pidió el dueño el 6 nov: antes se
# devolvía todo menos $20). Devuelve el guardado nuevo, o {} si no se puede
static func resetear() -> Dictionary:
	var s := Guardado.cargar()
	if not se_puede_resetear(s):
		return {}
	s.talentos = {}
	Guardado.escribir(s)
	return s


# Compra un punto de un talento con el mutágeno de la partida "p": primero el cogido en esta partida (p.mutageno) y,
# si no llega, lo que falte del guardado ("mutageno"; lo pidió el dueño: si luego caes, solo pierdes lo que quedara de
# esta partida). Devuelve el guardado nuevo, o {} si no se puede.
# Lo gastado de esta partida se quita también de la partida a medias (la foto del principio de la planta:
# partida_guardada.gd): si no, cerrar el juego y darle a «Continuar partida» lo devolvería y se quedarían los talentos
static func subir(id: String, p: Node) -> Dictionary:
	var s := Guardado.cargar()
	if motivo(s, id, p.mutageno_ahorrado + p.mutageno) != "":
		return {}
	var cuesta := precio(s, id)
	var de_partida := mini(cuesta, p.mutageno)
	p.mutageno -= de_partida
	s.mutageno = maxi(s.mutageno - (cuesta - de_partida), 0)
	p.mutageno_ahorrado = s.mutageno
	s.talentos[id] = nivel_de(s, id) + 1
	PartidaGuardada.gastar_mutageno(s, de_partida)
	Guardado.escribir(s)
	return s
