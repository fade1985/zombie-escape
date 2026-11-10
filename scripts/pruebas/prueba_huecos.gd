# La prueba de los huecos de guardado (-- --captura --huecos; M45): con sus propios archivos (guardado-prueba-huecos*.json),
# que se empiezan de cero cada vez. Un guardado de antes de los huecos (con los ajustes dentro y sin guardado-ajustes.json)
# pasa al hueco 1 con todo; cambiar de hueco cambia el progreso y no los ajustes, y el hueco elegido se recuerda; la
# pantalla «Elige partida» con un hueco a medias, uno vacío y uno con algo, y lo mismo tras borrar el 3.
# Fotos: captura-huecos.png, captura-huecos-seguro.png y captura-huecos-borrado.png. La lanza menu_principal.gd
class_name PruebaHuecos


static func probar(menu: Control) -> void:
	var arbol := menu.get_tree()
	Guardado.usar("user://guardado-prueba-huecos")
	for n in range(1, Guardado.HUECOS + 1):
		Guardado.borrar_hueco(n)
	for a in [Guardado.ruta_ajustes(), Guardado.ruta_ajustes() + ".bak"]:
		if FileAccess.file_exists(a):
			DirAccess.remove_absolute(a)
	# Un guardado de antes: un solo archivo, con los ajustes dentro y una partida a medias
	var viejo: Dictionary = Guardado.NUEVO.duplicate(true)
	viejo.dolares = 120
	viejo.mejor_planta = 4
	viejo.partidas = 3
	viejo.ajustes.temblor = 0.5
	viejo.en_curso = var_to_str({"version": PartidaGuardada.VERSION, "edificio": "apartamentos", "planta": 3,
		"alerta": 0, "reto": {"activo": false}})
	var f := FileAccess.open(Guardado.ruta(1), FileAccess.WRITE)
	f.store_string(JSON.stringify(viejo))
	f.close()
	var s := Guardado.cargar()
	bien("el guardado viejo es el hueco 1, con sus ajustes", s.dolares == 120 and s.ajustes.temblor == 0.5 and Guardado.hueco == 1)
	# Al hueco 3: vacío, con los mismos ajustes
	Guardado.elegir_hueco(3)
	s = Guardado.cargar()
	bien("el hueco 3 empieza de cero y con los mismos ajustes", s.dolares == 0 and s.ajustes.temblor == 0.5)
	bien("el hueco elegido se recuerda", Guardado.hueco_guardado() == 3)
	Guardado.cambiar(func(g):
		g.dolares = 50
		g.partidas = 1
		g.mejor_planta = 5
		Guardado.edificio(g, "apartamentos").completado = true)
	# Un ajuste cambiado en el hueco 1 vale también en el 3
	Guardado.elegir_hueco(1)
	bien("vuelta al hueco 1 con lo suyo", Guardado.cargar().dolares == 120)
	Guardado.cambiar(func(g): g.ajustes.temblor = 1.0)
	Guardado.elegir_hueco(3)
	bien("los ajustes son de todos los huecos", Guardado.ajuste("temblor") == 1.0 and Guardado.cargar().dolares == 50)
	Guardado.elegir_hueco(1)
	# La pantalla: el 1 a medias y en uso, el 2 vacío y el 3 con algo
	var h: Huecos = menu.abrir_huecos()
	await arbol.create_timer(0.4).timeout
	Captura.foto("captura-huecos.png")
	var borrar: Button = h.tarjetas.get_child(2).get_child(1)
	borrar.pressed.emit()
	await arbol.create_timer(0.2).timeout
	Captura.foto("captura-huecos-seguro.png")
	var pregunta: Confirmar = h.find_children("*", "Confirmar", false, false).front()
	bien("borrar pregunta antes («¿Estás seguro?»)", Guardado.hueco_usado(3) and pregunta != null)
	# Empieza elegido No, y el elegido es el rojo (sea cual sea): captura-huecos-seguro-si.png, con Sí elegido
	var b_si: Button = pregunta.find_child("b_si", true, false)
	var b_no: Button = pregunta.find_child("b_no", true, false)
	bien("empieza elegido No, en rojo (y Sí normal)", b_no.has_focus() and b_no.theme_type_variation == "BotonRojo"
			and b_si.theme_type_variation == "")
	b_si.grab_focus()
	await arbol.create_timer(0.2).timeout
	Captura.foto("captura-huecos-seguro-si.png")
	bien("al elegir Sí, el rojo pasa a Sí", b_si.theme_type_variation == "BotonRojo" and b_no.theme_type_variation == "")
	pregunta.responder(false)
	await arbol.process_frame
	bien("con No no se borra", Guardado.hueco_usado(3))
	borrar.pressed.emit()
	await arbol.process_frame
	(h.find_children("*", "Confirmar", false, false).front() as Confirmar).responder(true)
	await arbol.create_timer(0.3).timeout
	Captura.foto("captura-huecos-borrado.png")
	bien("el hueco 3, borrado (y el 1, intacto)", not Guardado.hueco_usado(3) and Guardado.cargar().dolares == 120)


static func bien(que: String, si: bool) -> void:
	print("Huecos · %s: %s" % [que, "BIEN" if si else "MAL"])
