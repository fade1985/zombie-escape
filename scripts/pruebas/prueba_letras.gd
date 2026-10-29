# La prueba de las letras (-- --captura --letras): comprueba que cada letra de las traducciones la tiene alguna de las
# fuentes del juego (la de la interfaz, Jersey 25, la del cirílico y la del chino: Tema.tiene_letra). Una letra que no
# esté saldría como un cuadro (en la web, que no trae letras del sistema, seguro). Dice, de cada idioma, las que faltan.
class_name PruebaLetras


static func probar() -> void:
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
# (con la letra del juego a tamaño 16), que son los que se pasan de su caja. Dice, de cada idioma, los 25 que más se pasan:
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
		for k in mini(25, pasados.size()):
			var p: Array = pasados[k]
			print("   +%d · %d → %d: %s → %s" % [p[0], p[1], p[2], p[3], p[4]])
