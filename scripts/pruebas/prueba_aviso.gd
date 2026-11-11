# --aviso: el aviso de fotosensibilidad del menú principal (ui/aviso_luces.gd). Lo lanza menu_principal.gd con
# "-- --captura --aviso". Comprueba que sale encima del menú, que un Intro nada más salir no lo quita ni pulsa el botón de
# detrás, que pasado el rato un Intro sí lo quita (sin pulsar tampoco el de detrás) y que no vuelve a salir.
# Fotos: captura-aviso.png (el aviso) y captura-aviso-menu.png (el menú, ya sin él)
class_name PruebaAviso


static func probar(menu: Node) -> void:
	var arbol := menu.get_tree()
	var aviso: AvisoLuces = null
	for n in menu.get_children():
		if n is AvisoLuces:
			aviso = n
	print("Aviso · sale encima del menú: %s (esperado: true)" % (aviso != null))
	if aviso == null:
		return
	intro()
	await arbol.process_frame
	print("Aviso · con un Intro nada más salir: sigue %s, el menú sigue a la vista %s (esperado: true, true)" % [
		is_instance_valid(aviso) and aviso.is_processing_input(), menu.centro.visible])
	Captura.foto("captura-aviso.png")
	await arbol.create_timer(AvisoLuces.ESPERA + 0.1).timeout
	intro()
	await arbol.create_timer(AvisoLuces.FUNDIDO + 0.2).timeout
	print("Aviso · con un Intro pasado el rato: se ha ido %s, el menú sigue a la vista %s (esperado: true, true)" % [
		not is_instance_valid(aviso), menu.centro.visible])
	Captura.foto("captura-aviso-menu.png")
	print("Aviso · al volver al menú, sale otra vez: %s (esperado: false)" % (AvisoLuces.poner(menu) != null))


# Un Intro pulsado y soltado, como si fuera del teclado
static func intro() -> void:
	for pulsada in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = KEY_ENTER
		ev.physical_keycode = KEY_ENTER
		ev.pressed = pulsada
		Input.parse_input_event(ev)
