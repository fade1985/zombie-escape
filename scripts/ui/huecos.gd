# La pantalla «Elige partida» del menú principal (M45): los tres huecos de guardado (guardado.gd), cada uno en su
# tarjeta con su resumen (mejor planta, dólares, edificios completados, partidas jugadas y la partida a medias) o
# «Vacía». Al pulsar una tarjeta se pasa a ese hueco y el menú se monta otra vez con lo suyo. Debajo de cada tarjeta con
# algo, «Borrar»: la primera pulsación pregunta y la segunda lo borra para siempre. Esc (o B en el mando) vuelve al menú.
class_name Huecos
extends CenterContainer

signal cerrado

const ANCHO := 260   # el ancho de una tarjeta

var tarjetas: HBoxContainer
var cambiado := false   # se ha borrado algo: el menú de detrás ya no vale


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 18)
	add_child(columna)
	var titulo := Label.new()
	titulo.theme_type_variation = "Titulo"
	titulo.text = Idioma.t("Elige partida")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	tarjetas = HBoxContainer.new()
	tarjetas.alignment = BoxContainer.ALIGNMENT_CENTER
	tarjetas.add_theme_constant_override("separation", 20)
	columna.add_child(tarjetas)
	poner_tarjetas()
	var volver := Button.new()
	volver.text = Idioma.t("Volver")
	volver.custom_minimum_size.x = 180
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.pressed.connect(cerrar)
	columna.add_child(volver)
	tarjeta_de(Guardado.hueco).grab_focus.call_deferred()


func poner_tarjetas() -> void:
	for caja in tarjetas.get_children():   # (fuera ya, y borradas luego: puede venir de pulsar su «Borrar»)
		tarjetas.remove_child(caja)
		caja.queue_free()
	for n in range(1, Guardado.HUECOS + 1):
		var caja := VBoxContainer.new()
		caja.add_theme_constant_override("separation", 6)
		caja.add_child(tarjeta(n))
		if Guardado.hueco_usado(n):
			var borrar := Button.new()
			borrar.text = Idioma.t("Borrar partida")
			borrar.custom_minimum_size.x = 200
			borrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			borrar.pressed.connect(func():
				if borrar.text == Idioma.t("Borrar partida"):
					borrar.text = Idioma.t("¿Seguro? Pulsa otra vez")
				else:
					Guardado.borrar_hueco(n)
					cambiado = true
					Sonido.tocar("click")
					poner_tarjetas()
					tarjeta_de(n).grab_focus())
			caja.add_child(borrar)
		tarjetas.add_child(caja)


func tarjeta_de(n: int) -> Button:
	return tarjetas.get_child(n - 1).get_child(0)


# La tarjeta de un hueco: su número, si está en uso y su resumen (o «Vacía»)
func tarjeta(n: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(ANCHO, 260)   # (en ruso y chino las líneas son más altas)
	b.pressed.connect(elegir.bind(n))
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.offset_left = 12
	caja.offset_right = -12
	caja.offset_top = 14
	caja.offset_bottom = -14
	caja.add_theme_constant_override("separation", 6)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(caja)
	var lineas := [[Idioma.t("Partida %d") % n, ""]]
	lineas.append([Idioma.t("En uso") if n == Guardado.hueco else " ", "Sub"])
	if Guardado.hueco_usado(n):
		var s := Guardado.cargar_archivo(Guardado.ruta(n))
		var completados := Edificios.LISTA.keys().filter(func(id): return s.edificios.get(id, {}).get("completado", false)).size()
		lineas.append([Idioma.t("Mejor planta: %d") % s.mejor_planta, "Sub"])
		lineas.append([Idioma.t("Dólares ahorrados: $%d") % s.dolares, "Sub"])
		lineas.append([Idioma.t("Edificios completados: %d de %d") % [completados, Edificios.LISTA.size()], "Sub"])
		lineas.append([Idioma.n("%d partida jugada", "%d partidas jugadas", s.partidas) % s.partidas, "Sub"])
		var foto := PartidaGuardada.guardada(s)
		if not foto.is_empty():
			var azotea: bool = Edificios.datos(foto.edificio).get("azotea", false) and foto.planta == Planta.PLANTAS
			lineas.append([Idioma.t("A medias: %s") % ("%s · %s" % [Idioma.t(Edificios.datos(foto.edificio).nombre),
				Planta.nombre_de({"num": foto.planta, "azotea": azotea, "edificio": foto.edificio})]), ""])
	else:
		lineas.append([Idioma.t("Vacía"), ""])
		lineas.append([Idioma.t("Empieza de cero"), "Sub"])
	for i in lineas.size():
		var l := Label.new()
		l.text = lineas[i][0]
		l.theme_type_variation = lineas[i][1]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = ANCHO - 24
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i == 1:   # «En uso», en el amarillo de los avisos
			l.modulate = Color(1.0, 0.85, 0.35)
		caja.add_child(l)
	return b


# Pasa a ese hueco y el menú se monta otra vez, con su «Continuar partida» y su récord
func elegir(n: int) -> void:
	Sonido.tocar("click")
	Guardado.elegir_hueco(n)
	get_tree().reload_current_scene()


func cerrar() -> void:
	if cambiado:
		get_tree().reload_current_scene()
		return
	cerrado.emit()
	queue_free()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()
