# El reto del día (parte 8 del centro comercial, trozo 4): cada día, el edificio sale igual para todo el mundo
# (la semilla de las plantas sale de la fecha: Planta.semilla) y con una regla rara, la misma para los dos
# edificios ese día. Sin servidor: solo compites contigo. La mejor marca de hoy de cada edificio va en el
# guardado ("retos", Guardado.RETO): hasta qué planta llegas y, si lo completas, en cuánto tiempo.
#
# Se entra por el botón "Reto del día" de cada tarjeta de "Elige edificio" (menu_principal.gd): empezar() pone
# aquí el reto antes de abrir la partida, y quitar() lo quita para una partida normal. Los dólares cuentan como
# siempre (y, la primera vez que se completa cada día en cada edificio, PREMIO de más), pero el reto va sin alerta,
# no abre niveles de alerta y no cuenta como edificio completado (partida.gd, terminar()).
#
# Para cambiar los números, se cambian las constantes; la partida solo pregunta a estas funciones. Una regla
# nueva: una entrada en REGLAS y la función a la que le pregunte la partida.
class_name Reto

# Las reglas raras: cada día toca una (regla_de). "nombre" sale en la tarjeta, en el HUD y en el cartel del
# final; "desc", en el aviso del principio
const REGLAS := {
	"cuerpo": {"nombre": "Solo cuerpo a cuerpo", "desc": "la pistola va vacía y no cae munición, ni molotovs ni granadas"},
	"oscuras": {"nombre": "Todo a oscuras", "desc": "todas las plantas como en un apagón: solo se ve con la linterna"},
	"curas": {"nombre": "Sin curas", "desc": "los armaritos están vacíos y no cae, ni se vende, ni te preparan nada que cure"},
	"rapidos": {"nombre": "Zombis rápidos", "desc": "todos un 35 % más rápidos (los jefes, no)"},
	"cristal": {"nombre": "De cristal", "desc": "Johnny con la mitad de vida"},
	"llena": {"nombre": "Casa llena", "desc": "el doble de zombis en cada sitio"},
	"oido": {"nombre": "Oído fino", "desc": "los zombis dormidos te oyen desde el triple de lejos"},
}
const MAS_RAPIDOS := 1.35   # rapidos: la velocidad de los zombis (no la de los jefes; partida.gd, meter_zombi)
const VIDA := 0.5           # cristal: la vida máxima de Johnny (partida.gd, aplicar_talentos)
const MAS_ZOMBIS := 2.0     # llena: el presupuesto de zombis de cada sitio (planta.gd, horda) y las oleadas de la horda
const OIDO := 3.0           # oido: la distancia a la que los zombis dormidos oyen los disparos (zombi.gd)
# El premio: estos dólares de más la primera vez que se completa el reto de hoy en cada edificio (premio(); se suman
# a los recogidos en partida.gd, terminar). Hasta el 27 oct el reto no daba nada más que su marca
const PREMIO := 10
# "oscuras" usa lo del apagón (eventos.gd, al_montar) y "cuerpo" y "curas" se miran donde se reparte cada cosa

# El reto que se juega: si es el reto, de qué día ("2026-10-22") y con qué regla (una clave de REGLAS)
static var activo := false
static var fecha := ""
static var regla := ""


# El día de hoy, como se escribe en el guardado
static func hoy() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


# La regla que toca un día: sale de la fecha, así que es la misma para todo el mundo (y para los dos edificios)
static func regla_de(dia: String) -> String:
	var claves := REGLAS.keys()
	return claves[("reto-" + dia).hash() % claves.size()]


# La semilla de las plantas de un edificio ese día (Planta.semilla): el mismo edificio para todo el mundo
static func semilla_de(dia: String, edificio: String) -> int:
	return maxi(1, ("reto-%s-%s" % [dia, edificio]).hash())


# "Elige edificio" lo llama antes de abrir la partida del reto de hoy...
static func empezar(edificio: String, dia := hoy()) -> void:
	activo = true
	fecha = dia
	regla = regla_de(dia)
	Planta.semilla = semilla_de(dia, edificio)


# ...o esto, para una partida normal
static func quitar() -> void:
	activo = false
	fecha = ""
	regla = ""
	Planta.semilla = 0


# ── Lo que pregunta la partida ──

static func es(cual: String) -> bool:
	return activo and regla == cual


# cuerpo: la pistola empieza vacía, no caen cajas de munición ni lanzables y la ayuda "pistola sin fin" no vale
static func sin_municion() -> bool:
	return es("cuerpo")


# oscuras: todos los sitios menos la sala de mantenimiento, como en el apagón (y el apagón no se sortea)
static func oscuras() -> bool:
	return es("oscuras")


# curas: los armaritos vacíos, sin el botiquín de la farmacéutica y los zombis no sueltan vendas ni bocadillos
# (objetos.gd, al_azar)
static func sin_curas() -> bool:
	return es("curas")


static func velocidad() -> float:
	return MAS_RAPIDOS if es("rapidos") else 1.0


static func vida() -> float:
	return VIDA if es("cristal") else 1.0


static func mas_zombis() -> float:
	return MAS_ZOMBIS if es("llena") else 1.0


static func oido() -> float:
	return OIDO if es("oido") else 1.0


# ── Los textos ──

static func nombre(r := regla) -> String:
	return REGLAS[r].nombre if r in REGLAS else ""


static func desc(r := regla) -> String:
	return REGLAS[r].desc if r in REGLAS else ""


# El aviso del principio de la partida
static func aviso() -> String:
	return "Reto del día · %s: %s" % [nombre(), desc()]


# Lo que se añade al nombre del sitio, arriba a la derecha (partida.gd, poner_lugar)
static func etiqueta() -> String:
	return " · Reto: " + nombre() if activo else ""


# ── La marca de hoy, en el guardado ──

# La ficha de hoy de un edificio (Guardado.RETO). Si la que hay es de otro día, se empieza de cero: el reto es nuevo
static func ficha(s: Dictionary, edificio: String, dia := fecha) -> Dictionary:
	if not edificio in s.retos or s.retos[edificio].fecha != dia:
		s.retos[edificio] = Guardado.RETO.duplicate()
		s.retos[edificio].fecha = dia
		s.retos[edificio].regla = regla_de(dia)
	return s.retos[edificio]


# Al ganar la partida del reto (partida.gd, terminar; antes de apuntar()): PREMIO si hoy aún no se había completado
# en ese edificio, 0 si ya
static func premio(s: Dictionary, edificio: String) -> int:
	return 0 if ficha(s, edificio).completado else PREMIO


# Al acabar la partida (partida.gd, terminar): apunta la marca si mejora la de hoy (llegar más lejos; con el
# edificio completado, hacerlo en menos tiempo). Devuelve si la ha mejorado
static func apuntar(s: Dictionary, edificio: String, planta_num: int, gano: bool, duracion: float) -> bool:
	var f := ficha(s, edificio)
	if gano:
		if f.completado and duracion >= f.tiempo:
			return false
		f.completado = true
		f.planta = Planta.PLANTAS
		f.tiempo = duracion
		return true
	if f.completado or planta_num <= f.planta:
		return false
	f.planta = planta_num
	return true


# La marca de una ficha, para la tarjeta ("Has llegado a la planta 3") o, corta, para el cartel del final ("planta 3")
static func marca(f: Dictionary, corta := false) -> String:
	if f.completado:
		var t := int(f.tiempo)
		return ("%d:%02d" if corta else "Completado en %d:%02d") % [t / 60, t % 60]
	if f.planta == 0:
		return "sin marca" if corta else "Sin marca"
	return ("planta %d" if corta else "Has llegado a la planta %d") % f.planta


# Lo de debajo del botón de la tarjeta: la regla de hoy y tu marca, con los intentos
static func texto_tarjeta(f: Dictionary) -> String:
	var linea := "Hoy: " + nombre(f.regla)
	if f.intentos == 0:
		return linea + "\nAún no lo has intentado"
	return "%s\n%s (%d intento%s)" % [linea, marca(f), f.intentos, "" if f.intentos == 1 else "s"]
