# El idioma del juego (cómo se traduce y cómo se escribe un texto: docs/IDIOMAS.md).
# El español es el idioma de origen: los textos del código están en español y cada uno es su propia clave. Los demás
# (locale/<código>.po: inglés, portugués de Brasil, alemán y francés) son traducciones. Si a un texto le falta su
# traducción, se ve en español y no se rompe nada.
#
# Es un autoload: se llama desde cualquier script, también desde los static:
#   Idioma.t("Salir")                              →  "Quit" en inglés, "Salir" en español
#   Idioma.t("Llevas %d") % n                      (los números y nombres se ponen DESPUÉS de traducir)
#   Idioma.n("%d intento", "%d intentos", n) % n   (singular y plural: cada idioma sabe cuándo usar cuál)
#   Idioma.t("Seguir", "pausa")                    (el mismo texto español que en otro idioma se dice distinto según
#                                                   el sitio: un contexto, que es parte de la clave)
# Se elige en Opciones y se guarda en ajustes.idioma. Si nunca se ha elegido, el del sistema (español, portugués, alemán o
# francés si el sistema está en uno de ellos y, si no, inglés). Con "-- --captura" siempre es español, salvo con
# "--ingles" o con "--lang <código>" (por ejemplo "--lang de").
# La señal "cambiado" avisa a las pantallas abiertas para que se vuelvan a escribir.
extends Node

signal cambiado

const ORIGEN := "es"
# Los idiomas del juego: [código, cómo se escribe en su propio idioma]
const IDIOMAS := [["es", "Español"], ["en", "English"], ["pt_BR", "Português (BR)"], ["de", "Deutsch"], ["fr", "Français"]]   # no-tr
# El idioma del sistema (OS.get_locale_language) → el del juego; los que no están, inglés
const DEL_SISTEMA := {"es": "es", "pt": "pt_BR", "de": "de", "fr": "fr"}

var actual := ORIGEN
# Solo en las pruebas con otro idioma: los textos que se han pedido y no están traducidos (se cuentan al cerrar)
var faltan := {}
var _letras := RegEx.create_from_string("[A-Za-zÀ-ÿ]{2}")


func _ready() -> void:
	poner(elegido(), false)


# El idioma con el que se arranca: el de la línea de órdenes (pruebas), el elegido en Opciones o el del sistema
func elegido() -> String:
	if Captura.activa():
		var args := OS.get_cmdline_user_args()
		if "--lang" in args and args.find("--lang") + 1 < args.size():
			return args[args.find("--lang") + 1]
		return "en" if "--ingles" in args else ORIGEN
	var guardado: String = Guardado.ajuste("idioma")
	if codigos().has(guardado):
		return guardado
	return DEL_SISTEMA.get(OS.get_locale_language(), "en")


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


# Un nombre (de un objeto, de una planta...) para meterlo en medio de una frase, en minúsculas. En alemán los nombres llevan
# siempre mayúscula: se dejan como están (con solo_inicial, solo se baja la primera letra: el texto de un botón en una línea
# de ayuda, «In die Truhe» → «in die Truhe»)
func minusculas(texto: String, solo_inicial := false) -> String:
	if actual != "de":
		return texto.to_lower()
	return texto.left(1).to_lower() + texto.substr(1) if solo_inicial else texto


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
