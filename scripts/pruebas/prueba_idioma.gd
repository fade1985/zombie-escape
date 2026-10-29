# La prueba del idioma (-- --captura --idioma, con --ingles para verlo en inglés): las pantallas del menú en el idioma de la
# prueba (el menú, Opciones con sus tres pestañas y "Elige edificio") y el cambio de idioma en caliente desde Opciones.
# Con --alerta 3 --reto, "Elige edificio" sale con el selector de alerta y la tarjeta del reto. Al acabar, si algún texto
# no tiene traducción, idioma.gd lo cuenta al cerrar ("TEXTOS SIN TRADUCIR AL IDIOMA ...").
# Fotos: captura-idioma-opciones.png, -controles.png, -ayudas.png, -cambio.png y captura-idioma-edificios.png.
class_name PruebaIdioma


static func probar(menu: Control) -> void:
	var arbol := menu.get_tree()
	var ingles := Idioma.actual == "en"
	print("Idioma de la prueba: %s (%s)" % [Idioma.actual, Idioma.nombre()])
	# Traducir, con número y con plural: el español no cambia y el inglés sí
	var salir := Idioma.t("Salir")
	var uno := Idioma.n("%d intento", "%d intentos", 1) % 1
	var tres := Idioma.n("%d intento", "%d intentos", 3) % 3
	print("  Salir → «%s» | 1 → «%s» | 3 → «%s» | con formato → «%s»" % [
		salir, uno, tres, Idioma.t("Has llegado a la planta %d de %d") % [3, 5]])
	var esperado := ["Quit", "1 attempt", "3 attempts"] if ingles else ["Salir", "1 intento", "3 intentos"]
	print("  %s" % ("BIEN: lo traducido es lo esperado" if [salir, uno, tres] == esperado else "MAL: se esperaba %s" % [esperado]))
	# Opciones: las tres pestañas
	var o := Opciones.abrir(menu, menu.centro)
	await arbol.create_timer(0.4).timeout
	Captura.foto("captura-idioma-opciones.png")
	o.ver("controles")
	await arbol.create_timer(0.3).timeout
	Captura.foto("captura-idioma-controles.png")
	o.ver("ayudas")
	await arbol.create_timer(0.3).timeout
	Captura.foto("captura-idioma-ayudas.png")
	# El cambio de idioma en caliente: la pantalla se monta otra vez, en la misma pestaña, y no queda ninguna vieja
	o.ver("general")
	var antes := Idioma.actual
	Idioma.siguiente()
	await arbol.create_timer(0.4).timeout
	var pantallas := menu.get_children().filter(func(n): return n is Opciones).size()
	var botones: Array = o.contenido.find_children("*", "Button", true, false)
	print("Cambio en caliente: %s → %s | pantallas de Opciones: %d | primer botón: «%s»" % [
		antes, Idioma.actual, pantallas, botones[0].text if not botones.is_empty() else "?"])
	Captura.foto("captura-idioma-cambio.png")
	Idioma.poner(antes, false)
	await arbol.create_timer(0.3).timeout
	o.cerrar()
	# Elige edificio
	menu.elegir_edificio()
	await arbol.create_timer(0.4).timeout
	Captura.foto("captura-idioma-edificios.png")
