# Los edificios que se pueden jugar (BUILDINGS de src/config.js del juego JS). Cada uno es una ficha con sus
# datos: añadir cosas a un edificio (su aspecto, sus zombis, su jefe...) es cambiar su ficha, sin tocar la partida.
#
#   nombre, desc      lo que sale en su tarjeta de la pantalla "Elige edificio" (menu_principal.gd)
#   el_nombre         con su artículo, para las frases ("los Apartamentos", "el Centro comercial")
#   generador         qué hay detrás de las puertas de cada planta: "apartamento" (apartamento.gd) o "tienda" (tienda.gd)
#   sitios            cómo se llaman esos sitios en los avisos ("apartamentos", "tiendas")
#   cerrojo           cómo se abre el sitio del jefe: "llave" (en el suelo de otro sitio) o "tarjeta" (la lleva
#                     el guardia de seguridad, que ronda el pasillo: zombi_guardia.gd)
#   jefe, el_jefe     el zombi jefe de cada planta (una escena de partida.gd, ZOMBIS) y cómo se le nombra
#   objetivo          el aviso al empezar cada planta
#   abre              el edificio que hay que completar antes para poder jugarlo ("" si está abierto desde el principio)
#   El dosier de cada edificio va por su id en historia.gd (DOSIERES) y el progreso, en el guardado (Guardado.edificio).
class_name Edificios

const LISTA := {
	"apartamentos": {
		"nombre": "Apartamentos",
		"el_nombre": "los Apartamentos",
		"desc": "Vecinos zombi, pisos a oscuras y una portera con muy mal genio",
		"generador": "apartamento",
		"sitios": "apartamentos",
		"cerrojo": "llave",
		"jefe": "portera",
		"el_jefe": "la portera",
		"objetivo": "limpia los apartamentos y busca la llave de la portera",
		"abre": "",
	},
	"centro": {
		"nombre": "Centro comercial",
		"el_nombre": "el Centro comercial",
		"desc": "Tiendas saqueadas, almacenes a oscuras y un guardia que no suelta su tarjeta",
		"generador": "tienda",
		"sitios": "tiendas",
		"cerrojo": "tarjeta",
		"jefe": "portera",          # de momento; los minijefes del centro comercial llegan en la parte 4
		"el_jefe": "la portera",
		"objetivo": "limpia las tiendas y caza al guardia de seguridad: lleva la tarjeta de acceso",
		"abre": "apartamentos",
	},
}

# El edificio elegido en el menú: la partida lo lee al empezar
static var elegido := "apartamentos"


static func datos(id := "") -> Dictionary:
	return LISTA[id if id != "" else elegido]


# ¿Se puede jugar ya? (el centro comercial, solo después de completar los Apartamentos)
static func abierto(s: Dictionary, id: String) -> bool:
	var antes: String = LISTA[id].abre
	return antes == "" or (s.edificios.has(antes) and s.edificios[antes].completado)
