# Los edificios que se pueden jugar (BUILDINGS de src/config.js del juego JS). Cada uno es una ficha con sus
# datos: añadir cosas a un edificio (su aspecto, sus zombis, su jefe...) es cambiar su ficha, sin tocar la partida.
#
#   nombre, desc      lo que sale en su tarjeta de la pantalla "Elige edificio" (menu_principal.gd)
#   el_nombre         con su artículo, para las frases ("los Apartamentos", "el Centro comercial")
#   generador         qué hay detrás de las puertas de cada planta: "apartamento" (apartamento.gd), "tienda" (tienda.gd) o
#                     "departamento" (los de la torre: también en tienda.gd, los de su "edificio")
#   sitios            cómo se llaman esos sitios en los avisos ("apartamentos", "tiendas")
#   cerrojo           cómo se abre el sitio del jefe: "llave" (la lleva un zombi al azar de los otros sitios), "tarjeta" (la lleva
#                     el guardia de seguridad, que ronda el pasillo: zombi_guardia.gd) o "codigo" (sus tres cifras, en tres
#                     ordenadores encendidos de los departamentos: terminal.gd)
#   jefe, el_jefe     el zombi jefe de cada planta (una escena de partida.gd, ZOMBIS) y cómo se le nombra
#   minijefes         los minijefes de las plantas (las de tiendas en el centro comercial), uno por planta desde la baja:
#                     la partida los sortea (sin repetir) y en las plantas de más, o si aún no existe el que toca,
#                     sale "jefe". Sus datos, en MINIJEFES
#   azotea            la última planta no tiene pisos ni tiendas: es la azotea (planta.gd, azotea), con
#                     el jefe final "final" ("el_final", cómo se le nombra). Mientras no tenga su escena en partida.gd
#                     (ZOMBIS), sale "jefe"
#   objetivo          el aviso al empezar cada planta
#   abre              el edificio que hay que completar antes para poder jugarlo ("" si está abierto desde el principio)
#   pasillo           el aspecto del pasillo de cada planta: su suelo, pared y tapa (mapa.gd, PASILLOS) y sus muebles
#                     (catalogo.gd, SALAS)
#   El dosier de cada edificio va por su id en historia.gd (DOSIERES) y el progreso, en el guardado (Guardado.edificio).
# Los textos (nombre, el_nombre, desc, el_jefe, el_final, objetivo, "el", "tienda", "la_tienda") se traducen al enseñarlos
# con Idioma.t(): están entre las marcas [traducir] (docs/IDIOMAS.md)
class_name Edificios

# [traducir]
const LISTA := {
	"apartamentos": {
		"nombre": "Apartamentos",
		"el_nombre": "los Apartamentos",
		"desc": "Vecinos zombi, pisos a oscuras y una portera con muy mal genio",
		"generador": "apartamento",
		"sitios": "apartamentos",
		"cerrojo": "llave",
		"jefe": "portera",          # donde le toque a un minijefe sin hacer (y en la azotea, mientras no esté el científico)
		"el_jefe": "la portera",
		"minijefes": ["portera", "gloton", "gymbro", "bombero"],
		"azotea": true,
		"final": "cientifico_jefe",
		"el_final": "el doctor Salas",
		"objetivo": "limpia los apartamentos y caza al zombi que lleva la llave de la portera",
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
	# El tercer edificio (docs/PLAN_TERCER_EDIFICIO.md): la sede de Velaria, de oficinas. Parte 1, el esqueleto: sus
	# departamentos y el código; el pasillo, de momento, la galería del centro, y la planta 40, de momento, la azotea
	"torre": {
		"nombre": "Torre Velaria",
		"el_nombre": "Torre Velaria",
		"desc": "Oficinas de moqueta, empleados que no duermen y un laboratorio en la planta 40",
		"generador": "departamento",
		"sitios": "departamentos",
		"cerrojo": "codigo",
		"jefe": "portera",          # donde le toque a un minijefe sin hacer (y en la planta 40, mientras no esté el Sujeto 1)
		"el_jefe": "la portera",
		"minijefes": ["directora", "informatico", "presentador", "becario"],
		"azotea": true,
		"final": "sujeto_1",
		"el_final": "el Sujeto 1",
		"objetivo": "limpia los departamentos y busca las tres cifras del código en sus ordenadores",
		"abre": "centro",
		"pasillo": "torre",
	},
}

# Los minijefes: cómo se les nombra y, en el centro comercial (parte 4 del plan), cómo se llama su tienda (sola y
# con su artículo). En los Apartamentos (docs/historial/JEFES_APARTAMENTOS.md) viven en un piso más, sin nombre propio.
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
	# los de Torre Velaria (los que aún no están hechos: en su planta sale la portera). La directora, directora.gd; el
	# informático, informatico.gd; el presentador, presentador.gd; el becario, becario.gd
	"directora": {"el": "la directora de Recursos Humanos", "tienda": "Despacho de Recursos Humanos",
		"la_tienda": "el Despacho de Recursos Humanos"},
	"informatico": {"el": "el informático", "tienda": "Centro de datos", "la_tienda": "el Centro de datos"},
	"presentador": {"el": "el presentador", "tienda": "Plató de presentaciones", "la_tienda": "el Plató de presentaciones"},
	"becario": {"el": "el becario", "tienda": "Sala de fotocopias", "la_tienda": "la Sala de fotocopias"},
}
# [/traducir]

# El edificio elegido en el menú: la partida lo lee al empezar
static var elegido := "apartamentos"
# Tecla de prueba N en "Elige edificio": todos abiertos, sin haber completado los de antes (no se guarda)
static var abrir_todo := false


static func datos(id := "") -> Dictionary:
	return LISTA[id if id != "" else elegido]


# ¿Se puede jugar ya? Solo con los tres requisitos del edificio de antes cumplidos (requisitos(); desde el 10 nov: hasta
# entonces bastaba con completarlo). Los Apartamentos, abiertos desde el principio
static func abierto(s: Dictionary, id: String) -> bool:
	if abrir_todo or LISTA[id].abre == "":
		return true
	return requisitos(s, id).all(func(r): return r.hecho)


# Lo que pide un edificio para abrirse, todo del edificio de antes ("abre"): completarlo, conseguir todas las páginas de
# su dosier y ver todos sus vídeos (las noticias de la tele de los salones, VIDEOS.EXE). Salen en su tarjeta de «Elige
# edificio», uno por renglón. Cada uno: {"texto" (ya traducido), "hecho", "cuenta" ("3/5"; "" en el de completarlo)}.
# (Torre Velaria pide los vídeos del Centro comercial, que aún no tiene teles: M92. Hasta entonces no se puede abrir)
static func requisitos(s: Dictionary, id: String) -> Array:
	var antes: String = LISTA[id].abre
	if antes == "":
		return []
	var c := cuentas(s, antes)
	return [
		{"texto": Idioma.t("Completa %s") % Idioma.t(LISTA[antes].el_nombre), "cuenta": "", "hecho": c.completado},
		{"texto": Idioma.t("Consigue los dosieres"), "cuenta": "%d/%d" % [c.halladas, c.paginas],
			"hecho": c.halladas >= c.paginas},
		{"texto": Idioma.t("Ve todos los vídeos"), "cuenta": "%d/%d" % [c.vistas, c.noticias],
			"hecho": c.vistas >= c.noticias},
	]


# Lo que llevas de un edificio: si lo has completado, las páginas de su dosier halladas (de cuántas) y sus vídeos
# vistos (de cuántos)
static func cuentas(s: Dictionary, id: String) -> Dictionary:
	var paginas: Array = Historia.dosier(id).paginas
	var noticias := Historia.noticias_de(id)
	var vistos: Array = s.get("videos_vistos", [])
	return {"completado": s.edificios.has(id) and s.edificios[id].completado,
		"halladas": paginas.filter(func(p): return Historia.encontrada(s, p.id)).size(), "paginas": paginas.size(),
		"vistas": noticias.filter(func(n): return n.id in vistos).size(), "noticias": noticias.size()}


# El tanto por ciento de un edificio (al lado de «Completado» en su tarjeta): un tercio por completarlo, otro por las
# páginas de su dosier y otro por sus vídeos, cada página y cada vídeo con su parte de su tercio. Con 5 y 5, cada uno
# vale 6,7 %; completarlo, 33,3 %. (El centro comercial no pasa del 67 % hasta que tenga teles: M92)
static func porcentaje(s: Dictionary, id: String) -> int:
	var c := cuentas(s, id)
	var partes := (1.0 if c.completado else 0.0) + float(c.halladas) / maxi(c.paginas, 1) \
			+ float(c.vistas) / maxi(c.noticias, 1)
	return floori(partes / 3.0 * 100.0 + 0.001)   # (a la baja: el 100 %, solo con todo)
