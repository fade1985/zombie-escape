# El idioma del juego (cómo se traduce y cómo se escribe un texto: docs/IDIOMAS.md).
# El español es el idioma de origen: los textos del código están en español y cada uno es su propia clave. El inglés es
# el segundo idioma (locale/en.po); otros idiomas, más adelante. Si a un texto le falta su traducción, se ve en español
# y no se rompe nada.
#
# Es un autoload: se llama desde cualquier script, también desde los static:
#   Idioma.t("Salir")                              →  "Quit" en inglés, "Salir" en español
#   Idioma.t("Llevas %d") % n                      (los números y nombres se ponen DESPUÉS de traducir)
#   Idioma.n("%d intento", "%d intentos", n) % n   (singular y plural: cada idioma sabe cuándo usar cuál)
#   Idioma.t("Seguir", "pausa")                    (el mismo texto español que en otro idioma se dice distinto según
#                                                   el sitio: un contexto, que es parte de la clave)
# Se elige en Opciones y se guarda en ajustes.idioma. Si nunca se ha elegido, el del sistema: español si el sistema está
# en español y inglés si no. Con "-- --captura" siempre es español, salvo con "--ingles".
# La señal "cambiado" avisa a las pantallas abiertas para que se vuelvan a escribir.
extends Node

signal cambiado

const ORIGEN := "es"
# Los idiomas del juego: [código, cómo se escribe en su propio idioma]
const IDIOMAS := [["es", "Español"], ["en", "English"]]   # no-tr

var actual := ORIGEN
# Solo en las pruebas con otro idioma: los textos que se han pedido y no están traducidos (se cuentan al cerrar)
var faltan := {}
var _letras := RegEx.create_from_string("[A-Za-zÀ-ÿ]{2}")


func _ready() -> void:
	poner(elegido(), false)


# El idioma con el que se arranca: el de la línea de órdenes (pruebas), el elegido en Opciones o el del sistema
func elegido() -> String:
	if Captura.activa():
		return "en" if "--ingles" in OS.get_cmdline_user_args() else ORIGEN
	var guardado: String = Guardado.ajuste("idioma")
	if codigos().has(guardado):
		return guardado
	return "es" if OS.get_locale_language() == "es" else "en"


func codigos() -> Array:
	return IDIOMAS.map(func(i): return i[0])


# El nombre de un idioma, en ese idioma ("English")
func nombre(codigo := actual) -> String:
	for i in IDIOMAS:
		if i[0] == codigo:
			return i[1]
	return codigo


# Cambia de idioma (guardar: que se recuerde la próxima vez; con --captura nunca se guarda)
func poner(codigo: String, guardar := true) -> void:
	if not codigos().has(codigo):
		codigo = ORIGEN
	var antes := actual
	actual = codigo
	TranslationServer.set_locale(codigo)
	if guardar and not Captura.activa():
		Guardado.cambiar(func(g): g.ajustes.idioma = codigo)
	if codigo != antes:
		cambiado.emit()


# Pasa al siguiente idioma de la lista (el botón de Opciones)
func siguiente() -> void:
	var lista := codigos()
	poner(lista[(lista.find(actual) + 1) % lista.size()])


# Traduce un texto (el español de origen es la clave)
func t(texto: String, contexto := "") -> String:
	if actual == ORIGEN or texto == "":
		return texto
	if Captura.activa() and _letras.search(texto):   # (lo que no tiene letras, "100 %", no se traduce)
		var tabla := TranslationServer.get_translation_object(actual)
		if tabla == null or tabla.get_message(texto, contexto) == "":
			faltan[texto] = true
	return TranslationServer.translate(texto, contexto)


# Traduce un texto que cambia con la cantidad: el singular y el plural en español, y cuántos hay
func n(uno: String, varios: String, cantidad: int, contexto := "") -> String:
	if actual == ORIGEN:
		return uno if cantidad == 1 else varios
	if Captura.activa():
		var tabla := TranslationServer.get_translation_object(actual)
		if tabla == null or tabla.get_plural_message(uno, varios, cantidad, contexto) == "":
			faltan[uno] = true
	return TranslationServer.translate_plural(uno, varios, cantidad, contexto)


# Al cerrar una prueba en otro idioma: qué textos se han pedido sin tener traducción
func _exit_tree() -> void:
	if faltan.is_empty():
		return
	var lista := faltan.keys()
	print("TEXTOS SIN TRADUCIR AL IDIOMA «%s» (%d): %s" % [actual, lista.size(), " | ".join(lista.slice(0, 40))])
