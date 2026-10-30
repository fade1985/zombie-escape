# La prueba del mando en los menús (-- --captura --mando): A confirma y B vuelve. Godot, de serie, no trae el botón A en
# ui_accept ni el B en ui_cancel (los menús solo se cerraban con Esc, Start o con su atajo); los pone project.godot. Aquí
# se pulsan botones del mando de verdad (InputEventJoypadButton, no la acción), para que si alguien quita A o B de esas
# dos acciones se note. Esta parte es la del menú principal (menu_principal.gd la lanza antes de pasar a la partida de
# prueba); la de la partida (pausa, Opciones, tutorial, inventario...) es probar_mando() de prueba_varias.gd. Las dos
# usan boton() y pulsar() de aquí
class_name PruebaMando


# Un botón del mando pulsado (o soltado)
static func boton(cual: JoyButton, pulsado := true) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = cual
	e.pressed = pulsado
	return e


# Pulsa y suelta un botón del mando, como un dedo de verdad, y espera a que llegue
static func pulsar(arbol: SceneTree, cual: JoyButton) -> void:
	for pulsado in [true, false]:
		Input.parse_input_event(boton(cual, pulsado))
		await arbol.process_frame
	await arbol.create_timer(0.2).timeout


# Lo que tiene el foco, para contarlo: el texto del botón (o, si no tiene, el nombre del nodo)
static func marcado(nodo: Node) -> String:
	var f := nodo.get_viewport().gui_get_focus_owner()
	if f == null:
		return "-"
	return f.text if f is Button and f.text != "" else String(f.name)


# El botón con ese texto, dentro de ese nodo (null si no está)
static func buscar(dentro: Node, texto: String) -> Button:
	for b: Button in dentro.find_children("*", "Button", true, false):
		if b.text == texto:
			return b
	return null


# El menú principal: JUGAR con A abre «Elige edificio» y B vuelve; Opciones y Tutorial, igual
static func menu_principal(menu: Control) -> void:
	var arbol := menu.get_tree()
	var abierta := func(clase: Variant) -> bool:   # ¿hay una pantalla de esa clase delante?
		return menu.get_children().any(func(n): return is_instance_of(n, clase) and not n.is_queued_for_deletion())
	await arbol.create_timer(0.3).timeout
	var jugar := buscar(menu.centro, Idioma.t("JUGAR"))
	jugar.grab_focus()
	await pulsar(arbol, JOY_BUTTON_A)
	print("Mando · menú, A en JUGAR: «Elige edificio» a la vista %s · menú a la vista %s · marcado «%s» (esperado: true, false, una tarjeta)" % [
		menu.edificios != null and menu.edificios.visible, menu.centro.visible, marcado(menu)])
	await pulsar(arbol, JOY_BUTTON_B)
	print("Mando · «Elige edificio», B: vuelve al menú %s · marcado «%s» (esperado: true, un botón del menú)" % [
		menu.centro.visible and not menu.edificios.visible, marcado(menu)])
	for par: Array in [[Idioma.t("Opciones"), Opciones], [Idioma.t("Tutorial"), Tutorial]]:
		var b := buscar(menu.centro, par[0])
		b.grab_focus()
		await pulsar(arbol, JOY_BUTTON_A)
		var salio: bool = abierta.call(par[1])
		await pulsar(arbol, JOY_BUTTON_B)
		print("Mando · menú, A en «%s»: se abre %s · B: se cierra %s · menú a la vista %s (esperado: true, true, true)" % [
			par[0], salio, not abierta.call(par[1]), menu.centro.visible])
