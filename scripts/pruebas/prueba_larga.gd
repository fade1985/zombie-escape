# La prueba larga (--captura a secas, en _process) y lo que mira por el camino: el ordenador, la historia, las
# Colecciones, los objetos, los menús... También --banco. Parte de la cadena de la partida de
# prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_varias.gd"

var tiempo := 0.0            # los segundos que lleva la prueba larga (_process)


func contar_planta() -> void:
	print("Planta: ", planta.nombre)
	for i in range(1, planta.sitios.size()):
		var s: Dictionary = planta.sitios[i]
		if not s.has("apt"):
			print("  %s [%s]: %d muebles" % [s.nombre, s.tipo, s.muebles.size()])
			continue
		var salas := []
		for sala in s.apt.salas:
			salas.append("%s(%d)" % [sala.nombre, sala.casillas])
		var tipos := {}
		for z in s.zombis:
			tipos[z.tipo] = tipos.get(z.tipo, 0) + 1
		print("  %s [%s] %dx%d casillas: %s | %d muebles | zombis: %s" % [s.nombre, s.tipo, s.apt.cols, s.apt.filas,
			" ".join(salas), s.muebles.size(), tipos])
	print("  pasillo: %d muebles | llave en %s" % [planta.sitios[0].muebles.size(),
		planta.sitios[planta.llave.sitio].nombre if planta.llave.sitio >= 0
		else "el guardia del pasillo" if ed.cerrojo == "tarjeta" else "un zombi al azar"])


func _process(delta: float) -> void:
	tiempo += delta
	var antes := tiempo - delta
	# primero, fotos de la sala de mantenimiento (donde empieza) y de la exposición
	if antes < 0.3 and tiempo >= 0.3:
		Captura.foto("captura-mantenimiento.png")
		montar(planta.expo, 0, false)
		johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, 420)
		johnny.get_node("Camara").reset_smoothing()
	if antes < 0.7 and tiempo >= 0.7:
		Captura.foto("captura-expo.png")
		# y las últimas filas de zombis (los del centro comercial, la portera y los minijefes): captura-expo-zombis.png
		var filas := []
		for s in mapa.expo_sprites:
			if s.position.y not in filas:
				filas.append(s.position.y)
		filas.sort()
		johnny.position = Vector2(560, filas[-1] - 140.0)
		johnny.get_node("Camara").reset_smoothing()
	if antes < 0.9 and tiempo >= 0.9:
		Captura.foto("captura-expo-zombis.png")
	# al segundo, a un apartamento normal (el que tiene más zombis)
	if antes < 1.0 and tiempo >= 1.0:
		var mejor := 1
		for i in range(1, planta.sitios.size()):
			if planta.sitios[i].zombis.size() > planta.sitios[mejor].zombis.size():
				mejor = i
		print("Entra en ", planta.sitios[mejor].nombre)
		montar(mejor, 0, false)
	# el botiquín del baño: herido, delante del armarito
	if antes < 1.1 and tiempo >= 1.1 and not mapa.armaritos.is_empty():
		var a: Node2D = mapa.armaritos[0]
		johnny.vida = 40
		johnny.position = a.position + Vector2(0, 40)
		johnny.get_node("Camara").reset_smoothing()
		a.get_node("Zona").abrir()   # M11: se abre con el clic (zona_usar.gd)
		$Pantalla/HUD.hide()   # para que se vea la pared de arriba en la foto
	if antes < 1.4 and tiempo >= 1.4:
		var a: Node2D = mapa.armaritos[0] if not mapa.armaritos.is_empty() else null
		print("Armaritos en el piso: %d | vida tras el botiquín: %d | cogido: %s" % [mapa.armaritos.size(), johnny.vida,
			a.datos.cogido if a else "-"])
		Captura.foto("captura-botiquin.png")
		$Pantalla/HUD.show()
	# poca vida: la pantalla roja y la barra con lo perdido en claro (luego se le devuelve la vida)
	if antes < 1.45 and tiempo >= 1.45:
		johnny.quitar_vida(johnny.vida - 18)
	if antes < 1.6 and tiempo >= 1.6:
		Captura.foto("captura-poca-vida.png")
		johnny.vida = johnny.stats.vida_max
		johnny.tercios = 3
	# una granada a un lado (explota antes de la foto)
	if antes < 2.0 and tiempo >= 2.0:
		lanzables.cambiar()
		lanzables.lanzar(johnny.global_position + Vector2(-180, 90))
		lanzables.cambiar()
	# un tiro de pistola para despertar a los de cerca
	if antes < 2.5 and tiempo >= 2.5:
		johnny.coger("pistola")
	if antes < 2.6 and tiempo >= 2.6:
		Input.action_press("atacar")
	# las trazadoras (normal, perdigón y crítica), quietas al lado de Johnny para la foto
	if antes < 2.65 and tiempo >= 2.65:
		for i in 3:
			var bala := preload("res://escenas/armas/bala.tscn").instantiate()
			bala.velocidad = Vector2.from_angle(-0.4 + i * 0.4) * 600.0
			bala.radio = 3.0 if i == 1 else 4.0
			bala.critico = i == 2
			bala.altura = 22.0
			bala.set_physics_process(false)
			bala.name = "BalaFoto%d" % i
			johnny.get_parent().add_child(bala)
			bala.global_position = johnny.global_position + Vector2(-70 + i * 50, 30)
	if antes < 2.7 and tiempo >= 2.7:
		Captura.foto("captura-balas.png")
		for n in johnny.get_parent().get_children():
			if n.name.begins_with("BalaFoto"):
				n.queue_free()
	if antes < 3.2 and tiempo >= 3.2:
		Input.action_release("atacar")
		# un molotov al zombi más cercano (o por delante)
		var prueba := meter_zombi("lento", mapa.punto_libre(johnny.position, 120.0))
		var donde: Vector2 = prueba.global_position
		lanzables.lanzar(donde)
		print("Molotov hacia ", donde, " | quedan ", lanzables.cantidades)
		# un zombi que cae al lado de Johnny: revienta y deja su mancha
		var muerto := meter_zombi("normal", johnny.position + Vector2(-60, 40))
		muerto.recibir_golpe(999, Vector2.ZERO)
		# y dos que mueren ardiendo: uno se queda en brasas y al otro se le adelanta el reloj hasta los huesos
		for i in 2:
			var quemado := meter_zombi("normal", johnny.position + Vector2(-90 + i * 130, 10))
			quemado.name = "QuemadoFoto%d" % i
			quemado.prender()
			quemado.recibir_golpe(999, Vector2.ZERO)
	if antes < 4.3 and tiempo >= 4.3:
		for i in 2:
			var cuerpo: Node = mapa.cosas.get_node_or_null("QuemadoFoto%d" % i)
			if cuerpo:
				var q: Quemado = cuerpo.get_children().filter(func(n): return n is Quemado)[0]
				q.t = q.caida + 3.0 if i == 0 else 99.0   # uno en brasas y humo; el otro, ya en huesos
	if antes < 4.4 and tiempo >= 4.4:
		Captura.foto("captura-quemado.png")
	if antes < 3.35 and tiempo >= 3.35:
		Captura.foto("captura-sangre.png")
		# las balas: sin ninguna, a la de cuerpo a cuerpo; una caja de munición devuelve la de fuego y recarga
		var antes_balas := "%s %d +%d" % [johnny.huecos.fuego, johnny.balas, johnny.reserva()]
		johnny.balas = 0
		johnny.municion.clear()
		johnny.sostener("fuego")
		johnny.lista_para_disparar()
		var sin: String = johnny.mano
		johnny.sumar_municion()
		print("Balas: %s | sin balas pasa a %s | con una caja: %s %d +%d recargando %s" % [antes_balas, sin,
			johnny.mano, johnny.balas, johnny.reserva(), johnny.recargando > 0.0])
	if antes < 4.2 and tiempo >= 4.2:
		var ardiendo := 0
		for z in get_tree().get_nodes_in_group("zombis"):
			if z.get("arder_t") != null and z.arder_t > 0.0:
				ardiendo += 1
		print("Charcos: %d | zombis ardiendo: %d | manchas: %d" % [get_tree().get_nodes_in_group("charcos").size(), ardiendo,
			get_tree().get_nodes_in_group("manchas").size()])
	if int(tiempo * 2.0) != int(antes * 2.0) and tiempo > 1.2:
		var dormidos := 0
		var despiertos := 0
		for z in get_tree().get_nodes_in_group("zombis"):
			if z.get("dormido"):
				dormidos += 1
			else:
				despiertos += 1
		print("t=%.1f vida=%d puerta %s | dormidos %d, despiertos %d | %s" % [tiempo, johnny.vida,
			"cerrada" if cerrada else "abierta", dormidos, despiertos, lugar.text.replace("\n", " / ")])
	if antes < 4.5 and tiempo >= 4.5:
		Captura.foto("captura.png")
		print("Foto guardada. Prueba de las escaleras:")
		planta.jefa_muerta = true
		cerrada = false
		montar(0, puerta_de_tipo("escaleras"), false)
	if antes < 4.7 and tiempo >= 4.7:
		cruzar(puerta_de_tipo("escaleras"))
	# en el centro comercial, el guardia: Johnny se le acerca (silbato y refuerzos), foto, y cae con su tarjeta
	if antes < 5.35 and tiempo >= 5.35 and guardia:
		johnny.position = mapa.punto_libre(guardia.position, 0.0)
		for i in 60:
			var p: Vector2 = guardia.position + Vector2.from_angle(randf() * TAU) * 220.0
			if mapa.zona_en(p) >= 0:
				johnny.position = p
				break
		johnny.get_node("Camara").reset_smoothing()
	if antes < 5.5 and tiempo >= 5.5 and guardia:
		print("Guardia: vida %d/%d | alerta %s | silbidos %d | zombis en el pasillo %d" % [guardia.vida, guardia.vida_max,
			guardia.alerta, guardia.silbidos, get_tree().get_nodes_in_group("zombis").size()])
		Captura.foto("captura-guardia.png")
		guardia.recibir_golpe(99999, Vector2.ZERO)
	if antes < 5.6 and tiempo >= 5.6:
		if planta.has("guardia"):
			print("Tarjeta: en el sitio %d, en %s | guardia vivo: %s" % [planta.llave.sitio, planta.llave.pos, planta.guardia.vivo])
		print("Ahora en: ", planta.nombre, " (", planta.sitios.size() - 1, " puertas)")
		Captura.foto("captura-pasillo.png")
		# Johnny pisa la puerta A del pasillo, como si fuera andando
		johnny.position = mapa.puertas[0].position + Vector2(0, 20)
	if antes < 6.6 and tiempo >= 6.6:
		print("Tras pisar la puerta A: en %s (aviso: '%s')" % [planta.sitios[aqui].nombre, aviso.text])
		# Prueba de la jefa: con la llave, a su apartamento
		planta.tiene_llave = true
		for i in planta.sitios.size():
			if planta.sitios[i].tipo == "jefe":
				montar(i, 0, false)
	if antes < 7.3 and tiempo >= 7.3 and jefa and planta.jefe == "gloton":   # (aparece a los 7,2)
		probar_gloton()   # la sangre ácida y el aspirado (lo escribe en la terminal)
	if antes < 7.3 and tiempo >= 7.3 and jefa and planta.jefe == "gymbro":
		probar_gymbro()   # los suplementos (la armadura) y las pesas (lo escribe en la terminal)
	if antes < 7.3 and tiempo >= 7.3 and jefa and planta.jefe == "bombero":
		probar_bombero()   # inmune al fuego, las bolas y los molotovs (lo escribe en la terminal)
	if antes < 7.7 and tiempo >= 7.7 and jefa:
		if jefa.has_method("cambiarse"):
			probar_modista(jefa)   # antes de poner a Johnny delante: se cambia de sitio
		# Johnny, delante del jefe (para que salga en la foto)
		for i in 60:
			var p: Vector2 = jefa.position + Vector2.from_angle(jefa.mirada.angle() + randf_range(-0.7, 0.7)) * 230.0
			if mapa.zona_en(p) >= 0:
				johnny.position = p
				break
		johnny.get_node("Camara").reset_smoothing()
		if jefa is Minijefe:
			jefa.mirada = (johnny.position - jefa.position).normalized()
		if jefa.has_method("lluvia"):
			probar_cocinero()
		if planta.jefe == "antidisturbios":
			# el antidisturbios. El escudo: un golpe de 10 por delante, de lado, por la espalda y de una explosión
			# (la fuerza va hacia donde empuja el golpe: el de delante empuja hacia atrás)
			var m: Vector2 = jefa.mirada
			var quita := []
			for golpe in [[-m, false], [m.orthogonal(), false], [m, false], [m, true]]:
				var antes_vida: int = jefa.vida
				jefa.recibir_golpe(10, golpe[0] * 300.0, golpe[1])
				quita.append(antes_vida - jefa.vida)
			print("Escudo (golpes de 10): de frente -%d, de lado -%d, por la espalda -%d, explosión -%d" % quita)
		if jefa.has_method("foto"):   # que salga en la foto haciendo lo suyo (el antidisturbios, preparando la carga; la mascota, saltando)
			jefa.foto(johnny)
		if jefa.has_method("cambiarse"):   # la modista: que salga en la foto tirando alfileres
			jefa.apuntar_alfileres(johnny.position - jefa.position)
			jefa.datos.aviso = 0.15
	if antes < 8.0 and tiempo >= 8.0 and jefa:
		Captura.foto("captura-jefe.png")
	if antes < 8.05 and tiempo >= 8.05:
		print("El jefe (%s) ha salido en '%s': %s | vida %d | puerta %s" % [planta.jefe, planta.sitios[aqui].nombre,
			jefa != null, jefa.vida_max if jefa else 0, "cerrada" if cerrada else "abierta"])
		if jefa:
			jefa.invulnerable = false   # (la mascota de la foto está en el aire, donde no se le puede dar)
			jefa.recibir_golpe(99999, Vector2.ZERO)
	if antes < 9.5 and tiempo >= 9.5:
		print("Jefa muerta: ", planta.jefa_muerta, " | ", aviso.text)
		probar_menus()


# El ordenador: con $60 en el guardado de prueba sube Ataque y Puntería ($5 cada punto), compra la escopeta y hace fotos
func probar_ordenador() -> void:
	Guardado.cambiar(func(g):
		g.dolares = 60
		g.dolares_talentos = 0
		g.talentos = {}
		g.armas = [])
	ahorrados = 60
	aplicar_talentos({})
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.abrir("puntos")
	ordenador.subir("ataque")
	ordenador.subir("punteria")
	ordenador.subir("tirador")   # bloqueado: no tiene Ataque al máximo
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ordenador.png")
	ordenador.abrir("armas")
	ordenador.comprar_arma("escopeta")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-tienda.png")
	# los logros: uno cobrado, uno por cobrar y algo de progreso en los demás
	Guardado.cambiar(func(g): g.logros = {"primer_turno": "cobrado", "desahucio": "conseguido"})
	logros.fregonazos = 4
	ordenador.abrir("logros", "b_desahucio")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-logros.png")
	ordenador.cobrar_logro("desahucio")
	print("Logros: %s | $%d ahorrados tras cobrar" % [Guardado.cargar().logros, Guardado.cargar().dolares])
	var g := Guardado.cargar()
	print("Ordenador: $%d ahorrados, $%d gastados en talentos, talentos %s, armas %s | daño x%.2f | lleva %s" % [g.dolares, g.dolares_talentos,
		g.talentos, g.armas, johnny.stats.dano, johnny.huecos])
	ordenador.abrir("")
	ordenador.apagar()


# La historia: el científico muerto de la planta (con su página sin encontrar), la página al cogerla y el Dosier
# del ordenador con dos páginas
# La sangre, en la sala de mantenimiento (con luz, para que se vea): el destello de un golpe, un zombi muerto a
# golpes que deja su charco, el lento arrastrándose con su rastro y los casquillos de unos disparos
func probar_sangre() -> void:
	# si sigue abierta la mutación de la portera, se elige una que no deja charcos (para que no salgan en la foto)
	if menus.abierto == "mutacion":
		menus.elegir("insensible")
	await montar(planta.mantenimiento, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var centro := Vector2(planta.sitios[aqui].ancho / 2.0, 330)
	johnny.position = centro
	johnny.get_node("Camara").reset_smoothing()
	johnny.invulnerable = 99.0
	johnny.coger("pistola")   # con la pistola (si lleva el desintegrador, el ácido tapa la sangre)
	# los acompañantes, quietos (si no, matan al lento antes de que se arrastre)
	for a in get_tree().get_nodes_in_group("presa"):
		if a != johnny:
			a.process_mode = Node.PROCESS_MODE_DISABLED
	var golpeado := meter_zombi("normal", centro + Vector2(110, -10))
	var lento := meter_zombi("lento", centro + Vector2(-300, 60))
	lento.despertar()
	var muerto := meter_zombi("normal", centro + Vector2(-60, 150))
	await get_tree().create_timer(0.3).timeout
	muerto.recibir_golpe(999, Vector2(-120, 60))
	golpeado.recibir_golpe(1, Vector2(150, 0))
	await get_tree().process_frame
	await get_tree().process_frame
	Captura.foto("captura-destello.png")
	await get_tree().create_timer(0.3).timeout
	golpeado.recibir_golpe(999, Vector2(170, 0))
	johnny.coger("pistola")
	johnny.balas = 8
	for i in 5:
		johnny.disparar(-0.3 + i * 0.15)
		await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(2.5).timeout
	var rastro: Node = lento.get_parent().get_node_or_null("Rastro")
	print("Sangre: rastro %d | gotas %d | casquillos %d | charco %s" % [rastro.celdas.size() if rastro else 0,
		lento.get_parent().get_node("Gotas").celdas.size() if lento.get_parent().has_node("Gotas") else 0,
		lento.get_parent().get_node("Casquillos").celdas.size() if lento.get_parent().has_node("Casquillos") else 0,
		golpeado.a_golpes])
	Captura.foto("captura-sangre2.png")
	johnny.invulnerable = 0.0
	for a in get_tree().get_nodes_in_group("presa"):
		a.process_mode = Node.PROCESS_MODE_INHERIT


func probar_historia() -> void:
	Guardado.cambiar(func(g): g.paginas = [])
	var c: Dictionary = planta.cientifico
	await montar(c.sitio, 0, false)
	johnny.position = c.pos + Vector2(-70, 0)
	johnny.get_node("Camara").reset_smoothing()
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().create_timer(1.2).timeout
	Captura.foto("captura-cientifico.png")
	print("Científico en pantalla: ", get_viewport().get_canvas_transform() * c.pos)
	johnny.position = c.pos + Vector2(28, 30)
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-pagina.png")
	print("Página cogida: %s | en el guardado: %s" % [c.get("pagina", {}).get("id", "-"), Guardado.cargar().paginas])
	menus.leida()
	# en el ordenador, la primera y la tercera página del dosier de este edificio (en los Apartamentos, el correo)
	# y la primera de cada uno de los otros edificios: el Dosier las enseña todas, sea cual sea el edificio
	var ids: Array = Historia.dosier(edificio).paginas.map(func(p): return p.id)
	var de_otros: Array = Historia.DOSIERES.keys().filter(func(e): return e != edificio).map(
		func(e): return Historia.DOSIERES[e].paginas[0].id)
	Guardado.cambiar(func(g): g.paginas = [ids[0], ids[2]] + de_otros)
	abrir_ordenador()
	await get_tree().create_timer(0.3).timeout
	ordenador.abrir("dosier", "b_" + ids[2])
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-dosier.png")
	# la del jefe, si este edificio la tiene (el centro comercial): sin encontrar en el ordenador y luego soltada
	var del_jefe := Historia.del_jefe(Guardado.cargar(), edificio)
	if not del_jefe.is_empty():
		ordenador.abrir("dosier", "b_" + del_jefe.id)
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-dosier-falta.png")
	ordenador.abrir("")
	ordenador.apagar()
	if not del_jefe.is_empty():
		pagina_del_jefe()
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-pagina-jefe.png")
		print("Página del jefe: %s | en el guardado: %s" % [del_jefe.id, Guardado.cargar().paginas])
		menus.leida()
	await montar(planta.mantenimiento, 0, false)
	await probar_noticias()


# Colecciones (bestiario.gd y el programa del ordenador; también solo, con --coleccion): deja en el guardado
# parte de los enemigos vistos y unos cuantos matados, y hace las fotos: el escritorio con el aviso de "¡NUEVO!"
# (captura-escritorio-nuevo.png), la pestaña de los durmientes con el vecino (captura-colecciones.png), la de los
# sonámbulos con el gerente en silueta (captura-bestiario-falta.png), los durmientes con el oficinista
# (captura-bestiario-torre.png), los sonámbulos con la criatura, el más grande (captura-bestiario-grande.png), y su
# segunda página con el Sujeto 1 (captura-bestiario-pagina.png). Luego cuenta en la terminal lo visto de cada familia,
# comprueba los totales, las flechas de las páginas y que matar uno lo apunta
func probar_colecciones() -> void:
	# lo que la prueba ha ido apuntando sola (meter_zombi avisa al bestiario con cada enemigo que nace)
	print("Bestiario apuntado por la prueba hasta aquí: %s" % [Guardado.cargar().get("bestiario", [])])
	var vistos: Array = ["normal", "lento", "rapido", "explosivo", "venenoso", "portera", "criatura", "dependienta",
		"guardia", "antidisturbios", "maniqui", "gerente_mutado", "oficinista", "escolta"]
	Guardado.cambiar(func(g):
		g.bestiario = vistos
		g.matados = {"normal": 128, "lento": 41, "rapido": 37, "portera": 3, "dependienta": 12}
		g.colecciones_nuevo = true)
	abrir_ordenador()
	await get_tree().create_timer(0.5).timeout   # el encendido del monitor dura 0,35 s
	Captura.foto("captura-escritorio-nuevo.png")   # el icono avisa de que hay algo nuevo
	ordenador.abrir("colecciones")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-colecciones.png")
	var marcado := get_viewport().gui_get_focus_owner()
	print("Colecciones al abrir: pestaña %s, marcado %s (esperado: durmientes, z_normal)" % [ordenador.familia_vista,
		marcado.name if marcado else "nada"])
	ordenador.abrir("colecciones", "z_gerente")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-bestiario-falta.png")
	print("Con z_gerente: pestaña %s, página %d (esperado: sonambulos, 0)" % [ordenador.familia_vista, ordenador.pagina_vista])
	ordenador.abrir("colecciones", "z_oficinista")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-bestiario-torre.png")
	ordenador.abrir("colecciones", "z_criatura")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-bestiario-grande.png")
	ordenador.abrir("colecciones", "z_sujeto_1")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-bestiario-pagina.png")
	print("Con z_sujeto_1: pestaña %s, página %d, casillas %d (esperado: sonambulos, 1, 5)" % [ordenador.familia_vista,
		ordenador.pagina_vista, ordenador.ventana.find_children("z_*", "Button", true, false).size()])
	# la flecha de la derecha da la vuelta a la primera página y se queda marcada
	var flecha: Button = ordenador.ventana.find_child("pag_sig", true, false)
	flecha.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	var tras_flecha := get_viewport().gui_get_focus_owner()
	print("Tras la flecha: página %d, marcado %s (esperado: 0, pag_sig)" % [ordenador.pagina_vista,
		tras_flecha.name if tras_flecha else "nada"])
	# una pestaña, pulsada de verdad: cambia de familia, vuelve a la primera página y se queda marcada
	ordenador.abrir("colecciones", "z_normal")
	var pestana: Button = ordenador.ventana.find_child("pes_sonambulos", true, false)
	pestana.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	marcado = get_viewport().gui_get_focus_owner()
	print("Al pulsar la pestaña de los sonámbulos: pestaña %s, marcado %s, casillas %d (esperado: sonambulos, pes_sonambulos, 12)" % [
		ordenador.familia_vista, marcado.name if marcado else "nada",
		ordenador.ventana.find_children("z_*", "Button", true, false).size()])
	# la ficha sale al elegir la casilla, no al pasar por ella: marcada (como con el ratón encima: aclarada y con borde
	# gris fino), el vecino sigue en la ficha (captura-sujetos-encima.png); pulsada, sale el crío
	ordenador.abrir("colecciones", "z_normal")
	await get_tree().create_timer(0.3).timeout
	var visor := func() -> String:
		for h in ordenador.ventana.find_children("*", "CenterContainer", true, false):
			if h.has_meta("ficha"):
				return h.get_meta("ficha")
		return ""
	var crio: Button = ordenador.ventana.find_child("z_rapido", true, false)
	crio.grab_focus()
	crio.mouse_entered.emit()
	await get_tree().create_timer(0.2).timeout
	Captura.foto("captura-sujetos-encima.png")
	var al_pasar: String = visor.call()
	crio.pressed.emit()
	await get_tree().create_timer(0.2).timeout
	print("Sujetos: al pasar por el crío, la ficha de %s; al elegirlo, la de %s (esperado: z_normal y z_rapido)" % [al_pasar,
		visor.call()])
	# ningún sujeto toca la lámpara del escenario: de cabeza a pies cabe entre el techo y el suelo
	var tocan := []
	for id in Bestiario.LISTA:
		var alto: int = Bestiario.LISTA[id].recorte.size.y
		var escala := clampi(int((ordenador.PIES_ESCENARIO - ordenador.TECHO_ESCENARIO) / alto), 1, 3)
		if alto * escala > ordenador.PIES_ESCENARIO - ordenador.TECHO_ESCENARIO:
			tocan.append(id)
	print("Sujetos que tocan la lámpara: %s (esperado: [])" % [tocan])
	# la ventana, maximizada, y nada se sale (sin barra de desplazamiento en el programa)
	var desliza: ScrollContainer = ordenador.ventana.find_children("*", "ScrollContainer", true, false)[0]
	print("Colecciones · ventana %s (esperado: 872 de ancho) · se desplaza %s (esperado: false; mide %d de alto y caben %d)" % [
		ordenador.ventana.size, desliza.get_v_scroll_bar().visible, desliza.get_v_scroll_bar().max_value, desliza.size.y])
	# lo que enseña, familia por familia
	var g := Guardado.cargar()
	var suman := 0
	for fam in Bestiario.familias():
		var suyos: Array = Bestiario.de_familia(fam)
		suman += suyos.size()
		print("Familia %s: %d/%d vistos" % [fam, suyos.filter(func(id): return id in g.bestiario).size(), suyos.size()])
	if suman != Bestiario.LISTA.size() or Bestiario.LISTA.size() != 30:   # (con la vecina, 8 nov)
		push_error("Colecciones: las familias suman %d y el bestiario tiene %d (esperado: 30 y 30)" % [suman, Bestiario.LISTA.size()])
	if g.colecciones_nuevo:
		push_error("Colecciones: el aviso de nuevo sigue puesto después de abrir el programa")
	# matar uno lo cuenta en la partida (al acabar pasa al guardado); en la sala de pruebas, no (ver meter_zombi)
	var antes: int = matados.get("lento", 0)
	contar_matado("lento")
	contar_matado("no_existe")
	print("Matados en la partida: lento %d → %d (esperado: uno más) · claves %s" % [antes, matados.lento, matados.keys()])
	ordenador.abrir("")
	ordenador.apagar()


# Con "--captura --ordenador-arriba": cada programa del ordenador recién abierto empieza arriba (todos sus
# desplazamientos, también los de dentro de Dosier, Noticias y Colecciones, a 0; en Noticias, la lista deja a la vista la
# emisión marcada). Al subir un talento desde abajo la ventana se queda donde estaba, con el talento a la vista, y con
# el teclado el desplazamiento sigue al foco. Lo mismo con clics de verdad, con y sin paso de física en cada fotograma
# (F13 y F14), y sin que llegue a dibujarse la ventana en otro sitio. Fotos: captura-arriba-<programa>.png y
# captura-arriba-clic.png (tras subir un talento con un clic)
func probar_ordenador_arriba() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g):
		g.dolares = 60
		g.talentos = {})   # (que Ataque se pueda subir)
	ahorrados = 60
	await get_tree().create_timer(0.3).timeout
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	var cuenta := func(programa: String) -> void:
		var foco := get_viewport().gui_get_focus_owner()
		var desplazamientos := []
		for d: ScrollContainer in ordenador.ventana.find_children("*", "ScrollContainer", true, false):
			desplazamientos.append("%d/%d" % [d.scroll_vertical, int(d.get_v_scroll_bar().max_value - d.get_v_scroll_bar().page)])
		print("%s: desplazada %s · marcado %s · info «%s»" % [programa, desplazamientos, foco.name if foco else "nada",
			ordenador.info.text.left(40)])
	for programa in ["puntos", "armas", "logros", "dosier", "videos", "colecciones"]:
		ordenador.abrir(programa)
		await get_tree().create_timer(0.6).timeout
		cuenta.call(programa)
		Captura.foto("captura-arriba-%s.png" % programa)
	# subir un talento desde abajo: no salta arriba
	ordenador.abrir("puntos")
	await get_tree().create_timer(0.4).timeout
	var desliza: ScrollContainer = ordenador.ventana.find_children("*", "ScrollContainer", true, false)[0]
	desliza.scroll_vertical = 120
	await get_tree().create_timer(0.3).timeout
	ordenador.subir("ataque")
	await get_tree().create_timer(0.6).timeout
	cuenta.call("puntos tras subir Ataque desde 120 (esperado: sigue sobre 120 y Ataque a la vista, info «¡Ataque sube...»)")
	Captura.foto("captura-arriba-subir.png")
	# el teclado: bajar por las tarjetas arrastra el desplazamiento
	ordenador.abrir("logros")
	await get_tree().create_timer(0.6).timeout
	for i in 10:
		var evento := InputEventAction.new()
		evento.action = "ui_down"
		evento.pressed = true
		Input.parse_input_event(evento)
		await get_tree().create_timer(0.1).timeout
		evento.pressed = false
		Input.parse_input_event(evento)
		await get_tree().create_timer(0.05).timeout
	cuenta.call("logros tras bajar 10 veces con el teclado (esperado: marcada una tarjeta de más abajo y la ventana ya no está arriba)")
	ordenador.ventana.find_children("*", "Button", true, false).back().grab_focus()
	await get_tree().create_timer(0.2).timeout
	cuenta.call("logros tras marcar la última tarjeta (esperado: la ventana la sigue hasta el fondo)")
	# con clics de verdad, también en fotogramas sin paso de física (en una pantalla de más de 60 Hz, o a ratos en cualquiera):
	# ahí se hace lo diferido después de avisar del fotograma, y es cuando las páginas se iban solas hasta abajo (F13 y F14)
	for pasos in [60, 5]:
		Engine.physics_ticks_per_second = pasos
		for programa in ["puntos", "armas", "logros", "dosier", "videos", "colecciones"]:
			ordenador.abrir("")
			await get_tree().create_timer(0.3).timeout
			await clic_en(ordenador.iconos.get_node("icono_" + programa))
			await get_tree().create_timer(0.4).timeout
			cuenta.call("%d pasos, %s abierto con un clic (esperado: arriba; Noticias, la de fuera arriba)" % [pasos, programa])
		Guardado.cambiar(func(g):
			g.dolares = 60
			g.talentos = {})
		ordenador.abrir("")
		await get_tree().create_timer(0.2).timeout
		ordenador.abrir("puntos")
		await get_tree().create_timer(0.4).timeout
		desliza = ordenador.ventana.find_children("*", "ScrollContainer", true, false)[0]
		desliza.scroll_vertical = 120
		await get_tree().create_timer(0.3).timeout
		var boton: Control = ordenador.ventana.find_child("b_ataque", true, false)
		var dibujados := {}   # lo desplazada que está la ventana en cada fotograma que se dibuja (justo antes de dibujarlo)
		var midiendo := func() -> void:
			var ahora: Array = ordenador.ventana.find_children("*", "ScrollContainer", true, false) if ordenador.ventana else []
			if not ahora.is_empty():
				dibujados[ahora[0].scroll_vertical] = true
		RenderingServer.frame_pre_draw.connect(midiendo)
		await clic_en(boton)
		await get_tree().create_timer(0.5).timeout
		RenderingServer.frame_pre_draw.disconnect(midiendo)
		cuenta.call("%d pasos, tras un clic en Ataque desde 120 (esperado: sigue sobre 120, info «¡Ataque sube...»)" % pasos)
		print("%d pasos, desplazamientos que han llegado a dibujarse: %s (esperado: solo 120, sin parpadeo)" % [pasos, dibujados.keys()])
		Captura.foto("captura-arriba-clic.png")
	Engine.physics_ticks_per_second = 60
	ordenador.abrir("")
	ordenador.apagar()
	Guardado.cambiar(func(g):
		g.dolares = antes.dolares
		g.dolares_talentos = antes.dolares_talentos
		g.talentos = antes.talentos)
	ahorrados = antes.dolares


# Hace clic de verdad, con el ratón, en el centro de ese botón (Godot lo recibe como cualquier otro clic)
func clic_en(b: Control) -> void:
	var sitio: Vector2 = get_viewport().get_screen_transform() * b.get_global_rect().get_center()
	Input.warp_mouse(sitio)
	await get_tree().create_timer(0.1).timeout   # (que el ratón llegue antes de pulsar: al moverse, la línea de info cambia)
	for pulsado in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.button_mask = MOUSE_BUTTON_MASK_LEFT if pulsado else 0
		e.pressed = pulsado
		e.position = sitio
		e.global_position = sitio
		Input.warp_mouse(sitio)   # (en Windows, Godot mira dónde está el cursor de verdad al soltar)
		Input.parse_input_event(e)
		await get_tree().process_frame
		await get_tree().process_frame


# Con "--captura --ordenador-teclado": con el teclado o el mando se llega a todo en cada programa del ordenador: sube hasta
# arriba, baja hasta abajo y vuelve, y dice por cuántas tarjetas ha pasado y dónde acaba. Deja el guardado como estaba
# Con "--captura --ordenador-iconos": cada icono del escritorio del ordenador con el ratón encima (el marco de madera del
# foco): una foto ampliada ×3 de cada uno, captura-ordenador-icono-<programa>.png, para ver que el dibujo y el rótulo
# quedan dentro del marco
func probar_ordenador_iconos() -> void:
	await get_tree().create_timer(0.3).timeout
	abrir_ordenador()
	await get_tree().create_timer(0.6).timeout
	for b: Button in ordenador.iconos.get_children():
		Input.warp_mouse(b.get_global_rect().get_center() * get_viewport().get_screen_transform().get_scale())
		b.grab_focus()
		await get_tree().create_timer(0.25).timeout
		var r := b.get_global_rect().grow(8)
		var img := get_viewport().get_texture().get_image().get_region(Rect2i(r))
		img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
		img.save_png(Captura.CARPETA + "captura-ordenador-icono-%s.png" % b.name.trim_prefix("icono_"))
	Captura.foto("captura-ordenador-iconos.png")
	ordenador.apagar()


func probar_ordenador_teclado() -> void:
	var antes := Guardado.cargar()
	await get_tree().create_timer(0.3).timeout
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	var donde := func() -> String:
		var foco := get_viewport().gui_get_focus_owner()
		var barras := []
		for d: ScrollContainer in ordenador.ventana.find_children("*", "ScrollContainer", true, false):
			barras.append("%d/%d" % [d.scroll_vertical, int(d.get_v_scroll_bar().max_value - d.get_v_scroll_bar().page)])
		return "%s %s" % [foco.name if foco else "nada", barras]
	for programa in ["puntos", "armas", "logros", "dosier", "videos", "colecciones"]:
		ordenador.abrir(programa)
		await get_tree().create_timer(0.5).timeout
		await andar_con_teclado("ui_up")
		var bajadas: int = await andar_con_teclado("ui_down")
		var abajo: String = donde.call()
		var subidas: int = await andar_con_teclado("ui_up")
		print("%s con el teclado: baja %d y acaba en %s (esperado: abajo del todo) · sube %d y acaba en %s (esperado: arriba del todo)" % [
			programa, bajadas, abajo, subidas, donde.call()])
	# con el ratón, un clic en un apartado de los logros (archivador_logros.gd) abre su página
	ordenador.abrir("logros")
	await get_tree().create_timer(0.5).timeout
	await clic_en(ordenador.ventana.find_child("b_tema_jefes", true, false))
	await get_tree().create_timer(0.3).timeout
	print("Clic en Jefes de los logros: página %s, marcado %s (esperado: jefes, b_tema_jefes)" % [
		ordenador.ventana.find_child("archivador", true, false).pagina, donde.call()])
	ordenador.abrir("")
	ordenador.apagar()
	Guardado.cambiar(func(g): g.merge(antes, true))


# Con "--captura --arbol-talentos": la ficha del árbol de talentos del ordenador (arbol_talentos.gd), con 100 $, Ataque
# lleno y Puntería a 2. Con el ratón: sale al pasar por encima de Tirador (captura-arbol-raton.png), se va al apartarlo y
# un clic compra. Con el mando: la cruceta pasa de Ataque a Camorrista, la ficha la sigue y dice «A: comprar»
# (captura-arbol-mando.png), y A compra. Con el dedo: el primer toque en Corpulento solo enseña la ficha, «Toca otra vez»
# (captura-arbol-dedo.png), y el segundo compra. Cada línea dice lo esperado. Deja el guardado como estaba
func probar_arbol_talentos() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g):
		g.dolares = 100
		g.talentos = {"ataque": 5, "punteria": 2})
	ahorrados = 100
	await get_tree().create_timer(0.3).timeout
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.abrir("puntos")
	await get_tree().create_timer(0.5).timeout
	var arbol := func() -> Control: return ordenador.ventana.find_child("arbol", true, false)
	var boton := func(id: String) -> Button: return ordenador.ventana.find_child("b_" + id, true, false)
	var nivel := func(id: String) -> int: return Talentos.nivel_de(Guardado.cargar(), id)
	# el ratón
	await mover_raton(boton.call("tirador").get_global_rect().get_center())
	print("Ratón encima de Tirador: ficha de «%s», a la vista %s, pie «%s» (esperado: tirador, true, Clic: comprar · $10)" % [
		arbol.call().ficha_id, arbol.call().ficha.visible, arbol.call().pie_ficha("tirador")])
	Captura.foto("captura-arbol-raton.png")
	await mover_raton(arbol.call().get_global_rect().position + Vector2(30, 30))
	print("Ratón apartado: ficha de «%s», a la vista %s (esperado: nada, false)" % [arbol.call().ficha_id, arbol.call().ficha.visible])
	await clic_en(boton.call("tirador"))
	await get_tree().create_timer(0.3).timeout
	print("Clic en Tirador: nivel %d (esperado: 1, a la primera)" % nivel.call("tirador"))
	# el mando
	Controles.con_mando = true
	boton.call("ataque").grab_focus()
	await pulsar_mando(JOY_BUTTON_DPAD_DOWN)
	var foco := get_viewport().gui_get_focus_owner()
	print("Mando, abajo desde Ataque: marcado %s · ficha de «%s» · pie «%s» (esperado: b_camorrista, camorrista, A: comprar · $10)" % [
		foco.name if foco else "nada", arbol.call().ficha_id, arbol.call().pie_ficha("camorrista")])
	Captura.foto("captura-arbol-mando.png")
	await pulsar_mando(JOY_BUTTON_A)
	await get_tree().create_timer(0.3).timeout
	foco = get_viewport().gui_get_focus_owner()
	print("Mando, A: Camorrista %d · sigue marcado %s · ficha de «%s» (esperado: 1, b_camorrista, camorrista)" % [
		nivel.call("camorrista"), foco.name if foco else "nada", arbol.call().ficha_id])
	Controles.con_mando = false
	# el dedo
	Tactil.activo = true
	Tactil.con_dedo = true
	await tocar(boton.call("corpulento").get_global_rect().get_center())
	print("Dedo, primer toque en Corpulento: nivel %d · ficha de «%s» · pie «%s» (esperado: 0, corpulento, Toca otra vez: comprar · $5)" % [
		nivel.call("corpulento"), arbol.call().ficha_id, arbol.call().pie_ficha("corpulento")])
	Captura.foto("captura-arbol-dedo.png")
	await get_tree().create_timer(0.4).timeout
	await tocar(boton.call("corpulento").get_global_rect().get_center())
	await get_tree().create_timer(0.3).timeout
	print("Dedo, segundo toque: nivel %d (esperado: 1)" % nivel.call("corpulento"))
	Tactil.activo = false
	ordenador.abrir("")
	ordenador.apagar()
	Guardado.cambiar(func(g):
		g.dolares = antes.dolares
		g.dolares_talentos = antes.dolares_talentos
		g.talentos = antes.talentos)
	ahorrados = antes.dolares


# Con "--captura --tienda-armas": la tienda de armas del ordenador (tienda_armas.gd), con 100 $. Al abrir, la ficha
# explica la tienda (captura-tienda-nota.png). Con el ratón: al pasar por la escopeta la ficha la enseña
# (captura-tienda-raton.png), se queda al ir hacia «Comprar» y «Comprar» la compra. Con el mando: la cruceta pasa del
# cuchillo al bate, la ficha lo sigue y dice «A: comprar» (captura-tienda-mando.png), y A lo compra. Con el dedo: el
# primer toque en la granada solo enseña la ficha (captura-tienda-dedo.png) y el segundo compra una. Y la ficha en alemán,
# ruso y chino (captura-tienda-de.png...). Cada línea dice lo esperado. Deja el guardado como estaba
func probar_tienda_armas() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g): g.dolares = 100)
	ahorrados = 100
	await get_tree().create_timer(0.3).timeout
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.abrir("armas")
	await get_tree().create_timer(0.5).timeout
	var tienda := func() -> Control: return ordenador.ventana.find_child("tienda", true, false)
	var boton := func(id: String) -> Button: return ordenador.ventana.find_child("b_" + id, true, false)
	var dolares := func() -> int: return Guardado.cargar().dolares
	var foco := get_viewport().gui_get_focus_owner()
	print("Al abrir: ficha de «%s» · marcado %s · «Comprar» a la vista %s (esperado: nada, b_cuchillo, false)" % [
		tienda.call().ficha_id, foco.name if foco else "nada", boton.call("comprar").visible])
	Captura.foto("captura-tienda-nota.png")
	# el ratón (primero por el cuchillo, el bate, la katana y la motosierra, que tienen sus dibujos de la tienda:
	# captura-tienda-<id>.png)
	await mover_raton(boton.call("cuchillo").get_global_rect().get_center())
	var alto_cuchillo: Vector2 = tienda.call().size
	Captura.foto("captura-tienda-cuchillo.png")
	await mover_raton(boton.call("bate").get_global_rect().get_center())
	Captura.foto("captura-tienda-bate.png")
	await mover_raton(boton.call("katana").get_global_rect().get_center())
	Captura.foto("captura-tienda-katana.png")
	await mover_raton(boton.call("motosierra").get_global_rect().get_center())
	print("Ratón encima de la motosierra: ficha de «%s» (esperado: motosierra)" % tienda.call().ficha_id)
	Captura.foto("captura-tienda-motosierra.png")
	await mover_raton(boton.call("pistola").get_global_rect().get_center())
	Captura.foto("captura-tienda-pistola.png")
	await mover_raton(boton.call("mp5").get_global_rect().get_center())
	Captura.foto("captura-tienda-mp5.png")
	await mover_raton(boton.call("lanzagranadas").get_global_rect().get_center())
	Captura.foto("captura-tienda-lanzagranadas.png")
	await mover_raton(boton.call("gatling").get_global_rect().get_center())
	Captura.foto("captura-tienda-gatling.png")
	await mover_raton(boton.call("lanzallamas").get_global_rect().get_center())
	Captura.foto("captura-tienda-lanzallamas.png")
	print("Ratón encima del lanzallamas: la tienda mide %s y la línea de info %s (esperado: lo mismo que encima del cuchillo, %s)" % [
		tienda.call().size, ordenador.info.size, alto_cuchillo])
	await mover_raton(boton.call("desintegrador").get_global_rect().get_center())
	Captura.foto("captura-tienda-desintegrador.png")
	await mover_raton(boton.call("pistola_electrica").get_global_rect().get_center())
	Captura.foto("captura-tienda-pistola_electrica.png")
	await mover_raton(boton.call("escopeta").get_global_rect().get_center())
	print("Ratón encima de la escopeta: ficha de «%s» · botón «%s» (esperado: escopeta, Comprar · $%d)" % [
		tienda.call().ficha_id, tienda.call().texto_comprar("escopeta"), tienda.call().precio("escopeta")])
	Captura.foto("captura-tienda-raton.png")
	await mover_raton(boton.call("comprar").get_global_rect().get_center())
	print("Ratón encima de «Comprar»: ficha de «%s» (esperado: escopeta, se queda)" % tienda.call().ficha_id)
	var precio_escopeta: int = tienda.call().precio("escopeta")
	await clic_en(boton.call("comprar"))
	await get_tree().create_timer(0.3).timeout
	print("Clic en «Comprar»: en la mano %s · $%d · ficha de «%s» · botón «%s» (esperado: escopeta, $%d, escopeta, Comprada)" % [
		johnny.huecos.fuego, dolares.call(), tienda.call().ficha_id, tienda.call().texto_comprar("escopeta"), 100 - precio_escopeta])
	Captura.foto("captura-tienda-comprada.png")
	# el mando
	Controles.con_mando = true
	boton.call("cuchillo").grab_focus()
	await pulsar_mando(JOY_BUTTON_DPAD_RIGHT)
	foco = get_viewport().gui_get_focus_owner()
	print("Mando, derecha desde el cuchillo: marcado %s · ficha de «%s» · botón «%s» (esperado: b_bate, bate, A: comprar · $%d)" % [
		foco.name if foco else "nada", tienda.call().ficha_id, tienda.call().texto_comprar("bate"), tienda.call().precio("bate")])
	Captura.foto("captura-tienda-mando.png")
	await pulsar_mando(JOY_BUTTON_A)
	await get_tree().create_timer(0.3).timeout
	foco = get_viewport().gui_get_focus_owner()
	print("Mando, A: cuerpo a cuerpo %s · sigue marcado %s · ficha de «%s» (esperado: bate, b_bate, bate)" % [
		johnny.huecos.cuerpo, foco.name if foco else "nada", tienda.call().ficha_id])
	await pulsar_mando(JOY_BUTTON_DPAD_UP)
	foco = get_viewport().gui_get_focus_owner()
	print("Mando, arriba desde el bate: marcado %s (esperado: b_bate, no se sale)" % [foco.name if foco else "nada"])
	Controles.con_mando = false
	# el dedo
	Tactil.activo = true
	Tactil.con_dedo = true
	var granadas: int = lanzables.total("granada")
	await tocar(boton.call("granada").get_global_rect().get_center())
	print("Dedo, primer toque en la granada: llevas %d (antes %d) · ficha de «%s» (esperado: las mismas, granada)" % [
		lanzables.total("granada"), granadas, tienda.call().ficha_id])
	Captura.foto("captura-tienda-dedo.png")
	await get_tree().create_timer(0.4).timeout
	await tocar(boton.call("granada").get_global_rect().get_center())
	await get_tree().create_timer(0.3).timeout
	print("Dedo, segundo toque: llevas %d (esperado: %d) · info «%s» · listo %s" % [lanzables.total("granada"), granadas + 1, ordenador.info.text, tienda.call().listo])
	Tactil.activo = false
	# en los idiomas más largos (y en chino, sin espacios): la ficha de la motosierra cabe (captura-tienda-<idioma>.png)
	var idioma := Idioma.actual
	for codigo in ["de", "ru", "zh_CN"]:
		Idioma.poner(codigo, false)
		ordenador.abrir("armas", "b_motosierra")
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-tienda-%s.png" % codigo)
	Idioma.poner(idioma, false)
	ordenador.abrir("")
	ordenador.apagar()
	Guardado.cambiar(func(g):
		g.dolares = antes.dolares
		g.armas = antes.armas)
	ahorrados = antes.dolares


# Mueve el ratón de verdad hasta ese punto (en coordenadas del lienzo)
func mover_raton(punto: Vector2) -> void:
	var sitio: Vector2 = get_viewport().get_screen_transform() * punto
	Input.warp_mouse(sitio)
	var e := InputEventMouseMotion.new()
	e.position = sitio
	e.global_position = sitio
	e.relative = Vector2(1, 1)
	Input.parse_input_event(e)
	await get_tree().create_timer(0.2).timeout


# Un botón del mando, pulsado y soltado
func pulsar_mando(cual: JoyButton) -> void:
	for pulsado in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = cual
		e.pressed = pulsado
		Input.parse_input_event(e)
		await get_tree().create_timer(0.1).timeout


# Un toque del dedo en ese punto (Godot lo convierte en un clic del ratón, como en el móvil)
func tocar(punto: Vector2) -> void:
	var sitio: Vector2 = get_viewport().get_screen_transform() * punto
	for pulsado in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.pressed = pulsado
		e.position = sitio
		Input.parse_input_event(e)
		await get_tree().create_timer(0.1).timeout


# Para probar_ordenador_teclado: pulsa esa acción hasta que la marca deje de moverse; devuelve las veces que se ha movido
func andar_con_teclado(accion: String) -> int:
	var pasos := 0
	for i in 200:
		var estaba := get_viewport().gui_get_focus_owner()
		var evento := InputEventAction.new()
		evento.action = accion
		evento.pressed = true
		Input.parse_input_event(evento)
		await get_tree().create_timer(0.05).timeout
		evento.pressed = false
		Input.parse_input_event(evento)
		await get_tree().create_timer(0.03).timeout
		if get_viewport().gui_get_focus_owner() == estaba:
			break
		pasos += 1
	return pasos


# Con "--captura --novedades": los avisos de lo nuevo (L11). En la sala de mantenimiento, con noticias sin ver, un logro
# por cobrar, algo nuevo en Colecciones y una skin sin ver, sale un «!» que bota encima de la mesa del ordenador y de la
# taquilla (captura-novedades.png); en el escritorio de ConserjeOS, el «!» y el rótulo de Noticias, Colecciones y Logros
# (captura-novedades-escritorio.png); y el grito grande encima de Johnny de las noticias, el logro y la skin
# (captura-novedades-noticias.png, -logro.png y -skin.png). Luego, sin nada nuevo, los «!» se esconden. Deja el guardado
# como estaba y se cierra
func probar_novedades() -> void:
	set_process(false)
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g):
		g.logros = {"manitas": "conseguido"}
		g.colecciones_nuevo = true
		g.skins_nuevo = true)
	johnny.position = Vector2((mapa.TAQUILLA_X + mapa.ORDENADOR_X) / 2.0, Planta.MURO + 150.0)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(1.4).timeout
	var marca := func(mueble: Node2D) -> bool: return mueble.get_node("Exclamacion").visible
	print("Con novedades %s: «!» de la mesa %s, de la taquilla %s (esperado: [colecciones, logros], true, true)" % [
		mapa.ORDENADOR.novedades(Guardado.cargar()), marca.call(mapa.ordenador), marca.call(mapa.taquilla)])
	Captura.foto("captura-novedades.png")
	# el escritorio: el rótulo y el «!» de los dos iconos (y de ninguno más)
	abrir_ordenador()
	await get_tree().create_timer(0.5).timeout
	var con_marca := []
	for icono in ordenador.iconos.get_children():
		if icono.get_children().any(func(c): return c.name == "marca_nuevo"):
			con_marca.append(icono.name)
	print("Escritorio: iconos con «!» %s (esperado: icono_logros, icono_colecciones)" % [con_marca])
	Captura.foto("captura-novedades-escritorio.png")
	ordenador.abrir("")
	ordenador.apagar()
	await get_tree().create_timer(0.3).timeout
	# el grito grande de cada cosa (el logro, sin las ayudas que lleva la partida de prueba: con ayudas no se consiguen)
	Guardado.cambiar(func(g):
		g.logros = {}
		for ayuda in Logros.AYUDAS:
			g.ajustes[ayuda] = false)
	logros.con_ayudas = false
	logros.cumplir("manitas")
	await get_tree().create_timer(0.35).timeout
	Captura.foto("captura-novedades-logro.png")
	await get_tree().create_timer(1.3).timeout
	gran_aviso("¡SKIN NUEVA!")
	await get_tree().create_timer(0.35).timeout
	Captura.foto("captura-novedades-skin.png")
	# sin nada nuevo, los «!» se esconden (la taquilla al abrirla; la mesa, con lo visto y lo cobrado)
	Guardado.cambiar(func(g):
		g.logros = {"manitas": "cobrado"}
		g.colecciones_nuevo = false
		g.skins_nuevo = false)
	await get_tree().create_timer(1.4).timeout
	print("Sin novedades %s: «!» de la mesa %s, de la taquilla %s (esperado: [], false, false)" % [
		mapa.ORDENADOR.novedades(Guardado.cargar()), marca.call(mapa.ordenador), marca.call(mapa.taquilla)])
	Guardado.cambiar(func(g):
		for clave in ["logros", "colecciones_nuevo", "skins_nuevo", "ajustes"]:
			g[clave] = antes[clave])


# Con "--captura --avisos-ordenador": los «!» de los iconos de ConserjeOS se quitan nada más mirar o cobrar lo nuevo, sin
# apagar el ordenador (L16). Con un logro por cobrar y algo nuevo en Colecciones, se enciende el ordenador
# (captura-avisos-1.png: los dos iconos con «!»); se abre Colecciones (se quita el suyo) y Logros, donde se cobra el premio
# (captura-avisos-2.png: Colecciones ya sin «!», Logros todavía con él; captura-avisos-3.png: ya ninguno). Al apagar, el «!» de la mesa también se va
# al instante. Deja el guardado como estaba y se cierra
func probar_avisos_ordenador() -> void:
	set_process(false)
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g):
		g.logros = {"manitas": "conseguido"}
		g.colecciones_nuevo = true)
	johnny.position = Vector2(mapa.ORDENADOR_X, Planta.MURO + 150.0)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(1.4).timeout
	var mesa: Node2D = mapa.ordenador
	var con_marca := func() -> Array:
		return ordenador.iconos.get_children().filter(func(icono): return icono.get_children().any(
			func(c): return c.name == "marca_nuevo")).map(func(icono): return str(icono.name))
	print("«!» de la mesa antes: %s (esperado: true)" % [mesa.get_node("Exclamacion").visible])
	abrir_ordenador()
	await get_tree().create_timer(0.5).timeout
	print("Al encender: iconos con «!» %s (esperado: icono_logros, icono_colecciones)" % [con_marca.call()])
	Captura.foto("captura-avisos-1.png")
	ordenador.abrir("colecciones")
	await get_tree().create_timer(0.4).timeout
	print("Al abrir Colecciones: %s (esperado: icono_logros)" % [con_marca.call()])
	Captura.foto("captura-avisos-2.png")
	ordenador.abrir("logros")
	await get_tree().create_timer(0.4).timeout
	print("Al abrir Logros, sin cobrar: %s (esperado: icono_logros)" % [con_marca.call()])
	ordenador.cobrar_logro("manitas")
	await get_tree().create_timer(0.4).timeout
	print("Con el premio cobrado: %s (esperado: ninguno)" % [con_marca.call()])
	Captura.foto("captura-avisos-3.png")
	ordenador.apagar()   # (sin esperar el segundo en que el juego mira la mesa)
	print("«!» de la mesa nada más apagar: %s (esperado: false)" % mesa.get_node("Exclamacion").visible)
	Guardado.cambiar(func(g):
		for clave in ["logros", "colecciones_nuevo", "dolares"]:
			g[clave] = antes[clave])


# Con "--captura --noticias": la tele del salón que enseña las noticias (M91) y VIDEOS.EXE. Cada planta generada tiene una
# sola tele; en la de esta planta: apagada al llegar (captura-tele-apagada.png), se enciende al limpiar el apartamento
# (captura-tele-encendida.png, con el «!» y el contorno), se abre con el clic y se cierra antes sin darla por vista, y
# luego se ve entera: queda apagada y apuntada (captura-tele-noticia.png, captura-tele-vista.png). Después, VIDEOS.EXE
# vacío y con la noticia vista, con el reproductor (captura-videos-vacio.png, captura-videos.png). Deja el guardado como estaba
func probar_noticias() -> void:
	var antes := Guardado.cargar().duplicate(true)
	Guardado.cambiar(func(g): g.videos_vistos = [])
	# una tele por planta, en un salón de un apartamento normal
	for num in range(1, 5):
		var p: Dictionary = Planta.generar(num, edificio)
		var cuantas := 0
		for sitio in p.sitios:
			if sitio.has("tele"):
				cuantas += 1
		print("Tele · planta %d: %d (esperado: 1)" % [num, cuantas])
	var donde := -1
	for j in planta.sitios.size():
		if planta.sitios[j].has("tele"):
			donde = j
	if donde < 0:
		Captura.fallar("esta planta no tiene tele")
		return
	await montar(donde, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var sitio: Dictionary = planta.sitios[donde]
	var tele: Node2D = mapa.tele_salon
	var mueble: Node2D = tele.get_parent()
	johnny.position = mueble.position + Vector2(0, 56)
	johnny.con_raton = false   # (sin ratón, el contorno amarillo sale con Johnny delante, zona_usar.gd)
	johnny.get_node("Camara").reset_smoothing()
	luz.alternar()   # (sin penumbra, para que se vea)
	sitio.limpio = false
	await get_tree().create_timer(0.05).timeout
	print("Tele · al llegar (con zombis): %s (esperado: apagada)" % sitio.tele.estado)
	await get_tree().create_timer(0.8).timeout
	print("Tele · al limpiar el apartamento: %s, limpio %s (esperado: encendida, true)" % [sitio.tele.estado, sitio.limpio])
	Captura.foto("captura-tele-encendida.png")
	# con el clic: sale la primera noticia; cerrada antes de acabar, sigue encendida y sin ver
	var primera: Dictionary = Historia.siguiente_noticia(edificio, Guardado.cargar())
	tele.zona.abrir()
	await get_tree().create_timer(3.0).timeout
	print("Tele · abierta: %s, juego parado %s (esperado: noticia, true)" % [menus.abierto, get_tree().paused])
	Captura.foto("captura-tele-noticia.png")
	menus.noticia_vista(false)
	await get_tree().create_timer(0.2).timeout
	print("Tele · cerrada antes de acabar: %s, vistas %s (esperado: encendida, [])" % [sitio.tele.estado, Guardado.cargar().videos_vistos])
	# otra vez, y entera (pasando cada trozo en cuanto se dice)
	tele.zona.abrir()
	await get_tree().create_timer(0.5).timeout
	var vista: Tele = menus.find_children("*", "Tele", true, false)[0]
	var hecho := 0.0
	while menus.abierto == "noticia" and hecho < 90.0:
		if vista.hablando():
			vista.saltar()
		await get_tree().create_timer(0.4).timeout
		hecho += 0.4
	await get_tree().create_timer(0.3).timeout
	print("Tele · vista entera (en %.0f s): %s, vistas %s (esperado: vista, [%s])" % [hecho, sitio.tele.estado,
		Guardado.cargar().videos_vistos, primera.get("id", "")])
	Captura.foto("captura-tele-vista.png")
	var otra: Dictionary = Historia.siguiente_noticia(edificio, Guardado.cargar())
	print("Tele · la siguiente noticia del edificio: %s (esperado: la segunda, %s)" % [otra.get("id", ""),
		Historia.noticias_de(edificio)[1].id])
	# VIDEOS.EXE: vacío y con la noticia vista
	Guardado.cambiar(func(g): g.videos_vistos = [])
	abrir_ordenador()
	await get_tree().create_timer(0.3).timeout
	if ordenador.fondo == null:   # (abrir_ordenador no lo abre si la partida ha acabado, se cambia de planta o Johnny ha muerto)
		Captura.fallar("el ordenador no se abre en probar_noticias (terminada %s, cambiando %s, Johnny vivo %s)" % [
			terminada, cambiando, johnny.vivo])
		return
	ordenador.abrir("videos")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-videos-vacio.png")
	Guardado.cambiar(func(g): g.videos_vistos = Historia.noticias_de(edificio).slice(0, 2).map(func(n): return n.id))
	ordenador.abrir("videos")
	await get_tree().create_timer(3.0).timeout
	Captura.foto("captura-videos.png")
	var reproductor: Tele = ordenador.find_children("*", "Tele", true, false)[0]
	var avance: ProgressBar = ordenador.ventana.find_child("avance", true, false)
	print("VIDEOS.EXE · reproduciendo: avance %.2f, parada %s (esperado: >0, false)" % [avance.value, reproductor.parada])
	ordenador.ventana.find_child("b_stop", true, false).pressed.emit()
	await get_tree().create_timer(0.3).timeout
	print("VIDEOS.EXE · tras parar: avance %.2f, parada %s (esperado: 0, true)" % [avance.value, reproductor.parada])
	ordenador.ventana.find_child("b_play", true, false).pressed.emit()
	await get_tree().create_timer(2.5).timeout
	print("VIDEOS.EXE · tras reproducir: avance %.2f, parada %s (esperado: >0, false)" % [avance.value, reproductor.parada])
	Captura.foto("captura-videos-play.png")
	ordenador.abrir("")
	ordenador.apagar()
	Guardado.cambiar(func(g): g.videos_vistos = antes.videos_vistos)


# Con "--captura --historia-torre": la historia de Torre Velaria (parte 8 del plan). Las cinco hojas del dosier
# (captura-torre-hoja-N.png); el Dosier del ordenador con la 1 y la 4 encontradas y las demás arrancadas, que dicen
# dónde buscarlas (vestíbulo, planta 10...; captura-torre-dosier-*.png); cada noticia de la torre en la tele, delante de
# la torre, trozo a trozo (captura-torre-tele-<id>-N.png), y si caben en ruso y chino; y el relato del final, línea a
# línea (captura-torre-relato.png). El guardado de prueba vuelve a quedar como estaba
func probar_historia_torre() -> void:
	var antes := Guardado.cargar().duplicate(true)
	var paginas: Array = Historia.dosier("torre").paginas
	# en cada planta de la torre con página (vestíbulo y plantas 10 a 30) hay un sitio para el muerto que la lleva
	for num in range(1, 5):
		var c: Dictionary = Planta.generar(num, "torre").cientifico
		print("Historia torre · el muerto de %s: %s" % [Planta.nombre_torre(num), "sitio %d" % c.sitio if not c.is_empty() else "NINGUNO"])
	for i in paginas.size():
		menus.pagina(paginas[i], i + 1, paginas.size(), func(): pass)
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-torre-hoja-%d.png" % (i + 1))
		menus.leida()
	# el Dosier con la 1 y la 4 encontradas y el centro completado (la torre aún no)
	Guardado.cambiar(func(g):
		for p in paginas:
			g.paginas.erase(p.id)
		g.paginas.append_array(["tv_visitas", "tv_sujeto_1"])
		Guardado.edificio(g, "centro").completado = true
		Guardado.edificio(g, "torre").completado = false)
	print("Historia torre · falta la 2: «%s»" % Historia.falta("torre", paginas[1]).replace("\n", " "))
	print("Historia torre · falta la 5: «%s»" % Historia.falta("torre", paginas[4]).replace("\n", " "))
	print("Historia torre · dónde, de la 1 a la 5: %s (esperado: vestíbulo, planta 10, planta 20, planta 30, laboratorio)" % [
		paginas.map(func(p): return Historia.donde(p, "torre"))])
	print("Historia torre · noticias de la torre: %s (esperado: las 5)" % [Historia.noticias_de("torre").map(func(n): return n.id)])
	abrir_ordenador()
	await get_tree().create_timer(0.3).timeout
	for id in ["tv_visitas", "tv_bienestar", "tv_sujeto_cero"]:
		ordenador.abrir("dosier", "b_" + id)
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-torre-dosier-%s.png" % id)
	# todas encontradas y la torre completada: las cinco noticias
	Guardado.cambiar(func(g):
		for p in paginas:
			if not p.id in g.paginas:
				g.paginas.append(p.id)
		Guardado.edificio(g, "torre").completado = true)
	var noticias: Array = Historia.noticias_de("torre")
	Guardado.cambiar(func(g): g.videos_vistos = Historia.NOTICIAS.map(func(n): return n.id))   # (VIDEOS.EXE solo enseña las vistas)
	for n in noticias:
		ordenador.abrir("videos", "b_" + n.id)
		await get_tree().create_timer(0.3).timeout
		var tele: Tele = ordenador.find_children("*", "", true, false).filter(func(x): return x is Tele)[0]
		tele.continuo = false   # (a mano, trozo a trozo)
		tele.saltar()
		await get_tree().create_timer(2.5).timeout   # que se vaya el rótulo del nombre de la reportera
		for i in tele.trozos.size():
			print("Tele %s, trozo %d de %d: %d líneas (caben %d)" % [n.id, i + 1, tele.trozos.size(),
				tele.texto.get_line_count(), tele.lineas_que_caben()])
			Captura.foto("captura-torre-tele-%s-%d.png" % [n.id, i + 1])
			tele.saltar()
			tele.saltar()
			await get_tree().create_timer(0.1).timeout
	var tele_idiomas: Tele = ordenador.find_children("*", "", true, false).filter(func(x): return x is Tele)[0]
	for codigo in ["en", "de", "ru", "zh_CN"]:
		Idioma.poner(codigo, false)
		var peor := 0
		for n in noticias:
			tele_idiomas.poner(n)
			tele_idiomas.texto.visible_characters = -1
			for t in tele_idiomas.trozos:
				tele_idiomas.texto.text = t
				peor = maxi(peor, tele_idiomas.texto.get_line_count())
		print("Tele de la torre en %s: el trozo más largo con %d líneas (caben %d)" % [codigo, peor, tele_idiomas.lineas_que_caben()])
	Idioma.poner(Idioma.ORIGEN, false)
	ordenador.abrir("")
	ordenador.apagar()
	await get_tree().create_timer(0.3).timeout
	# el relato del final, pasando las líneas con Intro
	Guardado.cambiar(func(g): g.relatos.erase("torre"))
	relatos_prueba = true   # (en las pruebas no salen relatos si no se pide: puede_relato)
	ver_relato("torre")
	await get_tree().create_timer(Relato.ESPERA + 0.1).timeout
	var r: Relato = null
	for h in get_children():
		if h is Relato and h.is_processing_input():
			r = h
	if r == null:
		print("ERROR: el relato de la torre no se ha abierto")
	else:
		var intro := InputEventKey.new()
		intro.keycode = KEY_ENTER
		intro.pressed = true
		while r.vistas < r.lineas.size():
			Input.parse_input_event(intro)
			await get_tree().create_timer(0.25).timeout
		await get_tree().create_timer(Relato.FUNDIDO).timeout
		print("Relato · torre: %d líneas, alto del texto %d" % [r.lineas.size(), r.columna.size.y])
		Captura.foto("captura-torre-relato.png")
		Input.parse_input_event(intro)
		await get_tree().create_timer(Relato.FUNDIDO + 0.5).timeout
		print("Relato · torre apuntado: %s (esperado: true)" % ("torre" in Guardado.cargar().relatos))
	Guardado.cambiar(func(g):
		g.paginas = antes.paginas
		g.videos_vistos = antes.videos_vistos
		g.relatos = antes.relatos
		for e in Historia.DOSIERES:
			Guardado.edificio(g, e).completado = antes.edificios.get(e, {}).get("completado", false))


# Con "--captura --historia": todos los textos de historia.gd, para ver si caben. Cada página del dosier de cada
# edificio en su hoja, como al cogerla (captura-hoja-<id>.png), y cada noticia en la tele con todo lo que dice la
# reportera, trozo a trozo (captura-tele-<id>-<trozo>.png). Al acabar, el guardado de prueba vuelve a tener sus páginas y sus noticias
func probar_historia_entera() -> void:
	var antes := Guardado.cargar().duplicate(true)
	for e in Historia.DOSIERES:
		var paginas: Array = Historia.DOSIERES[e].paginas
		for i in paginas.size():
			menus.pagina(paginas[i], i + 1, paginas.size(), func(): pass)
			await get_tree().create_timer(0.3).timeout
			Captura.foto("captura-hoja-%s.png" % paginas[i].id)
			menus.leida()
	# todas las noticias vistas (VIDEOS.EXE solo enseña las vistas)
	Guardado.cambiar(func(g): g.videos_vistos = Historia.NOTICIAS.map(func(n): return n.id))
	print("Noticias vistas: %d de %d" % [Historia.videos_vistos(Guardado.cargar()).size(), Historia.NOTICIAS.size()])
	abrir_ordenador()
	await get_tree().create_timer(0.3).timeout
	for n in Historia.NOTICIAS:
		ordenador.abrir("videos", "b_" + n.id)
		await get_tree().create_timer(0.3).timeout
		var tele: Tele = ordenador.find_children("*", "", true, false).filter(func(x): return x is Tele)[0]
		tele.continuo = false   # (a mano, trozo a trozo)
		tele.saltar()
		await get_tree().create_timer(2.5).timeout   # que se vaya el rótulo del nombre de la reportera
		# cada trozo de lo que dice (M75), entero: ¿cabe en el cuadro?
		for i in tele.trozos.size():
			print("Tele %s, trozo %d de %d: %d líneas (caben %d)" % [n.id, i + 1, tele.trozos.size(),
				tele.texto.get_line_count(), tele.lineas_que_caben()])
			Captura.foto("captura-tele-%s-%d.png" % [n.id, i + 1])
			tele.saltar()
			tele.saltar()
			await get_tree().create_timer(0.1).timeout
	# en otros idiomas (el ruso y el chino tienen las líneas más altas; el chino, sin espacios): ¿algún trozo se sale?
	var tele_idiomas: Tele = ordenador.find_children("*", "", true, false).filter(func(x): return x is Tele)[0]
	for codigo in ["de", "ru", "zh_CN"]:
		Idioma.poner(codigo, false)
		var peor := 0
		var trozos := 0
		for n in Historia.NOTICIAS:
			tele_idiomas.poner(n)
			trozos = maxi(trozos, tele_idiomas.trozos.size())
			tele_idiomas.texto.visible_characters = -1
			for t in tele_idiomas.trozos:
				tele_idiomas.texto.text = t
				peor = maxi(peor, tele_idiomas.texto.get_line_count())
		print("Tele en %s: hasta %d trozos, el más largo con %d líneas (caben %d)" % [codigo, trozos, peor,
			tele_idiomas.lineas_que_caben()])
	Idioma.poner(Idioma.ORIGEN, false)
	ordenador.abrir("")
	ordenador.apagar()
	Guardado.cambiar(func(g):
		g.paginas = antes.paginas
		g.videos_vistos = antes.videos_vistos
		for e in Historia.DOSIERES:
			Guardado.edificio(g, e).completado = antes.edificios.get(e, {}).get("completado", false))


# Con "--captura --banco": lo de las recetas en un guardado viejo (las armas creadas del baúl, "baul_armas"; las
# recetas aprendidas, "recetas", y las armas creadas alguna vez, "creadas", de Colecciones), que se quitó el 25 oct, y
# los objetos quitados ese día (los de las armas de cuerpo a cuerpo y los clavos, el spray, la lejía, la pistola de
# agua, la cinta americana, la bombona, la jeringuilla, el aceite y el bocadillo) y los que se quitaron con las piezas
# (los explosivos, el despertador, el extintor, el trapo y el alcohol) en el baúl y en los encontrados (Colecciones):
# al cargar desaparece todo (guardado.gd); la gasolina, que sigue, se queda. Luego, el baúl abierto con lo
# que queda (captura-banco-baul.png), la mochila, el banco de trabajo y el baúl (probar_cosas), los arrojables y las
# armas de efecto (probar_efectos) y las Colecciones (probar_colecciones). Cada línea dice lo esperado y se cierra
func probar_banco() -> void:
	var s := Guardado.cargar()
	s["baul_armas"] = [{"receta": "atraedora", "nombre": "Atraedora", "hueco": "arrojadiza", "icono": "despertador",
		"rareza": "azul", "dano": 96, "unidades": 4}]
	s["recetas"] = ["atraedora", "congeladora"]
	s["creadas"] = ["atraedora"]
	var quitados := ["mechero", "llave_inglesa", "hacha", "cuchillas", "taser", "cuerda", "mancuernas", "cadena", "perchas",
		"hielo_seco", "cable", "clavos", "spray", "lejia", "pistola_agua", "cinta_americana", "bombona", "jeringuilla",
		"aceite", "bocadillo", "explosivos", "despertador", "extintor", "trapo", "alcohol"]
	s.baul = {"gasolina": 1}
	for id in quitados:
		s.baul[id] = 2
	s.encontrados = quitados + ["gasolina"]
	Guardado.escribir(s)
	var leido := Guardado.cargar()
	print("Lo de las recetas, viejo, al cargar: baul_armas %s · recetas %s · creadas %s (esperado: false, false, false)" % [
		leido.has("baul_armas"), leido.has("recetas"), leido.has("creadas")])
	print("Los %d objetos quitados, viejos, al cargar: baúl %s · encontrados %s (esperado: { \"gasolina\": 1 }, [\"gasolina\"])" % [
		quitados.size(), leido.baul, leido.encontrados])
	abrir_cosas("baul")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-banco-baul.png")
	inventario.cerrar()
	await get_tree().process_frame
	await probar_cosas()
	await probar_efectos()
	await probar_colecciones()
	get_tree().quit()


# La mochila, el banco y el baúl: unos objetos en la mochila y en el baúl, compra el bate (la fregona va al
# inventario), abre el banco de trabajo (como al arrimarse; lo de mejorar, en --banco-mejorar) y hace fotos
func probar_cosas() -> void:
	Guardado.cambiar(func(g):
		g.dolares = 20
		g.baul = {"pieza_cuerpo": 1, "pieza_especial": 2})
	ahorrados = 20
	mochila = ["gasolina", "gasolina", "pieza_especial", "pieza_cuerpo", "pieza_arrojable"]
	soltar_objeto("pieza_distancia", johnny.position + Vector2(30, 0))
	await get_tree().create_timer(0.6).timeout
	abrir_ordenador()
	ordenador.abrir("armas")
	ordenador.comprar_arma("bate")
	ordenador.abrir("")
	ordenador.apagar()
	abrir_cosas("inventario")
	inventario.tocar("m0")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-inventario.png")
	inventario.cerrar()
	if mapa.banco:
		mapa.banco.usar.emit()   # como al arrimarse
	else:
		abrir_cosas("banco")   # (la prueba larga llega aquí desde la sala de un jefe, donde no hay banco: lo mismo que haría)
	await get_tree().process_frame
	print("Banco: abre la pantalla «%s» (esperado: banco)" % inventario.abierto)
	inventario.cerrar()
	abrir_cosas("baul")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-baul.png")
	inventario.cerrar()
	var g := Guardado.cargar()
	print("Cosas: mochila %s | guardadas %s | mano %s | baúl %s" % [mochila, armas_guardadas, johnny.huecos.cuerpo, g.baul])


# Los arrojables y las armas de efecto: coge congeladoras y atraedoras, lleva el lanza ácido y el lanza rayos
# (de la tienda de armas), dispara el lanza rayos, se pone el lanza ácido desde el inventario y dispara, y lanza
# la congeladora. Cuenta lo que pasa y hace una foto
func probar_efectos() -> void:
	dar_lanzable("congeladora")
	dar_lanzable("atraedora")
	llevar_arma("desintegrador")
	# dos de fuego como mucho (partida.llevar_arma): se deja la de repuesto, para que el lanza ácido pase a serlo
	armas_guardadas.assign(armas_guardadas.filter(func(id): return Armas.datos(id).tipo != "fuego"))
	llevar_arma("pistola_electrica")
	print("Armas de efecto: mano %s | guardadas %s | lanzables a mano %s, de repuesto %s" % [
		[Objetos.nombre(johnny.huecos.cuerpo), Objetos.nombre(johnny.huecos.fuego)], armas_guardadas.map(Objetos.nombre),
		lanzables.mano, lanzables.repuesto])
	print("En la tienda de armas: %s (esperado: Lanzallamas $60, Lanza ácido $60, Lanza rayos $45)" % [
		["lanzallamas", "desintegrador", "pistola_electrica"].map(func(id): return "%s $%d" % [Armas.DATOS[id].nombre, Armas.PRECIOS[id]])])
	johnny.direccion = "e"
	johnny.sostener("fuego")
	var z1 := meter_zombi("lento", johnny.position + Vector2(80, 0))
	var z2 := meter_zombi("lento", johnny.position + Vector2(140, 10))
	z1.vida = 500   # que no muera ninguno (saldría el recuadro de las mutaciones y pararía el juego)
	z2.vida = 500
	await get_tree().create_timer(0.1).timeout
	johnny.disparar(0.0)
	await get_tree().create_timer(0.3).timeout
	print("Lanza rayos: balas %d | zombi 1 aturdido %.1f vida %d | zombi 2 aturdido %.1f vida %d" % [johnny.balas,
		z1.aturdido, z1.vida, z2.aturdido, z2.vida])
	abrir_cosas("inventario")
	inventario.tocar("g%d" % armas_guardadas.find(armas_guardadas.filter(func(id): return Armas.DATOS[id].nombre == "Lanza ácido")[0]))   # (el nombre de la tabla, en español: Objetos.nombre sale traducido)
	inventario.poner_guardada()
	inventario.cerrar()
	for i in 6:
		johnny.disparar(0.0)
		await get_tree().create_timer(0.08).timeout
	await get_tree().create_timer(0.2).timeout
	menus.visible = false   # por si ha salido el recuadro de una mutación
	await get_tree().process_frame
	Captura.foto("captura-efectos.png")
	menus.visible = true
	print("Lanza ácido: mano %s balas %d | zombi 2 vida %d heridas %s | charcos %d" % [Objetos.nombre(johnny.huecos.fuego),
		johnny.balas, z2.vida, z2.get_children().filter(func(n): return n.name.begins_with("herida")).map(func(n): return n.name),
		get_tree().get_nodes_in_group("charcos").size()])
	var z3 := meter_zombi("lento", johnny.position + Vector2(-120, 30))
	z3.vida = 500
	lanzables.tipo = "congeladora"
	lanzables.lanzar(z3.global_position)
	await get_tree().create_timer(2.3).timeout
	print("Congeladora: zombi 3 aturdido %.1f vida %d | vida de Johnny %d | quedan %s" % [z3.aturdido, z3.vida, johnny.vida, lanzables.tipos()])


# El reparto de objetos (parte 6 del centro comercial): cuenta qué sale en cada sitio de los dos edificios y
# comprueba que las vendas (del centro) no salen en los Apartamentos y que ni las piezas ni lo de un solo zombi salen al
# azar. Luego deja en el suelo los del centro (SOLO_CENTRO), mete las piezas en el baúl (lo de «Piezas al baúl» del panel de pruebas) y hace una
# foto del baúl
func probar_objetos() -> void:
	var fallos := []
	for ed_id in ["apartamentos", "centro"]:
		for tienda in [""] + (Objetos.TIENDAS.keys() if ed_id == "centro" else []):
			var salen := {}
			for i in 2000:
				var id := Objetos.al_azar(ed_id, tienda)
				salen[id] = salen.get(id, 0) + 1
				if id in Objetos.DE_UN_ZOMBI or id in Objetos.PIEZAS or (ed_id == "apartamentos" and id in Objetos.SOLO_CENTRO):
					fallos.append("%s %s: %s" % [ed_id, tienda, id])
			print("Objetos en %s %s: %d distintos %s" % [ed_id, tienda if tienda != "" else "(pasillo)", salen.size(), salen.keys()])
	print("Reparto de objetos: ", "bien" if fallos.is_empty() else "MAL %s" % str(fallos.slice(0, 5)))
	for i in Objetos.SOLO_CENTRO.size():
		soltar_objeto(Objetos.SOLO_CENTRO[i], johnny.position + Vector2(-176 + i * 44, -100), true)
	await get_tree().create_timer(0.5).timeout
	menus.visible = false   # por si ha salido el recuadro de una mutación
	await get_tree().process_frame
	Captura.foto("captura-objetos-nuevos.png")
	menus.visible = true
	for cosa in mapa.cosas.get_children():
		if cosa.get_script() == BILLETE:
			cosa.queue_free()
	var baul_antes: Dictionary = Guardado.cargar().baul
	dar_objetos()
	abrir_cosas("baul")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-baul-todo.png")
	inventario.cerrar()
	print("Baúl con las piezas: %d casillas de %d (esperado: 4)" % [Objetos.casillas_baul(Guardado.cargar()), Objetos.BAUL])
	Guardado.cambiar(func(g): g.baul = baul_antes)


# El recuadro de las mutaciones: foto, elige la primera y comprueba que cambia los atributos
func probar_mutaciones() -> void:
	abrir_mutacion()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-mutacion.png")
	var primera: String = menus.cartas[0].id
	menus.elegir(primera)
	elegir_mutacion("insensible")
	print("Mutaciones: %s | daño recibido x%.2f | pausa %s" % [mutaciones.tengo, johnny.stats.dano_recibido, get_tree().paused])


# Con --pausa: solo la pausa (captura-pausa.png: sus números y las armas) y el cartel del final (captura-fin.png)
func probar_pausa_y_fin() -> void:
	pausar()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-pausa.png")
	seguir()
	terminar(true)
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-fin.png")
	get_tree().quit()


# Con --mutaciones: solo el recuadro de las mutaciones (captura-mutacion.png, la foto de la ficha del tutorial) y el
# efecto al elegirla (M54, EfectoSuelo "mutar", de hijo de Johnny: captura-mutar.png, con el ADN a medio subir)
func probar_mutaciones_solo() -> void:
	await probar_mutaciones()
	await get_tree().process_frame   # (EfectoSuelo.soltar lo mete en el siguiente paso)
	var efectos: Array = johnny.get_children().filter(func(n): return n is EfectoSuelo and n.tipo == "mutar")
	print("Mutar: efectos en Johnny %d (esperado: 2, uno por cada mutación elegida) · precalentado %s (esperado: true)" % [efectos.size(), EfectoSuelo.calentados.has("mutar")])
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-mutar.png")
	await get_tree().create_timer(1.2).timeout
	print("  al acabar, efectos %d (esperado: 0)" % johnny.get_children().filter(func(n): return n is EfectoSuelo).size())
	get_tree().quit()


# Fotos de la pausa y del cartel de victoria (con el juego parado solo cuentan los temporizadores)
func probar_menus() -> void:
	set_process(false)
	# Johnny, como nuevo y sin charcos alrededor: el bombero deja el suelo ardiendo y le seguía quemando hasta
	# dejarle en un tercio; con la vida tan baja las curas no se podían usar (se quedaba el inventario abierto y
	# el juego en pausa, y la prueba no se cerraba nunca) y en la azotea moría
	for c in get_tree().get_nodes_in_group("charcos"):
		c.remove_from_group("charcos")
		c.queue_free()
	johnny.estados.clear()
	johnny.tercios = 3
	johnny.vida = johnny.stats.vida_max
	soltar_billetes(3, johnny.position + Vector2(60, 0))
	await get_tree().create_timer(1.2).timeout
	print("Dólares de la partida: %d | muertos: %d" % [dolares, muertos])
	await probar_ordenador()
	await probar_cosas()
	await probar_efectos()
	await probar_objetos()
	await probar_curas()
	await supervivientes.probar()
	await probar_sangre()
	await probar_mutaciones()
	await probar_historia()
	await probar_colecciones()
	if ed.get("azotea", false):
		await probar_azotea()
	pausar()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-pausa.png")
	seguir()
	terminar(true)
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-fin.png")
	print("Guardado de prueba: ", Guardado.cargar())
	get_tree().quit()
