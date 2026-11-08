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
	for par: Array in [[Idioma.t("Opciones"), Opciones]]:   # (el Tutorial, desde el 8 nov, va dentro de Opciones)
		var b := buscar(menu.centro, par[0])
		b.grab_focus()
		await pulsar(arbol, JOY_BUTTON_A)
		var salio: bool = abierta.call(par[1])
		await pulsar(arbol, JOY_BUTTON_B)
		print("Mando · menú, A en «%s»: se abre %s · B: se cierra %s · menú a la vista %s (esperado: true, true, true)" % [
			par[0], salio, not abierta.call(par[1]), menu.centro.visible])


# Un mando que el navegador no reconoce, en la web (-- --captura --mandoweb, M73): se enchufa uno falso desde el
# navegador (sin «mapping» estándar, como algunos mandos USB en el móvil) y se pulsa su L2, que en bruto es el botón 6
# y el eje 4. Primero como llega (con el orden de Controles.ordenar_mando puesto al enchufarlo: solo lanza); luego sin
# ese orden, para ver el fallo (abría la pausa), y otra vez con él; su Start (el 9) sí abre la pausa. Al final, uno que el
# navegador sí reconoce («standard»), para ver que a ese no se le toca. Fuera de la web no se puede: lo dice y ya
static func mando_web(partida: Node) -> void:
	var arbol := partida.get_tree()
	if not OS.has_feature("web"):
		print("Mando web: esta prueba solo vale en la web (py tools/medir_web.py 40 --captura --mandoweb)")
		arbol.quit()
		return
	JavaScriptBridge.eval("""
		window.mandos_falsos = [];
		Object.defineProperty(navigator, 'getGamepads', {value: () => window.mandos_falsos, configurable: true});
		window.enchufar_falso = (id, mapping) => {
			const m = {id: id, index: window.mandos_falsos.length, connected: true, mapping: mapping, timestamp: 0,
				buttons: Array.from({length: 17}, () => ({pressed: false, touched: false, value: 0})), axes: [0, 0, 0, 0, 0, 0]};
			window.mandos_falsos.push(m);
			const e = new Event('gamepadconnected'); e.gamepad = m; window.dispatchEvent(e);
		};
		window.boton_falso = (i, b, eje, v) => {
			const m = window.mandos_falsos[i];
			m.buttons[b] = {pressed: v > 0, touched: v > 0, value: v};
			if (eje >= 0) m.axes[eje] = v;
			m.timestamp += 1;
		};
		window.enchufar_falso('Mando falso (Vendor: 1234 Product: 5678)', '');""", true)   # no-tr (JavaScript)
	await arbol.create_timer(0.5).timeout
	var menus = partida.menus
	# Pulsa y suelta el L2 del mando i (en bruto: el botón 6 y, en el desconocido, también el eje 4) y dice qué ha pasado
	var l2 := func(i: int, eje: int, que: String) -> void:
		JavaScriptBridge.eval("window.boton_falso(%d, 6, %d, 1)" % [i, eje], true)   # no-tr (JavaScript)
		await arbol.create_timer(0.3).timeout
		print("Mando web · L2 %s: pausa «%s» · lanzar %s" % [que, menus.abierto, Input.is_action_pressed("lanzar")])
		JavaScriptBridge.eval("window.boton_falso(%d, 6, %d, 0)" % [i, eje], true)   # no-tr (JavaScript)
		await arbol.create_timer(0.3).timeout
		if menus.abierto != "":
			Input.parse_input_event(boton(JOY_BUTTON_B))
			await arbol.create_timer(0.4).timeout
	print("Mando web: enchufado %s · «%s» (esperado: true, Android12345678 o Windows12345678)" % [
		Input.get_connected_joypads().size() == 1, Input.get_joy_guid(0)])
	await l2.call(0, 4, "al enchufarlo (esperado: «», true)")
	Input.remove_joy_mapping(Input.get_joy_guid(0))   # como antes del arreglo
	await l2.call(0, 4, "sin el arreglo (el fallo: «pausa», true)")
	Controles.ordenar_mando(0)
	await l2.call(0, 4, "con el arreglo otra vez (esperado: «», true)")
	JavaScriptBridge.eval("window.boton_falso(0, 9, -1, 1)", true)   # no-tr (JavaScript)
	await arbol.create_timer(0.3).timeout
	print("Mando web · Start: pausa «%s» (esperado: «pausa»)" % menus.abierto)
	JavaScriptBridge.eval("window.boton_falso(0, 9, -1, 0)", true)   # no-tr (JavaScript)
	Input.parse_input_event(boton(JOY_BUTTON_B))
	await arbol.create_timer(0.4).timeout
	JavaScriptBridge.eval("window.enchufar_falso('Mando estándar (Vendor: 045e Product: 028e)', 'standard')", true)   # no-tr (JavaScript)
	await arbol.create_timer(0.5).timeout
	print("Mando web · el estándar: «%s» · reconocido %s (esperado: «standard», true)" % [Input.get_joy_guid(1), Input.is_joy_known(1)])
	await l2.call(1, -1, "del estándar (esperado: «», true)")
	print("Mando web: hecho")
