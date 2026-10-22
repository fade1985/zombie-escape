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
#   minijefes         los minijefes de las plantas (las de tiendas en el centro comercial), uno por planta desde la baja:
#                     la partida los sortea (sin repetir) y en las plantas de más, o si aún no existe el que toca,
#                     sale "jefe". Sus datos, en MINIJEFES
#   azotea            (el centro comercial) la última planta no tiene tiendas: es la azotea (planta.gd, azotea), con
#                     el jefe final "final" ("el_final", cómo se le nombra). Mientras no tenga su escena en partida.gd
#                     (ZOMBIS), sale "jefe"
#   objetivo          el aviso al empezar cada planta
#   abre              el edificio que hay que completar antes para poder jugarlo ("" si está abierto desde el principio)
#   pasillo           el aspecto del pasillo de cada planta: su suelo, pared y tapa (mapa.gd, PASILLOS) y sus muebles
#                     (catalogo.gd, SALAS)
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
		"jefe": "portera",          # donde le toque a un minijefe sin hacer (y en la 4ª planta, mientras no haya azotea)
		"el_jefe": "la portera",
		"minijefes": ["portera", "gloton", "gymbro", "bombero"],
		"objetivo": "limpia los apartamentos y busca la llave de la portera",
		"abre": "",
		"pasillo": "pasillo",
	},
	"centro": {
		"nombre": "Centro comercial",
		"el_nombre": "el Centro comercial",
		"desc": "Tiendas saqueadas, almacenes a oscuras y un guardia que no suelta su tarjeta",
		"generador": "tienda",
		"sitios": "tiendas",
		"cerrojo": "tarjeta",
		"jefe": "portera",          # donde le toque a un minijefe sin hacer (y en la azotea, mientras no esté el gerente)
		"el_jefe": "la portera",
		"minijefes": ["antidisturbios", "cocinero", "modista", "mascota"],
		"azotea": true,
		"final": "gerente",
		"el_final": "el gerente",
		"objetivo": "limpia las tiendas y caza al guardia de seguridad: lleva la tarjeta de acceso",
		"abre": "apartamentos",
		"pasillo": "galeria",
	},
}

# Los minijefes: cómo se les nombra y, en el centro comercial (parte 4 del plan), cómo se llama su tienda (sola y
# con su artículo). En los Apartamentos (docs/JEFES_APARTAMENTOS.md) viven en un piso más, sin nombre propio.
# Mientras no tengan su escena en partida.gd (ZOMBIS), en su planta sale la portera
const MINIJEFES := {
	"portera": {"el": "la portera"},
	"gloton": {"el": "el Glotón"},
	"gymbro": {"el": "el Gymbro"},
	"bombero": {"el": "el jefe de bomberos"},
	"antidisturbios": {"el": "el antidisturbios", "tienda": "Oficina de seguridad", "la_tienda": "la Oficina de seguridad"},
	"cocinero": {"el": "el cocinero", "tienda": "Cocina central", "la_tienda": "la Cocina central"},
	"modista": {"el": "la modista", "tienda": "Taller de costura", "la_tienda": "el Taller de costura"},
	"mascota": {"el": "la mascota", "tienda": "Juguetería", "la_tienda": "la Juguetería"},
}

# El edificio elegido en el menú: la partida lo lee al empezar
static var elegido := "apartamentos"
# Tecla de prueba N en "Elige edificio": todos abiertos, sin haber completado los de antes (no se guarda)
static var abrir_todo := false


static func datos(id := "") -> Dictionary:
	return LISTA[id if id != "" else elegido]


# ¿Se puede jugar ya? (el centro comercial, solo después de completar los Apartamentos)
static func abierto(s: Dictionary, id: String) -> bool:
	var antes: String = LISTA[id].abre
	return abrir_todo or antes == "" or (s.edificios.has(antes) and s.edificios[antes].completado)
