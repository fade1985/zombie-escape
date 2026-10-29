# La prueba del idioma (-- --captura --idioma, con --ingles para verlo en inglés o --lang pt_BR / de / fr para los demás): las pantallas del menú en el idioma de la
# prueba (el menú, Opciones con sus cuatro pestañas y las licencias de Créditos, y "Elige edificio") y el cambio de idioma en
# caliente desde Opciones. De las licencias dice cuánto texto son y si a alguna letra le falta fuente.
# Con --alerta 3 --reto, "Elige edificio" sale con el selector de alerta y la tarjeta del reto. Al acabar, si algún texto
# no tiene traducción, idioma.gd lo cuenta al cerrar ("TEXTOS SIN TRADUCIR AL IDIOMA ...").
# Fotos: captura-idioma-opciones.png, -controles.png, -ayudas.png, -creditos.png, -licencias.png, -cambio.png y
# captura-idioma-edificios.png.
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
	if Idioma.actual in ["es", "en"]:   # (de los demás idiomas no se sabe de antemano lo que dirá: se ve en las fotos)
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
	o.ver("creditos")
	await arbol.create_timer(0.3).timeout
	Captura.foto("captura-idioma-creditos.png")
	# Las licencias: cuánto texto es, cuánto se tarda en ponerlo y si alguna de sus letras no la tiene ninguna fuente
	var antes_ms := Time.get_ticks_msec()
	o.ver("licencias")
	var ms := Time.get_ticks_msec() - antes_ms
	var licencias := Opciones.texto_de_licencias()
	var sin_letra := {}
	for i in licencias.length():
		if licencias.unicode_at(i) > 32 and not Tema.tiene_letra(licencias.unicode_at(i)):
			sin_letra[licencias[i]] = true
	print("Licencias: %d letras, puestas en %d ms · sin letra en las fuentes: %s (esperado: ninguna) · con Jersey 25: %s, con la de Godot: %s" % [
		licencias.length(), ms, "ninguna" if sin_letra.is_empty() else " ".join(sin_letra.keys()),
		"Soft Type" in licencias, "Godot Engine contributors" in licencias])
	await arbol.create_timer(0.3).timeout
	Captura.foto("captura-idioma-licencias.png")
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
