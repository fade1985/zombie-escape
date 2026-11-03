# Los controles a gusto del jugador. Los de serie están en el mapa de controles de Godot (project.godot,
# sección [input]); los que el jugador cambia en Opciones se guardan en el guardado (ajustes.teclas) y se
# ponen encima al arrancar el juego.
#
# Cada acción tiene teclas (o clics del ratón) y botones del mando. Al cambiar una, se cambian todas las de
# ese aparato por la nueva: "Esquivar: Espacio / Mayús" pasa a ser solo la tecla elegida. Si la nueva ya la
# usaba otra acción, se intercambian (la otra se queda con lo que tenía esta), para que nada se quede sin tecla.
#
# En el guardado cada tecla o botón va como un diccionario pequeño:
#   {"t": "k", "c": código de la tecla}  ·  {"t": "m", "b": botón del ratón}
#   {"t": "jb", "b": botón del mando}    ·  {"t": "ja", "e": eje del mando, "v": -1 o 1}
class_name Controles

# Las acciones que se pueden cambiar (las de probar, como 1-6, no)
const ACCIONES := ["arriba", "izquierda", "abajo", "derecha", "atacar", "esquivar", "cambiar_arma", "recargar",
	"lanzar", "cambiar_lanzable", "usar_vendas", "usar_botiquin", "inventario", "pausa", "cambiar_modo"]


# ¿Se está jugando con el mando? Lo último que ha tocado el jugador (fijarse, desde pantalla.gd): un botón o un stick del
# mando lo pone; una tecla, un clic o mover el ratón lo quita. Al arrancar, si hay un mando enchufado. Con él, el HUD
# enseña los botones del mando y los textos (tutoriales, relato...) hablan de botones en vez de teclas (M44)
static var con_mando := not Input.get_connected_joypads().is_empty()


# En la web, el navegador ordena los botones de casi todos los mandos de una forma estándar y Godot ya sabe leerla.
# Pero a algunos (sobre todo con un mando USB en el móvil) el navegador no los reconoce y los pasa tal cual: Godot no
# sabe qué es cada botón y toma su número a pelo. El 6 de esos mandos es el L2, y para Godot el 6 es Start: el L2 abría
# la pausa además de lanzar (M73). A esos mandos se les da el orden estándar del navegador, que es el que traen
# (A B X Y, LB RB, LT RT, Select Start, los sticks, la cruceta y el botón central); los ejes 4 y 5, si los tienen,
# siguen siendo los gatillos, como hasta ahora
const ORDEN_WEB := "a:b0,b:b1,x:b2,y:b3,leftshoulder:b4,rightshoulder:b5,lefttrigger:b6,righttrigger:b7," \
	+ "back:b8,start:b9,leftstick:b10,rightstick:b11,dpup:b12,dpdown:b13,dpleft:b14,dpright:b15,guide:b16," \
	+ "leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:a4,righttrigger:a5"   # no-tr (mapa de Godot)


# En la web, al arrancar y cada vez que se enchufa un mando (pantalla.gd). Los que el navegador reconoce («standard»)
# Godot ya los conoce y no se tocan. (Uno ordenado aquí Godot lo sigue dando por desconocido: si se desenchufa y se
# vuelve a enchufar, se le pone el mismo orden otra vez, y no pasa nada)
static func ordenar_mando(mando: int) -> void:
	if Input.is_joy_known(mando):
		return
	var nombre := Input.get_joy_name(mando).replace(",", " ")
	Input.add_joy_mapping("%s,%s,%s" % [Input.get_joy_guid(mando), nombre, ORDEN_WEB], true)


# Mira cada cosa que pulsa el jugador para saber si juega con el mando o con el teclado y el ratón (con_mando)
static func fijarse(ev: InputEvent) -> void:
	if (ev is InputEventJoypadButton and ev.pressed) or (ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.5):
		con_mando = true
	elif (ev is InputEventKey and ev.pressed) or (ev is InputEventMouseButton and ev.pressed) \
			or (ev is InputEventMouseMotion and ev.relative.length() > 4.0):
		con_mando = false


# El botón del mando de una acción (el primero que tenga), para dibujarlo en el HUD; null si no tiene
static func boton_de(accion: String) -> InputEvent:
	var lista := eventos(accion, true)
	return lista[0] if not lista.is_empty() else null


# La tecla del teclado de una acción, para enseñarla (en el HUD y en las fichas): "-" si no tiene
static func tecla_de(accion: String) -> String:
	for ev in eventos(accion, false):
		if ev is InputEventKey:
			return Opciones.nombre_evento(ev)
	return "-"


# La letra que hay en esa posición del teclado del jugador, en la web: ahí Godot no lo sabe y se le pide al
# navegador (en aplicar). Chrome y Edge lo dicen; Firefox y Safari no, y sale la letra de un teclado normal
static func letra_web(c: Key) -> String:
	var letra := OS.get_keycode_string(c)
	if c < KEY_A or c > KEY_Z:
		return letra
	var suya := str(JavaScriptBridge.eval("window.teclado_jugador?.get('Key%s') ?? ''" % letra, true))   # no-tr (JavaScript)
	return suya.to_upper() if suya != "" else letra


# Al arrancar (menú principal y partida): pone los controles guardados encima de los de serie
static func aplicar() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("navigator.keyboard?.getLayoutMap().then(m => window.teclado_jugador = m).catch(() => {})", true)   # no-tr (JavaScript)
	var teclas: Dictionary = Guardado.cargar().ajustes.teclas
	for accion in teclas:
		if not InputMap.has_action(accion):
			continue
		InputMap.action_erase_events(accion)
		for d in teclas[accion]:
			var ev := de_texto(d)
			if ev:
				InputMap.action_add_event(accion, ev)


# Pone "evento" a una acción en lugar de lo que tenía en ese aparato (teclado y ratón, o mando)
static func cambiar(accion: String, evento: InputEvent) -> void:
	var mando := es_mando(evento)
	var viejos := eventos(accion, mando)
	# ¿Quién más la usaba? Se queda con lo que tenía esta acción
	for otra in ACCIONES:
		if otra == accion:
			continue
		for ev in eventos(otra, mando):
			if iguales(ev, evento):
				InputMap.action_erase_event(otra, ev)
				for v in viejos:
					InputMap.action_add_event(otra, v)
				guardar(otra)
	for v in viejos:
		InputMap.action_erase_event(accion, v)
	InputMap.action_add_event(accion, evento)
	guardar(accion)


# Vuelve a los de serie
static func restablecer() -> void:
	InputMap.load_from_project_settings()
	Guardado.cambiar(func(g): g.ajustes.teclas = {})


static func guardar(accion: String) -> void:
	var lista := []
	for ev in InputMap.action_get_events(accion):
		var d := a_texto(ev)
		if not d.is_empty():
			lista.append(d)
	Guardado.cambiar(func(g): g.ajustes.teclas[accion] = lista)


# Las teclas (mando = false) o los botones del mando (mando = true) de una acción
static func eventos(accion: String, mando: bool) -> Array:
	return InputMap.action_get_events(accion).filter(func(e): return es_mando(e) == mando)


static func es_mando(ev: InputEvent) -> bool:
	return ev is InputEventJoypadButton or ev is InputEventJoypadMotion


static func iguales(a: InputEvent, b: InputEvent) -> bool:
	return a_texto(a) == a_texto(b)


static func codigo(ev: InputEventKey) -> Key:
	return ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode


static func a_texto(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		return {"t": "k", "c": int(codigo(ev))}
	if ev is InputEventMouseButton:
		return {"t": "m", "b": int(ev.button_index)}
	if ev is InputEventJoypadButton:
		return {"t": "jb", "b": int(ev.button_index)}
	if ev is InputEventJoypadMotion:
		return {"t": "ja", "e": int(ev.axis), "v": 1 if ev.axis_value > 0 else -1}
	return {}


static func de_texto(d: Dictionary) -> InputEvent:
	match d.get("t", ""):
		"k":
			var k := InputEventKey.new()
			k.physical_keycode = int(d.c)
			k.device = -1   # cualquier teclado
			return k
		"m":
			var m := InputEventMouseButton.new()
			m.button_index = int(d.b)
			m.device = -1
			return m
		"jb":
			var b := InputEventJoypadButton.new()
			b.button_index = int(d.b)
			b.device = -1   # cualquier mando
			return b
		"ja":
			var a := InputEventJoypadMotion.new()
			a.axis = int(d.e)
			a.axis_value = float(d.v)
			a.device = -1
			return a
	return null


# Una tecla, clic o botón del mando recién pulsado, limpio (sin Mayús pegada, sin cuánto se empuja el stick),
# listo para ponerlo en una acción. null si no vale (soltar, repetir, mover el ratón...)
static func capturar(ev: InputEvent, mando: bool) -> InputEvent:
	if mando:
		if ev is InputEventJoypadButton and ev.pressed:
			return de_texto(a_texto(ev))
		if ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.6:
			return de_texto(a_texto(ev))
		return null
	if ev is InputEventKey and ev.pressed and not ev.echo:
		return de_texto(a_texto(ev))
	if ev is InputEventMouseButton and ev.pressed:
		return de_texto(a_texto(ev))
	return null
