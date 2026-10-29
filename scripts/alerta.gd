# Los niveles de alerta (parte 8 del centro comercial; como las ascensiones de The Binding of Isaac): de la
# Alerta 1 a la 5, por edificio. Cada nivel pone una regla fija y se suman: en la Alerta 3 valen la 1, la 2 y la 3.
# A cambio, un 20 % más de dólares y de piezas de mejora (Objetos.PIEZAS) por nivel (hasta el 25 oct, también armas de
# mejor rareza en el banco de trabajo, que ya no las crea).
#
# Se desbloquean de una en una: completar un edificio abre su Alerta 1; completarlo con la 1, la 2, y así. La más
# alta abierta y la elegida van en el progreso de cada edificio del guardado (alerta_max y alerta).
# Se eligen en "Elige edificio" (menu_principal.gd), que pone aquí el nivel de la partida antes de empezarla.
#
# Para cambiar los números, se cambian las constantes de abajo; la partida solo pregunta a estas funciones.
class_name Alerta

const MAX := 5
# Lo que añade cada nivel (sale en "Elige edificio" y al empezar la partida); para enseñarlo, regla(n), que lo traduce
# [traducir]
const REGLAS := [
	"",
	"+25 % de zombis",
	"Zombis un 10 % más rápidos",
	"Jefes con +25 % de vida, y se enfadan antes",
	"Botiquines, vendas y Lobezno curan la mitad",
	"El guardia (o el zombi de la llave) aguanta el doble y los zombis te oyen más lejos",
]
# [/traducir]
const MAS_ZOMBIS := 1.25     # A1: el presupuesto de zombis de cada sitio (planta.gd, horda)
const MAS_RAPIDOS := 1.1     # A2: la velocidad de los zombis (no la de los jefes)
const JEFE_VIDA := 1.25      # A3: la vida de los jefes de planta...
const JEFE_ENFADO := 0.7     # ...y a qué parte de su vida se enfadan (sin alerta, a la mitad: 0,5)
const BOTIQUIN := 0.5        # A4: lo que curan los botiquines (y Lobezno: tarda el doble; johnny.gd)
const GUARDIA_VIDA := 2.0    # A5: la vida del guardia de la tarjeta (o del zombi que lleva la llave)...
const OIDO := 1.5            # ...y la distancia a la que se oyen los disparos
const DOLARES := 0.2         # recompensa: dólares de más por cada nivel (al completar el edificio)
const PIEZAS := 0.2          # recompensa: piezas de más por cada nivel (las que sueltan los zombis y los jefes)

# El nivel de la partida que se juega (0 = sin alerta)
static var nivel := 0


static func mas_zombis() -> float:
	return MAS_ZOMBIS if nivel >= 1 else 1.0


static func velocidad() -> float:
	return MAS_RAPIDOS if nivel >= 2 else 1.0


static func jefe_vida() -> float:
	return JEFE_VIDA if nivel >= 3 else 1.0


static func jefe_enfado() -> float:
	return JEFE_ENFADO if nivel >= 3 else 0.5


static func botiquin() -> float:
	return BOTIQUIN if nivel >= 4 else 1.0


static func guardia() -> float:
	return GUARDIA_VIDA if nivel >= 5 else 1.0


static func oido() -> float:
	return OIDO if nivel >= 5 else 1.0


# Los dólares de más al completar el edificio
static func dolares_extra(dolares: int) -> int:
	return roundi(dolares * DOLARES * nivel)


# Por cuánto se multiplican las piezas que sueltan los zombis (y las de los jefes): 1 + 0,2 por nivel (con la Alerta 5,
# el doble: del 6 % al 12 %, y de 4 a 8 por jefe)
static func mas_piezas() -> float:
	return 1.0 + PIEZAS * nivel


# El nombre corto ("Alerta 3") y lo que trae ese nivel, para los textos
static func nombre(n := nivel) -> String:
	return Idioma.t("Alerta %d") % n if n > 0 else Idioma.t("Sin alerta")


# Lo que añade un nivel (REGLAS), en el idioma del jugador
static func regla(n := nivel) -> String:
	return Idioma.t(REGLAS[n])


static func resumen(n := nivel) -> String:
	if n <= 0:
		return Idioma.t("Como siempre")
	return Idioma.t("%s%s\n+%d %% de dólares y de piezas") % [regla(n), Idioma.t(" (y lo de antes)") if n > 1 else "",
		roundi(DOLARES * n * 100)]
