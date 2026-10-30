# La prueba de las letras (-- --captura --letras): comprueba que cada letra de las traducciones la tiene alguna de las
# fuentes del juego (la de la interfaz, Jersey 25, la del cirílico y la del chino: Tema.tiene_letra). Una letra que no
# esté saldría como un cuadro (en la web, que no trae letras del sistema, seguro). Dice, de cada idioma, las que faltan.
class_name PruebaLetras


static func probar() -> void:
	# Cuánto mide una línea en cada idioma con la cadena de letras de verdad (a 16): get_height es lo que usan los botones y las etiquetas
	# (22 en ruso y chino, 17 en los demás: la de reserva de esos idiomas es más alta) y texto, lo que mide una línea ya escrita
	for codigo in ["es", "ru", "zh_CN"]:
		Idioma.poner(codigo, false)
		var muestra: String = {"es": "Vecinos zombi", "ru": "Соседи-зомби", "zh_CN": "僵尸邻居"}[codigo]
		print("Altura de línea [%s]: get_height %.0f, «%s» %.0f" % [codigo, Tema.FUENTE.get_height(16), muestra, Tema.FUENTE.get_string_size(muestra, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).y])
	Idioma.poner(Idioma.ORIGEN, false)
	for i in Idioma.IDIOMAS:
		var codigo: String = i[0]
		if codigo == Idioma.ORIGEN:
			continue
		var tabla := TranslationServer.get_translation_object(codigo)
		if tabla == null:
			print("Letras [%s]: sin traducciones" % codigo)
			continue
		var vistas := {}
		var faltan := ""
		for texto in tabla.get_translated_message_list():
			for c in str(texto):
				var n := c.unicode_at(0)
				if n < 32 or vistas.has(n):
					continue
				vistas[n] = true
				if not Tema.tiene_letra(n):
					faltan += c
		print("Letras [%s]: %d distintas, faltan %d%s" % [codigo, vistas.size(), faltan.length(),
			(": " + faltan) if faltan != "" else " (todas están)"])


# La prueba de las medidas (-- --captura --medidas): los textos cortos que en un idioma salen bastante más anchos que en español
# (con la letra del juego a tamaño 16), que son los que se pasan de su caja. Dice, de cada idioma, los 25 que más se pasan
# (con --todo, todos):
# «+ancho en píxeles · ancho en español → ancho en el idioma: español → traducción». Mira solo los de una línea (hasta 340 px en español)
static func medidas() -> void:
	var tabla_es := TranslationServer.get_translation_object("en")   # (la lista de textos en español: los msgid de cualquiera)
	if tabla_es == null:
		return
	var originales: PackedStringArray = tabla_es.get_message_list()
	for i in Idioma.IDIOMAS:
		var codigo: String = i[0]
		if codigo == Idioma.ORIGEN:
			continue
		Idioma.poner(codigo, false)
		var tabla := TranslationServer.get_translation_object(codigo)
		var pasados := []
		for es in originales:
			if "
" in es or "%" in es and es.length() > 40:
				continue
			var tr: String = tabla.get_message(es)
			if tr == "":
				continue
			var a := Tema.FUENTE.get_string_size(es, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			if a > 340.0:
				continue
			var b := Tema.FUENTE.get_string_size(tr, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			if b - a > 18.0 and b > a * 1.15:
				pasados.append([b - a, a, b, es, tr])
		pasados.sort_custom(func(x, y): return x[0] > y[0])
		print("Medidas [%s]: %d textos cortos más anchos que en español (+18 px y +15 %%)" % [codigo, pasados.size()])
		for k in mini(1000 if "--todo" in OS.get_cmdline_user_args() else 25, pasados.size()):   # con --todo, todos
			var p: Array = pasados[k]
			print("   +%d · %d → %d: %s → %s" % [p[0], p[1], p[2], p[3], p[4]])


# La prueba de las tildes (-- --captura --tildes): una foto ampliada (letra a 48, tres veces su tamaño) con las letras con tilde y los
# signos de abrir ¿ y ¡ en cada idioma, para ver a ojo que ninguna sale al revés ni cambiada. Fotos: captura-tildes-<idioma>.png.
# Las dos primeras líneas son las del español (la letra del juego); la tercera, las del idioma que se juega (las que la letra del
# juego no trae salen de las de reserva: Jersey 25, Ark Pixel o Unifont)
static func tildes(menu: Control) -> void:
	var muestras := {
		"es": "áéíóú ÁÉÍÓÚ ñÑ üÜ",
		"en": "à è ï ô ü ç é ñ",
		"pt_BR": "ãõç áéíóú âêô àü",
		"de": "äöüß ÄÖÜ",
		"fr": "àâçéèêëîïôùûüÿ",
		"ru": "Привет, зомби!",
		"zh_CN": "你好, 僵尸!",
	}
	var fondo := ColorRect.new()
	fondo.color = Color("#17141f")
	fondo.theme = Tema.crear()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.z_index = 100
	menu.add_child(fondo)
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.offset_left = 24.0
	caja.offset_top = 16.0
	fondo.add_child(caja)
	var lineas: Array[Label] = []
	for i in 4:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 48)
		l.add_theme_constant_override("outline_size", 0)
		caja.add_child(l)
		lineas.append(l)
	for i in Idioma.IDIOMAS:
		var codigo: String = i[0]
		Idioma.poner(codigo, false)
		lineas[0].text = "áéíóú ÁÉÍÓÚ ñÑ üÜ"   # no-tr
		lineas[1].text = "¿Qué? ¡Sí! ¿Cómo?"   # no-tr
		lineas[2].text = muestras[codigo]   # no-tr
		lineas[3].text = "[%s] AEIOU aeiou" % codigo   # no-tr
		await menu.get_tree().create_timer(0.3).timeout
		Captura.foto("captura-tildes-%s.png" % codigo)
	fondo.queue_free()
