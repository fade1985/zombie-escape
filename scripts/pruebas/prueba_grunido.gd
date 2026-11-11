# --grunido: el gruñido de zombi del botón JUGAR del menú principal (menu_principal.gd y Sonido.grunir). Lo lanza
# menu_principal.gd con "-- --captura --grunido". Otro botón cualquiera no gruñe; JUGAR sí, y pulsado otra vez enseguida
# no (GRUNIDO_HUECO). Y el gruñido (assets/sonidos/grunido.ogg): su largo, sin repetirse en bucle
class_name PruebaGrunido


static func probar(menu: Node) -> void:
	var otro := Button.new()
	menu.add_child(otro)
	var antes := Sonido.ultimo_grunido
	otro.pressed.emit()
	var con_otro := Sonido.ultimo_grunido != antes
	otro.queue_free()
	var jugar: Button = null
	for b: Button in menu.find_children("*", "Button", true, false):
		if b.text == Idioma.t("JUGAR"):
			jugar = b
	if jugar == null:
		print("ERROR: en el menú no está el botón JUGAR")
		return
	antes = Sonido.ultimo_grunido
	jugar.pressed.emit()
	var con_jugar := Sonido.ultimo_grunido != antes
	antes = Sonido.ultimo_grunido
	jugar.pressed.emit()
	var seguido := Sonido.ultimo_grunido != antes
	print("Gruñido · con otro botón: %s, con JUGAR: %s, con JUGAR otra vez enseguida: %s (esperado: false, true, false)" % [
		con_otro, con_jugar, seguido])
	print("Gruñido · dura %.2f s, en bucle %s, suena con él %s (esperado: 0.74 s, false, true)" % [
		Sonido.GRUNIDO.get_length(), Sonido.GRUNIDO.get("loop"), Sonido.voz_grunido != null and Sonido.voz_grunido.stream == Sonido.GRUNIDO])
